/*
 Copyright 2019 New Vector Ltd
 
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

import UIKit

final class MigrateToNewTchapCoordinator: MigrateToNewTchapCoordinatorType {
    
    // MARK: Constant
    
    private enum Constants {        
        static let nextTchapAppStoreAppURL = "https://apps.apple.com/fr/app/tchap-x/id6736991029"
        static let nextTchapHelpURL = "https://app.crisp.chat/website/6dacc68e-de3a-4511-8177-1339616098de/helpdesk/articles/fr/45a1de71-1093-4392-ab09-c88a6338c181/"
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let rootRouter: RootRouterType
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: MigrateToNewTchapCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(rootRouter: RootRouterType) {
        self.rootRouter = rootRouter
    }
    
    // MARK: - Public methods
    
    func start() {
        let migrateToNewTchapViewModel = MigrateToNewTchapViewModel(
            appStoreAppUrl: URL(string: Constants.nextTchapAppStoreAppURL)!, // swiftlint:disable:this force_unwrapping
            helpArticleUrl: URL(string: Constants.nextTchapHelpURL)!, // swiftlint:disable:this force_unwrapping
            actionCancel: { [weak self] in
            self?.migrateToNewTchapViewControllerDidTapSkipAction()
        })
        
        let migrateToNewTchapViewController = MigrateToNewTchapViewController.instantiate(with: migrateToNewTchapViewModel)
        
        self.rootRouter.presentModule(migrateToNewTchapViewController, animated: true, completion: nil)
    }
}

// MARK: - delegate
extension MigrateToNewTchapCoordinator {
    
    func migrateToNewTchapViewControllerDidTapSkipAction() {
        self.rootRouter.dismissModule(animated: true) {
            self.delegate?.migrateToNewTchapCoordinatorDidCancel(self)
        }
    }
}
