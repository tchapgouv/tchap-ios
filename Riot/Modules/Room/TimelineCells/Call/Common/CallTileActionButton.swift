// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

enum CallTileActionButtonStyle {
    case positive
    case negative
    case custom(bgColor: UIColor, tintColor: UIColor)
}

class CallTileActionButton: UIButton {
    
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 8.0
        static let fontSize: CGFloat = 17.0
        static let contentEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        static let spaceBetweenImageAndTitle: CGFloat = 8
        static let imageSize: CGSize = CGSize(width: 16, height: 16)
    }
    
    private var theme: Theme = ThemeService.shared().theme {
        didSet {
            updateStyle()
        }
    }
    
    private var hasImage: Bool {
        return image(for: .normal) != nil
    }
    
    var style: CallTileActionButtonStyle = .positive {
        didSet {
            updateStyle()
        }
    }
    
    // MARK: Setup
    
    init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        contentEdgeInsets = Constants.contentEdgeInsets
        layer.masksToBounds = true
        titleLabel?.font = UIFont.systemFont(ofSize: Constants.fontSize)
        layer.cornerRadius = Constants.cornerRadius
        setImage(image(for: .normal)?.vc_resized(with: Constants.imageSize)?.withRenderingMode(.alwaysTemplate), for: .normal)
        updateStyle()
    }
    
    private func updateStyle() {
        switch style {
        case .positive:
            vc_setBackgroundColor(theme.tintColor, for: .normal)
            tintColor = theme.baseTextPrimaryColor
        case .negative:
            vc_setBackgroundColor(theme.noticeColor, for: .normal)
            tintColor = theme.baseTextPrimaryColor
        case .custom(let bgColor, let tintColor):
            vc_setBackgroundColor(bgColor, for: .normal)
            self.tintColor = tintColor
        }
    }
    
    // MARK: - Overrides
    
    override func setImage(_ image: UIImage?, for state: UIControl.State) {
        // Tchap: tint icon in white
//        super.setImage(image?.vc_resized(with: Constants.imageSize)?.withRenderingMode(.alwaysTemplate),
//                       for: state)
        super.setImage(image?.vc_resized(with: Constants.imageSize)?.withRenderingMode(.alwaysTemplate).vc_tintedImage(usingColor: .white),
                       for: state)        
    }
    
    override var intrinsicContentSize: CGSize {
        var result = super.intrinsicContentSize
        guard hasImage else {
            return result
        }
        result.width += Constants.spaceBetweenImageAndTitle
        return result
    }
    
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        var result = super.imageRect(forContentRect: contentRect)
        guard hasImage else {
            return result
        }
        result.origin.x -= Constants.spaceBetweenImageAndTitle/2
        return result
    }
    
    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        var result = super.titleRect(forContentRect: contentRect)
        guard hasImage else {
            return result
        }
        result.origin.x += Constants.spaceBetweenImageAndTitle/2
        return result
    }
    
}

extension CallTileActionButton: Themable {
    
    func update(theme: Theme) {
        self.theme = theme
    }
    
}
