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

class ConversationsViewController: UIViewController {
    private lazy var tableView: UITableView = Self.makeTableView()
    private lazy var mainLabel: UILabel = Self.makeMainLabel()
    private let spinner = JGProgressHUD(style: .dark)

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
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Hello world!"
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ChatViewController()
        vc.title = "Mikhail Danilov"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Factory
extension ConversationsViewController {
    private static func makeTableView() -> UITableView {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "cell")
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
        let navVC = UINavigationController(rootViewController: vc)
        self.present(navVC, animated: true)
    }
}
