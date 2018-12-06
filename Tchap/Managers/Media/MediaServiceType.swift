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

/// Protocol describing a service to handle medias.
protocol MediaServiceType {
    
    /// Upload an UIImage.
    ///
    /// - Parameter image: The image to upload.
    /// - Returns: A Single with avatar url string.
    func upload(image: UIImage) -> Single<String>
    
    /// Upload an image data.
    ///
    /// - Parameters:
    ///   - imageData: The image data to upload
    ///   - mimeType: The image mime type
    /// - Returns: A Single with avatar url string.
    func upload(imageData: Data, mimeType: String) -> Single<String>
}
