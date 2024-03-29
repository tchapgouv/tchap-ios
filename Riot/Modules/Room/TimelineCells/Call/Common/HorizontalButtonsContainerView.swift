// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import Reusable

class HorizontalButtonsContainerView: UIView {
    
    private enum Constants {
        static let stackViewTopMargin: CGFloat = 8
        static let stackViewBottomMargin: CGFloat = 16
    }

    @IBOutlet weak private var stackView: UIStackView!
    
    @IBOutlet weak var firstButton: CallTileActionButton!
    @IBOutlet weak var secondButton: CallTileActionButton!
    
    override var intrinsicContentSize: CGSize {
        var result = stackView.intrinsicContentSize
        result.width = self.frame.width
        result.height += Constants.stackViewTopMargin + Constants.stackViewBottomMargin
        // Tchap: set minimum height for buttons not to be vertically compressed when text above is multi-line.
        result.height = max(result.height, 68.0)
        return result
    }

}

extension HorizontalButtonsContainerView: NibLoadable {}

extension HorizontalButtonsContainerView: Themable {
    
    func update(theme: Theme) {
        firstButton.update(theme: theme)
        secondButton.update(theme: theme)
    }
    
}
