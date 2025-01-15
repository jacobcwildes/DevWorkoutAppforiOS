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
            Spacer()
            
            Text("Welcome to the Workout App")
                .font(.largeTitle)
                .padding()
            
            // Button to navigate
            NavigationLink(destination: WorkoutSelectorScreen()) {
                Text("Begin!")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Spacer()
            
            Text("Built by Jacob Wildes")
                .foregroundColor(.red)
                .font(.footnote)
                .padding(.bottom, 5)
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
