// MARK: - StringExtensions.swift
import Foundation

extension String {
    // Limit string to max length with ellipsis
    func limitLength(to maxLength: Int) -> String {
        if self.count <= maxLength {
            return self
        }
        
        let index = self.index(self.startIndex, offsetBy: maxLength - 3)
        return String(self[..<index]) + "..."
    }

    // Convert to slug for URLs
    func toSlug() -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let slug = self.lowercased()
            .components(separatedBy: allowed.inverted)
            .joined(separator: "-")
        
        return slug.components(separatedBy: CharacterSet(charactersIn: "-")).filter { !$0.isEmpty }.joined(separator: "-")
    }

    // Extract the first letter of each word for initials
    var initials: String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.map { $0.first?.uppercased() ?? "" }.joined()
    }

    // Check if the string is a valid username
    func isValidUsername() -> Bool {
        let usernameRegex = "^[a-zA-Z0-9_]{3,20}$"
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        return usernamePredicate.evaluate(with: self)
    }

    // Check if the string is a valid email
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }

    // Create URL if string is a valid URL
    var asURL: URL? {
        URL(string: self)
    }
}
