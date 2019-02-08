/*
 Copyright 2018 Vector Creations Ltd
 
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

@objcMembers class RoomsCell: UITableViewCell, MXKCellRendering, Stylable {

    @IBOutlet private weak var pinView: UIView!
    @IBOutlet private(set) weak var avatarView: MXKImageView!
    @IBOutlet private weak var encryptedIcon: UIImageView!
    @IBOutlet private weak var missedNotifAndUnreadBadgeLabel: UILabel!
    @IBOutlet private(set) weak var missedNotifAndUnreadBadgeBgView: UIView!
    @IBOutlet private(set) weak var missedNotifAndUnreadBadgeContainerView: UIView!
    
    @IBOutlet private weak var labelsStackView: UIStackView!
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var lastEventDescription: UILabel!
    @IBOutlet private(set) weak var lastEventDate: UILabel!
    
    private(set) var style: Style!
    
    /**
     The current cell data displayed by the table view cell
     */
    private(set) var roomCellData: MXKRecentCellDataStoring?
    
    weak var delegate: MXKCellRenderingDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.update(style: Variant2Style.shared)
        
        self.avatarView.enableInMemoryCache = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    static func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    static func defaultReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarView.tc_makeCircle()
        
        // Round unread badge corners
        if let badgeView = self.missedNotifAndUnreadBadgeBgView {
            badgeView.layer.cornerRadius = badgeView.frame.size.height / 2
        }
        
        if let pinView = self.pinView {
            // Design the pinned room marker
            let path = UIBezierPath(rect: pinView.bounds)
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: pinView.frame.size.height))
            path.addLine(to: CGPoint(x: pinView.frame.size.width, y: 0))
            path.close()
            pinView.tc_mask(withPath: path, inverse: true)
        }
    }
    
    func render(_ cellData: MXKCellData!) {
        guard let roomCellData = cellData as? MXKRecentCellDataStoring else {
            fatalError("RoomsCell is not of the expected class")
        }
        
        self.roomCellData = roomCellData
        
        // Hide by default missed notifications and unread widgets
        self.missedNotifAndUnreadBadgeContainerView?.isHidden = true
        
        // Report computed values as is
        self.titleLabel.text = roomCellData.roomDisplayname
        
        self.lastEventDate?.text = roomCellData.lastEventDate
        
        // Notify unreads and bing
        if roomCellData.hasUnread {
            self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
            if let lastEventDesc = self.lastEventDescription {
                lastEventDesc.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                lastEventDesc.textColor = style.primaryTextColor
                lastEventDesc.text = roomCellData.lastEventTextMessage
            }
            
            if roomCellData.notificationCount > 0,
                let badgeContainerView = self.missedNotifAndUnreadBadgeContainerView,
                let badgeLabel = self.missedNotifAndUnreadBadgeLabel {
                badgeContainerView.isHidden = false
                badgeLabel.text = roomCellData.notificationCountStringValue
                badgeLabel.sizeToFit()
            }
        } else {
            self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            if let lastEventDesc = self.lastEventDescription {
                lastEventDesc.font = UIFont.systemFont(ofSize: 12, weight: .regular)
                lastEventDesc.textColor = style.secondaryTextColor
                lastEventDesc.text = roomCellData.lastEventTextMessage
            }
        }
        
        self.encryptedIcon?.isHidden = !roomCellData.roomSummary.isEncrypted
        
        roomCellData.roomSummary?.setRoomAvatarImageIn(self.avatarView)
        
        if let pinView = self.pinView {
            // Check whether the room is pinned
            if roomCellData.roomSummary?.room?.accountData?.tags?[kMXRoomTagFavourite] != nil {
                pinView.backgroundColor = self.style.buttonBorderedBackgroundColor
            } else {
                pinView.backgroundColor = UIColor.clear
            }
        }
    }
    
    // TODO: this method should be optional in the MXKCellRendering protocol
    class func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        // The RoomsCell instances support the self-sizing mode, return a default value
        return 80
    }
    
    func update(style: Style) {
        self.style = style
        self.titleLabel.textColor = style.primaryTextColor
        self.lastEventDescription?.textColor = style.secondaryTextColor
        self.lastEventDate?.textColor = style.secondaryTextColor
        self.missedNotifAndUnreadBadgeBgView?.backgroundColor = style.buttonBorderedBackgroundColor
        self.missedNotifAndUnreadBadgeLabel?.textColor = style.buttonBorderedTitleColor
        
        self.avatarView?.defaultBackgroundColor = UIColor.clear
        
        self.pinView?.backgroundColor = UIColor.clear
    }
}
