//
//  WeightModel.swift
//  WeightEntry
//
//  Created by Andras Kadar on 5/10/18.
//  Copyright © 2018 Andras Kadar. All rights reserved.
//

import Foundation

struct WeightModel: Codable {
    let weight: Double // In kg
    let time: Date
}

extension WeightModel {
    init?(dict: [String: Any]) {
        guard let weight = dict["weight"] as? Double,
            let time = dict["time"] as? Date else { return nil }
        self.weight = weight
        self.time = time
    }
    
    var dict: [String: Any] {
        return ["weight": weight, "time": time]
    }
}
