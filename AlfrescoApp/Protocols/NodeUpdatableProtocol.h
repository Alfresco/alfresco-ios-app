//
//  NodeUpdatableProtocol.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 14/05/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NodeUpdatableProtocol <NSObject>

- (void)updateToAlfrescoNode:(AlfrescoNode *)node permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session;

@end
