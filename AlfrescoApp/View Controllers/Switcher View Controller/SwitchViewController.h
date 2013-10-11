//
//  MainMenuViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainMenuViewController.h"

@interface SwitchViewController : UIViewController <MainMenuViewControllerDelegate>

- (instancetype)initWithInitialViewController:(UIViewController *)viewController;

@end
