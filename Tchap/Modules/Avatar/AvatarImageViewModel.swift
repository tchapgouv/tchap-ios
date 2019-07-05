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

@objcMembers
final class AvatarImageViewModel: NSObject {
    
    let avatarContentURI: String?
    let mediaManager: MXMediaManager?
    let thumbnailSize: CGSize?
    let thumbnailingMethod: MXThumbnailingMethod?
    let placeholderImage: UIImage
    let shape: AvatarImageShape
    let borderColor: UIColor?
    
    
    init(avatarContentURI: String?, mediaManager: MXMediaManager?, placeholderImage: UIImage, shape: AvatarImageShape, borderColor: UIColor?) {
        self.avatarContentURI = avatarContentURI
        self.mediaManager = mediaManager
        self.thumbnailSize = nil
        self.thumbnailingMethod = nil
        self.placeholderImage = placeholderImage
        self.shape = shape
        self.borderColor = borderColor
    }
    
    init(avatarContentURI: String?, mediaManager: MXMediaManager?, thumbnailSize: CGSize, thumbnailingMethod: MXThumbnailingMethod, placeholderImage: UIImage, shape: AvatarImageShape, borderColor: UIColor?) {
        self.avatarContentURI = avatarContentURI
        self.mediaManager = mediaManager
        self.thumbnailSize = thumbnailSize
        self.thumbnailingMethod = thumbnailingMethod
        self.placeholderImage = placeholderImage
        self.shape = shape
        self.borderColor = borderColor
    }
}
