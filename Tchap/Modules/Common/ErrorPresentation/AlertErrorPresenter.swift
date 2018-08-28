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

/// Used to present error as alert on a view controller
final class AlertErrorPresenter: ErrorPresenter {
    
    // MARK: - Properties
    
    private weak var viewControllerPresenter: UIViewController?
    private weak var currentAlertController: UIAlertController?
    
    // MARK: - Setup
    
    init(viewControllerPresenter: UIViewController) {
        self.viewControllerPresenter = viewControllerPresenter
    }
    
    // MARK: - Public
    
    func present(errorPresentable: ErrorPresentable, animated: Bool = true) {
        guard let viewController = self.viewControllerPresenter else {
            return
        }
        self.present(errorPresentable: errorPresentable, from: viewController, animated: animated)
    }
    
    // MARK: - Private
    
    private func present(errorPresentable: ErrorPresentable,
                         from viewController: UIViewController,
                         animated: Bool = true) {
        
        if let currentAlertController = self.currentAlertController {
            currentAlertController.dismiss(animated: false, completion: nil)
        }
        
        let alert = UIAlertController(title: errorPresentable.title, message: errorPresentable.message, preferredStyle: .alert)
        
        let okTitle = Bundle.mxk_localizedString(forKey: "ok")
        let okAction = UIAlertAction(title: okTitle, style: .default, handler: nil)
        alert.addAction(okAction)
        
        self.currentAlertController = alert
        
        viewController.present(alert, animated: animated, completion: nil)
    }
}
