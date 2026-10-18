import AppKit
import Foundation

@MainActor
final class TodoStore: ObservableObject {
    @Published private(set) var items: [TodoItem] = []
    @Published private(set) var groups = [TodoGroup(name: "待办")]
    @Published private(set) var lastSaveError: String?

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var loadFailed = false

    init(fileURL: URL? = nil) {
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
        self.fileURL = fileURL ?? baseURL
            .appendingPathComponent("Menuminder", isDirectory: true)
            .appendingPathComponent("todos.json", isDirectory: false)

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        load()
    }

    var activeItems: [TodoItem] {
        items
            .filter { !$0.isCompleted }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var completedItems: [TodoItem] {
        items
            .filter(\.isCompleted)
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    func add(title: String, noteRTFD: Data?, groupID: UUID? = nil) {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else { return }
        var item = TodoItem(title: cleanedTitle, noteRTFD: noteRTFD)
        item.groupID = groupID ?? groups.first?.id
        items.append(item)
        save()
    }

    func update(id: UUID, title: String, noteRTFD: Data?, groupID: UUID? = nil) {
        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty, let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].title = cleanedTitle
        items[index].noteRTFD = noteRTFD
        items[index].groupID = groupID ?? items[index].groupID
        items[index].updatedAt = Date()
        save()
    }

    func toggle(_ item: TodoItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].completedAt = items[index].isCompleted ? nil : Date()
        items[index].updatedAt = Date()
        save()
    }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clearCompleted() {
        items.removeAll { $0.isCompleted }
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            if let archive = try? decoder.decode(TodoArchive.self, from: data) {
                guard archive.version == 1, !archive.groups.isEmpty else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                groups = archive.groups
                items = archive.items
            } else {
                items = try decoder.decode([TodoItem].self, from: data)
                let backup = fileURL.appendingPathExtension("before-groups.bak")
                if !FileManager.default.fileExists(atPath: backup.path) {
                    try data.write(to: backup, options: .atomic)
                }
            }
            for index in items.indices where !groups.contains(where: { $0.id == items[index].groupID }) {
                items[index].groupID = groups[0].id
            }
        } catch {
            loadFailed = true
            lastSaveError = "无法读取数据：\(error.localizedDescription)"
        }
    }

    private func save() {
        guard !loadFailed else { return }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try encoder.encode(TodoArchive(groups: groups, items: items)).write(to: fileURL, options: .atomic)
            lastSaveError = nil
        } catch {
            lastSaveError = "无法保存数据：\(error.localizedDescription)"
        }
    }

    func saveGroup(id: UUID?, name: String, color: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if let id, let index = groups.firstIndex(where: { $0.id == id }) {
            groups[index].name = name
            groups[index].color = color
        } else {
            groups.append(TodoGroup(name: name, color: color))
        }
        save()
    }

    func deleteGroup(_ group: TodoGroup) {
        guard groups.contains(where: { $0.id == group.id }),
              let destination = groups.first(where: { $0.id != group.id }) else { return }
        for index in items.indices where items[index].groupID == group.id {
            items[index].groupID = destination.id
        }
        groups.removeAll { $0.id == group.id }
        save()
    }
}
