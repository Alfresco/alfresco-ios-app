//
//  BaseInboundFileHandler.h
//  AlfrescoApp
//
//  Created by Mike Hatfield on 03/05/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "FileLocationSelectionViewController.h"
#import "URLHandlerProtocol.h"
#import "SaveBackMetadata.h"

@interface BaseInboundURLHandler : NSObject <FileLocationSelectionViewControllerDelegate, URLHandlerProtocol>

- (BOOL)handleInboundFileURL:(NSURL *)url savebackMetadata:(SaveBackMetadata *)metadata session:(id<AlfrescoSession>)session;

@end
