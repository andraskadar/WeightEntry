//
//  DataStorage.swift
//  WeightEntry
//
//  Created by Andras Kadar on 5/10/18.
//  Copyright © 2018 Andras Kadar. All rights reserved.
//

import Foundation

final class DataStorage {
    
    private struct Constants {
        static let weightsKey = "StoredWeights"
    }
    
    static func storedWeights() -> [WeightModel] {
        guard let data = UserDefaults.standard.data(forKey: Constants.weightsKey),
            let weights = try? JSONDecoder().decode([WeightModel].self, from: data)
            else { return [] }
        return weights
    }
    
    static func store(weight: WeightModel) {
        var weights = storedWeights()
        weights.append(weight)
        guard let data = try? JSONEncoder().encode(weights) else { return }
        UserDefaults.standard.setValue(data, forKey: Constants.weightsKey)
    }
    
}
