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

import Foundation

protocol RoomDetailsCoordinatorDelegate: class {
    func roomDetailsCoordinator(_ coordinator: RoomDetailsCoordinatorType, mention member: MXRoomMember)
    func roomDetailsCoordinator(_ coordinator: RoomDetailsCoordinatorType, didSelectRoomID roomID: String)
    func roomDetailsCoordinator(_ coordinator: RoomDetailsCoordinatorType, didSelectUserID userID: String)
}

final class RoomDetailsCoordinator: NSObject, RoomDetailsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let session: MXSession
    private let roomID: String
    
    private let segmentedViewController: SegmentedViewController
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let errorPresenter: ErrorPresenter
    private let roomTitleViewModelBuilder: RoomTitleViewModelBuilder
    
    private weak var roomDetailsTitleView: RoomTitleView?
    
    // MARK: Public
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: RoomDetailsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(router: NavigationRouterType, session: MXSession, roomID: String) {
        self.router = router
        self.session = session
        self.roomID = roomID
        
        self.segmentedViewController = SegmentedViewController.instantiate()
        
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = AlertErrorPresenter(viewControllerPresenter: self.segmentedViewController)
        self.roomTitleViewModelBuilder = RoomTitleViewModelBuilder(session: self.session)
    }
    
    // MARK: - Public methods
    
    func start() {
        guard let room = session.room(withRoomId: roomID) else {
            fatalError("[RoomDetailsCoordinator] The room is unknown")
        }
        
        let viewControllers: [UIViewController]
        let titles: [String]
        
        // Files tab
        guard let roomFilesViewController = RoomFilesViewController.instantiate() else {
            fatalError("[RoomDetailsCoordinator] Files tab could not be loaded")
        }
        
        // Only the files tab is displayed in case of a direct chat (discussion)
        if room.isDirect {
            viewControllers = [roomFilesViewController]
            titles = [TchapL10n.roomFilesTabTitle]
        } else {
            // We add a tab for the participants list and another for the room settings
            guard let participantsViewController = RoomParticipantsViewController.instantiate(),
                let settingsViewController = RoomSettingsViewController.instantiate() else {
                    fatalError("[RoomDetailsCoordinator] Participants or Settings tab could not be loaded")
            }
            
            viewControllers = [participantsViewController, roomFilesViewController, settingsViewController]
            titles = [TchapL10n.roomMembersTabTitle, TchapL10n.roomFilesTabTitle, TchapL10n.roomSettingsTabTitle]
            
            // Prepare members tab
            participantsViewController.delegate = self
            participantsViewController.enableMention = true
            participantsViewController.mxRoom = room
            
            // Prepare settings tab
            settingsViewController.initWith(self.session, andRoomId: self.roomID)
        }
        
        // Prepare files tab
        // @TODO (async-state): This call should be synchronous. Every thing will be fine
        MXKRoomDataSource.load(withRoomId: self.roomID, andMatrixSession: self.session) { roomFilesDataSource in
            guard let roomFilesDataSource = roomFilesDataSource as? MXKRoomDataSource else {
                return
            }
            roomFilesDataSource.filterMessagesWithURL = true
            roomFilesDataSource.finalizeInitialization()
            // Give the data source ownership to the room files view controller.
            roomFilesViewController.hasRoomDataSourceOwnership = true
            roomFilesViewController.displayRoom(roomFilesDataSource)
        }
        
        self.segmentedViewController.initWithTitles(titles, viewControllers: viewControllers, defaultSelected: 0)
        self.segmentedViewController.addMatrixSession(self.session)
        self.segmentedViewController.update(with: Variant2Style.shared)
        
        let titleView = RoomTitleView.instantiate()
        self.segmentedViewController.navigationItem.titleView = titleView
        self.roomDetailsTitleView = titleView
        
        if let roomSummary = room.summary {
            self.updateRoomDetailsTitleView(with: roomSummary)
        }
        
        self.registerRoomSummaryDidChangeNotification()
    }
    
    func toPresentable() -> UIViewController {
        return self.segmentedViewController
    }
    
    // MARK: - Private methods
    
    private func didSelectUserID(_ userID: String, completion: (() -> Void)?) {
        self.activityIndicatorPresenter.presentActivityIndicator(on: self.segmentedViewController.view, animated: true)
        
        let discussionService = DiscussionService(session: session)
        discussionService.getDiscussionIdentifier(for: userID) { [weak self] response in
            guard let sself = self else {
                return
            }
            
            sself.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            
            switch response {
            case .success(let result):
                switch result {
                case .joinedDiscussion(let roomID):
                    // Open the current discussion
                    sself.delegate?.roomDetailsCoordinator(sself, didSelectRoomID: roomID)
                case .noDiscussion:
                    // Let the delegate handle this user for who no discussion exists.
                    sself.delegate?.roomDetailsCoordinator(sself, didSelectUserID: userID)
                default:
                    break
                }
            case .failure(let error):
                let errorPresentable = sself.openDiscussionErrorPresentable(from: error)
                sself.errorPresenter.present(errorPresentable: errorPresentable, animated: true)
            }
            
            completion?()
        }
    }
    
    private func openDiscussionErrorPresentable(from error: Error) -> ErrorPresentable {
        let errorTitle: String = TchapL10n.errorTitleDefault
        let errorMessage: String
        
        let nsError = error as NSError
        
        if let message = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
            errorMessage = message
        } else {
            errorMessage = TchapL10n.errorMessageDefault
        }
        
        return ErrorPresentableImpl(title: errorTitle, message: errorMessage)
    }
    
    private func registerRoomSummaryDidChangeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(roomSummeryDidChange(notification:)), name: NSNotification.Name.mxRoomSummaryDidChange, object: nil)
    }
    
    @objc private func roomSummeryDidChange(notification: Notification) {
        guard let roomSummary = notification.object as? MXRoomSummary else {
            return
        }
        if roomSummary.roomId == roomID {
            self.updateRoomDetailsTitleView(with: roomSummary)
        }
    }
    
    private func updateRoomDetailsTitleView(with roomSummary: MXRoomSummary) {
        guard let roomTitleView = self.roomDetailsTitleView else {
            return
        }
        let roomTitleViewModel = self.roomTitleViewModelBuilder.build(fromRoomSummary: roomSummary)
        roomTitleView.fill(roomTitleViewModel: roomTitleViewModel)
    }
}

// MARK: - RoomParticipantsViewControllerDelegate
extension RoomDetailsCoordinator: RoomParticipantsViewControllerDelegate {
    func roomParticipantsViewController(_ roomParticipantsViewController: RoomParticipantsViewController!, mention member: MXRoomMember!) {
        self.delegate?.roomDetailsCoordinator(self, mention: member)
    }
    
    func roomParticipantsViewController(_ roomParticipantsViewController: RoomParticipantsViewController!, startChatWithMemberId matrixId: String!, completion: (() -> Void)?) {
        self.didSelectUserID(matrixId, completion: completion)
    }
}
