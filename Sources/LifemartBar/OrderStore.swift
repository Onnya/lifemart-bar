import Foundation
import Combine

/// Holds the order the menu shows. Until the API client exists it serves
/// mock orders that the demo submenu switches between.
@MainActor
final class OrderStore: ObservableObject {
    @Published private(set) var order: Order?
    @Published private(set) var lastOrder: Order?
    @Published private(set) var now = Date()

    private var ticker: AnyCancellable?

    init() {
        lastOrder = Self.mock(stage: .delivered, minutesAgo: 26 * 60)
        showDemo(.onTheWay)
        ticker = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] in self?.now = $0 }
    }

    var symbol: String { order?.stage.symbol ?? "fork.knife" }

    func refresh() {
        now = Date()
    }

    func showDemo(_ stage: OrderStage?) {
        order = stage.map { Self.mock(stage: $0, minutesAgo: 23) }
        now = Date()
    }

    private static func mock(stage: OrderStage, minutesAgo: Double) -> Order {
        let created = Date().addingTimeInterval(-minutesAgo * 60)
        let pickup = stage == .readyForPickup
        return Order(
            code: "C02",
            stage: stage,
            createdAt: created,
            statusChangedAt: Date().addingTimeInterval(-4 * 60),
            storeAddress: "Жизньмарт, ул. Ленина, 10",
            kind: pickup ? .pickup : .delivery(address: "ул. Мира, 5, кв. 12"),
            items: [
                OrderItem(name: "Боул с курицей терияки", quantity: 1, price: 390),
                OrderItem(name: "Морс клюквенный 0,5 л", quantity: 2, price: 180),
                OrderItem(name: "Сырники со сметаной", quantity: 1, price: 290),
                OrderItem(name: "Салат «Цезарь»", quantity: 1, price: 380),
            ],
            total: 1240,
            paymentTitle: "оплачено картой"
        )
    }
}
