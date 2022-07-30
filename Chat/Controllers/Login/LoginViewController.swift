//
//  LoginViewController.swift
//  Chat
//
//  Created by Mikhail Danilov on 26.07.2022.
//

import UIKit
import TinyConstraints
import FirebaseAuth
import FBSDKLoginKit

class LoginViewController: UIViewController {
    private lazy var scrollView: UIScrollView = Self.makeScrollView()
    private lazy var scrollViewContainer: UIStackView = Self.makeScrollViewContainer()
    private lazy var imageView: UIImageView = Self.makeImageView()
    private lazy var emailField: UITextField = Self.makeEmailField()
    private lazy var passwordField: UITextField = Self.makePasswordField()
    private lazy var loginButton: UIButton = Self.makeLoginButton()
    private lazy var fBLoginButton: FBLoginButton = Self.makeFBLoginButton()

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
        self.scrollViewContainer.addArrangedSubview(fBLoginButton)

        self.loginButton.addTarget(self,
                                   action: #selector(self.loginButtonTapped),
                                   for: .touchUpInside)

        self.emailField.delegate = self
        self.passwordField.delegate = self
        self.fBLoginButton.delegate = self

    }
}

// MARK: - Factory
extension LoginViewController {
    private static func makeFBLoginButton() -> FBLoginButton {
        let loginButton = FBLoginButton()
        loginButton.permissions = ["public_profile", "email"]
        return loginButton
    }

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
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            guard let result = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            let user = result.user
            print("Logged in User: \(user)")
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
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

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }

    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        let facebookRequest = FBSDKLoginKit.GraphRequest(
            graphPath: "me",
            parameters: ["fields": "email, name"],
            tokenString: token,
            version: nil,
            httpMethod: .get
        )
        facebookRequest.start { _, result, error in
            guard let result = result as? [String: Any],
                    error == nil else {
                print(">>>> Failed to make facebok graph request")
                return
            }
            print(">>>>\(result)")
            guard let userName = result["name"] as? String,
                  let email = result["email"] as? String else {
                print(">>>> Failed to get email and name from fb request")
                return
            }
            let nameComponents = userName.components(separatedBy: " ")
            guard nameComponents.count == 2 else {
                return
            }
            let firstName = nameComponents[0]
            let lastName = nameComponents[1]

            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists {
                    DatabaseManager.shared.insertUser(with: CurrentUser(
                        firstName: firstName,
                        lastName: lastName,
                        emailAdress: email)
                    )
                }
            }
        }

        let credential = FacebookAuthProvider.credential(withAccessToken: token)
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            guard authResult != nil, error == nil else {
                if let error = error {
                    print(">>>> Facebook credential login failed, MFA may be needed - \(error)")
                }
                return
            }
            print(">>>> Successfuly loggin user in FB")
            self.navigationController?.dismiss(animated: true)
        }
    }
}
