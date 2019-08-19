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

protocol CreateNewDiscussionCoordinatorDelegate: class {
    func createNewDiscussionCoordinator(_ coordinator: CreateNewDiscussionCoordinatorType, didSelectUserID userID: String)
    func createNewDiscussionCoordinatorDidCancel(_ coordinator: CreateNewDiscussionCoordinatorType)
}

final class CreateNewDiscussionCoordinator: NSObject, CreateNewDiscussionCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let router: NavigationRouterType
    private let contactsViewController: ContactsViewController
    private let session: MXSession
    private let contactsDataSource: ContactsDataSource
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: CreateNewDiscussionCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.router = NavigationRouter(navigationController: TCNavigationController())
        self.session = session
        
        let contactsViewController = ContactsViewController.instantiate(with: Variant1Style.shared, showSearchBar: true, enableMultipleSelection: false)
        contactsViewController.title = TchapL10n.createNewDiscussionTitle
        self.contactsViewController = contactsViewController
        
        let contactsDataSource: ContactsDataSource = ContactsDataSource(matrixSession: self.session)
        contactsDataSource.finalizeInitialization()
        contactsDataSource.contactsFilter = ContactsDataSourceTchapFilterTchapUsersOnly
        self.contactsDataSource = contactsDataSource
        
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        self.contactsViewController.displayList(self.contactsDataSource)
        self.contactsViewController.delegate = self
        self.router.setRootModule(self.contactsViewController)
        
        self.contactsViewController.navigationItem.leftBarButtonItem = MXKBarButtonItem(title: TchapL10n.actionCancel, style: .plain) { [weak self] in
            self?.didCancel()
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.router.toPresentable()
    }
    
    // MARK: - Private
    
    private func didSelectUserID(_ userID: String) {
        self.delegate?.createNewDiscussionCoordinator(self, didSelectUserID: userID)
    }
    
    private func didCancel() {
        self.delegate?.createNewDiscussionCoordinatorDidCancel(self)
    }
}

// MARK: - ContactsViewControllerDelegate
extension CreateNewDiscussionCoordinator: ContactsViewControllerDelegate {
    
    func contactsViewController(_ contactsViewController: ContactsViewController, didSelect contact: MXKContact) {
        // No more than one matrix identifer is expected by contact in Tchap.
        guard contact.matrixIdentifiers.count == 1, let userID = contact.matrixIdentifiers.first as? String else {
            print("[CreateNewDiscussionCoordinator] Invalid selected contact: multiple matrix ids")
            return
        }
        
        self.didSelectUserID(userID)
    }
}
