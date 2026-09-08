//
//  CartItemCell.swift
//  MiniProject 1
//

import UIKit

/// Reports the cell's quantity buttons. The controller resolves the cell back to
/// an index path, so the cell never needs to know its own position.
protocol CartItemCellDelegate: AnyObject {
    func cartItemCellDidTapDecrease(_ cell: CartItemCell)
    func cartItemCellDidTapIncrease(_ cell: CartItemCell)
}

/// Row in the cart. Layout lives in `CartItemCell.xib`.
final class CartItemCell: UITableViewCell {

    static let reuseIdentifier = "CartItemCell"

    /// "−" is disabled at this quantity; removing a line is done by swiping.
    static let minimumQuantity = 1

    static let maximumQuantity = 99

    static var nib: UINib {
        UINib(nibName: "CartItemCell", bundle: nil)
    }

    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var unitPriceLabel: UILabel!
    @IBOutlet private weak var decreaseButton: UIButton!
    @IBOutlet private weak var quantityLabel: UILabel!
    @IBOutlet private weak var increaseButton: UIButton!
    @IBOutlet private weak var lineTotalLabel: UILabel!

    weak var delegate: CartItemCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.layer.cornerCurve = .continuous
        thumbnailImageView.backgroundColor = .secondarySystemBackground
        unitPriceLabel.textColor = .secondaryLabel

        style(decreaseButton, symbolName: "minus", accessibilityLabel: "Decrease quantity")
        style(increaseButton, symbolName: "plus", accessibilityLabel: "Increase quantity")

        decreaseButton.addTarget(self, action: #selector(decreaseTapped), for: .touchUpInside)
        increaseButton.addTarget(self, action: #selector(increaseTapped), for: .touchUpInside)
    }

    /// Interface Builder cannot express a symbol image plus a capsule fill, so
    /// both buttons are styled here.
    private func style(_ button: UIButton, symbolName: String, accessibilityLabel: String) {
        var config = UIButton.Configuration.gray()
        config.image = UIImage(systemName: symbolName,
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 14,
                                                                              weight: .semibold))
        config.baseForegroundColor = .label
        config.cornerStyle = .capsule
        button.configuration = config
        button.accessibilityLabel = accessibilityLabel
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        delegate = nil
        thumbnailImageView.image = nil
    }

    func configure(with item: CartItem) {
        titleLabel.text = item.product.title
        unitPriceLabel.text = "\(item.product.formattedPrice) each"
        quantityLabel.text = "\(item.quantity)"
        lineTotalLabel.text = item.formattedLineTotal

        decreaseButton.isEnabled = item.quantity > Self.minimumQuantity
        increaseButton.isEnabled = item.quantity < Self.maximumQuantity
    }

    func showThumbnail(_ image: UIImage) {
        thumbnailImageView.image = image
    }

    @objc private func decreaseTapped() {
        delegate?.cartItemCellDidTapDecrease(self)
    }

    @objc private func increaseTapped() {
        delegate?.cartItemCellDidTapIncrease(self)
    }
}
