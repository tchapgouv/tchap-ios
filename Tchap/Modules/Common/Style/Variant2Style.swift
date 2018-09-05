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

/// UI component style variant 2
@objcMembers
final class Variant2Style: NSObject, Style {
    
    static let shared = Variant2Style()
    
    let statusBarStyle: UIStatusBarStyle = kVariant2StatusBarStyle
    
    let backgroundColor: UIColor = kVariant2PrimaryBgColor
    let separatorColor: UIColor = kVariant2ActionColor
    
    let primarySubTextColor: UIColor = kVariant2PrimarySubTextColor
    
    func applyStyle(onNavigationBar navigationBar: UINavigationBar) {
        navigationBar.barTintColor = kVariant2PrimaryBgColor
        navigationBar.tintColor = kVariant2ActionColor
        navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: kVariant2PrimaryTextColor]
    }
    
    func applyStyle(onButton button: UIButton) {
        button.setTitleColor(kVariant2ActionColor, for: .normal)
    }
    
    func applyStyle(onTextField textField: UITextField) {
        textField.textColor = kVariant2PrimaryTextColor
        textField.tintColor = kVariant2PlaceholderTextColor
    }
}
