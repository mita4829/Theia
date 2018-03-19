//
//  Reminders.swift
//  Theia
//
//  Created by Michael Tang on 2/20/18.
//  Copyright © 2018 Michael Tang. All rights reserved.
//

import Foundation

class Reminders {
    var reminders:String
    var timeDifference:Double
    var notifiy:Bool
    init(title: String, timeDifference:Double, notify:Bool){
        self.reminders = title
        self.timeDifference = timeDifference
        self.notifiy = notify
    }
}
