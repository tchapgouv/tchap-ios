// 
// Copyright 2024 New Vector Ltd.
// Copyright 2020 Vector Creations Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

@objcMembers
final class Section: NSObject {
    
    let tag: Int
    var rows: [Row]
    var attributedHeaderTitle: NSAttributedString?
    var attributedFooterTitle: NSAttributedString?
    
    var headerTitle: String? {
        get {
            attributedHeaderTitle?.string
        }
        set {
            guard let newValue = newValue else {
                attributedHeaderTitle = nil
                return
            }
            
            // Tchap : add section title attributes
            let headerAttributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.foregroundColor: ThemeService.shared().theme.settingsHeaderForegroundColor,
                NSAttributedString.Key.font: ThemeService.shared().theme.fonts.footnote,
                NSAttributedString.Key.strokeWidth: -5.0]
            
            attributedHeaderTitle = NSAttributedString(string: newValue, attributes: headerAttributes)
        }
    }
    var footerTitle: String? {
        get {
            attributedFooterTitle?.string
        }
        set {
            guard let newValue = newValue else {
                attributedFooterTitle = nil
                return
            }
            
            attributedFooterTitle = NSAttributedString(string: newValue)
        }
    }
    
    init(withTag tag: Int) {
        self.tag = tag
        self.rows = []
        super.init()
    }
    
    static func section(withTag tag: Int) -> Section {
        return Section(withTag: tag)
    }
    
    func addRow(_ row: Row) {
        rows.append(row)
    }
    
    func addRow(withTag tag: Int) {
        addRow(Row.row(withTag: tag))
    }
    
    func addRows(withCount count: Int) {
        for i in 0..<count {
            addRow(withTag: i)
        }
    }
    
    func indexOfRow(withTag tag: Int) -> Int? {
        return rows.firstIndex(where: { $0.tag == tag })
    }
    
    var hasAnyRows: Bool {
        return rows.isEmpty == false
    }
    
}
