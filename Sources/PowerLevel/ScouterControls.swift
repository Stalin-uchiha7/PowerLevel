import SwiftUI

/// Outlined green HUD button. Fills solid while pressed.
struct ScouterButtonStyle: ButtonStyle {
    var tint: Color = Scouter.green
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        configuration.label
            .font(.system(size: compact ? 10 : 11, weight: .semibold, design: .monospaced))
            .textCase(.uppercase)
            .foregroundStyle(configuration.isPressed ? Scouter.background : tint)
            .padding(.horizontal, compact ? 6 : 10)
            .padding(.vertical, compact ? 2 : 4)
            .background(shape.fill(configuration.isPressed ? tint : tint.opacity(0.08)))
            .overlay(shape.strokeBorder(tint.opacity(0.7), lineWidth: 1))
            .contentShape(Rectangle())
    }
}

/// Segmented choice: the selected cell is solid green with dark text.
struct ScouterSegmented<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(label: String, value: Value)]

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 3)
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                cell(options[i].label, options[i].value)
                if i < options.count - 1 {
                    Rectangle().fill(Scouter.green.opacity(0.4)).frame(width: 1)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Scouter.green.opacity(0.7), lineWidth: 1))
    }

    private func cell(_ label: String, _ value: Value) -> some View {
        let selected = value == selection
        return Button { selection = value } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(selected ? Scouter.background : Scouter.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(selected ? Scouter.green : Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Square HUD switch with an ON / OFF readout.
struct ScouterToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        let on = configuration.isOn
        return Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 6) {
                Text(on ? "ON" : "OFF")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(on ? Scouter.green : Scouter.dim)
                    .frame(width: 26, alignment: .trailing)
                ZStack(alignment: on ? .trailing : .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(on ? Scouter.green.opacity(0.22) : Color.clear)
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Scouter.green.opacity(on ? 0.9 : 0.45), lineWidth: 1)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(on ? Scouter.green : Scouter.green.opacity(0.4))
                        .frame(width: 14, height: 12)
                        .padding(3)
                }
                .frame(width: 36, height: 18)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
