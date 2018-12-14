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

import UIKit

final class SelectableContactCell: ContactCell {
    
    // MARK: - Properties
    
    @IBOutlet private weak var checkMarkImageView: UIImageView!
    
    var checkmarkEnabled: Bool = false {
        didSet {
            self.toggleCheckmarkImage()
        }
    }
    
    // MARK: - Life cycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.checkmarkEnabled = false
    }
    
    // MARK: - Superclass overrides
    
    override class func nib() -> UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
    
    override class func defaultReuseIdentifier() -> String {
        return String(describing: self)
    }
    
    // MARK: - Private
    
    private func toggleCheckmarkImage() {
        self.checkMarkImageView.image = self.checkmarkEnabled ? Asset.Images.Common.selectionTick.image : Asset.Images.Common.selectionUntick.image
    }
}
