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
import RxSwift

/// Protocol describing a service to handle public rooms.
protocol PublicRoomServiceType {
    
    /// Get public rooms list from a search text.
    ///
    /// - Parameter searchText: The search text used to filter public rooms.
    ///
    /// - Returns: An Observable of MXPublicRoom list when succeed.
    func getPublicRooms(searchText: String?) -> Observable<[MXPublicRoom]>
}

// PublicRoomServiceType default implementation
extension PublicRoomServiceType {
    func getPublicRooms() -> Observable<[MXPublicRoom]> {
        return self.getPublicRooms(searchText: nil)
    }
}
