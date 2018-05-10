//
//  WeightEntryInterfaceController.swift
//  WeightEntryWatch Extension
//
//  Created by Andras Kadar on 5/10/18.
//  Copyright © 2018 Andras Kadar. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation

import RxSwift
import RxCocoa
import NSObject_Rx

import WCSessionRx

class WeightEntryInterfaceController: WKInterfaceController {
    
    @IBOutlet var lastEntryValueLabel: WKInterfaceLabel!
    @IBOutlet var lastEntryTimeLabel: WKInterfaceLabel!
    @IBOutlet var weightEntryLabel: WKInterfaceLabel!
    @IBOutlet var weightEntryTimeLabel: WKInterfaceLabel!
    @IBOutlet var addWeightButton: WKInterfaceButton!
    
    //Interface device, mostly us for haptic feedback
    private let interfaceDevice = WKInterfaceDevice()
    private let session = WCSession.default
    
    private var crownAccumulator: Double = 0
    private let currentWeightRelay = BehaviorRelay<Double>(value: 70)
    private let currentWeightTimeRelay = BehaviorRelay<Date>(value: Date())
    
    fileprivate struct Constants {
        static let crownRotationMinimumRotation: Double = 0.1
        static let crownRotationStep: Double = 0.1
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        
        WCSession.default.rx.activationState
            .subscribe(onNext: { state in
                print(state.rawValue)
            }, onError: { (error) in
                print(error)
            })
            .disposed(by: rx.disposeBag)
        
        currentWeightRelay
            .subscribe(onNext: { [unowned self] weight in
                self.weightEntryLabel.setText(weight.weightText)
            })
            .disposed(by: rx.disposeBag)
        
        currentWeightTimeRelay
            .subscribe(onNext: { [unowned self] time in
                self.weightEntryTimeLabel.setText(time.timeText)
            })
            .disposed(by: rx.disposeBag)
        
        crownSequencer.delegate = self
        
    }
    
    @IBAction func didTapAddWeightButton() {
        let weight = WeightModel(weight: currentWeightRelay.value,
                                 time: currentWeightTimeRelay.value)
        // Reset time
        currentWeightTimeRelay.accept(Date())
        guard let data = try? JSONEncoder().encode(weight)
            else { return }
        let weightMessage: [String: Any] = ["newWeight": data]
        
        session.sendMessage(weightMessage, replyHandler: { (reply) in
            print(reply)
        }) { (error) in
            try? self.session.updateApplicationContext(weightMessage)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        WCSession.default.activate()
        crownSequencer.focus()
        currentWeightTimeRelay.accept(Date())
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

extension WeightEntryInterfaceController: WKCrownDelegate {
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        crownAccumulator += rotationalDelta
        
        guard abs(crownAccumulator) > Constants.crownRotationMinimumRotation else { return }
        let direction: Double = crownAccumulator > 0 ? +1 : -1
        currentWeightRelay.accept(currentWeightRelay.value + direction * Constants.crownRotationStep)
        crownAccumulator = 0
    }
}

private extension Date {
    var timeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

private extension Double {
    var weightText: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.positiveSuffix = " kg"
        return formatter.string(from: NSNumber(value: self))!
    }
}
