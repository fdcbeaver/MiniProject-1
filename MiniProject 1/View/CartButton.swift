//
//  CartButton.swift
//  MiniProject 1
//

import UIKit

/// Circular cart button with a red count badge in its top-trailing corner.
/// The badge hides at zero and caps its text at "99+".
///
/// This is a `UIControl` rather than a `UIButton` on purpose: every layer is an
/// explicit subview, so there is no internal button imageView/titleLabel to
/// reorder or paint over the badge.
final class CartButton: UIControl {

    private enum Style {
        static let side: CGFloat = 40
        static let badgeHeight: CGFloat = 18
        static let badgeTextInset: CGFloat = 5
        static let maxDisplayedCount = 99
    }

    private let circleView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemFill
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "cart.fill",
                                  withConfiguration: UIImage.SymbolConfiguration(pointSize: 16,
                                                                                 weight: .semibold))
        imageView.tintColor = .label
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let badgeView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    var itemCount: Int = 0 {
        didSet { updateBadge() }
    }

    /// A bar button item's custom view is sized from this.
    override var intrinsicContentSize: CGSize {
        CGSize(width: Style.side, height: Style.side)
    }

    override var isHighlighted: Bool {
        didSet { circleView.alpha = isHighlighted ? 0.6 : 1 }
    }

    override init(frame: CGRect) {
        super.init(frame: .init(x: 0, y: 0, width: Style.side, height: Style.side))
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        // Touches must land on the control itself, never on the decoration.
        for subview in [circleView, iconView, badgeView, badgeLabel] {
            subview.isUserInteractionEnabled = false
        }

        addSubview(circleView)
        circleView.addSubview(iconView)
        addSubview(badgeView)
        badgeView.addSubview(badgeLabel)
        bringSubviewToFront(badgeView)

        NSLayoutConstraint.activate([
            circleView.topAnchor.constraint(equalTo: topAnchor),
            circleView.leadingAnchor.constraint(equalTo: leadingAnchor),
            circleView.trailingAnchor.constraint(equalTo: trailingAnchor),
            circleView.bottomAnchor.constraint(equalTo: bottomAnchor),
            circleView.widthAnchor.constraint(equalToConstant: Style.side),
            circleView.heightAnchor.constraint(equalToConstant: Style.side),

            iconView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),

            // Flush to the corner so the navigation bar cannot clip the badge.
            badgeView.topAnchor.constraint(equalTo: topAnchor),
            badgeView.trailingAnchor.constraint(equalTo: trailingAnchor),
            badgeView.heightAnchor.constraint(equalToConstant: Style.badgeHeight),
            badgeView.widthAnchor.constraint(greaterThanOrEqualTo: badgeView.heightAnchor),

            // The label's own size drives the badge width, plus side padding.
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),
            badgeLabel.leadingAnchor.constraint(equalTo: badgeView.leadingAnchor,
                                                constant: Style.badgeTextInset),
            badgeView.trailingAnchor.constraint(equalTo: badgeLabel.trailingAnchor,
                                                constant: Style.badgeTextInset)
        ])

        updateBadge()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Derived from the real laid-out size, so the pill is always fully round.
        circleView.layer.cornerRadius = circleView.bounds.height / 2
        circleView.layer.cornerCurve = .continuous
        circleView.layer.masksToBounds = true

        badgeView.layer.cornerRadius = badgeView.bounds.height / 2
        badgeView.layer.cornerCurve = .continuous
        badgeView.layer.masksToBounds = true
    }

    private func updateBadge() {
        badgeLabel.text = itemCount > Style.maxDisplayedCount
            ? "\(Style.maxDisplayedCount)+"
            : "\(itemCount)"

        badgeView.isHidden = itemCount <= 0

        accessibilityLabel = itemCount == 1 ? "Cart, 1 item" : "Cart, \(itemCount) items"

        setNeedsLayout()
    }
}
