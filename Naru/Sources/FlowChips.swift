import SwiftUI

struct FlowChips: View {
    let choices: [String]
    @Binding var selected: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(choices, id: \.self) { choice in
                    Button {
                        selected = selected == choice ? nil : choice
                    } label: {
                        Text(choice)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(selected == choice ? Color(.systemBackground) : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(
                                selected == choice ? Color.primary : Color(.systemGray6),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
