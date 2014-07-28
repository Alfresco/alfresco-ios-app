//
//  AlfrescoFormViewController.h
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 14/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AlfrescoForm.h"

@class AlfrescoFormViewController;

#pragma mark - AlfrescoFormViewControllerDelegate protocol

@protocol AlfrescoFormViewControllerDelegate <NSObject>

@optional

// Informs the delegate the user pressed the "Done" button
- (void)formViewController:(AlfrescoFormViewController *)viewController didEndEditingOfForm:(AlfrescoForm *)form;

// Determines whether the form fields can be persisted and thus whether the "Done" button is enabled.
// This method provides a mechanism to perform further validation, over and above the constraints
- (BOOL)formViewController:(AlfrescoFormViewController *)viewController canPersistForm:(AlfrescoForm *)form;

@end

#pragma mark - AlfrescoFormViewController

@interface AlfrescoFormViewController : UITableViewController

@property (nonatomic, strong, readonly) AlfrescoForm *form;
@property (nonatomic, weak) id<AlfrescoFormViewControllerDelegate> delegate;

- (instancetype)initWithForm:(AlfrescoForm *)form;

@end
