//
//  MetaDataViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"
#import "ItemInDetailViewProtocol.h"

@class AlfrescoNode;

@interface MetaDataViewController : ParentListViewController <ItemInDetailViewProtocol>

@property (nonatomic, strong, readonly) AlfrescoNode *node;

- (id)initWithAlfrescoNode:(AlfrescoNode *)node showingVersionHistoryOption:(BOOL)versionHistoryOption session:(id<AlfrescoSession>)session;

@end
