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
    
    @State private var workouts: [JWWorkoutEntity] = [] // Store workouts
    @State private var selectedWorkouts: [String] = [] // Selected workout names for graphs
    @State private var isSelectingWorkout: Bool = false // Controls selection sheet
    @State private var showWeight: Bool = true // Toggle between weight and volume

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
                                WorkoutGraph(
                                    workouts: filteredWorkouts(for: workoutName),
                                    workoutName: workoutName,
                                    showWeight: showWeight
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Graphs")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Toggle(isOn: $showWeight) {
                        Text(showWeight ? "Weight" : "Volume")
                    }
                    .toggleStyle(SwitchToggleStyle())
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isSelectingWorkout = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isSelectingWorkout) {
                WorkoutSelectionView(
                    workouts: workouts,
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
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "objectID", ascending: true)]
        do {
            workouts = try viewContext.fetch(fetchRequest)
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
                Text(workoutName)
                    .font(.headline)

                if workouts.isEmpty {
                    Text("No data available.")
                        .foregroundColor(.gray)
                } else {
                    Chart {
                        ForEach(workouts.indices, id: \.self) { index in
                            let workout = workouts[index]
                            
                            // Calculate value based on toggle (Weight or Volume)
                            let value = showWeight ? calculateWeight(for: workout) : calculateVolume(for: workout)
                            
                            LineMark(
                                x: .value("Order", index), // Order for X-axis
                                y: .value(showWeight ? "Weight" : "Volume", value) // Y-axis based on toggle
                            )
                            PointMark(
                                x: .value("Order", index),
                                y: .value(showWeight ? "Weight" : "Volume", value)
                            )
                            .annotation {
                                Text("\(value, specifier: "%.1f")")
                                    .font(.caption)
                                    .padding(5)
                                    .foregroundColor(.white)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(5)
                                    .shadow(radius: 5)
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(.top, 10)
                }
            }
        }
    
    // Calculate the weighted average weight for the workout
    private func calculateWeight(for workout: JWWorkoutEntity) -> Float {
        guard let sets = workout.workoutSets as? Set<JWWorkoutSetEntity>, !sets.isEmpty else {
            return 0
        }
        let totalWeight = sets.reduce(0) { $0 + (Float($1.weight ?? "") ?? 0) }
        return totalWeight / Float(sets.count) // Weighted average of weight
    }

    // Calculate the total volume for the workout: Volume = Sets x Reps x Weight
    private func calculateVolume(for workout: JWWorkoutEntity) -> Float {
        guard let sets = workout.workoutSets as? Set<JWWorkoutSetEntity>, !sets.isEmpty else {
            return 0
        }
        return sets.reduce(0) { total, set in
            let setCount = Float(set.sets ?? "") ?? 0
            let repsCount = Float(set.reps ?? "") ?? 0
            let weight = Float(set.weight ?? "") ?? 0
            return total + (setCount * repsCount * weight)
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
            let names = allEntries.compactMap { $0.entry }
            return Array(Set(names)).sorted()
        } catch {
            print("Failed to fetch workout entry names: \(error.localizedDescription)")
            return []
        }
    }
}
