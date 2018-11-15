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
    @IBOutlet private weak var missedNotifAndUnreadBadgeBgView: UIView!
    
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
    
    static func nib() -> UINib! {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    static func defaultReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarView.tc_makeCircle()
        
        // Round unread badge corners
        self.missedNotifAndUnreadBadgeBgView.layer.cornerRadius = 10
        
        // Design the pinned room marker
        let path = UIBezierPath(rect: self.pinView.bounds)
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: self.pinView.frame.size.height))
        path.addLine(to: CGPoint(x: self.pinView.frame.size.width, y: 0))
        path.close()
        self.pinView.tc_mask(withPath: path, inverse: true)
    }
    
    func render(_ cellData: MXKCellData!) {
        guard let roomCellData = cellData as? MXKRecentCellDataStoring else {
            fatalError("RoomsCell is not of the expected class")
        }
        
        self.roomCellData = roomCellData
        
        // Hide by default missed notifications and unread widgets
        self.missedNotifAndUnreadBadgeBgView.isHidden = true
        
        // Report computed values as is
        self.titleLabel.text = roomCellData.roomDisplayname
        
        self.lastEventDate.text = roomCellData.lastEventDate
        
        self.lastEventDescription.text = roomCellData.lastEventTextMessage
        
        // Notify unreads and bing
        if roomCellData.hasUnread {
            self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
            self.lastEventDescription.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            self.lastEventDescription.textColor = style.primaryTextColor
            
            if roomCellData.notificationCount > 0 {
                self.missedNotifAndUnreadBadgeBgView.isHidden = false
                
                self.missedNotifAndUnreadBadgeLabel.text = roomCellData.notificationCountStringValue
                self.missedNotifAndUnreadBadgeLabel.sizeToFit()
            }
        } else {
            self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            self.lastEventDescription.font = UIFont.systemFont(ofSize: 12, weight: .regular)
            self.lastEventDescription.textColor = style.secondaryTextColor
        }
        
        self.encryptedIcon.isHidden = !roomCellData.roomSummary.isEncrypted
        
        roomCellData.roomSummary?.setRoomAvatarImageIn(self.avatarView)
        
        // Check whether the room is pinned
        if roomCellData.roomSummary?.room?.accountData?.tags?[kMXRoomTagFavourite] != nil {
            self.pinView.backgroundColor = self.style.buttonBorderedBackgroundColor
        } else {
            self.pinView.backgroundColor = UIColor.clear
        }
    }
    
    static func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        // The height is fixed
        return 74
    }
    
    func update(style: Style) {
        self.style = style
        self.titleLabel.textColor = style.primaryTextColor
        self.lastEventDescription.textColor = style.secondaryTextColor
        self.lastEventDate.textColor = style.secondaryTextColor
        self.missedNotifAndUnreadBadgeBgView.backgroundColor = style.buttonBorderedBackgroundColor
        self.missedNotifAndUnreadBadgeLabel.textColor = style.buttonBorderedTitleColor
        
        self.avatarView.defaultBackgroundColor = UIColor.clear
        
        self.pinView.backgroundColor = UIColor.clear
    }
}
