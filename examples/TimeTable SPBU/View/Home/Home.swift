import SwiftUI

struct Home: View {
    @State private var weekOffset: Int = 0
    @State private var allWeeks: [[Date.Day]] = []
    @State private var currentWeek: [Date.Day] = []
    @State private var selectedDate: Date?
    @State private var eventsByDate: [Date: [Event]] = [:]
    @State private var isLoadingWeek: Bool = true
    @State private var errorMessage: String?

    let groupId = 429175
    @Namespace private var namespace

    var eventsForSelectedDate: [Event] {
        if let selected = selectedDate,
           let events = eventsByDate[selected] {
            return events
        }
        return []
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                currentWeek: $currentWeek,
                selectedDate: $selectedDate,
                weekOffset: $weekOffset,
                loadWeek: loadWeek
            )

            WeekScrollView(
                currentWeek: $currentWeek,
                eventsByDate: $eventsByDate,
                selectedDate: $selectedDate,
                isLoadingWeek: $isLoadingWeek,
                loadWeek: loadWeek,
                refreshCurrentWeek: refreshCurrentWeek,
                onError: { error in
                    errorMessage = error.localizedDescription
                }
            )
        }
        .background(Color("Background"))
        .task {
            setupWeeks()
        }
        .alert(isPresented: .constant(errorMessage != nil)) {
            Alert(
                title: Text("Ошибка"),
                message: Text(errorMessage ?? ""),
                dismissButton: .default(Text("Ок")) {
                    errorMessage = nil
                }
            )
        }
    }

    // MARK: - Настройка недели
    private func setupWeeks() {
        let cachedWeeks = UserDefaults.standard.loadWeeks()
        let cachedEvents = UserDefaults.standard.loadEvents()

        if let weekIndex = cachedWeeks.firstIndex(where: { $0.contains(where: { $0.date.isSame(.now) }) }) {
            currentWeek = cachedWeeks[weekIndex]
            allWeeks = [cachedWeeks[weekIndex]]
            eventsByDate = cachedEvents // ✅ сразу берём кэш
        } else {
            currentWeek = Date.week(for: 0)
            allWeeks = [currentWeek]
        }

        selectedDate = Date()
        isLoadingWeek = false

        Task {
            await refreshWeek(currentWeek)
        }
    }

    // MARK: - Загрузка недели
    func loadWeek(offset: Int) async {
        isLoadingWeek = true
        weekOffset = offset

        let week = Date.week(for: offset)
        currentWeek = week
        selectedDate = week.first?.date

        if offset == 0 {
            // ✅ Берём кэш полностью, без merge
            eventsByDate = UserDefaults.standard.loadEvents()
        }

        if !allWeeks.contains(where: { $0.first?.date.isSame(week.first?.date ?? .now) ?? false }) {
            allWeeks.append(week)
        }

        isLoadingWeek = false

        Task {
            do {
                let start = week.first?.date ?? .now
                let end = week.last?.date ?? .now
                let refreshed = try await Date.getTimetableRange(for: groupId, from: start, to: end)

                await MainActor.run {
                    eventsByDate.merge(refreshed) { _, new in new }
                    if offset == 0 {
                        UserDefaults.standard.saveEvents(eventsByDate) // ✅ всегда сохраняем
                        UserDefaults.standard.saveWeeks(allWeeks)
                    }
                }
            } catch {
                await MainActor.run {
                    if let err = error as? TimetableError {
                        errorMessage = err.localizedDescription
                    } else {
                        errorMessage = TimetableError.unknown.localizedDescription
                    }
                }
            }
        }
    }

    func refreshCurrentWeek() async {
        await refreshWeek(currentWeek)
    }

    func refreshWeek(_ week: [Date.Day]) async {
        guard let start = week.first?.date,
              let end = week.last?.date else { return }

        do {
            let refreshed = try await Date.getTimetableRange(for: groupId, from: start, to: end)
            await MainActor.run {
                eventsByDate.merge(refreshed) { _, new in new }
                if weekOffset == 0 {
                    UserDefaults.standard.saveEvents(eventsByDate) // ✅ сохраняем всегда
                    UserDefaults.standard.saveWeeks(allWeeks)
                }
            }
        } catch {
            await MainActor.run {
                if let err = error as? TimetableError {
                    errorMessage = err.localizedDescription
                } else {
                    errorMessage = TimetableError.unknown.localizedDescription
                }
            }
        }
    }
}
