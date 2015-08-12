/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

#import "AlfrescoURLHandler.h"
#import "UniversalDevice.h"
#import "FileFolderCollectionViewController.h"
#import "DetailSplitViewController.h"
#import "SwitchViewController.h"
#import "NavigationViewController.h"
#import "MainMenuViewController.h"

typedef NS_ENUM(NSInteger, AlfrescoURLType)
{
    AlfrescoURLTypeNone,
    AlfrescoURLTypeDocument,
    AlfrescoURLTypeFolder,
    AlfrescoURLTypeSite,
    AlfrescoURLTypeUser
};

@interface AlfrescoURLHandler()

@property (nonatomic, strong) UIViewController *viewControllerToPresent;

@end

@implementation AlfrescoURLHandler

static NSString * const kHandlerPrefix = @"alfresco://";
static NSString * const kDocumentPath = @"document";
static NSString * const kFolderPath = @"folder";
static NSString * const kSitePath = @"site";
static NSString * const kUserPath = @"user";


#pragma mark - URLHandlerProtocol

- (BOOL)canHandleURL:(NSURL *)url
{
    return [url.absoluteString hasPrefix:kHandlerPrefix];
}

- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation session:(id<AlfrescoSession>)session
{
    BOOL handled = NO;

    AlfrescoURLType actionType = [self parseURLForAction: url.absoluteString];
    self.viewControllerToPresent = nil;
    switch (actionType)
    {
        case AlfrescoURLTypeNone:
        {
            handled = YES;
        }
        break;
            
        case AlfrescoURLTypeDocument:
        {
            NSString *initialCommandPath = [NSString stringWithFormat:@"%@%@/", kHandlerPrefix, kDocumentPath];
            NSString *objectId = [url.absoluteString stringByReplacingOccurrencesOfString:initialCommandPath withString:@""];
            NSString *documentNodeRef = [NSString stringWithFormat:@"workspace://SpacesStore/%@", objectId];
            FileFolderCollectionViewController *controller = [[FileFolderCollectionViewController alloc] initWithDocumentNodeRef:documentNodeRef session:session];
            self.viewControllerToPresent = controller;
            
            handled = YES;
        }
        break;
            
        case AlfrescoURLTypeFolder:
        {
            NSString *initialCommandPath = [NSString stringWithFormat:@"%@%@/", kHandlerPrefix, kFolderPath];
            NSString *objectId = [url.absoluteString stringByReplacingOccurrencesOfString:initialCommandPath withString:@""];
            NSString *folderNodeRef = [NSString stringWithFormat:@"workspace://SpacesStore/%@", objectId];
            FileFolderCollectionViewController *controller = [[FileFolderCollectionViewController alloc] initWithNodeRef:folderNodeRef folderPermissions:nil folderDisplayName:nil session:session];
            self.viewControllerToPresent = controller;
            handled = YES;
        }
        break;
            
        case AlfrescoURLTypeSite:
        {
            NSString *initialCommandPath = [NSString stringWithFormat:@"%@%@/", kHandlerPrefix, kSitePath];
            NSString *siteShortName = [url.absoluteString stringByReplacingOccurrencesOfString:initialCommandPath withString:@""];
            FileFolderCollectionViewController *controller = [[FileFolderCollectionViewController alloc] initWithSiteShortname:siteShortName sitePermissions:nil siteDisplayName:nil session:session];
            self.viewControllerToPresent = controller;
            handled = YES;
        }
        break;
            
        case AlfrescoURLTypeUser:
        {
            NSString *initialCommandPath = [NSString stringWithFormat:@"%@%@/", kHandlerPrefix, kUserPath];
            NSString *username = [url.absoluteString stringByReplacingOccurrencesOfString:initialCommandPath withString:@""];
        }
        break;
    }
    
    if(self.viewControllerToPresent)
    {
        [self presentViewControllerFromURL:self.viewControllerToPresent];
    }
    return handled;
}

#pragma mark - Private methods
- (AlfrescoURLType) parseURLForAction: (NSString *)URLString
{
    //Removing the scheme from the url string
    NSString *urlWithoutScheme = [URLString stringByReplacingOccurrencesOfString:kHandlerPrefix withString:@""];
    
    if([urlWithoutScheme hasPrefix:kDocumentPath])
    {
        return AlfrescoURLTypeDocument;
    }
    else if ([urlWithoutScheme hasPrefix:kFolderPath])
    {
        return AlfrescoURLTypeFolder;
    }
    else if ([urlWithoutScheme hasPrefix:kSitePath])
    {
        return AlfrescoURLTypeSite;
    }
    else if ([urlWithoutScheme hasPrefix:kUserPath])
    {
        return AlfrescoURLTypeUser;
    }
    
    return AlfrescoURLTypeNone;
}

- (void)presentViewControllerFromURL:(UIViewController *)controller
{
    if([[UniversalDevice rootDetailViewController] isKindOfClass:[DetailSplitViewController class]])
    {
        //this is the iPad version
        DetailSplitViewController *splitViewController = (DetailSplitViewController *)[UniversalDevice rootDetailViewController];
        if([splitViewController.masterViewController isKindOfClass:[SwitchViewController class]])
        {
            SwitchViewController *switchController = (SwitchViewController *)splitViewController.masterViewController;
            NavigationViewController *navigationController = [[NavigationViewController alloc] initWithRootViewController:controller];
            [switchController displayURLViewController:navigationController];
        }
    }
    else if ([[UniversalDevice rootDetailViewController] isKindOfClass:[SwitchViewController class]])
    {
        //this is the iPhone version
        SwitchViewController *switchController = (SwitchViewController *)[UniversalDevice rootDetailViewController];
        NavigationViewController *navigationController = [[NavigationViewController alloc] initWithRootViewController:controller];
        [switchController displayURLViewController:navigationController];
    }
    
    if([[UniversalDevice rootMasterViewController] isKindOfClass:[MainMenuViewController class]])
    {
        MainMenuViewController *mainMenu = (MainMenuViewController *)[UniversalDevice rootMasterViewController];
        [mainMenu cleanSelection];
    }
    else
    {
        NSLog(@"==== present view controller from url root master view controller is not MainMenuViewController");
    }
}

@end
