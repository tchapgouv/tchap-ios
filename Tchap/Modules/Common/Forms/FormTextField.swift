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
import Reusable

protocol FormTextFieldDelegate: class {
    func formTextFieldShouldReturn(_ formTextField: FormTextField) -> Bool
}

/// FormTextField represent a text field used in application forms 
final class FormTextField: UIView, NibOwnerLoadable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let separatorViewHeight: CGFloat = 1        
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var separatorView: UIView!
    
    // MARK: Private
    
    private var formTextViewModel: FormTextViewModelType?
    
    // MARK: Public
    
    weak var delegate: FormTextFieldDelegate?
    
    // MARK: - Setup
    
    private func commonInit() {        
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        self.commonInit()
    }
    
    // MARK: - Overrides
    
    override var intrinsicContentSize: CGSize {
        let textFieldSize = self.textField.intrinsicContentSize
        return CGSize(width: textFieldSize.width,
                      height: textFieldSize.height + Constants.separatorViewHeight)
    }
    
    override var canBecomeFirstResponder: Bool {
        return self.textField.canBecomeFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        return self.textField.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        return self.textField.resignFirstResponder()
    }
    
    // MARK: - Public
    
    func fill(formTextViewModel: FormTextViewModelType) {
        self.formTextViewModel = formTextViewModel
        
        self.setTextFieldEditable(formTextViewModel.isEditable)
        self.updateTextFieldProperties(textFieldProperties: formTextViewModel.textInputProperties)
        
        if let attributedPlaceholder = formTextViewModel.attributedPlaceholder {
            self.textField.attributedPlaceholder = attributedPlaceholder
        } else {
            self.textField.placeholder = formTextViewModel.placeholder
        }
        
        self.textField.text = formTextViewModel.value
    }
    
    // MARK: - Private
    
    private func updateTextFieldProperties(textFieldProperties: TextInputProperties) {
        self.textField.keyboardType = textFieldProperties.keyboardType
        self.textField.returnKeyType = textFieldProperties.returnKeyType
        self.textField.isSecureTextEntry = textFieldProperties.isSecureTextEntry
        self.textField.autocorrectionType = textFieldProperties.autocorrectionType
        self.textField.autocapitalizationType = textFieldProperties.autocapitalization
        self.textField.font = textFieldProperties.font
        
        if #available(iOS 10.0, *) {
            self.textField.textContentType = textFieldProperties.textContentType
        }
    }
    
    private func setTextFieldEditable(_ enable: Bool) {
        self.isUserInteractionEnabled = enable
    }
}

// MARK: - Stylable
extension FormTextField: Stylable {
    func update(style: Style) {
        style.applyStyle(onTextField: self.textField)
        self.separatorView.backgroundColor = style.separatorColor
    }
}

// MARK: - UITextFieldDelegate
extension FormTextField: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let delegate = self.delegate else {
            return false
        }
        return delegate.formTextFieldShouldReturn(self)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let originalString = textField.text ?? ""
        
        let currentText = TextInputHandler.currentText(fromOrginalString: originalString, replacementCharactersRange: range, replacementString: string)
        
        guard let maxChar = self.formTextViewModel?.valueMaximumCharacterLength else {
            self.formTextViewModel?.value = currentText
            return true
        }
        
        if currentText.count <= maxChar {
            self.formTextViewModel?.value = currentText
        }
        
        return TextInputHandler.textInput(shouldChangeText: originalString, inRange: range, replacementString: string, maximumCharacterLength: maxChar)
    }
}
