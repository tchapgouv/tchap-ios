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
final class RoomTitleViewModel: NSObject {
    
    let title: String
    let roomTypeImage: UIImage?
    let roomTypeImageTintColor: UIColor?
    let subtitle: NSAttributedString?
    let roomMembersCount: String?
    
    init(title: String,
         roomTypeImage: UIImage?,
         roomTypeImageTintColor: UIColor?,
         subtitle: NSAttributedString?,
         roomMembersCount: String?) {
        self.title = title
        self.roomTypeImage = roomTypeImage
        self.roomTypeImageTintColor = roomTypeImageTintColor
        self.subtitle = subtitle
        self.roomMembersCount = roomMembersCount
    }
}
