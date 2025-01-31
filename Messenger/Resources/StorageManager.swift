//
//  File.swift
//  Messenger
//
//  Created by Oscar Lui on 16/5/2022.
//

import FirebaseStorage
import CoreMedia


/// Allows to get, fetch and upload files to firebase storage
final class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    private init() {}
    
    let metadata = StorageMetadata()
    /*
    /images/luiwinghin8998-gmail-com_profile_picutre.png
     */
    
    
    public typealias UploadPictureCompletion = (Result<String,Error>) -> Void
    
    /// Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping(UploadPictureCompletion)) {
        storage.child("images/\(fileName)").putData(data,metadata: nil,completion: {
            [weak self] metadata, error in
            guard let strongSelf = self else {
                return
            }
            guard error == nil else {
        
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            strongSelf.storage.child("images/\(fileName)").downloadURL(completion: {
                url,error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
                               
            })
            
            
        })
        
    }
    
    /// Upload image that will be sent in a conversation message
    public func uploadMessagePicture(with data: Data, fileName: String, completion: @escaping(UploadPictureCompletion)) {
        
        storage.child("message_images/\(fileName)").putData(data,metadata: nil,completion: {
            [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: {
                url,error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
                               
            })
            
            
        })
        
    }
    
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping(UploadPictureCompletion)) {
        metadata.contentType = "video/quicktime"
        if let videoData = NSData(contentsOf: fileUrl) as? Data {
            storage.child("message_videos/\(fileName)").putData(videoData, metadata: metadata ,completion: {
            [weak self] metadata, error in
            guard error == nil else {
                //failed
                
                print(fileUrl)
                print("\(error)")
                print("failed to upload data to firebase for video")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: {
                url,error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
                               
            })
            
            
        })
        
        }
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    
    public func downloadURL(for path: String, completion: @escaping (Result<URL,Error>) -> Void){
        let reference = storage.child(path)
        
        reference.downloadURL(completion: {url,error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            
            completion(.success(url))
        })
        
    }
    
    
    
   
}
