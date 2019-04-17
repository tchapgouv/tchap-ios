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

/// Representing a form text field view model
protocol FormTextViewModelType {
    
    /// Placeholder
    var placeholder: String? { get }
    
    /// Placeholder attributed string, override `placeholder` if set
    var attributedPlaceholder: NSAttributedString? { get }
    
    /// Additional info text
    var additionalInfo: String? { get }
    
    /// Text value
    var value: String? { get set }
    
    /// Value maximum character length
    var valueMinimumCharacterLength: Int? { get }
    
    /// Value maximum character length
    var valueMaximumCharacterLength: Int? { get }
    
    /// Called when value update
    var valueDidUpdate: ((_ newValue: String?, _ hasBeenAutoFilled: Bool) -> Void)? { get set }
    
    /// Indicate if text is editable
    var isEditable: Bool { get }
    
    /// Tell whether the text input seems to have been auto filled (or full pasted).
    var hasBeenAutoFilled: Bool { get }
    
    /// Text input properties (Some UITextInputTraits properties)
    var textInputProperties: TextInputProperties { get }
    
    /// Update the value by mentioning whether the new value comes from the auto fill (or pasteboard)
    func updateValue(value: String?, comesFromAutoFill: Bool)
}
