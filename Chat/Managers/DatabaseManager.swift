//
//  DatabaseManager.swift
//  Chat
//
//  Created by Mikhail Danilov on 27.07.2022.
//

import Foundation
import FirebaseDatabase
import MessageKit

final class DatabaseManager {
    static let shared = DatabaseManager()

    private let database = Database.database().reference()

    static func safeEmail(emailAdress: String) -> String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

// MARK: - Account Management
extension DatabaseManager {
    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void)) {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        self.database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }

    /// Insert new User to database
    public func insertUser(with user: CurrentUser, completion: @escaping (Bool) -> Void) {
        self.database.child(user.safeEmail).setValue([
            "fist_name": user.firstName,
            "last_name": user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print(">>>>Failde to write to databese")
                completion(false)
                return
            }
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    self.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                } else {
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            })
        })
    }

    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabeseError.failedToFeatch))
                return
            }
            completion(.success(value))
        })
    }

    public enum DatabeseError: Error {
        case failedToFeatch
    }
}

// MARK: - Sending messages / conversations
extension DatabaseManager {
    /// Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String
        else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAdress: currentEmail)
        let reference = self.database.child("\(safeEmail)")
        reference.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print(">>>> User not found")
                return
            }
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)

            var message = ""

            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            let conversationId = "conversation\(firstMessage.messageId)"

            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]

            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            // Update recipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    //create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }

            // Updete current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //conversation array exists for current user
                // append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                reference.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(
                        name: name, conversationID: conversationId,
                        firstMessage: firstMessage, completion: completion)
                }
            } else {
                //conversation array does NOT exist
                //create it
                userNode["conversations"] = [
                    newConversationData
                ]
                reference.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(
                        name: name, conversationID: conversationId,
                        firstMessage: firstMessage, completion: completion)
                }
            }
        }
    }

    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {

        var message = ""

        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }

        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)

        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)

        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKingString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]

        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]

        print(">>>> Adding convo: \(conversationID)")

        self.database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }

    /// Fetches and returns all conversationsa for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        self.database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                print(">>>> Snapshot \(snapshot.value)")
                completion(.failure(DatabeseError.failedToFeatch))
                return
            }
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool
                else {
                    return nil
                }
                print(">>>> name: \(name)")
                print(">>>> otherUserEmail: \(otherUserEmail)")
                print(">>>> latestMessage: \(latestMessage)")
                print(">>>> date: \(date)")
                print(">>>> message: \(message)")
                print(">>>> isRead: \(isRead)")

                let latestMessageObject = LatestMessage(date: date,
                                                        message: message,
                                                        isRead: isRead)
                return Conversation(id: conversationId,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject
                )
            })
            completion(.success(conversations))
        })
    }

    /// Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        self.database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                print(">>>> Snapshot \(snapshot.value)")
                completion(.failure(DatabeseError.failedToFeatch))
                return
            }
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let type = dictionary["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString)
                else {
                    return nil
                }

                var kind: MessageKind?
                if type == "photo" {
                    // photo
                    guard let imageUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "plus")
                    else {
                        return nil
                    }
                    let media = Media(
                        url: imageUrl,
                        image: nil,
                        placeholderImage: placeholder,
                        size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else {
                    kind = .text(content)
                }

                guard let finalKind = kind else { return nil }

                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: finalKind
                )
            })
            completion(.success(messages))
        })
    }

    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(emailAdress: myEmail)
        // add new message to messages
        //update sender latest message
        //update recipient latest message
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let strongSelf = self else { return }
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)

            var message = ""

            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrl = mediaItem.url?.absoluteString {
                    message = targetUrl
                }
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }

            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }

            let currentUserEmail = DatabaseManager.safeEmail(emailAdress: myEmail)

            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKingString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }

                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    guard var ccurrentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }


                    let updateValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]

                    var targetConversation: [String: Any]?

                    var position = 0

                    for conversationDictionary in ccurrentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    targetConversation?["latest_message"] = updateValue
                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    ccurrentUserConversations[position] = finalConversation
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(ccurrentUserConversations, withCompletionBlock: {
                        error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        // Update latest message for recipient user
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }


                            let updateValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]

                            var targetConversation: [String: Any]?

                            var position = 0

                            for conversationDictionary in otherUserConversations {
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                    targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }
                            targetConversation?["latest_message"] = updateValue
                            guard let finalConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            otherUserConversations[position] = finalConversation
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations, withCompletionBlock: {
                                error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        }
                    })
                }
            }
        }
    }
}

struct CurrentUser {
    let firstName: String
    let lastName: String
    let emailAdress: String

    var safeEmail: String {
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }

    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}

extension DatabaseManager {
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabeseError.failedToFeatch))
                return
            }
            completion(.success(value))
        }
    }
}
