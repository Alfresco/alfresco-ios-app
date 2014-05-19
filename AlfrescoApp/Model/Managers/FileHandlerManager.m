//
//  FileHandlerManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

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
