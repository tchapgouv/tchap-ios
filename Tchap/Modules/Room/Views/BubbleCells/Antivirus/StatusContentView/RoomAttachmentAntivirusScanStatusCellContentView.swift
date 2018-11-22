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

@objc final class RoomAttachmentAntivirusScanStatusCellContentView: UIView, NibOwnerLoadable, Stylable {
    
    // MARK: - Properties
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var fileInfoLabel: UILabel!
    
    private var style: Style!
    
    // MARK: - Setup
    
    private func commonInit() {
        self.update(style: Variant1Style.shared)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.loadNibContent()
        self.commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        self.commonInit()
    }
    
    // MARK: - Public
    
    @objc func fill(with viewModel: RoomAttachmentAntivirusScanStatusViewModel) {
        self.iconImageView.image = viewModel.icon
        self.titleLabel.text = viewModel.title
        self.fileInfoLabel.text = viewModel.fileInfo
    }
    
    // MARK: - Stylable
    
    func update(style: Style) {
        self.style = style
        
        self.titleLabel.textColor = self.style.primaryTextColor
        self.fileInfoLabel.textColor = self.style.primaryTextColor
    }
}
