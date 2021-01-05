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
    private var theme: Theme!
    private var keyboardAvoider: KeyboardAvoider?
    private var errorPresenter: MXKErrorPresentation!
    private var activityPresenter: ActivityIndicatorPresenter!
    private var isViewAppearedOnce: Bool = false
    
    private var roomBubbleCellDataList: [RoomBubbleCellData] = []

    // MARK: - Setup
    
    class func instantiate(with viewModel: FavouriteMessagesViewModelType) -> FavouriteMessagesViewController {
        let viewController = StoryboardScene.FavouriteMessagesViewController.initialScene.instantiate()
        viewController.viewModel = viewModel
        viewController.theme = ThemeService.shared().theme
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
        self.activityPresenter = ActivityIndicatorPresenter()
        self.errorPresenter = MXKErrorAlertPresentation()
        
        self.registerThemeServiceDidChangeThemeNotification()
        self.update(theme: self.theme)
        
        self.viewModel.viewDelegate = self

        self.viewModel.process(viewAction: .loadData)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        return self.theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func update(theme: Theme) {
        self.theme = theme
        
        self.view.backgroundColor = theme.headerBackgroundColor
        self.tableView.backgroundColor = theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            theme.applyStyle(onNavigationBar: navigationBar)
        }
    }
    
    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }
    
    @objc private func themeDidChange() {
        self.update(theme: ThemeService.shared().theme)
    }
    
    private func setupTableView() {
        self.tableView.contentInset = Constants.contentInset
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = Constants.estimatedRowHeight
        self.tableView.register(cellType: FavouriteMessagesViewCell.self)
        
        self.tableView.tableFooterView = UIView()
    }
    
    private func setupViews() {
        let cancelBarButtonItem = MXKBarButtonItem(title: VectorL10n.cancel, style: .plain) { [weak self] in
            self?.cancelButtonAction()
        }
        
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem
        
        self.setupTableView()
    }

    private func render(viewState: FavouriteMessagesViewState) {
        switch viewState {
        case .loading:
            self.renderLoading()
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

    
    // MARK: - Actions

    private func cancelButtonAction() {
        self.viewModel.process(viewAction: .cancel)
    }
}


// MARK: - FavouriteMessagesViewModelViewDelegate
extension FavouriteMessagesViewController: FavouriteMessagesViewModelViewDelegate {

    func favouriteMessagesViewModel(_ viewModel: FavouriteMessagesViewModelType, didUpdateViewState viewSate: FavouriteMessagesViewState) {
        self.render(viewState: viewSate)
    }
}


// MARK: - UITableViewDataSource
extension FavouriteMessagesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.roomBubbleCellDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let favouriteMessagesCell = tableView.dequeueReusableCell(for: indexPath, cellType: FavouriteMessagesViewCell.self)

        let roomBubbleCellData = self.roomBubbleCellDataList[indexPath.row]

        favouriteMessagesCell.update(theme: self.theme)
        favouriteMessagesCell.fill(with: roomBubbleCellData)

        return favouriteMessagesCell
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
