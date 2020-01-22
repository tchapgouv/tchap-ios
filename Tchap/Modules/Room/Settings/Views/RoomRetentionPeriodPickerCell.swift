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

@objc protocol RoomRetentionPeriodPickerCellDelegate: class {
    func roomRetentionPeriodPickerCell(_ cell: RoomRetentionPeriodPickerCell, didSelectRetentionPeriodInDays period: uint)
}

@objcMembers class RoomRetentionPeriodPickerCell: UITableViewCell, Stylable, UIPickerViewDataSource, UIPickerViewDelegate {
    
    private enum RoomRetentionPeriod {
        static let min: uint = 1
        static let max: uint = 365
    }
    
    @IBOutlet private weak var pickerView: UIPickerView!
    
    private var retentionPeriodValuesNb: Int!
    
    private(set) var style: Style!
    
    weak var delegate: RoomRetentionPeriodPickerCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        retentionPeriodValuesNb = (Int)(RoomRetentionPeriod.max - RoomRetentionPeriod.min) + 1
        self.update(style: Variant2Style.shared)
    }
    
    static func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    static func defaultReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    func update(style: Style) {
        self.style = style
        self.pickerView.backgroundColor = style.backgroundColor
        self.pickerView.tintColor = style.primaryTextColor
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // Make the picker wrap around by adding a set of values before and after -> 3 sets
        return 3 * self.retentionPeriodValuesNb
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row % self.retentionPeriodValuesNb + 1)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let period = ((uint)(row % self.retentionPeriodValuesNb + 1))
        self.delegate?.roomRetentionPeriodPickerCell(self, didSelectRetentionPeriodInDays: period)
    }
    
    func scrollTo(retentionPeriodInDays: uint, animated: Bool) {
        let period = retentionPeriodInDays < RoomRetentionPeriod.min ? RoomRetentionPeriod.min : retentionPeriodInDays > RoomRetentionPeriod.max ? RoomRetentionPeriod.max : retentionPeriodInDays
        self.pickerView.selectRow((Int)(period - 1) + self.retentionPeriodValuesNb, inComponent: 0, animated: animated)
    }
}
