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

protocol RoomPreviewCoordinatorDelegate: AnyObject {
    func roomPreviewCoordinatorDidCancel(_ coordinator: RoomPreviewCoordinatorType)
    func roomPreviewCoordinator(_ coordinator: RoomPreviewCoordinatorType, didJoinRoomWithId roomID: String, onEventId evenId: String?)
}

final class RoomPreviewCoordinator: NSObject, RoomPreviewCoordinatorType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let detailModulesCheckDelay: Double = 0.3
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private let publicRoom: MXPublicRoom?
    private let roomPreviewData: RoomPreviewData
    
    private let roomViewController: RoomViewController
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let roomsErrorPresenter: ErrorPresenter
    
    private var canReleaseRoomDataSource: Bool {
        // If the displayed data is not a preview, let the manager release the room data source
        // (except if the view controller has the room data source ownership).
        return self.roomViewController.roomDataSource != nil && self.roomViewController.hasRoomDataSourceOwnership == false
    }

    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomPreviewCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, publicRoom: MXPublicRoom) {
        self.session = session
        self.publicRoom = publicRoom
        self.roomPreviewData = RoomPreviewData(publicRoom: publicRoom, andSession: self.session)
        
        self.roomViewController = RoomViewController()
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.roomsErrorPresenter = AlertErrorPresenter(viewControllerPresenter: roomViewController)
        
        super.init()
    }
    
    init(session: MXSession, roomPreviewData: RoomPreviewData) {
        self.session = session
        self.publicRoom = nil
        self.roomPreviewData = roomPreviewData
        
        self.roomViewController = RoomViewController()
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.roomsErrorPresenter = AlertErrorPresenter(viewControllerPresenter: roomViewController)
        
        super.init()
    }
    
    // MARK: - Public methods
    
    func start() {
        self.roomViewController.vc_removeBackTitle()
        
        let roomName: String? = roomPreviewData.roomName

        // Try to get more information about the room
        if publicRoom?.worldReadable ?? false {
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.detailModulesCheckDelay, execute: { [weak self] in
                self?.roomViewController.startActivityIndicator()
            })

            roomPreviewData.peek(inRoom: { [weak self] succeeded in
                guard let sself = self else {
                    return
                }

                if succeeded {
                    sself.roomViewController.displayRoomPreview(sself.roomPreviewData)
                } else if roomName != nil {
                    // Restore the room name which has been overwritten with the roomId
                    sself.roomPreviewData.roomName = roomName
                }
            })
        }
        
        self.roomViewController.displayRoomPreview(roomPreviewData)
        self.roomViewController.delegate = self
        self.registerNavigationRouterNotifications()
    }
    
    func toPresentable() -> UIViewController {
        return self.roomViewController.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func didCancel() {
        self.delegate?.roomPreviewCoordinatorDidCancel(self)
    }
    
    private func joinRoom(with roomPreviewData: RoomPreviewData) {
        
        let roomIdOrAlias: String
        let eventId = roomPreviewData.eventId
        let signURL: URL?
        
        // We promote here join by room alias instead of room id when an alias is available, in order to handle federated room.
        if let canonicalAlias = roomPreviewData.roomCanonicalAlias {
            roomIdOrAlias = canonicalAlias
        } else if let firstRoomAlias = roomPreviewData.roomAliases?.first {
            roomIdOrAlias = firstRoomAlias
        } else {
            roomIdOrAlias = roomPreviewData.roomId
        }
        
        // Note in case of simple link to a room the signUrl param is nil
        if let signUrlString = roomPreviewData.emailInvitation?.signUrl {
            signURL = URL(string: signUrlString)
        } else {
            signURL = nil
        }
        
        self.activityIndicatorPresenter.presentActivityIndicator(on: roomViewController.view, animated: false)
        
        self.session.joinRoom(roomIdOrAlias, withSignUrl: signURL) { [weak self] response in
            guard let sself = self else {
                return
            }
            
            sself.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            
            switch response {
            case .success(let room):
                sself.delegate?.roomPreviewCoordinator(sself, didJoinRoomWithId: room.roomId, onEventId: eventId)
            case .failure(let error):
                let errorPresentable = sself.joinRoomErrorPresentable(from: error)
                sself.roomsErrorPresenter.present(errorPresentable: errorPresentable)
            }
        }
    }
    
    private func joinRoomErrorPresentable(from error: Error) -> ErrorPresentable {
        let errorTitle: String = VectorL10n.roomErrorJoinFailedTitle
        let errorMessage: String
        
        let nsError = error as NSError
        
        if MXError(nsError: nsError).errcode == kMXErrCodeStringForbidden {
            errorMessage = TchapL10n.tchapRoomAccessUnauthorized
        } else {
            if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
    
                if message == "No known servers" {
                    // minging kludge until https://matrix.org/jira/browse/SYN-678 is fixed
                    // 'Error when trying to join an empty room should be more explicit'
                    errorMessage = VectorL10n.roomErrorJoinFailedEmptyRoom
                } else {
                    errorMessage = TchapL10n.tchapRoomAccessUnauthorized
                }
            } else {
                errorMessage = TchapL10n.errorMessageDefault
            }
        }
        
        return ErrorPresentableImpl(title: errorTitle, message: errorMessage)
    }
    
    private func releaseRoomDataSourceIfNeeded() {

        guard self.canReleaseRoomDataSource,
              let roomId = self.publicRoom?.roomId else {
            return
        }

        let dataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.session)
        dataSourceManager?.closeRoomDataSource(withRoomId: roomId, forceClose: false)
    }
    
    private func registerNavigationRouterNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(navigationRouterDidPopViewController(_:)), name: NavigationRouter.didPopModule, object: nil)
    }
    
    @objc private func navigationRouterDidPopViewController(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
              let poppedModule = userInfo[NavigationRouter.NotificationUserInfoKey.module] as? Presentable,
              poppedModule is RoomPreviewCoordinatorType else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.detailModulesCheckDelay) {
            self.releaseRoomDataSourceIfNeeded()
        }
    }
}

// MARK: - RoomViewControllerDelegate
extension RoomPreviewCoordinator: RoomViewControllerDelegate {
    
    func roomViewController(_ roomViewController: RoomViewController, didRequestLiveLocationPresentationForBubbleData bubbleData: MXKRoomBubbleCellDataStoring) {
        //
    }
    
    func roomViewControllerDidStopLiveLocationSharing(_ roomViewController: RoomViewController, beaconInfoEventId: String?) {
        //
    }

    func roomViewController(_ roomViewController: RoomViewController, showRoomWithId roomID: String, eventId eventID: String?) {
        //
    }
    
    func roomViewController(_ roomViewController: RoomViewController,
                            didReplaceRoomWithReplacementId roomID: String) {
        //
    }
    
    func roomViewController(_ roomViewController: RoomViewController, endPollWithEventIdentifier eventIdentifier: String) {
        //
    }
    
    func roomViewControllerShowRoomDetails(_ roomViewController: RoomViewController) {
        //
    }
    
    func roomViewControllerDidLeaveRoom(_ roomViewController: RoomViewController) {
        //
    }
    
    func roomViewControllerPreviewDidTapCancel(_ roomViewController: RoomViewController) {
        self.didCancel()
    }
    
    func roomViewControllerDidRequestPollCreationFormPresentation(_ roomViewController: RoomViewController) {
        //
    }
    
    func roomViewController(_ roomViewController: RoomViewController, showMemberDetails roomMember: MXRoomMember) {
        //
    }
    
    func roomViewController(_ roomViewController: RoomViewController, startChatWithUserId userId: String, completion: @escaping () -> Void) {
        //
    }
    
    func roomViewController(_ roomViewController: RoomViewController, showCompleteSecurityFor session: MXSession) {
        //
    }
    
    func roomViewController(_ roomViewController: RoomViewController, handleUniversalLinkWith parameters: UniversalLinkParameters) -> Bool {
        return false
    }
    
    func roomViewController(_ roomViewController: RoomViewController, canEditPollWithEventIdentifier eventIdentifier: String) -> Bool {
        return false
    }
    
    func roomViewController(_ roomViewController: RoomViewController, canEndPollWithEventIdentifier eventIdentifier: String) -> Bool {
        return false
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didRequestEditForPollWithStart startEvent: MXEvent) {
        //
    }
    
    func roomViewControllerDidRequestLocationSharingFormPresentation(_ roomViewController: RoomViewController) {
        //
    }
    
    func roomViewController(_ roomViewController: RoomViewController, didRequestLocationPresentationFor event: MXEvent, bubbleData: MXKRoomBubbleCellDataStoring) {
        //
    }
    
    func roomViewController(_ roomViewController: RoomViewController, locationShareActivityViewControllerFor event: MXEvent) -> UIActivityViewController? {
        return nil
    }
    
    func roomViewControllerDidStartLoading(_ roomViewController: RoomViewController) {
        //
    }

    func roomViewControllerDidStopLoading(_ roomViewController: RoomViewController) {
        //
    }

    func roomViewControllerDidStopLiveLocationSharing(_ roomViewController: RoomViewController) {
        //
    }

    func roomViewControllerDidTapLiveLocationSharingBanner(_ roomViewController: RoomViewController) {
        //
    }

    // Tchap: Disable Threads
//    func threadsCoordinator(for roomViewController: RoomViewController, threadId: String?) -> ThreadsCoordinatorBridgePresenter? {
//        return nil
//    }
}
