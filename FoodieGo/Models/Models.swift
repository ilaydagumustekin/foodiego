import Foundation
import SwiftData

@Model
final class AppUser {
    @Attribute(.unique) var email: String
    var fullName: String
    var phone: String = ""
    var passwordHash: String
    var address: String
    var createdAt: Date

    init(email: String, fullName: String, phone: String = "", passwordHash: String, address: String = "Kadıköy, İstanbul") {
        self.email = email
        self.fullName = fullName
        self.phone = phone
        self.passwordHash = passwordHash
        self.address = address
        self.createdAt = .now
    }
}

@Model
final class ProductCategory {
    @Attribute(.unique) var categoryID: Int
    var name: String
    var emoji: String
    var colorHex: String
    @Relationship(deleteRule: .cascade, inverse: \Product.category) var products: [Product] = []

    init(categoryID: Int, name: String, emoji: String, colorHex: String) {
        self.categoryID = categoryID
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
    }

    /// Cover photo in Assets.xcassets ("category_<id>").
    var imageName: String { "category_\(categoryID)" }
}

@Model
final class Product {
    /// Stable numeric id — this is what the AI assistant refers to when matching ingredients.
    @Attribute(.unique) var productID: Int
    var name: String
    var emoji: String
    var price: Double
    var oldPrice: Double?
    var unit: String
    var details: String
    var ingredients: String
    var nutrition: String
    var origin: String
    var storage: String
    var isWeeklyDeal: Bool
    var category: ProductCategory?

    init(productID: Int, name: String, emoji: String, price: Double, oldPrice: Double? = nil, unit: String,
         details: String, ingredients: String, nutrition: String, origin: String, storage: String,
         isWeeklyDeal: Bool = false, category: ProductCategory? = nil) {
        self.productID = productID
        self.name = name
        self.emoji = emoji
        self.price = price
        self.oldPrice = oldPrice
        self.unit = unit
        self.details = details
        self.ingredients = ingredients
        self.nutrition = nutrition
        self.origin = origin
        self.storage = storage
        self.isWeeklyDeal = isWeeklyDeal
        self.category = category
    }

    /// Photo in Assets.xcassets ("product_<id>").
    var imageName: String { "product_\(productID)" }

    var discountPercent: Int? {
        guard let oldPrice, oldPrice > price else { return nil }
        return Int(((oldPrice - price) / oldPrice * 100).rounded())
    }
}

@Model
final class CartItem {
    var userEmail: String
    var product: Product?
    var quantity: Int
    var addedAt: Date

    init(userEmail: String, product: Product, quantity: Int) {
        self.userEmail = userEmail
        self.product = product
        self.quantity = quantity
        self.addedAt = .now
    }

    var lineTotal: Double { (product?.price ?? 0) * Double(quantity) }
}

@Model
final class FoodOrder {
    @Attribute(.unique) var orderNumber: String
    var userEmail: String
    var date: Date
    var total: Double
    var deliveryFee: Double
    @Relationship(deleteRule: .cascade) var items: [OrderItem] = []

    init(orderNumber: String, userEmail: String, total: Double, deliveryFee: Double) {
        self.orderNumber = orderNumber
        self.userEmail = userEmail
        self.date = .now
        self.total = total
        self.deliveryFee = deliveryFee
    }
}

/// A snapshot of the product at order time, so later price changes don't rewrite history.
@Model
final class OrderItem {
    var productID: Int = 0
    var productName: String
    var emoji: String
    var unit: String
    var unitPrice: Double
    var quantity: Int

    init(productID: Int, productName: String, emoji: String, unit: String, unitPrice: Double, quantity: Int) {
        self.productID = productID
        self.productName = productName
        self.emoji = emoji
        self.unit = unit
        self.unitPrice = unitPrice
        self.quantity = quantity
    }

    var lineTotal: Double { unitPrice * Double(quantity) }
    var imageName: String { "product_\(productID)" }
}

@Model
final class Campaign {
    var title: String
    var details: String
    var emoji: String
    var colorHex: String
    var discountPercent: Int
    var endDate: Date

    init(title: String, details: String, emoji: String, colorHex: String, discountPercent: Int, endDate: Date) {
        self.title = title
        self.details = details
        self.emoji = emoji
        self.colorHex = colorHex
        self.discountPercent = discountPercent
        self.endDate = endDate
    }

    /// Campaigns reuse the cover photo of the category they promote.
    var imageName: String {
        let category = ["🍓": 1, "🍳": 3, "🎉": 6, "🍿": 5][emoji] ?? 1
        return "category_\(category)"
    }
}
