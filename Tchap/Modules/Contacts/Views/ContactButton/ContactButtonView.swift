/*
 Copyright 2019 Vector Creations Ltd
 
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

@objcMembers class ContactButtonView: UITableViewCell {
    
    @IBOutlet private(set) weak var iconView: UIImageView!
    @IBOutlet private(set) weak var actionLabel: UILabel!
    
    private(set) var viewModel: ContactButtonViewModelType!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.update(theme: ThemeService.shared().theme)
    }
    
    class func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    class func defaultReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    func render(model: ContactButtonViewModelType) {
        self.viewModel = model
        
        self.iconView.image = model.iconImage
        self.actionLabel.text = model.action
    }
}

// MARK: - Theme
extension ContactButtonView: Themable {
    func update(theme: Theme) {
        self.actionLabel.textColor = theme.headerTextPrimaryColor
        self.actionLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
    }
}
