//
//  FolderPreviewViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 06/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "NodeUpdatableProtocol.h"

@interface FolderPreviewViewController : UIViewController <NodeUpdatableProtocol>

- (instancetype)initWithAlfrescoFolder:(AlfrescoFolder *)folder permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session;

@end
