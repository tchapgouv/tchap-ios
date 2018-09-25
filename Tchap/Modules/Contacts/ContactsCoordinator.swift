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

protocol ContactsCoordinatorDelegate: class {
    func contactsCoordinator(_ coordinator: ContactsCoordinatorType, didSelectRoomID roomID: String)
    func contactsCoordinator(_ coordinator: ContactsCoordinatorType, didSelectUserID userID: String)
}

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
    
    weak var delegate: ContactsCoordinatorDelegate?
    
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
    
    private func didSelectUserID(_ userID: String) {
        self.activityIndicatorPresenter.presentActivityIndicator(on: self.contactsViewController.view, animated: true)
        
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
                    sself.delegate?.contactsCoordinator(sself, didSelectRoomID: roomID)
                case .noDiscussion:
                    // Let the delegate handle this user for who no discussion exists.
                    sself.delegate?.contactsCoordinator(sself, didSelectUserID: userID)
                default:
                    break
                }
            case .failure(let error):
                let errorPresentable = sself.openDiscussionErrorPresentable(from: error)
                sself.contactsErrorPresenter.present(errorPresentable: errorPresentable, animated: true)
            }
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
        
        self.didSelectUserID(userID)
    }
}
