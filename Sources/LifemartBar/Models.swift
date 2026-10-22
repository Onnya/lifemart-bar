import Foundation

/// Stage of an order as the menu bar shows it.
enum OrderStage: Equatable {
    case accepted
    case assembled
    case onTheWay
    case readyForPickup
    case delivered
    case other(String)

    /// Status ids seen in `status_list`: 10 → 80 → 20 → 30.
    /// For pickup orders 30 means the order is ready to collect.
    init(statusID: Int, shortTitle: String, isPickup: Bool) {
        switch statusID {
        case 10: self = .accepted
        case 80: self = .assembled
        case 20: self = .onTheWay
        case 30: self = isPickup ? .readyForPickup : .delivered
        default: self = .other(shortTitle)
        }
    }

    var symbol: String {
        switch self {
        case .accepted, .other: "clock"
        case .assembled: "shippingbox"
        case .onTheWay: "scooter"
        case .readyForPickup: "bag"
        case .delivered: "checkmark.circle"
        }
    }

    var title: String {
        switch self {
        case .accepted: "Принят"
        case .assembled: "Собран"
        case .onTheWay: "Везут"
        case .readyForPickup: "Готов к выдаче"
        case .delivered: "Доставлен"
        case .other(let title): title
        }
    }

    var isFinal: Bool { self == .delivered || self == .readyForPickup }
}

enum DeliveryKind: Equatable {
    case delivery(address: String)
    case pickup
}

struct OrderItem: Identifiable, Equatable {
    let id: Int
    let name: String
    let quantity: Int
    let price: Int
}

struct Order: Equatable {
    let id: Int
    let code: String
    var stage: OrderStage
    /// Human text from the API, e.g. "Будем у Вас через ~ 20 мин".
    var statusText: String
    let createdAt: Date
    let expectedAt: Date?
    let storeName: String
    let storeAddress: String
    let kind: DeliveryKind
    let items: [OrderItem]
    let total: Int
    let paymentTitle: String
}
