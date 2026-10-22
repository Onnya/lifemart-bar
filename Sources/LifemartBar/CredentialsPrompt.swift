import AppKit

/// Asks for the `authorization` token and `X-Api-Key` header copied from
/// a lifemart.ru request in the browser's DevTools.
enum CredentialsPrompt {
    @MainActor
    static func run(onSave: (_ token: String, _ apiKey: String) -> Void) {
        let token = NSTextField(frame: NSRect(x: 0, y: 30, width: 300, height: 24))
        token.placeholderString = "authorization"
        token.stringValue = Credentials.token ?? ""
        let apiKey = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        apiKey.placeholderString = "X-Api-Key"
        apiKey.stringValue = Credentials.apiKey ?? ""

        let fields = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 54))
        fields.addSubview(token)
        fields.addSubview(apiKey)

        let alert = NSAlert()
        alert.messageText = "Токен lifemart.ru"
        alert.informativeText = "Откройте lifemart.ru, войдите в аккаунт, в DevTools → Network выберите любой запрос к api.lifemart.ru и скопируйте значения заголовков authorization и X-Api-Key. Они хранятся только в связке ключей этого Mac."
        alert.accessoryView = fields
        alert.addButton(withTitle: "Сохранить")
        alert.addButton(withTitle: "Отмена")
        alert.window.initialFirstResponder = token

        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let tokenValue = headerValue(token.stringValue)
        let apiKeyValue = headerValue(apiKey.stringValue)
        guard !tokenValue.isEmpty, !apiKeyValue.isEmpty else { return }
        onSave(tokenValue, apiKeyValue)
    }

    /// Accepts a bare value as well as a whole copied header line
    /// like `authorization: abc` or `"X-Api-Key": "abc"`.
    private static func headerValue(_ input: String) -> String {
        var value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if let colon = value.firstIndex(of: ":") {
            value = String(value[value.index(after: colon)...])
        }
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "\"' ,").union(.whitespacesAndNewlines))
    }
}
