import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(Session.self) private var session
    @State private var isReady = false

    var body: some View {
        Group {
            if !isReady {
                ProgressView()
            } else if session.user != nil {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .tint(Theme.primary)
        .preferredColorScheme(.light)
        .task {
            SeedData.syncCatalog(context)
            session.restore(context)
            isReady = true
        }
    }
}

enum AppTab: Hashable {
    case home, categories, cart, profile
}

/// App-wide navigation state: selected tab, the AI assistant sheet and the product detail sheet.
@Observable
final class AppRouter {
    var tab: AppTab = .home
    var showAssistant = false
    var selectedProduct: Product?
    var toast: String?

    func showToast(_ text: String) {
        withAnimation(.snappy) { toast = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            withAnimation(.snappy) { if self?.toast == text { self?.toast = nil } }
        }
    }
}

struct MainTabView: View {
    @Environment(Session.self) private var session
    @Query private var cartItems: [CartItem]
    @State private var router = AppRouter()

    private var cartCount: Int {
        cartItems.filter { $0.userEmail == session.email && $0.product != nil }.reduce(0) { $0 + $1.quantity }
    }

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            HomeView()
                .tabItem { Label("Ana Sayfa", systemImage: "house") }
                .tag(AppTab.home)
            CategoriesView()
                .tabItem { Label("Kategoriler", systemImage: "square.grid.2x2") }
                .tag(AppTab.categories)
            CartView()
                .tabItem { Label("Sepet", systemImage: "cart") }
                .badge(cartCount)
                .tag(AppTab.cart)
            ProfileView()
                .tabItem { Label("Profil", systemImage: "person") }
                .tag(AppTab.profile)
        }
        .overlay(alignment: .bottomTrailing) {
            // Only on browsing tabs, so it never covers cart totals or profile rows.
            if router.tab == .home || router.tab == .categories { assistantButton }
        }
        .overlay(alignment: .top) {
            if let toast = router.toast { Toast(text: toast).padding(.top, 8) }
        }
        .sheet(isPresented: $router.showAssistant) {
            AssistantSheet()
                .environment(router)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $router.selectedProduct) { product in
            ProductDetailSheet(product: product)
                .environment(router)
                .presentationDragIndicator(.visible)
        }
        .environment(router)
    }

    /// Floating AI chef button, like a chat bubble launcher.
    private var assistantButton: some View {
        Button { router.showAssistant = true } label: {
            Image(systemName: "sparkles")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(Circle().fill(LinearGradient(colors: [Theme.primary, Theme.green], startPoint: .top, endPoint: .bottom)))
                .overlay(Circle().stroke(.white, lineWidth: 3))
                .shadow(color: Theme.green.opacity(0.4), radius: 10, y: 5)
        }
        .accessibilityLabel("AI Tarif Asistanı")
        .padding(.trailing, 18)
        .padding(.bottom, 96)
    }
}
