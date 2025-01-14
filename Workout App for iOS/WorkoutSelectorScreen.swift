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
    @State private var showAddWorkoutDayModal = false
    
    var body: some View {
        VStack {
            let workouts = (week.workouts as? Set<JWWorkoutEntity>) ?? []
                        
            if workouts.isEmpty {
                Text("No workout days added for this week. Tap '+' to add one.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach((week.workouts?.allObjects as? [JWWorkoutDayEntity]) ?? [], id: \.self) { workoutDay in
                        NavigationLink(destination: WorkoutDayDetailView(workoutDay: workoutDay)) {
                            HStack {
                                Text(workoutDay.nameAttribute ?? "N/A")
                                    .font(.headline)
                                Spacer()
                                Text("\(workoutDay.nameAttribute?.count ?? 0) Workouts")
                                    .foregroundColor(.gray)
                            }
                        }
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
        .sheet(isPresented: $showAddWorkoutDayModal) {
            AddWorkoutDayModal(week: week)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private func deleteWorkoutDay(at offsets: IndexSet) {
        offsets
            .map { (week.workouts?.allObjects as? [JWWorkoutDayEntity])?[$0] }
            .compactMap { $0 } // Remove nil values
            .forEach { workoutDay in
                viewContext.delete(workoutDay) // Pass non-optional workoutDay
            }
        saveContext()
    }

    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to delete workout day: \(error.localizedDescription)")
        }
    }
}

struct WorkoutDayDetailView: View {
    @ObservedObject var workoutDay: JWWorkoutDayEntity
    @State private var showAddWorkoutModal = false
    
    var body: some View {
        VStack {
            if let workouts = workoutDay.workouts?.allObjects as? [JWWorkoutEntity] {
                if workouts.isEmpty {
                    Text("No workouts added for \(workoutDay.nameAttribute ?? "this day"). Tap '+' to add one.")
                        .foregroundColor(.gray)
                        .padding()
                }
            } else {
                List {
                    ForEach((workoutDay.workouts?.allObjects as? [JWWorkoutEntity]) ?? [], id: \.objectID) { workout in
                        VStack(alignment: .leading) {
                            Text(workout.name ?? "N/A")
                                .font(.headline)
                            Text("Weight: \(workout.weight) lbs, \(workout.sets) sets x \(workout.reps) reps")
                                .font(.subheadline)
                            if let notes = workout.notes, !notes.isEmpty {
                                Text("Notes: \(notes)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .onDelete(perform: deleteWorkout)  // Attach delete action to the list
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
            AddWorkoutModal(workoutDay: workoutDay)
        }
        
    }
    private func deleteWorkout(at offsets: IndexSet) {
        // Safely get the workouts array from the NSSet
        guard let workouts = workoutDay.workouts?.allObjects as? [JWWorkoutEntity] else { return }
        
        // Iterate over the selected workouts to delete
        offsets.map { workouts[$0] }.forEach { workout in
            workoutDay.removeFromWorkouts(workout)  // Remove from the workoutDay relationship
        }
        
        // Save the context to persist changes
        saveContext()
    }

    
    private func saveContext() {
        do {
            try workoutDay.managedObjectContext?.save()
        } catch {
            print("Failed to delete workout: \(error.localizedDescription)")
        }
    }
}

struct AddWorkoutDayModal: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @ObservedObject var week: JWWeekEntity
    @State private var dayName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Day Name", text: $dayName)
            }
            .navigationTitle("Add Workout Day")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            }, trailing: Button("Save") {
                addWorkoutDay()
                dismiss()
            })
        }
    }
    
    private func addWorkoutDay() {
        let newWorkoutDay = JWWorkoutDayEntity(context: viewContext)
            newWorkoutDay.nameAttribute = dayName // Set the type (e.g., "push", "pull", "legs")
            
            // Save the new entity
            saveContext()
    }

    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save workout day: \(error.localizedDescription)")
        }
    }
}

struct AddWorkoutModal: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutDay: JWWorkoutDayEntity
    @State private var workoutName: String = ""
    @State private var weight: Double = 0
    @State private var sets: Int32 = 0
    @State private var reps: Int32 = 0
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Workout Name", text: $workoutName)
                Stepper("Weight: \(weight, specifier: "%.1f") lbs", value: $weight, in: 0...1000, step: 2.5)
                Stepper("Sets: \(sets)", value: $sets, in: 0...10)
                Stepper("Reps: \(reps)", value: $reps, in: 0...50)
                TextField("Notes", text: $notes)
            }
            .navigationTitle("Add Workout")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            }, trailing: Button("Save") {
                addWorkout()
                dismiss()
            })
        }
    }
    
    private func addWorkout() {
        let newWorkout = JWWorkoutEntity(context: viewContext)
        newWorkout.name = workoutName
        newWorkout.weight = weight
        newWorkout.sets = sets
        newWorkout.reps = reps
        newWorkout.notes = notes
        
        // Access workoutDay directly, not the Binding
        workoutDay.addToWorkouts(newWorkout)
        
        saveContext()
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save workout: \(error.localizedDescription)")
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
        let newWeek = JWWeekEntity(context: viewContext)
        newWeek.weekNumber = weekNumber
        newWeek.startDate = startDate
        newWeek.endDate = endDate
        saveContext()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save new week: \(error.localizedDescription)")
        }
    }
}

class CoreDataStack {
    static let shared = CoreDataStack()

    // Persistent container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")  // Replace with your model's name
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
