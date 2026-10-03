import SwiftUI
import SwiftData
import UIKit

/// A bundled photo that fills its frame; falls back to the emoji if the asset is missing.
struct PhotoView: View {
    let imageName: String
    let fallbackEmoji: String
    var emojiSize: CGFloat = 52

    var body: some View {
        if UIImage(named: imageName) != nil {
            Color.clear
                .overlay(Image(imageName).resizable().scaledToFill())
                .clipped()
        } else {
            Color(.tertiarySystemFill)
                .overlay(Text(fallbackEmoji).font(.system(size: emojiSize)))
        }
    }
}

/// Darkens the bottom of a photo so white text on top stays readable.
struct PhotoOverlay: View {
    var body: some View {
        LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
    }
}

/// Product illustration centered on a soft tint of its category color.
struct ProductImage: View {
    let product: Product
    var height: CGFloat = 120
    var padding: CGFloat = 18
    var showsBadge = true

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(hex: product.category?.colorHex ?? "43A047").opacity(0.10))
            .frame(height: height)
            .overlay {
                if UIImage(named: product.imageName) != nil {
                    Image(product.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(padding)
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
                } else {
                    Text(product.emoji).font(.system(size: height * 0.45))
                }
            }
            .overlay(alignment: .topLeading) {
                if showsBadge, let discount = product.discountPercent {
                    Text("%\(discount)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Theme.red))
                        .padding(8)
                }
            }
    }
}

/// Small product thumbnail used in lists (cart, orders, assistant).
struct ProductThumb: View {
    let imageName: String
    let emoji: String
    var size: CGFloat = 56

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Theme.field)
            .frame(width: size, height: size)
            .overlay {
                if UIImage(named: imageName) != nil {
                    Image(imageName).resizable().scaledToFit().padding(size * 0.14)
                } else {
                    Text(emoji).font(.system(size: size * 0.5))
                }
            }
    }
}

struct PriceView: View {
    let product: Product
    var font: Font = .headline

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let old = product.oldPrice {
                Text(old.tl)
                    .font(.caption)
                    .strikethrough()
                    .foregroundStyle(Theme.secondaryText)
            }
            Text(product.price.tl)
                .font(font)
                .foregroundStyle(Theme.primary)
        }
    }
}

struct AddToCartButton: View {
    @Environment(\.modelContext) private var context
    @Environment(Session.self) private var session
    @Environment(AppRouter.self) private var router
    let product: Product
    @State private var added = false

    var body: some View {
        Button {
            CartActions.add(product, for: session.email, in: context)
            Haptics.tap()
            router.showToast("\(product.name) sepete eklendi")
            withAnimation(.snappy) { added = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.snappy) { added = false }
            }
        } label: {
            Image(systemName: added ? "checkmark" : "plus")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(RoundedRectangle(cornerRadius: 10).fill(added ? Theme.green : Theme.primary))
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sepete ekle")
    }
}

struct ProductCard: View {
    @Environment(AppRouter.self) private var router
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button { router.selectedProduct = product } label: {
                VStack(alignment: .leading, spacing: 4) {
                    ProductImage(product: product)
                    Text(product.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .padding(.top, 6)
                    Text(product.unit)
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .buttonStyle(.plain)

            HStack(alignment: .bottom) {
                PriceView(product: product, font: .subheadline.weight(.semibold))
                Spacer(minLength: 4)
                AddToCartButton(product: product)
            }
        }
        .padding(10)
        .card()
    }
}

struct ProductGrid: View {
    let products: [Product]
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(products) { ProductCard(product: $0) }
        }
    }
}

/// Floating "Sepetim" bar shown while the cart has items.
struct CartBar: View {
    @Environment(Session.self) private var session
    @Environment(AppRouter.self) private var router
    @Query private var allItems: [CartItem]

    private var items: [CartItem] { allItems.filter { $0.userEmail == session.email && $0.product != nil } }

    var body: some View {
        if !items.isEmpty {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SEPETİM · \(items.reduce(0) { $0 + $1.quantity }) ürün")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text(items.reduce(0) { $0 + $1.lineTotal }.tl)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                Spacer()
                Button { router.tab = .cart } label: {
                    Text("Sepete Git")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(Capsule().fill(Theme.accent))
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 20).fill(Theme.primary))
            .shadow(color: Theme.green.opacity(0.35), radius: 12, y: 6)
            .padding(.leading)
            .padding(.trailing, 86) // leave room for the AI button
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

struct ProductDetailSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(Session.self) private var session
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    let product: Product
    @State private var quantity = 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProductImage(product: product, height: 240, padding: 40)
                    .padding(.top, 24)

                VStack(spacing: 6) {
                    Text(product.name).font(.title2.weight(.semibold))
                    Text(product.unit).foregroundStyle(Theme.secondaryText)
                    HStack(spacing: 8) {
                        Text(product.price.tl).font(.title.weight(.semibold)).foregroundStyle(Theme.primary)
                        if let old = product.oldPrice {
                            Text(old.tl).strikethrough().foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Divider()

                infoBlock("Ürün Açıklaması", product.details)
                infoBlock("İçindekiler", product.ingredients)
                infoBlock("Besin Değerleri", product.nutrition)

                HStack(alignment: .top, spacing: 12) {
                    smallBox("Menşei", product.origin)
                    smallBox("Saklama Koşulu", product.storage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 14) {
                HStack(spacing: 16) {
                    Button { quantity = max(1, quantity - 1) } label: { Image(systemName: "minus") }
                    Text("\(quantity)").font(.headline.monospacedDigit()).frame(minWidth: 22)
                    Button { quantity += 1 } label: { Image(systemName: "plus") }
                }
                .font(.headline)
                .foregroundStyle(Theme.primary)
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.field))

                Button {
                    CartActions.add(product, quantity: quantity, for: session.email, in: context)
                    Haptics.success()
                    router.showToast("\(quantity) × \(product.name) sepete eklendi")
                    dismiss()
                } label: {
                    Text("Sepete Ekle · \((product.price * Double(quantity)).tl)")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.white)
        }
        .background(.white)
    }

    private func infoBlock(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(text).font(.subheadline).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func smallBox(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(Theme.secondaryText)
            Text(text).font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.08)))
    }
}
