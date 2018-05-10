//
//  ViewController.swift
//  WeightEntry
//
//  Created by Andras Kadar on 5/10/18.
//  Copyright © 2018 Andras Kadar. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx
import WatchConnectivity

class ViewController: UIViewController {

    @IBOutlet fileprivate weak var tableView: UITableView!
    
    private let weightsRelay = BehaviorRelay<[WeightModel]>(value: DataStorage.storedWeights())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weightsRelay.asDriver()
            .drive(tableView.rx.items(cellIdentifier: "WeightEntryTableViewCell", cellType: UITableViewCell.self)) { (_, model, cell) in
                cell.textLabel?.text = "\(model.weight)"
                cell.detailTextLabel?.text = "\(model.time)"
            }
            .disposed(by: rx.disposeBag)
        
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

}

extension ViewController: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Session Did Complete: \(activationState) - error: \(error)")
        if activationState == .activated {
            print(session.receivedApplicationContext)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session did deactivate")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        guard let newWeightData = message["newWeight"] as? Data,
            let newWeight = try? JSONDecoder().decode(WeightModel.self, from: newWeightData)
            else { return }
        
        print("New weight received: \(newWeight)")
        replyHandler(["success": true])
        DataStorage.store(weight: newWeight)
        weightsRelay.accept(DataStorage.storedWeights())
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Received context: \(applicationContext)")
    }
    
    
}

