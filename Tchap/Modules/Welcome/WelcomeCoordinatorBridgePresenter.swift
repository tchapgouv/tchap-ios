// 
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// WelcomeCoordinatorBridgePresenter enables to start WelcomeCoordinator from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// **WARNING**: This class breaks the Coordinator abstraction and it has been introduced for **Objective-C compatibility only** (mainly for integration in legacy view controllers). Each bridge should be removed
/// once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class WelcomeCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Constants
    
    private enum NavigationType {
        case present
        case push
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var navigationType: NavigationType = .present
    private var coordinator: WelcomeCoordinator?
    
    // MARK: Public
    
    var completion: (() -> Void)?
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        let welcomeCoordinator = makeWelcomeCoordinator()
        
        let presentable = welcomeCoordinator.toPresentable()
        presentable.modalPresentationStyle = .fullScreen
        presentable.modalTransitionStyle = .crossDissolve
        
        viewController.present(presentable, animated: animated, completion: nil)
        welcomeCoordinator.start()
        
        self.coordinator = welcomeCoordinator
        self.navigationType = .present
    }
    
    func push(from navigationController: UINavigationController, animated: Bool) {
                
        let navigationRouter = NavigationRouterStore.shared.navigationRouter(for: navigationController)
        
        let welcomeCoordinator = makeWelcomeCoordinator(navigationRouter: navigationRouter)

        welcomeCoordinator.start() // Will trigger the view controller push
        
        self.coordinator = welcomeCoordinator
        self.navigationType = .push
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }

        switch navigationType {
        case .present:
            // Dismiss modal
            coordinator.toPresentable().dismiss(animated: animated) {
                self.coordinator = nil

                if let completion = completion {
                    completion()
                }
            }
        case .push:
            // Pop view controller from UINavigationController
            guard let navigationController = coordinator.toPresentable() as? UINavigationController else {
                return
            }
            navigationController.popViewController(animated: animated)
            self.coordinator = nil

            if let completion = completion {
                completion()
            }
        }
    }
    
    // MARK: - Private
    
    /// Makes an `WelcomeCoordinator` using the supplied navigation router, or creating one if needed.
    private func makeWelcomeCoordinator(navigationRouter: NavigationRouterType? = nil) -> WelcomeCoordinator {
        let welcomeCoordinator = WelcomeCoordinator()
        welcomeCoordinator.delegate = self
        return welcomeCoordinator
    }
}

// MARK: - WelcomeCoordinatorDelegate
extension WelcomeCoordinatorBridgePresenter: WelcomeCoordinatorDelegate {
    func welcomeCoordinatorUserDidAuthenticate(_ coordinator: WelcomeCoordinatorType) {
        self.completion?()
    }
}
