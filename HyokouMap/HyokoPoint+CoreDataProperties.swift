//
//  HyokoPoint+CoreDataProperties.swift
//  HyokouMap
//
//  Created by SawakiRyusuke on 2015/11/07.
//  Copyright © 2015年 SawakiRyusuke. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension HyokoPoint {

    @NSManaged var latitude: String?
    @NSManaged var longitude: String?
    @NSManaged var regist_dt: Date?
    @NSManaged var elevation: String?
    @NSManaged var memo: String?
    @NSManaged var address: String?

}
