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
#import "NodeUpdatableProtocol.h"

@interface MetaDataViewController : ParentListViewController <ItemInDetailViewProtocol, NodeUpdatableProtocol>

@property (nonatomic, strong) AlfrescoNode *node;

- (id)initWithAlfrescoNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session;

@end
