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

@objcMembers class RoomsInviteCell: RoomsCell {
    
    static let actionJoinInvite = "actionJoinInvite"
    static let actionDeclineInvite = "actionDeclineInvite"
    static let keyRoom = "keyRoom"
    
    private enum Constants {
        static let hexagonImageBorderWidth: CGFloat = 1.0
    }

    @IBOutlet private weak var domainLabel: UILabel!
    @IBOutlet private weak var leftButton: UIButton!
    @IBOutlet private weak var rightButton: UIButton!
    
    private var isDirectChat: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.leftButton.setTitle(TchapL10n.conversationsInviteJoin, for: .normal)
        self.rightButton.setTitle(TchapL10n.conversationsInviteDecline, for: .normal)
        
        self.selectionStyle = .none
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.leftButton.layer.cornerRadius = 5
        self.rightButton.layer.cornerRadius = 5
        
        if isDirectChat {
            self.avatarView.tc_makeCircle()
        } else {
            self.avatarView.tc_makeHexagon(borderWidth: Constants.hexagonImageBorderWidth, borderColor: self.style.secondaryTextColor)
        }
    }
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        // Show by default missed notifications and unread widgets
        self.missedNotifAndUnreadBadgeBgView.isHidden = false
        
        if let isDirect = self.roomCellData?.roomSummary.isDirect {
            self.isDirectChat = isDirect
        }
        
        if self.isDirectChat, let displayName = self.roomCellData?.roomDisplayname {
            let displayNameComponents = DisplayNameComponents(displayName: displayName)
            self.titleLabel.text = displayNameComponents.name
            self.domainLabel.text = displayNameComponents.domain
            self.domainLabel.isHidden = false
        } else {
            self.domainLabel.isHidden = true
        }
    }
    
    override func update(style: Style) {
        super.update(style: style)
        self.domainLabel.textColor = style.primarySubTextColor
        self.leftButton.backgroundColor = style.buttonBorderedBackgroundColor
        self.leftButton.setTitleColor(style.buttonBorderedTitleColor, for: .normal)
        self.rightButton.backgroundColor = style.buttonBorderedBackgroundColor
        self.rightButton.setTitleColor(style.buttonBorderedTitleColor, for: .normal)
    }
    
    @IBAction private func onLeftPressed(_ sender: Any) {
        if let delegate = self.delegate, let room = self.roomCellData?.roomSummary.room {
            delegate.cell(self, didRecognizeAction: RoomsInviteCell.actionJoinInvite, userInfo: [RoomsInviteCell.keyRoom: room])
        }
    }
    
    @IBAction private func onRightPressed(_ sender: Any) {
        if let delegate = self.delegate, let room = self.roomCellData?.roomSummary.room {
            delegate.cell(self, didRecognizeAction: RoomsInviteCell.actionDeclineInvite, userInfo: [RoomsInviteCell.keyRoom: room])
        }
    }
}
