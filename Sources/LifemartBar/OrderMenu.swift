import SwiftUI

struct OrderMenu: View {
    @ObservedObject var store: OrderStore
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        if let order = store.order {
            current(order)
        } else {
            Text("Активных заказов нет")
            if let last = store.lastOrder {
                Text("Последний заказ \(last.code) · \(ago(last.createdAt)) назад")
            }
        }

        Divider()

        if store.order != nil {
            Button("Открыть заказ на сайте") {
                NSWorkspace.shared.open(URL(string: "https://lifemart.ru/")!)
            }
        }
        Button("Обновить сейчас") { store.refresh() }
            .keyboardShortcut("r")

        Menu("Настройки") {
            Toggle("Уведомления о статусе", isOn: $notificationsEnabled)
            Button("Вставить токен…") {}
                .disabled(true)
            Divider()
            Menu("Демо-статус") {
                ForEach(OrderStage.allCases, id: \.self) { stage in
                    Button {
                        store.showDemo(stage)
                    } label: {
                        Label(stage.title, systemImage: stage.symbol)
                    }
                }
                Button("Нет заказа") { store.showDemo(nil) }
            }
        }

        Divider()

        Button("Выйти") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    @ViewBuilder
    private func current(_ order: Order) -> some View {
        Text("\(order.stage.title) · заказ \(order.code)")
        Text("Статус обновлён \(ago(order.statusChangedAt)) назад · в заказе \(ago(order.createdAt))")

        Divider()

        Text("Откуда: \(order.storeAddress)")
        switch order.kind {
        case .delivery(let address):
            Text("Куда: \(address)")
        case .pickup:
            Text("Забрать: \(order.storeAddress)")
        }

        Divider()

        Menu("Состав (\(order.items.count))") {
            ForEach(order.items) { item in
                Text("\(item.name) ×\(item.quantity) — \(rub(item.price))")
            }
        }
        Text("Итого \(rub(order.total)) · \(order.paymentTitle)")
    }

    private func ago(_ date: Date) -> String {
        let minutes = max(0, Int(store.now.timeIntervalSince(date) / 60))
        if minutes < 60 { return "\(minutes) мин" }
        if minutes < 24 * 60 { return "\(minutes / 60) ч \(minutes % 60) мин" }
        return "\(minutes / (24 * 60)) дн"
    }

    private func rub(_ amount: Int) -> String {
        amount.formatted(.number.grouping(.automatic)) + " ₽"
    }
}
