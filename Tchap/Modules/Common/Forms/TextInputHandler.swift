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

/// An helper for text input (UITextField or UITextView)
struct TextInputHandler {
    
    /// Check if final text length match given maximumCharacterLength
    static func textInput(shouldChangeText orginalString: String,
                          inRange range: NSRange,
                          replacementString: String,
                          maximumCharacterLength: Int) -> Bool {
        let newString = self.currentText(fromOrginalString: orginalString, replacementCharactersRange: range, replacementString: replacementString)
        return newString.count <= maximumCharacterLength
    }
    
    /// Get current text from orignal and replacement text range.
    static func currentText(fromOrginalString orginalString: String, replacementCharactersRange range: NSRange, replacementString string: String) -> String {
        guard let stringRange = Range(range, in: orginalString) else {
            return orginalString
        }
        return orginalString.replacingCharacters(in: stringRange, with: string)
    }
}

extension TextInputHandler {
    
    static func textField(_ textField: UITextField,
                          shouldChangeCharactersInRange range: NSRange,
                          replacementString string: String,
                          maximumCharacterLength: Int) -> Bool {
        return self.textInput(shouldChangeText: textField.text ?? "", inRange: range, replacementString: string, maximumCharacterLength: maximumCharacterLength)
    }
    
    static func textView(_ textView: UITextView,
                         shouldChangeCharactersInRange range: NSRange,
                         replacementText text: String,
                         maximumCharacterLength: Int) -> Bool {
        return self.textInput(shouldChangeText: textView.text ?? "", inRange: range, replacementString: text, maximumCharacterLength: maximumCharacterLength)
    }
}
