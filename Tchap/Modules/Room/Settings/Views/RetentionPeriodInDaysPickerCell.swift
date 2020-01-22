/*
 Copyright 2020 Vector Creations Ltd
 
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

@objc protocol RetentionPeriodInDaysPickerCellDelegate: class {
    func retentionPeriodInDaysPickerCell(_ cell: RetentionPeriodInDaysPickerCell, didSelect period: uint)
}

@objcMembers class RetentionPeriodInDaysPickerCell: UITableViewCell, Stylable, RetentionPeriodInDaysPickerContentViewDelegate {
    
    @IBOutlet private weak var retentionPeriodInDaysPickerContentView: RetentionPeriodInDaysPickerContentView!
    
    private(set) var style: Style!
    
    weak var delegate: RetentionPeriodInDaysPickerCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.update(style: Variant2Style.shared)
        
        self.retentionPeriodInDaysPickerContentView.delegate = self
    }
    
    static func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    static func defaultReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    func update(style: Style) {
        self.style = style
        self.retentionPeriodInDaysPickerContentView.update(style: style)
    }
    
    func scrollTo(retentionPeriodInDays: uint, animated: Bool) {
        self.retentionPeriodInDaysPickerContentView.scrollTo(retentionPeriodInDays: retentionPeriodInDays, animated: animated)
    }
    
    func retentionPeriodInDaysPickerContentView(_ view: RetentionPeriodInDaysPickerContentView, didSelect period: uint) {
        self.delegate?.retentionPeriodInDaysPickerCell(self, didSelect: period)
    }
}
