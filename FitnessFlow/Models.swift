import Foundation

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case brust = "Brust", ruecken = "Rücken", schultern = "Schultern", bizeps = "Bizeps", trizeps = "Trizeps", beine = "Beine", gesaess = "Gesäß", bauch = "Bauch", waden = "Waden", ganzkoerper = "Ganzkörper"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .brust: return "heart.fill"
        case .ruecken: return "figure.strengthtraining.traditional"
        case .schultern: return "figure.arms.open"
        case .bizeps, .trizeps: return "dumbbell.fill"
        case .beine, .gesaess: return "figure.walk"
        case .bauch: return "figure.core.training"
        case .waden: return "figure.run"
        case .ganzkoerper: return "figure.mixed.cardio"
        }
    }
}

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var group: MuscleGroup
    var secondary: String
    var equipment: String
    var instructions: String
    var commonMistake: String
    init(id: UUID = UUID(), name: String, group: MuscleGroup, secondary: String, equipment: String, instructions: String, commonMistake: String) {
        self.id = id; self.name = name; self.group = group; self.secondary = secondary; self.equipment = equipment; self.instructions = instructions; self.commonMistake = commonMistake
    }
}

struct SetLog: Identifiable, Codable, Hashable {
    var id = UUID()
    var weight: Double
    var reps: Int
    var done: Bool = false
    var volume: Double { weight * Double(reps) }
}

struct WorkoutExercise: Identifiable, Codable, Hashable {
    var id = UUID()
    var exercise: Exercise
    var sets: [SetLog]
}

struct WorkoutSession: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    var title: String
    var exercises: [WorkoutExercise]
    var durationSeconds: Int = 0
    var notes = ""
    var volume: Double { exercises.flatMap(\.sets).filter(\.done).reduce(0) { $0 + $1.volume } }
    var completedSets: Int { exercises.flatMap(\.sets).filter(\.done).count }
    var calories: Int { max(80, Int(Double(durationSeconds) / 60 * 6.2)) }
}

struct FoodEntry: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: Double
    var unit: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var date = Date()
}

struct WeightEntry: Identifiable, Codable {
    var id = UUID()
    var weightKG: Double
    var date = Date()
}

struct SavedFoodProduct: Identifiable, Codable, Hashable {
    var id = UUID()
    var barcode: String
    var name: String
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
}

enum CardioKind: String, CaseIterable, Codable, Identifiable { case laufen = "Laufen", radfahren = "Radfahren", sonstiges = "Sonstiges"; var id: String { rawValue } }
struct CardioEntry: Identifiable, Codable {
    var id = UUID()
    var kind: CardioKind
    var durationMinutes: Int
    var distanceKM: Double
    var calories: Int
    var date = Date()
}

struct PlanDay: Identifiable, Codable {
    var id = UUID()
    var title: String
    var groups: [MuscleGroup]
    var exercises: [Exercise]
}

struct TrainingPlan: Codable {
    var daysPerWeek: Int
    var days: [PlanDay]
}

extension Exercise {
    static let catalog: [Exercise] = [
        Exercise(name: "Bankdrücken", group: .brust, secondary: "Trizeps, Schultern", equipment: "Langhantel", instructions: "Schulterblätter zurückziehen, Stange kontrolliert zur Brust senken und kraftvoll drücken.", commonMistake: "Ellbogen extrem weit nach außen stellen."),
        Exercise(name: "Schrägbank-Kurzhanteldrücken", group: .brust, secondary: "Schultern, Trizeps", equipment: "Kurzhanteln", instructions: "Bank leicht schräg einstellen und Hanteln kontrolliert nach oben führen.", commonMistake: "Zu steile Bank wählen."),
        Exercise(name: "Klimmzüge", group: .ruecken, secondary: "Bizeps", equipment: "Klimmzugstange", instructions: "Brust zur Stange ziehen, aus den Schulterblättern arbeiten.", commonMistake: "Nur mit Schwung arbeiten."),
        Exercise(name: "Latzug", group: .ruecken, secondary: "Bizeps", equipment: "Kabelzug", instructions: "Stange zur oberen Brust ziehen, Oberkörper stabil halten.", commonMistake: "Stange hinter den Nacken ziehen."),
        Exercise(name: "Kabelrudern", group: .ruecken, secondary: "Bizeps, hintere Schulter", equipment: "Kabelzug", instructions: "Griff zum Bauchnabel ziehen, Schulterblätter zusammenführen.", commonMistake: "Rücken stark vor und zurück schaukeln."),
        Exercise(name: "Kniebeugen", group: .beine, secondary: "Gesäß, Bauch", equipment: "Langhantel", instructions: "Rumpf anspannen, Knie folgen den Fußspitzen, kontrolliert tief beugen.", commonMistake: "Knie nach innen kollabieren lassen."),
        Exercise(name: "Beinpresse", group: .beine, secondary: "Gesäß", equipment: "Maschine", instructions: "Füße schulterbreit platzieren und mit voller Kontrolle drücken.", commonMistake: "Becken am unteren Punkt abheben."),
        Exercise(name: "Rumänisches Kreuzheben", group: .gesaess, secondary: "Beinbeuger, Rücken", equipment: "Langhantel", instructions: "Hüfte nach hinten schieben, Rücken neutral halten.", commonMistake: "Rücken rund werden lassen."),
        Exercise(name: "Schulterdrücken", group: .schultern, secondary: "Trizeps", equipment: "Kurzhanteln", instructions: "Hanteln kontrolliert über Kopf drücken, Rumpf fest.", commonMistake: "Zu stark ins Hohlkreuz gehen."),
        Exercise(name: "Seitheben", group: .schultern, secondary: "Trapez", equipment: "Kurzhanteln", instructions: "Arme leicht gebeugt seitlich bis Schulterhöhe heben.", commonMistake: "Mit Schwung aus dem Rücken arbeiten."),
        Exercise(name: "Bizeps-Curls", group: .bizeps, secondary: "Unterarme", equipment: "Kurzhanteln", instructions: "Ellbogen nah am Körper halten und Gewicht langsam senken.", commonMistake: "Ellbogen nach vorn schieben."),
        Exercise(name: "Trizepsdrücken", group: .trizeps, secondary: "", equipment: "Kabelzug", instructions: "Ellbogen fixieren und Griff nach unten strecken.", commonMistake: "Schultern mitbewegen."),
        Exercise(name: "Cable Crunch", group: .bauch, secondary: "", equipment: "Kabelzug", instructions: "Wirbelsäule kontrolliert einrollen und Bauch aktiv anspannen.", commonMistake: "Nur aus der Hüfte beugen."),
        Exercise(name: "Wadenheben", group: .waden, secondary: "", equipment: "Maschine", instructions: "Über den ganzen Bewegungsradius langsam heben und senken.", commonMistake: "Kurze, federnde Wiederholungen."),
    ]
}
