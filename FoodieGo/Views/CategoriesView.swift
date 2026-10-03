import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(Session.self) private var session
    @Query(sort: \ProductCategory.categoryID) private var categories: [ProductCategory]
    @Query(sort: \Product.name) private var products: [Product]
    @State private var search = ""
    @State private var chip = 0
    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var visibleCategories: [ProductCategory] {
        chip == 0 ? categories : categories.filter { $0.categoryID == categories[chip - 1].categoryID }
    }

    private var searchResults: [Product] {
        products.filter { $0.name.localizedStandardContains(search) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Ev • \(session.user?.address ?? "")", systemImage: "mappin.and.ellipse")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.primary)
                        Text("Kategoriler").font(.largeTitle.weight(.bold))
                        Text("Aradığın her şey burada").foregroundStyle(Theme.secondaryText)
                    }
                    .padding(.horizontal)

                    SearchField(placeholder: "Kategori veya ürün ara", text: $search)
                        .padding(.horizontal)

                    if search.isEmpty {
                        ChipBar(titles: ["Tümü"] + categories.map(\.name), selection: $chip)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(visibleCategories) { category in
                                NavigationLink(value: ProductListRoute(categoryID: category.categoryID)) {
                                    CategoryCard(category: category)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    } else if searchResults.isEmpty {
                        ContentUnavailableView.search(text: search)
                    } else {
                        ProductGrid(products: searchResults).padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Theme.background)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) { CartBar() }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ProductListRoute.self) { ProductListView(initialCategoryID: $0.categoryID) }
        }
    }
}

struct CategoryCard: View {
    let category: ProductCategory

    var body: some View {
        VStack(spacing: 10) {
            PhotoView(imageName: category.imageName, fallbackEmoji: category.emoji)
                .frame(height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(spacing: 2) {
                Text(category.name).font(.subheadline.weight(.semibold))
                Text("\(category.products.count) ürün").font(.caption).foregroundStyle(Theme.secondaryText)
            }
            .padding(.bottom, 4)
        }
        .padding(10)
        .card()
    }
}

/// "Tüm Ürünler" — all products with category filter chips.
struct ProductListView: View {
    @Query(sort: \ProductCategory.categoryID) private var categories: [ProductCategory]
    @Query(sort: \Product.name) private var products: [Product]
    let initialCategoryID: Int?
    @State private var chip = 0
    @State private var didSetInitial = false

    private var visible: [Product] {
        guard chip > 0, chip <= categories.count else { return products }
        let id = categories[chip - 1].categoryID
        return products.filter { $0.category?.categoryID == id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ChipBar(titles: ["Tümü"] + categories.map(\.name), selection: $chip)
                ProductGrid(products: visible).padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .background(Theme.background)
        .safeAreaInset(edge: .bottom) { CartBar() }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(chip == 0 ? "Tüm Ürünler" : categories[chip - 1].name).font(.headline)
                    Text("\(visible.count) ürün").font(.caption).foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .onAppear {
            guard !didSetInitial else { return }
            didSetInitial = true
            if let id = initialCategoryID, let index = categories.firstIndex(where: { $0.categoryID == id }) {
                chip = index + 1
            }
        }
    }
}
