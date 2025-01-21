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
                        Label("Nutrition", systemImage: "fork.knife.circle")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
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
            }
        }
    }

    struct GraphsView: View {
        var body: some View {
            NavigationView {
                VStack {
                    GraphView()
                }
            }
        }
    }

    struct DietView: View {
        var body: some View {
            NavigationView {
                VStack {
                    NutritionView()
                }
            }
        }
    }
        
    struct SettingsView: View{
        var body: some View {
            NavigationView {
                VStack {
                    Settings()
                }
            }
        }
    }
