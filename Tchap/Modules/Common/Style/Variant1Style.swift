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

/// UI component style variant 1
@objcMembers
final class Variant1Style: NSObject, Style {
    
    static let shared = Variant1Style()
    
    // MARK: - Status bar
    
    let statusBarStyle: UIStatusBarStyle = kVariant1StatusBarStyle
    
    // MARK: - Bar
    
    let barBackgroundColor: UIColor = kVariant1BarBgColor
    let barTitleColor: UIColor = kVariant1BarTitleColor
    let barSubTitleColor: UIColor = kVariant1BarSubTitleColor
    let barActionColor: UIColor = kVariant1BarActionColor
    
    // MARK: - Button
    
    let buttonBorderedTitleColor: UIColor = kVariant1ButtonBorderedTitleColor
    let buttonBorderedBackgroundColor: UIColor = kVariant1ButtonBorderedBgColor
    let buttonPlainTitleColor: UIColor = kVariant1ButtonPlainTitleColor
    let buttonPlainBackgroundColor: UIColor = kVariant1ButtonPlainBgColor
    
    // MARK: - Body
    
    let backgroundColor: UIColor = kVariant1PrimaryBgColor
    let secondaryBackgroundColor: UIColor = kVariant1SecondaryBgColor
    
    let separatorColor: UIColor = kVariant1SeparatorColor
    
    let primaryTextColor: UIColor = kVariant1PrimaryTextColor
    let primarySubTextColor: UIColor = kVariant1PrimarySubTextColor
    let secondaryTextColor: UIColor = kVariant1SecondaryTextColor
    let warnTextColor: UIColor = kVariant1WarnTextColor
    
    let presenceIndicatorOnlineColor: UIColor = kVariant1PresenceIndicatorOnlineColor
    
    // MARK: - Commodity methods
    
    func applyStyle(onNavigationBar navigationBar: UINavigationBar) {
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = self.barBackgroundColor
        navigationBar.tintColor = self.barActionColor
        navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: self.barTitleColor]
    }
    
    func applyStyle(onButton button: UIButton, bordered: Bool = false) {
        
        let titleColor: UIColor
        let backgroundColor: UIColor
        
        if bordered {
            titleColor = self.buttonBorderedTitleColor
            backgroundColor = self.buttonBorderedBackgroundColor
        } else {
            titleColor = self.buttonPlainTitleColor
            backgroundColor = self.buttonPlainBackgroundColor
        }
        
        button.setTitleColor(titleColor, for: .normal)
        button.setTitleColor(.lightGray, for: .highlighted)
        button.backgroundColor = backgroundColor
    }
    
    func applyStyle(onTextField textField: UITextField) {
        textField.textColor = self.primaryTextColor
        textField.tintColor = self.primaryTextColor
    }
    
    func applyStyle(onSwitch uiSwitch: UISwitch) {
        uiSwitch.onTintColor = self.barBackgroundColor
    }
}
