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
            self.valueDidUpdate?(value, hasBeenAutoFilled)
        }
    }
    
    private (set) var hasBeenAutoFilled: Bool
    
    func updateValue(value: String?, comesFromAutoFill: Bool = false) {
        self.hasBeenAutoFilled = comesFromAutoFill
        self.value = value
    }
    
    var valueMinimumCharacterLength: Int?
    var valueMaximumCharacterLength: Int?
    
    var valueDidUpdate: ((_ newValue: String?, _ hasBeenAutoFilled: Bool) -> Void)?
    
    var isEditable: Bool
    
    var textInputProperties: TextInputProperties = TextInputProperties()
    
    // MARK: - Setup
    
    init(placeholder: String,
         additionalInfo: String? = nil,
         value: String? = nil,
         valueMinimumCharacterLength: Int? = nil,
         valueMaximumCharacterLength: Int? = nil,
         isEditable: Bool = true,
         hasBeenAutoFilled: Bool = false) {
        self.placeholder = placeholder
        self.additionalInfo = additionalInfo
        self.value = value
        self.valueMinimumCharacterLength = valueMinimumCharacterLength
        self.valueMaximumCharacterLength = valueMaximumCharacterLength
        self.isEditable = isEditable
        self.hasBeenAutoFilled = hasBeenAutoFilled
    }
    
    init(attributedPlaceholder: NSAttributedString,
         additionalInfo: String? = nil,
         value: String? = nil,
         valueMinimumCharacterLength: Int? = nil,
         valueMaximumCharacterLength: Int? = nil,
         isEditable: Bool = true,
         hasBeenAutoFilled: Bool = false) {
        self.attributedPlaceholder = attributedPlaceholder
        self.additionalInfo = additionalInfo
        self.value = value
        self.valueMinimumCharacterLength = valueMinimumCharacterLength
        self.valueMaximumCharacterLength = valueMaximumCharacterLength
        self.isEditable = isEditable
        self.hasBeenAutoFilled = hasBeenAutoFilled
    }
}
