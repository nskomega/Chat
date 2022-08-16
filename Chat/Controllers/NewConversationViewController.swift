//
//  NewConversationViewController.swift
//  Chat
//
//  Created by Mikhail Danilov on 26.07.2022.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    public var completion: (([String: String]) -> (Void))?

    private lazy var tableView: UITableView = Self.makeTableView()
    private lazy var searchBar: UISearchBar = Self.makeSearchBar()
    private lazy var noResultsLabel: UILabel = Self.makeNoResultsLabel()
    private let spinner = JGProgressHUD(style: .dark)

    private var users = [[String: String]]()
    private var results = [[String: String]]()
    private var hasFetched = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white

        self.navigationController?.navigationBar.topItem?.titleView = self.searchBar
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .done,
            target: self,
            action: #selector(self.dissmisSelf)
        )

        self.searchBar.delegate = self

        self.view.addSubview(self.noResultsLabel)
        self.noResultsLabel.centerInSuperview()

        self.view.addSubview(self.tableView)
        self.tableView.edgesToSuperview()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
}

// MARK: - Factory
extension NewConversationViewController {
    private static func makeTableView() -> UITableView {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "cell")
        return table
    }

    private static func makeSearchBar() -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Users..."
        return searchBar
    }

    private static func makeNoResultsLabel() -> UILabel {
        let label = UILabel()
        label.text = "No Results"
        label.isHidden = true
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }
}

// MARK: - UISearchBarDelegate
extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()

        self.results.removeAll()
        self.spinner.show(in: self.view)
        self.searchUsers(query: text)

    }

    func searchUsers(query: String) {
        if hasFetched {
            self.fileterUsers(with: query)
        } else {
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.fileterUsers(with: query)
                case .failure(let error):
                    print(">>>> Failed to get users: \(error)")
                }
            })
        }
    }

    func fileterUsers(with term: String) {
        guard hasFetched else {
            return
        }

        self.spinner.dismiss()

        let results: [[String: String]] = self.users.filter {
            guard let name = $0["name"]?.lowercased() as? String else { return false
            }
            return name.hasPrefix(term.lowercased())
        }
        self.results = results
        self.updateUI()
    }

    func updateUI() {
        if self.results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        } else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDelegate
extension NewConversationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targerUserData = results[indexPath.row]

        self.dismiss(animated: true, completion: { [weak self] in
            self?.completion?(targerUserData)
        })
    }
}

// MARK: - UITableViewDataSource
extension NewConversationViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
}

// MARK: - Private
extension NewConversationViewController {
    @objc
    private func dissmisSelf() {
        self.dismiss(animated: true)
    }
}
