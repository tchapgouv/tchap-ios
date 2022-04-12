/*
 Copyright 2019 Vector Creations Ltd
 
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

@objcMembers class PublicRoomsCell: UITableViewCell, NibReusable {
    
    private enum Constants {
        static let hexagonImageBorderWidth: CGFloat = 1.0
    }
    
    @IBOutlet private(set) weak var avatarView: MXKImageView!
    @IBOutlet private(set) weak var roomDisplayName: UILabel!
    @IBOutlet private(set) weak var roomTopic: UILabel!
    @IBOutlet private(set) weak var memberCount: UILabel!
    @IBOutlet private(set) weak var domainLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.update(theme: ThemeService.shared().theme)
        
        self.avatarView.enableInMemoryCache = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // All the public rooms are restricted
        self.avatarView.tc_makeHexagon(borderWidth: Constants.hexagonImageBorderWidth,
                                       borderColor: ThemeService.shared().theme.borderMain)
    }
    
    func render(publicRoom: MXPublicRoom, using mediaManager: MXMediaManager) {
        
        // Set the public room name display
        let roomDisplayName: String?
        if let roomName = publicRoom.name {
            roomDisplayName = roomName
        } else {
            roomDisplayName = publicRoom.aliases?.first
        }
        self.roomDisplayName.text = roomDisplayName
        
        // Check whether this public room has topic
        if let topic = publicRoom.topic {
            self.roomTopic.isHidden = false
            self.roomTopic.text = MXTools.stripNewlineCharacters(topic)
        } else {
            self.roomTopic.isHidden = true
        }
        
        // Set the avatar
        let avatarImage = AvatarGenerator.generateAvatar(forMatrixItem: publicRoom.roomId, withDisplayName: roomDisplayName)
        
        if let avatarUrl = publicRoom.avatarUrl {
            self.avatarView.setImageURI(avatarUrl, withType: nil, andImageOrientation: UIImage.Orientation.up, toFitViewSize: self.avatarView.frame.size, with: MXThumbnailingMethodCrop, previewImage: avatarImage, mediaManager: mediaManager)
        } else {
            self.avatarView.image = avatarImage
        }
        self.avatarView.contentMode = .scaleAspectFill
        
        // Set Room domain
        self.domainLabel.text = PublicRoomsCell.homeServerDisplayName(from: publicRoom.roomId)
        
        // Set member count
        let membersLabel: String!
        if publicRoom.numJoinedMembers > 1 {
            membersLabel = String(format: Bundle.mxk_localizedString(forKey: "num_members_other"), String(publicRoom.numJoinedMembers))
        } else if publicRoom.numJoinedMembers == 1 {
            membersLabel = String(format: Bundle.mxk_localizedString(forKey: "num_members_one"), "1")
        } else {
            membersLabel = nil
        }
        self.memberCount.text = membersLabel
    }
    
    private static func homeServerDisplayName(from publicRoomId: String) -> String? {
        guard let matrixIDComponents = RoomIDComponents(matrixID: publicRoomId) else {
            return nil
        }
        
        return HomeServerComponents(hostname: matrixIDComponents.homeServer).displayName
    }
}

// MARK: - Theme
extension PublicRoomsCell: Themable {
    func update(theme: Theme) {
        self.roomDisplayName.textColor = theme.textPrimaryColor
        self.roomTopic.textColor = theme.textSecondaryColor
        self.memberCount.textColor = theme.textSecondaryColor
        self.domainLabel.textColor = theme.textTertiaryColor
        
        self.avatarView?.defaultBackgroundColor = UIColor.clear
    }
}
