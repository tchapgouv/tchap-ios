/*
 Copyright 2019 New Vector Ltd
 
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

class ShareRoomsRoomCell: RoomsCell {
    // MARK: - Constants
    
    private enum Constants {
        static let hexagonImageBorderWidthDefault: CGFloat = 1.0
        static let hexagonImageBorderWidthUnrestricted: CGFloat = 5.0
    }
    
    @IBOutlet private weak var lastEventSenderName: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.updateAvatarView()
    }
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        // Set the right avatar border
        self.updateAvatarView()
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)

        self.contentView.backgroundColor = theme.backgroundColor
    }
    
    private func updateAvatarView () {
        let avatarBorderColor: UIColor
        let avatarBorderWidth: CGFloat
        
        // Set the right avatar border
        if let roomSummary = self.roomCellData?.roomSummary as? MXRoomSummary {
            switch roomSummary.tc_roomAccessRule() {
            case .restricted:
                avatarBorderColor = ThemeService.shared().theme.borderMain
                avatarBorderWidth = Constants.hexagonImageBorderWidthDefault
            case .unrestricted:
                avatarBorderColor = ThemeService.shared().theme.borderSecondary
                avatarBorderWidth = Constants.hexagonImageBorderWidthUnrestricted
            default:
                avatarBorderColor = UIColor.clear
                avatarBorderWidth = Constants.hexagonImageBorderWidthDefault
            }
        } else {
            avatarBorderColor = UIColor.clear
            avatarBorderWidth = Constants.hexagonImageBorderWidthDefault
        }
        
        self.avatarView.tc_makeHexagon(borderWidth: avatarBorderWidth, borderColor: avatarBorderColor)
    }
    
    func renderedCellData() -> MXKCellData! {
        return (roomCellData as! MXKCellData)
    }
}
