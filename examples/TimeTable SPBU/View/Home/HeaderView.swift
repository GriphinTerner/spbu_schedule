import SwiftUI

struct HeaderView: View {
    @Binding var currentWeek: [Date.Day]
    @Binding var selectedDate: Date?
    @Binding var weekOffset: Int
    var loadWeek: (Int) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Text((selectedDate?.string("MMMM") ?? "").capitalized)
                    .font(.title.bold())
                    .foregroundColor(.textPrimary)
                
                Text(selectedDate?.string("YYYY") ?? "")
                    .font(.title3.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .baselineOffset(6)
            }
            .padding(.horizontal, 16)

            HStack(spacing: 0) {
                ArrowButton(direction: .left) {
                    Task { await loadWeek(weekOffset - 1) }
                }

                ForEach(currentWeek) { day in
                    DayView(day: day, selectedDate: $selectedDate)
                }

                ArrowButton(direction: .right) {
                    Task { await loadWeek(weekOffset + 1) }
                }
            }
            .frame(height: 80)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color.appBackground)
    }
}

// MARK: - DayView
struct DayView: View {
    var day: Date.Day
    @Binding var selectedDate: Date?

    var body: some View {
        let date = day.date
        let isSameDate = date.isSame(selectedDate)

        return VStack(spacing: 4) {
            Text(date.string("EEE"))
                .font(.caption)
                .foregroundColor(.textSecondary)

            Text(date.string("d"))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(isSameDate ? .textPrimary : .textSecondary)
                .frame(width: 38, height: 38)

            Circle()
                .fill(
                    LinearGradient(colors: [Color.blue],
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .frame(width: 6, height: 6)
                .opacity(isSameDate ? 1 : 0)
        }
        .frame(width: 38, height: 54)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring()) {
                selectedDate = date
            }
        }
    }
}


enum ArrowDirection { case left, right }

struct ArrowButton: View {
    var direction: ArrowDirection
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(.accentColor)
                .padding(6)
        }
    }
}
