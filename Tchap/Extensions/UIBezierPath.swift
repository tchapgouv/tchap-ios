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

extension UIBezierPath {
    
    convenience init(polygonIn rect: CGRect, sides: Int, rotationAngle: CGFloat = .pi/6) {
        guard sides >= 3 else {
            fatalError("A least 3 sides are needed to build a polygon")
        }
        
        self.init()
        
        let xRadius = rect.width/2
        let yRadius = rect.height/2
        
        let centerX = rect.midX
        let centerY = rect.midY
        
        self.move(to: CGPoint(x: centerX + xRadius, y: centerY + 0))
        
        for i in 0..<sides {
            let theta = CGFloat(2.0 * .pi)/CGFloat(sides) * CGFloat(i)
            let xCoordinate = centerX + xRadius * cos(theta)
            let yCoordinate = centerY + yRadius * sin(theta)
            self.addLine(to: CGPoint(x: xCoordinate, y: yCoordinate))
        }
        
        self.close()
        
        self.tc_rotate(radians: rotationAngle)
    }
    
    /// Apply a rotation around center
    func tc_rotate(radians: CGFloat) {
        let bounds: CGRect = self.cgPath.boundingBox
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        var transform: CGAffineTransform = .identity
        transform = transform.translatedBy(x: center.x, y: center.y)
        transform = transform.rotated(by: radians)
        transform = transform.translatedBy(x: -center.x, y: -center.y)
        self.apply(transform)
    }
}
