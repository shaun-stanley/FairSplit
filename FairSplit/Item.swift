//
//  Item.swift
//  FairSplit
//
//  Created by Shaun Stanley on 8/24/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
