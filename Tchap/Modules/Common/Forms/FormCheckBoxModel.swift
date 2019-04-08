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

import Foundation
import UIKit

/// `FormCheckBoxModel` implementation representing a form check box view model
final class FormCheckBoxModel: FormCheckBoxModelType {
    
    // MARK: - Properties
    
    let label: String
    let labelLink: String?
    var isSelected: Bool
    
    // MARK: - Setup
    
    init(label: String,
         labelLink: String? = nil,
         isSelected: Bool = false) {
        self.label = label
        self.labelLink = labelLink
        self.isSelected = isSelected
    }
}
