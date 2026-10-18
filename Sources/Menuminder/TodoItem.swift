import Foundation

struct TodoItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var noteRTFD: Data?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var groupID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        noteRTFD: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.noteRTFD = noteRTFD
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }

    var isCompleted: Bool { completedAt != nil }
}

struct TodoGroup: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var color: String = "blue"
}

struct TodoArchive: Codable {
    var version = 1
    var groups: [TodoGroup]
    var items: [TodoItem]
}
