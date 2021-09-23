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

@objc protocol RoomTitleViewDelegate: AnyObject {
    func roomTitleViewDidTapped(_ roomTitleView: RoomTitleView)
}

@objc final class RoomTitleView: UIView, NibLoadable {
    
    // MARK: - Constants
    
    private enum Constants {
        static let hexagonImageBorderWidth: CGFloat = 1.0
        static let backBarButtonItemRightPosition: CGFloat = 30.0
    }
    
    // MARK: - Properties
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subTitleFirstView: UIView!
    @IBOutlet private weak var subTitleRoomTypeImageView: UIImageView!
    @IBOutlet private weak var subTitleLabel: UILabel!
    @IBOutlet private weak var subTitleMembersView: UIView!
    @IBOutlet private weak var subTitleMembersSeparatorLabel: UILabel!
    @IBOutlet private weak var subTitleMembersImageView: UIImageView!
    @IBOutlet private weak var subTitleMembersLabel: UILabel!
    @IBOutlet private weak var subTitleRetentionView: UIView!
    @IBOutlet private weak var subTitleRetentionSeparatorLabel: UILabel!
    @IBOutlet private weak var subTitleRetentionImageView: UIImageView!
    @IBOutlet private weak var subTitleRetentionLabel: UILabel!
    @IBOutlet private weak var titlesStackView: UIStackView!
    @IBOutlet private weak var subTitleStackView: UIStackView!
    @IBOutlet private weak var imageView: MXKImageView!
    @IBOutlet private weak var roomImageMarker: UIImageView!
    
    private var imageBorderColor: UIColor = UIColor.clear
    private var imageBorderWidth: CGFloat = Constants.hexagonImageBorderWidth
    
    private weak var titlesStackViewCenterXConstraint: NSLayoutConstraint?
    
    private var imageShape: AvatarImageShape = .circle
    
    @objc weak var delegate: RoomTitleViewDelegate?
    
    // MARK: Setup
    
    @objc class func instantiate() -> RoomTitleView {
        let roomTitleView = RoomTitleView.loadFromNib()
        roomTitleView.update(theme: ThemeService.shared().theme)
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
        
        self.updateAvatarView()
    }
    
    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
    
    // MARK: - Public    
    
    @objc func fill(roomTitleViewModel: RoomTitleViewModel) {
        self.titleLabel.text = roomTitleViewModel.title
        if let roomTypeImage = roomTitleViewModel.roomTypeImage {
            self.subTitleRoomTypeImageView.isHidden = false
            self.subTitleRoomTypeImageView.image = roomTypeImage
            if let tintColor = roomTitleViewModel.roomTypeImageTintColor {
                self.subTitleRoomTypeImageView.tintColor = tintColor
            }
        } else {
            self.subTitleRoomTypeImageView.isHidden = true
        }
        self.subTitleLabel.attributedText = roomTitleViewModel.subtitle
        if let roomMembersCount = roomTitleViewModel.roomMembersCount {
            self.subTitleMembersView.isHidden = false
            self.subTitleMembersLabel.text = roomMembersCount
        } else {
            self.subTitleMembersView.isHidden = true
        }
        if let roomRetentionInfo = roomTitleViewModel.roomRetentionInfo {
            self.subTitleRetentionView.isHidden = false
            self.subTitleRetentionLabel.text = roomRetentionInfo
        } else {
            self.subTitleRetentionView.isHidden = true
        }
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
            if let marker = avatarImageViewModel.marker {
                self.roomImageMarker.image = marker
                self.roomImageMarker.isHidden = false
            } else {
                self.roomImageMarker.isHidden = true
            }
            self.updateAvatarView()
        } else {
            self.imageView.isHidden = true
            self.roomImageMarker.isHidden = true
        }
    }
    
    // MARK: - Private
    
    private func setupTapGestureRecognizer() {
        self.isUserInteractionEnabled = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        self.addGestureRecognizer(tapGestureRecognizer)
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

// MARK: - Theme
extension RoomTitleView: Themable {
    @objc func update(theme: Theme) {
        self.titleLabel.textColor = theme.headerTextPrimaryColor
        self.subTitleLabel.textColor = theme.headerTextSecondaryColor
        self.subTitleMembersSeparatorLabel.textColor = theme.textSecondaryColor
        self.subTitleMembersLabel.textColor = theme.textSecondaryColor
        self.subTitleRetentionSeparatorLabel.textColor = theme.textSecondaryColor
        self.subTitleRetentionLabel.textColor = theme.textSecondaryColor

        self.imageView?.defaultBackgroundColor = UIColor.clear
    }
}
