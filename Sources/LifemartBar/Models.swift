import Foundation

/// Stage of an order as the menu bar shows it. Mapping from the API's
/// `status.id` is unknown until a live order is captured.
enum OrderStage: CaseIterable {
    case accepted
    case assembling
    case readyForPickup
    case onTheWay
    case delivered

    var symbol: String {
        switch self {
        case .accepted: "clock"
        case .assembling: "shippingbox"
        case .readyForPickup: "bag"
        case .onTheWay: "scooter"
        case .delivered: "checkmark.circle"
        }
    }

    var title: String {
        switch self {
        case .accepted: "Принят"
        case .assembling: "Собирают"
        case .readyForPickup: "Готов к выдаче"
        case .onTheWay: "Везут"
        case .delivered: "Доставлен"
        }
    }
}

enum DeliveryKind {
    case delivery(address: String)
    case pickup
}

struct OrderItem: Identifiable {
    let id = UUID()
    let name: String
    let quantity: Int
    let price: Int
}

struct Order {
    let code: String
    let stage: OrderStage
    let createdAt: Date
    let statusChangedAt: Date
    let storeAddress: String
    let kind: DeliveryKind
    let items: [OrderItem]
    let total: Int
    let paymentTitle: String
}
