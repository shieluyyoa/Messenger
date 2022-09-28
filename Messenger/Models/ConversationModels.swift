//
//  ConversationModels.swift
//  Messenger
//
//  Created by Oscar Lui on 22/7/2022.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail : String
    let latestMessage: LatestMessage
    
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
