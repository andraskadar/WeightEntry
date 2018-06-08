//
//  WCSession+Rx.swift
//  WCSession+Rx
//
//  Created by Inomoto Shintaro on 2017/02/19.
//  Copyright © 2017年 Inomoto Shintaro. All rights reserved.
//

import WatchConnectivity
import RxSwift
import RxCocoa

extension Reactive where Base: WCSession {
    public var delegate: DelegateProxy<WCSession, WCSessionDelegate> {
        if #available(watchOSApplicationExtension 2.2, *), #available(iOS 9.3, *) {
            return RxWCSessionDelegateProxy.proxy(for: base)
        } else {
            fatalError("use watchOS 2.2 upper.")
        }
    }
    
    @available(iOS 9.3, *)
    @available(watchOS 2.2, *)
    public var activationState: Observable<WCSessionActivationState> {
        return RxWCSessionDelegateProxy.proxy(for: base).activationStateSubject
    }
    
    @available(iOS 9.3, *)
    @available(watchOS 2.2, *)
    public func sendMessage(_ message: [String: Any]) -> Single<[String: Any]> {
        return Single.create { (observer) -> Disposable in
            self.base.sendMessage(message,
                                  replyHandler: { observer(.success($0)) },
                                  errorHandler: { observer(.error($0)) })
            return Disposables.create()
        }
    }
    
    @available(iOS 9.3, *)
    @available(watchOS 2.2, *)
    public func sendMessageData(_ data: Data) -> Single<Data> {
        return Single.create { (observer) -> Disposable in
            self.base.sendMessageData(data,
                                  replyHandler: { observer(.success($0)) },
                                  errorHandler: { observer(.error($0)) })
            return Disposables.create()
        }
    }
    
    /*
    @available(watchOS 2.2, *)
     public var didComplete: Observable<WCSessionActivationState> { ... }
     */
    
    /** ------------------------- Interactive Messaging ------------------------- */
    @available(iOS 9.3, *)
    @available(watchOS 2.0, *)
    public var didChangeReachability: Observable<Bool> {
        return delegate.methodInvoked(#selector(WCSessionDelegate.sessionReachabilityDidChange(_:))).map{ a in
            return try self.castOrThrow(WCSession.self, a[0]).isReachable
        }
    }
    
    @available(iOS 9.3, *)
    @available(watchOS 2.0, *)
    public var didReceiveMessage: Observable<[String: Any]> {
        return delegate.methodInvoked(#selector(WCSessionDelegate.session(_:didReceiveMessage:))).map{ a in
            return try self.castOrThrow([String: Any].self, a[1])
        }
    }
    
    @available(iOS 9.3, *)
    @available(watchOS 2.0, *)
    public var didReceiveMessageWithReplyHandler: Observable<(message: [String: Any], replyHandler: [String: Any])> {
        return delegate.methodInvoked(#selector(WCSessionDelegate.session(_:didReceiveMessage:replyHandler:))).map{ a in
            return try self.castOrThrow(([String: Any], [String: Any]).self, (a[1], a[2]))
        }
    }
    
    @available(iOS 9.3, *)
    @available(watchOS 2.0, *)
    public var didReceiveMessageData: Observable<Data> {
        return delegate.methodInvoked(#selector(WCSessionDelegate.session(_:didReceiveMessageData:))).map{ a in
            return try self.castOrThrow(Data.self, a[1])
        }
    }
    
    @available(iOS 9.3, *)
    @available(watchOS 2.0, *)
    public var didReceiveMessageDataWithReplyHandler: Observable<(messageData: Data, replyHandler: [String: Any])> {
        return delegate.methodInvoked(#selector(WCSessionDelegate.session(_:didReceiveMessageData:replyHandler:))).map{ a in
            return try self.castOrThrow((Data, [String: Any]).self, (a[1], a[2]))
        }
    }
    
    /** -------------------------- Background Transfers ------------------------- */
    
    @available(iOS 9.3, *)
    @available(watchOS 2.0, *)
    public var didReceiveApplicationContext: Observable<[String: Any]> {
        return delegate.methodInvoked(#selector(WCSessionDelegate.session(_:didReceiveApplicationContext:))).map{ a in
            return try self.castOrThrow([String: Any].self, a[1])
        }
    }
    
    @available(iOS 9.3, *)
    @available(watchOS 2.0, *)
    public var didFinishUserInfoTransfer: Observable<WCSessionUserInfoTransfer> {
        
        let selector = #selector(
            WCSessionDelegate.session(_:didFinish:error:)
                as ((WCSessionDelegate) -> (WCSession, WCSessionUserInfoTransfer, Error?) -> Void)?
        )
        
        return delegate.methodInvoked(selector).map{ a in
            
            if let error = a[2] as? Error {
                throw error
            }
            
            return try self.castOrThrow(WCSessionUserInfoTransfer.self, a[1])
        }
    }
    
    @available(iOS 9.3, *)
    @available(watchOS 2.0, *)
    public var didReceiveUserInfo: Observable<[String: Any]> {
        return delegate.methodInvoked(#selector(WCSessionDelegate.session(_:didReceiveUserInfo:))).map{ a in
            return try self.castOrThrow([String: Any].self, a[1])
        }
    }
    
    @available(iOS 9.3, *)
    @available(watchOS 2.0, *)
    public var didFinishFileTransfer: Observable<WCSessionFileTransfer> {
        
        let selector = #selector(
            WCSessionDelegate.session(_:didFinish:error:)
                as ((WCSessionDelegate) -> (WCSession, WCSessionFileTransfer, Error?) -> Void)?
        )
        
        return delegate.methodInvoked(selector).map { a in
            
            if let error = a[2] as? Error {
                throw error
            }
            
            return try self.castOrThrow(WCSessionFileTransfer.self, a[1])
        }
    }
    
    public var didReceiveFile: Observable<WCSessionFile> {
        return delegate.methodInvoked(#selector(WCSessionDelegate.session(_:didReceive:))).map{ a in
            return try self.castOrThrow(WCSessionFile.self, a[1])
        }
    }
    
    fileprivate func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
        guard let returnValue = object as? T else {
            throw RxCocoaError.castingError(object: object, targetType: resultType)
        }
        
        return returnValue
    }

}
