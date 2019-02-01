
import UIKit

extension UIColor {
    
    static var mainBlue = UIColor.rgb(red: 17, green: 154, blue: 237)
    
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
}

extension UIView {
    func anchor(top: NSLayoutYAxisAnchor? = nil, left: NSLayoutXAxisAnchor? = nil, bottom: NSLayoutYAxisAnchor? = nil, right: NSLayoutXAxisAnchor? = nil, paddingTop: CGFloat = 0, paddingLeft: CGFloat = 0, paddingBottom: CGFloat = 0, paddingRight: CGFloat = 0, width: CGFloat = 0, height: CGFloat = 0) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        if let left = left {
            leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
        }
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
        }
        if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        if height != 0 {
            heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }
}

extension Date {
    
    func timeAgoDisplay() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        
        if secondsAgo == 0 {
            return "Just now"
        }
        if secondsAgo < minute {
            if secondsAgo == 1 {
                return "\(secondsAgo) second ago"
            } else {
                return "\(secondsAgo) seconds ago"
            }
        } else if secondsAgo < hour {
            if secondsAgo / minute == 1 {
                return "\(secondsAgo / minute) minute ago"
            } else {
                return "\(secondsAgo / minute) minutes ago"
            }
        } else if secondsAgo < day {
            if secondsAgo / hour == 1 {
                return "\(secondsAgo / hour) hour ago"
            } else {
                return "\(secondsAgo / hour) hours ago"
            }
        } else if secondsAgo < week {
            if secondsAgo / day == 1 {
                return "\(secondsAgo / day) day ago"
            } else {
                return "\(secondsAgo / day) days ago"
            }
        }
        
        if secondsAgo / week == 1 {
            return "\(secondsAgo / week) week ago"
        } else {
            return "\(secondsAgo / week) weeks ago"
        }
    }
    
    func timeAgoDisplayShort() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        
        if secondsAgo == 0 {
            return "Just now"
        }
        if secondsAgo < minute {
            return "\(secondsAgo)s"
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute)m"
        } else if secondsAgo < day {
            return "\(secondsAgo / hour)h"
        } else if secondsAgo < week {
            return "\(secondsAgo / day)d"
        }
        
        return "\(secondsAgo / week)wk"
    }
}

extension NSNotification.Name {
    static var updateHomeFeed = NSNotification.Name(rawValue: "updateFeed")
    static var updateUserProfileFeed = NSNotification.Name(rawValue: "updateUserProfileFeed")
}

extension UIViewController{
    
    func simpleAlert(title: String, message: String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension UIImage {
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}
