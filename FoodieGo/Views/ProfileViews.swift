import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var context
    @Environment(Session.self) private var session

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let user = session.user { header(user) }

                    menuSection("HESABIM") {
                        menuRow("Siparişlerim", icon: "shippingbox") { OrdersView() }
                        menuRow("İndirimler", icon: "tag") { CampaignsView() }
                        menuRow("Uygulama İstatistikleri", icon: "chart.bar") { StatsView() }
                    }

                    menuSection("AYARLAR") {
                        menuRow("Teslimat Adresi", icon: "mappin.and.ellipse") { AddressEditView() }
                        menuRow("Yapay Zekâ Ayarları", icon: "sparkles") { APIKeyView() }
                    }

                    Button {
                        try? context.save()
                        session.logout()
                    } label: {
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .card()
                    }
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("Profilim")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func header(_ user: AppUser) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "person")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .overlay(Circle().stroke(.white, lineWidth: 3))
            Text(user.fullName).font(.title3.weight(.semibold)).foregroundStyle(.white)
            Text(user.email).font(.subheadline).foregroundStyle(Theme.accent)
            if !user.phone.isEmpty {
                Text(user.phone).font(.caption).foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Theme.primary, Theme.green], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }

    private func menuSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(Theme.secondaryText).padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .card()
        }
    }

    private func menuRow<Destination: View>(_ title: String, icon: String, @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.primary)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.primary.opacity(0.1)))
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.secondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct AddressEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(Session.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Siparişlerin bu adrese teslim edilir.").foregroundStyle(Theme.secondaryText)
            TextField("Adres", text: $address, axis: .vertical)
                .lineLimit(2...4)
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.field))
            Button("Kaydet") {
                session.user?.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
                try? context.save()
                dismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty)
            Spacer()
        }
        .padding()
        .navigationTitle("Teslimat Adresi")
        .onAppear { address = session.user?.address ?? "" }
    }
}

struct APIKeyView: View {
    @AppStorage("geminiAPIKey") private var apiKey = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Şef, tarifleri Google Gemini ile hazırlar. aistudio.google.com adresinden ücretsiz bir API anahtarı alıp buraya yapıştır. Anahtar yalnızca bu cihazda saklanır.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
            SecureField("Gemini API anahtarı", text: $apiKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.field))
            if !apiKey.isEmpty {
                Label("Anahtar kaydedildi", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.green)
            } else if !GeminiService.bundledKey.isEmpty {
                Label("Uygulamanın varsayılan anahtarı kullanılıyor", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.green)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Yapay Zekâ Ayarları")
    }
}

struct OrdersView: View {
    @Environment(Session.self) private var session
    @Query(sort: \FoodOrder.date, order: .reverse) private var allOrders: [FoodOrder]

    private var orders: [FoodOrder] { allOrders.filter { $0.userEmail == session.email } }

    var body: some View {
        Group {
            if orders.isEmpty {
                ContentUnavailableView("Henüz siparişin yok", systemImage: "shippingbox", description: Text("Verdiğin siparişler burada listelenir."))
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(orders) { order in
                            NavigationLink { OrderDetailView(order: order) } label: { OrderCard(order: order) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Theme.background)
        .navigationTitle("Siparişlerim")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OrderCard: View {
    let order: FoodOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                (Text("Sipariş No: ") + Text("#\(order.orderNumber)").foregroundStyle(Theme.primary))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Label("Hazırlanıyor", systemImage: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.green)
            }
            Text(order.date.formatted(date: .numeric, time: .shortened))
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
            Divider()
            HStack(spacing: 8) {
                ForEach(order.items.prefix(4)) { item in
                    ProductThumb(imageName: item.imageName, emoji: item.emoji, size: 48)
                }
                if order.items.count > 4 {
                    Text("+\(order.items.count - 4) daha").font(.caption).foregroundStyle(Theme.secondaryText)
                }
            }
            Divider()
            HStack {
                Text("Toplam Tutar:").font(.subheadline)
                Spacer()
                Text(order.total.tl).font(.headline).foregroundStyle(Theme.primary)
            }
        }
        .padding()
        .card()
    }
}

struct OrderDetailView: View {
    let order: FoodOrder

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    row("Sipariş No", "#\(order.orderNumber)")
                    row("Tarih", order.date.formatted(date: .long, time: .shortened))
                    HStack {
                        Text("Durum").foregroundStyle(Theme.secondaryText)
                        Spacer()
                        Label("Hazırlanıyor", systemImage: "shippingbox").foregroundStyle(Theme.green)
                    }
                }
                .font(.subheadline)
                .padding()
                .card()

                VStack(spacing: 12) {
                    ForEach(order.items.sorted { $0.productName < $1.productName }) { item in
                        HStack(spacing: 12) {
                            ProductThumb(imageName: item.imageName, emoji: item.emoji, size: 52)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.productName).font(.subheadline.weight(.semibold))
                                Text("\(item.quantity) × \(item.unitPrice.tl)").font(.caption).foregroundStyle(Theme.secondaryText)
                            }
                            Spacer()
                            Text(item.lineTotal.tl).font(.subheadline.weight(.semibold))
                        }
                    }
                }
                .padding()
                .card()

                VStack(spacing: 8) {
                    row("Teslimat", order.deliveryFee == 0 ? "Ücretsiz" : order.deliveryFee.tl)
                    HStack {
                        Text("Toplam Tutar").font(.headline)
                        Spacer()
                        Text(order.total.tl).font(.headline).foregroundStyle(Theme.primary)
                    }
                }
                .font(.subheadline)
                .padding()
                .card()
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Sipariş Detayı")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Theme.secondaryText)
            Spacer()
            Text(value)
        }
    }
}

/// "İndirimler" — campaign cards with photo, badge and deadline.
struct CampaignsView: View {
    @Query(sort: \Campaign.endDate) private var campaigns: [Campaign]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Sana özel fırsatları kaçırma").foregroundStyle(Theme.secondaryText)
                ForEach(campaigns) { campaign in
                    VStack(alignment: .leading, spacing: 0) {
                        PhotoView(imageName: campaign.imageName, fallbackEmoji: campaign.emoji)
                            .frame(height: 170)
                            .overlay(alignment: .topLeading) {
                                Text("%\(campaign.discountPercent)")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(Theme.primary))
                                    .padding(12)
                            }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(campaign.title).font(.headline)
                            Text(campaign.details).font(.subheadline).foregroundStyle(Theme.secondaryText)
                            HStack {
                                Label("Son gün: \(campaign.endDate.formatted(.dateTime.day().month(.wide)))", systemImage: "alarm")
                                    .font(.caption)
                                    .foregroundStyle(Theme.red)
                                Spacer()
                                Text("Sepette uygulanır")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(Capsule().fill(Theme.primary))
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("İndirimler")
    }
}

struct StatsView: View {
    @Query private var users: [AppUser]
    @Query private var products: [Product]
    @Query private var categories: [ProductCategory]
    @Query private var orders: [FoodOrder]
    @Query private var cartItems: [CartItem]

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    /// Share of ordered items per category, by quantity.
    private var topCategory: (name: String, share: Int)? {
        let categoryByProduct = Dictionary(products.map { ($0.productID, $0.category?.name ?? "") }, uniquingKeysWith: { a, _ in a })
        var counts: [String: Int] = [:]
        for item in orders.flatMap(\.items) {
            counts[categoryByProduct[item.productID] ?? "", default: 0] += item.quantity
        }
        counts["", default: 0] = 0
        counts.removeValue(forKey: "")
        let total = counts.values.reduce(0, +)
        guard total > 0, let best = counts.max(by: { $0.value < $1.value }) else { return nil }
        return (best.key, Int((Double(best.value) / Double(total) * 100).rounded()))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                LazyVGrid(columns: columns, spacing: 14) {
                    tile("Kullanıcı", "\(users.count)", "person.2")
                    tile("Ürün", "\(products.count)", "basket")
                    tile("Kategori", "\(categories.count)", "square.grid.2x2")
                    tile("Sipariş", "\(orders.count)", "shippingbox")
                    tile("Aktif Sepet Hacmi", cartItems.reduce(0) { $0 + $1.lineTotal }.tl, "cart")
                    tile("Toplam Ciro", orders.reduce(0) { $0 + $1.total }.tl, "turkishlirasign.circle")
                }

                Text("Analitik Performans").font(.title3.weight(.semibold)).padding(.top, 4)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Ortalama Sipariş Tutarı").font(.subheadline).foregroundStyle(Theme.secondaryText)
                    Text(orders.isEmpty ? 0.0.tl : (orders.reduce(0) { $0 + $1.total } / Double(orders.count)).tl)
                        .font(.title.weight(.semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .card()

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("En Popüler Kategori").font(.subheadline).foregroundStyle(Theme.secondaryText)
                        Text(topCategory?.name ?? "Henüz sipariş yok").font(.title3.weight(.semibold))
                    }
                    Spacer()
                    if let share = topCategory?.share {
                        Text("%\(share)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.primary))
                    }
                }
                .padding()
                .card()
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle("Uygulama İstatistikleri")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tile(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.primary)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.primary.opacity(0.1)))
            Text(title).font(.caption).foregroundStyle(Theme.secondaryText).multilineTextAlignment(.center)
            Text(value).font(.title3.weight(.semibold)).minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .card()
    }
}
