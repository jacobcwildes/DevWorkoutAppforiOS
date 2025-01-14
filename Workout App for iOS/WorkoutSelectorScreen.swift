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
                AddWeekModal()
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
        return viewModel.workoutDays.sorted {
            guard let firstDay = $0.nameAttribute, let secondDay = $1.dayType else { return false }
            return daysOrder.firstIndex(of: firstDay) ?? 0 < daysOrder.firstIndex(of: secondDay) ?? 0
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
    @State private var sets: String = ""  // Keep as String for user input
    @State private var reps: String = ""  // Keep as String for user input
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout Day: \(workoutDay.nameAttribute ?? "Unknown")")) {
                    Text("Type: \(workoutDay.dayType ?? "No Type")")
                        .foregroundColor(.gray)
                }
                
                Section(header: Text("Add New Workout")) {
                    TextField("Workout Name", text: $workoutName)
                    
                    // Weight input as text field
                    TextField("Weight (lbs)", text: $weight)
                        .keyboardType(.decimalPad) // Allow decimal input for weight
                    
                    // Sets input as text field
                    TextField("Sets", text: $sets)
                        .keyboardType(.numberPad) // Allow only numbers for sets
                    
                    // Reps input as text field
                    TextField("Reps", text: $reps)
                        .keyboardType(.numberPad) // Allow only numbers for reps
                    
                    // Notes input as text field
                    TextField("Notes", text: $notes)
                }
            }
            .navigationTitle("Add Workout")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            }, trailing: Button("Save") {
                // Use the viewModel's addWorkout method
                    viewModel.addWorkout(workoutName: workoutName, weight: weight, sets: sets, reps: reps, notes: notes)
                    dismiss()
            })
        }
    }
}


struct AddWeekModal: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    @State private var weekNumber: Int32 = 1
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Week Details")) {
                    Stepper("Week Number: \(weekNumber)", value: $weekNumber, in: 1...52)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
            }
            .navigationTitle("Add Week")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    addWeek()
                    dismiss()
                }
            )
        }
    }
    
    private func addWeek() {
        guard startDate <= endDate else {
            print("Start date must be before or equal to end date.")
            return
        }
        
        let newWeek = JWWeekEntity(context: viewContext)
        newWeek.weekNumber = weekNumber
        newWeek.startDate = startDate
        newWeek.endDate = endDate
        saveContext()
    }

    
    private func saveContext() {
        do {
            try viewContext.save()
            print("Saved week successfully")
        } catch {
            print("Failed to save new week: \(error.localizedDescription)")
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
