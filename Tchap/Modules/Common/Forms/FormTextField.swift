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
    func formTextField(_ formTextField: FormTextField, hasBeenAutoFilled: Bool)
}

/// FormTextField represent a text field used in application forms 
final class FormTextField: UIView, NibOwnerLoadable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let separatorViewHeight: CGFloat = 1
        static let separatorBottomSpace: CGFloat = 6
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var separatorView: UIView!
    @IBOutlet weak var additionalInfoLabel: UILabel!
    
    // MARK: Private
    
    private var formTextViewModel: FormTextViewModelType?
    
    // MARK: Public
    
    weak var delegate: FormTextFieldDelegate?
    
    // MARK: - Setup
    
    private func commonInit() {
        self.textField.placeholder = nil
        self.additionalInfoLabel.text = nil
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
        let additionalInfoLabelHeight = self.additionalInfoLabel.intrinsicContentSize.height
        
        let height = textFieldSize.height + Constants.separatorViewHeight + Constants.separatorBottomSpace + additionalInfoLabelHeight
        return CGSize(width: textFieldSize.width, height: height)
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
        
        self.additionalInfoLabel.text = formTextViewModel.additionalInfo
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
        self.textField.textContentType = textFieldProperties.textContentType
    }
    
    private func setTextFieldEditable(_ enable: Bool) {
        self.isUserInteractionEnabled = enable
    }
    
    private func toggleAutoFillStatus(_ hasBeenAutoFilled: Bool) {
        // Consider only state change
        guard let currentFlag = self.formTextViewModel?.hasBeenAutoFilled else {
            return
        }
        
        if currentFlag != hasBeenAutoFilled {
            self.formTextViewModel?.hasBeenAutoFilled = hasBeenAutoFilled
            self.delegate?.formTextField(self, hasBeenAutoFilled: hasBeenAutoFilled)
        }
    }
    
}

// MARK: - Stylable
extension FormTextField: Stylable {
    func update(style: Style) {
        style.applyStyle(onTextField: self.textField)
        self.separatorView.backgroundColor = style.separatorColor
        self.additionalInfoLabel.textColor = style.secondaryTextColor
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
        
        // Check whether the textfield value is autofilled or full pasted
        let minLength = self.formTextViewModel?.valueMinimumCharacterLength ?? 1
        let hasBeenAutoFilled = (range.location == 0 && range.length == 0 && originalString.count == 0 && string.count > minLength)
        self.toggleAutoFillStatus(hasBeenAutoFilled)
        
        guard let maxChar = self.formTextViewModel?.valueMaximumCharacterLength else {
            self.formTextViewModel?.value = currentText
            return true
        }
        
        if currentText.count <= maxChar {
            self.formTextViewModel?.value = currentText
            return true
        }
        
        return false
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.formTextViewModel?.value = nil
        self.toggleAutoFillStatus(false)
        return true
    }
}
