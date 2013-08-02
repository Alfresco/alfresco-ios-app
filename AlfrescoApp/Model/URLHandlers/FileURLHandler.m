//
//  FileOpenURLProtocol.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "FileURLHandler.h"
#import "PreviewViewController.h"
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
    // Move the incoming file into the GDSecureContainer
    [[DownloadManager sharedManager] moveFileIntoSecureContainer:url.path completionBlock:^(NSString *filePath) {
        if (filePath != nil)
        {
            // Get the right navigation controller for the Downloads view
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            NavigationViewController *navigationController = [appDelegate navigationControllerOfType:NavigationControllerTypeDownloads];
            
            // Activate the tab hosting the Downloads view
            [appDelegate activateTabBarForNavigationControllerOfType:NavigationControllerTypeDownloads];
            
            // Create and push the Preview controller
            PreviewViewController *previewController = [[PreviewViewController alloc] initWithDocument:nil documentPermissions:nil contentFilePath:filePath session:nil];
            [UniversalDevice pushToDisplayViewController:previewController usingNavigationController:navigationController animated:YES];
        }

        // MDM policies dictate we should now remove the unsecured inbound document
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    }];
    
    return YES;
}

@end
