//
//  RxWCSessionDelegateProxy.swift
//  WCSession+Rx
//
//  Created by Inomoto Shintaro on 2017/02/19.
//  Copyright © 2017年 Inomoto Shintaro. All rights reserved.
//

import WatchConnectivity
import RxSwift
import RxCocoa

extension WCSession: HasDelegate {
    public typealias Delegate = WCSessionDelegate
}

@available(iOS 9.3, *)
@available(watchOSApplicationExtension 2.2, *)
public class RxWCSessionDelegateProxy: DelegateProxy<WCSession, WCSessionDelegate>, WCSessionDelegate, DelegateProxyType {
    
    public init(session: WCSession) {
        super.init(parentObject: session, delegateProxy: RxWCSessionDelegateProxy.self)
    }
    
    public static func registerKnownImplementations() {
        self.register { RxWCSessionDelegateProxy(session: $0) }
    }
    
    fileprivate var _activationStateSubject: PublishSubject<WCSessionActivationState>?
    
    internal var activationStateSubject: PublishSubject<WCSessionActivationState> {
        if let subject = _activationStateSubject {
            return subject
        }
        
        let subject = PublishSubject<WCSessionActivationState>()
        _activationStateSubject = subject
        
        return subject
    }
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

        if let error = error {
            _activationStateSubject?.on(.error(error))
        } else {
            _activationStateSubject?.on(.next(activationState))
        }
        
        _forwardToDelegate?.session(session, activationDidCompleteWith: activationState, error: error)
    }
    
    #if os(iOS)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
        
    }
    #endif
    
    deinit {
        _activationStateSubject?.on(.completed)
    }
    
}
