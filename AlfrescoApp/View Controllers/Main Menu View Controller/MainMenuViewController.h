//
//  MainMenuViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainMenuItem.h"

@protocol MainMenuViewControllerDelegate <NSObject>

- (void)didSelectMenuItem:(MainMenuItem *)mainMenuItem;

@end

@interface MainMenuViewController : UIViewController

@property (nonatomic, weak) id<MainMenuViewControllerDelegate> delegate;

- (instancetype)initWithSectionArrays:(NSArray *)sections, ... NS_REQUIRES_NIL_TERMINATION;

@end
