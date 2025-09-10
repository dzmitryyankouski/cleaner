//
//  cleaner_iosApp.swift
//  cleaner_ios
//
//  Created by Dmitriy Yankovskiy on 06/09/2025.
//

import SwiftUI
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

@main
struct cleaner_iosApp: App {
    init() {
        AppCenter.start(withAppSecret: "6acbaba5-f2ac-484e-87fd-5fc59675eeda", services:[
          Analytics.self,
          Crashes.self
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            AppView()
        }
    }
}
