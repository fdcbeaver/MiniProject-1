//
//  ProductCell.swift
//  MiniProject 1
//

import UIKit

/// Reports the cell's Add button tap. The controller resolves the cell back to
/// an index path, so the cell never needs to know its own position.
protocol ProductCellDelegate: AnyObject {
    func productCellDidTapAdd(_ cell: ProductCell)
}

/// Row in the product list. Layout lives in `ProductCell.xib`.
///
/// The cell only displays what it is handed — fetching the thumbnail is the
/// controller's job, so the view layer never touches the network.
final class ProductCell: UITableViewCell {

    static let reuseIdentifier = "ProductCell"

    static var nib: UINib {
        UINib(nibName: "ProductCell", bundle: nil)
    }

    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var ratingLabel: UILabel!
    @IBOutlet private weak var addButton: UIButton!

    weak var delegate: ProductCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        // Interface Builder cannot express these, so they are set here.
        thumbnailImageView.layer.cornerRadius = 10
        thumbnailImageView.layer.cornerCurve = .continuous
        thumbnailImageView.backgroundColor = .secondarySystemBackground
        subtitleLabel.textColor = .secondaryLabel
        ratingLabel.textColor = .secondaryLabel

        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "plus",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 15,
                                                                              weight: .semibold))
        config.baseBackgroundColor = .label
        config.baseForegroundColor = .systemBackground
        config.cornerStyle = .capsule
        addButton.configuration = config
        addButton.accessibilityLabel = "Add to cart"

        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        delegate = nil
        thumbnailImageView.image = nil
    }

    func configure(with product: Product) {
        titleLabel.text = product.title
        subtitleLabel.text = product.subtitle
        priceLabel.text = product.formattedPrice
        ratingLabel.text = "★ \(product.formattedRating)"
        thumbnailImageView.image = nil
    }

    func showThumbnail(_ image: UIImage) {
        thumbnailImageView.image = image
    }

    @objc private func addTapped() {
        delegate?.productCellDidTapAdd(self)
    }
}
