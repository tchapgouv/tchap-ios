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

final class ContactsCoordinator: RoomsCoordinatorType {
    
    private let contactsViewController: PeopleViewController
    private let session: MXSession
    private let recentsDataSource: RecentsDataSource
    
    var childCoordinators: [Coordinator] = []
    
    init(session: MXSession) {
        self.session = session
        
        self.contactsViewController = PeopleViewController.instantiate()
        self.recentsDataSource = RecentsDataSource(matrixSession: self.session)
        self.recentsDataSource.setDelegate(self.contactsViewController, andRecentsDataSourceMode: RecentsDataSourceModePeople)
    }
    
    func start() {
        self.contactsViewController.displayList(self.recentsDataSource)
    }
    
    func toPresentable() -> UIViewController {
        return self.contactsViewController
    }
}
