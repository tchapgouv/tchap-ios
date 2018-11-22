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

/// `RoomAttachmentAntivirusScanStatusViewModel` is a view model representing antivirus scan status information
final class RoomAttachmentAntivirusScanStatusViewModel: NSObject {
    
    let icon: UIImage
    let title: String
    let fileInfo: String
    
    init(icon: UIImage, title: String, fileInfo: String) {
        self.icon = icon
        self.title = title
        self.fileInfo = fileInfo
        
        super.init()
    }
}
