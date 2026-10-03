import Foundation
import SwiftData
import CryptoKit
import Observation

enum AuthError: LocalizedError {
    case emptyName, invalidEmail, shortPassword, emailTaken, wrongCredentials

    var errorDescription: String? {
        switch self {
        case .emptyName: return "Lütfen adınızı girin."
        case .invalidEmail: return "Geçerli bir e-posta adresi girin."
        case .shortPassword: return "Şifre en az 6 karakter olmalı."
        case .emailTaken: return "Bu e-posta ile kayıtlı bir hesap zaten var."
        case .wrongCredentials: return "E-posta veya şifre hatalı."
        }
    }
}

/// Keeps track of the logged-in user (remembered across launches).
@Observable
final class Session {
    private static let key = "sessionEmail"
    private(set) var user: AppUser?

    var email: String { user?.email ?? "" }

    func restore(_ context: ModelContext) {
        guard let email = UserDefaults.standard.string(forKey: Self.key) else { return }
        user = Self.fetchUser(email, context)
    }

    func login(email: String, password: String, context: ModelContext) throws {
        let email = Self.normalize(email)
        guard let user = Self.fetchUser(email, context),
              user.passwordHash == Self.hash(password, email: email) else {
            throw AuthError.wrongCredentials
        }
        setUser(user)
    }

    func register(name: String, email: String, phone: String = "", password: String, context: ModelContext) throws {
        let email = Self.normalize(email)
        let name = name.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { throw AuthError.emptyName }
        guard email.contains("@"), email.contains(".") else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.shortPassword }
        guard Self.fetchUser(email, context) == nil else { throw AuthError.emailTaken }

        let user = AppUser(email: email, fullName: name, phone: phone, passwordHash: Self.hash(password, email: email))
        context.insert(user)
        try context.save()
        setUser(user)
    }

    func logout() {
        user = nil
        UserDefaults.standard.removeObject(forKey: Self.key)
    }

    private func setUser(_ user: AppUser) {
        self.user = user
        UserDefaults.standard.set(user.email, forKey: Self.key)
    }

    private static func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespaces).lowercased()
    }

    private static func fetchUser(_ email: String, _ context: ModelContext) -> AppUser? {
        let descriptor = FetchDescriptor<AppUser>(predicate: #Predicate { $0.email == email })
        return try? context.fetch(descriptor).first
    }

    /// Passwords are never stored in plain text.
    static func hash(_ password: String, email: String) -> String {
        let digest = SHA256.hash(data: Data("foodiego:\(email):\(password)".utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
