import SwiftUI

enum Currency {
    static let key = "currencyCode"
    static var defaultCode: String { Locale.current.currency?.identifier ?? "USD" }

    static let common = ["USD", "CAD", "EUR", "GBP", "AUD", "NZD", "JPY", "KRW", "CNY", "INR", "PHP", "SGD", "MXN", "BRL", "CHF", "ZAR"]

    static func format(_ amount: Double, code: String) -> String {
        amount.formatted(.currency(code: code))
    }

    static func name(for code: String) -> String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }
}

/// Rounded, tinted icon for a service type.
struct TypeIcon: View {
    let type: ServiceType
    var size: CGFloat = 40
    var muted = false

    var body: some View {
        Image(systemName: type.symbol)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(muted ? Color.secondary : Color.white)
            .frame(width: size, height: size)
            .background(
                muted ? AnyShapeStyle(Color(.tertiarySystemFill)) : AnyShapeStyle(type.tint.gradient),
                in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            )
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.title3.bold())
            .padding(.horizontal, 4)
    }
}
