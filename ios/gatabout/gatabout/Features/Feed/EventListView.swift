import SwiftUI

struct EventListView: View {
    let events: [EventEdge]
    let hasMorePages: Bool
    let onLoadMore: () async -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Sizes.spacing12) {
                ForEach(events) { edge in
                    EventCardView(edge: edge)
                }

                if hasMorePages {
                    ProgressView()
                        .padding(Sizes.padding16)
                        .task {
                            await onLoadMore()
                        }
                }
            }
            .padding(.horizontal, Sizes.padding16)
            .padding(.vertical, Sizes.padding8)
        }
    }
}
