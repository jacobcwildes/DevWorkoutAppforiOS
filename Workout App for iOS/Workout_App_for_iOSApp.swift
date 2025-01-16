//
//  Workout_App_for_iOSApp.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/10/25.
//

import SwiftUI

@main
struct Workout_App_for_iOSApp: App {
        var body: some Scene {
            WindowGroup {
                MainTabView()
                    .environment(\.managedObjectContext, PersistenceController.shared.context)
            }
        }
    }

    struct MainTabView: View {
        var body: some View {
            TabView {
                WorkoutsView()
                    .tabItem {
                        Label("Workouts", systemImage: "list.bullet")
                    }
                
                GraphsView()
                    .tabItem {
                        Label("Graphs", systemImage: "chart.bar")
                    }
                
                DietView()
                    .tabItem {
                        Label("Nutrition", systemImage: "gear")
                    }
            }
        }
    }

    struct WorkoutsView: View {
        var body: some View {
            NavigationView {
                // Main workout management view
                VStack {
                    WelcomeScreen()
                }
                .navigationTitle("Workouts")
            }
        }
    }

    struct GraphsView: View {
        var body: some View {
            NavigationView {
                VStack {
                    GraphView()
                }
                .navigationTitle("Graphs")
            }
        }
    }

    struct DietView: View {
        var body: some View {
            NavigationView {
                VStack {
                    NutritionView()
                }
                .navigationTitle("Diet")
            }
        }
    }
