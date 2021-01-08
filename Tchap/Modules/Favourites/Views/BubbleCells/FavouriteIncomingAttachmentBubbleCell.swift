// 
// Copyright 2020 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import Reusable

final class FavouriteIncomingAttachmentBubbleCell: MXKRoomIncomingAttachmentBubbleCell, NibReusable, Themable {
    
    // MARK: - Public
    
    func update(theme: Theme) {
        super.customizeRendering()
        
        self.userNameLabel.textColor = theme.userNameColors[0]
        self.messageTextView?.tintColor = theme.tintColor
    }
    
    override class func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        var rowHeight = self.attachmentBubbleCellHeight(for: cellData, withMaximumWidth: maxWidth)
        
        if rowHeight <= 0 {
            rowHeight = super.height(for: cellData, withMaximumWidth: maxWidth)
        }
        
        return rowHeight
    }
    
    override class func nib() -> UINib! {
        return UINib(nibName: String(describing: self), bundle: Bundle.main)
    }
}
