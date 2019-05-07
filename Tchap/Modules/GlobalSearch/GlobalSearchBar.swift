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
import Reusable

protocol GlobalSearchBarDelegate: class {
    func globalSearchBar(_ globalSearchBar: GlobalSearchBar, textDidChange searchText: String?)
}

/// The search bar used to perform global search
@objcMembers
final class GlobalSearchBar: UIView, NibLoadable {
    
    // MARK: - Properties
    
    @IBOutlet private weak var searchBar: UISearchBar!
    
    // MARK: Public
    
    weak var delegate: GlobalSearchBarDelegate?
    
    // MARK: - Setup
    
    class func instantiate() -> GlobalSearchBar {
        return GlobalSearchBar.loadFromNib()
    }
    
    // MARK: - Life cycle
    
    override func awakeFromNib() {
        self.searchBar.delegate = self
        
        self.searchBar.barStyle = .black
        self.searchBar.searchBarStyle = .minimal
    }
    
    // MARK: - Overrides
    
    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
    
    override func becomeFirstResponder() -> Bool {
        let becomeFirstResponder = super.becomeFirstResponder()
        self.searchBar.becomeFirstResponder()
        return becomeFirstResponder
    }
    
    override func resignFirstResponder() -> Bool {
        self.searchBar.resignFirstResponder()
        return super.resignFirstResponder()
    }
    
    // MARK: - Public methods
    
    func resetSearchText() {
        self.searchBar.text = nil
        self.searchBar.showsCancelButton = false
        self.delegate?.globalSearchBar(self, textDidChange: nil)
    }
}

// MARK: - UISearchBarDelegate
extension GlobalSearchBar: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.resetSearchText()
        self.searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.delegate?.globalSearchBar(self, textDidChange: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
        self.searchBar.showsCancelButton = false
    }
}
