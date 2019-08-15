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
    func contactsCoordinator(_ coordinator: ContactsCoordinatorType, didSelectUserID userID: String)
    func contactsCoordinator(_ coordinator: ContactsCoordinatorType, sendEmailInviteTo email: String)
}

final class ContactsCoordinator: NSObject, ContactsCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let contactsViewController: ContactsViewController
    private let session: MXSession
    private let contactsDataSource: ContactsDataSource
    
    private let userService: UserServiceType
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ContactsCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(router: NavigationRouterType, session: MXSession) {
        self.router = router
        self.session = session
        
        self.contactsViewController = ContactsViewController.instantiate(with: Variant1Style.shared)
        
        self.contactsDataSource = ContactsDataSource(matrixSession: self.session)
        self.contactsDataSource.finalizeInitialization()
        self.contactsDataSource.contactsFilter = ContactsDataSourceTchapFilterTchapUsersOnly
        
        self.userService = UserService(session: session)
        
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        self.contactsViewController.displayList(self.contactsDataSource)
        self.contactsViewController.delegate = self
        
        // Display the invite button at the top of the contacts list, except if the current user is an external users.
        // Check whether the current user is available
        if let myUserId = session.myUser?.userId {
            self.contactsDataSource.showInviteButton = !self.userService.isExternalUser(for: myUserId)
        } else {
            self.registerSessionStateNotification()
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.contactsViewController
    }
    
    func updateSearchText(_ searchText: String?) {
        self.contactsDataSource.search(withPattern: searchText, forceReset: false)
    }

    // MARK: - Private
    
    private func registerSessionStateNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(sessionStateDidChange), name: NSNotification.Name.mxSessionStateDidChange, object: nil)
    }
    
    private func unregisterSessionStateNotification() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.mxSessionStateDidChange, object: nil)
    }
    
    @objc private func sessionStateDidChange() {
        // Check whether the current user id is available
        if let myUserId = self.session.myUser?.userId {
            self.unregisterSessionStateNotification()
            self.contactsDataSource.showInviteButton = !self.userService.isExternalUser(for: myUserId)
        }
    }
    
    private func didSelectUserID(_ userID: String) {
        self.delegate?.contactsCoordinator(self, didSelectUserID: userID)
    }
}

// MARK: - ContactsViewControllerDelegate
extension ContactsCoordinator: ContactsViewControllerDelegate {
    
    func contactsViewController(_ contactsViewController: ContactsViewController, didSelect contact: MXKContact) {
        // No more than one matrix identifer is expected by contact in Tchap.
        guard contact.matrixIdentifiers.count == 1, let userID = contact.matrixIdentifiers.first as? String else {
            print("[ContactsCoordinator] Invalid selected contact: multiple matrix ids")
            return
        }

        self.didSelectUserID(userID)
    }
    
    func contactsViewController(_ contactsViewController: ContactsViewController, sendEmailInviteTo email: String) {
        self.delegate?.contactsCoordinator(self, sendEmailInviteTo: email)
    }
}
