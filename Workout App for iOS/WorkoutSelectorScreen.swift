//
//  NextScreen.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/10/25.
//

import SwiftUI

struct WorkoutSelectorScreen: View {
    var body: some View {
        VStack {
            Text("Get ready for your workout!")
                .font(.title)
                .padding()
        }
        .navigationTitle("Workout")
        .padding()
    }
}


#Preview {
    WorkoutSelectorScreen()
}
