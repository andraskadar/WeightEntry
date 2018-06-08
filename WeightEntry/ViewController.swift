//
//  ViewController.swift
//  WeightEntry
//
//  Created by Andras Kadar on 5/10/18.
//  Copyright © 2018 Andras Kadar. All rights reserved.
//

import UIKit
import RxSwift
import RxOptional
import RxCocoa
import NSObject_Rx
import WatchConnectivity
import WCSessionRx

class ViewController: UIViewController {

    @IBOutlet fileprivate weak var tableView: UITableView!
    
    private let weightsRelay = BehaviorRelay<[WeightModel]>(value: DataStorage.storedWeights())
    
    private let watchConnectivity: WatchConnectivityServiceType = WatchConnectivityService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        weightsRelay.asDriver()
            .drive(tableView.rx.items(cellIdentifier: "WeightEntryTableViewCell", cellType: UITableViewCell.self)) { (_, model, cell) in
                cell.textLabel?.text = "\(model.weight)"
                cell.detailTextLabel?.text = "\(model.time)"
            }
            .disposed(by: rx.disposeBag)
        
        let session = WCSession.default
        session.activate()
        
        watchConnectivity.startSession()
        watchConnectivity.hasActiveConnection
            .filter { $0 }
            .flatMap { [unowned self] _ in self.watchConnectivity.didReceiveObject(type: WeightModel.self) }
            .map(DataStorage.store)
            .map { _ in DataStorage.storedWeights() }
            .bind(to: weightsRelay)
            .disposed(by: rx.disposeBag)
    }

}

