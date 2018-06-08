//
//  WatchConnectivityService.swift
//  WeightEntry
//
//  Created by Andras Kadar on 2018. 05. 11..
//  Copyright © 2018. Andras Kadar. All rights reserved.
//

import Foundation
import RxSwift
import RxOptional
import WatchConnectivity

protocol WatchTransferObject: Codable {
    static var objectKey: String { get }
}

enum WatchConnectivityError: Error {
    case noValidSession
    case noReachableSession
}

protocol WatchConnectivityServiceType {
    var hasActiveConnection: Observable<Bool> { get }
    
    func startSession()
    func didReceiveObject<T: WatchTransferObject>(type objectType: T.Type) -> Observable<T>
}

final class WatchConnectivityService: NSObject {
    
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private var validSession: WCSession? {
        // paired - the user has to have their device paired to the watch
        // watchAppInstalled - the user must have your watch app installed
        
        // Note: if the device is paired, but your watch app is not installed
        // consider prompting the user to install it for a better experience
        if let session = session, session.isPaired && session.isWatchAppInstalled {
            return session
        }
        return nil
    }
    private var validReachableSession: WCSession? {
        if let session = validSession, session.isReachable {
            return session
        }
        return nil
    }
    
    private func getValidSession() -> Observable<WCSession> {
        guard let session = validSession else { return Observable.error(WatchConnectivityError.noValidSession) }
        return Observable.just(session)
    }
    
    private func getValidReachableSession() -> Observable<WCSession> {
        return getValidSession()
            .map { guard $0.isReachable else { throw WatchConnectivityError.noReachableSession }; return $0 }
    }
    
}

extension WatchConnectivityService: WatchConnectivityServiceType {
    var hasActiveConnection: Observable<Bool> {
        guard let session = session else { return Observable.just(false) }
        return session.rx.activationState.startWith(session.activationState)
            .debug("STATE")
            .map { $0 == .activated }
            .debug("HASACTIVECONNECTION")
    }
    
    func startSession() {
        session?.activate()
    }
    
    func sendObject<T: WatchTransferObject>(_ object: T) -> Observable<Void> {
        return getValidReachableSession()
            .flatMap { $0.rx.sendMessage([T.objectKey: try JSONEncoder().encode(object)]) }
            .map { _ in }
    }
    
    func didReceiveObject<T: WatchTransferObject>(type objectType: T.Type) -> Observable<T> {
        return getValidSession()
            .flatMap { $0.rx.didReceiveMessageWithReplyHandler.map { $0.message } }
            .debug("MESSAGE")
            .map { message -> T? in
                guard let data = message[objectType.objectKey] as? Data,
                    let object = try? JSONDecoder().decode(objectType, from: data) else { return nil }
                return object
            }
            .filterNil()
    }
}

/*
// MARK: Application Context
// use when your app needs only the latest information
// if the data was not sent, it will be replaced
extension WatchConnectivityService: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    // Sender
    func updateApplicationContext(applicationContext: [String : Any]) throws {
        if let session = validSession {
            do {
                try session.updateApplicationContext(applicationContext)
            } catch let error {
                throw error
            }
        }
    }
    
    // Receiver
    sessiondidreceiveappli
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        // handle receiving application context
        
    }
}


// MARK: User Info
// use when your app needs all the data
// FIFO queue
extension WatchConnectivityService {
    
    // Sender
    func transferUserInfo(userInfo: [String : Any]) -> WCSessionUserInfoTransfer? {
        
        return validSession?.transferUserInfo(userInfo)
    }
    
    func session(session: WCSession, didFinishUserInfoTransfer userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        // implement this on the sender if you need to confirm that
        // the user info did in fact transfer
    }
    
    // Receiver
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        
    }
    
}

// MARK: Transfer File
extension WatchConnectivityService {
    
    // Sender
    func transferFile(file: URL, metadata: [String : Any]) -> WCSessionFileTransfer? {
        return validSession?.transferFile(file, metadata: metadata)
    }
    
    func session(session: WCSession, didFinishFileTransfer fileTransfer: WCSessionFileTransfer, error: Error?) {
        // handle filed transfer completion
    }
    
    // Receiver
    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        // handle receiving file
        
    }
}


// MARK: Interactive Messaging
extension WatchConnectivityService {
    
    // Live messaging! App has to be reachable
    private var validReachableSession: WCSession? {
        if let session = validSession, session.isReachable {
            return session
        }
        return nil
    }
    
    // Sender
    func sendMessage(message: [String : Any],
                     replyHandler: (([String : Any]) -> Void)? = nil,
                     errorHandler: ((Error) -> Void)? = nil)
    {
        validReachableSession?.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    func sendMessageData(data: Data,
                         replyHandler: ((Data) -> Void)? = nil,
                         errorHandler: ((Error) -> Void)? = nil)
    {
        validReachableSession?.sendMessageData(data, replyHandler: replyHandler, errorHandler: errorHandler)
    }
    
    // Receiver
    func session(session: WCSession, didReceiveMessage message: [String : Any], replyHandler: ([String : Any]) -> Void) {
        
    }
    
    func session(session: WCSession, didReceiveMessageData messageData: Data, replyHandler: (Data) -> Void) {
        
    }
}

 */

extension WeightModel: WatchTransferObject {
    static var objectKey: String { return "Weight" }
}
