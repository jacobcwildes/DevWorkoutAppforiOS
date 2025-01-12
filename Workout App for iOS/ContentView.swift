//
//  ContentView.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/10/25.
//

import SwiftUI

struct ContentView: View {
    // Persistence Controller to manage Core Data
    let persistenceController = PersistenceController.shared
    var body: some View {
        NavigationView {
            WelcomeScreen()  //Show the WelcomeScreen as the initial view
                .environment(\.managedObjectContext, persistenceController.context)
                .onChange(of: persistenceController.context.hasChanges) { newValue in
                    if newValue {
                        persistenceController.saveContext()
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
