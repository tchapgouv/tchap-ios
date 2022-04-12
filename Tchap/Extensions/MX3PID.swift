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

extension MX3PID {
    static func threePidFromArray(_ array: [String]) -> MX3PID? {
        guard array.count > 1 else { return nil }
        
        let medium = MX3PID.Medium(identifier: array[0])
        let value = array[1]
        return MX3PID(medium: medium, address: value)
    }
    
    func arrayFromThreePid(with value: String) -> [String] {
        return [self.medium.identifier, self.address, value]
    }
}
