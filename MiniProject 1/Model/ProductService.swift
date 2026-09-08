//
//  ProductService.swift
//  MiniProject 1
//

import Foundation

enum ProductServiceError: LocalizedError {
    case unexpectedStatus(Int)

    var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let code):
            return "The server responded with status \(code)."
        }
    }
}

struct ProductService {

    private static let endpoint = URL(string: "https://dummyjson.com/products")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchProducts() async throws -> [Product] {
        let (data, response) = try await session.data(from: Self.endpoint)

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ProductServiceError.unexpectedStatus(http.statusCode)
        }

        return try JSONDecoder().decode(ProductPage.self, from: data).products
    }
}
