import SwiftUI

extension ShapeStyle where Self == Color {
    static var mainBackground: Color {
        Color(red: 28/255, green: 28/255, blue: 30/255) 
    }
}

extension Color {
    static let appBackground = Color("Background")
    static let appCardBackground = Color("CardBackground")
    static let appTextPrimary = Color("TextPrimary")
    static let appTextSecondary = Color("TextSecondary")
}
