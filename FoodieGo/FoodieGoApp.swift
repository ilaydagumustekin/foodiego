import SwiftUI
import SwiftData

@main
struct FoodieGoApp: App {
    @State private var session = Session()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
        .modelContainer(for: [
            AppUser.self,
            ProductCategory.self,
            Product.self,
            CartItem.self,
            FoodOrder.self,
            OrderItem.self,
            Campaign.self,
        ])
    }
}
