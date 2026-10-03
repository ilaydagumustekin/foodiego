import SwiftUI
import SwiftData

struct AuthView: View {
    @Environment(\.modelContext) private var context
    @Environment(Session.self) private var session

    @State private var isRegister = false
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var passwordAgain = ""
    @State private var showPassword = false
    @State private var error: String?

    var body: some View {
        ZStack(alignment: .top) {
            // Green header behind the logo, white below the form card.
            VStack(spacing: 0) {
                Theme.primary.frame(height: 320)
                Color.white
            }
            .ignoresSafeArea()

            VStack(spacing: 6) {
                Text("FoodieGo")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                Text(isRegister ? "Hesap Oluşturun" : "Tekrar Hoş Geldiniz")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Lezzet ve ihtiyaçlar kapınıza gelsin")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.top, 36)

            ScrollView {
                VStack(spacing: 14) {
                    if !isRegister {
                        VStack(spacing: 6) {
                            Text("Giriş Yap").font(.title2.weight(.semibold))
                            Text("Siparişlerine devam etmek için giriş yap")
                                .font(.subheadline)
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .padding(.bottom, 8)
                    }

                    if isRegister {
                        field("Ad Soyad", text: $name, icon: "person")
                            .textContentType(.name)
                    }
                    field("E-Posta Adresi", text: $email, icon: "envelope")
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    if isRegister {
                        field("Telefon Numarası", text: $phone, icon: "phone")
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                    secureField("Şifre", text: $password)
                    if isRegister {
                        secureField("Şifre Tekrarı", text: $passwordAgain)
                    }

                    if let error {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(Theme.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(action: submit) {
                        HStack(spacing: 8) {
                            Text(isRegister ? "Kayıt Ol" : "Giriş Yap")
                            Image(systemName: "arrow.right")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 6)

                    HStack(spacing: 4) {
                        Text(isRegister ? "Zaten hesabınız var mı?" : "Hesabınız yok mu?")
                            .foregroundStyle(Theme.secondaryText)
                        Button(isRegister ? "Giriş Yap" : "Kayıt Ol") {
                            withAnimation(.snappy) { isRegister.toggle(); error = nil }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.primary)
                    }
                    .font(.subheadline)
                    .padding(.top, 8)
                }
                .padding(24)
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 600, alignment: .top)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                        .fill(.white)
                )
                .padding(.top, 170)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func field(_ title: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.secondaryText).frame(width: 20)
            TextField(title, text: text).autocorrectionDisabled()
        }
        .padding(.horizontal, 16).padding(.vertical, 15)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.field))
    }

    private func secureField(_ title: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock").foregroundStyle(Theme.secondaryText).frame(width: 20)
            Group {
                if showPassword { TextField(title, text: text) } else { SecureField(title, text: text) }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            Button { showPassword.toggle() } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye").foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 15)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.field))
    }

    private func submit() {
        do {
            if isRegister {
                guard password == passwordAgain else {
                    error = "Şifreler birbiriyle eşleşmiyor."
                    return
                }
                try session.register(name: name, email: email, phone: phone, password: password, context: context)
            } else {
                try session.login(email: email, password: password, context: context)
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
