import Foundation

struct RecipeIngredient: Codable, Hashable {
    let name: String
    let amount: String
    /// The catalog product this ingredient maps to, or nil if the market doesn't sell it.
    let productId: Int?
}

struct Recipe: Codable {
    let title: String
    let summary: String
    let servings: Int
    let prepMinutes: Int
    let ingredients: [RecipeIngredient]
    let steps: [String]
}

/// The slice of a product the model needs to see (id, name, price).
struct CatalogEntry {
    let id: Int
    let name: String
    let price: Double
    let unit: String
}

enum GeminiError: LocalizedError {
    case missingKey
    case http(Int, String)
    case empty
    case decoding

    var errorDescription: String? {
        switch self {
        case .missingKey: return "Gemini API anahtarı girilmemiş. Profil sekmesinden ekleyebilirsin."
        case .http(let code, let message): return "Gemini isteği başarısız oldu (\(code)). \(message)"
        case .empty: return "Gemini boş bir yanıt döndürdü. Lütfen tekrar dene."
        case .decoding: return "Tarif okunamadı. Lütfen isteğini farklı bir şekilde yaz."
        }
    }
}

/// Asks Google Gemini for a recipe and has it match ingredients to catalog product ids.
struct GeminiService {
    /// Change this if Google retires the model.
    static let model = "gemini-2.5-flash"

    let apiKey: String

    func generateRecipe(for request: String, catalog: [CatalogEntry]) async throws -> Recipe {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else { throw GeminiError.missingKey }

        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(Self.model):generateContent")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let body: [String: Any] = [
            "systemInstruction": ["parts": [["text": Self.systemPrompt]]],
            "contents": [["role": "user", "parts": [["text": Self.userPrompt(request, catalog: catalog)]]]],
            "generationConfig": [
                "temperature": 0.7,
                "responseMimeType": "application/json",
                "responseSchema": Self.responseSchema,
            ],
        ]
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let message = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.error.message ?? ""
            throw GeminiError.http(status, message)
        }

        let envelope = try JSONDecoder().decode(ResponseEnvelope.self, from: data)
        let text = envelope.candidates?.first?.content?.parts?.compactMap(\.text).joined() ?? ""
        guard !text.isEmpty else { throw GeminiError.empty }

        guard let recipe = try? JSONDecoder().decode(Recipe.self, from: Data(text.utf8)) else {
            throw GeminiError.decoding
        }
        return Self.validated(recipe, catalog: catalog)
    }

    /// Drops product ids the model invented — only real catalog products can be added to the cart.
    private static func validated(_ recipe: Recipe, catalog: [CatalogEntry]) -> Recipe {
        let validIDs = Set(catalog.map(\.id))
        let ingredients = recipe.ingredients.map { ingredient in
            guard let id = ingredient.productId, validIDs.contains(id) else {
                return RecipeIngredient(name: ingredient.name, amount: ingredient.amount, productId: nil)
            }
            return ingredient
        }
        return Recipe(title: recipe.title, summary: recipe.summary, servings: recipe.servings,
                      prepMinutes: recipe.prepMinutes, ingredients: ingredients, steps: recipe.steps)
    }

    // MARK: Prompt

    private static let systemPrompt = """
    Sen FoodieGo market uygulamasının yapay zekâ tarif asistanısın. Kullanıcının istediği yemek için \
    Türkçe, uygulanabilir bir tarif hazırlarsın.

    Kurallar:
    - Malzemeleri SADECE verilen ürün kataloğundaki ürünlerle eşleştir ve eşleşen ürünün id değerini productId alanına yaz.
    - Katalogda karşılığı olmayan malzemeler için productId alanını null bırak; asla katalogda olmayan bir id uydurma.
    - Bir malzeme için en uygun tek ürünü seç (ör. "tavuk" için "Tavuk Göğüs" veya "Tavuk But").
    - Su gibi musluktan alınabilecek malzemeleri ürünle eşleştirme.
    - Adımlar kısa, net ve sıralı olsun. Miktarları gram, adet, su bardağı gibi birimlerle yaz.
    - İstek bir yemek veya içecekle ilgili değilse, kibarca yemek önerisi içeren kısa bir tarif döndür.
    """

    private static func userPrompt(_ request: String, catalog: [CatalogEntry]) -> String {
        let lines = catalog.map { entry in
            "\(entry.id) | \(entry.name) | \(entry.unit) | \(String(format: "%.2f", entry.price)) TL"
        }
        return """
        Kullanıcının isteği: \(request)

        Ürün kataloğu (id | ad | birim | fiyat):
        \(lines.joined(separator: "\n"))
        """
    }

    private static let responseSchema: [String: Any] = [
        "type": "OBJECT",
        "properties": [
            "title": ["type": "STRING"],
            "summary": ["type": "STRING"],
            "servings": ["type": "INTEGER"],
            "prepMinutes": ["type": "INTEGER"],
            "ingredients": [
                "type": "ARRAY",
                "items": [
                    "type": "OBJECT",
                    "properties": [
                        "name": ["type": "STRING"],
                        "amount": ["type": "STRING"],
                        "productId": ["type": "INTEGER", "nullable": true],
                    ],
                    "required": ["name", "amount"],
                ],
            ],
            "steps": ["type": "ARRAY", "items": ["type": "STRING"]],
        ],
        "required": ["title", "summary", "servings", "prepMinutes", "ingredients", "steps"],
    ]

    // MARK: Response envelopes

    private struct ResponseEnvelope: Decodable {
        struct Candidate: Decodable { let content: Content? }
        struct Content: Decodable { let parts: [Part]? }
        struct Part: Decodable { let text: String? }
        let candidates: [Candidate]?
    }

    private struct ErrorEnvelope: Decodable {
        struct Body: Decodable { let message: String }
        let error: Body
    }
}
