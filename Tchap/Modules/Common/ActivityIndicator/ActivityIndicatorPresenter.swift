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

import Foundation
import UIKit

/// Used to present activity indicator on a view
final class ActivityIndicatorPresenter: ActivityIndicatorPresenterType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let animationDuration: TimeInterval = 0.3
    }
    
    // MARK: - Properties
    
    private weak var activityIndicatorView: ActivityIndicatorView?
    private weak var presentingView: UIView?
    
    // MARK: - Public
    
    func presentActivityIndicator(on view: UIView, animated: Bool, completion: (() -> Void)? = nil) {
        self.presentingView = view
        
        view.isUserInteractionEnabled = false
        
        let activityIndicatorView = ActivityIndicatorView()
        
        activityIndicatorView.startAnimating()
        activityIndicatorView.alpha = 0
        activityIndicatorView.isHidden = false
        
        view.tc_addSubViewMathingParent(activityIndicatorView)
        
        self.activityIndicatorView = activityIndicatorView
        
        let animationInstructions = {
            activityIndicatorView.alpha = 1
        }
        
        if animated {
            UIView.animate(withDuration: Constants.animationDuration, animations: {
                animationInstructions()
            }, completion: { _ in
                completion?()
            })
        } else {
            animationInstructions()
            completion?()
        }
    }
    
    func removeCurrentActivityIndicator(animated: Bool, completion: (() -> Void)? = nil) {
        guard let presentingView = self.presentingView, let activityIndicatorView = self.activityIndicatorView else {
            return
        }
        
        presentingView.isUserInteractionEnabled = true
        
        let animationInstructions = {
            activityIndicatorView.alpha = 0
        }
        
        let animationCompletionInstructions = {
            activityIndicatorView.stopAnimating()
            activityIndicatorView.isHidden = true
            activityIndicatorView.removeFromSuperview()
        }
        
        if animated {
            UIView.animate(withDuration: Constants.animationDuration, animations: {
                animationInstructions()
            }, completion: { _ in
                animationCompletionInstructions()
            })
        } else {
            animationInstructions()
            animationCompletionInstructions()
        }
    }
}
