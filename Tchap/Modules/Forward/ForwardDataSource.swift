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

class ForwardDataSource: MXKRecentsDataSource {
    
    private var session: MXSession!
    private var cellDataArray: [MXKRecentCellData]!
    private var filteredCellDataArray: [MXKRecentCellData]?
    
    override init(matrixSession mxSession: MXSession!) {
        super.init()
        self.session = mxSession
        self.cellDataArray = [MXKRecentCellData]()
        self.loadCellData()
    }
    
    private func loadCellData() {
        for summary in self.session.roomsSummaries() {
            if !summary.hiddenFromUser && summary.membership != .invite {
                if summary.isDirect && MXTools.isEmailAddress(summary.directUserId) {
                    continue
                }
                
                if let recentCellData = MXKRecentCellData(roomSummary: summary, andRecentListDataSource: nil), recentCellData.roomDisplayname != nil {
                    self.cellDataArray.append(recentCellData)
                }
            }
        }
        
        self.cellDataArray.sort { (cellData1, cellData2) -> Bool in
            // Then order by name
            if !cellData1.roomDisplayname.isEmpty && !cellData2.roomDisplayname.isEmpty {
                return cellData1.roomDisplayname.caseInsensitiveCompare(cellData2.roomDisplayname) == .orderedAscending
            } else {
                return cellData2.roomDisplayname.isEmpty
            }
        }
        
        self.delegate?.dataSource(self, didCellChange: nil)
    }
    
    // MARK: - MXKRecentsDataSource
    
    func roomCellData(at indexPath: IndexPath!) -> MXKRecentCellData? {
        if let filteredArray = self.filteredCellDataArray {
            return indexPath.row < filteredArray.count ? filteredArray[indexPath.row] : nil
        }
        return indexPath.row < self.cellDataArray.count ? self.cellDataArray[indexPath.row] : nil
    }
    
    override func search(withPatterns patternsList: [Any]!) {
        guard let list = patternsList as? [String], !list.isEmpty else {
            self.filteredCellDataArray = nil
            self.delegate?.dataSource(self, didCellChange: nil)
            return
        }
        
        self.filteredCellDataArray?.removeAll()
        if self.filteredCellDataArray == nil {
            self.filteredCellDataArray = [MXKRecentCellData]()
        }
        
        for cellData in self.cellDataArray {
            for pattern in list {
                if let name = cellData.roomDisplayname, name.vc_caseInsensitiveContains(pattern) {
                    self.filteredCellDataArray?.append(cellData)
                    break
                }
            }
        }
        self.delegate?.dataSource(self, didCellChange: nil)
    }

    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let filteredArray = self.filteredCellDataArray {
            return filteredArray.count
        }
        return self.cellDataArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let roomData = self.roomCellData(at: indexPath),
              let delegate = self.delegate,
              let cellIdentifier = delegate.cellReuseIdentifier(for: roomData) else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        if let viewCell = cell as? MXKCellRendering {
            viewCell.render(roomData)
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
