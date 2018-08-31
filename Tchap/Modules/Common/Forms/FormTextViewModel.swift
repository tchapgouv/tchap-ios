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
import UIKit

/// `FormTextViewModelType` implementation representing a form text field view model
final class FormTextViewModel: FormTextViewModelType {
    
    // MARK: - Properties
    
    var placeholder: String?
    var attributedPlaceholder: NSAttributedString?
    var additionalInfo: String?
    
    var value: String? {
        didSet {
            self.valueDidUpdate?(value)
        }
    }
    
    var valueMaximumCharacterLength: Int?
    
    var valueDidUpdate: ((String?) -> Void)?
    
    var isEditable: Bool
    
    var textInputProperties: TextInputProperties = TextInputProperties()
    
    // MARK: - Setup
    
    init(placeholder: String,
         additionalInfo: String? = nil,
         value: String? = nil,
         valueMaximumCharacterLength: Int? = nil,
         isEditable: Bool = true) {
        self.placeholder = placeholder
        self.additionalInfo = additionalInfo
        self.value = value
        self.valueMaximumCharacterLength = valueMaximumCharacterLength
        self.isEditable = isEditable
    }
    
    init(attributedPlaceholder: NSAttributedString,
         additionalInfo: String? = nil,
         value: String? = nil,
         valueMaximumCharacterLength: Int? = nil,
         isEditable: Bool = true) {
        self.attributedPlaceholder = attributedPlaceholder
        self.additionalInfo = additionalInfo
        self.value = value
        self.valueMaximumCharacterLength = valueMaximumCharacterLength
        self.isEditable = isEditable
    }
}
