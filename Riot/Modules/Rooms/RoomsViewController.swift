// 
// Copyright 2022 New Vector Ltd
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

import Foundation
import UIKit

@objc protocol RoomsViewControllerDelegate: NSObjectProtocol {
    func roomsViewControllerDidTapCreateRoomButton(_ roomsViewController: RoomsViewController)
    func roomsViewControllerDidTapPublicRoomsAccessButton(_ roomsViewController: RoomsViewController)
}

extension RoomsViewController {
    @objc func showPlusMenu(from button: UIView) -> UIAlertController {
        let currentAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        currentAlert.addAction(UIAlertAction(title: TchapL10n.conversationsCreateRoomAction, style: .default, handler: { _ in
            self.roomsViewDelegate?.roomsViewControllerDidTapCreateRoomButton(self)
        }))
        
        currentAlert.addAction(UIAlertAction(title: TchapL10n.conversationsAccessToPublicRoomsAction, style: .default, handler: { _ in
            self.roomsViewDelegate?.roomsViewControllerDidTapPublicRoomsAccessButton(self)
        }))
        
        currentAlert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: nil))
        
        currentAlert.popoverPresentationController?.sourceView = button
        currentAlert.popoverPresentationController?.sourceRect = button.bounds
        
        self.present(currentAlert, animated: true)
        
        return currentAlert
    }
}
