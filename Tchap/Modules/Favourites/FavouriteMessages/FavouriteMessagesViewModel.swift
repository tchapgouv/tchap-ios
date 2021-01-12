// File created from ScreenTemplate
// $ createScreen.sh Favourites/FavouriteMessages FavouriteMessages
/*
 Copyright 2020 New Vector Ltd
 
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

import Foundation

struct FavouriteEvent {
    let roomId: String
    let eventId: String
    let eventInfo: MXTaggedEventInfo
}

final class FavouriteMessagesViewModel: NSObject, FavouriteMessagesViewModelType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let paginationLimit: Int = 20
    }
    
    // MARK: - Properties
    
    // MARK: Private

    private let session: MXSession
    private let favouriteMessagesQueue: DispatchQueue
    
    private var sortedFavouriteEvents: [FavouriteEvent] = []
    private var roomBubbleCellDataList: [RoomBubbleCellData] = []
    private var favouriteMessagesCache: Set<RoomBubbleCellData> = []
    private var favouriteEventIndex = 0
    private var viewState: FavouriteMessagesViewState?
    private var extraEventsListener: Any?
    private var eventId: String = ""
    
    var titleViewModel: RoomTitleViewModel
    
    // MARK: Public

    weak var viewDelegate: FavouriteMessagesViewModelViewDelegate?
    weak var coordinatorDelegate: FavouriteMessagesViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        self.favouriteMessagesQueue = DispatchQueue(label: "\(type(of: self)).favouriteMessagesQueue")
        
        let subtitle = NSAttributedString(string: TchapL10n.favouriteMessagesOneSubtitle(0), attributes: [.foregroundColor: kColorWarmGrey])
        self.titleViewModel = RoomTitleViewModel(title: TchapL10n.favouriteMessagesTitle, subtitle: subtitle, roomInfo: nil, avatarImageViewModel: nil)
    }
    
    // MARK: - Public
    
    func process(viewAction: FavouriteMessagesViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .longPress:
            self.viewDelegate?.favouriteMessagesViewModel(self, didLongPressForEventId: self.eventId)
        case .cancel:
            self.coordinatorDelegate?.favouriteMessagesViewModelDidCancel(self)
        }
    }
    
    // MARK: - Private
    
    private func canLoadData() -> Bool {
        guard let viewState = self.viewState else {
            return true
        }
        
        let canLoadData: Bool
        
        switch viewState {
        case .loading:
            canLoadData = false
        case .loaded(roomBubbleCellDataList: _):
            canLoadData = self.roomBubbleCellDataList.count < self.sortedFavouriteEvents.count || self.sortedFavouriteEvents.isEmpty
        default:
            canLoadData = true
        }
        
        return canLoadData
    }
    
    private func loadData() {
        guard self.canLoadData() else {
            print("[FavouriteMessagesViewModel] loadData: pending loading or all data loaded")
            return
        }

        self.update(viewState: .loading)
        
        if self.sortedFavouriteEvents.isEmpty {
            var favouriteEvents: [FavouriteEvent] = []
            for room in self.session.rooms {
                if let eventIds = room.accountData.getTaggedEventsIds(kMXTaggedEventFavourite) {
                    for eventId in eventIds {
                        if let eventInfo = room.accountData.getTaggedEventInfo(eventId, withTag: kMXTaggedEventFavourite) {
                            if eventInfo.originServerTs == kMXUndefinedTimestamp || eventInfo.originServerTs >= room.summary.tc_mininumTimestamp() {
                                favouriteEvents.append(FavouriteEvent(roomId: room.roomId, eventId: eventId, eventInfo: eventInfo))
                            }
                        }
                    }
                }
            }
            
            self.sortedFavouriteEvents = favouriteEvents.sorted { $0.eventInfo.originServerTs > $1.eventInfo.originServerTs }
            self.addEventsListener()
        }
        
        let subtitle: String
        if self.sortedFavouriteEvents.count > 0 {
            subtitle = TchapL10n.favouriteMessagesMultipleSubtitle(self.sortedFavouriteEvents.count)
        } else {
            subtitle = TchapL10n.favouriteMessagesOneSubtitle(self.sortedFavouriteEvents.count)
        }
        
        self.titleViewModel = RoomTitleViewModel(title: TchapL10n.favouriteMessagesTitle, subtitle: NSAttributedString(string: subtitle, attributes: [.foregroundColor: kColorWarmGrey]), roomInfo: nil, avatarImageViewModel: nil)
        
        self.update(viewState: .sorted)
        
        if !self.sortedFavouriteEvents.isEmpty {
            let limit = min(self.favouriteEventIndex + Constants.paginationLimit, self.sortedFavouriteEvents.count - 1)
            let roomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.session)
            
            //            dispatch_group_t group = dispatch_group_create();
            
            for i in self.favouriteEventIndex...limit {
                let favouriteEvent = self.sortedFavouriteEvents[i]
                self.favouriteEventIndex += 1
                
                //  attempt to fetch the event
                self.session.event(withEventId: favouriteEvent.eventId, inRoom: favouriteEvent.roomId, success: { [weak self] (event) in
                    guard let self = self else {
                        NSLog("[FavouriteMessagesViewModel] fetchEvent: MXSession.event method returned too late successfully.")
                        return
                    }
                    
                    guard let event = event else {
                        NSLog("[FavouriteMessagesViewModel] fetchEvent: MXSession.event method returned successfully with no event.")
                        return
                    }
                    
                    //  handle encryption for this event
                    if event.isEncrypted && event.clear == nil {
                        if self.session.decryptEvent(event, inTimeline: nil) == false {
                            print("[FavouriteMessagesViewModel] processEditEvent: Fail to decrypt event: \(event.eventId ?? "")")
                        }
                    }
                    
                    // Check whether the user knows this room to create the room data source if it doesn't exist.
                    roomDataSourceManager?.roomDataSource(forRoom: favouriteEvent.roomId, create: (self.session.room(withRoomId: favouriteEvent.roomId) != nil), onComplete: { roomDataSource in
                        
                        if roomDataSource != nil, let cellData = RoomBubbleCellData(event: event, andRoomState: roomDataSource?.roomState, andRoomDataSource: roomDataSource) {
                            self.process(cellData: cellData)
                        }
                    })
                }, failure: { [weak self] error in
                    guard let self = self else {
                        return
                    }
                    self.update(viewState: .error(error!))
                })
            }
        }
    }
    
    private func process(cellData: RoomBubbleCellData) {
        self.favouriteMessagesQueue.async {
            let nextEventId = self.sortedFavouriteEvents[min(self.roomBubbleCellDataList.count, self.sortedFavouriteEvents.count - 1)].eventId
            
            if cellData.events[0].eventId == nextEventId {
                self.roomBubbleCellDataList.append(cellData)
                DispatchQueue.main.async {
                    self.update(viewState: .loaded(self.roomBubbleCellDataList))
                }
                
                self.favouriteMessagesCache.remove(cellData)
                for favouriteMessagesCacheItem in self.favouriteMessagesCache {
                    self.process(cellData: favouriteMessagesCacheItem)
                }
            } else {
                self.favouriteMessagesCache.insert(cellData)
            }
        }
    }
    
    private func update(viewState: FavouriteMessagesViewState) {
        self.viewState = viewState
        self.viewDelegate?.favouriteMessagesViewModel(self, didUpdateViewState: viewState)
    }
    
    private func addEventsListener() {
        if self.extraEventsListener == nil {
            self.extraEventsListener = self.session.listenToEvents([.taggedEvents]) { (event, direction, roomState) in
                self.sortedFavouriteEvents.removeAll()
                self.roomBubbleCellDataList.removeAll()
                self.favouriteMessagesCache.removeAll()
                self.favouriteEventIndex = 0
                
                self.loadData()
            }
        }
    }
    
    private func removeEventsListener() {
        if self.extraEventsListener != nil {
            self.extraEventsListener = nil
        }
    }
}

// MARK: - MXKDataSourceDelegate

extension FavouriteMessagesViewModel: MXKDataSourceDelegate {
    
    func cellViewClass(for cellData: MXKCellData!) -> MXKCellRendering.Type! {
        return nil
    }
    
    func cellReuseIdentifier(for cellData: MXKCellData!) -> String! {
        return nil
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didCellChange changes: Any!) {
        
    }
    
    func dataSource(_ dataSource: MXKDataSource!, didStateChange state: MXKDataSourceState) {
        self.viewDelegate?.favouriteMessagesViewModelDidUpdateDataSource(self)
    }
    
}
