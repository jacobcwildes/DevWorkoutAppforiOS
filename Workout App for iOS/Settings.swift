//
//  Settings.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/20/25.
//

import SwiftUI
import CoreData

struct Settings: View {
    @State private var isManageEntriesPresented: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Button("Manage Entries") {
                    isManageEntriesPresented = true
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $isManageEntriesPresented) {
                ManageEntriesView()
                    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            }
        }
    }
}

struct ManageEntriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    @FetchRequest(
        entity: JWWorkoutEntryEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \JWWorkoutEntryEntity.entry, ascending: true)]
    ) private var entries: FetchedResults<JWWorkoutEntryEntity>
    
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search Entries", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                List {
                    ForEach(entries.filter { searchText.isEmpty || ($0.entry?.contains(searchText) ?? false) }, id: \.self) { entry in
                        HStack {
                            Text(entry.entry ?? "Unnamed Entry")
                                .foregroundColor(.primary)
                            Spacer()
                            Button(action: {
                                removeEntry(entry)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Manage Entries")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismissView()
                    }
                }
            }
        }
    }
    
    private func removeEntry(_ entry: JWWorkoutEntryEntity) {
        withAnimation {
            viewContext.delete(entry)
            do {
                try viewContext.save()
            } catch {
                print("Error deleting entry: \(error.localizedDescription)")
            }
        }
    }
    
    private func dismissView() {
        dismiss()
    }
}

