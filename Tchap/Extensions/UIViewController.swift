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

import UIKit

extension UIViewController {
    
    /// Remove back bar button title when pushing a view controller
    /// This method should be called on the previous controller in UINavigationController stack
    func tc_removeBackTitle() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
        
    func tc_addChildViewController(viewController: UIViewController) {
        self.tc_addChildViewController(viewController: viewController, onView: self.view)
    }
    
    func tc_addChildViewController(viewController: UIViewController, onView view: UIView) {
        self.addChild(viewController)
        
        viewController.view.frame = view.bounds
        view.tc_addSubViewMatchingParent(viewController.view)
        viewController.didMove(toParent: self)
    }
    
    func tc_removeChildViewController(viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    func tc_removeFromParent() {
        self.tc_removeChildViewController(viewController: self)
    }
}
