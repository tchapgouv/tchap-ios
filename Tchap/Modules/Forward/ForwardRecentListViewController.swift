// 
// Copyright 2021 New Vector Ltd
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

class ForwardRecentListViewController: MXKRecentListViewController {
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.recentsTableView.register(ShareRoomsDiscussionCell.nib(), forCellReuseIdentifier: ShareRoomsDiscussionCell.defaultReuseIdentifier())
        self.recentsTableView.register(ShareRoomsRoomCell.nib(), forCellReuseIdentifier: ShareRoomsRoomCell.defaultReuseIdentifier())
        
        // Enable self-sizing cells.
        self.recentsTableView.rowHeight = UITableView.automaticDimension
        self.recentsTableView.estimatedRowHeight = 56
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // MARK: - MXKDataSourceDelegate
    
    override func cellViewClass(for cellData: MXKCellData!) -> MXKCellRendering.Type! {
        guard let cellData = cellData as? MXKRecentCellData else {
            return nil
        }

        return cellData.roomSummary.isDirect ? ShareRoomsDiscussionCell.self : ShareRoomsRoomCell.self
    }

    override func cellReuseIdentifier(for cellData: MXKCellData!) -> String! {
        guard let cellData = cellData as? MXKRecentCellData else {
            return nil
        }

        return cellData.roomSummary.isDirect ? ShareRoomsDiscussionCell.defaultReuseIdentifier() : ShareRoomsRoomCell.defaultReuseIdentifier()
    }
}
