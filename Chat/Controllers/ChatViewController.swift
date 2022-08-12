//
//  ChatViewController.swift
//  Chat
//
//  Created by Mikhail Danilov on 30.07.2022.
//

import UIKit
import MessageKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {
    private var messages = [Message]()
    private let selfSender = Sender(
        photoURL: "",
        senderId: "1",
        displayName: "Mikhail Danilov"
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.messages.append(Message(
            sender: selfSender,
            messageId: "1",
            sentDate: Date(),
            kind: .text("Hello Wolrd message"))
        )
        self.messages.append(Message(
            sender: selfSender,
            messageId: "1",
            sentDate: Date(),
            kind: .text("Hello Wolrd message Hello Wolrd message Hello Wolrd message Hello Wolrd message Hello Wolrd message Hello Wolrd message")))

        self.messagesCollectionView.messagesDataSource = self
        self.messagesCollectionView.messagesLayoutDelegate = self
        self.messagesCollectionView.messagesDisplayDelegate = self

    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {

    func currentSender() -> SenderType {
        return selfSender
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }


}
