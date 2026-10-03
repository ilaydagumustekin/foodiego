import SwiftUI
import SwiftData

struct CartView: View {
    @Environment(\.modelContext) private var context
    @Environment(Session.self) private var session
    @Environment(AppRouter.self) private var router
    @Query(sort: \CartItem.addedAt) private var allItems: [CartItem]
    @State private var placedOrder: FoodOrder?
    @State private var error: String?

    private var items: [CartItem] {
        allItems.filter { $0.userEmail == session.email && $0.product != nil }
    }
    private var subtotal: Double { items.reduce(0) { $0 + $1.lineTotal } }
    private var delivery: Double { CartActions.delivery(forSubtotal: subtotal) }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView {
                        Label("Sepetin boş", systemImage: "cart")
                    } description: {
                        Text("Ürünleri keşfet ya da AI Şef'ten bir tarif iste.")
                    } actions: {
                        Button("Alışverişe Başla") { router.tab = .home }
                            .buttonStyle(PrimaryButtonStyle())
                            .frame(width: 220)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(items) { item in
                                if let product = item.product {
                                    CartRow(item: item, product: product)
                                }
                            }
                            deliveryNote
                        }
                        .padding()
                        .padding(.bottom, 12)
                    }
                    .safeAreaInset(edge: .bottom) { checkoutBar }
                }
            }
            .background(Theme.background)
            .navigationTitle("Sepetim")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Siparişin alındı 🎉", isPresented: Binding(get: { placedOrder != nil }, set: { if !$0 { placedOrder = nil } })) {
                Button("Tamam", role: .cancel) {}
            } message: {
                if let placedOrder {
                    Text("Sipariş numaran: #\(placedOrder.orderNumber)\nToplam: \(placedOrder.total.tl)")
                }
            }
            .alert("Sipariş oluşturulamadı", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
        }
    }

    private var deliveryNote: some View {
        HStack(spacing: 10) {
            Image(systemName: delivery == 0 ? "checkmark.seal.fill" : "shippingbox")
                .foregroundStyle(Theme.primary)
            Text(delivery == 0
                 ? "Teslimat ücretsiz!"
                 : "\((CartActions.freeDeliveryThreshold - subtotal).tl) daha ekle, teslimat ücretsiz olsun.")
                .font(.footnote)
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.primary.opacity(0.08)))
    }

    private var checkoutBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Ara toplam").foregroundStyle(Theme.secondaryText)
                Spacer()
                Text(subtotal.tl)
            }
            .font(.subheadline)
            HStack {
                Text("Teslimat").foregroundStyle(Theme.secondaryText)
                Spacer()
                Text(delivery == 0 ? "Ücretsiz" : delivery.tl)
            }
            .font(.subheadline)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Toplam Tutar").font(.caption).foregroundStyle(Theme.secondaryText)
                    Text((subtotal + delivery).tl).font(.title3.weight(.bold)).foregroundStyle(Theme.primary)
                }
                Button("Siparişi Tamamla", action: checkout)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func checkout() {
        do {
            placedOrder = try CartActions.checkout(for: session.email, in: context)
            Haptics.success()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct CartRow: View {
    @Environment(\.modelContext) private var context
    let item: CartItem
    let product: Product

    var body: some View {
        HStack(spacing: 14) {
            ProductThumb(imageName: product.imageName, emoji: product.emoji, size: 68)
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name).font(.subheadline.weight(.semibold))
                Text(product.unit).font(.caption).foregroundStyle(Theme.secondaryText)
                Text(product.price.tl).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.primary)
            }
            Spacer()
            HStack(spacing: 10) {
                Button { CartActions.setQuantity(item, to: item.quantity - 1, in: context) } label: {
                    Image(systemName: item.quantity == 1 ? "trash" : "minus")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(item.quantity == 1 ? Theme.red : .primary)
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.field))
                }
                Text("\(item.quantity)").font(.headline.monospacedDigit()).frame(minWidth: 18)
                Button { CartActions.setQuantity(item, to: item.quantity + 1, in: context) } label: {
                    Image(systemName: "plus")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.primary))
                }
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .card()
    }
}
