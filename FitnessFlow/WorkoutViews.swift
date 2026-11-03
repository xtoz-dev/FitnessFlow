import SwiftUI

struct WorkoutRootView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View {
        Group { if store.currentSession != nil { ActiveWorkoutView() } else { WorkoutHistoryView() } }
    }
}

struct WorkoutHistoryView: View {
    @EnvironmentObject private var store: AppStore
    var body: some View { NavigationStack { List { if store.sessions.isEmpty { ContentUnavailableView("Noch keine Sessions", systemImage: "dumbbell", description: Text("Starte über Heute oder deinen Trainingsplan.")) } else { Section("Letzte Einheiten") { ForEach(store.sessions) { session in HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(.mint); VStack(alignment: .leading) { Text(session.title).font(.headline); Text(session.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary) }; Spacer(); VStack(alignment: .trailing) { Text("\(Int(session.volume)) kg").font(.subheadline.bold()); Text("\(session.durationSeconds / 60) Min.").font(.caption).foregroundStyle(.secondary) } } } } } }.navigationTitle("Training") } }
}

struct ActiveWorkoutView: View {
    @EnvironmentObject private var store: AppStore
    @State private var elapsed = 0
    @State private var rest = 90
    @State private var restRunning = false
    @State private var showAdd = false
    @State private var timer: Timer?
    var session: WorkoutSession { store.currentSession! }
    var body: some View {
        NavigationStack {
            List {
                Section { HStack { Label("\(elapsed / 60):\(String(format: "%02d", elapsed % 60))", systemImage: "timer").monospacedDigit(); Spacer(); Text("~\(session.calories) kcal").foregroundStyle(.orange) } } footer: { Text("Kalorienverbrauch ist eine Schätzung. Passe Training und Ernährung immer an deine persönlichen Bedürfnisse an.") }
                ForEach(session.exercises.indices, id: \.self) { index in ExerciseLogCard(exerciseIndex: index) }
                Section { Button { showAdd = true } label: { Label("Übung hinzufügen", systemImage: "plus.circle.fill") } }
                Section { Button(role: .destructive) { store.finishCurrentSession() } label: { Label("Training abschließen", systemImage: "checkmark.seal.fill") } }
            }.navigationTitle(session.title).toolbar { ToolbarItem(placement: .topBarTrailing) { Button { restRunning.toggle() } label: { Label(restRunning ? "\(rest)s" : "Pause", systemImage: restRunning ? "pause.fill" : "timer") }.monospacedDigit() } }
                .sheet(isPresented: $showAdd) { ExercisePicker { ex in var draft = store.currentSession!; draft.exercises.append(WorkoutExercise(exercise: ex, sets: (0..<3).map { _ in SetLog(weight: 0, reps: 10) })); store.currentSession = draft } }
                .onAppear { elapsed = store.currentSession?.durationSeconds ?? 0; timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in elapsed += 1; if var draft = store.currentSession { draft.durationSeconds = elapsed; store.currentSession = draft }; if restRunning && rest > 0 { rest -= 1 }; if rest == 0 { restRunning = false; rest = 90 } } }
                .onDisappear { timer?.invalidate() }
        }
    }
}

struct ExerciseLogCard: View {
    @EnvironmentObject private var store: AppStore
    let exerciseIndex: Int
    private var workout: WorkoutExercise { store.currentSession!.exercises[exerciseIndex] }
    var body: some View {
        Section { ForEach(workout.sets.indices, id: \.self) { setIndex in SetRow(exerciseIndex: exerciseIndex, setIndex: setIndex) }; Button { var s = store.currentSession!; s.exercises[exerciseIndex].sets.append(SetLog(weight: 0, reps: 10)); store.currentSession = s } label: { Label("Satz hinzufügen", systemImage: "plus") } } header: { HStack { Text(workout.exercise.name); Spacer(); Text(workout.exercise.group.rawValue).font(.caption).foregroundStyle(.secondary) } }
    }
}

struct SetRow: View {
    @EnvironmentObject private var store: AppStore
    let exerciseIndex: Int; let setIndex: Int
    var body: some View {
        let set = store.currentSession!.exercises[exerciseIndex].sets[setIndex]
        HStack { Text("\(setIndex + 1)").foregroundStyle(.secondary).frame(width: 20); TextField("kg", value: binding(\.weight), format: .number.precision(.fractionLength(1))).keyboardType(.decimalPad).multilineTextAlignment(.center).textFieldStyle(.roundedBorder).frame(width: 75); Text("×").foregroundStyle(.secondary); TextField("Wdh.", value: binding(\.reps), format: .number).keyboardType(.numberPad).multilineTextAlignment(.center).textFieldStyle(.roundedBorder).frame(width: 70); Spacer(); Button { var draft = store.currentSession!; draft.exercises[exerciseIndex].sets[setIndex].done.toggle(); store.currentSession = draft } label: { Image(systemName: set.done ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(set.done ? .mint : .secondary) }.buttonStyle(.plain) }
    }
    private func binding<T>(_ path: WritableKeyPath<SetLog, T>) -> Binding<T> { Binding { store.currentSession!.exercises[exerciseIndex].sets[setIndex][keyPath: path] } set: { value in var draft = store.currentSession!; draft.exercises[exerciseIndex].sets[setIndex][keyPath: path] = value; store.currentSession = draft } }
}

struct ExercisePicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let select: (Exercise) -> Void
    var filtered: [Exercise] { query.isEmpty ? Exercise.catalog : Exercise.catalog.filter { $0.name.localizedCaseInsensitiveContains(query) } }
    var body: some View { NavigationStack { List(filtered) { ex in Button { select(ex); dismiss() } label: { VStack(alignment: .leading) { Text(ex.name); Text(ex.group.rawValue + " · " + ex.equipment).font(.caption).foregroundStyle(.secondary) } } }.searchable(text: $query).navigationTitle("Übung wählen").toolbar { Button("Fertig") { dismiss() } } } }
}

struct CardioEntryView: View {
    @EnvironmentObject private var store: AppStore; @Environment(\.dismiss) private var dismiss
    @State private var type: CardioKind = .laufen; @State private var duration = 30; @State private var distance = 5.0
    var calories: Int { let factor = type == .radfahren ? 7 : 10; return duration * factor }
    var body: some View { NavigationStack { Form { Picker("Aktivität", selection: $type) { ForEach(CardioKind.allCases) { Text($0.rawValue).tag($0) } }; Stepper("Dauer: \(duration) Minuten", value: $duration, in: 1...600); HStack { Text("Distanz"); Spacer(); TextField("km", value: $distance, format: .number.precision(.fractionLength(1))).keyboardType(.decimalPad).multilineTextAlignment(.trailing); Text("km") }; LabeledContent("Geschätzt", value: "~\(calories) kcal") }.navigationTitle("Cardio eintragen").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Speichern") { store.cardio.insert(CardioEntry(kind: type, durationMinutes: duration, distanceKM: distance, calories: calories), at: 0); dismiss() } }; ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } } } } }
}
