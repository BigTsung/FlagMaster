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
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(.white.opacity(0.22), lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
        .accessibilityHidden(true)
    }

    nonisolated(unsafe) private static let cache = NSCache<NSString, UIImage>()

    private static func load(_ code: String) -> UIImage? {
        if let cached = cache.object(forKey: code as NSString) { return cached }
        guard let url = Bundle.main.url(forResource: code, withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: code as NSString)
        return image
    }
}

#Preview("Flag Image") {
    AppPreview {
        ZStack {
            AppBackground()
            FlagImage(code: "TW")
                .frame(width: 320, height: 210)
                .padding()
        }
    }
}
