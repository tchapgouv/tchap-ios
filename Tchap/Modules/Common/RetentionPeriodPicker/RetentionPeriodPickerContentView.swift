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

protocol RetentionPeriodPickerContentViewDelegate: class {
    func retentionPeriodPickerContentView(_ view: RetentionPeriodPickerContentView, didSelect periodInDays: uint)
}

final class RetentionPeriodPickerContentView: UIView, NibOwnerLoadable, Stylable, UIPickerViewDataSource, UIPickerViewDelegate {
    
    private enum RoomRetentionPeriod {
        static let oneDay: uint = 1
        static let oneWeek: uint = 7
        static let oneMonth: uint = 30
        static let sixMonths: uint = 180
        static let oneYear: uint = 365
    }
    
    @objc static let roomRetentionPeriodOneDay = RoomRetentionPeriod.oneDay
    @objc static let roomRetentionPeriodOneWeek = RoomRetentionPeriod.oneWeek
    @objc static let roomRetentionPeriodOneMonth = RoomRetentionPeriod.oneMonth
    @objc static let roomRetentionPeriodSixMonths = RoomRetentionPeriod.sixMonths
    @objc static let roomRetentionPeriodOneYear = RoomRetentionPeriod.oneYear
    
    // MARK: - Properties
    
    @IBOutlet private weak var pickerView: UIPickerView!
    
    private var retentionPeriodValuesNb: Int!
    
    private var style: Style!
    
    weak var delegate: RetentionPeriodPickerContentViewDelegate?
    
    // MARK: - Setup
    
    private func commonInit() {
        retentionPeriodValuesNb = 6
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
        let level = row % self.retentionPeriodValuesNb
        let levelLabel: String
        switch level {
        case 0:
            levelLabel = TchapL10n.roomSettingsRetentionPeriodInfinite
        case 1:
            levelLabel = TchapL10n.roomSettingsRetentionPeriodOneYear
        case 2:
            levelLabel = TchapL10n.roomSettingsRetentionPeriodSixMonths
        case 3:
            levelLabel = TchapL10n.roomSettingsRetentionPeriodOneMonth
        case 4:
            levelLabel = TchapL10n.roomSettingsRetentionPeriodOneWeek
        case 5:
            levelLabel = TchapL10n.roomSettingsRetentionPeriodOneDay
        default:
            // unexpected case
            levelLabel = TchapL10n.errorTitleDefault
        }
        return levelLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let level = row % self.retentionPeriodValuesNb
        let periodInDays: uint
        switch level {
        case 0:
            periodInDays = MXRoomSummary.undefinedRetentionValueInDays
        case 1:
            periodInDays = RoomRetentionPeriod.oneYear
        case 2:
            periodInDays = RoomRetentionPeriod.sixMonths
        case 3:
            periodInDays = RoomRetentionPeriod.oneMonth
        case 4:
            periodInDays = RoomRetentionPeriod.oneWeek
        case 5:
            periodInDays = RoomRetentionPeriod.oneDay
        default:
            // unexpected case
            periodInDays = MXRoomSummary.undefinedRetentionValueInDays
        }
        self.delegate?.retentionPeriodPickerContentView(self, didSelect: periodInDays)
    }
    
    func updatePickerWith(retentionPeriodInDays: uint, animated: Bool) {
        let row: Int
        if retentionPeriodInDays <= RoomRetentionPeriod.oneDay {
            row = 5
        } else if retentionPeriodInDays <= RoomRetentionPeriod.oneWeek {
            row = 4
        } else if retentionPeriodInDays <= RoomRetentionPeriod.oneMonth {
            row = 3
        } else if retentionPeriodInDays <= RoomRetentionPeriod.sixMonths {
            row = 2
        } else if retentionPeriodInDays <= RoomRetentionPeriod.oneYear {
            row = 1
        } else {
            row = 0
        }
        self.pickerView.selectRow(row + self.retentionPeriodValuesNb, inComponent: 0, animated: animated)
    }
    
    // MARK: - Stylable
    
    func update(style: Style) {
        self.style = style
        
        self.pickerView.backgroundColor = self.style.backgroundColor
        self.pickerView.tintColor = self.style.primaryTextColor
    }
}
