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

protocol PublicRoomsViewControllerDelegate: AnyObject {
    func publicRoomsViewController(_ publicRoomsViewController: PublicRoomsViewController, didSelect publicRoom: MXPublicRoom)
}

final class PublicRoomsViewController: UITableViewController {
    
    // MARK: - Constants
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    // MARK: Private
    
    private var publicRoomsDataSource: PublicRoomsDataSource!
    
    private var searchController: UISearchController?
    
    // MARK: Public
    
    weak var delegate: PublicRoomsViewControllerDelegate?
    
    // MARK: - Setup
    
    class func instantiate(dataSource: PublicRoomsDataSource) -> PublicRoomsViewController {
        let viewController = StoryboardScene.PublicRoomsViewController.initialScene.instantiate()
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
        self.setupNavigationBar()
        
        self.publicRoomsDataSource.search(with: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.userThemeDidChange()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.searchController?.searchBar.resignFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 13.0, *) {
            // iOS 13 issue: When the search bar is shown, the navigation bar color is replaced with the background color of the TableView
            // Patch: Always show the search bar on iOS 13
            self.navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            // Enable to hide search bar on scrolling after first time view appear
            self.navigationItem.hidesSearchBarWhenScrolling = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeService.shared().theme.statusBarStyle
    }
    
    // MARK: - Private
    
    private func setupViews() {
        self.setupSearchController()

        self.clearsSelectionOnViewWillAppear = true
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 80
        
        self.tableView.tableFooterView = UIView()
    }
    
    private func setupDataSource() {
        self.publicRoomsDataSource?.setup(tableView: self.tableView)
    }
    
    private func setupSearchController() {
        let searchController = UISearchController(searchResultsController: nil)
        
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = TchapL10n.publicRoomsSearchBarPlaceholder
        searchController.hidesNavigationBarDuringPresentation = false
        
        self.navigationItem.searchController = searchController
        // Make the search bar visible on first view appearance
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        self.definesPresentationContext = true
        
        self.searchController = searchController
    }
    
    private func setupNavigationBar() {
        let cancelButton = UIBarButtonItem(title: TchapL10n.actionCancel,
                                           style: .plain,
                                           target: self,
                                           action: #selector(didTapCancel))
        self.navigationItem.leftBarButtonItem = cancelButton
    }
    
    @objc private func didTapCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func userThemeDidChange() {
        self.updateTheme()
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

// MARK: - Theme
private extension PublicRoomsViewController {
    func updateTheme() {
        self.view.backgroundColor = ThemeService.shared().theme.backgroundColor
        
        if let navigationBar = self.navigationController?.navigationBar {
            ThemeService.shared().theme.applyStyle(onNavigationBar: navigationBar)
        }
        
        if let searchBar = self.searchController?.searchBar {
            ThemeService.shared().theme.applyStyle(onSearchBar: searchBar)
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
