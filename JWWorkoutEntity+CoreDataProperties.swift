//
//  JWWorkoutEntity+CoreDataProperties.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/13/25.
//
//

import Foundation
import CoreData


extension JWWorkoutEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JWWorkoutEntity> {
        return NSFetchRequest<JWWorkoutEntity>(entityName: "JWWorkoutEntity")
    }

    @NSManaged public var date: Date?
    @NSManaged public var name: String?
    @NSManaged public var notes: String?
    @NSManaged public var reps: Int32
    @NSManaged public var sets: Int32
    @NSManaged public var weight: Double
    @NSManaged public var week: JWWeekEntity?
    @NSManaged public var workoutDay: JWWorkoutDayEntity?

}

extension JWWorkoutEntity : Identifiable {

}
