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

final class FavouriteAttachmentAntivirusScanStatusBubbleCell: FavouriteIncomingAttachmentBubbleCell {

    // MARK: Outlets
    
    @IBOutlet private weak var favouriteAttachmentAntivirusScanStatusCellContentView: RoomAttachmentAntivirusScanStatusCellContentView!
    
    // MARK: - Private
    private var roomAttachmentAntivirusScanStatusViewModelBuilder: RoomAttachmentAntivirusScanStatusViewModelBuilder?
    
    // MARK: - Public
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if self.roomAttachmentAntivirusScanStatusViewModelBuilder == nil {
            self.roomAttachmentAntivirusScanStatusViewModelBuilder = RoomAttachmentAntivirusScanStatusViewModelBuilder()
        }
    }
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
                
        if let roomAttachmentAntivirusScanStatusViewModel = self.roomAttachmentAntivirusScanStatusViewModelBuilder?.viewModel(from: bubbleData) {
            self.favouriteAttachmentAntivirusScanStatusCellContentView.fill(with: roomAttachmentAntivirusScanStatusViewModel)
        }
    }
    
    override class func height(for cellData: MXKCellData!, withMaximumWidth maxWidth: CGFloat) -> CGFloat {
        let cell: FavouriteAttachmentAntivirusScanStatusBubbleCell = {
            FavouriteAttachmentAntivirusScanStatusBubbleCell()
        }()
        
        cell.render(cellData)
        cell.layoutIfNeeded()
        
        var fittingSize = UIView.layoutFittingCompressedSize
        fittingSize.width = maxWidth
        
        return cell.systemLayoutSizeFitting(fittingSize).height
    }
}
