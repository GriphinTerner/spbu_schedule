
import SwiftUI

struct DaySection: View {
    let date: Date
    let isLast: Bool
    let size: CGSize
    let events: [Event]
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedSubjects: Set<String> = []

    var groupedEvents: [String: [Event]] {
        Dictionary(grouping: events) { $0.Subject }
    }

    private func gradientFor(events: [Event]) -> LinearGradient {
        let hasCancelled = events.contains { $0.IsCancelled }
        let hasChanged = events.contains { $0.TimeWasChanged }

        var colors: [Color] = []
        if hasCancelled { colors.append(.red) }
        if hasChanged { colors.append(.orange) }
        colors.append(.blue)

        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func statusColor(for event: Event) -> Color {
        if event.IsCancelled {
            return .red
        } else if event.TimeWasChanged {
            return .orange
        } else {
            return .blue
        }
    }
    
    private func statusColorForGroup(_ events: [Event]) -> Color {
        if events.contains(where: { $0.IsCancelled }) {
            return .red
        } else if events.contains(where: { $0.TimeWasChanged }) {
            return .orange
        } else {
            return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if events.isEmpty {
                EmptyTaskRow()
            } else {
                ForEach(groupedEvents.keys.sorted(), id: \.self) { subject in
                    if let subjectEvents = groupedEvents[subject] {
                        let statusGradient = gradientFor(events: subjectEvents)

                        if subjectEvents.count == 1 {
                            TaskRow(event: subjectEvents.first!)
                        } else {
                            VStack(spacing: 0) {
                                // Папка предмета
                                HStack(spacing: 8) {
                                    Rectangle()
                                        .fill(statusGradient)
                                        .frame(width: 4)
                                        .frame(height: 40)
                                        .cornerRadius(2)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(subject)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.textPrimary)
                                        Text("\(subjectEvents.count) занятий")
                                            .font(.caption)
                                            .foregroundColor(
                                                statusColorForGroup(subjectEvents).opacity(0.7)
                                            )
                                    }

                                    Spacer()

                                    Image(systemName: expandedSubjects.contains(subject) ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.textSecondary)
                                        .padding(.trailing, 8)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.cardBackground)
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        if expandedSubjects.contains(subject) {
                                            expandedSubjects.remove(subject)
                                        } else {
                                            expandedSubjects.insert(subject)
                                        }
                                    }
                                }

                                if expandedSubjects.contains(subject) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(Array(subjectEvents.enumerated()), id: \.element.id) { index, event in
                                            HStack(spacing: 0) {
                                                Rectangle()
                                                    .fill(statusColor(for: event).opacity(0.7))
                                                    .frame(width: 12, height: 2)
                                                    .padding(.leading, 16)
                                                
                                                TaskRow(event: event)
                                                    .padding(.leading, 4)
                                            }
                                        }
                                    }
                                    .padding(.top, 12)
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                                        removal: .opacity
                                    ))
                                } else {
                                    Spacer().frame(height: 4)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: isLast ? size.height - 110 : nil, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.dayBackground)
        )
    }
}
