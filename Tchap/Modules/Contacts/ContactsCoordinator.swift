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

final class ContactsCoordinator: NSObject, ContactsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let contactsViewController: ContactsTableViewController
    private let session: MXSession
    private let contactsDataSource: ContactsDataSource
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private let contactsErrorPresenter: ErrorPresenter
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(router: NavigationRouterType, session: MXSession) {
        self.router = router
        self.session = session
        
        self.contactsViewController = ContactsTableViewController.instantiate()
        
        self.contactsDataSource = ContactsDataSource(matrixSession: self.session)
        self.contactsDataSource.finalizeInitialization()
        self.contactsDataSource.contactsFilter = ContactsDataSourceTchapFilterTchapOnly
        
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        self.contactsErrorPresenter = AlertErrorPresenter(viewControllerPresenter: contactsViewController)
    }
    
    // MARK: - Public methods
    
    func start() {
        self.contactsViewController.displayList(self.contactsDataSource)
        self.contactsViewController.contactsTableViewControllerDelegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.contactsViewController
    }
    
    func updateSearchText(_ searchText: String?) {
        self.contactsDataSource.search(withPattern: searchText, forceReset: false)
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
        self.activityIndicatorPresenter.presentActivityIndicator(on: self.contactsViewController.view, animated: true)
        
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
                sself.contactsErrorPresenter.present(errorPresentable: errorPresentable, animated: true)
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
}

// MARK: - ContactsTableViewControllerDelegate
extension ContactsCoordinator: ContactsTableViewControllerDelegate {
    
    func contactsTableViewController(_ contactsTableViewController: ContactsTableViewController!, didSelect contact: MXKContact!) {
        // Check whether the selected contact is a Tchap user.
        guard let contact = contact, !contact.matrixIdentifiers.isEmpty else {
            return
        }
        
        // No more than one matrix identifer is expected by contact in Tchap.
        guard contact.matrixIdentifiers.count == 1, let userID = contact.matrixIdentifiers.first as? String else {
            print("[ContactsCoordinator] Invalid selected contact: multiple matrix ids")
            return
        }
        
        self.activityIndicatorPresenter.presentActivityIndicator(on: self.contactsViewController.view, animated: true)
        
        let discussionService = DiscussionService(session: session)
        discussionService.getDiscussionIdentifier(for: userID) { [weak self] response in
            guard let sself = self else {
                return
            }
            
            sself.activityIndicatorPresenter.removeCurrentActivityIndicator(animated: true)
            
            switch response {
            case .success(let roomID):
                if let roomID = roomID {
                    if let room = sself.session.room(withRoomId: roomID) {
                        // Check whether this is a pending invite
                        if room.summary.membership == .invite {
                            // Accept this invite
                            sself.joinRoom(with: roomID)
                        } else {
                            // Open the current discussion
                            sself.showRoom(with: roomID)
                        }
                    } else {
                        // Unexpected case where we fail to retrieve the room for the returned id
                        let errorPresentable = ErrorPresentableImpl.init(title: TchapL10n.errorTitleDefault, message: TchapL10n.errorMessageDefault)
                        sself.contactsErrorPresenter.present(errorPresentable: errorPresentable, animated: true)
                    }
                } else {
                    //TODO: Display a fake room, create the discussion only when an event is sent (#41).
                }
            case .failure(let error):
                let errorPresentable = sself.openDiscussionErrorPresentable(from: error)
                sself.contactsErrorPresenter.present(errorPresentable: errorPresentable, animated: true)
            }
        }
    }
}
