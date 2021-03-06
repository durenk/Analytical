//
//  Mixpanel.swift
//  Analytical
//
//  Created by Dal Rupnik on 18/07/16.
//  Copyright © 2016 Unified Sense. All rights reserved.
//

import Mixpanel

public class MixpanelProvider : Provider<MixpanelInstance>, Analytical {
    private var token : String
    
    public static let ApiToken = "ApiToken"
    
    public init(token: String) {
        self.token = token
        
        super.init()
    }
    
    //
    // MARK: Analytical
    //
    
    public func setup(with properties: Properties?) {
        
        if let token = properties?[MixpanelProvider.ApiToken] as? String {
            self.token = token
        }
        
        instance = Mixpanel.initialize(token: token)
    }
    
    public func flush() {
        instance.flush()
    }
    
    public func reset() {
        instance.reset()
    }
    
    public override func event(name: EventName, properties: Properties? = nil) {
        instance.track(event: name, properties: properties as? [String : MixpanelType])
    }
    
    public func screen(name: EventName, properties: Properties? = nil) {
        //
        // Mixpanel does not specifically track screens, so just send out an event.
        //
        instance.track(event: name, properties: properties as? [String : MixpanelType])
    }
    
    public override func time(name: EventName, properties: Properties? = nil) {
        super.time(name: name, properties: properties)
        
        instance.time(event: name)
    }
    
    public func identify(userId: String, properties: Properties? = nil) {
        
        instance.identify(distinctId: userId)
        
        if let properties = properties {
            set(properties: properties)
        }
    }
    
    public func alias(userId: String, forId: String) {
        instance.createAlias(userId, distinctId: forId)
        instance.identify(distinctId: forId)
    }
        
    public func set(properties: Properties) {
        guard let properties = prepare(properties: properties) else {
            return
        }
        
        instance.people.set(properties: properties)
    }
    
    public override func global(properties: Properties, overwrite: Bool) {
        //
        // Mixpanel has it's own global property system, so just use it.
        //
        
        guard let properties = properties as? [String : MixpanelType] else {
            return
        }
        
        if overwrite {
            instance.registerSuperProperties(properties)
        }
        else {
            instance.registerSuperPropertiesOnce(properties)
        }
    }
    
    public func increment(property: String, by number: NSDecimalNumber) {
        instance.people.increment(property: property, by: number.doubleValue)
    }
    
    public override func purchase(amount: NSDecimalNumber, properties: Properties?) {
        instance.people.trackCharge(amount: amount.doubleValue, properties: properties as? [String : MixpanelType])
    }
    
    public override func addDevice(token: Data) {
        instance.people.addPushDeviceToken(token)
    }
    
    public override func push(payload: [AnyHashable : Any], event: EventName?) {
        if let event = event {
            instance.trackPushNotification(payload, event: event)
        }
        else {
            instance.trackPushNotification(payload)
        }
    }
    
    //
    // MARK: Private Methods
    //
    
    private func prepare(properties: Properties) -> [String : MixpanelType]? {
        guard let properties = properties as? [String : MixpanelType] else {
            return nil
        }
        
        let mapping : [String : String] = [
            Property.User.email.rawValue : "$email",
            Property.User.name.rawValue : "$name",
            Property.User.lastLogin.rawValue : "$last_login"
        ]
        
        var finalProperties : [String : MixpanelType] = [:]
        
        for (property, value) in properties {
            if let map = mapping[property] {
                finalProperties[map] = value
            }
            else {
                finalProperties[property] = value
            }
        }
        
        return finalProperties
    }
}
