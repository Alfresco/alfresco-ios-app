//
//  FileHandlerManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

@interface FileHandlerManager : NSObject

+ (FileHandlerManager *)sharedManager;

- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation session:(id<AlfrescoSession>)session;

@end
