// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit
import DesignKit

class RoundedToastView: UIView, Themable {
    private struct ShadowStyle {
        let offset: CGSize
        let radius: CGFloat
        let opacity: Float
    }
    
    private struct Constants {
        static let padding = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        static let activityIndicatorScale = CGFloat(0.75)
        static let imageViewSize = CGFloat(15)
        static let lightShadow = ShadowStyle(offset: .init(width: 0, height: 4), radius: 12, opacity: 0.1)
        static let darkShadow = ShadowStyle(offset: .init(width: 0, height: 4), radius: 4, opacity: 0.2)
        static let cornerRadius = CGFloat(16.0) // Tchap
    }
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.transform = .init(scaleX: Constants.activityIndicatorScale, y: Constants.activityIndicatorScale)
        indicator.startAnimating()
        return indicator
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Constants.imageViewSize),
            imageView.heightAnchor.constraint(equalToConstant: Constants.imageViewSize)
        ])
        return imageView
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .top // Tchap
        stack.spacing = 5
        return stack
    }()
    
    private lazy var label: UILabel = {
        // Tchap : allow multiline text
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lbl.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width * 0.67)
        ])
        return lbl
    }()

    private var action: ToastViewState.Action? // Tchap tap action
    
    init(viewState: ToastViewState) {
        super.init(frame: .zero)
        setup(viewState: viewState)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(viewState: ToastViewState) {
        setupStackView()
        stackView.addArrangedSubview(toastView(for: viewState.style))
        stackView.addArrangedSubview(label)
        label.text = viewState.label
        
        // Tchap : handle tap action
        action = viewState.action
        
        if let _ = viewState.action {
            let tapAction = UITapGestureRecognizer(target: self, action: #selector(tapAction))
            self.addGestureRecognizer(tapAction)
        }
    }
    
    // Tchap : handle tap action
    @objc private func tapAction() {
        guard let action = self.action else { return }
        action()
    }
    
    private func setupStackView() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.padding.top),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.padding.bottom),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding.right)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = Constants.cornerRadius // Tchap : don't rely on box height to evaluate corner radius.
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if newSuperview != nil {
            NotificationCenter.default.addObserver(self, selector: #selector(self.themeDidChange(notification:)), name: NSNotification.Name.themeServiceDidChangeTheme, object: nil)
        } else {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.themeServiceDidChangeTheme, object: nil)
        }
    }
    
    @objc private func themeDidChange(notification: Notification) {
        update(theme: ThemeService.shared().theme)
    }
    
    func update(theme: Theme) {
        backgroundColor = theme.colors.system
        stackView.arrangedSubviews.first?.tintColor = theme.colors.primaryContent
        label.font = theme.fonts.subheadline
        label.textColor = theme.colors.primaryContent
        
        let shadowStyle = theme.identifier == ThemeIdentifier.dark.rawValue ? Constants.darkShadow : Constants.lightShadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = shadowStyle.offset
        layer.shadowRadius = shadowStyle.radius
        layer.shadowOpacity = shadowStyle.opacity
    }
    
    private func toastView(for style: ToastViewState.Style) -> UIView {
        switch style {
        case .loading:
            return activityIndicator
        case .success:
            imageView.image = Asset.Images.checkmark.image
            return imageView
        case .failure:
            imageView.image = Asset.Images.errorIcon.image
            return imageView
        case .custom(let icon):
            imageView.image = icon?.withRenderingMode(.alwaysTemplate)
            return imageView
        }
    }
}
