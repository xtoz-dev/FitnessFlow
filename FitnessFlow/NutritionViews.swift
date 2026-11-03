import SwiftUI
import AVFoundation

struct NutritionView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAddFood = false
    @State private var showingScanner = false

    var body: some View {
        NavigationStack {
            List {
                Section("Heute") {
                    HStack(spacing: 14) {
                        NutritionRing(value: Double(store.caloriesToday) / 2400, label: "\(store.caloriesToday)", sublabel: "kcal")
                        MacroColumn(label: "Eiweiß", value: "\(Int(store.proteinToday)) g", color: .mint)
                        MacroColumn(label: "Kohlenhydrate", value: "\(Int(store.carbsToday)) g", color: .orange)
                        MacroColumn(label: "Fett", value: "\(Int(store.fatToday)) g", color: .pink)
                    }
                    .frame(maxWidth: .infinity)
                }

                Section("Mahlzeiten") {
                    if store.todayFoods.isEmpty {
                        Text("Noch nichts eingetragen.").foregroundStyle(.secondary)
                    } else {
                        ForEach(store.todayFoods) { food in
                            FoodRow(food: food)
                        }
                        .onDelete { offsets in
                            let entries = store.todayFoods
                            for index in offsets {
                                guard let id = entries[safe: index]?.id else { continue }
                                store.foods.removeAll { $0.id == id }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ernährung")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showingScanner = true } label: { Image(systemName: "barcode.viewfinder") }
                    Button { showingAddFood = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAddFood) { AddFoodView() }
            .sheet(isPresented: $showingScanner) { BarcodeScannerSheet() }
        }
    }
}

struct NutritionRing: View {
    let value: Double
    let label: String
    let sublabel: String

    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 9)
            Circle()
                .trim(from: 0, to: min(value, 1))
                .stroke(.orange, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(label).font(.headline.bold())
                Text(sublabel).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(width: 84, height: 84)
    }
}

struct MacroColumn: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(value).font(.caption.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
    }
}

struct FoodRow: View {
    let food: FoodEntry

    var body: some View {
        HStack {
            Image(systemName: "fork.knife").foregroundStyle(.mint).frame(width: 28)
            VStack(alignment: .leading) {
                Text(food.name)
                Text("\(food.amount.formatted()) \(food.unit) · E \(Int(food.protein)) g · KH \(Int(food.carbs)) g · F \(Int(food.fat)) g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(food.calories)").font(.headline)
            Text("kcal").font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct AddFoodView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @State private var foodName = ""
    @State private var amount = 100.0
    @State private var calories = 0
    @State private var protein = 0.0
    @State private var carbs = 0.0
    @State private var fat = 0.0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("z. B. 250 g Hähnchen mit Reis", text: $input)
                    Button("Schätzung erstellen") {
                        let estimate = FoodEstimator.estimate(input)
                        foodName = estimate.name
                        amount = estimate.amount
                        calories = estimate.calories
                        protein = estimate.protein
                        carbs = estimate.carbs
                        fat = estimate.fat
                    }
                } header: {
                    Text("Schnell per KI schätzen")
                } footer: {
                    Text("Die Werte sind nur eine Schätzung. Bitte prüfe sie vor dem Speichern.")
                }

                Section("Werte") {
                    TextField("Lebensmittel", text: $foodName)
                    TextField("Menge (g)", value: $amount, format: .number).keyboardType(.decimalPad)
                    TextField("Kalorien", value: $calories, format: .number).keyboardType(.numberPad)
                    TextField("Eiweiß (g)", value: $protein, format: .number).keyboardType(.decimalPad)
                    TextField("Kohlenhydrate (g)", value: $carbs, format: .number).keyboardType(.decimalPad)
                    TextField("Fett (g)", value: $fat, format: .number).keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Mahlzeit hinzufügen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        guard !foodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        store.addFood(FoodEntry(name: foodName, amount: amount, unit: "g", calories: calories, protein: protein, carbs: carbs, fat: fat))
                        dismiss()
                    }
                }
            }
        }
    }
}

enum FoodEstimator {
    static func estimate(_ input: String) -> FoodEntry {
        let lower = input.lowercased()
        let amount = extractNumber(lower) ?? 100
        let base: (String, Int, Double, Double, Double)
        if lower.contains("hähnchen") || lower.contains("chicken") {
            base = ("Hähnchenbrust", 165, 31, 0, 3.6)
        } else if lower.contains("reis") {
            base = ("Reis, gekocht", 130, 2.7, 28, 0.3)
        } else if lower.contains("hafer") {
            base = ("Haferflocken", 370, 13, 60, 7)
        } else if lower.contains("banane") {
            base = ("Banane", 89, 1.1, 23, 0.3)
        } else if lower.contains("protein") || lower.contains("shake") {
            base = ("Proteinshake", 120, 24, 4, 2)
        } else {
            base = (input.isEmpty ? "Mahlzeit" : input, 180, 8, 20, 7)
        }

        let multiplier = amount / 100
        return FoodEntry(name: base.0, amount: amount, unit: "g", calories: Int(Double(base.1) * multiplier), protein: base.2 * multiplier, carbs: base.3 * multiplier, fat: base.4 * multiplier)
    }

    private static func extractNumber(_ string: String) -> Double? {
        let token = string.split(whereSeparator: { !$0.isNumber && $0 != "." && $0 != "," }).first
        return token.flatMap { Double(String($0).replacingOccurrences(of: ",", with: ".")) }
    }
}

struct BarcodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var manualBarcode = ""

    var body: some View {
        NavigationStack {
            Group {
                if let scannedCode {
                    ProductEntryView(barcode: scannedCode) { dismiss() }
                } else {
                    VStack(spacing: 16) {
                        BarcodeScanner { scannedCode = $0 }
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .frame(height: 280)
                        Text("Halte einen EAN-/UPC-Barcode in den Kamerarahmen.")
                            .foregroundStyle(.secondary)
                        HStack {
                            TextField("Barcode manuell eingeben", text: $manualBarcode)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            Button("Weiter") {
                                let value = manualBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !value.isEmpty { scannedCode = value }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.mint)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Produkt scannen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

struct ProductEntryView: View {
    @EnvironmentObject private var store: AppStore
    let barcode: String
    let completed: () -> Void
    @State private var name = ""
    @State private var amount = 100.0
    @State private var caloriesPer100g = 0.0
    @State private var proteinPer100g = 0.0
    @State private var carbsPer100g = 0.0
    @State private var fatPer100g = 0.0
    @State private var loaded = false

    private var factor: Double { amount / 100 }
    private var calories: Int { Int((caloriesPer100g * factor).rounded()) }

    var body: some View {
        Form {
            Section {
                Text(barcode).font(.caption.monospaced()).foregroundStyle(.secondary)
                TextField("Produktname", text: $name)
            } header: {
                Text("Produkt")
            } footer: {
                Text("Gespeicherte Produkte werden beim nächsten Scan desselben Barcodes sofort wiederverwendet.")
            }

            Section("Nährwerte pro 100 g") {
                TextField("Kalorien", value: $caloriesPer100g, format: .number).keyboardType(.decimalPad)
                TextField("Eiweiß (g)", value: $proteinPer100g, format: .number).keyboardType(.decimalPad)
                TextField("Kohlenhydrate (g)", value: $carbsPer100g, format: .number).keyboardType(.decimalPad)
                TextField("Fett (g)", value: $fatPer100g, format: .number).keyboardType(.decimalPad)
            }

            Section("Deine Menge") {
                TextField("Gramm", value: $amount, format: .number).keyboardType(.decimalPad)
                LabeledContent("Kalorien für diese Portion", value: "\(calories) kcal")
                LabeledContent("Eiweiß", value: String(format: "%.1f g", proteinPer100g * factor))
                LabeledContent("Kohlenhydrate", value: String(format: "%.1f g", carbsPer100g * factor))
                LabeledContent("Fett", value: String(format: "%.1f g", fatPer100g * factor))
            }

            Section {
                Button("Produkt speichern & Mahlzeit hinzufügen") {
                    guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, amount > 0 else { return }
                    let product = SavedFoodProduct(
                        barcode: barcode,
                        name: name,
                        caloriesPer100g: caloriesPer100g,
                        proteinPer100g: proteinPer100g,
                        carbsPer100g: carbsPer100g,
                        fatPer100g: fatPer100g
                    )
                    store.saveProduct(product)
                    store.addFood(FoodEntry(
                        name: name,
                        amount: amount,
                        unit: "g",
                        calories: calories,
                        protein: proteinPer100g * factor,
                        carbs: carbsPer100g * factor,
                        fat: fatPer100g * factor
                    ))
                    completed()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
        }
        .navigationTitle("Nährwerte")
        .onAppear {
            guard !loaded else { return }
            loaded = true
            guard let product = store.product(for: barcode) else { return }
            name = product.name
            caloriesPer100g = product.caloriesPer100g
            proteinPer100g = product.proteinPer100g
            carbsPer100g = product.carbsPer100g
            fatPer100g = product.fatPer100g
        }
    }
}

struct BarcodeScanner: UIViewControllerRepresentable {
    let found: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerController {
        let controller = ScannerController()
        controller.found = found
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerController, context: Context) {}
}

final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var found: ((String) -> Void)?
    private let session = AVCaptureSession()

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }

        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.addSublayer(preview)
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let value = (metadataObjects.first as? AVMetadataMachineReadableCodeObject)?.stringValue else { return }
        session.stopRunning()
        found?(value)
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
