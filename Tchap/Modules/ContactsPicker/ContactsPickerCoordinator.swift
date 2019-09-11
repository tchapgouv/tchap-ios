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

protocol ContactsPickerCoordinatorDelegate: class {
    // Two types of identifiers are supported here: Matrix ids and email addresses.
    func contactsPickerCoordinator(_ coordinator: ContactsPickerCoordinatorType, didSelectContactIdentifiers identifiers: [String])
}

final class ContactsPickerCoordinator: NSObject, ContactsPickerCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let contactsViewController: ContactsViewController
    private let session: MXSession
    private let contactsDataSource: ContactsDataSource
    private let activityIndicatorPresenter: ActivityIndicatorPresenterType
    private weak var validateBarButtonItem: UIBarButtonItem?
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: ContactsPickerCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, contactsFilter: ContactsDataSourceTchapFilter) {
        self.session = session
        
        let contactsViewController = ContactsViewController.instantiate(with: Variant1Style.shared, showSearchBar: true, enableMultipleSelection: true)
        contactsViewController.title = TchapL10n.contactsPickerTitle
        self.contactsViewController = contactsViewController
        
        let contactsDataSource: ContactsDataSource = ContactsDataSource(matrixSession: self.session)
        contactsDataSource.finalizeInitialization()
        contactsDataSource.contactsFilter = contactsFilter
        self.contactsDataSource = contactsDataSource
        
        self.activityIndicatorPresenter = ActivityIndicatorPresenter()
        
        super.init()
    }
    
    // MARK: - Public
    
    func start() {
        
        let validateBarButtonItem = MXKBarButtonItem(title: TchapL10n.actionValidate, style: .plain) { [weak self] in
            self?.validateSelection()
        }
        self.contactsViewController.navigationItem.rightBarButtonItem = validateBarButtonItem
        self.validateBarButtonItem = validateBarButtonItem
        
        self.contactsViewController.displayList(self.contactsDataSource)
        self.contactsViewController.delegate = self
    }
    
    func toPresentable() -> UIViewController {
        return self.contactsViewController
    }
    
    func updateSearchText(_ searchText: String?) {
        self.contactsDataSource.search(withPattern: searchText, forceReset: false)
    }
    
    func setPickerUserInteraction(enabled: Bool) {
        self.contactsViewController.view.isUserInteractionEnabled = enabled
        self.validateBarButtonItem?.isEnabled = enabled
    }
    
    // MARK: - Private
    
    private func validateSelection() {
        let selectedIdentifiers: [String]
        
        if let identifiers = self.contactsDataSource.selectedContactByIdentifier.allKeys as? [String] {
            selectedIdentifiers = identifiers
        } else {
            selectedIdentifiers = []
        }
        
        self.delegate?.contactsPickerCoordinator(self, didSelectContactIdentifiers: selectedIdentifiers)
    }    
}

// MARK: - ContactsViewControllerDelegate
extension ContactsPickerCoordinator: ContactsViewControllerDelegate {
    
    func contactsViewController(_ contactsViewController: ContactsViewController, didSelect contact: MXKContact) {
    }
}
