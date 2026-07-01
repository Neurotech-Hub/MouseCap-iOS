//
//  ParameterInputViews.swift
//  MouseCap
//

import SwiftUI
import UIKit

struct DecimalPadTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isEditing: Bool
    var onCommit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .decimalPad
        textField.borderStyle = .roundedRect
        textField.delegate = context.coordinator
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )
        textField.inputAccessoryView = Self.makeToolbar(coordinator: context.coordinator)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        if uiView.text != text {
            uiView.text = text
        }
    }

    private static func makeToolbar(coordinator: Coordinator) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: coordinator,
            action: #selector(Coordinator.doneTapped)
        )
        toolbar.items = [spacer, done]
        return toolbar
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: DecimalPadTextField

        init(_ parent: DecimalPadTextField) {
            self.parent = parent
        }

        @objc func textChanged(_ sender: UITextField) {
            parent.text = sender.text ?? ""
        }

        @objc func doneTapped() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isEditing = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isEditing = false
            parent.onCommit()
        }
    }
}

enum StimulationMode: String, CaseIterable {
    case continuous = "Continuous"
    case burst = "Burst"
}

enum TimeUnit: String, CaseIterable {
    case milliseconds = "ms"
    case seconds = "s"
    case minutes = "min"

    func toMilliseconds(_ value: Double) -> Double {
        switch self {
        case .milliseconds: return value
        case .seconds: return value * 1000
        case .minutes: return value * 60_000
        }
    }

    func fromMilliseconds(_ ms: Double) -> Double {
        switch self {
        case .milliseconds: return ms
        case .seconds: return ms / 1000
        case .minutes: return ms / 60_000
        }
    }

    func toSeconds(_ value: Double) -> Double {
        switch self {
        case .milliseconds: return value / 1000
        case .seconds: return value
        case .minutes: return value * 60
        }
    }

    func fromSeconds(_ seconds: Double) -> Double {
        switch self {
        case .milliseconds: return seconds * 1000
        case .seconds: return seconds
        case .minutes: return seconds / 60
        }
    }
}

struct NumericParameterRow: View {
    let label: String
    @Binding var baseValue: Double
    let allowedUnits: [TimeUnit]
    let storageUnit: TimeUnit
    let minBaseValue: Double
    let maxBaseValue: Double
    var onValueChanged: () -> Void

    @State private var selectedUnit: TimeUnit
    @State private var textValue: String = ""
    @State private var isEditing = false

    init(
        label: String,
        baseValue: Binding<Double>,
        allowedUnits: [TimeUnit],
        storageUnit: TimeUnit,
        minBaseValue: Double,
        maxBaseValue: Double,
        defaultDisplayUnit: TimeUnit,
        onValueChanged: @escaping () -> Void
    ) {
        self.label = label
        self._baseValue = baseValue
        self.allowedUnits = allowedUnits
        self.storageUnit = storageUnit
        self.minBaseValue = minBaseValue
        self.maxBaseValue = maxBaseValue
        self.onValueChanged = onValueChanged
        self._selectedUnit = State(initialValue: defaultDisplayUnit)
    }

    private var displayValue: Double {
        baseToDisplay(baseValue)
    }

    private var formattedDisplay: String {
        let value = displayValue
        if selectedUnit == .milliseconds {
            return String(format: "%.0f %@", value, selectedUnit.rawValue)
        } else if selectedUnit == .minutes {
            return String(format: "%.2f %@", value, selectedUnit.rawValue)
        } else {
            return String(format: "%.1f %@", value, selectedUnit.rawValue)
        }
    }

    private var stepAmount: Double {
        switch selectedUnit {
        case .milliseconds: return 100
        case .seconds: return 1
        case .minutes: return 1
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(label): \(formattedDisplay)")
                .font(.subheadline)

            HStack(spacing: 8) {
                DecimalPadTextField(
                    text: $textValue,
                    isEditing: $isEditing,
                    onCommit: commitTextValue
                )
                .frame(width: 80, height: 34)

                Stepper("", value: Binding(
                    get: { displayValue },
                    set: { setFromDisplay($0) }
                ), in: displayMin...displayMax, step: stepAmount)
                .labelsHidden()

                if allowedUnits.count > 1 {
                    Picker("Unit", selection: $selectedUnit) {
                        ForEach(allowedUnits, id: \.self) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 140)
                    .onChange(of: selectedUnit) { _, _ in
                        syncTextFromBase()
                    }
                }
            }
        }
        .padding(.top, 8)
        .onAppear { syncTextFromBase() }
        .onChange(of: baseValue) { _, _ in
            if !isEditing { syncTextFromBase() }
        }
    }

    private var displayMin: Double { baseToDisplay(minBaseValue) }
    private var displayMax: Double { baseToDisplay(maxBaseValue) }

    private func baseToDisplay(_ base: Double) -> Double {
        switch (storageUnit, selectedUnit) {
        case (.milliseconds, .milliseconds), (.seconds, .seconds): return base
        case (.milliseconds, .seconds): return base / 1000
        case (.milliseconds, .minutes): return base / 60_000
        case (.seconds, .minutes): return base / 60
        case (.seconds, .milliseconds): return base * 1000
        default: return base
        }
    }

    private func displayToBase(_ display: Double) -> Double {
        switch (storageUnit, selectedUnit) {
        case (.milliseconds, .milliseconds), (.seconds, .seconds): return display
        case (.milliseconds, .seconds): return display * 1000
        case (.milliseconds, .minutes): return display * 60_000
        case (.seconds, .minutes): return display * 60
        case (.seconds, .milliseconds): return display / 1000
        default: return display
        }
    }

    private func syncTextFromBase() {
        let value = displayValue
        if selectedUnit == .milliseconds {
            textValue = String(format: "%.0f", value)
        } else if selectedUnit == .minutes {
            textValue = String(format: "%.2f", value)
        } else {
            textValue = String(format: "%.1f", value)
        }
    }

    private func commitTextValue() {
        guard let parsed = Double(textValue) else {
            syncTextFromBase()
            return
        }
        setFromDisplay(parsed)
        syncTextFromBase()
    }

    private func setFromDisplay(_ display: Double) {
        let clampedDisplay = min(max(display, displayMin), displayMax)
        let clampedBase = min(max(displayToBase(clampedDisplay), minBaseValue), maxBaseValue)
        if clampedBase != baseValue {
            baseValue = clampedBase
            onValueChanged()
        }
    }
}

struct SharedStimulationControlsView: View {
    @Binding var amplitude: Double
    @Binding var pulseDuration: Double
    var ignoreChanges: Bool
    var onValueChanged: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("OFF")
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                let maxValue: Double = 600
                let calculatedValue: Double = (amplitude / 100) * maxValue

                VStack(alignment: .leading, spacing: 4) {
                    Text("Amplitude: \(amplitude, specifier: "%.0f")% (\(calculatedValue, specifier: "%.0f") µA @ 1kΩ)")

                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                        Text("Charge balancing is ON")
                    }
                }

                Spacer()
            }

            Slider(value: $amplitude, in: 0...100, step: 1)
                .accentColor(.mint)
                .onChange(of: amplitude) {
                    if !ignoreChanges { onValueChanged() }
                }
        }
        .padding(.top, 4)

        VStack {
            Text("Pulse Duration: \(pulseDuration, specifier: "%.0f") μs")
            Slider(value: $pulseDuration, in: 90...600, step: 30)
                .accentColor(.purple)
                .onChange(of: pulseDuration) {
                    if !ignoreChanges { onValueChanged() }
                }
        }
        .padding(.top, 4)
    }
}

struct ContinuousControlsView: View {
    @Binding var frequency: Double
    var ignoreChanges: Bool
    var onValueChanged: () -> Void

    var body: some View {
        VStack {
            Text("Frequency: \(frequency, specifier: "%.0f") Hz")
            Slider(value: $frequency, in: 80...160, step: 5)
                .accentColor(.cyan)
                .onChange(of: frequency) {
                    if !ignoreChanges { onValueChanged() }
                }
        }
        .padding(.top)
    }
}

struct BurstControlsView: View {
    @Binding var burstPeriodMs: Double
    @Binding var intraBurstFrequency: Double
    @Binding var burstDurationMs: Double
    var ignoreChanges: Bool
    var onValueChanged: () -> Void

    private var burstsMayRunContinuously: Bool {
        burstDurationMs > burstPeriodMs
    }

    var body: some View {
        NumericParameterRow(
            label: "Burst Period",
            baseValue: $burstPeriodMs,
            allowedUnits: [.milliseconds, .seconds, .minutes],
            storageUnit: .milliseconds,
            minBaseValue: 1,
            maxBaseValue: 3_600_000,
            defaultDisplayUnit: .seconds,
            onValueChanged: {
                if !ignoreChanges { onValueChanged() }
            }
        )

        VStack {
            Text("Intra-burst Frequency: \(intraBurstFrequency, specifier: "%.0f") Hz")
            Slider(value: $intraBurstFrequency, in: 80...160, step: 5)
                .accentColor(.cyan)
                .onChange(of: intraBurstFrequency) {
                    if !ignoreChanges { onValueChanged() }
                }
        }
        .padding(.top)

        NumericParameterRow(
            label: "Burst Duration",
            baseValue: $burstDurationMs,
            allowedUnits: [.milliseconds, .seconds, .minutes],
            storageUnit: .milliseconds,
            minBaseValue: 1,
            maxBaseValue: 120_000,
            defaultDisplayUnit: .seconds,
            onValueChanged: {
                if !ignoreChanges { onValueChanged() }
            }
        )

        if burstsMayRunContinuously {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Burst duration is longer than burst period. Stimulation may run continuously.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.top, 6)
        }
    }
}
