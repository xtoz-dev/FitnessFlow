import SwiftUI
import AVFoundation

struct NutritionView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showAdd = false
    @State private var showScanner = false
    var body: some View { NavigationStack { List { Section { HStack(spacing: 14) { NutritionRing(value: Double(store.caloriesToday) / 2400, label: "\(store.caloriesToday)", sublabel: "kcal"); MacroColumn(label: "Eiweiß", value: "\(Int(store.proteinToday)) g", color: .mint); MacroColumn(label: "Kohlenhydrate", value: "\(Int(store.carbsToday)) g", color: .orange); MacroColumn(label: "Fett", value: "\(Int(store.fatToday)) g", color: .pink) }.frame(maxWidth: .infinity) } header: { Text("Heute") }
        Section("Mahlzeiten") { if store.todayFoods.isEmpty { Text("Noch nichts eingetragen.").foregroundStyle(.secondary) } else { ForEach(store.todayFoods) { food in FoodRow(food: food) }.onDelete { offsets in let entries = store.todayFoods; for index in offsets { if let id = entries[safe: index]?.id { store.foods.removeAll { $0.id == id } } } } } }
    }.navigationTitle("Ernährung").toolbar { ToolbarItemGroup(placement: .topBarTrailing) { Button { showScanner = true } label: { Image(systemName: "barcode.viewfinder") }; Button { showAdd = true } label: { Image(systemName: "plus") } } }.sheet(isPresented: $showAdd) { AddFoodView() }.sheet(isPresented: $showScanner) { BarcodeScannerSheet() } } }
}

struct NutritionRing: View { let value: Double; let label: String; let sublabel: String
    var body: some View { ZStack { Circle().stroke(.quaternary, lineWidth: 9); Circle().trim(from: 0, to: min(value, 1)).stroke(.orange, style: StrokeStyle(lineWidth: 9, lineCap: .round)).rotationEffect(.degrees(-90)); VStack(spacing: 0) { Text(label).font(.headline.bold()); Text(sublabel).font(.caption2).foregroundStyle(.secondary) } }.frame(width: 84, height: 84) }
}
struct MacroColumn: View { let label: String; let value: String; let color: Color; var body: some View { VStack(spacing: 4) { Circle().fill(color).frame(width: 8); Text(value).font(.caption.bold()); Text(label).font(.caption2).foregroundStyle(.secondary).lineLimit(1) } } }
struct FoodRow: View { let food: FoodEntry; var body: some View { HStack { Image(systemName: "fork.knife").foregroundStyle(.mint).frame(width: 28); VStack(alignment: .leading) { Text(food.name); Text("\(food.amount.formatted()) \(food.unit) · E \(Int(food.protein)) g · KH \(Int(food.carbs)) g · F \(Int(food.fat)) g").font(.caption).foregroundStyle(.secondary) }; Spacer(); Text("\(food.calories)").font(.headline); Text("kcal").font(.caption).foregroundStyle(.secondary) } }

struct AddFoodView: View {
    @EnvironmentObject private var store: AppStore; @Environment(\.dismiss) private var dismiss
    @State private var description = ""; @State private var name = ""; @State private var amount = 100.0; @State private var unit = "g"; @State private var calories = 0; @State private var protein = 0.0; @State private var carbs = 0.0; @State private var fat = 0.0; @State private var hasEstimate = false
    var body: some View { NavigationStack { Form { Section("Schnell per KI schätzen") { TextField("z. B. 250 g Hähnchen mit Reis", text: $description); Button("Schätzung erstellen") { let estimated = FoodEstimator.estimate(description); name = estimated.name; amount = estimated.amount; unit = estimated.unit; calories = estimated.calories; protein = estimated.protein; carbs = estimated.carbs; fat = estimated.fat; hasEstimate = true } } footer: { Text("Die Werte sind nur eine Schätzung. Bitte prüfe sie vor dem Speichern.") }
        Section(hasEstimate ? "Geschätzte Werte – anpassbar" : "Manuell eintragen") { TextField("Lebensmittel", text: $name); HStack { TextField("Menge", value: $amount, format: .number.precision(.fractionLength(0...1))).keyboardType(.decimalPad); TextField("Einheit", text: $unit).frame(width: 55) }; TextField("Kalorien", value: $calories, format: .number).keyboardType(.numberPad); TextField("Eiweiß (g)", value: $protein, format: .number.precision(.fractionLength(1))).keyboardType(.decimalPad); TextField("Kohlenhydrate (g)", value: $carbs, format: .number.precision(.fractionLength(1))).keyboardType(.decimalPad); TextField("Fett (g)", value: $fat, format: .number.precision(.fractionLength(1))).keyboardType(.decimalPad) } }.navigationTitle("Mahlzeit hinzufügen").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Speichern") { guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }; store.addFood(FoodEntry(name: name, amount: amount, unit: unit, calories: calories, protein: protein, carbs: carbs, fat: fat)); dismiss() }; ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } } } } }
}

enum FoodEstimator {
    static func estimate(_ input: String) -> FoodEntry {
        let lower = input.lowercased(); let grams = extractNumber(lower) ?? 100
        let base: (String, Int, Double, Double, Double)
        if lower.contains("hähnchen") || lower.contains("chicken") { base = ("Hähnchenbrust", 165, 31, 0, 3.6) }
        else if lower.contains("reis") { base = ("Reis, gekocht", 130, 2.7, 28, 0.3) }
        else if lower.contains("hafer") { base = ("Haferflocken", 370, 13, 60, 7) }
        else if lower.contains("banane") { base = ("Banane", 89, 1.1, 23, 0.3) }
        else if lower.contains("protein") || lower.contains("shake") { base = ("Proteinshake", 120, 24, 4, 2) }
        else if lower.contains("brot") { base = ("Vollkornbrot", 230, 8, 43, 3) }
        else { base = (input.isEmpty ? "Mahlzeit" : input, 180, 8, 20, 7) }
        let multiplier = grams / 100
        return FoodEntry(name: base.0, amount: grams, unit: "g", calories: Int(Double(base.1) * multiplier), protein: base.2 * multiplier, carbs: base.3 * multiplier, fat: base.4 * multiplier)
    }
    private static func extractNumber(_ string: String) -> Double? { let value = string.split(whereSeparator: { !$0.isNumber && $0 != "." && $0 != "," }).first; return value.flatMap { Double(String($0).replacingOccurrences(of: ",", with: ".")) } }
}

struct BarcodeScannerSheet: View {
    @Environment(\.dismiss) private var dismiss; @State private var code: String?
    var body: some View { NavigationStack { VStack(spacing: 24) { BarcodeScanner { code = $0 }; if let code { VStack(spacing: 8) { Text("Barcode erkannt").font(.headline); Text(code).font(.title3.monospaced()).textSelection(.enabled); Text("Verbinde hier eine Lebensmittel-Datenbank, um Produktwerte automatisch zu laden.").multilineTextAlignment(.center).foregroundStyle(.secondary) } } else { Text("Halte den Barcode in den Rahmen.").foregroundStyle(.secondary) } }.padding().navigationTitle("Barcode scannen").toolbar { Button("Fertig") { dismiss() } } } }
}

struct BarcodeScanner: UIViewControllerRepresentable {
    let found: (String) -> Void
    func makeUIViewController(context: Context) -> ScannerController { let controller = ScannerController(); controller.found = found; return controller }
    func updateUIViewController(_ uiViewController: ScannerController, context: Context) {}
}
final class ScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var found: ((String) -> Void)?; private let session = AVCaptureSession()
    override func viewDidLoad() { super.viewDidLoad(); guard let device = AVCaptureDevice.default(for: .video), let input = try? AVCaptureDeviceInput(device: device), session.canAddInput(input) else { return }; session.addInput(input); let output = AVCaptureMetadataOutput(); guard session.canAddOutput(output) else { return }; session.addOutput(output); output.setMetadataObjectsDelegate(self, queue: .main); output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .qr]; let preview = AVCaptureVideoPreviewLayer(session: session); preview.videoGravity = .resizeAspectFill; preview.frame = view.layer.bounds; view.layer.addSublayer(preview); DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() } }
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) { guard let value = (metadataObjects.first as? AVMetadataMachineReadableCodeObject)?.stringValue else { return }; session.stopRunning(); found?(value) }
}

extension Collection { subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil } }
