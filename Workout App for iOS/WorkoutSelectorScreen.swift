import SwiftUI
import CoreData

struct WorkoutSelectorScreen: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JWWeekEntity.startDate, ascending: true)],
        animation: .default
    ) private var weeks: FetchedResults<JWWeekEntity>
    
    @State private var showAddWeekModal = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if weeks.isEmpty {
                    Text("No workout weeks found. Tap '+' to add one.")
                        .font(.headline)
                        .padding()
                } else {
                    List {
                        ForEach(weeks) { week in
                            NavigationLink(destination: WeekDetailView(week: week)) {
                                HStack {
                                    Text("Week \(week.weekNumber):")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(formattedDate(week.startDate)) - \(formattedDate(week.endDate))")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .onDelete(perform: deleteWeek)
                    }
                }
                Spacer()
            }
            .navigationTitle("Workout Weeks")
            .navigationBarItems(trailing: Button(action: {
                showAddWeekModal = true
            }) {
                Image(systemName: "plus")
                    .font(.title)
            })
            .sheet(isPresented: $showAddWeekModal) {
                AddWeekModal(weekNumber: getNextWeekNumber())
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func deleteWeek(at offsets: IndexSet) {
        offsets.map { weeks[$0] }.forEach(viewContext.delete)
        saveContext()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete week: \(error.localizedDescription)")
        }
    }

    private func getNextWeekNumber() -> Int {
        // Get the next week number based on the last week in the list
        guard let lastWeek = weeks.last else {
            return 1 // If no weeks exist, start at week 1
        }
        return Int(lastWeek.weekNumber + 1)
    }
}


struct WeekDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var week: JWWeekEntity
    @StateObject private var viewModel: WorkoutDaysViewModel

    @State private var showAddWorkoutDayModal = false
    @State private var selectedWorkoutDay: JWWorkoutDayEntity?

    init(week: JWWeekEntity) {
        self.week = week
        _viewModel = StateObject(wrappedValue: WorkoutDaysViewModel(viewContext: week.managedObjectContext!))
    }

    var body: some View {
        VStack {
            if viewModel.workoutDays.isEmpty {
                Text("No workout days added for this week. Tap '+' to add one.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    // Iterate over the workout days and display day and type in order
                    ForEach(sortedWorkoutDays(), id: \.self) { workoutDay in
                        HStack {
                            // Display the day of the week and associated workout type
                            Text("\(workoutDay.nameAttribute ?? "N/A"): \(workoutDay.dayType ?? "N/A")")
                                .font(.headline)
                            Spacer()
                        }
                        .background(
                            NavigationLink(
                                destination: WorkoutDayDetailView(workoutDay: workoutDay, viewContext: viewContext) // Provide the viewContext here
                            ) {
                                EmptyView()
                            }
                            .opacity(0) // Hides the default NavigationLink appearance
                        )
                    }
                    .onDelete(perform: deleteWorkoutDay)
                }
            }
            Spacer()
        }
        .navigationTitle("Week \(week.weekNumber)")
        .navigationBarItems(trailing: Button(action: {
            showAddWorkoutDayModal = true
        }) {
            Image(systemName: "plus")
                .font(.title)
        })
        .sheet(isPresented: $showAddWorkoutDayModal, onDismiss: {
            viewModel.fetchWorkoutDays(for: week) // Refresh the list after dismissal
        }) {
            AddWorkoutDayModal(week: week)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            viewModel.fetchWorkoutDays(for: week)
        }
    }


    private func sortedWorkoutDays() -> [JWWorkoutDayEntity] {
        // Sort the workout days from Sunday to Saturday
        let daysOrder = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        
        return viewModel.workoutDays.sorted { firstDay, secondDay in
            guard let firstDayName = firstDay.nameAttribute, let secondDayName = secondDay.nameAttribute else {
                return false
            }
            
            // Get the index of the day in the daysOrder array to compare correctly
            let firstDayIndex = daysOrder.firstIndex(of: firstDayName) ?? 0
            let secondDayIndex = daysOrder.firstIndex(of: secondDayName) ?? 0
            
            return firstDayIndex < secondDayIndex
        }
    }

    private func deleteWorkoutDay(at offsets: IndexSet) {
        offsets
            .map { viewModel.workoutDays[$0] }
            .forEach { workoutDay in
                viewContext.delete(workoutDay)
            }
        saveContext()
        viewModel.fetchWorkoutDays(for: week) // Refresh the list after deletion
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete workout day: \(error.localizedDescription)")
        }
    }
}

class WorkoutDaysViewModel: ObservableObject {
    @Published var workoutDays: [JWWorkoutDayEntity] = []
    private var viewContext: NSManagedObjectContext

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }

    func fetchWorkoutDays(for week: JWWeekEntity) {
        let fetchRequest: NSFetchRequest<JWWorkoutDayEntity> = JWWorkoutDayEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "week == %@", week)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \JWWorkoutDayEntity.nameAttribute, ascending: true)]

        do {
            workoutDays = try viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch workout days: \(error.localizedDescription)")
        }
    }
}

struct WorkoutDayDetailView: View {
    @ObservedObject var workoutDay: JWWorkoutDayEntity
    @State private var showAddWorkoutModal = false
    @ObservedObject private var viewModel: WorkoutsViewModel

    init(workoutDay: JWWorkoutDayEntity, viewContext: NSManagedObjectContext) {
        self.workoutDay = workoutDay
        _viewModel = ObservedObject(wrappedValue: WorkoutsViewModel(viewContext: viewContext, workoutDay: workoutDay))
    }

    var body: some View {
        VStack {
            if viewModel.workouts.isEmpty {
                Text("No workouts added for \(workoutDay.nameAttribute ?? "this day"). Tap '+' to add one.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(viewModel.workouts, id: \.objectID) { workout in
                        VStack(alignment: .leading) {
                            Text(workout.name ?? "N/A")
                                .font(.headline)
                            Text("Weight: \(workout.weight ?? "N/A") lbs, \(String(workout.sets)) sets x \(String(workout.reps)) reps")
                                .font(.subheadline)
                            if let notes = workout.notes, !notes.isEmpty {
                                Text("Notes: \(notes)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: deleteWorkout)
                }
                Spacer()
            }
        }
        .navigationTitle(workoutDay.nameAttribute ?? "Workout Day")
        .navigationBarItems(trailing: Button(action: {
            showAddWorkoutModal = true
        }) {
            Image(systemName: "plus")
                .font(.title)
        })
        .sheet(isPresented: $showAddWorkoutModal) {
            AddWorkoutModal(workoutDay: workoutDay, viewModel: viewModel) // Pass viewModel here
        }
        .onAppear {
            viewModel.fetchWorkouts()
        }
    }

    private func deleteWorkout(at offsets: IndexSet) {
        viewModel.deleteWorkout(at: offsets)
    }
}

class WorkoutsViewModel: ObservableObject {
    @Published var workouts: [JWWorkoutEntity] = []
    private var viewContext: NSManagedObjectContext
    private var workoutDay: JWWorkoutDayEntity

    init(viewContext: NSManagedObjectContext, workoutDay: JWWorkoutDayEntity) {
        self.viewContext = viewContext
        self.workoutDay = workoutDay
        fetchWorkouts()
    }

    func fetchWorkouts() {
        let fetchRequest: NSFetchRequest<JWWorkoutEntity> = JWWorkoutEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "workoutDay == %@", workoutDay)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \JWWorkoutEntity.name, ascending: true)]

        do {
            workouts = try viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch workouts: \(error.localizedDescription)")
        }
    }

    func addWorkout(workoutName: String, weight: String, sets: String, reps: String, notes: String) {
        let newWorkout = JWWorkoutEntity(context: viewContext)
        newWorkout.name = workoutName
        newWorkout.weight = weight
        newWorkout.sets = sets
        newWorkout.reps = reps
        newWorkout.notes = notes
        newWorkout.workoutDay = workoutDay

        // Save the new workout
        saveContext()

        // Fetch updated workouts
        fetchWorkouts()
    }


    func deleteWorkout(at offsets: IndexSet) {
        for index in offsets {
            let workoutToDelete = workouts[index]
            viewContext.delete(workoutToDelete)
        }
        saveContext()

        // Fetch updated workouts
        fetchWorkouts()
    }

    private func saveContext() {
        do {
            try viewContext.save()
            print("Workouts saved")
        } catch {
            print("Failed to save workouts: \(error.localizedDescription)")
        }
    }
}


struct AddWorkoutDayModal: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @ObservedObject var week: JWWeekEntity

    @State private var dayTypes: [String] = Array(repeating: "", count: 7)
    
    private let daysOfWeek = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        NavigationView {
            Form {
                ForEach(0..<daysOfWeek.count, id: \.self) { index in
                    Section(header: Text("\(daysOfWeek[index])")) {
                        TextField("Enter day type (e.g., Push, Rest)", text: $dayTypes[index])
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                
                // Action buttons for saving or canceling
                Section {
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        Spacer()
                        Button("Save All") {
                            addWorkoutDays()
                            dismiss()
                        }
                        .disabled(dayTypes.allSatisfy { $0.isEmpty }) // Disable if all types are empty
                    }
                }
            }
            .navigationTitle("Add Workout Days")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func addWorkoutDays() {
        for (index, dayType) in dayTypes.enumerated() {
            guard !dayType.isEmpty else { continue }
            
            let newWorkoutDay = JWWorkoutDayEntity(context: viewContext)
            newWorkoutDay.nameAttribute = daysOfWeek[index]
            newWorkoutDay.dayType = dayType
            newWorkoutDay.week = week
        }
        saveContext()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
            print("Saved workout day type successfully")
        } catch {
            print("Failed to save workout days: \(error.localizedDescription)")
        }
    }
}

struct AddWorkoutModal: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutDay: JWWorkoutDayEntity
    @ObservedObject var viewModel: WorkoutsViewModel
    
    @State private var workoutName: String = ""
    @State private var weight: String = ""  // Keep as String for user input
    @State private var sets: String = ""    // Keep as String for user input
    @State private var reps: String = ""    // Keep as String for user input
    @State private var notes: String = ""
    
    @State private var suggestions: [JWWorkoutEntryEntity] = []
    @State private var showSuggestions: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Workout Day: \(workoutDay.nameAttribute ?? "Unknown")")) {
                        Text("Type: \(workoutDay.dayType ?? "No Type")")
                            .foregroundColor(.gray)
                    }
                    
                    Section(header: Text("Add New Workout")) {
                        VStack(alignment: .leading) {
                            // Workout Name Input with Predictive Text
                            TextField("Workout Name", text: $workoutName)
                                .onChange(of: workoutName) { newValue in
                                    fetchSuggestions(for: newValue) // Fetch suggestions as the user types
                                }
                                .autocapitalization(.none) // Ensure case-insensitive behavior in input
                                .disableAutocorrection(true) // Avoid unwanted autocorrections
                            
                            // Display Suggestions
                            if showSuggestions {
                                ScrollView { // Allows the list to scroll if there are many suggestions
                                    LazyVStack(alignment: .leading, spacing: 4) {
                                        ForEach(suggestions, id: \.self) { suggestion in
                                            Button(action: {
                                                workoutName = suggestion.entry ?? ""
                                                showSuggestions = false // Hide suggestions after selection
                                            }) {
                                                Text(suggestion.entry ?? "Unnamed Workout")
                                                    .foregroundColor(.primary)
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal, 12)
                                                    .background(Color(.systemGray6))
                                                    .cornerRadius(6)
                                                    .frame(maxWidth: .infinity, alignment: .leading) // Ensure text is left-aligned
                                            }
                                            //.buttonStyle(PlainButtonStyle()) // Remove default button styling
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                                .frame(maxHeight: 150) // Limit the height of the suggestion list
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                        }

                        
                        // Weight input
                        TextField("Weight (lbs)", text: $weight)
                            .keyboardType(.decimalPad)
                        
                        // Sets input
                        TextField("Sets", text: $sets)
                            .keyboardType(.numberPad)
                        
                        // Reps input
                        TextField("Reps", text: $reps)
                            .keyboardType(.numberPad)
                        
                        // Notes input
                        TextField("Notes", text: $notes)
                    }
                }
                .navigationTitle("Add Workout")
                .navigationBarItems(
                    leading: Button("Cancel") { dismiss() },
                    trailing: Button("Save") {
                        saveWorkout()
                    }
                )
            }
        }
    }
    
    /// Save the workout and add it to Core Data
    private func saveWorkout() {
        guard !workoutName.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("Workout name cannot be empty.")
            return
        }
        
        // Save the workout to the workoutDay via viewModel
        viewModel.addWorkout(workoutName: workoutName, weight: weight, sets: sets, reps: reps, notes: notes)
        
        // Save the workout name to suggestions in Core Data
        addWorkoutNameToSuggestions(workoutName: workoutName)
        
        // Dismiss the modal
        dismiss()
    }
    
    /// Add the workout name to suggestions in Core Data
    private func addWorkoutNameToSuggestions(workoutName: String) {
        let trimmedName = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if the workout already exists
        let fetchRequest: NSFetchRequest<JWWorkoutEntryEntity> = JWWorkoutEntryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "entry ==[cd] %@", trimmedName)
        
        do {
            let existingEntries = try viewContext.fetch(fetchRequest)
            if existingEntries.isEmpty {
                // Create a new entry if none exists
                let newEntry = JWWorkoutEntryEntity(context: viewContext)
                newEntry.entry = trimmedName
                
                // Save the context
                try viewContext.save()
                print("Saved workout name to Core Data: \(trimmedName)")
            } else {
                print("Workout name already exists in Core Data: \(trimmedName)")
            }
        } catch {
            print("Error saving workout name to Core Data: \(error)")
        }
    }
    
    /// Fetch suggestions from Core Data
    private func fetchSuggestions(for input: String) {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedInput.isEmpty else {
            suggestions = []
            showSuggestions = false
            return
        }
        
        let fetchRequest: NSFetchRequest<JWWorkoutEntryEntity> = JWWorkoutEntryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "entry CONTAINS[cd] %@", trimmedInput)
        fetchRequest.fetchLimit = 10 // Limit suggestions to 10
        
        do {
            suggestions = try viewContext.fetch(fetchRequest)
            showSuggestions = !suggestions.isEmpty
        } catch {
            print("Error fetching suggestions: \(error)")
            suggestions = []
            showSuggestions = false
        }
    }
}


struct AddWeekModal: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    var weekNumber: Int
    
    @State private var startDate = Date() // Default to current date
    @State private var endDate = Date().addingTimeInterval(60 * 60 * 24 * 7) // 7 days from start date
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Week Information")) {
                    Text("Week Number: \(weekNumber)")
                        .font(.headline)
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .onChange(of: startDate) { newValue in
                            endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? Date()
                        }
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        .disabled(true) // End date is always 7 days after start date
                }
                
                Section {
                    Button("Save Week") {
                        let newWeek = JWWeekEntity(context: viewContext)
                        newWeek.weekNumber = Int32(weekNumber)
                        newWeek.startDate = startDate
                        newWeek.endDate = endDate
                        saveContext()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Add New Week")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save week: \(error.localizedDescription)")
        }
    }
}


class CoreDataStack {
    static let shared = CoreDataStack()

    // Persistent container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel") 
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error {
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            }
        }
        return container
    }()

    // Managed Object Context
    var managedObjectContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    // Save changes to context
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
