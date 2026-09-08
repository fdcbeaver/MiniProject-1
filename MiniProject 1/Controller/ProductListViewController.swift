//
//  ProductListViewController.swift
//  MiniProject 1
//

import UIKit

/// Screen 2: the product list from https://dummyjson.com/products.
/// Layout lives in `ProductListViewController.xib`.
final class ProductListViewController: UIViewController {

    private enum LoadState {
        case loading
        case loaded
        case failed(Error)
    }

    @IBOutlet private weak var greetingLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!

    private let customerName: String
    private let service: ProductService
    private let cart: Cart

    private let cartButton = CartButton()

    private var products: [Product] = []
    private var loadTask: Task<Void, Never>?
    private var thumbnailTasks: [IndexPath: Task<Void, Never>] = [:]

    private var loadState: LoadState = .loading {
        didSet { setNeedsUpdateContentUnavailableConfiguration() }
    }

    init(customerName: String = "",
         service: ProductService = ProductService(),
         cart: Cart = .shared) {
        self.customerName = customerName
        self.service = service
        self.cart = cart
        super.init(nibName: "ProductListViewController", bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
        thumbnailTasks.values.forEach { $0.cancel() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "Products"

        greetingLabel.text = customerName.isEmpty
            ? "Here is what we have in store"
            : "Hi \(customerName), here is what we have in store"
        greetingLabel.textColor = .secondaryLabel

        tableView.register(ProductCell.nib, forCellReuseIdentifier: ProductCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 104

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        tableView.refreshControl = refreshControl

        setupCartButton()
        loadProducts()
    }

    private func setupCartButton() {
        cartButton.addTarget(self, action: #selector(cartTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cartButton)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cartDidChange),
                                               name: Cart.didChangeNotification,
                                               object: nil)

        updateCartBadge()
    }

    private func updateCartBadge() {
        cartButton.itemCount = cart.itemCount
    }

    @objc private func cartDidChange() {
        updateCartBadge()
    }

    @objc private func cartTapped() {
        navigationController?.pushViewController(CartViewController(cart: cart), animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        updateCartBadge()
    }

    // MARK: - Loading

    private func loadProducts() {
        loadTask?.cancel()
        cancelThumbnailLoads()

        if products.isEmpty {
            loadState = .loading
        }

        loadTask = Task { [weak self] in
            guard let self else { return }

            do {
                let products = try await self.service.fetchProducts()
                guard !Task.isCancelled else { return }

                self.products = products
                self.loadState = .loaded
                self.tableView.reloadData()
            } catch {
                guard !Task.isCancelled else { return }
                self.loadState = .failed(error)
            }

            self.tableView.refreshControl?.endRefreshing()
        }
    }

    @objc private func refreshPulled() {
        loadProducts()
    }

    // MARK: - Thumbnails

    /// Fetches the thumbnail for a row and hands the image to whichever cell is
    /// showing that row by the time it arrives.
    private func loadThumbnail(for product: Product, at indexPath: IndexPath) {
        guard let url = product.thumbnail else { return }

        thumbnailTasks.removeValue(forKey: indexPath)?.cancel()

        thumbnailTasks[indexPath] = Task { [weak self] in
            let image = try? await ImageLoader.shared.image(for: url)

            guard !Task.isCancelled, let self else { return }
            self.thumbnailTasks[indexPath] = nil

            guard let image,
                  let cell = self.tableView.cellForRow(at: indexPath) as? ProductCell else {
                return
            }

            cell.showThumbnail(image)
        }
    }

    private func cancelThumbnailLoads() {
        thumbnailTasks.values.forEach { $0.cancel() }
        thumbnailTasks.removeAll()
    }

    // MARK: - Loading / error / empty states

    override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
        switch loadState {
        case .loading:
            contentUnavailableConfiguration = products.isEmpty
                ? UIContentUnavailableConfiguration.loading()
                : nil

        case .loaded:
            guard products.isEmpty else {
                contentUnavailableConfiguration = nil
                return
            }

            var config = UIContentUnavailableConfiguration.empty()
            config.image = UIImage(systemName: "shippingbox")
            config.text = "No products"
            config.secondaryText = "The catalogue came back empty."
            contentUnavailableConfiguration = config

        case .failed(let error):
            var config = UIContentUnavailableConfiguration.empty()
            config.image = UIImage(systemName: "wifi.exclamationmark")
            config.text = "Couldn't load products"
            config.secondaryText = error.localizedDescription

            var button = UIButton.Configuration.borderedTinted()
            button.title = "Try Again"
            config.button = button
            config.buttonProperties.primaryAction = UIAction { [weak self] _ in
                self?.loadProducts()
            }

            contentUnavailableConfiguration = config
        }
    }
}

// MARK: - UITableViewDataSource

extension ProductListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductCell.reuseIdentifier,
                                                 for: indexPath)

        let product = products[indexPath.row]

        if let productCell = cell as? ProductCell {
            productCell.configure(with: product)
            productCell.delegate = self
            loadThumbnail(for: product, at: indexPath)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate

extension ProductListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   didEndDisplaying cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        thumbnailTasks.removeValue(forKey: indexPath)?.cancel()
    }

}

// MARK: - ProductCellDelegate

extension ProductListViewController: ProductCellDelegate {

    func productCellDidTapAdd(_ cell: ProductCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        cart.add(products[indexPath.row])
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
