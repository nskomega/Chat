//
//  NewConversationViewController.swift
//  Chat
//
//  Created by Mikhail Danilov on 26.07.2022.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    private lazy var tableView: UITableView = Self.makeTableView()
    private lazy var searchBar: UISearchBar = Self.makeSearchBar()
    private lazy var noResultsLabel: UILabel = Self.makeNoResultsLabel()
    private let spinner = JGProgressHUD(style: .dark)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.searchBar.delegate = self

        self.navigationController?.navigationBar.topItem?.titleView = self.searchBar
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .done,
            target: self,
            action: #selector(self.dissmisSelf)
        )
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

    }
}

// MARK: - Private
extension NewConversationViewController {
    @objc
    private func dissmisSelf() {
        self.dismiss(animated: true)
    }
}
