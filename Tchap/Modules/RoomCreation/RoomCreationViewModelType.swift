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

enum RoomType {
    case privateRestricted(isFederated: Bool = true)
    case privateUnrestricted(isFederated: Bool = true)
    case forum(isFederated: Bool = true) // Set forum as federated by default.
}

/// Protocol describing the view model used by RoomCreationViewController
protocol RoomCreationViewModelType {
    
    var roomNameFormTextViewModel: FormTextViewModel { get }
    var homeServerDomain: String { get }
    var selectedRoomType: RoomType { get set }
}
