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

/// Describe UI component style properties and commodity method to apply it
@objc protocol Style {
    
    var statusBarStyle: UIStatusBarStyle { get }
    
    var backgroundColor: UIColor { get }
    var secondaryBackgroundColor: UIColor { get }
    
    var separatorColor: UIColor { get }
    
    var primaryTextColor: UIColor { get }
    var primarySubTextColor: UIColor { get }
    var secondaryTextColor: UIColor { get }
    
    func applyStyle(onNavigationBar: UINavigationBar)
    func applyStyle(onButton: UIButton)
    func applyStyle(onTextField: UITextField)
}
