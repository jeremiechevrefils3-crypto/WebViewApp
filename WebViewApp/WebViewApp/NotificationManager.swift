import Foundation
import UserNotifications
import WebKit

class NotificationManager: NSObject, WKScriptMessageHandler {
    
    static let shared = NotificationManager()
    
    override init() {
        super.init()
    }
    
    // Handle messages from JavaScript
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "pushNotification" {
            guard let body = message.body as? [String: Any],
                  let title = body["title"] as? String,
                  let messageText = body["message"] as? String else {
                return
            }
            
            let delay = body["delay"] as? Double ?? 0.0
            
            scheduleNotification(title: title, message: messageText, delay: delay)
        }
    }
    
    // Schedule notification
    func scheduleNotification(title: String, message: String, delay: Double) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.badge = 1
        
        let identifier = UUID().uuidString
        
        if delay > 0 {
            // Schedule notification with delay
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                } else {
                    print("Notification scheduled for \(delay) seconds")
                }
            }
        } else {
            // Send notification immediately
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error sending immediate notification: \(error)")
                } else {
                    print("Immediate notification sent")
                }
            }
        }
    }
}

