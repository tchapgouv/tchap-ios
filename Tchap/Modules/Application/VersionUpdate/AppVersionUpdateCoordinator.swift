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

final class AppVersionUpdateCoordinator: AppVersionUpdateCoordinatorType {
    
    // MARK: Constant
    
    private enum Constants {        
        static let tchapItunesURL = "itms-apps://itunes.apple.com/app/apple-store/id1446253779?mt=8"
    }
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let rootRouter: RootRouterType
    private let versionInfo: ClientVersionInfo
    
    // MARK: Public
    
    var childCoordinators: [Coordinator] = []
    
    weak var delegate: AppVersionUpdateCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(rootRouter: RootRouterType, versionInfo: ClientVersionInfo) {
        self.rootRouter = rootRouter
        self.versionInfo = versionInfo
    }
    
    // MARK: - Public methods
    
    func start() {
        let appVersionUpdateViewModel = AppVersionUpdateViewModel(versionInfo: self.versionInfo)
        let appVersionUpdateViewController = AppVersionUpdateViewController.instantiate(with: appVersionUpdateViewModel)
        appVersionUpdateViewController.delegate = self
        
        // If opening the app is not possible set AppVersionUpdateViewController as the root view controller to prevent navigation into the app.
        if versionInfo.allowOpeningApp == false {
            self.rootRouter.setRootModule(appVersionUpdateViewController)
        } else {
            self.rootRouter.presentModule(appVersionUpdateViewController, animated: true, completion: nil)
        }
    }
}

// MARK: - AppVersionUpdateViewControllerDelegate
extension AppVersionUpdateCoordinator: AppVersionUpdateViewControllerDelegate {
    
    func appVersionUpdateViewControllerDidTapCancelAction(_ appVersionUpdateViewController: AppVersionUpdateViewController) {
        self.rootRouter.dismissModule(animated: true) {
            self.delegate?.appVersionUpdateCoordinatorDidCancel(self)
        }
    }
    
    func appVersionUpdateViewControllerDidTapOpenAppStoreAction(_ appVersionUpdateViewController: AppVersionUpdateViewController) {
        if let appURL = URL(string: Constants.tchapItunesURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
        }
    }
}
