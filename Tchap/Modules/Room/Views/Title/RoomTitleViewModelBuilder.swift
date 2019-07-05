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
        let subtitle: String?
        let avatarImageShape: AvatarImageShape
        let avatarBorderColor: UIColor?
        
        let displayName = roomSummary.displayname ?? ""
        let avatarUrl = roomSummary.avatar
        let isDirectChat = roomSummary.isDirect
        
        if isDirectChat {
            let displayNameComponents = DisplayNameComponents(displayName: displayName)
            title = displayNameComponents.name
            subtitle = displayNameComponents.domain
            avatarImageShape = .circle
            avatarBorderColor = nil
        } else {
            let roomMemberCount = Int(roomSummary.membersCount.members)
            title = displayName
            subtitle = TchapL10n.roomTitleRoomMembersCount(roomMemberCount)
            avatarImageShape = .hexagon
            
            // Look for the right avatar border
            let roomStateService = RoomStateService(session: session)
            if let rule = roomStateService.getRoomAccessRule(for: roomSummary.roomId) {
                switch rule {
                case .restricted:
                    avatarBorderColor = kColorDarkBlue
                case .unrestricted:
                    avatarBorderColor = kColorDarkGrey
                default:
                    avatarBorderColor = UIColor.clear
                }
            } else {
                avatarBorderColor = UIColor.clear
            }
        }
        
        let placeholderImage: UIImage = AvatarGenerator.generateAvatar(forText: displayName)
        
        let avatarImageViewModel = AvatarImageViewModel(avatarContentURI: avatarUrl,
                                                        mediaManager: self.session.mediaManager,
                                                        thumbnailSize: self.avatarImageSize,
                                                        thumbnailingMethod: MXThumbnailingMethodCrop,
                                                        placeholderImage: placeholderImage,
                                                        shape: avatarImageShape,
                                                        borderColor: avatarBorderColor)
        
        return RoomTitleViewModel(title: title, subtitle: subtitle, avatarImageViewModel: avatarImageViewModel)
    }
    
    func build(fromRoomPreviewData roomPreviewData: RoomPreviewData) -> RoomTitleViewModel {
        
        let title: String = roomPreviewData.roomName ?? ""
        let subtitle: String? = roomPreviewData.roomTopic
        
        let avatarUrl = roomPreviewData.roomAvatarUrl
        
        let placeholderImage: UIImage = AvatarGenerator.generateAvatar(forText: title)
        let avatarImageShape: AvatarImageShape = .hexagon

        // The room preview is only supported for public room which are restricted by default (external users can not join them)
        let avatarImageViewModel = AvatarImageViewModel(avatarContentURI: avatarUrl,
                                                        mediaManager: self.session.mediaManager,
                                                        thumbnailSize: self.avatarImageSize,
                                                        thumbnailingMethod: MXThumbnailingMethodCrop,
                                                        placeholderImage: placeholderImage,
                                                        shape: avatarImageShape,
                                                        borderColor: kColorDarkBlue)
        
        return RoomTitleViewModel(title: title, subtitle: subtitle, avatarImageViewModel: avatarImageViewModel)
    }
    
    func build(fromUser user: User) -> RoomTitleViewModel {
        
        let displayName = user.displayName
        let avatarUrl = user.avatarStringURL
        
        let displayNameComponents = DisplayNameComponents(displayName: displayName)
        let title = displayNameComponents.name
        let subtitle = displayNameComponents.domain
        let avatarImageShape: AvatarImageShape = .circle
        
        let placeholderImage: UIImage = AvatarGenerator.generateAvatar(forText: displayName)
        
        let avatarImageViewModel = AvatarImageViewModel(avatarContentURI: avatarUrl,
                                                        mediaManager: self.session.mediaManager,
                                                        thumbnailSize: self.avatarImageSize,
                                                        thumbnailingMethod: MXThumbnailingMethodCrop,
                                                        placeholderImage: placeholderImage,
                                                        shape: avatarImageShape,
                                                        borderColor: nil)
        
        return RoomTitleViewModel(title: title, subtitle: subtitle, avatarImageViewModel: avatarImageViewModel)
    }
    
    func buildWithoutAvatar(fromUser user: User) -> RoomTitleViewModel {
        
        let displayName = user.displayName
        let displayNameComponents = DisplayNameComponents(displayName: displayName)
        let title = displayNameComponents.name
        let subtitle = displayNameComponents.domain
        
        return RoomTitleViewModel(title: title, subtitle: subtitle, avatarImageViewModel: nil)
    }
}
