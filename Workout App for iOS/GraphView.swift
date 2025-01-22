//
//  GraphView.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/16/25.
//

import SwiftUI
import Charts
import CoreData

struct GraphView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var workouts: [JWWorkoutEntity] = [] // Store workouts manually
    @State private var selectedWorkouts: [String] = [] // Stores selected workout names for graphs
    @State private var isSelectingWorkout: Bool = false // Controls the workout selection sheet
    @State private var showWeight: Bool = true // Toggle between Weight and Volume

    var body: some View {
        NavigationView {
            VStack {
                // Display a message when no workouts are selected
                if selectedWorkouts.isEmpty {
                    Text("No graphs selected. Tap '+' to add a graph.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(selectedWorkouts, id: \.self) { workoutName in
                                WorkoutGraph(
                                    workouts: filteredWorkouts(for: workoutName),
                                    workoutName: workoutName,
                                    showWeight: showWeight // Pass the toggle value to the graph view
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Graphs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isSelectingWorkout = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isSelectingWorkout) {
                WorkoutSelectionView(
                    workouts: workouts, // Passing workouts array for selection
                    selectedWorkouts: $selectedWorkouts,
                    isPresented: $isSelectingWorkout
                )
            }
            .toolbar {
                // Add a toggle to switch between Weight and Volume
                ToolbarItem(placement: .navigationBarLeading) {
                    Toggle(isOn: $showWeight) {
                        Text(showWeight ? "Weight" : "Volume")
                    }
                    .toggleStyle(SwitchToggleStyle())
                }
            }
        }
        .onAppear {
            fetchWorkouts()
        }
    }
    
    private func fetchWorkouts() {
        let fetchRequest = NSFetchRequest<JWWorkoutEntity>(entityName: "JWWorkoutEntity")
        
        // Sorting by rowID, which corresponds to SQLite row order
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "objectID", ascending: true)] // Sort by objectID
        
        do {
            let allWorkouts = try viewContext.fetch(fetchRequest)
            workouts = allWorkouts // Store the fetched workouts
        } catch {
            print("Failed to fetch workouts: \(error.localizedDescription)")
        }
    }
    
    private func filteredWorkouts(for workoutName: String) -> [JWWorkoutEntity] {
        workouts.filter { $0.name == workoutName }
    }
}

struct WorkoutGraph: View {
    let workouts: [JWWorkoutEntity] // The list of filtered workouts
    let workoutName: String // The name of the workout to display dynamically as the title
    let showWeight: Bool // The toggle to choose between Weight and Volume
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(workoutName)  // Use the workout name dynamically as the title
                .font(.headline)
            
            if workouts.isEmpty {
                Text("No data available.")
                    .foregroundColor(.gray)
            } else {
                Chart {
                    ForEach(workouts.indices, id: \.self) { index in
                        let workout = workouts[index]
                        
                        // Calculate the value (Weight or Volume) depending on the toggle
                        let value = showWeight ? calculateWeight(for: workout) : calculateVolume(for: workout)
                        
                        // Plot the graph with the selected value
                        LineMark(
                            x: .value("Order", index),
                            y: .value("Value", value)
                        )
                        PointMark(
                            x: .value("Order", index),
                            y: .value("Value", value)
                        )
                    }
                }
                .frame(height: 200)
                .padding(.top, 10)
            }
        }
    }
    
    // Calculate the weighted average for the workout (Weight)
    private func calculateWeight(for workout: JWWorkoutEntity) -> Float {
        if let weightString = workout.weight, let weight = Float(weightString) {
            return weight
        }
        return 0
    }
    
    // Calculate the volume for the workout: Volume = Sets x Reps x Weight
    private func calculateVolume(for workout: JWWorkoutEntity) -> Float {
        guard let setsString = workout.sets, let repsString = workout.reps,
              let sets = Int(setsString), let reps = Int(repsString),
              let weightString = workout.weight, let weight = Float(weightString) else {
            return 0
        }
        return Float(sets * reps) * weight
    }
}


struct WorkoutSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let workouts: [JWWorkoutEntity] // Now this is an array of JWWorkoutEntity
    @Binding var selectedWorkouts: [String]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(uniqueWorkoutNames(), id: \.self) { workoutName in
                    Button {
                        if !selectedWorkouts.contains(workoutName) {
                            selectedWorkouts.append(workoutName)
                        }
                        isPresented = false // Dismiss the sheet
                    } label: {
                        HStack {
                            Text(workoutName)
                            Spacer()
                            if selectedWorkouts.contains(workoutName) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Workout")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
    
    /// Extracts unique workout names from the `JWWorkoutEntryEntity` dataset.
    private func uniqueWorkoutNames() -> [String] {
        let fetchRequest = NSFetchRequest<JWWorkoutEntryEntity>(entityName: "JWWorkoutEntryEntity")
        
        do {
            let allEntries = try viewContext.fetch(fetchRequest)
            let names = allEntries.compactMap { $0.entry }
            return Array(Set(names)).sorted()
        } catch {
            print("Failed to fetch workout entry names: \(error.localizedDescription)")
            return []
        }
    }
}
