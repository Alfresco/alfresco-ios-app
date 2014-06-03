/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
 
#import "FileHandlerManager.h"
#import "URLHandlerProtocol.h"
#import "FileURLHandler.h"

@interface FileHandlerManager ()

@property (nonatomic, strong) NSArray *fileHandlers;

@end

@implementation FileHandlerManager

+ (FileHandlerManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static FileHandlerManager *sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] initWithHandlers:@[[FileURLHandler new]]];
    });
    return sharedManager;
}

- (instancetype)initWithHandlers:(NSArray *)handlers
{
    self = [self init];
    if (self)
    {
        self.fileHandlers = handlers;
    }
    return self;
}

- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation session:(id<AlfrescoSession>)session
{
    id<URLHandlerProtocol> fileHandler = nil;
    
    // find the handler
    for (id<URLHandlerProtocol> handler in self.fileHandlers)
    {
        if ([handler canHandleURL:url])
        {
            fileHandler = handler;
            break;
        }
    }
    
    BOOL handled = NO;
    
    if (fileHandler)
    {
        handled = [fileHandler handleURL:url sourceApplication:sourceApplication annotation:annotation session:session];
    }
    
    return handled;
}

@end
