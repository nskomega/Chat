//
//  DatabaseManager.swift
//  Chat
//
//  Created by Mikhail Danilov on 27.07.2022.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()

    private let database = Database.database().reference()
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
    public func insertUser(with user: CurrentUser) {
        self.database.child(user.safeEmail).setValue([
            "fist_name": user.firstName,
            "last_name": user.lastName
        ]) {
            (error:Error?, ref:DatabaseReference) in
            if let error = error {
                print(">>>>Data could not be saved: \(error).")
            } else {
                print("Data saved successfully!")
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
}
