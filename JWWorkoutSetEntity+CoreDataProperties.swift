//
//  JWWorkoutSetEntity+CoreDataProperties.swift
//  Workout App for iOS
//
//  Created by Jacob Wildes on 1/21/25.
//
//

import Foundation
import CoreData


extension JWWorkoutSetEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JWWorkoutSetEntity> {
        return NSFetchRequest<JWWorkoutSetEntity>(entityName: "JWWorkoutSetEntity")
    }

    @NSManaged public var weight: String?
    @NSManaged public var sets: String?
    @NSManaged public var reps: String?
    @NSManaged public var workout: JWWorkoutEntity?

}

extension JWWorkoutSetEntity : Identifiable {

}
