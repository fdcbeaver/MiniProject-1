//
//  ViewController.swift
//  MiniProject 1
//
//  Created by FDC.Beaver-NC-IOS on 9/8/26.
//

import UIKit

class ViewController: UIViewController {

    private enum Layout {
        static let horizontalMargin: CGFloat = 20
        static let titleTopSpacing: CGFloat = 24
        static let fieldSpacing: CGFloat = 24
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "What's your name?"
        let base = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: base)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Let us know how to properly address you"
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let firstNameField = LabeledTextField(caption: "First name",
                                                  placeholder: "Enter first name")

    private let lastNameField = LabeledTextField(caption: "Last name",
                                                 placeholder: "Enter last name")

    private let submitButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Submit"
        config.baseBackgroundColor = .label
        config.baseForegroundColor = .systemBackground
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 28, bottom: 18, trailing: 28)
        let button = UIButton(configuration: config)
        return button
    }()

    /// Bottom inset of the button row, raised while the keyboard is on screen.
    private var bottomBarConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupLayout()
        setupBehavior()
        observeKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // This screen draws its own title, so it needs no navigation bar.
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupLayout() {
        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 12

        let fieldStack = UIStackView(arrangedSubviews: [firstNameField, lastNameField])
        fieldStack.axis = .vertical
        fieldStack.spacing = Layout.fieldSpacing

        let contentStack = UIStackView(arrangedSubviews: [headerStack, fieldStack])
        contentStack.axis = .vertical
        contentStack.spacing = 40
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        let bottomBar = UIStackView(arrangedSubviews: [UIView(), submitButton])
        bottomBar.axis = .horizontal
        bottomBar.alignment = .center
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(contentStack)
        view.addSubview(bottomBar)

        let safeArea = view.safeAreaLayoutGuide
        let bottomConstraint = bottomBar.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor,
                                                                 constant: -Layout.titleTopSpacing)
        bottomBarConstraint = bottomConstraint

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: safeArea.topAnchor,
                                              constant: Layout.titleTopSpacing),
            contentStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor,
                                                  constant: Layout.horizontalMargin),
            contentStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor,
                                                   constant: -Layout.horizontalMargin),

            bottomBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor,
                                               constant: Layout.horizontalMargin),
            bottomBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor,
                                                constant: -Layout.horizontalMargin),
            bottomConstraint
        ])
    }

    private func setupBehavior() {
        firstNameField.textField.textContentType = .givenName
        firstNameField.textField.returnKeyType = .next
        firstNameField.textField.delegate = self

        lastNameField.textField.textContentType = .familyName
        lastNameField.textField.returnKeyType = .done
        lastNameField.textField.delegate = self

        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: - Actions

    @objc private func submitTapped() {
        let firstName = firstNameField.trimmedText

        guard !firstName.isEmpty else {
            firstNameField.becomeFirstResponder()
            return
        }

        view.endEditing(true)

        let fullName = [firstName, lastNameField.trimmedText]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let productList = ProductListViewController(customerName: fullName)
        navigationController?.pushViewController(productList, animated: true)
    }

    // MARK: - Keyboard

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let keyboardTop = view.convert(frame, from: nil).minY
        let overlap = max(0, view.bounds.maxY - keyboardTop - view.safeAreaInsets.bottom)
        setBottomInset(Layout.titleTopSpacing + overlap, notification: notification)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        setBottomInset(Layout.titleTopSpacing, notification: notification)
    }

    private func setBottomInset(_ inset: CGFloat, notification: Notification) {
        bottomBarConstraint?.constant = -inset

        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UITextFieldDelegate

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === firstNameField.textField {
            lastNameField.becomeFirstResponder()
        } else {
            submitTapped()
        }
        return true
    }
}
