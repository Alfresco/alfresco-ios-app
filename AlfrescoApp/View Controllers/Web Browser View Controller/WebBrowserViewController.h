//
//  HelpViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebBrowserViewController : UIViewController

- (instancetype)initWithURLString:(NSString *)urlString initialTitle:(NSString *)initialTitle errorLoadingURLString:(NSString *)errorURLString;
- (instancetype)initWithURL:(NSURL *)url initialTitle:(NSString *)initialTitle errorLoadingURL:(NSURL *)errorURL;

@end
