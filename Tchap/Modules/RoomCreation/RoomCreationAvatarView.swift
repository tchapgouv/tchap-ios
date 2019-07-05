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
import Reusable

protocol RoomCreationAvatarViewDelegate: class {
    func roomCreationAvatarViewDidTapAddPhotoButton(_ roomCreationAvatarView: RoomCreationAvatarView)
}

final class RoomCreationAvatarView: UIView, NibLoadable, Stylable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let hexagonBorderWidth: CGFloat = 10.0
    }
    
    // MARK: - Properties
    
    @IBOutlet private weak var backgroundView: UIView!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var imageView: UIImageView!
    
    private var style: Style!
    private var hexagonBorderColor: UIColor = UIColor.clear
    
    weak var delegate: RoomCreationAvatarViewDelegate?
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundView.layer.masksToBounds = true

        self.addButton.titleLabel?.textAlignment = .center
        self.addButton.titleLabel?.numberOfLines = 0

        self.updateAddButtonTextVisibility()

        self.update(style: Variant1Style.shared)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.updateBackgroundView()
    }
    
    // MARK: - Public
    
    func updateAvatar(with image: UIImage) {
        self.imageView.image = image
        self.updateAddButtonTextVisibility()
    }
    
    func setAvatarBorderColor(_ color: UIColor) {
        self.hexagonBorderColor = color
        self.updateBackgroundView()
    }
    
    // MARK: - Private
    
    private func updateAddButtonTextVisibility() {
        
        let buttonTitle: String?
        
        if self.imageView.image != nil {
            buttonTitle = nil
        } else {
            buttonTitle = TchapL10n.roomCreationAddAvatarAction
        }
        
        self.addButton.setTitle(buttonTitle, for: .normal)
    }
    
    private func updateBackgroundView () {
        self.backgroundView.tc_makeHexagon(borderWidth: Constants.hexagonBorderWidth, borderColor: self.hexagonBorderColor)
    }
    
    // MARK: - Actions
    
    @IBAction private func addButtonAction(_ sender: Any) {
        self.delegate?.roomCreationAvatarViewDidTapAddPhotoButton(self)
    }
    
    // MARK: - Stylable
    
    func update(style: Style) {
        self.style = style
        
        self.backgroundView.backgroundColor = style.secondaryBackgroundColor
        self.addButton.setTitleColor(style.primarySubTextColor, for: .normal)
    }
}
