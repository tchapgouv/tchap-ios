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

import Foundation

final class SegmentedViewCoordinator: SegmentedViewCoordinatorType {        
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let navigationRouter: NavigationRouterType
    private let session: MXSession
    
    // MARK: Public
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.navigationRouter = NavigationRouter()
        self.session = session
    }
    
    // MARK: - Public methods
    
    func start() {
        let roomsCoordinator = RoomsCoordinator(session: self.session)
        let contactsCoordinator = ContactsCoordinator(session: self.session)
        
        self.add(childCoordinator: roomsCoordinator)
        self.add(childCoordinator: contactsCoordinator)
        
        let viewControllers = [roomsCoordinator.toPresentable(), contactsCoordinator.toPresentable()]
        
        let segmentedViewController = self.createSegmentedViewController(with: viewControllers)
        
        self.navigationRouter.setRootModule(segmentedViewController)
        
        roomsCoordinator.start()
        contactsCoordinator.start()
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
    
    // MARK: - Private methods
    
    private func showSettings(animated: Bool) {
        let settingsCoordinator = SettingsCoordinator(router: self.navigationRouter)
        settingsCoordinator.start()
        self.add(childCoordinator: settingsCoordinator)
        
        self.navigationRouter.push(settingsCoordinator, animated: animated, popCompletion: {
            self.remove(childCoordinator: settingsCoordinator)
        })
    }
    
    private func createSegmentedViewController(with viewControllers: [UIViewController]) -> SegmentedViewController {
        guard let segmentedViewController = SegmentedViewController.instantiate() else {
            fatalError("[SegmentedViewCoordinator] SegmentedViewController could not be loaded")
        }
        
        // TODO: Make a protocol to retrieve title from view controller
        let titles = ["Rooms", "Contact"]
        
        segmentedViewController.initWithTitles(titles, viewControllers: viewControllers, defaultSelected: 0)
        
        // Setup navigation bar
        
        segmentedViewController.navigationItem.leftBarButtonItem = MXKBarButtonItem(image: #imageLiteral(resourceName: "settings_icon"), style: .plain, action: { [weak self] in
            
            guard let sself = self else {
                return
            }
            
            sself.showSettings(animated: true)
        })
        
        return segmentedViewController
    }
}