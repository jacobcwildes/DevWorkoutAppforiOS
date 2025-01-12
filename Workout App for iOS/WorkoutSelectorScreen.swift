//
//  NextScreen.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/10/25.
//

import SwiftUI

struct WorkoutSelectorScreen: View {
    @State private var showModal = false
    @State private var selectedWorkouts: [String: String] = [:]
    @State private var selectedDay: IdentifiableDay? = nil // Use IdentifiableDay
    
    var body: some View {
        NavigationView {
            VStack {
                if selectedWorkouts.isEmpty {
                    Text("Please add workout days by tapping '+'")
                        .font(.headline)
                        .padding()
                } else {
                    List {
                        ForEach(Array(selectedWorkouts.keys.sorted()), id: \.self) { day in
                            HStack {
                                Text("\(day):")
                                    .font(.headline)
                                Spacer()
                                Text(selectedWorkouts[day] ?? "None")
                                    .foregroundColor(.gray)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedDay = IdentifiableDay(day: day) // Wrap day in IdentifiableDay
                            }
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle("Workout")
            .navigationBarItems(trailing: Button(action: {
                showModal = true
            }) {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.blue)
            })
            .sheet(isPresented: $showModal) {
                ModalView(selectedWorkouts: $selectedWorkouts)
            }
            .sheet(item: $selectedDay) { identifiableDay in
                WorkoutDetailView(day: identifiableDay.day) // Pass only the day
            }
        }
    }
}

struct IdentifiableDay: Identifiable{
    let id = UUID()
    let day: String
}

struct Workout: Identifiable {
    let id = UUID()
    let name: String
    let weight: Int
    let sets: Int
    let reps: Int
    let notes: String
}


struct ModalView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedWorkouts: [String: String]
    @State private var selectedDay: IdentifiableDay? = nil // Stores currently selected day for editing
    
    private let workoutTypes = ["Rest", "Push", "Pull", "Legs"]
    
    var body: some View {
        VStack {
            // Week Header
            Text("Weekly Workout Plan")
                .font(.largeTitle)
                .padding()
            
            // Vertical List of Days
            List(daysOfWeek, id: \.self) { day in
                HStack {
                    Text("\(day):")
                        .font(.headline)
                    Spacer()
                    Text(selectedWorkouts[day] ?? "None")
                        .foregroundColor(.gray)
                        .onTapGesture {
                            assignWorkout(for: day)
                        }
                        .padding(.trailing)
                }
            }
            
            // Close Button
            Button("Close") {
                dismiss()
            }
            .padding()
        }
        // Workout Type Selection Modal
        .sheet(item: $selectedDay) { identifiableDay in
            WorkoutTypeSelectionView(day: identifiableDay.day, selectedWorkouts: $selectedWorkouts)
        }
    }
    
    // List of Days
    private var daysOfWeek: [String] {
        ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    }
    
    // MARK: - Workout Assignment
    private func assignWorkout(for day: String) {
        selectedDay = IdentifiableDay(day: day)
    }
}

struct WorkoutTypeSelectionView: View {
    var day: String
    @Binding var selectedWorkouts: [String: String]
    @Environment(\.dismiss) var dismiss
    
    let workoutTypes = ["Rest", "Push", "Pull", "Legs"]
    
    var body: some View {
        VStack {
            Text("Select Workout for \(day)")
                .font(.title)
                .padding()
            
            // List of Workout Types
            List(workoutTypes, id: \.self) { type in
                Button(type) {
                    selectedWorkouts[day] = type
                    dismiss()
                }
                .padding()
            }
            
            // Cancel Button
            Button("Cancel") {
                dismiss()
            }
            .padding()
        }
    }
}


// MARK: - Helper Extensions
extension Date {
    func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }
}

struct WorkoutDetailView: View {
    var day: String
    @State private var workouts: [Workout] = []
    @State private var showAddWorkoutModal = false
    
    var body: some View {
        VStack {
            if workouts.isEmpty {
                Text("No workouts added for \(day). Tap '+' to add one.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(workouts) { workout in
                    VStack(alignment: .leading) {
                        Text(workout.name)
                            .font(.headline)
                        Text("Weight: \(workout.weight) lbs, \(workout.sets) sets x \(workout.reps) reps")
                            .font(.subheadline)
                        if !workout.notes.isEmpty {
                            Text("Notes: \(workout.notes)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .navigationTitle("\(day) Workouts")
        .navigationBarItems(trailing: Button(action: {
            showAddWorkoutModal = true
        }) {
            Image(systemName: "plus")
                .font(.title)
        })
        .sheet(isPresented: $showAddWorkoutModal) {
            AddWorkoutView(workouts: $workouts)
        }
    }
}

struct AddWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var workouts: [Workout]
    
    @State private var name = ""
    @State private var weight = ""
    @State private var sets = ""
    @State private var reps = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Workout Details")) {
                    TextField("Workout Name", text: $name)
                    TextField("Weight (lbs)", text: $weight)
                        .keyboardType(.decimalPad)
                    TextField("Sets", text: $sets)
                        .keyboardType(.numberPad)
                    TextField("Reps", text: $reps)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Notes")) {
                    TextField("Additional Notes", text: $notes)
                }
            }
            .navigationTitle("Add Workout")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            }, trailing: Button("Save") {
                saveWorkout()
                dismiss()
            })
        }
    }
    
    private func saveWorkout() {
        guard let weight = Int(weight),
              let sets = Int(sets),
              let reps = Int(reps),
              !name.isEmpty else { return }
        
        let newWorkout = Workout(name: name, weight: weight, sets: sets, reps: reps, notes: notes)
        workouts.append(newWorkout)
    }
}


#Preview{
    WorkoutSelectorScreen()
}
