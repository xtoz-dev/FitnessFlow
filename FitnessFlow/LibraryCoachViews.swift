import SwiftUI

struct ExerciseLibraryView: View {
    @State private var query = ""; @State private var group: MuscleGroup?
    private var filtered: [Exercise] { Exercise.catalog.filter { (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)) && (group == nil || $0.group == group) } }
    var body: some View { NavigationStack { List { Section { ScrollView(.horizontal, showsIndicators: false) { HStack { FilterPill(title: "Alle", selected: group == nil) { group = nil }; ForEach(MuscleGroup.allCases) { g in FilterPill(title: g.rawValue, selected: group == g) { group = g } } }.padding(.vertical, 4) }.listRowInsets(EdgeInsets()) } ; ForEach(filtered) { exercise in NavigationLink { ExerciseDetailView(exercise: exercise) } label: { HStack { Image(systemName: exercise.group.icon).foregroundStyle(.mint).frame(width: 30); VStack(alignment: .leading) { Text(exercise.name); Text(exercise.group.rawValue + " · " + exercise.equipment).font(.caption).foregroundStyle(.secondary) } } } } }.searchable(text: $query, prompt: "Übung suchen").navigationTitle("Übungen") } }
}
struct FilterPill: View { let title: String; let selected: Bool; let action: () -> Void; var body: some View { Button(title, action: action).buttonStyle(.bordered).tint(selected ? .mint : .gray) } }
struct ExerciseDetailView: View { let exercise: Exercise
    var body: some View { List { Section("Zielmuskulatur") { Label(exercise.group.rawValue, systemImage: exercise.group.icon); if !exercise.secondary.isEmpty { LabeledContent("Zusätzlich", value: exercise.secondary) }; LabeledContent("Equipment", value: exercise.equipment) }; Section("Ausführung") { Text(exercise.instructions) }; Section("Häufiger Fehler") { Label(exercise.commonMistake, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) }; Section("Muskelaufbau") { Text("Starte mit 3 Arbeitssätzen à 8–12 sauberen Wiederholungen. Steigere Gewicht oder Wiederholungen schrittweise, sobald du den oberen Wiederholungsbereich sicher erreichst.") } }.navigationTitle(exercise.name).navigationBarTitleDisplayMode(.inline) }
}

struct FitnessProgressView: View {
    @EnvironmentObject private var store: AppStore
    var totalVolume: Double { store.sessions.reduce(0) { $0 + $1.volume } }
    var body: some View { NavigationStack { ScrollView { VStack(spacing: 16) { HStack(spacing: 12) { MetricCard(title: "Sessions", value: "\(store.sessions.count)", caption: "gespeichert", icon: "calendar", color: .mint); MetricCard(title: "Volumen", value: "\(Int(totalVolume))", caption: "kg insgesamt", icon: "chart.bar.fill", color: .indigo) }; VStack(alignment: .leading, spacing: 12) { Text("Letzte Trainings").font(.headline); if store.sessions.isEmpty { Text("Nach deiner ersten Session siehst du hier deinen Fortschritt.").foregroundStyle(.secondary) } else { ForEach(store.sessions.prefix(6)) { s in HStack { Text(s.date.formatted(.dateTime.day().month())); Text(s.title); Spacer(); Text("\(Int(s.volume)) kg").font(.subheadline.bold()) } } } }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20)); VStack(alignment: .leading, spacing: 12) { Text("Cardio").font(.headline); HStack { Text("\(store.cardio.count) Einträge"); Spacer(); Text("\(store.cardio.reduce(0) { $0 + $1.calories }) kcal").foregroundStyle(.orange) } }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20)) }.padding() }.navigationTitle("Fortschritt") } }
}

struct CoachView: View {
    @EnvironmentObject private var store: AppStore
    @State private var messages: [CoachMessage] = [CoachMessage(text: "Hi! Ich bin dein FitnessFlow Coach. Frag mich zum Beispiel, wie du deinen Plan anpasst oder was du heute trainieren solltest.", fromUser: false)]
    @State private var input = ""
    var body: some View { NavigationStack { VStack { ScrollViewReader { proxy in ScrollView { LazyVStack(spacing: 12) { ForEach(messages) { message in HStack { if message.fromUser { Spacer() }; Text(message.text).padding(12).foregroundStyle(message.fromUser ? .white : .primary).background(message.fromUser ? Color.mint : Color.secondary.opacity(0.13), in: RoundedRectangle(cornerRadius: 18)); if !message.fromUser { Spacer() } }.id(message.id) } }.padding() }.onChange(of: messages.count) { _, _ in proxy.scrollTo(messages.last?.id, anchor: .bottom) } }; HStack { TextField("Frag deinen Coach …", text: $input, axis: .vertical).textFieldStyle(.roundedBorder); Button { send() } label: { Image(systemName: "arrow.up.circle.fill").font(.title2) }.disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }.padding() }.navigationTitle("KI-Coach").toolbar { Image(systemName: "sparkles").foregroundStyle(.mint) } } }
    private func send() { let question = input.trimmingCharacters(in: .whitespacesAndNewlines); guard !question.isEmpty else { return }; messages.append(CoachMessage(text: question, fromUser: true)); input = ""; messages.append(CoachMessage(text: CoachEngine.answer(question, plan: store.plan, sessions: store.sessions), fromUser: false)) }
}
struct CoachMessage: Identifiable { var id = UUID(); let text: String; let fromUser: Bool }
enum CoachEngine {
    static func answer(_ question: String, plan: TrainingPlan, sessions: [WorkoutSession]) -> String {
        let q = question.lowercased()
        if q.contains("3") && q.contains("tag") { return "Für 3 Trainingstage empfehle ich Ganzkörper A/B/C. So stimulierst du jede große Muskelgruppe mehrmals pro Woche und hast ausreichend Regeneration. Wechsle im Plan-Tab auf „3 Tage“, um ihn direkt anzupassen." }
        if q.contains("brust") { return "Für mehr Brust-Fokus: Beginne deine Push-Einheit mit Bankdrücken oder Schrägbankdrücken und ergänze 2–4 harte Sätze. Ziel: etwa 10–16 saubere Brustsätze pro Woche, mit mindestens 48 Stunden Abstand." }
        if q.contains("kalorien") || q.contains("essen") { return "Für Muskelaufbau sind ein moderater Kalorienüberschuss, ausreichend Eiweiß und regelmäßiges Training entscheidend. Als grober Bereich eignen sich 1,6–2,2 g Eiweiß pro kg Körpergewicht. Die Ernährungsschätzungen in der App sind Richtwerte, keine medizinische Beratung." }
        if q.contains("schmerz") || q.contains("verletz") { return "Bei Schmerz solltest du die Übung abbrechen und nicht durchtrainieren. Lass anhaltende oder starke Beschwerden ärztlich bzw. physiotherapeutisch abklären. Ich kann dir gern eine schmerzfreie Übungsalternative nennen." }
        if q.contains("plan") || q.contains("wechsel") { return "Dein aktueller Plan hat \(plan.daysPerWeek) Tage. Im Plan-Tab kannst du direkt zwischen 3, 4 und 5 Tagen wechseln; die Übungen und Muskelgruppen werden passend neu verteilt." }
        return "Konstanz, saubere Technik und progressive Überlastung sind die Basis. Notiere deine Sätze im Trainingsmodus und versuche, über Zeit eine Wiederholung oder etwas Gewicht mehr zu schaffen. Was möchtest du konkret an Training oder Ernährung verbessern?"
    }
}
