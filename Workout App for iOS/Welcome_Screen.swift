//
//  Welcome_Screen.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/10/25.
//

import SwiftUI

struct WelcomeScreen: View {
    
    var body: some View {
        VStack {
            Text("Welcome to the Workout App")
                .font(.largeTitle)
                .padding()
            
            // Button to navigate
            NavigationLink(destination: WorkoutSelectorScreen()) {
                Text("Start Workout")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .navigationTitle("Welcome")
        .padding()
    }
}

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen()
    }
}
