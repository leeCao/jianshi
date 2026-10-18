import Foundation

@main
struct StoreSmoke {
    @MainActor static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Menuminder-Test-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("todos.json")
        let old = TodoItem(title: "Existing task", noteRTFD: Data([1, 2, 3]))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let original = try encoder.encode([old])
        try original.write(to: url)
        let store = TodoStore(fileURL: url)
        precondition(store.items.count == 1 && store.items[0].groupID == store.groups[0].id)
        let backup = try Data(contentsOf: url.appendingPathExtension("before-groups.bak"))
        precondition(backup == original)
        store.saveGroup(id: nil, name: "Work", color: "purple")
        let work = store.groups[1]
        store.update(id: old.id, title: "Moved", noteRTFD: old.noteRTFD, groupID: work.id)
        store.add(title: "New", noteRTFD: nil, groupID: work.id)
        store.saveGroup(id: work.id, name: "Renamed", color: "orange")
        let reloaded = TodoStore(fileURL: url)
        precondition(reloaded.groups[1].name == "Renamed")
        precondition(reloaded.items.allSatisfy { $0.groupID == work.id })
        reloaded.toggle(reloaded.items[0])
        reloaded.deleteGroup(work)
        let final = TodoStore(fileURL: url)
        precondition(final.items.count == 2 && final.groups.count == 1)
        precondition(final.items.allSatisfy { $0.groupID == final.groups[0].id })
        precondition(final.completedItems.count == 1 && final.items[0].noteRTFD == old.noteRTFD)
        final.deleteGroup(final.groups[0])
        precondition(final.groups.count == 1)
        print("PASS: legacy migration, backup, group CRUD, task move, completion and persistence")
    }
}
