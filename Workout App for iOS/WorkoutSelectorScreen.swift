//
//  NextScreen.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/10/25.
//

import SwiftUI

struct WorkoutSelectorScreen: View {
    @State private var showModal = false
    
    var body: some View {
        VStack {
            Text("Get ready for your workout!")
                .font(.title)
                .padding()
        }
        .navigationTitle("Workout")
        .navigationBarItems(trailing: Button(action: {
            showModal = true
            print("Add workout tapped")
        }) {
            Image(systemName: "plus")
                .font(.title)
                .foregroundColor(.blue)
        })
        .sheet(isPresented: $showModal) {
            ModalView()
        }
    }
}

struct IdentifiableDay: Identifiable{
    let id = UUID()
    let day: String
}

struct ModalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedWorkouts: [String: String] = [:] // Stores workouts or rest days for each day
    @State private var currentWeekStart: Date = Date().startOfWeek() // Tracks start of the current week
    @State private var selectedDay: IdentifiableDay? = nil // To track the currently selected day for input

    var body: some View {
        VStack {
            // Header to navigate between weeks
            HStack {
                Button("Previous Week") {
                    changeWeek(by: -1)
                }
                Spacer()
                Text(weekRange)
                    .font(.headline)
                Spacer()
                Button("Next Week") {
                    changeWeek(by: 1)
                }
            }
            .padding()
            
            // Days of the Week
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 20) {
                ForEach(daysOfWeek, id: \.self) { day in
                    VStack {
                        Text(day)
                            .font(.headline)
                        
                        Button(action: {
                            assignWorkout(for: day)
                        }) {
                            Text(selectedWorkouts[day] ?? "Add")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedWorkouts[day] == "Rest" ? Color.red : Color.blue.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            
            // Close Button
            Button("Close") {
                dismiss()
            }
            .padding()
        }
        // Workout Input Modal
        .sheet(item: $selectedDay) { identifiableDay in
            WorkoutInputView(day: identifiableDay.day, selectedWorkouts: $selectedWorkouts)
        }

    }
    
    // MARK: - Days of the Week
    private var daysOfWeek: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return (0..<7).compactMap { index in
            let date = Calendar.current.date(byAdding: .day, value: index, to: currentWeekStart)
            return formatter.string(from: date ?? Date())
        }
    }
    
    // MARK: - Week Range
    private var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart)!
        return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: endOfWeek))"
    }
    
    // MARK: - Week Navigation
    private func changeWeek(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .weekOfYear, value: value, to: currentWeekStart) {
            currentWeekStart = newDate
        }
    }
    
    // MARK: - Workout Assignment
    private func assignWorkout(for day: String) {
        selectedDay = IdentifiableDay(day: day)
    }
}

struct WorkoutInputView: View {
    let day: String
    @Binding var selectedWorkouts: [String: String]
    @Environment(\.dismiss) var dismiss

    @State private var inputText: String = ""

    var body: some View {
        VStack {
            Text("Add Workout for \(day)")
                .font(.headline)
                .padding()

            TextField("Enter Workout (e.g., Chest Day)", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .padding()

                Spacer()

                Button("Save") {
                    selectedWorkouts[day] = inputText.isEmpty ? "Rest" : inputText
                    dismiss()
                }
                .padding()
            }
        }
        .padding()
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

#Preview{
    WorkoutSelectorScreen()
}
