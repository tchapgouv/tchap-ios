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

/// Used set of default appearance of object conforming to UIAppearance protocol.
/// Use appearance in last resort, only when UI component cannot be customized directly.
struct Appearance {
    
    static func setup() {
        self.setupSearchBarAppearance()
    }
    
    // UISearchBar textColor could not be set directly
    static func setupSearchBarAppearance() {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, UINavigationBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: Variant1Style.shared.barActionColor]
        
        // Since iOS 11 UISearchController is set as navigationItem and displayed under UINavigationBar in UINavigationController
        if #available(iOS 11.0, *) {
            UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self, UINavigationController.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: Variant1Style.shared.barActionColor]
        }
    }
}
