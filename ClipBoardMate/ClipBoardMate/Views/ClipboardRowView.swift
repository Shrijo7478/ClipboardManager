import SwiftUI

struct ClipboardRowView: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onPinToggle: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: item.createdAt)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            preview

            VStack(alignment: .leading, spacing: 3) {
                if !previewText.isEmpty {
                    Text(previewText)
                        .font(.system(size: 13))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                }
                HStack(spacing: 5) {
                    typeBadge
                    Text(formattedDate)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isHovering {
                HStack(spacing: 10) {
                    actionButton(icon: "doc.on.doc", help: "Copy again", action: onCopy)
                    actionButton(
                        icon: item.pinned ? "pin.fill" : "pin",
                        help: item.pinned ? "Unpin" : "Pin",
                        action: onPinToggle,
                        tint: item.pinned ? .orange : .secondary
                    )
                    actionButton(icon: "trash", help: "Delete", action: onDelete, tint: .red)
                }
                .transition(.opacity)
            }
        }
        .padding(10)
        .background(
            Color.white.opacity(isHovering ? 0.12 : 0.0),
            in: .rect(cornerRadius: 10)
        )
        .contentShape(Rectangle())
        .onTapGesture { onCopy() }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
    }

    private func actionButton(icon: String, help: String, action: @escaping () -> Void, tint: Color = .secondary) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(tint)
                .padding(6)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private var typeBadge: some View {
        Circle()
            .fill(item.isImage ? Color.blue.opacity(0.7) : Color.green.opacity(0.7))
            .frame(width: 5, height: 5)
    }

    private var preview: some View {
        Group {
            if item.isImage, let image = item.imageThumbnail {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "doc.text")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    )
            }
        }
    }

    private var previewText: String {
        if item.isText {
            return item.textContent ?? ""
        }
        
        if item.isImage {
            return item.fileName ?? ""
        }
        
        return ""
    }
}
