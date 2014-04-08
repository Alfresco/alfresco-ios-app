//
//  FileOpenURLProtocol.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "FileURLHandler.h"
#import "UniversalDevice.h"
#import "DownloadManager.h"
#import "NavigationViewController.h"
#import "AppDelegate.h"

@implementation FileURLHandler

#pragma mark - URLHandlerProtocol

- (BOOL)canHandleURL:(NSURL *)url
{
    return [url.scheme isEqualToString:@"file"];
}

- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return YES;
}

@end
