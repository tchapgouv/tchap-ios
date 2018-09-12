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

final class RoomsCoordinator: NSObject, RoomsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let session: MXSession
    
    private let roomsViewController: RoomsViewController
    private let roomsDataSource: RoomsDataSource
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let roomsErrorPresenter: ErrorPresenter
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: NavigationRouterType, session: MXSession) {
        self.router = router
        self.session = session
        self.roomsViewController = RoomsViewController.instantiate()
        self.roomsDataSource = RoomsDataSource(matrixSession: self.session)
        self.roomsDataSource.finalizeInitialization()
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.roomsErrorPresenter = AlertErrorPresenter(viewControllerPresenter: roomsViewController)
    }
    
    // MARK: - Public methods
    
    func start() {
        self.roomsViewController.displayList(self.roomsDataSource)
        self.roomsViewController.roomsViewControllerDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.roomsViewController
    }
    
    func updateSearchText(_ searchText: String) {        
        self.roomsDataSource.search(withPatterns: [searchText])
    }
    
    // MARK: - Private methods
    
    private func showRoom(with roomID: String) {
        let roomViewController: RoomViewController = RoomViewController.instantiate()
        
        self.router.push(roomViewController, animated: true, popCompletion: nil)
        
        self.activityIndicatorPresenter.presentActivityIndicator(on: roomViewController.view, animated: false)
        
        // Present activity indicator when retrieving roomDataSource for given room ID
        let roomDataSourceManager: MXKRoomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.session)
        roomDataSourceManager.roomDataSource(forRoom: roomID, create: true, onComplete: { (roomDataSource) in
            
            self.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            
            if let roomDataSource = roomDataSource {
                roomViewController.displayRoom(roomDataSource)
            }
        })
    }
    
    private func joinRoom(with roomID: String) {
        self.activityIndicatorPresenter.presentActivityIndicator(on: self.roomsViewController.view, animated: true)
        
        self.session.joinRoom(roomID) { [weak self] (response) in
            guard let sself = self else {
                return
            }
            
            sself.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            switch response {
            case .success:
                sself.showRoom(with: roomID)
            case .failure(let error):
                let errorPresentable = sself.joinRoomErrorPresentable(from: error)
                sself.roomsErrorPresenter.present(errorPresentable: errorPresentable, animated: true)
            }
        }
    }
    
    private func joinRoomErrorPresentable(from error: Error) -> ErrorPresentable {
        let errorTitle: String = Bundle.mxk_localizedString(forKey: "room_error_join_failed_title")
        let errorMessage: String
        
        let nsError = error as NSError
        
        if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
            
            if message == "No known servers" {
                // minging kludge until https://matrix.org/jira/browse/SYN-678 is fixed
                // 'Error when trying to join an empty room should be more explicit'
                errorMessage = Bundle.mxk_localizedString(forKey: "room_error_join_failed_empty_room")
            } else {
                errorMessage = message
            }
        } else {
            errorMessage = TchapL10n.errorMessageDefault
        }
        
        return ErrorPresentableImpl(title: errorTitle, message: errorMessage)
    }
}

// MARK: - RoomsViewControllerDelegate
extension RoomsCoordinator: RoomsViewControllerDelegate {
    
    func roomsViewController(_ roomsViewController: RoomsViewController!, didSelectRoomWithID roomID: String!) {
        self.showRoom(with: roomID)
    }
    
    func roomsViewController(_ roomsViewController: RoomsViewController!, didAcceptRoomInviteWithRoomID roomID: String!) {
        self.joinRoom(with: roomID)
    }
    
    func roomsViewController(_ roomsViewController: RoomsViewController!, didSelect publicRoom: MXPublicRoom!) {
        
    }
    
    func roomsViewControllerDidSelectDirectoryServerPicker(_ roomsViewController: RoomsViewController!) {
        
    }
}
