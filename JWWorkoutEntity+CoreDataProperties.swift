//
//  JWWorkoutEntity+CoreDataProperties.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/14/25.
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
    @NSManaged public var reps: String
    @NSManaged public var sets: String
    @NSManaged public var weight: String?
    @NSManaged public var week: JWWeekEntity?
    @NSManaged public var workoutDay: JWWorkoutDayEntity?

}

extension JWWorkoutEntity : Identifiable {

}
