/*
Copyright 2024 New Vector Ltd.
Copyright 2020 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

import UIKit
import Reusable

@objcMembers
final class LaunchLoadingView: UIView, NibLoadable, Themable {
    
    // MARK: - Constants
    
    private enum LaunchAnimation {
        static let duration: TimeInterval = 3.0
        static let repeatCount = Float.greatestFiniteMagnitude
    }
    
    // MARK: - Properties
    
    @IBOutlet private weak var animationView: ElementView!
    @IBOutlet private weak var progressContainer: UIStackView!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var statusLabel: UILabel!
    
    private var animationTimeline: Timeline_1!
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()
    
    // MARK: - Setup
    
    static func instantiate(startupProgress: MXSessionStartupProgress?) -> LaunchLoadingView {
        let view = LaunchLoadingView.loadFromNib()
        startupProgress?.delegate = view
        return view
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let animationTimeline = Timeline_1(view: self.animationView, duration: LaunchAnimation.duration, repeatCount: LaunchAnimation.repeatCount)
        animationTimeline.play()
        self.animationTimeline = animationTimeline
        
        // Tchap: setup custom loading view.
        tchapSetupLoadingView()
        
        progressContainer.isHidden = true
    }
    
    // Tchap: replace Element logo loadng animation by a simple UIActivityIndicatorView.
    private func tchapSetupLoadingView() {
        let tchapAnimationView = UIActivityIndicatorView(style: .large)
        self.addSubview(tchapAnimationView)
        tchapAnimationView.translatesAutoresizingMaskIntoConstraints = false
        tchapAnimationView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        tchapAnimationView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        tchapAnimationView.startAnimating()
        
        // Hide Element aninmated logo.
        animationView.isHidden = true
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.backgroundColor = theme.backgroundColor
        self.animationView.backgroundColor = theme.backgroundColor
        
        // Tchap: Set progress view to Tchap color.
        progressView.progressTintColor = theme.tintColor
    }
}

extension LaunchLoadingView: MXSessionStartupProgressDelegate {
    func sessionDidUpdateStartupProgress(state: MXSessionStartupProgress.State) {
        update(with: state)
        
    }
    
    private func update(with state: MXSessionStartupProgress.State) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.update(with: state)
            }
            return
        }
        
        // Sync may be doing a lot of heavy work on the main thread and the status text
        // does not update reliably enough without explicitly refreshing
        CATransaction.begin()
        progressContainer.isHidden = false
        progressView.progress = Float(state.progress)
        statusLabel.text = state.showDelayWarning ? VectorL10n.launchLoadingDelayWarning : VectorL10n.launchLoadingGeneric
        CATransaction.commit()
    }
}
