import SwiftUI

struct PopoverShape: Shape {
    var cornerRadius: CGFloat = 12
    var arrowWidth: CGFloat = 24
    var arrowHeight: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        let bodyTop = rect.minY + arrowHeight
        let arrowMidX = rect.midX

        return Path { p in
            // Start at top-left corner of body
            p.move(to: CGPoint(x: rect.minX, y: bodyTop + cornerRadius))
            p.addArc(
                center: CGPoint(x: rect.minX + cornerRadius, y: bodyTop + cornerRadius),
                radius: cornerRadius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
            )

            // Line to arrow left
            p.addLine(to: CGPoint(x: arrowMidX - arrowWidth / 2, y: bodyTop))
            // Arrow tip
            p.addLine(to: CGPoint(x: arrowMidX, y: rect.minY))
            p.addLine(to: CGPoint(x: arrowMidX + arrowWidth / 2, y: bodyTop))

            // Top-right corner
            p.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: bodyTop))
            p.addArc(
                center: CGPoint(x: rect.maxX - cornerRadius, y: bodyTop + cornerRadius),
                radius: cornerRadius, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false
            )

            // Bottom-right corner
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
            p.addArc(
                center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                radius: cornerRadius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false
            )

            // Bottom-left corner
            p.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
            p.addArc(
                center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                radius: cornerRadius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
            )

            p.closeSubpath()
        }
    }
}

struct ContentView: View {
    @Bindable var store: ProjectStore

    var body: some View {
        Group {
            if store.projects.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Waiting for notifications...")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Notifications will appear here when Claude Code sessions send hooks.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(store.projects) { project in
                            ProjectColumnView(project: project, store: store)
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(.regular.interactive(), in: PopoverShape())
    }
}
