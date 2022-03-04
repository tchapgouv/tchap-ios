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

/// Generate RoomTitleViewModel used to fill RoomTitleView
@objcMembers
final class RoomTitleViewModelBuilder: NSObject {
    
    // MARK: - Constants
    
    private enum Constants {
        static let defaultAvatarSize = CGSize(width: 32, height: 32)
        static let hexagonImageBorderWidthDefault: CGFloat = 1.0
        static let hexagonImageBorderWidthUnrestricted: CGFloat = 5.0
    }
    
    // MARK: - Properties
    
    private let session: MXSession
    private let avatarImageSize: CGSize
    
    // MARK: - Setup
    
    init(session: MXSession, avatarImageSize: CGSize) {
        self.session = session
        self.avatarImageSize = avatarImageSize
    }
    
    convenience init(session: MXSession) {
        self.init(session: session, avatarImageSize: Constants.defaultAvatarSize)
    }
    
    // MARK: - Public
    
    func build(fromRoomSummary roomSummary: MXRoomSummary) -> RoomTitleViewModel {
        
        let title: String
        let roomTypeImage: UIImage?
        let roomTypeImageTintColor: UIColor?
        let subtitle: NSAttributedString?
        let roomMembersCount: String?
        let avatarImageShape: AvatarImageShape
        let avatarBorderColor: UIColor?
        let avatarBorderWidth: CGFloat?
        let avatarMarker: UIImage?
        
        let displayName = roomSummary.displayname ?? ""
        let avatarUrl = roomSummary.avatar
        
        let roomCategory = roomSummary.tc_roomCategory()
        if case .directChat = roomCategory {
            let displayNameComponents = DisplayNameComponents(displayName: displayName)
            title = displayNameComponents.name
            roomTypeImage = nil
            roomTypeImageTintColor = nil
            if let domain = displayNameComponents.domain {
                subtitle = NSAttributedString(string: domain)
            } else {
                subtitle = nil
            }
            roomMembersCount = nil
            avatarImageShape = .circle
            avatarBorderColor = nil
            avatarBorderWidth = nil
            avatarMarker = Asset.SharedImages_tchap.privateAvatarIcon.image
        } else if case .serverNotice = roomCategory {
            title = displayName
            subtitle = nil
            roomTypeImage = nil
            roomTypeImageTintColor = nil
            roomMembersCount = nil
            avatarImageShape = .circle
            avatarBorderColor = nil
            avatarBorderWidth = nil
            avatarMarker = nil
        } else {
            title = displayName
            avatarImageShape = .hexagon
            
            // Customize the avatar border and the room subtitle
            switch roomCategory {
            case .restrictedPrivateRoom:
                roomTypeImage = Asset.Images_tchap.roomTypePrivate.image.withRenderingMode(.alwaysTemplate)
                roomTypeImageTintColor = ThemeService.shared().theme.roomTypeRestricted
                avatarBorderColor = ThemeService.shared().theme.borderMain
                avatarBorderWidth = Constants.hexagonImageBorderWidthDefault
                avatarMarker = Asset.SharedImages_tchap.privateAvatarIcon.image
                subtitle = NSAttributedString(string: TchapL10n.roomTitlePrivateRoom,
                                              attributes: [.foregroundColor: ThemeService.shared().theme.roomTypeRestricted])
            case .unrestrictedPrivateRoom:
                roomTypeImage = Asset.Images_tchap.roomTypePrivate.image.withRenderingMode(.alwaysTemplate)
                roomTypeImageTintColor = ThemeService.shared().theme.roomTypeUnrestricted
                avatarBorderColor = ThemeService.shared().theme.borderSecondary
                avatarBorderWidth = Constants.hexagonImageBorderWidthUnrestricted
                avatarMarker = Asset.SharedImages_tchap.privateAvatarIcon.image
                subtitle = NSAttributedString(string: TchapL10n.roomTitleExternRoom,
                                              attributes: [.foregroundColor: ThemeService.shared().theme.roomTypeUnrestricted])
            case .forum:
                roomTypeImage = Asset.Images_tchap.roomTypeForum.image.withRenderingMode(.alwaysTemplate)
                roomTypeImageTintColor = ThemeService.shared().theme.roomTypePublic
                avatarBorderColor = ThemeService.shared().theme.borderMain
                avatarBorderWidth = Constants.hexagonImageBorderWidthDefault
                avatarMarker = Asset.SharedImages_tchap.forumAvatarIcon.image
                subtitle = NSAttributedString(string: TchapL10n.roomTitleForumRoom,
                                              attributes: [.foregroundColor: ThemeService.shared().theme.roomTypePublic])
            default:
                roomTypeImage = nil
                roomTypeImageTintColor = nil
                avatarBorderColor = UIColor.clear
                avatarBorderWidth = Constants.hexagonImageBorderWidthDefault
                avatarMarker = nil
                subtitle = nil
            }
            
            roomMembersCount = TchapL10n.roomTitleRoomMembersCount(Int(roomSummary.membersCount.joined))
        }
        
        let placeholderImage: UIImage = AvatarGenerator.generateAvatar(forText: displayName)
        
        let avatarImageViewModel = AvatarImageViewModel(avatarContentURI: avatarUrl,
                                                        mediaManager: self.session.mediaManager,
                                                        thumbnailSize: self.avatarImageSize,
                                                        thumbnailingMethod: MXThumbnailingMethodCrop,
                                                        placeholderImage: placeholderImage,
                                                        shape: avatarImageShape,
                                                        borderColor: avatarBorderColor,
                                                        borderWidth: avatarBorderWidth,
                                                        marker: avatarMarker)
        
        return RoomTitleViewModel(title: title,
                                  roomTypeImage: roomTypeImage,
                                  roomTypeImageTintColor: roomTypeImageTintColor,
                                  subtitle: subtitle,
                                  roomMembersCount: roomMembersCount,
                                  avatarImageViewModel: avatarImageViewModel)
    }
    
    func build(fromRoomPreviewData roomPreviewData: RoomPreviewData) -> RoomTitleViewModel {
        
        let title: String = roomPreviewData.roomName ?? ""
        let subtitle: NSAttributedString?
        if let topic = roomPreviewData.roomTopic {
            subtitle = NSAttributedString(string: topic)
        } else {
            subtitle = nil
        }
        
        let avatarUrl = roomPreviewData.roomAvatarUrl
        
        let placeholderImage: UIImage = AvatarGenerator.generateAvatar(forText: title)
        let avatarImageShape: AvatarImageShape = .hexagon
        let avatarBorderColor: UIColor
        let marker: UIImage?
        if roomPreviewData.wasInitializedWithPublicRoom {
            // The public rooms (forums) are restricted (external users can not join them)
            avatarBorderColor = ThemeService.shared().theme.borderMain
            marker = Asset.SharedImages_tchap.forumAvatarIcon.image
        } else {
            // We don't have information to customize the room avatar
            avatarBorderColor = UIColor.clear
            marker = nil
        }

        let avatarImageViewModel = AvatarImageViewModel(avatarContentURI: avatarUrl,
                                                        mediaManager: self.session.mediaManager,
                                                        thumbnailSize: self.avatarImageSize,
                                                        thumbnailingMethod: MXThumbnailingMethodCrop,
                                                        placeholderImage: placeholderImage,
                                                        shape: avatarImageShape,
                                                        borderColor: avatarBorderColor,
                                                        borderWidth: Constants.hexagonImageBorderWidthDefault,
                                                        marker: marker)
        
        return RoomTitleViewModel(title: title,
                                  roomTypeImage: nil,
                                  roomTypeImageTintColor: nil,
                                  subtitle: subtitle,
                                  roomMembersCount: nil,
                                  avatarImageViewModel: avatarImageViewModel)
    }
    
    func build(fromUser user: User) -> RoomTitleViewModel {
        
        let displayName = user.displayName
        let avatarUrl = user.avatarStringURL
        
        let displayNameComponents = DisplayNameComponents(displayName: displayName)
        let title = displayNameComponents.name
        let subtitle: NSAttributedString?
        if let domain = displayNameComponents.domain {
            subtitle = NSAttributedString(string: domain)
        } else {
            subtitle = nil
        }
        let avatarImageShape: AvatarImageShape = .circle
        
        let placeholderImage: UIImage = AvatarGenerator.generateAvatar(forText: displayName)
        
        let avatarImageViewModel = AvatarImageViewModel(avatarContentURI: avatarUrl,
                                                        mediaManager: self.session.mediaManager,
                                                        thumbnailSize: self.avatarImageSize,
                                                        thumbnailingMethod: MXThumbnailingMethodCrop,
                                                        placeholderImage: placeholderImage,
                                                        shape: avatarImageShape,
                                                        borderColor: nil,
                                                        borderWidth: nil,
                                                        marker: Asset.SharedImages_tchap.privateAvatarIcon.image)
        
        return RoomTitleViewModel(title: title,
                                  roomTypeImage: nil,
                                  roomTypeImageTintColor: nil,
                                  subtitle: subtitle,
                                  roomMembersCount: nil,
                                  avatarImageViewModel: avatarImageViewModel)
    }
    
    func buildWithoutAvatar(fromUser user: User) -> RoomTitleViewModel {
        
        let displayName = user.displayName
        let displayNameComponents = DisplayNameComponents(displayName: displayName)
        let title = displayNameComponents.name
        let subtitle: NSAttributedString?
        if let domain = displayNameComponents.domain {
            subtitle = NSAttributedString(string: domain)
        } else {
            subtitle = nil
        }
        
        return RoomTitleViewModel(title: title,
                                  roomTypeImage: nil,
                                  roomTypeImageTintColor: nil,
                                  subtitle: subtitle,
                                  roomMembersCount: nil,
                                  avatarImageViewModel: nil)
    }
}
