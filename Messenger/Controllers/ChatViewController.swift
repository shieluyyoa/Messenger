//
//  ChatViewController.swift
//  Messenger
//
//  Created by Oscar Lui on 4/5/2022.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import RealmSwift
import SDWebImage
import AVKit
import AVFoundation
import CoreLocation


final class ChatViewController: MessagesViewController {
    
    private var profilePictureURL: URL?
    private var otherUserPhotoURL: URL?
    
    public static let dateFormatter: DateFormatter = {
        let formattre = DateFormatter()
        formattre.dateStyle = .medium
        formattre.timeStyle = .long
        formattre.locale = .current
        formattre.dateFormat = "MMM d, y \'at\' h:mm:ss a z"
        return formattre
    }()
    
    public var isNewConversation = false
    private var conversationID: String?
    public let otherUserEmail:String
    
    
    
    private var messages = [Message]()
    private var selfSender:Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String
        
        else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoURL: "",
                      senderId: safeEmail,
                      displayName: "Me")
    }
    
    
    init(with email: String, id:String?) {
        self.otherUserEmail = email
        self.conversationID = id
        
        super.init(nibName: nil, bundle: nil)
        
       
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
       
        setupInputButton()
        
    }
    
    
    private func setupInputButton(){
        
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self]_ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: {
            [weak self] _ in
            
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: {
           [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {
           _ in
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: {
           [weak self] _ in
            self?.presentLocationPicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil
        ))
        
        present(actionSheet,animated: true)
        
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = {
            [weak self] selectedCoordinates in
            
            guard let strongSelf = self else {
                return
            }
            guard let messageId = strongSelf.createMessageID(),
                  let conversationID = strongSelf.conversationID,
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender
            else {
                return
            }
            
            let longitude: Double = selectedCoordinates.longitude
            let latitude: Double  = selectedCoordinates.latitude
            
            print("long = \(longitude) | lat = \(latitude)")
            
            let location = Location(
                location: CLLocation(latitude: latitude,longitude: longitude),
                size: .zero)
            
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name , newMessage: message, completion: {
                success in
                if success {
                    print("location message sent success")
                }
                else {
                    print("failed to send video message")
                }
                
            })
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach a photo from?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {
            [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker,animated:true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo library", style: .default, handler: {
            [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker,animated:true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {
           _ in
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {
            _ in
        }))
        
        present(actionSheet,animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach a video from?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {
            [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker,animated:true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {
            [weak self] _ in
            
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker,animated:true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: {
           _ in
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {
            _ in
        }))
        
        present(actionSheet,animated: true)
    }
    
    private func listenforMessage(id:String,shouldScrollToBottom: Bool){
        
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: {
            [weak self] result in
            switch result {
            case.success(let message):
                print("success fetchin message")
                guard !message.isEmpty else {
                    print("no message")
                    return
                }
                
                self?.messages = message
               
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
               
                
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationID = conversationID {
            print("listening")
            print(conversationID)
            listenforMessage(id: conversationID, shouldScrollToBottom: true)
        }
    }
    

}

extension ChatViewController: UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageID(),
              let conversationID = conversationID,
              let name = self.title,
              let selfSender = selfSender
        else {
            return
        }
        
        if let image = info[.editedImage] as? UIImage,let imageData = image.pngData(){
           let filename = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            //Upload image
            
            StorageManager.shared.uploadMessagePicture(with: imageData, fileName: filename, completion: { [weak self] result in

                guard let strongSelf = self else {
                    return
                }

                switch result {
                case .success(let urlString):
                    // Read to send the message
                    print("Uploading Message Photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                              return
                          }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name , newMessage: message, completion: {
                        success in
                        if success {
                            print("Photo sent success")
                        }
                        else {
                            print("failed to send photo message")
                        }
                        
                    })
                case .failure(let error):
                    print("message photo upload error:\(error)")
                    
                }
                
                
            })
        }
        else if let videoUrl = info[.mediaURL] as? URL {
            let filename = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            //Upload video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: filename, completion: { [weak self] result in

                guard let strongSelf = self else {
                    return
                }

                switch result {
                case .success(let urlString):
                    // Read to send the message
                    print("Uploading Message Video: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                              return
                          }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name , newMessage: message, completion: {
                        success in
                        if success {
                            print("Video sent success")
                        }
                        else {
                            print("failed to send video message")
                        }
                        
                    })
                case .failure(let error):
                    print("message video upload error:\(error)")
                    
                }
                
                
            })
        }
        
        
        
    
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageID = createMessageID()
        else {
            
            return
        }
        
        inputBar.inputTextView.text = ""
        
        // send Message
        let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))
        if isNewConversation{
            //create convo in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: { [weak self]
                success in
                if success {
                    print("message sent")
                    let conversationID =  "conversation_\(messageID)"
                    self?.isNewConversation = false
                    self?.conversationID = conversationID
                    self?.listenforMessage(id: conversationID, shouldScrollToBottom: true)
                }
                else{
                    print("failed to send")
                }
                
                
            })
            
        }
        else {
            
            guard let conversationID = conversationID,let name = self.title else {
                return
            }
            //append to existing conversaiton data
            DatabaseManager.shared.sendMessage(to: conversationID,otherUserEmail:otherUserEmail, name: name, newMessage: message , completion: { success in
                if success {
                    print(conversationID)
                    print("message sent")
                }
                else {
                    print("failed to send")
                }
            })
        }
    }
    
    
    private func createMessageID() -> String? {
        //date,otherUserEmail,senderEmail,randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String
        else {
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        return newIdentifier
    }
}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    
    
    func currentSender() -> SenderType {
        if let sender =  selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email should be cached")
        
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        print(messages.count)
        return messages.count
        
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        
        }		
        
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            // our message that we haves sent
            return .link
        }
        
        return .secondarySystemBackground
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            if let currentUserURL = self.profilePictureURL {
                avatarView.sd_setImage(with: currentUserURL)
            
            } else {
                // fetch URL
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let filename = safeEmail + "_profile_picture.png"
                let path = "images/"+filename
                
                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.profilePictureURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                    case .failure(let error):
                        print("Failed to get download url: \(error)")
                    }
                })
            }
            
        } else {
            
            if let otherUserURL = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUserURL)
            
            } else {
                // fetch URL
                let email = otherUserEmail
                
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let filename = safeEmail + "_profile_picture.png"
                let path = "images/"+filename
                
                StorageManager.shared.downloadURL(for: path, completion: {  [weak self] result in
                    switch result {
                    case .success(let url):
                        
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url)
                        }
                        
                    case .failure(let error):
                        print("Failed to get download url: \(error)")
                    }
                })
            }
        }
    }
}
    
extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
           
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
            
        default:
            break
        }
        
        
      
        
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
            
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            vc.player?.play()
            present(vc,animated: true)
        default:
            break
        }
    }

}

