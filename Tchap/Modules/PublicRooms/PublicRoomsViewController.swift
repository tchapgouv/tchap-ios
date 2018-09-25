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

protocol PublicRoomsViewControllerDelegate: class {
    func publicRoomsViewController(_ publicRoomsViewController: PublicRoomsViewController, didSelect publicRoom: MXPublicRoom)
}

final class PublicRoomsViewController: UITableViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let cellHeight: CGFloat = 72.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    // MARK: Private
    
    private var publicRoomsDataSource: PublicRoomsDataSource!
    
    private var searchController: UISearchController?
    private var currentStyle: Style!
    
    // MARK: Public
    
    weak var delegate: PublicRoomsViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(dataSource: PublicRoomsDataSource, style: Style = Variant1Style.shared) -> PublicRoomsViewController {
        let viewController = StoryboardScene.PublicRoomsViewController.initialScene.instantiate()
        viewController.currentStyle = style
        viewController.publicRoomsDataSource = dataSource
        return viewController
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.title = TchapL10n.publicRoomsTitle
        
        self.setupViews()
        self.setupDataSource()
        
        self.publicRoomsDataSource.search(with: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.userThemeDidChange()
    }        
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.currentStyle.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        self.setupSearchController()

        self.clearsSelectionOnViewWillAppear = true
        self.tableView.rowHeight = Constants.cellHeight
        self.tableView.tableFooterView = UIView()
    }
    
    private func setupDataSource() {
        self.publicRoomsDataSource?.setup(tableView: self.tableView)
    }
    
    private func setupSearchController() {
        let searchController = UISearchController(searchResultsController: nil)
        
        self.definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = TchapL10n.publicRoomsSearchBarPlaceholder
        searchController.hidesNavigationBarDuringPresentation = false
        
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = searchController
        } else {
            self.tableView.tableHeaderView = searchController.searchBar
        }
        
        self.searchController = searchController
    }
    
    private func userThemeDidChange() {
        self.update(style: self.currentStyle)
    }
}

// MARK: - UITableViewDelegate
extension PublicRoomsViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let publicRoom = publicRoomsDataSource.room(at: indexPath) else {
            return
        }
        self.delegate?.publicRoomsViewController(self, didSelect: publicRoom)
    }
}

// MARK: - Stylable
extension PublicRoomsViewController: Stylable {
    func update(style: Style) {
        self.currentStyle = style
        
        self.view.backgroundColor = style.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            style.applyStyle(onNavigationBar: navigationBar)
        }
        
        if let searchBar = self.searchController?.searchBar {
            if #available(iOS 11.0, *) {
                searchBar.tintColor = style.barActionColor
            } else {
                searchBar.tintColor = style.primarySubTextColor
            }
        }
    }
}

// MARK: - UISearchResultsUpdating
extension PublicRoomsViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        self.publicRoomsDataSource?.search(with: searchText)
    }
}
