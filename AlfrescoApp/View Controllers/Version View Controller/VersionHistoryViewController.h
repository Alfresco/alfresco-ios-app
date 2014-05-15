//
//  VersionHistoryViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"
#import "NodeUpdatableProtocol.h"

@class AlfrescoDocument;

@interface VersionHistoryViewController : ParentListViewController <NodeUpdatableProtocol>

- (id)initWithDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session;

@end
