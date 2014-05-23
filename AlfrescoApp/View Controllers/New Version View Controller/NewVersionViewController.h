//
//  NewVersionViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 23/05/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ParentListViewController.h"

@interface NewVersionViewController : ParentListViewController

- (instancetype)initWithDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session;

@end
