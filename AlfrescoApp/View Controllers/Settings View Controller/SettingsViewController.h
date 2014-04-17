//
//  SettingsViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 25/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ParentListViewController.h"
#import "DismissCompletionProtocol.h"

@interface SettingsViewController : ParentListViewController <DismissCompletionProtocol>

@property (nonatomic, copy) DismissCompletionBlock dismissCompletionBlock;

@end
