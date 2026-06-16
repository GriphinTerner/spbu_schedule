import SwiftUI

struct WeekScrollView: View {
    @Binding var currentWeek: [Date.Day]
    @Binding var eventsByDate: [Date: [Event]]
    @Binding var selectedDate: Date?
    @Binding var isLoadingWeek: Bool

    var loadWeek: (Int) async -> Void
    var refreshCurrentWeek: () async throws -> Void 
    var onError: (TimetableError) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ScrollViewReader { scrollProxy in
                ZStack {
                    if !isLoadingWeek {
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 15, pinnedViews: [.sectionHeaders]) {
                                if let selected = selectedDate,
                                   let day = currentWeek.first(where: { $0.date.isSame(selected) }) {
                                    DaySection(date: day.date,
                                               isLast: true,
                                               size: size,
                                               events: eventsByDate[day.date] ?? [])
                                        .id(day.id)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .refreshable {
                            do {
                                try await refreshCurrentWeek()
                            } catch let error as TimetableError {
                                onError(error)
                            } catch {
                                onError(.unknown)
                            }
                        }
                        .onChange(of: selectedDate) { _, newValue in
                            if let newValue,
                               let day = currentWeek.first(where: { $0.date.isSame(newValue) }) {
                                withAnimation(.easeInOut) {
                                    scrollProxy.scrollTo(day.id, anchor: .top)
                                }
                            }
                        }
                    }

                    if isLoadingWeek {
                        VStack {
                            ProgressView("Загрузка недели...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.9))
                    }
                }
            }
        }
        .background(Color("Background"))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .ignoresSafeArea(.all, edges: .bottom)
    }
}
