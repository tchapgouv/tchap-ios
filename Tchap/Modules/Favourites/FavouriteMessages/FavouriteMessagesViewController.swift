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

    // MARK: - Setup
    
    class func instantiate(with viewModel: FavouriteMessagesViewModelType, style: Style = Variant1Style.shared) -> FavouriteMessagesViewController {
        let viewController = StoryboardScene.FavouriteMessagesViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.currentStyle = style
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // Remove back bar button title when pushing a view controller
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            
        self.setupViews()
        self.setupLongPressGestureRecognizer()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
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
        
        self.tableView.tableFooterView = UIView()
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.leftBarButtonItem = cancelBarButtonItem
        
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
        self.titleView.fill(roomTitleViewModel: self.viewModel.titleViewModel)
        self.navigationItem.titleView = titleView
    }
    
    private func updateTitleInfo() {
        self.titleView.fill(roomTitleViewModel: self.viewModel.titleViewModel)
    }
    
    private func setupLongPressGestureRecognizer() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        gestureRecognizer.delaysTouchesBegan = true
        self.tableView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else {
            return
        }
        self.viewModel?.process(viewAction: .longPress)
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
    
    func favouriteMessagesViewModel(_ viewModel: FavouriteMessagesViewModelType, didLongPressForEventId eventId: String) {
        print(eventId)
    }
    
    func favouriteMessagesViewModelDidUpdateDataSource(_ viewModel: FavouriteMessagesViewModelType) {
        self.tableView.reloadData()
    }
}


// MARK: - UITableViewDataSource
extension FavouriteMessagesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.roomBubbleCellDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let favouriteMessagesCell: MXKRoomBubbleTableViewCell & NibReusable & Themable
//        let showEncryptionBadge = false
        
        let cellData = self.roomBubbleCellDataList[indexPath.row]
        
        // Sanity check
        if cellData.conforms(to: MXKRoomBubbleCellDataStoring.self) {
//            id<MXKRoomBubbleCellDataStoring> bubbleData = (id<MXKRoomBubbleCellDataStoring>)cellData;
//            if (bubbleData.showAntivirusScanStatus)
//            {
            
            if cellData.isAttachmentWithThumbnail {
                favouriteMessagesCell = tableView.dequeueReusableCell(for: indexPath, cellType: FavouriteIncomingAttachmentBubbleCell.self)
            } else {
                favouriteMessagesCell = tableView.dequeueReusableCell(for: indexPath, cellType: FavouriteIncomingTextMsgBubbleCell.self)
            }
            
            
        } else {
            favouriteMessagesCell = tableView.dequeueReusableCell(for: indexPath, cellType: FavouriteIncomingTextMsgBubbleCell.self)
        }
        
        favouriteMessagesCell.render(cellData)

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
