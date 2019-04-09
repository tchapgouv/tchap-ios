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
import Reusable

protocol FormCheckBoxDelegate: class {
    func formCheckBoxDidSelectLabelLink(_ formCheckBox: FormCheckBox)
}

/// FormCheckBox represent a check box used in application forms
final class FormCheckBox: UIView, NibOwnerLoadable {
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var checkBoxImaveView: UIImageView!
    @IBOutlet private weak var checkBoxMask: UIView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var labelMask: UIView!
    
    // MARK: Private
    
    private var formCheckBoxModel: FormCheckBoxModelType?
    
    // MARK: Public
    
    weak var delegate: FormCheckBoxDelegate?
    
    // MARK: - Setup
    
    private func commonInit() {
        self.label.text = nil
        
        self.isUserInteractionEnabled = true
        let checkBoxTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleCheckBoxTap(_:)))
        self.checkBoxMask.addGestureRecognizer(checkBoxTapGestureRecognizer)
        
        let labelTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleLabelTap(_:)))
        self.labelMask.addGestureRecognizer(labelTapGestureRecognizer)
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
    
    // MARK: - Public
    
    func fill(formCheckBoxModel: FormCheckBoxModelType) {
        self.formCheckBoxModel = formCheckBoxModel
        
        self.updateCheckBoxImage()
        self.setupCheckBoxLabel(formCheckBoxModel.label, labelLink: formCheckBoxModel.labelLink)
    }
    
    // MARK: - Private
    
    private func updateCheckBoxImage() {
        let isSelected = self.formCheckBoxModel?.isSelected ?? false
        self.checkBoxImaveView.image = isSelected ? Asset.Images.Common.selectionTick.image : Asset.Images.Common.selectionUntick.image
    }
    
    private func setupCheckBoxLabel(_ label: String, labelLink: String?) {
        if let link = labelLink {
            let attributedLabel = NSMutableAttributedString(string: label)
            let range = (label as NSString).range(of: link)
            attributedLabel.addAttribute(.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: range)
            attributedLabel.addAttribute(.link, value: "link", range: range)
            self.label.attributedText = attributedLabel
        } else {
            self.label.text = label
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleCheckBoxTap(_ sender: UITapGestureRecognizer) {
        if let model = self.formCheckBoxModel {
            // invert the current state
            self.formCheckBoxModel?.isSelected = !model.isSelected
            self.updateCheckBoxImage()
        }
    }
    
    @objc private func handleLabelTap(_ sender: UITapGestureRecognizer) {
        self.delegate?.formCheckBoxDidSelectLabelLink(self)
    }
}

// MARK: - Stylable
extension FormCheckBox: Stylable {
    func update(style: Style) {
        self.label.textColor = style.buttonPlainTitleColor
    }
}
