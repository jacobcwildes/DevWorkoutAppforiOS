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
                                destination: WorkoutDayDetailView(workoutDay: workoutDay) // Provide the viewContext here
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

    @FetchRequest var workouts: FetchedResults<JWWorkoutEntity>

    init(workoutDay: JWWorkoutDayEntity) {
        self.workoutDay = workoutDay
        _workouts = FetchRequest(
            entity: JWWorkoutEntity.entity(),
            sortDescriptors: [NSSortDescriptor(key: "objectID", ascending: true)],
            predicate: NSPredicate(format: "workoutDay == %@", workoutDay)
        )
    }

    var body: some View {
        VStack {
            if workouts.isEmpty {
                Text("No workouts added for \(workoutDay.nameAttribute ?? "this day"). Tap '+' to add one.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    // Iterate over the workouts and create a NavigationLink for each workout
                    ForEach(workouts, id: \.objectID) { workout in
                        NavigationLink(destination: EditWorkoutView(workout: workout)) {
                            VStack(alignment: .leading) {
                                // Workout name
                                Text(workout.name ?? "N/A")
                                    .font(.headline)

                                // Notes
                                if let notes = workout.notes, !notes.isEmpty {
                                    Text("Notes: \(notes)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }

                                // Display all sets for the workout
                                if let sets = workout.workoutSets as? Set<JWWorkoutSetEntity>, !sets.isEmpty {
                                    ForEach(
                                        Array(sets.sorted {
                                            $0.objectID.uriRepresentation().absoluteString < $1.objectID.uriRepresentation().absoluteString
                                        }),
                                        id: \.objectID
                                    ) { set in
                                        VStack(alignment: .leading) {
                                            Text("Weight: \(set.weight ?? "N/A") lbs")
                                            Text("Sets: \(set.sets ?? "N/A")")
                                            Text("Reps: \(set.reps ?? "N/A")")
                                        }
                                        .padding(.leading, 10) // Indent for sets
                                        .font(.subheadline)
                                    }
                                } else {
                                    Text("No sets available.")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .onDelete(perform: deleteWorkout)
                }
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
            AddWorkoutModal(workoutDay: workoutDay)
        }
    }


    private func deleteWorkout(at offsets: IndexSet) {
        for index in offsets {
            let workout = workouts[index]
            workout.managedObjectContext?.delete(workout)
        }
        try? workoutDay.managedObjectContext?.save()
    }
}

struct EditWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workout: JWWorkoutEntity
    @State private var workoutSets: [JWWorkoutSetEntity] = []
    
    @State private var weight: String = ""
    @State private var sets: String = ""
    @State private var reps: String = ""
    @State private var notes: String = ""
    
    // To keep track of any sets added
    @State private var newSets: [WorkoutSet] = []

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Edit Workout")) {
                    TextField("Workout Name", text: Binding(get: { workout.name ?? "" }, set: { workout.name = $0 }))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Notes", text: Binding(get: { workout.notes ?? "" }, set: { workout.notes = $0 }))
                    
                    TextField("Weight", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Sets", text: $sets)
                        .keyboardType(.numberPad)
                    TextField("Reps", text: $reps)
                        .keyboardType(.numberPad)
                    
                    // Add Set Button
                    Button(action: addSet) {
                        Text("Add Set")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                    // Display all sets for the workout
                    if let sets = workout.workoutSets as? Set<JWWorkoutSetEntity>, !sets.isEmpty {
                        ForEach(Array(sets.sorted { $0.objectID.uriRepresentation().absoluteString < $1.objectID.uriRepresentation().absoluteString }), id: \.self) { set in
                            VStack(alignment: .leading) {
                                Text("Weight: \(set.weight ?? "N/A") lbs")
                                Text("Sets: \(set.sets ?? "N/A")")
                                Text("Reps: \(set.reps ?? "N/A")")
                                
                                Button(action: {
                                    deleteSet(set)
                                }) {
                                    Text("Delete Set")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.leading, 10) // Indent for sets
                            .font(.subheadline)
                        }
                    }
                }
            }
            
            // Save Changes Button
            Button(action: saveWorkout) {
                Text("Save Workout")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .onAppear {
            // Load workout sets to the state for editing
            workoutSets = Array(workout.workoutSets as? Set<JWWorkoutSetEntity> ?? [])
        }
        .navigationTitle("Edit Workout")
    }

    private func addSet() {
        // Check if all fields are filled
        guard !weight.isEmpty, !sets.isEmpty, !reps.isEmpty else { return }
        
        // Create a new set as a Core Data entity (JWWorkoutSetEntity)
        let newWorkoutSetEntity = JWWorkoutSetEntity(context: viewContext)
        newWorkoutSetEntity.weight = weight
        newWorkoutSetEntity.sets = sets
        newWorkoutSetEntity.reps = reps
        newWorkoutSetEntity.workout = workout // Associate this set with the current workout

        // Add the new set to the Core Data workoutSets relationship
        workout.addToWorkoutSets(newWorkoutSetEntity)

        // Save context to persist the new set
        saveContext()

        // Clear the input fields after adding
        weight = ""
        sets = ""
        reps = ""
    }


    private func deleteSet(_ set: JWWorkoutSetEntity) {
        // Remove the set from Core Data
        viewContext.delete(set)

        // Save context after deletion
        saveContext()

        // Refresh the workout sets (optional, since Core Data will update the relationship automatically)
        workoutSets = Array(workout.workoutSets as? Set<JWWorkoutSetEntity> ?? [])
    }

    private func saveWorkout() {
        // Save the workout with the updated sets
        workout.sets = sets
        workout.reps = reps
        workout.weight = weight
        workout.notes = notes
        
        // Save the changes to Core Data
        saveContext()
        
        // Dismiss the view
        dismiss()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
            print("Workout updated successfully.")
        } catch {
            print("Error saving workout: \(error.localizedDescription)")
        }
    }
}





struct WorkoutView: View {
    @ObservedObject var workoutsViewModel: WorkoutsViewModel

    var body: some View {
        List {
            ForEach(workoutsViewModel.workouts, id: \.self) { workout in
                Text(workout.name ?? "Unknown Workout")
            }
            .onDelete(perform: workoutsViewModel.deleteWorkout)
        }
        .onAppear {
            workoutsViewModel.fetchWorkouts()
        }
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
        
        // Sort by objectID, which correlates with the row insertion order in the database
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "objectID", ascending: true)]

        do {
            workouts = try viewContext.fetch(fetchRequest)
            print("Fetched workouts: \(workouts.count)")
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

struct WorkoutSet: Identifiable, Hashable {
    var id = UUID()
    var weight: String
    var sets: String
    var reps: String
}

struct AddWorkoutModal: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutDay: JWWorkoutDayEntity

    @State private var workoutName: String = ""
    @State private var weight: String = ""
    @State private var sets: String = ""
    @State private var reps: String = ""
    @State private var notes: String = ""

    @State private var workoutSets: [WorkoutSet] = []
    @State private var suggestions: [JWWorkoutEntryEntity] = []
    @State private var showSuggestions: Bool = false
    @State private var recentWorkout: (name: String, weight: String, sets: String, reps: String, notes: String)?

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    workoutDaySection
                    addNewWorkoutSection
                }
                .navigationTitle("Add Workout")
                .navigationBarItems(
                    leading: Button("Cancel") { dismiss() },
                    trailing: Button("Save") { saveWorkout() }
                )
            }
        }
    }

    private var workoutDaySection: some View {
        Section(header: Text("Workout Day: \(workoutDay.nameAttribute ?? "Unknown")")) {
            Text("Type: \(workoutDay.dayType ?? "No Type")")
                .foregroundColor(.gray)
        }
    }

    private var addNewWorkoutSection: some View {
        Section(header: Text("Add New Workout")) {
            VStack(alignment: .leading) {
                workoutNameInput
                recentWorkoutSection
                workoutInputs
                addSetButton
                addedSetsSection
            }
        }
    }

    private var workoutNameInput: some View {
        VStack(alignment: .leading) {
            TextField("Workout Name", text: $workoutName)
                .onChange(of: workoutName) { newValue in
                    fetchSuggestions(for: newValue)
                    fetchMostRecentWorkout(for: newValue)
                }
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if showSuggestions {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(action: {
                                workoutName = suggestion.entry ?? ""
                                showSuggestions = false
                            }) {
                                Text(suggestion.entry ?? "Unnamed Workout")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 150)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }

    private var recentWorkoutSection: some View {
        Group {
            if let recent = recentWorkout {
                Section(header: Text("Most Recent: \(recent.name)")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight: \(recent.weight)")
                        Text("Sets: \(recent.sets)")
                        Text("Reps: \(recent.reps)")
                        Text("Notes: \(recent.notes)")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }

    private var workoutInputs: some View {
        Group {
            TextField("Weight (lbs)", text: $weight)
                .keyboardType(.decimalPad)
            TextField("Sets", text: $sets)
                .keyboardType(.numberPad)
            TextField("Reps", text: $reps)
                .keyboardType(.numberPad)
            TextField("Notes", text: $notes)
        }
    }

    private var addSetButton: some View {
        Button(action: addSet) {
            Text("Add Set")
                .foregroundColor(Color(.white))
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
        }
    }

    private var addedSetsSection: some View {
        Group {
            if !workoutSets.isEmpty {
                Section(header: Text("Sets")) {
                    ForEach(workoutSets) { set in
                        VStack(alignment: .leading) {
                            Text("Weight: \(set.weight)")
                            Text("Sets: \(set.sets)")
                            Text("Reps: \(set.reps)")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }


    private func fetchSuggestions(for input: String) {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            suggestions = []
            showSuggestions = false
            return
        }

        let fetchRequest: NSFetchRequest<JWWorkoutEntryEntity> = JWWorkoutEntryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "entry CONTAINS[cd] %@", trimmedInput)
        fetchRequest.fetchLimit = 10

        do {
            suggestions = try viewContext.fetch(fetchRequest)
            showSuggestions = !suggestions.isEmpty
        } catch {
            print("Error fetching suggestions: \(error)")
            suggestions = []
            showSuggestions = false
        }
    }

    private func fetchMostRecentWorkout(for name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            recentWorkout = nil
            return
        }

        let namePredicate = NSPredicate(format: "name CONTAINS[c] %@", trimmedName)
        let sortDescriptor = NSSortDescriptor(key: "objectID", ascending: false)

        let request: NSFetchRequest<JWWorkoutEntity> = JWWorkoutEntity.fetchRequest()
        request.predicate = namePredicate
        request.sortDescriptors = [sortDescriptor]

        do {
            let workouts = try viewContext.fetch(request)
            if let mostRecentWorkout = workouts.first {
                // Fetch associated sets
                if let sets = mostRecentWorkout.workoutSets as? Set<JWWorkoutSetEntity> {
                    let sortedSets = sets.sorted { $0.objectID.uriRepresentation().absoluteString < $1.objectID.uriRepresentation().absoluteString }

                    // Concatenate set details (e.g., for the first set, or aggregate as needed)
                    if let firstSet = sortedSets.first {
                        recentWorkout = (
                            name: mostRecentWorkout.name ?? "No Name",
                            weight: firstSet.weight ?? "No Weight",
                            sets: firstSet.sets ?? "No Sets",
                            reps: firstSet.reps ?? "No Reps",
                            notes: mostRecentWorkout.notes ?? "No Notes"
                        )
                    } else {
                        recentWorkout = (
                            name: mostRecentWorkout.name ?? "No Name",
                            weight: "No Weight",
                            sets: "No Sets",
                            reps: "No Reps",
                            notes: mostRecentWorkout.notes ?? "No Notes"
                        )
                    }
                }
            } else {
                recentWorkout = nil
            }
        } catch {
            print("Error fetching recent workout: \(error.localizedDescription)")
            recentWorkout = nil
        }
    }

    private func addSet() {
        guard !weight.isEmpty, !sets.isEmpty, !reps.isEmpty else {
            print("Cannot add an empty set.")
            return
        }

        let newSet = WorkoutSet(weight: weight, sets: sets, reps: reps)
        workoutSets.append(newSet)

        weight = ""
        sets = ""
        reps = ""
    }

    private func saveWorkout() {
        guard !workoutName.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("Workout name cannot be empty.")
            return
        }

        // Automatically add the current text field inputs as a set if they are valid
        let trimmedWeight = weight.trimmingCharacters(in: .whitespaces)
        let trimmedSets = sets.trimmingCharacters(in: .whitespaces)
        let trimmedReps = reps.trimmingCharacters(in: .whitespaces)

        if !trimmedWeight.isEmpty, !trimmedSets.isEmpty, !trimmedReps.isEmpty {
            let newSet = WorkoutSet(weight: trimmedWeight, sets: trimmedSets, reps: trimmedReps)
            workoutSets.append(newSet)
        }

        guard !workoutSets.isEmpty else {
            print("No sets provided.")
            return
        }

        let newWorkout = JWWorkoutEntity(context: viewContext)
        newWorkout.name = workoutName
        newWorkout.notes = notes
        newWorkout.workoutDay = workoutDay

        for workoutSet in workoutSets {
            let workoutSetEntity = JWWorkoutSetEntity(context: viewContext)
            workoutSetEntity.weight = workoutSet.weight
            workoutSetEntity.sets = workoutSet.sets
            workoutSetEntity.reps = workoutSet.reps
            newWorkout.addToWorkoutSets(workoutSetEntity)
        }

        do {
            try viewContext.save()
            print("Workout saved successfully.")
            addWorkoutNameToSuggestions(workoutName: workoutName) // Update suggestions
            dismiss()
        } catch {
            print("Error saving workout: \(error.localizedDescription)")
        }
    }
    
    private func addWorkoutNameToSuggestions(workoutName: String) {
        let trimmedName = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Ensure the name is not empty
        guard !trimmedName.isEmpty else {
            print("Workout name is empty. Skipping addition to suggestions.")
            return
        }

        let fetchRequest: NSFetchRequest<JWWorkoutEntryEntity> = JWWorkoutEntryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "entry ==[cd] %@", trimmedName)

        do {
            let existingEntries = try viewContext.fetch(fetchRequest)

            // Add to suggestions if it doesn't already exist
            if existingEntries.isEmpty {
                let newEntry = JWWorkoutEntryEntity(context: viewContext)
                newEntry.entry = trimmedName

                // Save the context
                try viewContext.save()
                print("Saved workout name to Core Data: \(trimmedName)")
            } else {
                print("Workout name already exists in Core Data: \(trimmedName)")
            }
        } catch {
            print("Error saving workout name to Core Data: \(error.localizedDescription)")
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
