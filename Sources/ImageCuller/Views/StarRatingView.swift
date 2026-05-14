import SwiftUI

struct StarRatingDisplay: View {
    let rating: Int
    var maxStars: Int = 5

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...maxStars, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.4))
            }
        }
    }
}

struct StarRatingControl: View {
    @Binding var rating: Int
    var maxStars: Int = 5

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxStars, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .yellow : .gray)
                    .onTapGesture { rating = star }
            }
            if rating > 0 {
                Button("0") { rating = 0 }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
}
