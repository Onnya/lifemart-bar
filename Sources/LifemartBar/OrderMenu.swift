import SwiftUI

struct OrderMenu: View {
    @ObservedObject var store: OrderStore
    @AppStorage(Notifier.enabledKey) private var notificationsEnabled = true

    var body: some View {
        switch store.problem {
        case .needsCredentials:
            Text("Нужен токен: Настройки → Ввести токен…")
        case .unauthorized:
            Text("Токен не подошёл, введите его заново")
        case .offline:
            Text("Нет связи с lifemart.ru")
        case .serverError(let status):
            Text("lifemart.ru ответил ошибкой \(status)")
        case .unreadable:
            Text("Не удалось разобрать ответ lifemart.ru")
        case nil:
            EmptyView()
        }

        if let order = store.order {
            current(order)
        } else if store.problem != .needsCredentials {
            Text("Активных заказов нет")
            if let last = store.lastOrder {
                Text("Последний заказ \(last.code) · \(ago(last.createdAt)) назад")
            }
        }

        Divider()

        Button("Открыть lifemart.ru") {
            NSWorkspace.shared.open(URL(string: "https://lifemart.ru/")!)
        }
        Button("Обновить сейчас") {
            Task { await store.refresh() }
        }
        .keyboardShortcut("r")

        Menu("Настройки") {
            Toggle("Уведомления о статусе", isOn: $notificationsEnabled)
            if store.notifier.isBlocked {
                Button("Разрешить уведомления в macOS…") { store.notifier.openSystemSettings() }
            } else {
                Button("Тестовое уведомление") { store.notifier.sendTest() }
            }
            Button("Ввести токен…") {
                CredentialsPrompt.run(onSave: store.saveCredentials)
            }
        }

        Divider()

        Button("Выйти") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    @ViewBuilder
    private func current(_ order: Order) -> some View {
        Text("\(order.stage.title) · заказ \(order.code)")
        if !order.statusText.isEmpty {
            Text(order.statusText)
        }
        if let expected = order.expectedAt, !order.stage.isFinal {
            switch order.kind {
            case .delivery:
                Text("Привезут к \(time(expected)) · в заказе \(ago(order.createdAt))")
            case .pickup:
                Text("Будет готов к \(time(expected)) · в заказе \(ago(order.createdAt))")
            }
        }
        if let changed = store.statusChangedAt {
            Text("Статус обновлён \(ago(changed)) назад")
        }

        Divider()

        switch order.kind {
        case .delivery(let address):
            Text("Откуда: \(order.storeName)")
            Text("Куда: \(address)")
        case .pickup:
            Text("Забрать: \(order.storeName)")
            if !order.storeAddress.isEmpty {
                Text(order.storeAddress)
            }
        }

        Divider()

        if !order.items.isEmpty {
            Menu("Состав (\(order.items.count))") {
                ForEach(order.items) { item in
                    Text("\(item.name) ×\(item.quantity) — \(rub(item.price))")
                }
            }
        }
        Text("Итого \(rub(order.total))" + (order.paymentTitle.isEmpty ? "" : " · \(order.paymentTitle.lowercased())"))
    }

    private func ago(_ date: Date) -> String {
        let minutes = max(0, Int(store.now.timeIntervalSince(date) / 60))
        if minutes < 60 { return "\(minutes) мин" }
        if minutes < 24 * 60 { return "\(minutes / 60) ч \(minutes % 60) мин" }
        return "\(minutes / (24 * 60)) дн"
    }

    private func time(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func rub(_ amount: Int) -> String {
        amount.formatted(.number.grouping(.automatic)) + " ₽"
    }
}
