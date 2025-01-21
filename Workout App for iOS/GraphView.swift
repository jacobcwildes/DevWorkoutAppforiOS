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

    var body: some View {
        NavigationView {
            VStack {
                if selectedWorkouts.isEmpty {
                    Text("No graphs selected. Tap '+' to add a graph.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(selectedWorkouts, id: \.self) { workoutName in
                                WorkoutGraph(workouts: filteredWorkouts(for: workoutName), workoutName: workoutName)
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
            
            // Optionally print the fetched workouts for debugging
            print("Fetched workouts ordered by ROWID:")
            for workout in allWorkouts {
                print("Workout: \(workout.name ?? "Unnamed"), Weight: \(workout.weight ?? "No weight")")
            }
            
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
                        if let weight = Float(workout.weight ?? "") {
                            LineMark(
                                x: .value("Order", index), // Use index for X-axis (most recent will be on the right)
                                y: .value("Weight", weight)
                            )
                            PointMark(
                                x: .value("Order", index), // Use index for X-axis (most recent will be on the right)
                                y: .value("Weight", weight)
                            )
                        }
                    }
                }
                .frame(height: 200)
            }
        }
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
            let names = allEntries.compactMap { $0.entry } // Assuming 'entry' is the workout name
            return Array(Set(names)).sorted()
        } catch {
            print("Failed to fetch workout entry names: \(error.localizedDescription)")
            return []
        }
    }
}


