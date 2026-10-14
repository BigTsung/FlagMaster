import SwiftUI
import UIKit

struct FlagImage: View {
    let code: String

    var body: some View {
        Group {
            if let image = Self.load(code) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "flag.slash")
                    .resizable()
                    .scaledToFit()
                    .padding(30)
                    .foregroundStyle(.secondary)
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.22), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 16, y: 8)
        .accessibilityHidden(true)
    }

    private static func load(_ code: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: code, withExtension: "png") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

#Preview("Flag Image") {
    ZStack {
        AppBackground()
        FlagImage(code: "TW")
            .frame(width: 320, height: 210)
            .padding()
    }
}
