import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(Session.self) private var session
    @Environment(AppRouter.self) private var router

    @Query(sort: \Product.productID) private var products: [Product]
    @Query(sort: \ProductCategory.categoryID) private var categories: [ProductCategory]
    @Query(sort: \Campaign.endDate) private var campaigns: [Campaign]
    @State private var search = ""
    @State private var heroPage = 0
    @State private var path = NavigationPath()

    private var searchResults: [Product] {
        products.filter {
            $0.name.localizedStandardContains(search) || ($0.category?.name.localizedStandardContains(search) ?? false)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    topBar
                    SearchField(placeholder: "Ürün, kategori veya marka ara", text: $search)

                    if search.isEmpty {
                        hero
                        categoryRow
                        deliveryBanner
                        dealsRow
                        SectionHeader(title: "Popüler Ürünler") { path.append(ProductListRoute(categoryID: nil)) }
                        ProductGrid(products: Array(products.prefix(8)))
                    } else if searchResults.isEmpty {
                        ContentUnavailableView.search(text: search)
                    } else {
                        Text("\(searchResults.count) sonuç").font(.headline)
                        ProductGrid(products: searchResults)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) { CartBar() }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ProductListRoute.self) { ProductListView(initialCategoryID: $0.categoryID) }
            .navigationDestination(for: CampaignsRoute.self) { _ in CampaignsView() }
        }
    }

    private var topBar: some View {
        HStack {
            Image(systemName: "mappin.and.ellipse")
                .font(.title3)
                .foregroundStyle(Theme.primary)
            Spacer()
            VStack(spacing: 1) {
                Text("Teslimat Adresi").font(.caption2).foregroundStyle(Theme.secondaryText)
                Text("Ev • \(session.user?.address ?? "")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primary)
                    .lineLimit(1)
            }
            Spacer()
            Button { path.append(CampaignsRoute()) } label: {
                Image(systemName: "bell")
                    .font(.title3)
                    .foregroundStyle(Theme.primary)
                    .overlay(alignment: .topTrailing) {
                        Circle().fill(Theme.red).frame(width: 8, height: 8).offset(x: 2, y: -1)
                    }
            }
        }
        .padding(.top, 4)
    }

    private var hero: some View {
        VStack(spacing: 10) {
            TabView(selection: $heroPage) {
                ForEach(Array(campaigns.enumerated()), id: \.offset) { index, campaign in
                    HeroCard(campaign: campaign)
                        .onTapGesture { path.append(CampaignsRoute()) }
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 176)

            HStack(spacing: 6) {
                ForEach(campaigns.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == heroPage ? Theme.primary : Color.black.opacity(0.15))
                        .frame(width: index == heroPage ? 18 : 7, height: 7)
                }
            }
            .animation(.snappy, value: heroPage)
        }
    }

    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Kategoriler") { router.tab = .categories }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories) { category in
                        Button { path.append(ProductListRoute(categoryID: category.categoryID)) } label: {
                            VStack(spacing: 8) {
                                PhotoView(imageName: category.imageName, fallbackEmoji: category.emoji, emojiSize: 30)
                                    .frame(width: 76, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text(category.name)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 76, height: 32, alignment: .top)
                            }
                            .padding(8)
                            .card(radius: 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 2)
            }
        }
    }

    private var deliveryBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.car")
                .font(.title3)
                .foregroundStyle(Theme.primary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.primary.opacity(0.12)))
            VStack(alignment: .leading, spacing: 2) {
                Text("Hızlı teslimat avantajlarını kaçırma!").font(.subheadline.weight(.semibold))
                Text("300 TL üzeri siparişlerde teslimat ücretsiz.").font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: 4)
            Button("İncele") { path.append(CampaignsRoute()) }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(Theme.primary))
        }
        .padding(12)
        .card()
    }

    private var dealsRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Haftanın Fırsatları")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(products.filter(\.isWeeklyDeal)) { product in
                        ProductCard(product: product).frame(width: 164)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 2)
            }
        }
    }
}

struct ProductListRoute: Hashable { let categoryID: Int? }
struct CampaignsRoute: Hashable {}

/// Big campaign banner at the top of the home screen.
struct HeroCard: View {
    let campaign: Campaign

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("%\(campaign.discountPercent) İndirim")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Theme.accent))
                Text(campaign.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(campaign.details)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            PhotoView(imageName: campaign.imageName, fallbackEmoji: campaign.emoji, emojiSize: 44)
                .frame(width: 118, height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.5), lineWidth: 3))
                .rotationEffect(.degrees(4))
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(colors: [Theme.primary, Theme.green], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(alignment: .topTrailing) {
            Circle().fill(.white.opacity(0.08)).frame(width: 140).offset(x: 40, y: -50)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 1)
    }
}
