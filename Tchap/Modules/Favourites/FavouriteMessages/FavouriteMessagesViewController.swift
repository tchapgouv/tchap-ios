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
    
    // MARK: Private

    private var viewModel: FavouriteMessagesViewModelType!
    private var currentStyle: Style!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var isViewAppearedOnce: Bool = false
    private var titleView: RoomTitleView!
    
    private var roomBubbleCellDataList: [RoomBubbleCellData] = []
    private var roomMessageURLParser: RoomMessageURLParser!
    private var mxEventDidDecryptNotificationObserver: Any!
    private var currentAlert: UIAlertController!

    // MARK: - Setup
    
    class func instantiate(with viewModel: FavouriteMessagesViewModelType, style: Style = Variant1Style.shared) -> FavouriteMessagesViewController {
        let viewController = StoryboardScene.FavouriteMessagesViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.currentStyle = style
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
        return self.currentStyle.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(style: Style) {
        self.currentStyle = style
        
        self.view.backgroundColor = style.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            style.applyStyle(onNavigationBar: navigationBar)
        }
    }

    private func userThemeDidChange() {
        self.update(style: self.currentStyle)
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
        case .sorted:
            self.updateTitleInfo()
        case .loaded(roomBubbleCellDataList: let roomBubbleCellDataList):
            self.renderLoaded(roomBubbleCellDataList: roomBubbleCellDataList)
        case .error(let error):
            self.render(error: error)
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
    
    private func render(error: Error) {
        self.activityPresenter.removeCurrentActivityIndicator(animated: true)
        self.errorPresenter.presentError(from: self, forError: error, animated: true, handler: nil)
    }
    
    private func setupTitleView() {
        // Build title view
        self.titleView = RoomTitleView.instantiate(style: self.currentStyle)
        self.updateTitleInfo()
        self.navigationItem.titleView = titleView
    }
    
    private func updateTitleInfo() {
        self.titleView.fill(roomTitleViewModel: self.viewModel.titleViewModel)
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
        //TODO show alert
//        [[AppDelegate theDelegate] showAlertWithTitle:[NSBundle mxk_localizedStringForKey:@"error"]
//                                              message:NSLocalizedStringFromTable(@"room_message_unable_open_link_error_message", @"Vector", nil)];
    }
    
    private func showExplanationAlert(event: MXEvent) {
        // Observe kMXEventDidDecryptNotification to remove automatically the dialog
        // if the user has shared the keys from another device
        let alert = UIAlertController(title: VectorL10n.rerequestKeysAlertTitle, message: VectorL10n.rerequestKeysAlertMessage, preferredStyle: .alert)
        
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
    
    // MARK: - Actions

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
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

extension FavouriteMessagesViewController: MXKCellRenderingDelegate {
    func cell(_ cell: MXKCellRendering!, didRecognizeAction actionIdentifier: String!, userInfo: [AnyHashable: Any]! = [:]) {
        if let favouriteMessagesCell = cell as? MXKRoomBubbleTableViewCell, let cellData = favouriteMessagesCell.bubbleData {
            
            switch actionIdentifier {
            case kMXKRoomBubbleCellLongPressOnEvent:
                print("longpress")
            default:
                self.viewModel.process(viewAction: .tapEvent(roomId: (cellData.roomId), eventId: (cellData.events[0].eventId)))
            }
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
                    self.viewModel.process(viewAction: .tapAction(fragment: fragment))
                }
            
            // Click on a member. Do nothing in favourites case.
            } else if MXTools.isMatrixUserIdentifier(absoluteURLString) {
                    print("[FavouriteMessagesViewController] showMemberDetails: Do nothing: \(absoluteURLString)")
                
            // Open the clicked room
            } else if MXTools.isMatrixRoomIdentifier(absoluteURLString) || MXTools.isMatrixRoomAlias(absoluteURLString) {
                shouldDoAction = false
                self.viewModel.process(viewAction: .tapAction(fragment: absoluteURLString))
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
                    if let tappedEvent = userInfo[kMXKRoomBubbleCellEventKey] {
                        // Long press on link, present room contextual menu.
                        //TODO show contextual menu
                        print("[self showContextualMenuForEvent:tappedEvent fromSingleTapGesture:NO cell:cell animated:YES];")
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
