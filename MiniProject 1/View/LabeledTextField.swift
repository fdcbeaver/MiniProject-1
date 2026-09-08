//
//  LabeledTextField.swift
//  MiniProject 1
//

import UIKit

/// A text field with a caption above it. Draws a bordered outline while it is
/// being edited and a filled, borderless box the rest of the time.
final class LabeledTextField: UIView {

    private enum Style {
        static let height: CGFloat = 56
        static let cornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 2
        static let textInset: CGFloat = 16
    }

    /// A field that insets its text so it sits comfortably inside the rounded box.
    private final class InsetTextField: UITextField {

        override func textRect(forBounds bounds: CGRect) -> CGRect {
            super.textRect(forBounds: bounds).insetBy(dx: Style.textInset, dy: 0)
        }

        override func editingRect(forBounds bounds: CGRect) -> CGRect {
            super.editingRect(forBounds: bounds).insetBy(dx: Style.textInset, dy: 0)
        }

        override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
            super.placeholderRect(forBounds: bounds).insetBy(dx: Style.textInset, dy: 0)
        }
    }

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        return label
    }()

    let textField: UITextField = {
        let textField = InsetTextField()
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.borderStyle = .none
        textField.layer.cornerRadius = Style.cornerRadius
        textField.layer.cornerCurve = .continuous
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .words
        return textField
    }()

    var text: String {
        textField.text ?? ""
    }

    /// `text` with leading and trailing whitespace removed.
    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init(caption: String, placeholder: String) {
        super.init(frame: .zero)

        captionLabel.text = caption
        textField.placeholder = placeholder

        let stack = UIStackView(arrangedSubviews: [captionLabel, textField])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            textField.heightAnchor.constraint(equalToConstant: Style.height)
        ])

        textField.addTarget(self, action: #selector(updateStyle), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(updateStyle), for: .editingDidEnd)
        updateStyle()

        // layer.borderColor is a cgColor, so it does not follow light/dark on its own.
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: Self, _) in
            view.textField.layer.borderColor = UIColor.label.cgColor
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func updateStyle() {
        let isEditing = textField.isFirstResponder
        textField.backgroundColor = isEditing ? .systemBackground : .secondarySystemBackground
        textField.layer.borderWidth = isEditing ? Style.borderWidth : 0
        textField.layer.borderColor = UIColor.label.cgColor
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }
}
