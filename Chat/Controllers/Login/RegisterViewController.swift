//
//  RegisterViewController.swift
//  Chat
//
//  Created by Mikhail Danilov on 26.07.2022.
//

import UIKit
import TinyConstraints
import FirebaseAuth

class RegisterViewController: UIViewController {
    private lazy var scrollView: UIScrollView = Self.makeScrollView()
    private lazy var scrollViewContainer: UIStackView = Self.makeScrollViewContainer()
    private lazy var imageView: UIImageView = Self.makeImageView()
    private lazy var emailField: UITextField = Self.makeEmailField()
    private lazy var firstNameField: UITextField = Self.makeFistNameField()
    private lazy var lastNameField: UITextField = Self.makeLastNameField()
    private lazy var passwordField: UITextField = Self.makePasswordField()
    private lazy var registerButton: UIButton = Self.makeRegisterButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Registration"
        self.view.backgroundColor = .white

        self.view.addSubview(self.scrollView)
        self.scrollView.edgesToSuperview()

        self.scrollView.addSubview(self.scrollViewContainer)
        self.scrollViewContainer.edgesToSuperview()
        self.scrollViewContainer.widthToSuperview(relation: .equal)

        self.scrollViewContainer.addArrangedSubview(self.imageView)
        self.imageView.centerXToSuperview()

        self.scrollViewContainer.addArrangedSubview(self.firstNameField)
        self.scrollViewContainer.addArrangedSubview(self.lastNameField)
        self.scrollViewContainer.addArrangedSubview(self.emailField)
        self.scrollViewContainer.addArrangedSubview(self.passwordField)
        self.scrollViewContainer.addArrangedSubview(self.registerButton)

        self.registerButton.addTarget(self,
                                   action: #selector(self.registerButtonTapped),
                                   for: .touchUpInside)

        self.emailField.delegate = self
        self.passwordField.delegate = self

        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.didTappedChangeProfilePic))
        self.imageView.isUserInteractionEnabled = true
        self.imageView.addGestureRecognizer(gesture)
    }
}

// MARK: - Factory
extension RegisterViewController {
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
        imageView.image = UIImage(systemName: "person.circle")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 30
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

    private static func makeFistNameField() -> UITextField {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.height(50)
        textField.placeholder = "First Name..."
        return textField
    }

    private static func makeLastNameField() -> UITextField {
        let textField = UITextField()
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.height(50)
        textField.placeholder = "Last Name..."
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

    private static func makeRegisterButton() -> UIButton {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.height(50)
        return button
    }
}

// MARK: - Actions
extension RegisterViewController {
    @objc private func registerButtonTapped() {
        self.firstNameField.resignFirstResponder()
        self.lastNameField.resignFirstResponder()
        self.emailField.resignFirstResponder()
        self.passwordField.resignFirstResponder()

        guard let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty,
              !firstName.isEmpty,
              !lastName.isEmpty,
              password.count >= 6 else {
            alertUserLoginError()
            return
        }
        DatabaseManager.shared.userExists(with: email) { [weak self] exists in
            guard let self = self else { return }
            guard !exists else {
                self.alertUserLoginError(message: "Looks like a user account for that email address alredy exists.")
                return
            }

            Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResults, error in
                guard let self = self else { return }
                guard authResults != nil, error == nil else {
                    print("error creating User")
                    return
                }
                DatabaseManager.shared.insertUser(with: CurrentUser(
                    firstName: firstName,
                    lastName: lastName,
                    emailAdress: email
                ))
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    @objc private func didTappedChangeProfilePic() {
        self.presentPhotoActionSheet()
    }
}

// MARK: - Private
extension RegisterViewController {
    private func alertUserLoginError(message: String = "Please enter all information to create new account.") {
        let alert = UIAlertController(title: "Ops", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dissmis", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField {
            self.registerButtonTapped()
        }
        return true
    }
}

// MARK: - UIImagePickerControllerDelegate
extension RegisterViewController: UIImagePickerControllerDelegate {
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(
            title: "Profile Picture",
            message: "How would you like to select a picture?",
            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil)
        )
        actionSheet.addAction(UIAlertAction(
            title: "Take Photo",
            style: .default,
            handler: { [weak self] _ in
                self?.presentCamera()
            }))
        actionSheet.addAction(UIAlertAction(
            title: "Chose Photo",
            style: .default,
            handler: { [weak self] _ in
                self?.presentPhotoPicker()
            }))
        present(actionSheet, animated: true)
    }


    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }

    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        print(info)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { return }
        self.imageView.image = selectedImage
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

}

// MARK: - UINavigationControllerDelegate
extension RegisterViewController: UINavigationControllerDelegate {

}
