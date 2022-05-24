// 
// Copyright 2022 New Vector Ltd
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

import MatrixSDK

extension MXSession {
    /// Returns the valid (not leaved) direct discussion with the user in parameter.
    /// If not, returns nil in completion.
    @objc func validRoomDirectDiscussion(for userID: String,
                                         completion: @escaping (_ room: MXRoom?) -> Void) {
        self.hasValidDirectDiscussion(for: userID) { roomID in
            guard let roomID = roomID,
                  let room = self.room(withRoomId: roomID) else {
                completion(nil)
                return
            }
            completion(room)
        }
    }

    /// Check if there is a valid (not leaved) direct discussion with the user in parameter, and then returns the roomID.
    /// If not, returns nil in completion.
    func hasValidDirectDiscussion(for userID: String,
                                  completion: @escaping (String?) -> Void) {
        let discussionFinder: DiscussionFinderType = DiscussionFinder(session: self)
        discussionFinder.getDiscussionIdentifier(for: userID,
                                                 includeInvite: true,
                                                 autoJoin: true,
                                                 includeLeft: false) { response in
            switch response {
            case .success(let result):
                switch result {
                case .pendingInvite(let roomID):
                    completion(roomID)
                case .joinedDiscussion(let roomID):
                    completion(roomID)
                case .noDiscussion:
                    completion(nil)
                }
            case .failure(_):
                completion(nil)
            }
        }
    }
}
