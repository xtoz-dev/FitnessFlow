import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var plan: TrainingPlan { didSet { save(plan, key: "plan") } }
    @Published var sessions: [WorkoutSession] { didSet { save(sessions, key: "sessions") } }
    @Published var foods: [FoodEntry] { didSet { save(foods, key: "foods") } }
    @Published var savedProducts: [SavedFoodProduct] { didSet { save(savedProducts, key: "savedProducts") } }
    @Published var weights: [WeightEntry] { didSet { save(weights, key: "weights") } }
    @Published var cardio: [CardioEntry] { didSet { save(cardio, key: "cardio") } }
    @Published var currentSession: WorkoutSession?
    private let encoder = JSONEncoder()

    init() {
        plan = Self.load("plan") ?? Self.makePlan(days: 5)
        sessions = Self.load("sessions") ?? []
        foods = Self.load("foods") ?? []
        savedProducts = Self.load("savedProducts") ?? []
        weights = Self.load("weights") ?? []
        cardio = Self.load("cardio") ?? []
    }
    func changePlan(to days: Int) { plan = Self.makePlan(days: days) }
    func start(day: PlanDay) { currentSession = WorkoutSession(title: day.title, exercises: day.exercises.map { WorkoutExercise(exercise: $0, sets: (0..<3).map { _ in SetLog(weight: 0, reps: 10) }) }) }
    func finishCurrentSession() { if let currentSession { sessions.insert(currentSession, at: 0) }; currentSession = nil }
    func addFood(_ item: FoodEntry) { foods.insert(item, at: 0) }
    func saveProduct(_ product: SavedFoodProduct) {
        savedProducts.removeAll { $0.barcode == product.barcode }
        savedProducts.insert(product, at: 0)
    }
    func product(for barcode: String) -> SavedFoodProduct? { savedProducts.first { $0.barcode == barcode } }
    func addWeight(_ value: Double) { weights.insert(WeightEntry(weightKG: value), at: 0) }
    var todayFoods: [FoodEntry] { foods.filter { Calendar.current.isDateInToday($0.date) } }
    var caloriesToday: Int { todayFoods.reduce(0) { $0 + $1.calories } }
    var proteinToday: Double { todayFoods.reduce(0) { $0 + $1.protein } }
    var carbsToday: Double { todayFoods.reduce(0) { $0 + $1.carbs } }
    var fatToday: Double { todayFoods.reduce(0) { $0 + $1.fat } }
    private func save<T: Encodable>(_ value: T, key: String) { if let data = try? encoder.encode(value) { UserDefaults.standard.set(data, forKey: key) } }
    private static func load<T: Decodable>(_ key: String) -> T? { guard let d = UserDefaults.standard.data(forKey: key) else { return nil }; return try? JSONDecoder().decode(T.self, from: d) }
    static func makePlan(days: Int) -> TrainingPlan {
        let c = Exercise.catalog
        func pick(_ names: [String]) -> [Exercise] { c.filter { names.contains($0.name) } }
        let all: [PlanDay]
        switch days {
        case 3: all = [PlanDay(title: "Ganzkörper A", groups: [.brust,.ruecken,.beine], exercises: pick(["Bankdrücken","Kabelrudern","Kniebeugen","Cable Crunch"])), PlanDay(title: "Ganzkörper B", groups: [.schultern,.ruecken,.gesaess], exercises: pick(["Schulterdrücken","Latzug","Rumänisches Kreuzheben","Bizeps-Curls"])), PlanDay(title: "Ganzkörper C", groups: [.brust,.beine,.trizeps], exercises: pick(["Schrägbank-Kurzhanteldrücken","Beinpresse","Trizepsdrücken","Wadenheben"]))]
        case 4: all = [PlanDay(title: "Oberkörper A", groups: [.brust,.ruecken,.schultern], exercises: pick(["Bankdrücken","Kabelrudern","Schulterdrücken","Bizeps-Curls"])), PlanDay(title: "Unterkörper A", groups: [.beine,.gesaess,.waden], exercises: pick(["Kniebeugen","Rumänisches Kreuzheben","Wadenheben","Cable Crunch"])), PlanDay(title: "Oberkörper B", groups: [.brust,.ruecken,.trizeps], exercises: pick(["Schrägbank-Kurzhanteldrücken","Latzug","Seitheben","Trizepsdrücken"])), PlanDay(title: "Unterkörper B", groups: [.beine,.gesaess,.bauch], exercises: pick(["Beinpresse","Rumänisches Kreuzheben","Wadenheben","Cable Crunch"]))]
        default: all = [PlanDay(title: "Push", groups: [.brust,.schultern,.trizeps], exercises: pick(["Bankdrücken","Schrägbank-Kurzhanteldrücken","Schulterdrücken","Trizepsdrücken"])), PlanDay(title: "Pull", groups: [.ruecken,.bizeps], exercises: pick(["Klimmzüge","Kabelrudern","Latzug","Bizeps-Curls"])), PlanDay(title: "Beine", groups: [.beine,.gesaess,.waden], exercises: pick(["Kniebeugen","Rumänisches Kreuzheben","Beinpresse","Wadenheben"])), PlanDay(title: "Oberkörper Fokus", groups: [.brust,.ruecken,.schultern], exercises: pick(["Schrägbank-Kurzhanteldrücken","Kabelrudern","Seitheben","Trizepsdrücken"])), PlanDay(title: "Unterkörper & Core", groups: [.beine,.gesaess,.bauch], exercises: pick(["Beinpresse","Rumänisches Kreuzheben","Cable Crunch","Wadenheben"]))]
        }
        return TrainingPlan(daysPerWeek: days, days: all)
    }
}
