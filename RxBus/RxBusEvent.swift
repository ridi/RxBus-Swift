protocol Event {
    static var name: String { get }
}

extension Event {
    static var name: String {
        return "\(self)"
    }
}
