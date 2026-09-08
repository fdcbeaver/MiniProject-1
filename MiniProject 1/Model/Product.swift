//
//  Product.swift
//  MiniProject 1
//

import Foundation

/// Top level payload of `GET https://dummyjson.com/products`.
struct ProductPage: Decodable {
    let products: [Product]
    let total: Int
    let skip: Int
    let limit: Int
}

struct Product: Decodable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Double
    let discountPercentage: Double?
    let rating: Double
    let stock: Int
    let brand: String?
    let thumbnail: URL?

    var formattedPrice: String {
        price.formatted(.currency(code: "USD"))
    }

    var formattedRating: String {
        rating.formatted(.number.precision(.fractionLength(1)))
    }

    /// "Essence · Beauty", falling back to just the category when there is no brand.
    var subtitle: String {
        let capitalizedCategory = category.capitalized
        guard let brand, !brand.isEmpty else { return capitalizedCategory }
        return "\(brand) · \(capitalizedCategory)"
    }
}
