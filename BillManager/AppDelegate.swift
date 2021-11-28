//
//  AppDelegate.swift
//  BillManager
//

import UIKit
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //Action to remind the user again in an hour
        //Action to allow the user to mark the bill as paied (Requires the .authenticationRequired)
        let remindInAnHourAction = UNNotificationAction(identifier: Bill.remindAgainInAnHourID, title: "Remind me in an hour", options: [])
        let markAsPaidAction = UNNotificationAction(identifier: Bill.markAsPaidID, title: "Mark as paid", options: [.authenticationRequired])
        
        //Category with the two options above and register it with the user notification center
        let billReminderCategory = UNNotificationCategory(
            identifier: Bill.notificationCategoryID,
            actions: [remindInAnHourAction, markAsPaidAction],
            intentIdentifiers: [],
            options: .customDismissAction)
        
        let notificatonCenter = UNUserNotificationCenter.current()
        notificatonCenter.setNotificationCategories([billReminderCategory])
        
        //Set the user notification center delegate
        notificatonCenter.delegate = self
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let notificationID = response.notification.request.identifier
        
        var bill = Database.shared.getBill(forNotificationID: notificationID)
        
        if response.actionIdentifier == Bill.remindAgainInAnHourID {
            let alertDate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
            bill.scheduleReminder(date: alertDate) { (bill) in
                Database.shared.updateAndSave(bill)
            }
        } else if response.actionIdentifier == Bill.markAsPaidID {
            bill.paidDate = Date()
            Database.shared.updateAndSave(bill)
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
}

