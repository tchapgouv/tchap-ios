/*
 Copyright 2021 Vector Creations Ltd
 
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

@objcMembers class RoomsTchapInfoCell: RoomsCell {

    @IBOutlet private weak var domainLabel: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.avatarView.tc_makeCircle()
    }
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        if let displayName = self.roomCellData?.roomDisplayname {
            self.titleLabel.text = displayName
        }
        self.domainLabel.text = TchapL10n.roomCategoryInfoRoom
        
        if let cellData = self.roomCellData, cellData.hasUnread {
            self.contentView.backgroundColor = ThemeService.shared().theme.unreadBackground
        } else {
            self.contentView.backgroundColor = nil
        }
    }
    
    override func update(theme: Theme) {
        super.update(theme: theme)
        self.domainLabel.textColor = ThemeService.shared().theme.domainLabel
    }
}
