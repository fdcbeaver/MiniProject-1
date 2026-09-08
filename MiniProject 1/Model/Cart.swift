//
//  Cart.swift
//  MiniProject 1
//

import Foundation

/// One line in the cart: a product plus how many of it were added.
struct CartItem {
    let product: Product
    var quantity: Int

    var lineTotal: Double {
        product.price * Double(quantity)
    }

    var formattedLineTotal: String {
        lineTotal.formatted(.currency(code: "USD"))
    }
}

/// The shopping cart. Posts `Cart.didChangeNotification` whenever its contents
/// change so any interested controller can refresh itself.
final class Cart {

    static let shared = Cart()

    static let didChangeNotification = Notification.Name("CartDidChangeNotification")

    private(set) var items: [CartItem] = []

    /// Total number of units, not lines — two of one product counts as two.
    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    var total: Double {
        items.reduce(0) { $0 + $1.lineTotal }
    }

    var formattedTotal: String {
        total.formatted(.currency(code: "USD"))
    }

    /// Adds one of `product`, bumping the quantity if it is already in the cart.
    func add(_ product: Product) {
        if let index = items.firstIndex(where: { $0.product.id == product.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(product: product, quantity: 1))
        }

        postChange()
    }

    func setQuantity(_ quantity: Int, at index: Int) {
        guard items.indices.contains(index) else { return }

        if quantity <= 0 {
            items.remove(at: index)
        } else {
            items[index].quantity = quantity
        }

        postChange()
    }

    func remove(at index: Int) {
        guard items.indices.contains(index) else { return }

        items.remove(at: index)
        postChange()
    }

    private func postChange() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}
