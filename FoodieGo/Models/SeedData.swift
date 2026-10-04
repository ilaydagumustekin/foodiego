import Foundation
import SwiftData

/// Fills the database with the market catalog on first launch.
enum SeedData {
    private struct CategorySeed {
        let id: Int
        let name: String
        let emoji: String
        let color: String
        let nutrition: String
        let storage: String
    }

    private struct ProductSeed {
        let id: Int
        let name: String
        let emoji: String
        let price: Double
        let unit: String
        let category: Int
        var oldPrice: Double? = nil
        var origin = "Türkiye"
    }

    private static let categories: [CategorySeed] = [
        CategorySeed(id: 1, name: "Meyve & Sebze", emoji: "🍎", color: "4CAF50",
                     nutrition: "100 g: ~40 kcal · Lif açısından zengin · Yağ: 0,2 g",
                     storage: "Serin ve kuru yerde ya da buzdolabının sebzeliğinde saklayınız."),
        CategorySeed(id: 2, name: "Et, Tavuk & Balık", emoji: "🍗", color: "E53935",
                     nutrition: "100 g: ~150–250 kcal (ürüne göre değişir) · Yüksek protein kaynağı",
                     storage: "0–4 °C'de saklayınız. Dondurulmuş ürünü tekrar dondurmayınız."),
        CategorySeed(id: 3, name: "Süt Ürünleri", emoji: "🥛", color: "42A5F5",
                     nutrition: "100 g: ~60 kcal · Kalsiyum kaynağı · Protein: 3,3 g",
                     storage: "+4 °C'de saklayınız. Açıldıktan sonra 3 gün içinde tüketiniz."),
        CategorySeed(id: 4, name: "Temel Gıda", emoji: "🍚", color: "FFA726",
                     nutrition: "100 g: ~350 kcal · Karbonhidrat: 75 g · Protein: 8 g",
                     storage: "Serin, kuru ve güneş görmeyen bir yerde, ağzı kapalı saklayınız."),
        CategorySeed(id: 5, name: "Atıştırmalık", emoji: "🍪", color: "8D6E63",
                     nutrition: "100 g: ~500 kcal · Şeker: 30 g · Yağ: 25 g",
                     storage: "Oda sıcaklığında, kuru ortamda saklayınız."),
        CategorySeed(id: 6, name: "İçecekler", emoji: "🥤", color: "26C6DA",
                     nutrition: "100 ml: ~0–45 kcal (ürüne göre değişir)",
                     storage: "Serin yerde saklayınız. Açıldıktan sonra buzdolabında muhafaza ediniz."),
    ]

    private static let products: [ProductSeed] = [
        // Meyve & Sebze
        ProductSeed(id: 1, name: "Elma", emoji: "🍎", price: 39.90, unit: "1 kg", category: 1, origin: "Amasya"),
        ProductSeed(id: 2, name: "Muz", emoji: "🍌", price: 59.90, unit: "1 kg", category: 1, oldPrice: 74.90, origin: "Anamur"),
        ProductSeed(id: 3, name: "Domates", emoji: "🍅", price: 34.90, unit: "1 kg", category: 1, origin: "Antalya"),
        ProductSeed(id: 4, name: "Salatalık", emoji: "🥒", price: 29.90, unit: "1 kg", category: 1, origin: "Antalya"),
        ProductSeed(id: 5, name: "Mor Soğan", emoji: "🧅", price: 24.90, unit: "1 kg", category: 1, origin: "Polatlı"),
        ProductSeed(id: 6, name: "Patates", emoji: "🥔", price: 24.90, unit: "1 kg", category: 1, origin: "Niğde"),
        ProductSeed(id: 7, name: "Havuç", emoji: "🥕", price: 22.90, unit: "1 kg", category: 1, origin: "Konya"),
        ProductSeed(id: 8, name: "Limon", emoji: "🍋", price: 44.90, unit: "1 kg", category: 1, origin: "Mersin"),
        ProductSeed(id: 9, name: "Sarımsak", emoji: "🧄", price: 24.90, unit: "250 g", category: 1, origin: "Kastamonu"),
        ProductSeed(id: 10, name: "Dolmalık Biber", emoji: "🫑", price: 69.90, unit: "1 kg", category: 1, origin: "Antalya"),
        ProductSeed(id: 11, name: "Maydanoz", emoji: "🌿", price: 9.90, unit: "1 demet", category: 1, origin: "Bursa"),
        ProductSeed(id: 47, name: "İncir", emoji: "🟣", price: 119.90, unit: "1 kg", category: 1, origin: "Aydın"),
        ProductSeed(id: 48, name: "Portakal", emoji: "🍊", price: 34.90, unit: "1 kg", category: 1, origin: "Finike"),
        ProductSeed(id: 49, name: "Ananas", emoji: "🍍", price: 129.90, unit: "1 adet", category: 1, origin: "Kosta Rika"),
        ProductSeed(id: 50, name: "Avokado", emoji: "🥑", price: 39.90, unit: "1 adet", category: 1, origin: "Mersin"),
        ProductSeed(id: 51, name: "Turp", emoji: "🌱", price: 14.90, unit: "1 demet", category: 1, origin: "Bursa"),
        ProductSeed(id: 52, name: "Pancar", emoji: "🟣", price: 29.90, unit: "1 kg", category: 1, origin: "Konya"),
        // Et, Tavuk & Balık
        ProductSeed(id: 12, name: "Tavuk Göğüs", emoji: "🍗", price: 189.90, unit: "1 kg", category: 2, oldPrice: 219.90),
        ProductSeed(id: 13, name: "Tavuk But", emoji: "🍗", price: 149.90, unit: "1 kg", category: 2),
        ProductSeed(id: 14, name: "Dana Kıyma", emoji: "🥩", price: 459.90, unit: "1 kg", category: 2),
        ProductSeed(id: 15, name: "Kuzu Pirzola", emoji: "🍖", price: 649.90, unit: "1 kg", category: 2),
        ProductSeed(id: 16, name: "Dana Pastırma", emoji: "🥓", price: 179.90, unit: "125 g", category: 2, origin: "Kayseri"),
        ProductSeed(id: 53, name: "Dana Burger Köftesi", emoji: "🍔", price: 249.90, unit: "4'lü", category: 2),
        ProductSeed(id: 54, name: "Dana Kuşbaşı", emoji: "🥩", price: 499.90, unit: "1 kg", category: 2),
        ProductSeed(id: 55, name: "Karides", emoji: "🦐", price: 389.90, unit: "500 g", category: 2, origin: "Muğla"),
        ProductSeed(id: 56, name: "Somon Fileto", emoji: "🐟", price: 429.90, unit: "500 g", category: 2, origin: "Norveç"),
        // Süt Ürünleri
        ProductSeed(id: 17, name: "Süt", emoji: "🥛", price: 34.90, unit: "1 L", category: 3),
        ProductSeed(id: 18, name: "Yoğurt", emoji: "🥣", price: 64.90, unit: "1 kg", category: 3),
        ProductSeed(id: 19, name: "Tereyağı", emoji: "🧈", price: 49.90, unit: "125 g", category: 3, oldPrice: 59.90),
        ProductSeed(id: 20, name: "Beyaz Peynir", emoji: "🧀", price: 99.90, unit: "500 g", category: 3, origin: "Ezine"),
        ProductSeed(id: 21, name: "Kaşar Peyniri", emoji: "🧀", price: 219.90, unit: "700 g", category: 3, origin: "Kars"),
        ProductSeed(id: 22, name: "Yumurta", emoji: "🥚", price: 169.90, unit: "30'lu", category: 3),
        ProductSeed(id: 57, name: "Krema", emoji: "🥛", price: 44.90, unit: "200 ml", category: 3),
        ProductSeed(id: 58, name: "Labne", emoji: "🧀", price: 89.90, unit: "400 g", category: 3),
        // Temel Gıda
        ProductSeed(id: 23, name: "Baldo Pirinç", emoji: "🍚", price: 89.90, unit: "1 kg", category: 4, origin: "Gönen"),
        ProductSeed(id: 24, name: "Ekşi Mayalı Ekmek", emoji: "🍞", price: 59.90, unit: "1 adet", category: 4),
        ProductSeed(id: 25, name: "Tagliatelle Makarna", emoji: "🍝", price: 49.90, unit: "500 g", category: 4, oldPrice: 59.90, origin: "İtalya"),
        ProductSeed(id: 26, name: "Tam Buğday Unu", emoji: "🌾", price: 44.90, unit: "1 kg", category: 4),
        ProductSeed(id: 27, name: "Ayçiçek Yağı", emoji: "🌻", price: 129.90, unit: "1 L", category: 4),
        ProductSeed(id: 28, name: "Zeytinyağı", emoji: "🫒", price: 299.90, unit: "1 L", category: 4, origin: "Ayvalık"),
        ProductSeed(id: 29, name: "Tuz", emoji: "🧂", price: 14.90, unit: "750 g", category: 4),
        ProductSeed(id: 30, name: "Süzme Bal", emoji: "🍯", price: 189.90, unit: "350 g", category: 4, origin: "Muğla"),
        ProductSeed(id: 31, name: "Domates Salçası", emoji: "🥫", price: 69.90, unit: "830 g", category: 4),
        ProductSeed(id: 32, name: "Kırmızı Mercimek", emoji: "🫘", price: 54.90, unit: "1 kg", category: 4, origin: "Mardin"),
        ProductSeed(id: 33, name: "Mısır", emoji: "🌽", price: 19.90, unit: "1 adet", category: 1, origin: "Adana"),
        ProductSeed(id: 34, name: "Pul Biber", emoji: "🌶️", price: 39.90, unit: "100 g", category: 4, origin: "Kahramanmaraş"),
        ProductSeed(id: 59, name: "Yeşil Mercimek", emoji: "🫘", price: 44.90, unit: "500 g", category: 4, origin: "Kanada"),
        // Atıştırmalık
        ProductSeed(id: 35, name: "Sütlü Çikolata", emoji: "🍫", price: 34.90, unit: "80 g", category: 5, oldPrice: 44.90),
        ProductSeed(id: 36, name: "Patlamış Mısır", emoji: "🍿", price: 29.90, unit: "100 g", category: 5),
        ProductSeed(id: 37, name: "Sütlü Çikolatalı Bisküvi", emoji: "🍪", price: 54.90, unit: "200 g", category: 5),
        ProductSeed(id: 38, name: "Karışık Kuruyemiş", emoji: "🥜", price: 89.90, unit: "180 g", category: 5),
        ProductSeed(id: 39, name: "Karabuğday Patlağı", emoji: "🍘", price: 54.90, unit: "100 g", category: 5),
        // İçecekler
        ProductSeed(id: 40, name: "Su", emoji: "💧", price: 5.90, unit: "0,5 L", category: 6),
        ProductSeed(id: 41, name: "Maden Suyu", emoji: "🫧", price: 7.90, unit: "200 ml", category: 6),
        ProductSeed(id: 42, name: "Portakal Suyu", emoji: "🧃", price: 49.90, unit: "1 L", category: 6, oldPrice: 59.90),
        ProductSeed(id: 43, name: "Kola", emoji: "🥤", price: 39.90, unit: "1 L", category: 6),
        ProductSeed(id: 44, name: "Siyah Çay", emoji: "🍵", price: 64.90, unit: "500 g", category: 6, origin: "Rize"),
        ProductSeed(id: 45, name: "Türk Kahvesi", emoji: "☕", price: 89.90, unit: "100 g", category: 6),
        ProductSeed(id: 46, name: "Ayran", emoji: "🥛", price: 14.90, unit: "300 ml", category: 6),
    ]

    /// Inserts or updates every category and product by id, so catalog changes reach existing installs
    /// without touching users, carts or orders.
    static func syncCatalog(_ context: ModelContext) {
        let tr = Locale(identifier: "tr_TR")
        let existingCategories = Dictionary((try? context.fetch(FetchDescriptor<ProductCategory>()))?.map { ($0.categoryID, $0) } ?? [],
                                            uniquingKeysWith: { first, _ in first })
        let existingProducts = Dictionary((try? context.fetch(FetchDescriptor<Product>()))?.map { ($0.productID, $0) } ?? [],
                                          uniquingKeysWith: { first, _ in first })

        var categoryByID: [Int: (ProductCategory, CategorySeed)] = [:]
        for seed in categories {
            let category = existingCategories[seed.id] ?? {
                let new = ProductCategory(categoryID: seed.id, name: seed.name, emoji: seed.emoji, colorHex: seed.color)
                context.insert(new)
                return new
            }()
            category.name = seed.name
            category.emoji = seed.emoji
            category.colorHex = seed.color
            categoryByID[seed.id] = (category, seed)
        }

        for seed in products {
            guard let (category, categorySeed) = categoryByID[seed.category] else { continue }
            let lowered = seed.name.lowercased(with: tr)
            let product = existingProducts[seed.id] ?? {
                let new = Product(productID: seed.id, name: seed.name, emoji: seed.emoji, price: seed.price, unit: seed.unit,
                                  details: "", ingredients: "", nutrition: "", origin: "", storage: "")
                context.insert(new)
                return new
            }()
            product.name = seed.name
            product.emoji = seed.emoji
            product.price = seed.price
            product.oldPrice = seed.oldPrice
            product.unit = seed.unit
            product.details = "Özenle seçilmiş, taze ve kaliteli \(lowered). FoodieGo güvencesiyle kapınıza kadar gelir."
            product.ingredients = "%100 \(lowered)"
            product.nutrition = categorySeed.nutrition
            product.origin = seed.origin
            product.storage = categorySeed.storage
            product.isWeeklyDeal = seed.oldPrice != nil
            product.category = category
        }

        if ((try? context.fetchCount(FetchDescriptor<Campaign>())) ?? 0) == 0 {
            seedCampaigns(context)
        }
        try? context.save()
    }

    private static func seedCampaigns(_ context: ModelContext) {
        let day: TimeInterval = 86_400
        let campaigns = [
            Campaign(title: "Haftanın Meyveleri", details: "Tüm meyvelerde sepette %20 indirim!", emoji: "🍓", colorHex: "4CAF50", discountPercent: 20, endDate: .now + 7 * day),
            Campaign(title: "Kahvaltı Şöleni", details: "Peynir, yumurta ve tereyağında %15 indirim.", emoji: "🍳", colorHex: "FFA726", discountPercent: 15, endDate: .now + 10 * day),
            Campaign(title: "İlk Siparişe Özel", details: "İlk siparişinde 300 TL üzeri %10 indirim.", emoji: "🎉", colorHex: "2E7D32", discountPercent: 10, endDate: .now + 30 * day),
            Campaign(title: "Atıştırmalık Festivali", details: "Çikolata, cips ve kuruyemişte %25 indirim.", emoji: "🍿", colorHex: "8D6E63", discountPercent: 25, endDate: .now + 5 * day),
        ]
        campaigns.forEach(context.insert)
    }
}
