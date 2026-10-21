import SwiftUI

@main
struct LifemartBarApp: App {
    @StateObject private var store = OrderStore()

    var body: some Scene {
        MenuBarExtra {
            OrderMenu(store: store)
        } label: {
            Image(systemName: store.symbol)
        }
        .menuBarExtraStyle(.menu)
    }
}
