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

import UIKit
import RxSwift

enum MediaServiceError: Error {
    case imageToDataRepresentationFailed
    case mediaLoaderInitFailed
    case unknown
}

/// `MediaService` implementation of `MediaServiceType` is used to handle medias.
final class MediaService: MediaServiceType {
    
    // MARK: - Constants
    
    private enum Constants {
        static let jpegCompressionQuality: CGFloat = 0.5
        static let jpegMimeType = "image/jpeg"
    }
    
    // MARK: - Properties
    
    private let session: MXSession
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
    }
    
    // MARK: - Public
    
    func upload(image: UIImage) -> Single<String> {
        guard let upImage = MXKTools.forceImageOrientationUp(image), // Retrieve the current picture and make sure its orientation is up
            let imageData = upImage.jpegData(compressionQuality: Constants.jpegCompressionQuality) else {
                return Single.error(MediaServiceError.imageToDataRepresentationFailed)
        }
        
        return self.upload(imageData: imageData, mimeType: Constants.jpegMimeType)
    }
    
    func upload(imageData: Data, mimeType: String) -> Single<String> {
        return Single.create { (single) -> Disposable in
            self.upload(imageData: imageData, mimeType: mimeType) { (response) in
                switch response {
                case .success(let avatarUrl):
                    single(.success(avatarUrl))
                case .failure(let error):
                    single(.error(error))
                }
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - private

    private func upload(imageData: Data, mimeType: String, completion: @escaping (MXResponse<String>) -> Void) {
        
        guard let mediaLoader = MXMediaManager.prepareUploader(withMatrixSession: self.session, initialRange: 0, andRange: 1.0) else {
            completion(MXResponse.failure(MediaServiceError.mediaLoaderInitFailed))
            return
        }
        
        mediaLoader.uploadData(imageData, filename: nil, mimeType: mimeType, success: { (mediaURL) in
            if let mediaURL = mediaURL {
                completion(MXResponse.success(mediaURL))
            } else {
                completion(MXResponse.failure(MediaServiceError.unknown))
            }
        }, failure: { (error) in
            let finalError = error ?? MediaServiceError.unknown
            completion(MXResponse.failure(finalError))
        })
    }

}
