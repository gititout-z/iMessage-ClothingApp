// MARK: - DateExtensions.swift
import Foundation

extension Date {
    // Format date as relative to now
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    // Format as short date
    func formattedShortDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    // Format as medium date
    func formattedMediumDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    // Format as long date
    func formattedLongDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    // Format as date and time
    func formattedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    // Check if date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    // Check if date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }

    // Check if date is in this week
    var isThisWeek: Bool {
        let calendar = Calendar.current
        let thisWeekRange = calendar.dateInterval(of: .weekOfYear, for: Date())
        return thisWeekRange?.contains(self) ?? false
    }

    // Check if date is in this month
    var isThisMonth: Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: Date(), toGranularity: .month)
    }
}
