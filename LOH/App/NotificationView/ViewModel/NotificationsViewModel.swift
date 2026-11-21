import Foundation
import Combine

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published private(set) var notifications: [NotificationModel] = []
    @Published private(set) var sections: [NotificationSection] = []
    @Published private(set) var filter: NotificationsFilter = .all
    @Published private(set) var count: Int?
    @Published private(set) var hasLoaded = false
    @Published private(set) var loading = false
    @Published private(set) var loadingMore = false
    @Published private(set) var mutating = false
    @Published private(set) var hasMore = false
    @Published private(set) var error: String?
    @Published private(set) var countError: String?
    @Published var mutationError: String?
    var requiresSignIn: Bool { UserDefaults.accessToken == nil }
    let client: DefaultResponseHandler
    private var language = ""
    private var nextPage = 1
    private var needsReload = true
    private var generation = UUID()
    private var listRequest = UUID()
    private var countRequest = UUID()
    private var locallyReadIDs = Set<String>()

    init(client: DefaultResponseHandler = DefaultResponseHandler()) {
        self.client = client
    }

    func refresh(language: String) async {
        let generation = generation, token = UserDefaults.accessToken
        await reload(filter: filter, language: language)
        guard self.generation == generation, UserDefaults.accessToken == token, !Task.isCancelled else { return }
        await refreshCount(language: language)
    }

    func reload(filter: NotificationsFilter, language: String) async {
        guard !mutating, !Task.isCancelled else { return }
        guard let token = UserDefaults.accessToken else { resetSession(); return }
        if self.filter != filter || self.language != language {
            notifications = []; sections = []; hasLoaded = false
        }
        self.filter = filter; self.language = language
        let request = UUID(), generation = generation
        listRequest = request
        loading = true; loadingMore = false; error = nil; needsReload = true; hasMore = false
        defer { if listRequest == request { loading = false } }
        do {
            let result: NotificationsListData = try await client.data(
                from: NotificationEndpoints.list(filter: filter, page: 1, token: token), language: language)
            try check(token, generation)
            guard listRequest == request else { return }
            try validate(result, page: 1)
            sections = uniqueSections(result.sections)
            notifications = unique(result.data)
            applyLocalReadState()
            nextPage = 2
            hasMore = !notifications.isEmpty && (result.pagination?.totalPages ?? 1) > 1
            hasLoaded = true; needsReload = false
        } catch {
            if current(token, generation), listRequest == request { self.error = error.localizedDescription }
        }
    }

    func loadMore() async {
        guard hasMore, !needsReload, !loading, !loadingMore, !mutating, !Task.isCancelled,
              let token = UserDefaults.accessToken else { return }
        let request = UUID(), generation = generation, page = nextPage
        listRequest = request; loadingMore = true; error = nil
        defer { if listRequest == request { loadingMore = false } }
        do {
            let result: NotificationsListData = try await client.data(
                from: NotificationEndpoints.list(filter: filter, page: page, token: token), language: language)
            try check(token, generation)
            guard listRequest == request else { return }
            try validate(result, page: page)
            let existing = Set(notifications.map(\.id))
            let additions = unique(result.data).filter { !existing.contains($0.id) }
            notifications.append(contentsOf: additions)
            sections = mergeSections(sections, with: result.sections)
            applyLocalReadState()
            nextPage = page + 1
            hasMore = !additions.isEmpty && page < (result.pagination?.totalPages ?? page)
        } catch {
            if current(token, generation), listRequest == request { self.error = error.localizedDescription }
        }
    }

    func retry(language: String) async {
        if needsReload { await reload(filter: filter, language: language) }
        else { await loadMore() }
    }

    func refreshCount(language: String) async {
        guard !mutating, !Task.isCancelled else { return }
        guard let token = UserDefaults.accessToken else { resetSession(); return }
        let request = UUID(), generation = generation
        countRequest = request; countError = nil
        do {
            let result: NotificationCount = try await client.data(
                from: NotificationEndpoints.count(token: token), language: language)
            let value = result.count
            try check(token, generation)
            guard countRequest == request else { return }
            count = value
        } catch {
            if current(token, generation), countRequest == request { countError = error.localizedDescription }
        }
    }

    @discardableResult
    func markAllAsRead(language: String) async -> Bool {
        guard !mutating, !Task.isCancelled, !notifications.isEmpty,
              let token = UserDefaults.accessToken else { return false }
        let generation = generation
        listRequest = UUID(); countRequest = UUID()
        loading = false; loadingMore = false; mutating = true; mutationError = nil
        do {
            try await client.perform(
                NotificationEndpoints.markAllAsRead(token: token), language: language)
            try check(token, generation)
            markLocallyAsRead(ids: notifications.map(\.id))
            count = 0
            mutating = false
            return true
        } catch {
            if current(token, generation) { mutationError = error.localizedDescription }
            if self.generation == generation { mutating = false }
            return false
        }
    }

    @discardableResult
    func markAsRead(id: String, language: String) async -> Bool {
        guard !mutating, !Task.isCancelled, !id.isEmpty,
              notifications.contains(where: { $0.id == id && !$0.isRead }),
              let token = UserDefaults.accessToken else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard id.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
        let generation = generation
        listRequest = UUID(); countRequest = UUID()
        loading = false; loadingMore = false; mutating = true; mutationError = nil
        do {
            try await client.perform(
                NotificationEndpoints.markAsRead(id: id, token: token), language: language)
            try check(token, generation)
            markLocallyAsRead(ids: [id])
            if let count { self.count = max(0, count - 1) }
            mutating = false
            return true
        } catch {
            if current(token, generation) { mutationError = error.localizedDescription }
            if self.generation == generation { mutating = false }
            return false
        }
    }

    @discardableResult
    func delete(id: String?, language: String) async -> Bool {
        guard !mutating, !Task.isCancelled, let token = UserDefaults.accessToken else { return false }
        let generation = generation
        listRequest = UUID(); countRequest = UUID()
        loading = false; loadingMore = false; mutating = true; mutationError = nil
        do {
            if let id {
                let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
                guard !id.isEmpty, id.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
                    throw APIError.invalidResponse
                }
                try await client.perform(NotificationEndpoints.delete(id: id, token: token), language: language)
            } else {
                try await client.perform(NotificationEndpoints.deleteAll(token: token), language: language)
            }
            try check(token, generation)
            if let id { notifications.removeAll { $0.id == id } }
            else { notifications = []; sections = []; count = 0; hasLoaded = true }
            hasMore = false; needsReload = true; nextPage = 1; error = nil
            mutating = false
            await reload(filter: filter, language: language)
            guard current(token, generation) else { return true }
            await refreshCount(language: language)
            return true
        } catch {
            if current(token, generation) { mutationError = error.localizedDescription }
            if self.generation == generation { mutating = false }
            if current(token, generation), !hasLoaded {
                await reload(filter: filter, language: language)
            }
            return false
        }
    }

    func resetSession() {
        generation = UUID(); listRequest = UUID(); countRequest = UUID()
        notifications = []; sections = []; count = nil; filter = .all; language = ""
        locallyReadIDs.removeAll()
        hasLoaded = false; loading = false; loadingMore = false; mutating = false
        hasMore = false; needsReload = true; nextPage = 1
        error = nil; countError = nil; mutationError = nil
    }

    private func check(_ token: String, _ generation: UUID) throws {
        try Task.checkCancellation()
        guard self.generation == generation, UserDefaults.accessToken == token else { throw CancellationError() }
    }
    private func current(_ token: String, _ generation: UUID) -> Bool {
        self.generation == generation && UserDefaults.accessToken == token && !Task.isCancelled
    }
    private func validate(_ result: NotificationsListData, page: Int) throws {
        if let pagination = result.pagination, pagination.currentPage != page { throw APIError.invalidResponse }
    }
    private func unique(_ items: [NotificationModel]) -> [NotificationModel] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }

    private func applyLocalReadState() {
        guard !locallyReadIDs.isEmpty else { return }
        notifications = notifications.map { item in
            guard locallyReadIDs.contains(item.id) else { return item }
            var item = item
            item.isRead = true
            return item
        }
        sections = sections.map { section in
            NotificationSection(
                key: section.key,
                title: section.title,
                notifications: section.notifications.map { item in
                    guard locallyReadIDs.contains(item.id) else { return item }
                    var item = item
                    item.isRead = true
                    return item
                })
        }
    }

    private func markLocallyAsRead(ids: [String]) {
        locallyReadIDs.formUnion(ids)
        applyLocalReadState()
    }
    private func uniqueSections(_ items: [NotificationSection]) -> [NotificationSection] {
        items.map { section in
            NotificationSection(key: section.key, title: section.title, notifications: unique(section.notifications))
        }
    }
    private func mergeSections(_ current: [NotificationSection], with incoming: [NotificationSection]) -> [NotificationSection] {
        guard !incoming.isEmpty else { return current }
        var merged = current
        for section in incoming {
            let additions = unique(section.notifications).filter { notification in
                !merged.flatMap(\.notifications).contains(where: { $0.id == notification.id })
            }
            guard !additions.isEmpty else { continue }
            if let index = merged.firstIndex(where: { $0.key == section.key }) {
                merged[index] = NotificationSection(
                    key: merged[index].key,
                    title: merged[index].title,
                    notifications: merged[index].notifications + additions)
            } else {
                merged.append(NotificationSection(key: section.key, title: section.title, notifications: additions))
            }
        }
        return merged
    }
}
