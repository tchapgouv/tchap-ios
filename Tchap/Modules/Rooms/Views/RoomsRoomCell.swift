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

class RoomsRoomCell: RoomsCell {
    // MARK: - Constants
    
    private enum Constants {
        static let hexagonImageBorderWidth: CGFloat = 1.0
    }
    
    @IBOutlet private weak var lastEventSenderName: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarView.tc_makeHexagon(borderWidth: Constants.hexagonImageBorderWidth, borderColor: self.style.secondaryTextColor)
    }
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        self.lastEventSenderName.text = nil
        if let senderId = self.roomCellData?.lastEvent?.sender, let session = self.roomCellData?.recentsDataSource.mxSession {
            // Try to find user in local session
            let senderUser: User
            let userService = UserService(session: session)
            
            if let userFromSession = userService.getUserFromLocalSession(with: senderId) {
                senderUser = userFromSession
            } else {
                senderUser = userService.buildTemporaryUser(from: senderId)
            }
            let displayNameComponents = DisplayNameComponents(displayName: senderUser.displayName)
            self.lastEventSenderName.text = displayNameComponents.name
        }
    }
    
    override func update(style: Style) {
        super.update(style: style)
        self.lastEventSenderName.textColor = style.primaryTextColor
    }
    
}
