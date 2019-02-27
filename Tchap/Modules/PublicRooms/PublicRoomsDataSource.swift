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
import RxSwift

/// `PublicRoomsDataSource` handle public rooms that should be displayed in a list
final class PublicRoomsDataSource: NSObject {
    
    // MARK: - Constants
    
    private enum Constants {
        static let searchTriggerTimeInterval: TimeInterval = 0.3
    }
    
    // MARK: - Properties
    
    private let disposeBag = DisposeBag()
    
    private let session: MXSession
    private let publicRoomService: PublicRoomServiceType
    
    private let searchTextSubject = PublishSubject<String?>()
    
    private weak var tableView: UITableView?
    private var state: MXKDataSourceState = MXKDataSourceStateUnknown
    private var rooms: [MXPublicRoom] = []
    
    private var searchText: String?
    private var searchTriggerTimer: Timer?
    private var hasSearchText: Bool {
        guard let searchText = self.searchText, searchText.isEmpty == false else {
            return false
        }
        return true
    }
    
    // MARK: - Setup
    
    init(session: MXSession, publicRoomService: PublicRoomServiceType) {
        self.session = session
        self.publicRoomService = publicRoomService
        
        super.init()
    }
    
    // MARK: - Public
    
    func setup(tableView: UITableView) {
        self.tableView = tableView
        self.setupTableViewCells()
        
        tableView.dataSource = self
        
        self.observeSearchText()
    }
    
    func search(with searchText: String?) {
        self.searchText = searchText
        self.searchTextSubject.onNext(searchText)
    }
    
    func room(at indexPath: IndexPath) -> MXPublicRoom? {
        guard indexPath.row < self.rooms.count else {
            return nil
        }
        return self.rooms[indexPath.row]
    }
    
    // Listen to search text update
    private func observeSearchText() {
        
        self.searchTextSubject
        .debounce(Constants.searchTriggerTimeInterval, scheduler: MainScheduler.instance) // Takes the last event and sends it if no new event is sent within `searchTriggerTimeInterval`
        .distinctUntilChanged() // Emits only if search text change
        .do(onNext: { [unowned self] _ in
            self.state = MXKDataSourceStatePreparing
            self.updateRooms(publicRooms: [])
        })
        .flatMapLatest({ [unowned self] (searchText) -> Observable<[MXPublicRoom]> in
            // flatMapLatest cancel subscriptions for any previous Observable. Cancel any previous public rooms requests.
            return self.publicRoomService.getPublicRooms(searchText: searchText)
            .map({ (publicRooms) -> [MXPublicRoom] in
                // Sort public rooms by joined members count
                return publicRooms.sorted(by: { (item1, item2) -> Bool in
                    return item1.numJoinedMembers > item2.numJoinedMembers
                })
            })
        })
        .do(onNext: { [unowned self] publicRooms in
            self.state = MXKDataSourceStateReady
            self.updateRooms(publicRooms: publicRooms)
        }, onError: { [unowned self] error in
            // This could not happen for the moment as `getPublicRooms` catch errors and return an empty array
            print("[PublicRoomsDataSource]: Fail to search public rooms")
            self.state = MXKDataSourceStateFailed
            self.updateRooms(publicRooms: [])
        })
        .subscribe()
        .disposed(by: self.disposeBag)
    }
    
    // MARK: - Private
    
    private func setupTableViewCells() {
        self.tableView?.register(PublicRoomsCell.nib(), forCellReuseIdentifier: PublicRoomsCell.defaultReuseIdentifier())
        self.tableView?.register(MXKTableViewCell.self, forCellReuseIdentifier: MXKTableViewCell.defaultReuseIdentifier())
    }
    
    private func updateRooms(publicRooms: [MXPublicRoom]) {
        self.rooms = publicRooms
        self.tableView?.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension PublicRoomsDataSource: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard self.rooms.isEmpty == false else {
            // Display a default cell when no rooms is available.
            return 1
        }
        return rooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell
        
        // Sanity check
        if indexPath.row < rooms.count {
            
            let room = rooms[indexPath.row]
            
            if let publicRoomCell = tableView.dequeueReusableCell(withIdentifier: PublicRoomsCell.defaultReuseIdentifier(), for: indexPath) as? PublicRoomsCell {
                publicRoomCell.render(publicRoom: room, withMatrixSession: self.session)
                cell = publicRoomCell
            } else {
                fatalError("Fail to dequeue PublicRoomsCell")
            }
        } else {
            
            if let tableViewCell = tableView.dequeueReusableCell(withIdentifier: MXKTableViewCell.defaultReuseIdentifier(), for: indexPath) as? MXKTableViewCell {
                tableViewCell.textLabel?.font = UIFont.systemFont(ofSize: 15.0)
                tableViewCell.selectionStyle = UITableViewCellSelectionStyle.none
                
                let cellText: String
                
                switch self.state {
                case MXKDataSourceStateReady, MXKDataSourceStateFailed:
                    if self.hasSearchText {
                        cellText = NSLocalizedString("search_no_result", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
                    } else {
                        cellText = NSLocalizedString("room_directory_no_public_room", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
                    }
                case MXKDataSourceStatePreparing:
                    if self.hasSearchText {
                        cellText = NSLocalizedString("search_in_progress", tableName: "Vector", bundle: Bundle.main, value: "", comment: "")
                    } else {
                        cellText = TchapL10n.publicRoomsLoadingInProgress
                    }
                default:
                    cellText = ""
                }
                
                tableViewCell.textLabel?.text = cellText
                
                cell = tableViewCell
            } else {
                fatalError("Fail to dequeue MXKTableViewCell")
            }
        }
        
        return cell
    }
}
