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

@objc protocol RoomTitleViewDelegate: class {
    func roomTitleViewDidTapped(_ roomTitleView: RoomTitleView)
}

@objc final class RoomTitleView: UIView, NibLoadable, Stylable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let hexagonImageBorderWidth: CGFloat = 1.0
        static let backBarButtonItemRightPosition: CGFloat = 30.0
    }
    
    // MARK: - Properties
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subTitleLabel: UILabel!
    @IBOutlet private weak var roomInfoLabel: UILabel!
    @IBOutlet private weak var titlesStackView: UIStackView!
    @IBOutlet private weak var imageView: MXKImageView!
    
    private var style: Style!
    
    private var imageBorderColor: UIColor = UIColor.clear
    private var imageBorderWidth: CGFloat = Constants.hexagonImageBorderWidth
    
    private weak var titlesStackViewCenterXConstraint: NSLayoutConstraint?
    
    // Left margin from superView, used only for iOS 10 and below
    private var leftMargin: CGFloat = 0
    
    private var imageShape: AvatarImageShape = .circle
    
    @objc weak var delegate: RoomTitleViewDelegate?
    
    // MARK: Setup
    
    @objc class func instantiate(style: Style = Variant2Style.shared) -> RoomTitleView {
        let roomTitleView = RoomTitleView.loadFromNib()
        roomTitleView.update(style: style)
        return roomTitleView
    }
    
    // MARK: Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.imageView.enableInMemoryCache = true        
        self.setupTapGestureRecognizer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update frame only for iOS 10 and below
        if #available(iOS 11.0, *) {} else {
            self.updateFrameFromSuperview()
        }
        
        self.updateAvatarView()
    }
    
    override func updateConstraints() {
        
        if #available(iOS 11.0, *) {
            if self.titlesStackViewCenterXConstraint == nil {
                
                // Center horizontally titles with superview if possible to avoid offset
                if let superView = self.superview {
                    self.titlesStackViewCenterXConstraint = self.titlesStackView.centerXAnchor.constraint(equalTo: superView.centerXAnchor)
                } else {
                    self.titlesStackViewCenterXConstraint = self.titlesStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
                }
                
                self.titlesStackViewCenterXConstraint?.isActive = true
            }
        }
        
        super.updateConstraints()
    }
    
    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
    
    // MARK: - Public    
    
    @objc func fill(roomTitleViewModel: RoomTitleViewModel) {
        self.titleLabel.text = roomTitleViewModel.title
        self.subTitleLabel.text = roomTitleViewModel.subtitle
        self.roomInfoLabel.text = roomTitleViewModel.roomInfo
        if let avatarImageViewModel = roomTitleViewModel.avatarImageViewModel {
            self.imageView.isHidden = false
            if let thumbnailSize = avatarImageViewModel.thumbnailSize, let thumbnailingMethod = avatarImageViewModel.thumbnailingMethod {
                self.imageView.setImageURI(avatarImageViewModel.avatarContentURI,
                                           withType: nil,
                                           andImageOrientation: .up,
                                           toFitViewSize: thumbnailSize,
                                           with: thumbnailingMethod,
                                           previewImage: avatarImageViewModel.placeholderImage,
                                           mediaManager: avatarImageViewModel.mediaManager)
            } else {
                self.imageView.setImageURI(avatarImageViewModel.avatarContentURI,
                                           withType: nil,
                                           andImageOrientation: .up,
                                           previewImage: avatarImageViewModel.placeholderImage,
                                           mediaManager: avatarImageViewModel.mediaManager)
            }
            
            self.imageShape = avatarImageViewModel.shape
            if let borderColor = avatarImageViewModel.borderColor {
                self.imageBorderColor = borderColor
            }
            if let borderWidth = avatarImageViewModel.borderWidth {
                self.imageBorderWidth = borderWidth
            }
            self.updateAvatarView()
        } else {
            self.imageView.isHidden = true
        }
    }
    
    @objc func update(style: Style) {
        self.style = style
        self.titleLabel.textColor = style.barTitleColor
        self.subTitleLabel.textColor = style.barSubTitleColor
        self.roomInfoLabel.textColor = style.secondaryTextColor
        
        self.imageView?.defaultBackgroundColor = UIColor.clear
    }
    
    // MARK: - Private
    
    private func setupTapGestureRecognizer() {
        self.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        self.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // Update view frame according superview only for iOS 10 and below
    // This is a workaround, prefer update RoomTitleView frame from outside to get more control and avoid introspection
    private func updateFrameFromSuperview() {
        guard let superView = self.superview as? UINavigationBar else {
            return
        }
        
        // Handle presence of backBarButtonItem with hardcoded margin
        let leftMargin: CGFloat = superView.backItem != nil ? Constants.backBarButtonItemRightPosition : 0
        let rightargin: CGFloat = 0
        
        let titleViewWidth: CGFloat = superView.frame.size.width - leftMargin - rightargin
        let titleViewHeight: CGFloat = superView.frame.size.height
        
        self.frame = CGRect(x: leftMargin, y: 0, width: titleViewWidth, height: titleViewHeight)
        
        // Center horizontally titles with superview
        self.titlesStackViewCenterXConstraint = self.titlesStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: -leftMargin/2)
        self.titlesStackViewCenterXConstraint?.isActive = true
    }
    
    private func updateAvatarView () {
        switch self.imageShape {
        case .circle:
            self.imageView.tc_makeCircle()
        case .hexagon:
            self.imageView.tc_makeHexagon(borderWidth: self.imageBorderWidth, borderColor: self.imageBorderColor)
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleBackgroundTap(_ sender: UITapGestureRecognizer) {
        self.delegate?.roomTitleViewDidTapped(self)
    }
}
