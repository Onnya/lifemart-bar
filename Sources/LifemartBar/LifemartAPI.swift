import Foundation

/// Client for the same API lifemart.ru uses. Unofficial: field names come
/// from the site's own requests and may change without notice.
struct LifemartAPI {
    enum Failure: Error {
        case unauthorized
        case badResponse(Int)
    }

    let token: String
    let apiKey: String

    private static let base = URL(string: "https://api.lifemart.ru/api/")!

    private static var deviceID: String {
        let key = "deviceID"
        if let id = UserDefaults.standard.string(forKey: key) { return id }
        let id = UUID().uuidString.lowercased()
        UserDefaults.standard.set(id, forKey: key)
        return id
    }

    func activeOrders() async throws -> [Order] {
        try Self.orders(from: await get("orders/currentList", query: [
            "incomplete": "1",
            "show_additional_products": "1",
        ]))
    }

    func lastOrder() async throws -> Order? {
        try Self.orders(from: await get("orders/list", query: [
            "with_cancelled": "0",
            "max_records": "1",
            "offset": "0",
        ])).first
    }

    /// Decodes the `{"orders": [...]}` body of `orders/list` and `orders/currentList`.
    static func orders(from data: Data) throws -> [Order] {
        try JSONDecoder().decode(OrderList.self, from: data).orders?.map(\.order) ?? []
    }

    private func get(_ path: String, query: [String: String]) async throws -> Data {
        var components = URLComponents(url: Self.base.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }

        var request = URLRequest(url: components.url!)
        request.setValue(token, forHTTPHeaderField: "authorization")
        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        // Without a device id the API treats the token as invalid; any UUID is accepted.
        request.setValue(Self.deviceID, forHTTPHeaderField: "uuid")
        request.setValue("site-B", forHTTPHeaderField: "source")
        request.setValue("1", forHTTPHeaderField: "sitenew")
        request.setValue("ru", forHTTPHeaderField: "Content-Language")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("https://lifemart.ru", forHTTPHeaderField: "Origin")
        request.setValue("https://lifemart.ru/", forHTTPHeaderField: "Referer")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        // A rejected token is redirected to the HTML login page, not answered with 401.
        let loggedOut = response.url?.path.hasPrefix("/site/login") ?? false
        if status == 401 || status == 403 || loggedOut { throw Failure.unauthorized }
        guard (200..<300).contains(status) else { throw Failure.badResponse(status) }
        return data
    }
}

// MARK: - Wire format

private struct OrderList: Decodable {
    /// Missing or null when there is nothing to show.
    let orders: [WireOrder]?
}

private struct WireOrder: Decodable {
    struct Status: Decodable {
        let id: Int
        let title: String?
        let short_title: String?
        let text: String?
    }

    struct Product: Decodable {
        let id: Int?
        let name: String?
        let quantity: Int?
        let price: Int?
    }

    /// Present once a courier has the order.
    struct DeliveryInfo: Decodable {
        let expected_time: String?
    }

    let id: Int
    let code: String?
    let status: Status
    let create_time: String?
    let delivery_time: String?
    let delivery_info: Lenient<DeliveryInfo>?
    let delivery_type: String?
    let delivery_address: String?
    let delivery_department_name: String?
    let delivery_department_address: String?
    let total_amount: Int?
    let payment_title: String?
    let products: [Product]?

    var order: Order {
        let isPickup = delivery_type != "delivery"
        return Order(
            id: id,
            code: code ?? String(id),
            stage: OrderStage(statusID: status.id, shortTitle: status.short_title ?? status.title ?? "", isPickup: isPickup),
            statusText: status.text ?? "",
            createdAt: Self.date(create_time) ?? Date(),
            expectedAt: Self.date(delivery_info?.value?.expected_time) ?? Self.date(delivery_time),
            storeName: delivery_department_name ?? "Жизньмарт",
            storeAddress: delivery_department_address ?? "",
            kind: isPickup ? .pickup : .delivery(address: delivery_address ?? ""),
            items: (products ?? []).enumerated().map { index, product in
                OrderItem(
                    id: product.id ?? index,
                    name: product.name ?? "—",
                    quantity: product.quantity ?? 1,
                    price: product.price ?? 0
                )
            },
            total: total_amount ?? 0,
            paymentTitle: payment_title ?? ""
        )
    }

    private static func date(_ string: String?) -> Date? {
        string.flatMap { ISO8601DateFormatter().date(from: $0) }
    }
}

/// Decodes to nil instead of failing when a field changes shape
/// (the API sends `null` here, and PHP backends like to send `[]`).
private struct Lenient<T: Decodable>: Decodable {
    let value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}
