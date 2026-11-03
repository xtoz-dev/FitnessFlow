import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView().tabItem { Label("Heute", systemImage: "house.fill") }
            PlanView().tabItem { Label("Plan", systemImage: "calendar") }
            WorkoutRootView().tabItem { Label("Training", systemImage: "dumbbell.fill") }
            NutritionView().tabItem { Label("Ernährung", systemImage: "fork.knife") }
            ExerciseLibraryView().tabItem { Label("Übungen", systemImage: "list.bullet.rectangle") }
            FitnessProgressView().tabItem { Label("Fortschritt", systemImage: "chart.line.uptrend.xyaxis") }
            CoachView().tabItem { Label("KI-Coach", systemImage: "sparkles") }
        }
        .tint(.mint)
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showCardio = false
    private var nextPlan: PlanDay { store.plan.days.first ?? PlanDay(title: "Training", groups: [], exercises: []) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    HStack { VStack(alignment: .leading, spacing: 4) { Text("Guten Trainingstag").font(.title.bold()); Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "flame.fill").font(.title).foregroundStyle(.orange) }
                    Button { store.start(day: nextPlan) } label: {
                        HStack { Image(systemName: "play.fill").font(.title2); VStack(alignment: .leading) { Text("Training starten").font(.headline); Text(nextPlan.title).font(.subheadline).opacity(0.8) }; Spacer(); Image(systemName: "chevron.right") }
                        .padding(20).foregroundStyle(.white).background(LinearGradient(colors: [.mint, .teal], startPoint: .leading, endPoint: .trailing)).clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                    HStack(spacing: 12) { MetricCard(title: "Kalorien", value: "\(store.caloriesToday)", caption: "von 2.400 kcal", icon: "flame.fill", color: .orange); MetricCard(title: "Eiweiß", value: "\(Int(store.proteinToday)) g", caption: "Ziel: 160 g", icon: "bolt.fill", color: .mint) }
                    VStack(alignment: .leading, spacing: 12) { Text("Dein heutiger Fokus").font(.headline); ForEach(nextPlan.groups) { group in HStack { Image(systemName: group.icon).frame(width: 28).foregroundStyle(.mint); Text(group.rawValue); Spacer() } } }.padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    Button { showCardio = true } label: { Label("Lauf- oder Radtour eintragen", systemImage: "figure.run").frame(maxWidth: .infinity).padding().background(Color.accentColor.opacity(0.12), in: Capsule()) }
                }.padding()
            }.navigationTitle("FitnessFlow").sheet(isPresented: $showCardio) { CardioEntryView() }
        }
    }
}

struct MetricCard: View { let title: String; let value: String; let caption: String; let icon: String; let color: Color
    var body: some View { VStack(alignment: .leading, spacing: 9) { Image(systemName: icon).foregroundStyle(color); Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.title2.bold()); Text(caption).font(.caption2).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20)) }
}

struct PlanView: View {
    @EnvironmentObject private var store: AppStore
    @State private var chosenDays = 5
    var body: some View { NavigationStack { List { Section { Picker("Trainingstage", selection: $chosenDays) { Text("3 Tage").tag(3); Text("4 Tage").tag(4); Text("5 Tage").tag(5) }.pickerStyle(.segmented).onChange(of: chosenDays) { _, new in store.changePlan(to: new) } } footer: { Text("Dein Plan wird mit einer hypertrophieorientierten Aufteilung angepasst.") }
        Section("Dein \(store.plan.daysPerWeek)-Tage-Plan") { ForEach(store.plan.days) { day in NavigationLink { PlanDetailView(day: day) } label: { VStack(alignment: .leading, spacing: 7) { Text(day.title).font(.headline); Text(day.groups.map(\.rawValue).joined(separator: " • ")).foregroundStyle(.secondary); Text("\(day.exercises.count) Übungen").font(.caption).foregroundStyle(.mint) } } } }
    }.navigationTitle("Trainingsplan").onAppear { chosenDays = store.plan.daysPerWeek } } }
}

struct PlanDetailView: View { @EnvironmentObject private var store: AppStore; let day: PlanDay
    var body: some View { List { Section("Muskelgruppen") { ForEach(day.groups) { Label($0.rawValue, systemImage: $0.icon) } }; Section("Vorgeschlagene Übungen") { ForEach(day.exercises) { exercise in VStack(alignment: .leading) { Text(exercise.name); Text("3 Sätze · 8–12 Wiederholungen").font(.caption).foregroundStyle(.secondary) } } }; Section { Button { store.start(day: day) } label: { Label("Dieses Training starten", systemImage: "play.fill") } } }.navigationTitle(day.title) }
}
