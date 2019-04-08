/*
 Copyright 2019 New Vector Ltd
 
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

/// Representing a form check box view model
protocol FormCheckBoxModelType {
    
    /// The label
    var label: String { get }
    
    /// The optional link in the label - label is a formatted string if set
    var labelLink: String? { get }
    
    /// Check box value
    var isSelected: Bool { get set }
}
