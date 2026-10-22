import Foundation
import Combine

/// Polls lifemart.ru for the current order and tracks how its status changes.
@MainActor
final class OrderStore: ObservableObject {
    enum Problem: Equatable {
        case needsCredentials
        case unauthorized
        case offline
        case serverError(Int)
        case unreadable
    }

    @Published private(set) var order: Order?
    @Published private(set) var lastOrder: Order?
    @Published private(set) var statusChangedAt: Date?
    @Published private(set) var problem: Problem?
    @Published private(set) var now = Date()

    /// A finished order stays in the menu bar this long before the icon goes idle.
    private let finishedOrderLinger: TimeInterval = 15 * 60
    private var finishedAt: Date?
    private var loadedOnce = false
    private var poller: Task<Void, Never>?
    private let notifier = Notifier()

    init() {
        poller = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.refresh()
                let tracking = self.order.map { !$0.stage.isFinal } ?? false
                try? await Task.sleep(for: .seconds(tracking ? 30 : 60))
            }
        }
    }

    var symbol: String {
        if problem == .unauthorized { return "exclamationmark.triangle" }
        return order?.stage.symbol ?? "fork.knife"
    }

    func refresh() async {
        now = Date()
        guard let token = Credentials.token, let apiKey = Credentials.apiKey else {
            problem = .needsCredentials
            order = nil
            return
        }
        let api = LifemartAPI(token: token, apiKey: apiKey)
        do {
            let active = try await api.activeOrders().max { $0.createdAt < $1.createdAt }
            apply(active)
            if order == nil && lastOrder == nil {
                lastOrder = try await api.lastOrder()
            }
            problem = nil
        } catch LifemartAPI.Failure.unauthorized {
            problem = .unauthorized
        } catch LifemartAPI.Failure.badResponse(let status) {
            NSLog("LifemartBar: HTTP %d", status)
            problem = .serverError(status)
        } catch let error as DecodingError {
            NSLog("LifemartBar: unreadable response: %@", String(describing: error))
            problem = .unreadable
        } catch {
            NSLog("LifemartBar: request failed: %@", String(describing: error))
            problem = .offline
        }
        loadedOnce = true
    }

    func saveCredentials(token: String, apiKey: String) {
        Credentials.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        Credentials.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { await refresh() }
    }

    private func apply(_ active: Order?) {
        if let active {
            if active.id != order?.id || active.stage != order?.stage {
                statusChangedAt = now
                if loadedOnce { notifier.post(active) }
            }
            order = active
            finishedAt = active.stage.isFinal ? (finishedAt ?? now) : nil
            return
        }

        // The order left the incomplete list: it was delivered or handed over.
        if var current = order, !current.stage.isFinal {
            if case .pickup = current.kind {
                current.stage = .readyForPickup
                current.statusText = "Можно забирать"
            } else {
                current.stage = .delivered
                current.statusText = "Приятного аппетита!"
            }
            order = current
            statusChangedAt = now
            finishedAt = now
            notifier.post(current)
        }

        if let finishedAt, now.timeIntervalSince(finishedAt) > finishedOrderLinger {
            lastOrder = order
            order = nil
            self.finishedAt = nil
        }
    }
}
