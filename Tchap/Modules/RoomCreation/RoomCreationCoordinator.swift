/*
 Copyright 2018 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit
import MobileCoreServices
import RxSwift

protocol RoomCreationCoordinatorDelegate: AnyObject {
    func roomCreationCoordinatorDidCancel(_ coordinator: RoomCreationCoordinatorType)
    func roomCreationCoordinator(_ coordinator: RoomCreationCoordinatorType, didCreateRoomWithID roomID: String)
}

final class RoomCreationCoordinator: NSObject, RoomCreationCoordinatorType {

    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let session: MXSession
    private let roomCreationViewController: RoomCreationViewController
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let mediaService: MediaServiceType
    private let roomService: RoomServiceType
    
    private var imageData: Data?
    private var roomCreationFormResult: RoomCreationFormResult?
    
    private var imagePickerPresenter: SingleImagePickerPresenter?
    
    private var disposeBag: DisposeBag = DisposeBag()
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomCreationCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.router = NavigationRouter(navigationController: RiotNavigationController())
        self.session = session
        self.mediaService = MediaService(session: session)
        self.roomService = RoomService(session: session)
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        
        let homeServerDomain = RoomCreationCoordinator.getHomeServerDomain(from: session)
        
        let roomCreationViewModel = RoomCreationViewModel(homeServerDomain: homeServerDomain)
        let roomCreationViewController = RoomCreationViewController.instantiate(viewModel: roomCreationViewModel)
        roomCreationViewController.vc_removeBackTitle()
        self.roomCreationViewController = roomCreationViewController
        
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        self.roomCreationViewController.delegate = self
        self.router.setRootModule(self.roomCreationViewController)
        
        self.roomCreationViewController.navigationItem.leftBarButtonItem = MXKBarButtonItem(title: TchapL10n.actionCancel, style: .plain) { [weak self] in
            self?.didCancel()
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.router.toPresentable()
    }
    
    // MARK: - Private
    
    private func didCancel() {
        self.delegate?.roomCreationCoordinatorDidCancel(self)
    }
    
    private class func homeServerDomain(from homeServerURL: String) -> String? {
        guard let homeServerURLComponents = URLComponents(string: homeServerURL),
            let homeServerHost = homeServerURLComponents.host else {
            return nil
        }
        
        return HomeServerComponents(hostname: homeServerHost).displayName
    }
    
    private class func getHomeServerDomain(from session: MXSession) -> String {
        guard let homeServerURL = session.matrixRestClient.homeserver,
            let homeServerDomain = self.homeServerDomain(from: homeServerURL) else {
            return ""
        }
        return homeServerDomain
    }
    
    private func showImagePicker() {
        let singleImagePickerPresenter = SingleImagePickerPresenter(session: self.session)
        singleImagePickerPresenter.delegate = self
        
        singleImagePickerPresenter.present(from: self.toPresentable(), sourceView: nil, sourceRect: .null, animated: true)
        
        self.imagePickerPresenter = singleImagePickerPresenter
    }
    
    private func createRoom() {
        guard let roomCreationFormResult = self.roomCreationFormResult else {
            MXLog.debug("[RoomCreationCoordinator] Fail to create room")
            return
        }

        let removeActivityIndicator: (() -> Void) = {
            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
        }

        let navigationController = self.router.toPresentable()

        self.activityIndicatorPresenter.presentActivityIndicator(on: navigationController.view, animated: true)

        self.uploadRoomAvatarIfNeeded()
        .flatMap { [unowned self] (avatarUrl) -> Single<String> in
            return self.createRoom(roomCreationFormResult: roomCreationFormResult,
                                   avatarUrl: avatarUrl)
        }
        .subscribeOn(MainScheduler.instance)
        .subscribe(onSuccess: { [weak self] (roomID) in
            removeActivityIndicator()
            if let strongSelf = self {
                strongSelf.delegate?.roomCreationCoordinator(strongSelf,
                                                             didCreateRoomWithID: roomID)
            }
        }, onError: { [weak self] error in
            removeActivityIndicator()

            if let strongSelf = self {
                
                // Check whether the room creation failed because of the generated room alias.
                let nsError = error as NSError
                
                if let matrixErrorCode = nsError.userInfo[kMXErrorCodeKey] as? String, matrixErrorCode == kMXErrCodeStringRoomInUse,
                    let matrixMessageError = nsError.userInfo[kMXErrorMessageKey] as? String, matrixMessageError == "Room alias already taken" {
                    // Try again
                    strongSelf.createRoom()
                } else {
                    let errorPresentable = strongSelf.formErrorPresentable(from: error)
                    let formErrorPresenter = AlertErrorPresenter(viewControllerPresenter: navigationController)
                    formErrorPresenter.present(errorPresentable: errorPresentable)
                }
            }
        })
        .disposed(by: self.disposeBag)
    }
    
    private func formErrorPresentable(from error: Error) -> ErrorPresentable {
        return ErrorPresentableImpl(title: TchapL10n.errorTitleDefault, message: TchapL10n.errorMessageDefault)
    }
    
    private func cancelPendingRoomCreation() {
        self.disposeBag = DisposeBag()
    }
    
    private func uploadRoomAvatarIfNeeded() -> Single<String?> {
        guard let imageData = self.imageData, let image = UIImage(data: imageData) else {
            return Single.just(nil)
        }
        
        return self.mediaService.upload(image: image).map({ $0 })
    }
    
    private func createRoom(roomCreationFormResult: RoomCreationFormResult,
                            avatarUrl: String?) -> Single<String> {
        let roomVisibility: MXRoomDirectoryVisibility
        let roomAccessRule: RoomAccessRule
        let isFederated: Bool
        
        switch roomCreationFormResult.roomType {
        case .privateRestricted:
            roomVisibility = .private
            roomAccessRule = .restricted
            isFederated = true
        case .privateUnrestricted:
            roomVisibility = .private
            roomAccessRule = .unrestricted
            isFederated = true
        case .forum(let isFed):
            roomVisibility = .public
            roomAccessRule = .restricted
            isFederated = isFed
        }

        return self.roomService.createRoom(visibility: roomVisibility,
                                           name: roomCreationFormResult.name,
                                           avatarURL: avatarUrl,
                                           inviteUserIds: nil,
                                           isFederated: isFederated,
                                           accessRule: roomAccessRule)
    }
}


// MARK: - RoomCreationViewControllerDelegate
extension RoomCreationCoordinator: RoomCreationViewControllerDelegate {
    func roomCreationViewControllerDidTapAddAvatarButton(_ roomCreationViewController: RoomCreationViewController) {
        self.showImagePicker()
    }
    
    func roomCreationViewController(_ roomCreationViewController: RoomCreationViewController, didTapNextButtonWith roomCreationFormResult: RoomCreationFormResult) {
        self.roomCreationFormResult = roomCreationFormResult
        self.createRoom()
    }
}

// MARK: - SingleImagePickerPresenterDelegate
extension RoomCreationCoordinator: SingleImagePickerPresenterDelegate {
    func singleImagePickerPresenterDidCancel(_ presenter: SingleImagePickerPresenter) {
        presenter.dismiss(animated: true, completion: nil)
        self.imagePickerPresenter = nil
    }
    
    func singleImagePickerPresenter(_ presenter: SingleImagePickerPresenter,
                                    didSelectImageData imageData: Data,
                                    withUTI uti: MXKUTI?) {
        presenter.dismiss(animated: true, completion: nil)
        self.imagePickerPresenter = nil
        
        if let image = UIImage(data: imageData) {
            self.roomCreationViewController.updateAvatar(with: image)
        }
        
        self.imageData = imageData
    }
}
