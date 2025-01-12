import CoreData
import SwiftUI

// This struct manages the Core Data stack for SwiftUI apps
struct PersistenceController {
    static let shared = PersistenceController()

    // The persistent container to hold the managed object context
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WorkoutModel") // Replace with your model name
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unresolved error \(error), \(error.localizedDescription)")
            }
        }
    }

    // Managed Object Context
    var context: NSManagedObjectContext {
        return container.viewContext
    }

    // Save the context
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
