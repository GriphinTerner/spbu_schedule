import SwiftUI

struct TaskRow: View {
    var event: Event
    @State private var isExpanded: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private var statusColor: Color {
        if event.IsCancelled {
            return .red
        } else if event.TimeWasChanged {
            return .orange
        } else {
            return .blue
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.Subject)
                        .font(SwiftUI.Font.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(isExpanded ? nil : 2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(event.TimeIntervalString)
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [statusColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Spacer()

                Button {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(statusColor)
                        .padding(.vertical, 4)
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    if let educator = event.EducatorsDisplayText {
                        Text(educator)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                    if let location = event.LocationsDisplayText {
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    if event.IsCancelled {
                        Text("Занятие отменено")
                            .font(.caption2)
                            .foregroundColor(.red)
                    } else if event.TimeWasChanged {
                        Text("Время изменилось")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.top, 5)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - EmptyTaskRow
struct EmptyTaskRow: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Сегодня занятий нет 🎉")
                .font(.headline)
                .foregroundColor(.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
