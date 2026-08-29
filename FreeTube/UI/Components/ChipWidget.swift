import SwiftUI

/// Pill-style category chip used in the YouTube header feed
struct ChipWidget: View {
    var text: String
    var isActive: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isActive ? Color.black : Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isActive ? Color.white : Color(white: 0.18))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
