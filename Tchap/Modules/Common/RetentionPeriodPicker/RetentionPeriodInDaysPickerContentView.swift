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

protocol RetentionPeriodInDaysPickerContentViewDelegate: class {
    func retentionPeriodInDaysPickerContentView(_ view: RetentionPeriodInDaysPickerContentView, didSelect period: uint)
}

final class RetentionPeriodInDaysPickerContentView: UIView, NibOwnerLoadable, Stylable, UIPickerViewDataSource, UIPickerViewDelegate {
    
    private enum RoomRetentionPeriod {
        static let min: uint = 1
        static let max: uint = 365
    }
    
    // MARK: - Properties
    
    @IBOutlet private weak var pickerView: UIPickerView!
    
    private var retentionPeriodValuesNb: Int!
    
    private var style: Style!
    
    weak var delegate: RetentionPeriodInDaysPickerContentViewDelegate?
    
    // MARK: - Setup
    
    private func commonInit() {
        retentionPeriodValuesNb = (Int)(RoomRetentionPeriod.max - RoomRetentionPeriod.min) + 1
        self.update(style: Variant2Style.shared)
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
        self.delegate?.retentionPeriodInDaysPickerContentView(self, didSelect: period)
    }
    
    func scrollTo(retentionPeriodInDays: uint, animated: Bool) {
        let period = retentionPeriodInDays < RoomRetentionPeriod.min ? RoomRetentionPeriod.min : retentionPeriodInDays > RoomRetentionPeriod.max ? RoomRetentionPeriod.max : retentionPeriodInDays
        self.pickerView.selectRow((Int)(period - 1) + self.retentionPeriodValuesNb, inComponent: 0, animated: animated)
    }
    
    // MARK: - Stylable
    
    func update(style: Style) {
        self.style = style
        
        self.pickerView.backgroundColor = self.style.backgroundColor
        self.pickerView.tintColor = self.style.primaryTextColor
    }
}
