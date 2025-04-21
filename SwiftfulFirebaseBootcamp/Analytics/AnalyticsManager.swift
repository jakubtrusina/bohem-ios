import SwiftUI
import FirebaseAnalytics
import FirebaseAnalyticsSwift






enum AnalyticsEvent: String {
    case screenView = "screen_view"
    case buttonClick = "button_click"
    case viewedProduct = "view_item"
    case addToCart = "add_to_cart"
    case addToFavorites = "add_to_favorites"
    case categorySelected = "category_selected"
    case startCheckout = "begin_checkout"
    case purchase = "purchase"
    case debug = "debug_event"
}

enum UserProperty: RawRepresentable {
    case isPremium
    case gender
    case age
    case country
    case custom(String)

    var rawValue: String {
        switch self {
        case .isPremium: return "user_is_premium"
        case .gender: return "user_gender"
        case .age: return "user_age"
        case .country: return "user_country"
        case .custom(let name): return name
        }
    }

    init?(rawValue: String) {
        return nil // Not needed for our use case
    }
}

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() { }

    func logEvent(_ event: AnalyticsEvent, params: [String: Any]? = nil) {
        Analytics.logEvent(event.rawValue, parameters: params)
        print("📊 Logged event: \(event.rawValue) | \(params ?? [:])")
    }

    func logCustomEvent(name: String, params: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: params)
        print("📊 Logged custom event: \(name) | \(params ?? [:])")
    }

    func setUserId(_ userId: String) {
        Analytics.setUserID(userId)
    }

    func setUserProperty(_ value: String?, for property: UserProperty) {
        Analytics.setUserProperty(value, forName: property.rawValue)
    }

    func setUserProperties(from user: DBUser) {
        print("🔥 Setting user properties for:", user.userId)
        
        setUserId(user.userId)
        
        if let isPremium = user.isPremium {
            print("  → isPremium:", isPremium)
            setUserProperty(isPremium.description, for: .isPremium)
        }
        if let gender = user.gender {
            print("  → gender:", gender)
            setUserProperty(gender, for: .gender)
        }
        if let age = user.age {
            print("  → age:", age)
            setUserProperty(String(age), for: .age)
        }
        if let bodyShape = user.bodyShape {
            print("  → bodyShape:", bodyShape)
            setUserProperty(bodyShape, for: .custom("body_shape"))
        }
        // etc. for each property
    }


    func logProductView(product: Product) {
        logEvent(.viewedProduct, params: [
            "item_id": product.id,
            "item_name": product.title ?? "",
            "brand": product.brand ?? "",
            "price": product.price ?? 0,
            "category": product.category ?? ""
        ])
    }

    func logAddToCart(product: Product, quantity: Int) {
        let item: [String: Any] = [
            "item_id": product.id,
            "item_name": product.title ?? "",
            "item_brand": product.brand ?? "",
            "item_category": product.category ?? "",
            "price": product.price ?? 0,
            "quantity": quantity,
            "currency": "CZK"
        ]

        logEvent(.addToCart, params: [
            "items": [item],
            "currency": "CZK",
            "value": Double(product.price ?? 0) * Double(quantity)
        ])
    }


    func logAddToFavorites(product: Product) {
        logEvent(.addToFavorites, params: [
            "item_id": product.id,
            "name": product.title,
            "category": product.category,
            "brand": product.brand ?? "",
            "price": product.price


        ])
    }


    func logCategorySelected(main: String, sub: String?) {
        var params: [String: Any] = ["main_category": main]
        if let sub = sub { params["subcategory"] = sub }
        logEvent(.categorySelected, params: params)
    }

    func logStartCheckout(cartItems: [Product], total: Double, currency: String = "USD") {
        let items: [[String: Any]] = cartItems.map {
            return [
                "item_id": $0.id,
                "name": $0.title,
                "price": $0.price,
                "category": $0.category
            ]
        }

        logEvent(.startCheckout, params: [
            "value": total,
            "currency": currency,
            "item_count": cartItems.count,
            "items": items
        ])
    }

    func logPurchase(transactionId: String, products: [Product], total: Double, currency: String = "USD") {
        let items: [[String: Any]] = products.map {
            return [
                "item_id": $0.id,
                "name": $0.title,
                "price": $0.price,
                "category": $0.category
            ]
        }

        logEvent(.purchase, params: [
            "transaction_id": transactionId,
            "value": total,
            "currency": currency,
            "items": items
        ])
    }
}
