import Foundation
import SwiftData

enum CartActions {
    static let freeDeliveryThreshold = 300.0
    static let deliveryFee = 29.90

    static func items(for email: String, in context: ModelContext) -> [CartItem] {
        let descriptor = FetchDescriptor<CartItem>(predicate: #Predicate { $0.userEmail == email })
        return (try? context.fetch(descriptor)) ?? []
    }

    static func add(_ product: Product, quantity: Int = 1, for email: String, in context: ModelContext) {
        guard !email.isEmpty else { return }
        if let existing = items(for: email, in: context).first(where: { $0.product?.productID == product.productID }) {
            existing.quantity += quantity
        } else {
            context.insert(CartItem(userEmail: email, product: product, quantity: quantity))
        }
        try? context.save()
    }

    static func setQuantity(_ item: CartItem, to quantity: Int, in context: ModelContext) {
        if quantity <= 0 {
            context.delete(item)
        } else {
            item.quantity = quantity
        }
        try? context.save()
    }

    static func remove(_ item: CartItem, in context: ModelContext) {
        context.delete(item)
        try? context.save()
    }

    static func delivery(forSubtotal subtotal: Double) -> Double {
        subtotal >= freeDeliveryThreshold || subtotal == 0 ? 0 : deliveryFee
    }

    /// Turns the cart into an order: random order number, date, total and a snapshot of every item.
    @discardableResult
    static func checkout(for email: String, in context: ModelContext) throws -> FoodOrder? {
        let cart = items(for: email, in: context).filter { $0.product != nil }
        guard !cart.isEmpty else { return nil }

        let subtotal = cart.reduce(0) { $0 + $1.lineTotal }
        let fee = delivery(forSubtotal: subtotal)
        let order = FoodOrder(orderNumber: "FG-\(Int.random(in: 100_000...999_999))",
                              userEmail: email, total: subtotal + fee, deliveryFee: fee)
        context.insert(order)
        for item in cart {
            guard let product = item.product else { continue }
            order.items.append(OrderItem(productID: product.productID, productName: product.name, emoji: product.emoji, unit: product.unit,
                                         unitPrice: product.price, quantity: item.quantity))
            context.delete(item)
        }
        try context.save()
        return order
    }
}
