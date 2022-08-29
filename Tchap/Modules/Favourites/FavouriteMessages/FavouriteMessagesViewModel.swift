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
    private let formatter: EventFormatter
    
    private var sortedFavouriteEvents: [FavouriteEvent] = []
    private var favouriteMessagesDataList: [FavouriteMessagesBubbleCellData] = []
    private var favouriteEventIndex = 0
    private var pendingOperations = 0
    private var viewState: FavouriteMessagesViewState?
    private var extraEventsListener: Any?
    private var selectedBubbleCellData: FavouriteMessagesBubbleCellData!
    
    var titleViewModel: RoomTitleViewModel
    
    // MARK: Public

    weak var viewDelegate: FavouriteMessagesViewModelViewDelegate?
    weak var coordinatorDelegate: FavouriteMessagesViewModelCoordinatorDelegate?
    
    // MARK: - Setup
    
    init(session: MXSession, formatter: EventFormatter) {
        self.session = session
        self.formatter = formatter
        
        let subtitle = NSAttributedString(string: TchapL10n.favouriteMessagesOneSubtitle(0), attributes: [.foregroundColor: ThemeService.shared().theme.headerTextPrimaryColor])
        self.titleViewModel = RoomTitleViewModel(title: TchapL10n.favouriteMessagesTitle,
                                                 roomTypeImage: nil,
                                                 roomTypeImageTintColor: nil,
                                                 subtitle: subtitle,
                                                 roomMembersCount: nil)
    }
    
    deinit {
        self.releaseData()
    }
    
    // MARK: - Public
    
    func process(viewAction: FavouriteMessagesViewAction) {
        switch viewAction {
        case .loadData:
            self.loadData()
        case .tapEvent(let roomId, let eventId):
            self.coordinatorDelegate?.favouriteMessagesViewModel(self, didShowRoomWithId: roomId, onEventId: eventId)
        case .handlePermalinkFragment(let fragment):
            self.coordinatorDelegate?.favouriteMessagesViewModel(self, handlePermalinkFragment: fragment)
        case .selectEvent(let event, let cellData):
            self.selectEvent(event: event, cellData: cellData)
        case .cancelSelection:
            self.cancelSelection()
        case .cancel:
            self.releaseData()
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
        case .loading, .sorted:
            canLoadData = false
        case .loaded(roomBubbleCellDataList: _), .updated, .selectedEvent, .cancelledSelection:
            canLoadData = self.favouriteMessagesDataList.count < self.sortedFavouriteEvents.count || self.sortedFavouriteEvents.isEmpty
        default:
            canLoadData = true
        }
        
        return canLoadData
    }
    
    private func loadData() {
        guard self.canLoadData() else {
            MXLog.debug("[FavouriteMessagesViewModel] loadData: pending loading or all data loaded")
            return
        }

        self.update(viewState: .loading)
        self.unregisterEventDidDecryptNotification()
        
        if self.sortedFavouriteEvents.isEmpty {
            var favouriteEvents: [FavouriteEvent] = []
            for room in self.session.rooms {
                if let eventIds = room.accountData.getTaggedEventsIds(kMXTaggedEventFavourite) {
                    for eventId in eventIds {
                        if let eventInfo = room.accountData.getTaggedEventInfo(eventId, withTag: kMXTaggedEventFavourite),
                           eventInfo.originServerTs == kMXUndefinedTimestamp {
                            favouriteEvents.append(FavouriteEvent(roomId: room.roomId, eventId: eventId, eventInfo: eventInfo))
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
        
        self.titleViewModel = RoomTitleViewModel(title: TchapL10n.favouriteMessagesTitle,
                                                 roomTypeImage: nil,
                                                 roomTypeImageTintColor: nil,
                                                 subtitle: NSAttributedString(string: subtitle, attributes: [.foregroundColor: ThemeService.shared().theme.headerTextPrimaryColor]),
                                                 roomMembersCount: nil)
        
        self.update(viewState: .sorted)
        
        if !self.sortedFavouriteEvents.isEmpty {
            let limit = min(self.favouriteEventIndex + Constants.paginationLimit, self.sortedFavouriteEvents.count - 1)
            let roomDataSourceManager = MXKRoomDataSourceManager.sharedManager(forMatrixSession: self.session)
            
            self.pendingOperations = limit - self.favouriteEventIndex + 1
            var favouriteMessagesCache: [FavouriteMessagesBubbleCellData] = []

            for i in self.favouriteEventIndex...limit {
                let favouriteEvent = self.sortedFavouriteEvents[i]
                self.favouriteEventIndex += 1
                
                //  attempt to fetch the event
                self.session.event(withEventId: favouriteEvent.eventId,
                                   inRoom: favouriteEvent.roomId) { [weak self] response in
                    guard let self = self else {
                        return
                    }
                    
                    switch response {
                    case .success(let event):
                        //  handle encryption for this event
                        if event.isEncrypted && event.clear == nil && self.session.decryptEvent(event, inTimeline: nil) == false {
                            MXLog.debug("[FavouriteMessagesViewModel] processEditEvent: Fail to decrypt event: \(event.eventId ?? "")")
                        }
                        
                        // Check whether the user knows this room to create the room data source if it doesn't exist.
                        roomDataSourceManager?.roomDataSource(forRoom: favouriteEvent.roomId, create: (self.session.room(withRoomId: favouriteEvent.roomId) != nil), onComplete: { roomDataSource in
                            
                            if let roomDataSource = roomDataSource {
                                roomDataSource.eventFormatter = self.formatter
                                if let cellData = FavouriteMessagesBubbleCellData(event: event, andRoomState: roomDataSource.roomState, andRoomDataSource: roomDataSource) {
                                    favouriteMessagesCache.append(cellData)
                                }
                            }
                            
                            self.process(cellDatas: favouriteMessagesCache)
                        })
                    case .failure:
                        self.process(cellDatas: favouriteMessagesCache)
                    }
                }
            }
        }
    }
    
    private func process(cellDatas: [FavouriteMessagesBubbleCellData]) {
        self.pendingOperations -= 1
        if self.pendingOperations == 0, !cellDatas.isEmpty {
            self.favouriteMessagesDataList.append(contentsOf: cellDatas.sorted { $0.events[0].originServerTs > $1.events[0].originServerTs })
            self.update(viewState: .loaded(self.favouriteMessagesDataList))
            self.registerEventDidDecryptNotification()
        }
    }
    
    private func selectEvent(event: MXEvent, cellData: FavouriteMessagesBubbleCellData) {
        cellData.selectedEventId = event.eventId
        self.selectedBubbleCellData = cellData
        self.update(viewState: .selectedEvent)
    }
    
    private func cancelSelection() {
        self.selectedBubbleCellData.selectedEventId = nil
        self.selectedBubbleCellData = nil
        self.update(viewState: .cancelledSelection)
    }
    
    private func releaseData() {
        self.removeEventsListener()
        self.unregisterEventDidDecryptNotification()
    }
    
    private func update(viewState: FavouriteMessagesViewState) {
        self.viewState = viewState
        self.viewDelegate?.favouriteMessagesViewModel(self, didUpdateViewState: viewState)
    }
    
    private func addEventsListener() {
        if self.extraEventsListener == nil {
            self.extraEventsListener = self.session.listenToEvents([.taggedEvents]) { (event, direction, roomState) in
                self.sortedFavouriteEvents.removeAll()
                self.favouriteMessagesDataList.removeAll()
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
    
    // MARK: - mxEventDidDecrypt
    
    private func registerEventDidDecryptNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(eventDidDecrypt(notification:)), name: .mxEventDidDecrypt, object: nil)
    }
    
    private func unregisterEventDidDecryptNotification() {
        NotificationCenter.default.removeObserver(self, name: .mxEventDidDecrypt, object: nil)
    }
    
    @objc private func eventDidDecrypt(notification: Notification) {
        guard let decryptedEvent = notification.object as? MXEvent else {
            return
        }
        
        for cellData in self.favouriteMessagesDataList where cellData.events[0].eventId == decryptedEvent.eventId {
            cellData.updateEvent(decryptedEvent.eventId, with: decryptedEvent)
            self.update(viewState: .updated)
            break
        }
    }
}
