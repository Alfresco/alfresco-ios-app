//
//  SyncNavigationViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 13/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NavigationViewController.h"
#import "SyncManager.h"

@interface SyncNavigationViewController : NavigationViewController <SyncManagerProgressDelegate>

- (BOOL)isProgressViewVisible;
- (CGFloat)progressViewHeight;

@end
