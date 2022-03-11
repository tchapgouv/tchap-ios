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

import UIKit
import Reusable

final class FavouriteMessagesViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let estimatedRowHeight: CGFloat = 21.0
        static let contentInset = UIEdgeInsets(top: 10.0, left: 0.0, bottom: 10.0, right: 0.0)
    }
    
    // MARK: - Properties
    
    // MARK: Outlets

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var overlayContainerView: UIView!
    
    // MARK: Private

    private var viewModel: FavouriteMessagesViewModelType!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var isViewAppearedOnce: Bool = false
    private var titleView: RoomTitleView!
    
    private var roomBubbleCellDataList: [RoomBubbleCellData] = []
    private var roomMessageURLParser: RoomMessageURLParser!
    private var roomContextualMenuPresenter: RoomContextualMenuPresenter!
    private var roomContextualMenuViewController: RoomContextualMenuViewController!
    private var documentInteractionController: UIDocumentInteractionController!
    private var currentSharedAttachment: MXKAttachment!
    private var mxEventDidDecryptNotificationObserver: Any!
    private var currentAlert: UIAlertController!
    private var isEventSelected: Bool = false

    // MARK: - Setup
    
    class func instantiate(with viewModel: FavouriteMessagesViewModelType) -> FavouriteMessagesViewController {
        let viewController = StoryboardScene.FavouriteMessagesViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        return viewController
    }
    
    deinit {
        self.viewModel.process(viewAction: .cancel)
        self.unregisterEventDidDecryptNotification()
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
            
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        self.roomMessageURLParser = RoomMessageURLParser()
        self.roomContextualMenuPresenter = RoomContextualMenuPresenter()
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.userThemeDidChange()
        self.keyboardAvoider?.startAvoiding()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.keyboardAvoider?.stopAvoiding()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.isViewAppearedOnce == false {
            self.isViewAppearedOnce = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeService.shared().theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func updateTheme() {
        self.tableView.backgroundColor = ThemeService.shared().theme.backgroundColor
        self.view.backgroundColor = ThemeService.shared().theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            ThemeService.shared().theme.applyStyle(onNavigationBar: navigationBar)
        }
    }

    private func userThemeDidChange() {
        self.updateTheme()
    }
    
    private func setupTableView() {
        self.tableView.contentInset = Constants.contentInset
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = Constants.estimatedRowHeight
        self.tableView.register(cellType: FavouriteIncomingTextMsgBubbleCell.self)
        self.tableView.register(cellType: FavouriteIncomingAttachmentBubbleCell.self)
        self.tableView.register(cellType: FavouriteAttachmentAntivirusScanStatusBubbleCell.self)
        
        self.tableView.tableFooterView = UIView()
    }
    
    private func setupViews() {
        self.setupTitleView()
        self.setupTableView()
    }

    private func render(viewState: FavouriteMessagesViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
        case .loaded(roomBubbleCellDataList: let roomBubbleCellDataList):
            self.renderLoaded(roomBubbleCellDataList: roomBubbleCellDataList)
        case .updated:
            self.tableView.reloadData()
        case .selectedEvent:
            self.renderSelectedEvent()
        case .cancelledSelection:
            self.renderCancelledSelection()
        case .error(let error):
            self.render(error: error)
        default:
            break
            // Do nothing
        }
    }
    
    private func renderLoading() {
        self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
    }
    
    private func renderLoaded(roomBubbleCellDataList: [RoomBubbleCellData]) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.roomBubbleCellDataList = roomBubbleCellDataList
        self.tableView.reloadData()
    }
    
    private func renderSelectedEvent() {
        self.renderSelected(isSelected: true)
    }
    
    private func renderCancelledSelection() {
        self.renderSelected(isSelected: false)
    }
    
    private func renderSelected(isSelected: Bool) {
        self.isEventSelected = isSelected
        self.tableView.reloadData()
    }
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func setupTitleView() {
        // Build title view
        self.titleView = RoomTitleView()
        self.navigationItem.titleView = titleView
    }
    
    private func scanBubbleDataIfNeeded(cellData: RoomBubbleCellData) {
        if let scanManager = cellData.mxSession.scanManager {
            for bubbleComponent in cellData.bubbleComponents {
                if let event = bubbleComponent.event, event.isContentScannable() {
                    scanManager.scanEventIfNeeded(event)
                    bubbleComponent.eventScan = scanManager.eventScan(withId: event.eventId)
                }
            }
        }
    }
    
    private func showUnableToOpenLinkErrorAlert() {
        AppDelegate.theDelegate().showAlert(withTitle: Bundle.mxk_localizedString(forKey: "error"), message: VectorL10n.roomMessageUnableOpenLinkErrorMessage)
    }
    
    private func showExplanationAlert(event: MXEvent) {
        // Observe kMXEventDidDecryptNotification to remove automatically the dialog
        // if the user has shared the keys from another device
        let alert = UIAlertController(title: VectorL10n.rerequestKeysAlertTitle, message: VectorL10n.rerequestKeysAlertMessage(AppInfo.current.displayName), preferredStyle: .alert)
        
        self.mxEventDidDecryptNotificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.mxEventDidDecrypt, object: nil, queue: .main) { (notif) in
            if let decryptedEvent = notif.object as? MXEvent, decryptedEvent.eventId == event.eventId {
                self.unregisterEventDidDecryptNotification()
                
                if self.currentAlert == alert {
                    self.currentAlert.dismiss(animated: true, completion: nil)
                    self.currentAlert = nil
                }
            }
        }
        
        self.currentAlert = alert
        
        alert.addAction(UIAlertAction(title: Bundle.mxk_localizedString(forKey: "ok"), style: .default, handler: { (action) in
            self.unregisterEventDidDecryptNotification()
            self.currentAlert = nil
        }))
        
        self.present(self.currentAlert, animated: true, completion: nil)
    }
    
    private func unregisterEventDidDecryptNotification() {
        guard let observer = self.mxEventDidDecryptNotificationObserver else {
            return
        }
        
        NotificationCenter.default.removeObserver(observer)
        self.mxEventDidDecryptNotificationObserver = nil
    }
    
    // MARK: -  Contextual Menu
    
    private func contextualMenuItems(event: MXEvent, cell: MXKRoomBubbleTableViewCell) -> Array<RoomContextualMenuItem> {
        
        let attachment = cell.bubbleData.attachment
        
        // Favourite action

        let favouriteMenuItem = RoomContextualMenuItem(menuAction: .favourite)
        favouriteMenuItem.isEnabled = true
        favouriteMenuItem.action = {
            self.hideContextualMenu(animated: true)
            self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
            
            cell.bubbleData.mxSession.room(withRoomId: event.roomId)?.untagEvent(event, withTag: kMXTaggedEventFavourite, success: {
                self.activityPresenter.removeCurrentActivityIndicator(animated: true)
            }, failure: { [weak self] (error) in
                guard let self = self, let error = error else {
                    return
                }
                
                MXLog.debug("[FavouriteMessagesViewController] Tag event (%@) failed", event.eventId)
                //Alert user
                self.render(error: error)
            })
        }
        
        // Copy action
        
        var isCopyActionEnabled = attachment == nil || attachment?.type != .sticker
        
        if attachment != nil && !BuildSettings.messageDetailsAllowCopyMedia {
            isCopyActionEnabled = false
        }
        
        if isCopyActionEnabled {
            switch event.eventType {
            case .roomMessage:
                if let messageType = event.content["msgtype"] as? String, messageType == kMXMessageTypeKeyVerificationRequest {
                    isCopyActionEnabled = false
                }
            case .keyVerificationStart, .keyVerificationAccept, .keyVerificationKey, .keyVerificationMac, .keyVerificationDone, .keyVerificationCancel:
                isCopyActionEnabled = false
            default:
                break
            }
        }
        
        let copyMenuItem = RoomContextualMenuItem(menuAction: .copy)
        copyMenuItem.isEnabled = isCopyActionEnabled
        copyMenuItem.action = {
            if attachment == nil {
                if let selectedComponent = cell.bubbleData.bubbleComponents.first(where: {$0.event.eventId == event.eventId}) {
                    if let textMessage = selectedComponent.textMessage {
                        MXKPasteboardManager.shared.pasteboard.string = textMessage
                    } else {
                        MXLog.debug("[RoomViewController] Contextual menu copy failed. Text is nil for room id/event id: %@/%@", selectedComponent.event.roomId, selectedComponent.event.eventId)
                    }
                }
                
                self.hideContextualMenu(animated: true)
            } else if attachment?.type != .sticker {
                self.hideContextualMenu(animated: true) {
                    self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
                    
                    attachment?.copy({
                        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
                    }, failure: { [weak self] (error) in
                        guard let self = self, let error = error else {
                            return
                        }
                        
                        //Alert user
                        self.render(error: error)
                    })
                    
                    // Start animation in case of download during attachment preparing
                    cell.startProgressUI()
                }
            }
        }
        
        // share action

        let shareMenuItem = RoomContextualMenuItem(menuAction: .share)
        shareMenuItem.isEnabled = true
        shareMenuItem.action = {
            if attachment == nil {
                if let selectedComponent = cell.bubbleData.bubbleComponents.first(where: {$0.event.eventId == event.eventId}) {
                    if let textMessage = selectedComponent.textMessage {
                        let activityViewController = UIActivityViewController(activityItems: [textMessage], applicationActivities: nil)
                        
                        activityViewController.modalTransitionStyle = UIModalTransitionStyle.coverVertical
                        activityViewController.popoverPresentationController?.sourceView = cell
                        activityViewController.popoverPresentationController?.sourceRect = cell.bounds
                        
                        self.present(activityViewController, animated: true, completion: nil)
                        
                    } else {
                        MXLog.debug("[RoomViewController] Contextual menu share failed. Text is nil for room id/event id: %@/%@", selectedComponent.event.roomId, selectedComponent.event.eventId)
                    }
                }
                
                self.hideContextualMenu(animated: true)
            } else if attachment?.type != .sticker {
                
                self.hideContextualMenu(animated: true)
                
                attachment?.prepareShare({ [weak self] (fileURL) in
                    guard let self = self, let fileURL = fileURL else {
                        return
                    }

                    self.documentInteractionController = UIDocumentInteractionController(url: fileURL)
                    self.documentInteractionController.delegate = self
                    
                    self.currentSharedAttachment = attachment
                    
                    if !self.documentInteractionController.presentOptionsMenu(from: self.view.frame, in: self.view, animated: true) {
                        self.documentInteractionController = nil
                        attachment?.onShareEnded()
                        self.currentSharedAttachment = nil
                    }
                }, failure: { [weak self] (error) in
                    guard let self = self, let error = error else {
                        return
                    }
                    
                    //Alert user
                    self.render(error: error)
                })
         
                // Start animation in case of download during attachment preparing
                cell.startProgressUI()
            }
            
        }
        
        // More action

        let moreMenuItem = RoomContextualMenuItem(menuAction: .more)
        moreMenuItem.action = {
            self.hideContextualMenu(animated: true)
            self.showAdditionalActionsMenu(selectedEvent: event, inCell: cell, animated: true)
        }

        // Actions list

        let actionItems = [favouriteMenuItem, copyMenuItem, shareMenuItem, moreMenuItem]
        
        return actionItems
    }
    
    // Display the additiontal event actions menu
    private func showAdditionalActionsMenu(selectedEvent: MXEvent, inCell: MXKRoomBubbleTableViewCell, animated: Bool) {
        
        if self.currentAlert != nil {
            self.currentAlert.dismiss(animated: false, completion: nil)
            self.currentAlert = nil
        }
        
        self.currentAlert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Add action for attachment
        if let attachment = inCell.bubbleData.attachment, BuildSettings.messageDetailsAllowSave {
            if attachment.type == .image || attachment.type == .video {
                self.currentAlert.addAction(UIAlertAction(title: VectorL10n.roomEventActionSave, style: .default, handler: { [weak self] (action) in
                    guard let self = self else {
                        return
                    }
                        
                    self.hideContextualMenu(animated: true)
                    
                    self.activityPresenter.presentActivityIndicator(on: self.view, animated: true)
                    
                    attachment.save { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
                    } failure: { [weak self] (error) in
                        guard let self = self, let error = error else {
                            return
                        }
                        
                        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
                                
                        //Alert user
                        self.render(error: error)
                    }

                    // Start animation in case of download during attachment preparing
                    inCell.startProgressUI()
                }))
            }
        }
        
        // Check status of the selected event
        if selectedEvent.sentState == MXEventSentStateSent {
            self.currentAlert.addAction(UIAlertAction(title: VectorL10n.roomEventActionPermalink, style: .default, handler: { [weak self] (action) in
                guard let self = self else {
                    return
                }
                
                self.hideContextualMenu(animated: true)
                
                // Create a Tchap permalink
                if let permalink = Tools.permalink(toEvent: selectedEvent.eventId, inRoom: selectedEvent.roomId) {
                    MXKPasteboardManager.shared.pasteboard.string = permalink
                } else {
                    MXLog.debug("[FavouriteMessagesViewController] Contextual menu permalink action failed. Permalink is nil room id/event id: %@/%@", selectedEvent.roomId, selectedEvent.eventId)
                }
            }))
        }
        
        self.currentAlert.addAction(UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: { [weak self] (action) in
            guard let self = self else {
                return
            }
            
            self.hideContextualMenu(animated: true)
        }))
        
        // Do not display empty action sheet
        if currentAlert.actions.count > 1 {
            let bubbleComponentIndex = inCell.bubbleData.bubbleComponentIndex(forEventId: selectedEvent.eventId)
            
            let sourceRect = inCell.componentFrameInContentView(for: bubbleComponentIndex)
            
            self.currentAlert.mxk_setAccessibilityIdentifier("RoomVCEventMenuAlert")
            self.currentAlert.popoverPresentationController?.sourceView = inCell
            self.currentAlert.popoverPresentationController?.sourceRect = sourceRect
            self.present(self.currentAlert, animated: animated, completion: nil)
        } else {
            self.currentAlert = nil
        }
    }

    private func showContextualMenu(event: MXEvent, singleTapGesture: Bool, cell: MXKRoomBubbleTableViewCell, animated: Bool) {
        guard !self.roomContextualMenuPresenter.isPresenting else {
            return
        }
        
        guard let cellData = cell.bubbleData as? FavouriteMessagesBubbleCellData else {
            fatalError("FavouriteMessagesBubbleCellData is not of the expected class")
        }
        
        let contextualMenuItems = self.contextualMenuItems(event: event, cell: cell)
        let bubbleComponentFrameInOverlayView = CGRect.null
        
        if self.roomContextualMenuViewController == nil {
            self.roomContextualMenuViewController = RoomContextualMenuViewController.instantiate()
            self.roomContextualMenuViewController.delegate = self
        }
        
        self.roomContextualMenuViewController.update(contextualMenuItems: contextualMenuItems, reactionsMenuViewModel: nil)
        
        self.enableOverlayContainerUserInteractions(enable: true)
        
        self.roomContextualMenuPresenter.present(
            roomContextualMenuViewController: self.roomContextualMenuViewController,
            from: self,
            on: self.overlayContainerView,
            contentToReactFrame: bubbleComponentFrameInOverlayView,
            fromSingleTapGesture: singleTapGesture,
            animated: animated) {
            self.viewModel.process(viewAction: .selectEvent(event: event, cellData: cellData))
        }
    }
        
    private func hideContextualMenu(animated: Bool, completion: (() -> Void)? = nil) {
        self.hideContextualMenu(animated: animated, cancelEventSelection: true, completion: completion)
    }
    
    private func hideContextualMenu(animated: Bool, cancelEventSelection: Bool, completion: (() -> Void)? = nil) {
        guard self.roomContextualMenuPresenter.isPresenting else {
            return
        }
        
        if cancelEventSelection {
            self.cancelEventSelection()
        }
        
        self.roomContextualMenuPresenter.hideContextualMenu(animated: animated) {
            self.enableOverlayContainerUserInteractions(enable: false)
            
            if let completion = completion {
                completion()
            }
        }
    }

    private func enableOverlayContainerUserInteractions(enable: Bool) {
        self.tableView.scrollsToTop = !enable
        self.overlayContainerView.isUserInteractionEnabled = enable
    }
    
    // MARK: - Actions

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
    
    private func cancelEventSelection() {
        
        if self.currentAlert != nil {
            self.currentAlert.dismiss(animated: false, completion: nil)
            self.currentAlert = nil
        }
        
        self.viewModel.process(viewAction: .cancelSelection)
    }
    
    private func cancelImageSharing() {
        self.documentInteractionController = nil
        
        if self.currentSharedAttachment != nil {
            self.currentSharedAttachment.onShareEnded()
            self.currentSharedAttachment = nil
        }
    }
}


// MARK: - FavouriteMessagesViewModelViewDelegate
extension FavouriteMessagesViewController: FavouriteMessagesViewModelViewDelegate {
    
    func favouriteMessagesViewModel(_ viewModel: FavouriteMessagesViewModelType, didUpdateViewState viewState: FavouriteMessagesViewState) {
        self.render(viewState: viewState)
    }
}


// MARK: - UITableViewDataSource
extension FavouriteMessagesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.roomBubbleCellDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let favouriteMessagesCell: MXKRoomBubbleTableViewCell & NibReusable & Themable
        
        let cellData = self.roomBubbleCellDataList[indexPath.row]

        // Launch an antivirus scan on events contained in bubble data if needed
        self.scanBubbleDataIfNeeded(cellData: cellData)
        
        if cellData.showAntivirusScanStatus {
            favouriteMessagesCell = tableView.dequeueReusableCell(for: indexPath, cellType: FavouriteAttachmentAntivirusScanStatusBubbleCell.self)
        } else if cellData.isAttachmentWithThumbnail {
            favouriteMessagesCell = tableView.dequeueReusableCell(for: indexPath, cellType: FavouriteIncomingAttachmentBubbleCell.self)
        } else {
            favouriteMessagesCell = tableView.dequeueReusableCell(for: indexPath, cellType: FavouriteIncomingTextMsgBubbleCell.self)
        }
        
        favouriteMessagesCell.render(cellData)
        favouriteMessagesCell.delegate = self
        favouriteMessagesCell.addTimestampLabel(forComponent: UInt(cellData.mostRecentComponentIndex))
        
        // Check whether an event is currently selected: the other messages are then blurred
        if self.isEventSelected {
            // Check whether the selected event belongs to this bubble
            if cellData.selectedComponentIndex != NSNotFound {
                favouriteMessagesCell.selectComponent(UInt(cellData.selectedComponentIndex), showEditButton: false, showTimestamp: cellData.showTimestampForSelectedComponent)
            } else {
                favouriteMessagesCell.blurred = true
            }
        }

        return favouriteMessagesCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cellData = self.roomBubbleCellDataList[indexPath.row]
        
        if cellData.isAttachmentWithThumbnail {
            return FavouriteIncomingAttachmentBubbleCell.height(for: cellData, withMaximumWidth: tableView.frame.size.width)
        }
        
        return UITableView.automaticDimension
    }
}

// MARK: - UITableViewDelegate
extension FavouriteMessagesViewController: UITableViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        guard self.isViewAppearedOnce else {
            return
        }

        // Check if a scroll beyond scroll view content occurs
        let distanceFromBottom = scrollView.contentSize.height - scrollView.contentOffset.y
        if distanceFromBottom < scrollView.frame.size.height {
            self.viewModel.process(viewAction: .loadData)
        }
    }
}

// MARK: - MXKCellRenderingDelegate
extension FavouriteMessagesViewController: MXKCellRenderingDelegate {
    func cell(_ cell: MXKCellRendering!, didRecognizeAction actionIdentifier: String!, userInfo: [AnyHashable: Any]! = [:]) {
        guard let favouriteMessagesCell = cell as? MXKRoomBubbleTableViewCell else {
            return
        }
        
        let tappedEvent: MXEvent
        if userInfo != nil, let info = userInfo[kMXKRoomBubbleCellEventKey] as? MXEvent {
            tappedEvent = info
        } else {
            tappedEvent = favouriteMessagesCell.bubbleData.events[0]
        }

        switch actionIdentifier {
        case kMXKRoomBubbleCellLongPressOnEvent:
            self.showContextualMenu(event: tappedEvent, singleTapGesture: false, cell: favouriteMessagesCell, animated: true)
        default:
            self.viewModel.process(viewAction: .tapEvent(roomId: (tappedEvent.roomId), eventId: (tappedEvent.eventId)))
        }
    }
    
    func cell(_ cell: MXKCellRendering!, shouldDoAction actionIdentifier: String!, userInfo: [AnyHashable: Any]! = [:], defaultValue: Bool) -> Bool {
        var shouldDoAction = defaultValue
        
        guard let favouriteMessagesCell = cell as? MXKRoomBubbleTableViewCell else {
            fatalError("MXKRoomBubbleTableViewCell is not of the expected class")
        }
        
        guard let cellData = favouriteMessagesCell.bubbleData as? FavouriteMessagesBubbleCellData else {
            fatalError("FavouriteMessagesBubbleCellData is not of the expected class")
        }
        
        // Try to catch universal link supported by the app
        if actionIdentifier == kMXKRoomBubbleCellShouldInteractWithURL, let url = userInfo[kMXKRoomBubbleCellUrl] as? URL {
            
            // When a link refers to a room alias/id, a user id or an event id, the non-ASCII characters (like '#' in room alias) has been escaped
            // to be able to convert it into a legal URL string.
            guard let absoluteURLString = url.absoluteString.removingPercentEncoding else {
                fatalError("absoluteURLString should be defined")
            }
            
            // Check whether this is a permalink to handle it directly into the app
            if Tools.isPermaLink(url) {
                // Patch: catch up all the permalinks even if they are not all supported by Tchap for the moment,
                // like the permalinks with a userid.
                shouldDoAction = false
                
                // iOS Patch: fix urls before using it
                let fixedURL = Tools.fixURL(withSeveralHashKeys: url)
                // In some cases (for example when the url has multiple '#'), the '%' character has been espaced twice in the provided url (we got %2524 for '$').
                // We decided to remove percent encoding on all the fragment here. A second attempt will take place during the parameters parsing.
                if let fragment = fixedURL?.fragment?.removingPercentEncoding {
                    self.viewModel.process(viewAction: .handlePermalinkFragment(fragment: fragment))
                }
            
            // Click on a member. Do nothing in favourites case.
            } else if MXTools.isMatrixUserIdentifier(absoluteURLString) {
                MXLog.debug("[FavouriteMessagesViewController] showMemberDetails: Do nothing: \(absoluteURLString)")
                
            // Open the clicked room
            } else if MXTools.isMatrixRoomIdentifier(absoluteURLString) || MXTools.isMatrixRoomAlias(absoluteURLString) {
                shouldDoAction = false
                self.viewModel.process(viewAction: .handlePermalinkFragment(fragment: absoluteURLString))
            
            // ReRequest keys
            } else if absoluteURLString.hasPrefix(EventFormatterOnReRequestKeysLinkAction) {
                let arguments = absoluteURLString.components(separatedBy: EventFormatterLinkActionSeparator)
                if arguments.count > 1 {
                    let eventId = arguments[1]
                    
                    for event in cellData.events where eventId == event.eventId {
                        // Make the re-request
                        cellData.mxSession.crypto.reRequestRoomKey(for: event)
                        self.showExplanationAlert(event: event)
                        break
                    }
                }
                shouldDoAction = false
                
            // Retrieve the type of interaction expected with the URL (See UITextItemInteraction)
            } else if let urlItemInteractionValue = userInfo[kMXKRoomBubbleCellUrlItemInteraction] as? Int {
                // Fallback case for external links
                switch UITextItemInteraction(rawValue: urlItemInteractionValue) {
                case .invokeDefaultAction:
                    let roomMessageURLType = self.roomMessageURLParser.parseURL(url)
                    
                    switch roomMessageURLType {
                    case .appleDataDetector:
                        // Keep the default OS behavior on single tap when UITextView data detector detect a known type.
                        shouldDoAction = true
                    case .dummy:
                        // Do nothing for dummy links
                        shouldDoAction = false
                    default:
                        if let tappedEvent = userInfo[kMXKRoomBubbleCellEventKey] as? MXEvent, let format = tappedEvent.content["format"] as? String {
                            
                            //  if an html formatted body exists
                            if format == kMXRoomMessageFormatHTML, let formattedBody = tappedEvent.content["formatted_body"] as? String {
                                if let visibleURL = FormattedBodyParser().getVisibleURL(forURL: url, inFormattedBody: formattedBody), url != visibleURL {
                                    //  urls are different, show confirmation alert
                                    let message = VectorL10n.externalLinkConfirmationMessage(visibleURL.absoluteString, url.absoluteString)
                                    
                                    let alert = UIAlertController(title: VectorL10n.externalLinkConfirmationTitle, message: message, preferredStyle: .alert)
                                    
                                    let continueAction = UIAlertAction(title: VectorL10n.continue, style: .default) { (action) in
                                        UIApplication.shared.vc_open(url) { (success) in
                                            if !success {
                                                self.showUnableToOpenLinkErrorAlert()
                                            }
                                        }
                                    }
                                    
                                    let cancelAction = UIAlertAction(title: VectorL10n.cancel, style: .cancel, handler: nil)
                                    
                                    alert.addAction(continueAction)
                                    alert.addAction(cancelAction)
                                    
                                    self.present(alert, animated: true, completion: nil)
                                    return false
                                }
                            }
                        }
                        UIApplication.shared.vc_open(url) { (success) in
                            if !success {
                                self.showUnableToOpenLinkErrorAlert()
                            }
                        }
                        shouldDoAction = false
                }
                case .presentActions:
                    // Retrieve the tapped event
                    if let favouriteMessagesCell = cell as? MXKRoomBubbleTableViewCell, let tappedEvent = userInfo[kMXKRoomBubbleCellEventKey] as? MXEvent {
                        // Long press on link, present room contextual menu.
                        self.showContextualMenu(event: tappedEvent, singleTapGesture: false, cell: favouriteMessagesCell, animated: true)
                    }
                    
                    shouldDoAction = false
                case .preview:
                    // Force touch on link, let MXKRoomBubbleTableViewCell UITextView use default peek and pop behavior.
                    break
                default:
                    break
                }
            }
        } else {
            self.showUnableToOpenLinkErrorAlert()
        }
        
        return shouldDoAction
    }
}

// MARK: - RoomContextualMenuViewControllerDelegate
extension FavouriteMessagesViewController: RoomContextualMenuViewControllerDelegate {
    
    func roomContextualMenuViewControllerDidTapBackgroundOverlay(_ viewController: RoomContextualMenuViewController) {
        self.hideContextualMenu(animated: true)
    }
}

// MARK: - UIDocumentInteractionControllerDelegate
extension FavouriteMessagesViewController: UIDocumentInteractionControllerDelegate {

    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    // Preview presented/dismissed on document.  Use to set up any HI underneath.
    func documentInteractionControllerWillBeginPreview(_ controller: UIDocumentInteractionController) {
        self.documentInteractionController = controller
    }

    func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
        self.cancelImageSharing()
    }

    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        self.cancelImageSharing()
    }

    func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
        self.cancelImageSharing()
    }
}
