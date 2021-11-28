//
//  Bill+Extras.swift
//  BillManager
//

import Foundation
import UserNotifications

extension Bill {
    
    static let notificationCategoryID = "NotificationCategory"
    static let remindAgainInAnHourID = "RemindAgianInAnHour"
    static let markAsPaidID = "markAsPaid"
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    var hasReminder: Bool {
        return (remindDate != nil)
    }
    
    var isPaid: Bool {
        return (paidDate != nil)
    }
    
    var formattedDueDate: String {
        let dateString: String
        
        if let dueDate = self.dueDate {
            dateString = Bill.dateFormatter.string(from: dueDate)
        } else {
            dateString = ""
        }
        
        return dateString
    }
    
    //We need a function for scheduling a notification
    mutating func scheduleReminder(date: Date, completion: @escaping (Bill) -> Void) {
        unscheduleReminder()
        
        var updatedBill = self
        
        requestPermissionIfNeeded { (givenAccess) in
            if !givenAccess {
                DispatchQueue.main.async {
                    completion(updatedBill)
                }
                return
            } else {
                
                let billNotification = UNMutableNotificationContent()
                billNotification.title = "Bill Reminder"
                
                let amount = updatedBill.amount ?? 0
                let payee = updatedBill.payee ?? "hello"
                let dateFormatted = Bill.dateFormatter.string(from: date)
                billNotification.body = "\(amount) due to \(payee) on \(dateFormatted)"
                
                //this is essential in order to add actions to the notification
                billNotification.categoryIdentifier = Bill.notificationCategoryID
                
                let dateComponents = Calendar.current.dateComponents([.minute, .hour, .day, .month, .year], from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                let notificationIdentifier = updatedBill.id.uuidString
                let request = UNNotificationRequest(identifier: notificationIdentifier, content: billNotification, trigger: trigger)
                
                let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.add(request, withCompletionHandler: nil)
                
                updatedBill.notificationID = notificationIdentifier
                updatedBill.remindDate = date
                
                DispatchQueue.main.async {
                    completion(updatedBill)
                }
            }
        }
    }
    
    //We need a function for unscheduling a notification
    mutating func unscheduleReminder() {
        let notificationCenter = UNUserNotificationCenter.current()
        guard notificationID != nil else { return }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationID!])
        notificationID = nil
        remindDate = nil
    }
    //We need a funciton for requesting permission to send out notifications
    private func requestPermissionIfNeeded(completion: @escaping (Bool) -> Void) {
        //if the app hasnt yet requested authorization, request autorization
        //call completion in all possible code paths, passing in the appropriate boolian value
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if let error = error {
                        print(error.localizedDescription)
                        completion(false)
                    } else {
                        completion(granted)
                    }
                }
            case .denied, .provisional, .ephemeral:
                completion(false)
            }
        }
    }
}
