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

@objc protocol RetentionPeriodPickerCellDelegate: AnyObject {
    func retentionPeriodPickerCell(_ cell: RetentionPeriodPickerCell, didSelect periodInDays: uint)
}

@objcMembers class RetentionPeriodPickerCell: UITableViewCell, RetentionPeriodPickerContentViewDelegate {
    
    @IBOutlet private weak var retentionPeriodPickerContentView: RetentionPeriodPickerContentView!
    
    weak var delegate: RetentionPeriodPickerCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.updateTheme()
        
        self.retentionPeriodPickerContentView.delegate = self
    }
    
    static func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    static func defaultReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    func updateTheme() {
        self.retentionPeriodPickerContentView.updateTheme()
    }
    
    func updatePickerWith(retentionPeriodInDays: uint, animated: Bool) {
        self.retentionPeriodPickerContentView.updatePickerWith(retentionPeriodInDays: retentionPeriodInDays, animated: animated)
    }
    
    func retentionPeriodPickerContentView(_ view: RetentionPeriodPickerContentView, didSelect periodInDays: uint) {
        self.delegate?.retentionPeriodPickerCell(self, didSelect: periodInDays)
    }
}
