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

extension UIView {
    
    /// Add a subview matching parent view using autolayout
    func tc_addSubViewMathingParent(_ subView: UIView) {
        self.addSubview(subView)
        subView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["view": subView]
        ["H:|[view]|", "V:|[view]|"].forEach { vfl in
            let constraints = NSLayoutConstraint.constraints(withVisualFormat: vfl,
                                                             options: [],
                                                             metrics: nil,
                                                             views: views)
            constraints.forEach { $0.isActive = true }
        }
    }
    
    func tc_mask(withPath path: UIBezierPath, inverse: Bool = false) {
        let path = path
        let maskLayer = CAShapeLayer()
        
        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = kCAFillRuleEvenOdd
        }
        
        maskLayer.path = path.cgPath
        
        self.layer.mask = maskLayer
    }
    
    func tc_makeCircle() {
        let minDimension = min(self.bounds.size.width, self.bounds.size.height)
        self.layer.cornerRadius = minDimension/2
        self.layer.masksToBounds = true
        self.layer.mask = nil
    }
    
    func tc_makeHexagon(borderWidth: CGFloat = 0.0, borderColor: UIColor = UIColor.black) {
        let path = UIBezierPath(polygonIn: self.bounds, sides: 6)
        self.tc_mask(withPath: path)
        
        self.tc_addOrUpdateBorderLayer(with: path.cgPath, name: "HexagonBorderLayer", bringToFront: true, borderWidth: borderWidth, borderColor: borderColor)
    }
    
    func tc_addOrUpdateBorderLayer(with path: CGPath, name: String, bringToFront: Bool = true, borderWidth: CGFloat = 0.0, borderColor: UIColor = UIColor.black) {
        
        let foundBorderLayerIndex = self.layer.sublayers?.index(where: { sublayer -> Bool in
            return sublayer.name == name
        })
        
        let foundBorderLayer: CAShapeLayer?
        
        // Remove border layer when border is zero
        if borderWidth == 0 {
            if let foundBorderLayerIndex = foundBorderLayerIndex {
                self.layer.sublayers?.remove(at: foundBorderLayerIndex)
            }
        } else {
            
            if let foundBorderLayerIndex = foundBorderLayerIndex {
                foundBorderLayer = self.layer.sublayers?[foundBorderLayerIndex] as? CAShapeLayer
            } else {
                foundBorderLayer = nil
            }
            
            let borderLayer: CAShapeLayer
            
            // Reuse existing border to avoid creating a new one
            if let foundBorderLayer = foundBorderLayer {
                borderLayer = foundBorderLayer
            } else {
                borderLayer = CAShapeLayer()
                borderLayer.name = name
                self.layer.addSublayer(borderLayer)
            }
            
            // Bring border layer at the top
            if bringToFront, let sublayers = self.layer.sublayers, sublayers.count > 1, let lastLayer = sublayers.last, lastLayer != borderLayer {
                borderLayer.removeFromSuperlayer()
                self.layer.addSublayer(borderLayer)
            }
            
            borderLayer.frame = self.bounds
            borderLayer.path = path
            borderLayer.lineWidth = borderWidth
            borderLayer.strokeColor = borderColor.cgColor
            borderLayer.fillColor = UIColor.clear.cgColor
        }
    }
}
