//
//  CartViewController.swift
//  MiniProject 1
//

import UIKit

/// Screen 3: the products added to the cart.
/// Layout lives in `CartViewController.xib`.
final class CartViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var summaryBar: UIView!
    @IBOutlet private weak var itemCountLabel: UILabel!
    @IBOutlet private weak var totalLabel: UILabel!

    private let cart: Cart
    private var thumbnailTasks: [IndexPath: Task<Void, Never>] = [:]

    /// Decoded thumbnails by product id. Quantity edits reload the table, and
    /// without this the images would blink on every tap.
    private var thumbnails: [Int: UIImage] = [:]

    init(cart: Cart = .shared) {
        self.cart = cart
        super.init(nibName: "CartViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        thumbnailTasks.values.forEach { $0.cancel() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "Cart"

        summaryBar.backgroundColor = .secondarySystemBackground
        itemCountLabel.textColor = .secondaryLabel

        tableView.register(CartItemCell.nib, forCellReuseIdentifier: CartItemCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 112

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange),
                                               name: Cart.didChangeNotification,
                                               object: nil)

        updateSummary()
    }

    // MARK: - Cart changes

    @objc private func cartDidChange() {
        tableView.reloadData()
        updateSummary()
        setNeedsUpdateContentUnavailableConfiguration()
    }

    private func updateSummary() {
        let count = cart.itemCount
        itemCountLabel.text = count == 1 ? "1 item" : "\(count) items"
        totalLabel.text = cart.formattedTotal
        summaryBar.isHidden = cart.isEmpty
    }

    // MARK: - Empty state

    override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
        guard cart.isEmpty else {
            contentUnavailableConfiguration = nil
            return
        }

        var config = UIContentUnavailableConfiguration.empty()
        config.image = UIImage(systemName: "cart")
        config.text = "Your cart is empty"
        config.secondaryText = "Add products from the list to see them here."
        contentUnavailableConfiguration = config
    }

    // MARK: - Thumbnails

    private func loadThumbnail(for item: CartItem, at indexPath: IndexPath) {
        guard let url = item.product.thumbnail else { return }

        thumbnailTasks.removeValue(forKey: indexPath)?.cancel()

        thumbnailTasks[indexPath] = Task { [weak self] in
            let image = try? await ImageLoader.shared.image(for: url)

            guard !Task.isCancelled, let self else { return }
            self.thumbnailTasks[indexPath] = nil

            guard let image else { return }
            self.thumbnails[item.product.id] = image

            guard let cell = self.tableView.cellForRow(at: indexPath) as? CartItemCell else {
                return
            }

            cell.showThumbnail(image)
        }
    }
}

// MARK: - UITableViewDataSource

extension CartViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cart.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CartItemCell.reuseIdentifier,
                                                 for: indexPath)

        let item = cart.items[indexPath.row]

        if let cartCell = cell as? CartItemCell {
            cartCell.configure(with: item)
            cartCell.delegate = self

            if let image = thumbnails[item.product.id] {
                cartCell.showThumbnail(image)
            } else {
                loadThumbnail(for: item, at: indexPath)
            }
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension CartViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didEndDisplaying cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        thumbnailTasks.removeValue(forKey: indexPath)?.cancel()
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let remove = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            // Let the swipe finish committing before the model change reloads
            // the table out from under it.
            completion(true)
            self?.cart.remove(at: indexPath.row)
        }

        return UISwipeActionsConfiguration(actions: [remove])
    }
}

// MARK: - CartItemCellDelegate

extension CartViewController: CartItemCellDelegate {

    func cartItemCellDidTapDecrease(_ cell: CartItemCell) {
        guard let index = index(for: cell) else { return }

        // The cell disables "−" at the minimum, but never trust the view alone.
        let quantity = cart.items[index].quantity
        guard quantity > CartItemCell.minimumQuantity else { return }

        cart.setQuantity(quantity - 1, at: index)
    }

    func cartItemCellDidTapIncrease(_ cell: CartItemCell) {
        guard let index = index(for: cell) else { return }

        let quantity = cart.items[index].quantity
        cart.setQuantity(min(quantity + 1, CartItemCell.maximumQuantity), at: index)
    }

    private func index(for cell: CartItemCell) -> Int? {
        guard let row = tableView.indexPath(for: cell)?.row,
              cart.items.indices.contains(row) else {
            return nil
        }

        return row
    }

}
