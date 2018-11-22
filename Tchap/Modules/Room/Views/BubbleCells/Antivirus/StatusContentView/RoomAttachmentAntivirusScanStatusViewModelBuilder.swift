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

import UIKit

/// `RoomAttachmentAntivirusScanStatusViewModelBuilder` enables to build RoomAttachmentAntivirusScanStatusViewModel
@objcMembers
final class RoomAttachmentAntivirusScanStatusViewModelBuilder: NSObject {
    
    // MARK: - Public
    
    /// Transform a MXKRoomBubbleCellData to RoomAttachmentAntivirusScanStatusViewModel
    ///
    /// - Parameter roomBubbleCellData: A room bubble cell data
    /// - Returns: A view model RoomAttachmentAntivirusScanStatusViewModel
    func viewModel(from roomBubbleCellData: MXKRoomBubbleCellData) -> RoomAttachmentAntivirusScanStatusViewModel? {
        
        guard roomBubbleCellData.attachment != nil,
            let firstBubbleComponent = roomBubbleCellData.bubbleComponents.first,
            let eventScan = firstBubbleComponent.eventScan,
            eventScan.antivirusScanStatus != MXAntivirusScanStatus.trusted,
            let filename = self.filename(from: firstBubbleComponent) else {
                return nil
        }
        
        return self.viewModel(from: eventScan.antivirusScanStatus, filename: filename)
    }
    
    // MARK: - Private
    
    private func isRoomBubbleCellDataContainsMediaUploadInProgress(_ roomBubbleCellData: MXKRoomBubbleCellData) -> Bool {
        guard let contentURL = roomBubbleCellData.attachment?.contentURL else {
            return false
        }
        
        return contentURL.hasPrefix(kMXMediaUploadIdPrefix)
    }
    
    private func filename(from bubbleComponent: MXKRoomBubbleComponent) -> String? {
        return bubbleComponent.attributedTextMessage?.string ?? bubbleComponent.textMessage
    }
    
    private func eventScan(from roomBubbleCellData: MXKRoomBubbleCellData) -> MXEventScan? {
        guard let firstBubbleComponent = roomBubbleCellData.bubbleComponents.first else {
            return nil
        }
        return firstBubbleComponent.eventScan
    }
    
    private func viewModel(from antivirusScanStatus: MXAntivirusScanStatus, filename: String) -> RoomAttachmentAntivirusScanStatusViewModel? {
        
        let viewModel: RoomAttachmentAntivirusScanStatusViewModel?
        
        let icon: UIImage?
        let title: String?
        let fileInfo: String?
        
        switch antivirusScanStatus {
        case .unknown:
            icon = #imageLiteral(resourceName: "attachment_scan_status_unavailable")
            title = TchapL10n.roomAttachmentScanStatusUnavailableTitle
            fileInfo = filename
        case .inProgress:
            icon = #imageLiteral(resourceName: "attachment_scan_status_in_progress")
            title = TchapL10n.roomAttachmentScanStatusInProgressTitle
            fileInfo = filename
        case .infected:
            icon = #imageLiteral(resourceName: "attachment_scan_status_infected")
            title = TchapL10n.roomAttachmentScanStatusInfectedTitle
            fileInfo = TchapL10n.roomAttachmentScanStatusInfectedFileInfo(filename)            
        default:
            icon = nil
            title = nil
            fileInfo = nil
        }
        
        if let icon = icon, let title = title, let fileInfo = fileInfo {
            viewModel = RoomAttachmentAntivirusScanStatusViewModel(icon: icon, title: title, fileInfo: fileInfo)
        } else {
            viewModel = nil
        }
        
        return viewModel
    }
}
