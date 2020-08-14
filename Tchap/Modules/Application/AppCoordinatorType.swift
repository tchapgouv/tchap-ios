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

/// `AppCoordinatorType` is a protocol describing a Coordinator that handle application navigation flow.
protocol AppCoordinatorType: Coordinator {
    
    /// Handle a user activity
    ///
    /// - Parameters:
    ///   - userActivity: The user activity.
    ///   - application: The shared app object that controls and coordinates your app.
    /// - Returns: true to indicate that the activity has been handled, or false to let iOS handle the activity.
    func handleUserActivity(_ userActivity: NSUserActivity, application: UIApplication) -> Bool
    
    /// Handle the fragment of a Tchap permalink.
    ///
    /// - Parameters:
    ///   - fragment: The url fragment to handle.
    /// - Returns: true to indicate that the fragment has been handled, or false when the fragment is not supported.
    func handlePermalinkFragment(_ fragment: String) -> Bool
    
    /// Resume the application by selecting a room.
    ///
    /// - Parameters:
    ///   - roomId: the room identifier.
    func resumeBySelectingRoom(with roomId: String)
    
    /// Open a Tchap room
    ///
    /// - Parameters:
    ///   - roomIdOrAlias: the room identifier.
    ///   - eventID: an optional event identifier to point to in the room history.
    /// - Returns: true to indicate that the room has been opened, or false if the room has not been found.
    func showRoom(with roomIdOrAlias: String, onEventID eventID: String?) -> Bool
    
    /// Check if the user should be notified of an application update.
    func checkMinAppVersionRequirements()
}

// `AppCoordinatorType` default implementation
extension AppCoordinatorType {
    func showRoom(with roomIdOrAlias: String) -> Bool {
        return showRoom(with: roomIdOrAlias, onEventID: nil)
    }
}
