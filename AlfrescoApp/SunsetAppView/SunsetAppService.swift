//
//  SunsetAppService.swift
//  AlfrescoApp
//
//  Created by global on 23/03/22.
//  Copyright © 2022 Alfresco. All rights reserved.
//

import UIKit

class SunsetAppService: NSObject {

    @objc func showBannerIfRequired() {
        if let appDelegate = UIApplication.shared.delegate, let controller = appDelegate.window!!.rootViewController {
            let view = SunsetAppView.loadFromXib()
            view.frame = CGRect(x: 0, y: 0, width: controller.view.frame.size.width, height: controller.view.frame.size.height)
            controller.view.addSubview(view)
        }
    }
    
    @objc func redirectUserToOpenApp() {
        let appScheme = "ioscontentapp://"
        let appUrl = URL(string: appScheme)!
        if UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
        } else if let url = URL(string: "itms-apps://itunes.apple.com/app/" + "1514434480") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @objc func isAppReachedToEndOfLife() -> Bool {
        if let endOfLifeDate = getAppEOLDate() {
            let currentDate = Date()
            if currentDate >= endOfLifeDate  {
                return true
            }
        }
        return false
    }
    
    func getAppEOLDate() -> Date? {
        let isoDate = "2022-11-30 00:00:00+0000"
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ssZ"
        let date = dateFormatter.date(from:isoDate)
        return date
    }
}
