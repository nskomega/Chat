//
//  ViewController.swift
//  Chat
//
//  Created by Mikhail Danilov on 26.07.2022.
//

import UIKit
import FirebaseAuth
import JGProgressHUD
import TinyConstraints

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let message: String
    let isRead: Bool
}

class ConversationsViewController: UIViewController {
    private lazy var tableView: UITableView = Self.makeTableView()
    private lazy var mainLabel: UILabel = Self.makeMainLabel()
    private let spinner = JGProgressHUD(style: .dark)

    private var conversations = [Conversation]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchConversations()
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.mainLabel)
        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.tableView.edgesToSuperview(usingSafeArea: true)

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .compose,
            target: self,
            action: #selector(self.didTapComposeButton)
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.validateAuth()
        self.startListeningForConversations()
    }

}
// MARK: - Private
extension ConversationsViewController {
    private func validateAuth() {
        if Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }

    private func fetchConversations() {
        self.tableView.isHidden = false
    }

    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        print(">>>> Starting conversation Fetch...")
        let safeEmail = DatabaseManager.safeEmail(emailAdress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            switch result {
            case .success(let conversations):
                print(">>>> Successuly got conversation models")
                guard !conversations.isEmpty else {
                    print(">>>> Conversations isEmpty")
                    return
                }
                self?.conversations = conversations
                print(">>>> Conversations: \(conversations)")
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print(">>>> Failed to get conversations: \(error)")
            }
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(">>>> ", self.conversations.count)
        return self.conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        print(">>>> ", model)
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        print(">>>> ", model)
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}

// MARK: - Factory
extension ConversationsViewController {
    private static func makeTableView() -> UITableView {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self,
                       forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }

    private static func makeMainLabel() -> UILabel {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font =  .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }
}

// MARK: - Action
extension ConversationsViewController {
    @objc
    private func didTapComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            print(">>>> \(result)")
            self?.createNewConversation(result: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        self.present(navVC, animated: true)
    }

    private func createNewConversation(result: [String: String]) {
        guard let name = result["name"],
            let email = result["email"]
        else {
            return
        }
        let vc = ChatViewController(with: email, id: nil)
        vc.isNewConversation = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
