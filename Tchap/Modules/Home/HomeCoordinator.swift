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

protocol HomeCoordinatorDelegate: class {
    func homeCoordinator(_ coordinator: HomeCoordinatorType, reloadMatrixSessionsByClearingCache clearCache: Bool)
}

final class HomeCoordinator: NSObject, HomeCoordinatorType {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    
    private weak var roomsCoordinator: RoomsCoordinatorType?
    private weak var contactsCoordinator: ContactsCoordinatorType?
    
    // MARK: Public
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: HomeCoordinatorDelegate?
    
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
    
    func showRoom(with roomID: String, onEventID eventID: String? = nil) {
        let roomCoordinator = RoomCoordinator(router: self.navigationRouter, session: self.session, roomID: roomID, eventID: eventID)
        roomCoordinator.start()
        roomCoordinator.delegate = self
        
        self.navigationRouter.popToRootModule(animated: false)
        
        self.add(childCoordinator: roomCoordinator)
        self.navigationRouter.push(roomCoordinator, animated: true) {
            self.remove(childCoordinator: roomCoordinator)
        }
    }
    
    // MARK: - Private methods
    
    private func showSettings(animated: Bool) {
        let settingsCoordinator = SettingsCoordinator(router: self.navigationRouter)
        settingsCoordinator.start()
        settingsCoordinator.delegate = self
        
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
        publicRoomsCoordinator.start()
        self.add(childCoordinator: publicRoomsCoordinator)
        self.navigationRouter.present(publicRoomsCoordinator, animated: true)
        publicRoomsCoordinator.delegate = self
    }
    
    // Prepare a new discussion with a user without associated room
    private func startDiscussion(with userID: String) {
        let roomCoordinator = RoomCoordinator(router: self.navigationRouter, session: self.session, discussionTargetUserID: userID)
        roomCoordinator.start()
        
        self.navigationRouter.push(roomCoordinator, animated: true, popCompletion: { [weak self] in
            self?.remove(childCoordinator: roomCoordinator)
        })
        
        self.add(childCoordinator: roomCoordinator)
    }
    
    private func showCreateNewDiscussion() {
        let createNewDiscussionCoordinator = CreateNewDiscussionCoordinator(session: self.session)
        createNewDiscussionCoordinator.delegate = self
        createNewDiscussionCoordinator.start()
        
        self.navigationRouter.present(createNewDiscussionCoordinator, animated: true)
        
        self.add(childCoordinator: createNewDiscussionCoordinator)
    }
    
    private func showCreateNewRoom() {
        let roomCreationCoordinator = RoomCreationCoordinator(session: self.session)
        roomCreationCoordinator.delegate = self
        roomCreationCoordinator.start()
        
        self.navigationRouter.present(roomCreationCoordinator, animated: true)
        
        self.add(childCoordinator: roomCreationCoordinator)
    }
}

// MARK: - SettingsCoordinatorDelegate
extension HomeCoordinator: SettingsCoordinatorDelegate {
    func settingsCoordinator(_ coordinator: SettingsCoordinatorType, reloadMatrixSessionsByClearingCache clearCache: Bool) {
        self.navigationRouter.popToRootModule(animated: false)
        self.delegate?.homeCoordinator(self, reloadMatrixSessionsByClearingCache: clearCache)
    }
}

// MARK: - GlobalSearchBarDelegate
extension HomeCoordinator: GlobalSearchBarDelegate {
    func globalSearchBar(_ globalSearchBar: GlobalSearchBar, textDidChange searchText: String?) {
        self.roomsCoordinator?.updateSearchText(searchText)
        self.contactsCoordinator?.updateSearchText(searchText)
    }
}

// MARK: - RoomsCoordinatorDelegate
extension HomeCoordinator: RoomsCoordinatorDelegate {
    func roomsCoordinator(_ coordinator: RoomsCoordinatorType, didSelectRoomID roomID: String) {
        self.showRoom(with: roomID)
    }
}

// MARK: - ContactsCoordinatorDelegate
extension HomeCoordinator: ContactsCoordinatorDelegate {
    
    func contactsCoordinator(_ coordinator: ContactsCoordinatorType, didSelectUserID userID: String) {
        self.startDiscussion(with: userID)
    }
}

// MARK: - RoomCoordinatorDelegate
extension HomeCoordinator: RoomCoordinatorDelegate {
    func roomCoordinator(_ coordinator: RoomCoordinatorType, didSelectRoomID roomID: String) {
        self.showRoom(with: roomID)
    }
    
    func roomCoordinator(_ coordinator: RoomCoordinatorType, didSelectUserID userID: String) {
        self.startDiscussion(with: userID)
    }
}
        
// MARK: - HomeViewControllerDelegate
extension HomeCoordinator: HomeViewControllerDelegate {
    
    func homeViewControllerDidTapStartChatButton(_ homeViewController: HomeViewController) {
        self.showCreateNewDiscussion()
    }
    
    func homeViewControllerDidTapCreateRoomButton(_ homeViewController: HomeViewController) {
        self.showCreateNewRoom()
    }
    
    func homeViewControllerDidTapPublicRoomsAccessButton(_ homeViewController: HomeViewController) {
        self.showPublicRooms()
    }
}

// MARK: - PublicRoomsCoordinatorDelegate
extension HomeCoordinator: PublicRoomsCoordinatorDelegate {
    
    func publicRoomsCoordinator(_ publicRoomsCoordinator: PublicRoomsCoordinator, showRoomWithId roomId: String, onEventId eventId: String?) {
        self.navigationRouter.dismissModule(animated: true) { [weak self] in
            self?.remove(childCoordinator: publicRoomsCoordinator)
            self?.showRoom(with: roomId, onEventID: eventId)
        }
    }
    
    func publicRoomsCoordinatorDidCancel(_ publicRoomsCoordinator: PublicRoomsCoordinator) {
        self.navigationRouter.dismissModule(animated: true) { [weak self] in
            self?.remove(childCoordinator: publicRoomsCoordinator)
        }
    }
}

// MARK: - CreateNewDiscussionCoordinatorDelegate
extension HomeCoordinator: CreateNewDiscussionCoordinatorDelegate {
    
    func createNewDiscussionCoordinator(_ coordinator: CreateNewDiscussionCoordinatorType, didSelectUserID userID: String) {
        self.navigationRouter.dismissModule(animated: true) { [weak self] in
            self?.startDiscussion(with: userID)
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    func createNewDiscussionCoordinatorDidCancel(_ coordinator: CreateNewDiscussionCoordinatorType) {
        self.navigationRouter.dismissModule(animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
}

// MARK: - RoomCreationCoordinatorDelegate
extension HomeCoordinator: RoomCreationCoordinatorDelegate {
    
    func roomCreationCoordinatorDidCancel(_ coordinator: RoomCreationCoordinatorType) {
        self.navigationRouter.dismissModule(animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
    
    func roomCreationCoordinator(_ coordinator: RoomCreationCoordinatorType, didCreateRoomWithID roomID: String) {
        self.navigationRouter.dismissModule(animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
            self?.showRoom(with: roomID)
        }
    }
}
