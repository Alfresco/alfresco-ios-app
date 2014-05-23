//
//  FileOpenURLProtocol.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "FileURLHandler.h"
#import "NavigationViewController.h"
#import "FileLocationSelectionViewController.h"
#import "UniversalDevice.h"

static NSString * const kHandlerPrefix = @"file://";

@implementation FileURLHandler

#pragma mark - URLHandlerProtocol

- (BOOL)canHandleURL:(NSURL *)url
{
    return [url.absoluteString hasPrefix:kHandlerPrefix];
}

- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation session:(id<AlfrescoSession>)session
{
    BOOL handled = NO;
    
    // Are we using Quickoffice SaveBack?
    if (annotation[kQuickofficeApplicationSecretUUIDKey])
    {
        NSDictionary *partnerApplicationInfo = annotation[kQuickofficeApplicationInfoKey];
        NSDictionary *metadataDictionary = partnerApplicationInfo[kAlfrescoInfoMetadataKey];
        SaveBackMetadata *metadata = [[SaveBackMetadata alloc] initWithDictionary:metadataDictionary];
        
        handled = [self handleInboundFileURL:url savebackMetadata:metadata session:session];
    }
    else
    {
        // User selection
        FileLocationSelectionViewController *locationSelectionViewController = [[FileLocationSelectionViewController alloc] initWithFilePath:url.path session:session delegate:self];
        NavigationViewController *locationNavigationController = [[NavigationViewController alloc] initWithRootViewController:locationSelectionViewController];
        [UniversalDevice displayModalViewController:locationNavigationController onController:[UniversalDevice containerViewController] withCompletionBlock:nil];
        
        handled = YES;
    }
    
    return handled;
}

@end
