//
//  LoginViewController.swift
//  Chat
//
//  Created by Mikhail Danilov on 26.07.2022.
//

import UIKit
import TinyConstraints

class LoginViewController: UIViewController {
    private lazy var scrollView: UIScrollView = Self.makeScrollView()
    private lazy var scrollViewContainer: UIStackView = Self.makeScrollViewContainer()
    private lazy var imageView: UIImageView = Self.makeImageView()
    private lazy var emailField: UITextField = Self.makeEmailField()
    private lazy var passwordField: UITextField = Self.makePasswordField()
    private lazy var loginButton: UIButton = Self.makeLoginButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Login"
        self.view.backgroundColor = .white

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Register",
            style: .done,
            target: self,
            action: #selector(self.didTappedRegister))

        self.view.addSubview(self.scrollView)
        self.scrollView.edgesToSuperview()

        self.scrollView.addSubview(self.scrollViewContainer)
        self.scrollViewContainer.edgesToSuperview()
        self.scrollViewContainer.widthToSuperview(relation: .equal)

        self.scrollViewContainer.addArrangedSubview(self.imageView)
        self.imageView.centerXToSuperview()

        self.scrollViewContainer.addArrangedSubview(self.emailField)
        self.scrollViewContainer.addArrangedSubview(self.passwordField)
        self.scrollViewContainer.addArrangedSubview(self.loginButton)

        self.loginButton.addTarget(self,
                                   action: #selector(self.loginButtonTapped),
                                   for: .touchUpInside)

        self.emailField.delegate = self
        self.passwordField.delegate = self
    }
}

// MARK: - Factory
extension LoginViewController {
    private static func makeScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }

    private static func makeScrollViewContainer() -> UIStackView {
        let view = UIStackView()
        view.spacing = 7.0
        view.axis = .vertical
        view.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }

    private static func makeImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.image = R.image.logo()
        imageView.contentMode = .scaleAspectFit
        imageView.height(60)
        imageView.width(60)
        return imageView
    }

    private static func makeEmailField() -> UITextField {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.height(50)
        textField.placeholder = "Email Address..."
        return textField
    }

    private static func makePasswordField() -> UITextField {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.height(50)
        textField.isSecureTextEntry = true
        textField.placeholder = "Password..."
        return textField
    }

    private static func makeLoginButton() -> UIButton {
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.height(50)
        return button
    }
}

// MARK: - Actions
extension LoginViewController {
    @objc private func didTappedRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func loginButtonTapped() {
        self.emailField.resignFirstResponder()
        self.passwordField.resignFirstResponder()
        guard let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
            alertUserLoginError()
            return
        }
        //Firebase Login
    }
}

// MARK: - Private
extension LoginViewController {
    private func alertUserLoginError() {
        let alert = UIAlertController(title: "Ops", message: "Please enter all information to log in.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dissmis", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField {
            self.loginButtonTapped()
        }
        return true
    }
}
