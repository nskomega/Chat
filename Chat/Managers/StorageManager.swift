//
//  StorageManager.swift
//  Chat
//
//  Created by Mikhail Danilov on 08.08.2022.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()

    private let storage = Storage.storage().reference()

    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void

    /// Upload picture to firebase strorage and return url string to download
    public func uploadProfilePicture(with data: Data,
                                     fileName: String,
                                     completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil) { metadata, error in
            guard error == nil else {
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("Download url returned: \(urlString)")
                completion(.success(urlString))
            }
        }
    }

    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
}
