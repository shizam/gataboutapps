import SwiftUI

struct TitleLargeStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.largeTitle.bold())
    }
}

struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.headline)
    }
}

struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.body)
    }
}

struct CaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

extension View {
    func titleLargeStyle() -> some View { modifier(TitleLargeStyle()) }
    func headlineStyle() -> some View { modifier(HeadlineStyle()) }
    func bodyStyle() -> some View { modifier(BodyStyle()) }
    func captionStyle() -> some View { modifier(CaptionStyle()) }
}
