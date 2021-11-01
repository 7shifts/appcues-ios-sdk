//
//  Appcues.swift
//  Appcues
//
//  Created by Matt on 2021-10-06.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

/// An object that manages Appcues tracking for your app.
public class Appcues {

    private let container = DIContainer()

    private lazy var storage = container.resolve(Storage.self)
    private lazy var uiDebugger = container.resolve(UIDebugger.self)
    private lazy var experienceLoader = container.resolve(ExperienceLoader.self)

    private var subscribers: [AnalyticsSubscriber] = []

    /// Creates an instance of Appcues analytics.
    /// - Parameter config: `Config` object for this instance.
    public init(config: Config) {
        initializeContainer(config)
        initializeSession(config)
    }

    /// Identify the user and determine if they should see Appcues content.
    /// - Parameters:
    ///   - userID: Unique value identifying the user.
    ///   - properties: Optional properties that provide additional context about the user.
    public func identify(userID: String, properties: [String: Any]? = nil) {
        storage.userID = userID
        publish(TrackingUpdate(type: .profile, properties: properties, userID: userID))
    }

    /// Track an action taken by a user.
    /// - Parameters:
    ///   - name: Name of the event.
    ///   - properties: Optional properties that provide additional context about the event.
    public func track(name: String, properties: [String: Any]? = nil) {
        publish(TrackingUpdate(type: .event(name), properties: properties, userID: storage.userID))
    }

    /// Track an screen viewed by a user.
    /// - Parameters:
    ///   - title: Name of the screen.
    ///   - properties: Optional properties that provide additional context about the event.
    public func screen(title: String, properties: [String: Any]? = nil) {
        publish(TrackingUpdate(type: .screen(title), properties: properties, userID: storage.userID))
    }

    /// Forces specific Appcues content to appear for the current user by passing in the ID.
    /// - Parameters:
    ///   - contentID: ID of the flow.
    ///
    /// This method ignores any targeting that is set on the flow or checklist.
    public func show(contentID: String) {
        experienceLoader.load(contentID: contentID)
    }

    /// Launches the Appcues debugger over your app's UI.
    public func debug() {
        uiDebugger.show()
    }

    private func initializeContainer(_ config: Config) {
        container.register(Config.self, value: config)
        container.register(AnalyticsPublisher.self, value: self)
        container.registerLazy(Storage.self, initializer: Storage.init)
        container.registerLazy(Networking.self, initializer: Networking.init)
        container.registerLazy(StyleLoader.self, initializer: StyleLoader.init)
        container.registerLazy(ExperienceLoader.self, initializer: ExperienceLoader.init)
        container.registerLazy(ExperienceRenderer.self, initializer: ExperienceRenderer.init)
        container.registerLazy(UIDebugger.self, initializer: UIDebugger.init)
        container.registerLazy(AnalyticsTracker.self, initializer: AnalyticsTracker.init)
        container.registerLazy(LifecycleTracking.self, initializer: LifecycleTracking.init)
        container.registerLazy(UIKitScreenTracking.self, initializer: UIKitScreenTracking.init)
    }

    private func initializeSession(_ config: Config) {
        storage.accountID = config.accountID

        let previousBuild = storage.applicationBuild
        let currentBuild = Bundle.main.build

        storage.applicationBuild = currentBuild
        storage.applicationVersion = Bundle.main.version

        var launchType = LaunchType.open
        if previousBuild.isEmpty {
            launchType = .install
        } else if previousBuild != currentBuild {
            launchType = .update
        }

        if launchType == .install {
            // perform any fresh install activities here
            storage.userID = config.anonymousIDFactory()
        }

        // anything that should be eager init at launch is handled here
        _ = container.resolve(AnalyticsTracker.self)

        if config.trackLifecycle {
            container.resolve(LifecycleTracking.self).launchType = launchType
        }

        if config.trackScreens {
            _ = container.resolve(UIKitScreenTracking.self)
        }
    }
}

extension Appcues: AnalyticsPublisher {
    func register(subscriber: AnalyticsSubscriber) {
        subscribers.append(subscriber)
    }

    func remove(subscriber: AnalyticsSubscriber) {
        subscribers.removeAll { $0 === subscriber }
    }

    private func publish(_ update: TrackingUpdate) {
        for subscriber in subscribers {
            subscriber.track(update: update)
        }
    }
}
