import SwiftUI
import SwiftData

/// One entry in the AI chef conversation.
private struct ChatEntry: Identifiable {
    enum Kind {
        case user(String)
        case assistant(String)
        case recipe(Recipe)
        case error(String)
    }

    let id = UUID()
    let kind: Kind
}

/// "FoodieGo Yapay Zeka Asistanı" — chat-style recipe assistant opened from the floating button.
struct AssistantSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("geminiAPIKey") private var apiKey = ""
    @Query(sort: \Product.productID) private var products: [Product]

    @State private var entries: [ChatEntry] = [
        ChatEntry(kind: .assistant("Merhaba! 👋 Yapmak istediğin yemeği yaz; tarifini hazırlayıp gereken malzemeleri marketten bulayım."))
    ]
    @State private var input = ""
    @State private var isLoading = false
    @FocusState private var focused: Bool

    private let suggestions = ["Tavuklu pilav", "Menemen", "Mercimek çorbası", "Domates soslu makarna"]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if apiKey.isEmpty { apiKeyCard }
                        ForEach(entries) { entry in
                            bubble(for: entry).id(entry.id)
                        }
                        if isLoading { typingBubble.id("typing") }
                        if entries.count == 1 && !isLoading { suggestionChips }
                    }
                    .padding()
                }
                .onChange(of: entries.count) {
                    withAnimation { proxy.scrollTo(entries.last?.id, anchor: .top) }
                }
                .onChange(of: isLoading) {
                    if isLoading { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
                }
            }
            .background(Theme.background)
            .scrollDismissesKeyboard(.interactively)

            inputBar
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            AssistantAvatar(size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("FoodieGo Yapay Zeka Asistanı").font(.headline)
                Text("Tarifini yaz, malzemeleri sepete ekle").font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Theme.field))
            }
        }
        .padding()
        .padding(.top, 8)
    }

    @ViewBuilder
    private func bubble(for entry: ChatEntry) -> some View {
        switch entry.kind {
        case .user(let text):
            HStack {
                Spacer(minLength: 50)
                Text(text)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 4, topTrailingRadius: 18).fill(Theme.primary))
            }
        case .assistant(let text):
            assistantBubble { Text(text) }
        case .error(let text):
            assistantBubble {
                Label(text, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Theme.red)
            }
        case .recipe(let recipe):
            RecipeMessage(recipe: recipe, products: products)
        }
    }

    private func assistantBubble<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            content()
                .font(.subheadline)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 4, bottomTrailingRadius: 18, topTrailingRadius: 18).fill(Theme.primary.opacity(0.1)))
            Spacer(minLength: 40)
        }
    }

    private var typingBubble: some View {
        assistantBubble {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Tarif hazırlanıyor…").foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private var suggestionChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Örnek istekler").font(.caption).foregroundStyle(Theme.secondaryText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(suggestion) { send("\(suggestion) yapmak istiyorum") }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.primary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Capsule().stroke(Theme.primary.opacity(0.4)))
                    }
                }
            }
        }
    }

    private var apiKeyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Gemini API anahtarı gerekli", systemImage: "key.fill").font(.subheadline.weight(.semibold))
            Text("aistudio.google.com adresinden ücretsiz bir anahtar alıp yapıştır. Profil → Yapay Zekâ Ayarları'ndan değiştirebilirsin.")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
            SecureField("API anahtarı", text: $apiKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent.opacity(0.18)))
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Örn: Tavuklu pilav yapmak istiyorum", text: $input, axis: .vertical)
                .lineLimit(1...3)
                .focused($focused)
                .submitLabel(.send)
                .onSubmit { send(input) }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.field))
            Button("Gönder") { send(input) }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.primary))
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                .opacity(input.trimmingCharacters(in: .whitespaces).isEmpty || isLoading ? 0.5 : 1)
        }
        .padding()
        .background(.white)
    }

    private func send(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        input = ""
        focused = false
        entries.append(ChatEntry(kind: .user(text)))
        isLoading = true

        // Only id, name, unit and price go to the model — just enough to match ingredients.
        let catalog = products.map { CatalogEntry(id: $0.productID, name: $0.name, price: $0.price, unit: $0.unit) }
        let service = GeminiService(apiKey: apiKey)

        Task {
            do {
                let recipe = try await service.generateRecipe(for: text, catalog: catalog)
                entries.append(ChatEntry(kind: .recipe(recipe)))
                Haptics.success()
            } catch {
                entries.append(ChatEntry(kind: .error(error.localizedDescription)))
            }
            isLoading = false
        }
    }
}

struct AssistantAvatar: View {
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(LinearGradient(colors: [Theme.primary, Theme.green], startPoint: .top, endPoint: .bottom)))
    }
}

/// The assistant's answer: recipe text plus the matched products with "Ekle" buttons.
private struct RecipeMessage: View {
    @Environment(\.modelContext) private var context
    @Environment(Session.self) private var session
    @Environment(AppRouter.self) private var router
    let recipe: Recipe
    let products: [Product]
    @State private var added: Set<Int> = []

    private var productByID: [Int: Product] {
        Dictionary(products.map { ($0.productID, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private var matched: [(RecipeIngredient, Product)] {
        var seen = Set<Int>()
        return recipe.ingredients.compactMap { ingredient in
            guard let id = ingredient.productId, let product = productByID[id], seen.insert(id).inserted else { return nil }
            return (ingredient, product)
        }
    }

    private var missing: [RecipeIngredient] {
        recipe.ingredients.filter { $0.productId == nil || productByID[$0.productId!] == nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.title).font(.headline)
                Text(recipe.summary).font(.subheadline).foregroundStyle(Theme.secondaryText)
                HStack(spacing: 14) {
                    Label("\(recipe.servings) kişilik", systemImage: "person.2")
                    Label("\(recipe.prepMinutes) dk", systemImage: "clock")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.primary)

                Divider().padding(.vertical, 2)

                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.primary)
                        Text(step).font(.subheadline)
                    }
                }
            }
            .padding(14)
            .background(UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 4, bottomTrailingRadius: 18, topTrailingRadius: 18).fill(Theme.primary.opacity(0.1)))

            if !matched.isEmpty {
                VStack(spacing: 10) {
                    ForEach(matched, id: \.1.productID) { ingredient, product in
                        HStack(spacing: 12) {
                            ProductThumb(imageName: product.imageName, emoji: product.emoji, size: 50)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name).font(.subheadline.weight(.semibold))
                                Text("\(ingredient.amount) · \(product.price.tl)").font(.caption).foregroundStyle(Theme.primary)
                            }
                            Spacer()
                            Button(added.contains(product.productID) ? "Eklendi" : "Ekle") { add(product) }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16).padding(.vertical, 9)
                                .background(RoundedRectangle(cornerRadius: 10).fill(added.contains(product.productID) ? Theme.green : Theme.primary))
                        }
                        .padding(10)
                        .card(radius: 14)
                    }

                    Button {
                        matched.map(\.1).filter { !added.contains($0.productID) }.forEach(add)
                    } label: {
                        Label("Tümünü Sepete Ekle · \(matched.reduce(0) { $0 + $1.1.price }.tl)", systemImage: "cart.badge.plus")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: added.count == matched.count ? Theme.green : Theme.primary))
                    .disabled(added.count == matched.count)
                }
            }

            if !missing.isEmpty {
                Text("Markette bulunamayanlar: " + missing.map { "\($0.name) (\($0.amount))" }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func add(_ product: Product) {
        CartActions.add(product, for: session.email, in: context)
        added.insert(product.productID)
        Haptics.tap()
        router.showToast("\(product.name) sepete eklendi")
    }
}
