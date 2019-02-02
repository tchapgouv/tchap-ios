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


/// Protocol used to handle the parameters extracted from an URL fragment part (after '#') of a Tchap Universal link:
/// The fragment can contain a '?'. So there are two kinds of parameters: path params and query params.
/// It is in the form of /[pathParam1]/[pathParam2]?[queryParam1Key]=[queryParam1Value]&[queryParam2Key]=[queryParam2Value]
protocol UniversalLinkParametersType {
    /// The decoded path params.
    var pathParams: [String] { get }
    
    /// The decoded query params.
    var queryParams: [String: String]? { get }
}
