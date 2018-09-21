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

final class SegmentedViewCoordinator: NSObject, SegmentedViewCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    
    private weak var roomsCoordinator: RoomsCoordinatorType?
    private weak var contactsCoordinator: ContactsCoordinatorType?
    
    // MARK: Public
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.navigationRouter = NavigationRouter(navigationController: TCNavigationController())
        self.session = session
    }
    
    // MARK: - Public methods
    
    func start() {
        let roomsCoordinator = RoomsCoordinator(router: self.navigationRouter, session: self.session)
        let contactsCoordinator = ContactsCoordinator(router: self.navigationRouter, session: self.session)
        
        roomsCoordinator.delegate = self
        contactsCoordinator.delegate = self
        
        self.add(childCoordinator: roomsCoordinator)
        self.add(childCoordinator: contactsCoordinator)
        
        let viewControllers = [roomsCoordinator.toPresentable(), contactsCoordinator.toPresentable()]
        let viewControllersTitles = [TchapL10n.conversationsTabTitle, TchapL10n.contactsTabTitle]
        
        let globalSearchBar = GlobalSearchBar.instantiate()
        globalSearchBar.delegate = self
        
        let segmentedViewController = self.createHomeViewController(with: viewControllers, viewControllersTitles: viewControllersTitles, globalSearchBar: globalSearchBar)
        segmentedViewController.tc_removeBackTitle()
        segmentedViewController.delegate = self
        
        self.navigationRouter.setRootModule(segmentedViewController)
        
        roomsCoordinator.start()
        contactsCoordinator.start()
        
        self.roomsCoordinator = roomsCoordinator
        self.contactsCoordinator = contactsCoordinator
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func showRoom(with roomID: String) {
        let roomCoordinator = RoomCoordinator(router: self.navigationRouter, session: self.session, roomID: roomID)
        roomCoordinator.start()
        
        self.navigationRouter.popToRootModule(animated: false)
        
        self.add(childCoordinator: roomCoordinator)
        self.navigationRouter.push(roomCoordinator, animated: true) {
            self.remove(childCoordinator: roomCoordinator)
        }
    }
    
    private func showSettings(animated: Bool) {
        let settingsCoordinator = SettingsCoordinator(router: self.navigationRouter)
        settingsCoordinator.start()
        
        self.add(childCoordinator: settingsCoordinator)
        self.navigationRouter.push(settingsCoordinator, animated: animated) {
            self.remove(childCoordinator: settingsCoordinator)
        }
    }
    
    private func createHomeViewController(with viewControllers: [UIViewController], viewControllersTitles: [String], globalSearchBar: GlobalSearchBar) -> HomeViewController {
        let homeViewController = HomeViewController.instantiate(with: viewControllers, viewControllersTitles: viewControllersTitles, globalSearchBar: globalSearchBar)
        
        homeViewController.navigationItem.leftBarButtonItem = MXKBarButtonItem(image: #imageLiteral(resourceName: "settings_icon"), style: .plain, action: { [weak self] in
            guard let sself = self else {
                return
            }
            sself.showSettings(animated: true)
        })
        
        return homeViewController
    }
    
    private func showPublicRooms() {
        let publicRoomsCoordinator = PublicRoomsCoordinator(session: self.session)
        self.add(childCoordinator: publicRoomsCoordinator)
        self.navigationRouter.present(publicRoomsCoordinator, animated: true)
        publicRoomsCoordinator.delegate = self
    }
}

// MARK: - GlobalSearchBarDelegate
extension SegmentedViewCoordinator: GlobalSearchBarDelegate {
    func globalSearchBar(_ globalSearchBar: GlobalSearchBar, textDidChange searchText: String?) {
        self.roomsCoordinator?.updateSearchText(searchText)
        self.contactsCoordinator?.updateSearchText(searchText)
    }
}

// MARK: - RoomsCoordinatorDelegate
extension SegmentedViewCoordinator: RoomsCoordinatorDelegate {
    func roomsCoordinator(_ coordinator: RoomsCoordinatorType, didSelectRoomID roomID: String) {
        self.showRoom(with: roomID)
    }
}

// MARK: - ContactsCoordinatorDelegate
extension SegmentedViewCoordinator: ContactsCoordinatorDelegate {
    func contactsCoordinator(_ coordinator: ContactsCoordinatorType, didSelectRoomID roomID: String) {
        self.showRoom(with: roomID)
    }
}

// MARK: - RoomCoordinatorDelegate
extension SegmentedViewCoordinator: RoomCoordinatorDelegate {
    func roomCoordinator(_ coordinator: RoomCoordinatorType, didSelectRoomID roomID: String) {
        self.showRoom(with: roomID)
    }
    
    func roomCoordinator(_ coordinator: RoomCoordinatorType, didSelectUserID userID: String) {
        //TODO Display a fake room, create the discussion only when an event is sent (#41).
    }
}
        
// MARK: - HomeViewControllerDelegate
extension SegmentedViewCoordinator: HomeViewControllerDelegate {
    
    func homeViewControllerDidTapStartChatButton(_ homeViewController: HomeViewController) {
        //TODO Open a contact picker with only Tchap users
    }
    
    func homeViewControllerDidTapCreateRoomButton(_ homeViewController: HomeViewController) {
        
    }
    
    func homeViewControllerDidTapPublicRoomsAccessButton(_ homeViewController: HomeViewController) {
        self.showPublicRooms()
    }
}

// MARK: - PublicRoomsCoordinatorDelegate
extension SegmentedViewCoordinator: PublicRoomsCoordinatorDelegate {
    
    func publicRoomsCoordinatorDidCancel(_ publicRoomsCoordinator: PublicRoomsCoordinator) {
        self.navigationRouter.dismissModule(animated: true) { [weak self] in
            self?.remove(childCoordinator: publicRoomsCoordinator)
        }
    }
}
