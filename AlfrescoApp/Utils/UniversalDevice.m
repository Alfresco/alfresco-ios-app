/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
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
 
#import "UniversalDevice.h"
#import "RootRevealViewController.h"
#import "DetailSplitViewController.h"
#import "NavigationViewController.h"
#import "ItemInDetailViewProtocol.h"
#import "PlaceholderViewController.h"
#import "ContainerViewController.h"
#import "SwitchViewController.h"
#import "FolderPreviewViewController.h"
#import "DocumentPreviewViewController.h"
#import "DownloadsDocumentPreviewViewController.h"

static FolderPreviewViewController *folderPreviewController;
static DocumentPreviewViewController *documentPreviewController;
static DownloadsDocumentPreviewViewController *downloadDocumentPreviewController;

@implementation UniversalDevice

+ (void)pushToDisplayFolderPreviewControllerForAlfrescoDocument:(AlfrescoFolder *)folder
                                                    permissions:(AlfrescoPermissions *)permissions
                                                        session:(id<AlfrescoSession>)session
                                           navigationController:(UINavigationController *)navigationController
                                                       animated:(BOOL)animated
{
    if (folderPreviewController != nil && [self controllerDisplayedInDetailNavigationController] == folderPreviewController)
    {
        if ([folderPreviewController respondsToSelector:@selector(updateToAlfrescoNode:permissions:session:)])
        {
            [folderPreviewController updateToAlfrescoNode:folder permissions:permissions session:session];
        }
    }
    else
    {
        if (folderPreviewController == nil)
        {
            folderPreviewController = [[FolderPreviewViewController alloc] initWithAlfrescoFolder:folder permissions:permissions session:session];
        }
        else
        {
            if ([folderPreviewController respondsToSelector:@selector(updateToAlfrescoNode:permissions:session:)])
            {
                [folderPreviewController updateToAlfrescoNode:folder permissions:permissions session:session];
            }
        }
        
        [self pushToDisplayViewController:folderPreviewController usingNavigationController:navigationController animated:animated];
    }
}

+ (void)pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)document
                                                      permissions:(AlfrescoPermissions *)permissions
                                                      contentFile:(NSString *)contentFilePath
                                                 documentLocation:(InAppDocumentLocation)documentLocation
                                                          session:(id<AlfrescoSession>)session
                                             navigationController:(UINavigationController *)navigationController
                                                         animated:(BOOL)animated;
{
    if (documentPreviewController != nil && [self controllerDisplayedInDetailNavigationController] == documentPreviewController)
    {
        if ([documentPreviewController respondsToSelector:@selector(updateToAlfrescoDocument:permissions:contentFilePath:documentLocation:session:)])
        {
            [documentPreviewController updateToAlfrescoDocument:document permissions:permissions contentFilePath:contentFilePath documentLocation:documentLocation session:session];
        }
    }
    else
    {
        if (documentPreviewController == nil)
        {
            documentPreviewController = [[DocumentPreviewViewController alloc] initWithAlfrescoDocument:document permissions:permissions contentFilePath:contentFilePath documentLocation:documentLocation session:session];
        }
        else
        {
            if ([documentPreviewController respondsToSelector:@selector(updateToAlfrescoDocument:permissions:contentFilePath:documentLocation:session:)])
            {
                [documentPreviewController updateToAlfrescoDocument:document permissions:permissions contentFilePath:contentFilePath documentLocation:documentLocation session:session];
            }
        }
        
        [self pushToDisplayViewController:documentPreviewController usingNavigationController:navigationController animated:animated];
    }
}

+ (void)pushToDisplayDownloadDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)document
                                                              permissions:(AlfrescoPermissions *)permissions
                                                              contentFile:(NSString *)contentFilePath
                                                         documentLocation:(InAppDocumentLocation)documentLocation
                                                                  session:(id<AlfrescoSession>)session
                                                     navigationController:(UINavigationController *)navigationController
                                                                 animated:(BOOL)animated
{
    if (downloadDocumentPreviewController != nil && [self controllerDisplayedInDetailNavigationController] == downloadDocumentPreviewController)
    {
        if ([downloadDocumentPreviewController respondsToSelector:@selector(updateToAlfrescoDocument:permissions:contentFilePath:documentLocation:session:)])
        {
            [downloadDocumentPreviewController updateToAlfrescoDocument:document permissions:permissions contentFilePath:contentFilePath documentLocation:documentLocation session:session];
        }
    }
    else
    {
        if (downloadDocumentPreviewController == nil)
        {
            downloadDocumentPreviewController = [[DownloadsDocumentPreviewViewController alloc] initWithAlfrescoDocument:document permissions:permissions contentFilePath:contentFilePath documentLocation:documentLocation session:session];
        }
        else
        {
            if ([downloadDocumentPreviewController respondsToSelector:@selector(updateToAlfrescoDocument:permissions:contentFilePath:documentLocation:session:)])
            {
                [downloadDocumentPreviewController updateToAlfrescoDocument:document permissions:permissions contentFilePath:contentFilePath documentLocation:documentLocation session:session];
            }
        }
        
        [self pushToDisplayViewController:downloadDocumentPreviewController usingNavigationController:navigationController animated:animated];
    }
}

+ (void)pushToDisplayViewController:(UIViewController *)viewController usingNavigationController:(UINavigationController *)navigationController animated:(BOOL)animated;
{
    if (IS_IPAD)
    {
        UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        
        if ([rootViewController isKindOfClass:[ContainerViewController class]])
        {
            ContainerViewController *containerViewController = (ContainerViewController *)rootViewController;
            RootRevealViewController *splitViewController = (RootRevealViewController *)containerViewController.rootViewController;
            UIViewController *rootDetailController = splitViewController.detailViewController;
            if ([rootDetailController isKindOfClass:[DetailSplitViewController class]])
            {
                DetailSplitViewController *rootDetailSplitViewController = (DetailSplitViewController *)rootDetailController;
                UIViewController *controllerInRootDetailSplitViewController = rootDetailSplitViewController.detailViewController;
                
                if ([controllerInRootDetailSplitViewController isKindOfClass:[NavigationViewController class]])
                {
                    NavigationViewController *detailNavigationViewController = (NavigationViewController *)controllerInRootDetailSplitViewController;
                    
                    if ([viewController isKindOfClass:[NavigationViewController class]])
                    {
                        viewController = [(NavigationViewController *)viewController rootViewController];
                    }
                    
                    [detailNavigationViewController resetRootViewControllerWithViewController:viewController];
                }
            }
        }
        else
        {
            [navigationController pushViewController:viewController animated:animated];
        }
    }
    else
    {
        if (viewController.navigationController)
        {
            NSArray *navigationStackControllers = viewController.navigationController.viewControllers;
            NSMutableArray *mutableNavigationStackControllers = viewController.navigationController.viewControllers.mutableCopy;
            [navigationStackControllers enumerateObjectsUsingBlock:^(UIViewController *currentController, NSUInteger idx, BOOL *stop) {
                if (currentController == viewController)
                {
                    [mutableNavigationStackControllers removeObject:currentController];
                }
            }];
            viewController.navigationController.viewControllers = mutableNavigationStackControllers;
        }
        
        [navigationController pushViewController:viewController animated:animated];
    }
}

+ (void)displayModalViewController:(UIViewController *)viewController onController:(UIViewController *)controller withCompletionBlock:(void (^)(void))completionBlock
{
    if (IS_IPAD)
    {
        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [controller presentViewController:viewController animated:YES completion:^{
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
}

+ (void)clearDetailViewController
{
    folderPreviewController = nil;
    documentPreviewController = nil;
    downloadDocumentPreviewController = nil;
    if (IS_IPAD)
    {
        PlaceholderViewController *viewController = [[PlaceholderViewController alloc] init];
        [UniversalDevice pushToDisplayViewController:viewController usingNavigationController:nil animated:NO];
    }
    else
    {
        RootRevealViewController *rootRevealViewController = (RootRevealViewController *)[self revealViewController];
        SwitchViewController *switchViewController = (SwitchViewController *)[rootRevealViewController detailViewController];
        UINavigationController *navController = (UINavigationController *)[switchViewController displayedViewController];
        [navController popViewControllerAnimated:NO];
    }
}

+ (UIViewController *)controllerDisplayedInDetailNavigationController
{
    UIViewController *returnController = nil;
    
    if (IS_IPAD)
    {
        UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        
        if ([rootViewController isKindOfClass:[ContainerViewController class]])
        {
            ContainerViewController *containerViewController = (ContainerViewController *)rootViewController;
            RootRevealViewController *splitViewController = (RootRevealViewController *)containerViewController.rootViewController;
            UIViewController *rootDetailController = splitViewController.detailViewController;
            if ([rootDetailController isKindOfClass:[DetailSplitViewController class]])
            {
                DetailSplitViewController *rootDetailSplitViewController = (DetailSplitViewController *)rootDetailController;
                UIViewController *controllerInRootDetailSplitViewController = rootDetailSplitViewController.detailViewController;
                
                if ([controllerInRootDetailSplitViewController isKindOfClass:[NavigationViewController class]])
                {
                    NavigationViewController *detailNavigationViewController = (NavigationViewController *)controllerInRootDetailSplitViewController;
                    returnController = [detailNavigationViewController.viewControllers lastObject];
                }
            }
        }
    }
    
    return returnController;
}

+ (NSString *)detailViewItemIdentifier
{
    id detailViewController = [self controllerDisplayedInDetailNavigationController];
    
    if ([detailViewController conformsToProtocol:@protocol(ItemInDetailViewProtocol)])
    {
        return [detailViewController detailViewItemIdentifier];
    }
    
    return nil;
}

+ (UIViewController *)containerViewController
{
    ContainerViewController *rootViewController = (ContainerViewController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
    return rootViewController;
}

+ (UIViewController *)revealViewController
{
    ContainerViewController *rootViewController = (ContainerViewController *)[self containerViewController];
    return rootViewController.rootViewController;
}

+ (UIViewController *)rootMasterViewController
{
    RootRevealViewController *rootViewController = (RootRevealViewController *)[self revealViewController];
    return rootViewController.masterViewController;
}

+ (UIViewController *)rootDetailViewController
{
    RootRevealViewController *rootViewController = (RootRevealViewController *)[self revealViewController];
    return rootViewController.detailViewController;
}

+ (UIViewController *)topPresentedViewController
{
    UIViewController *viewController = [self containerViewController];
    
    while (viewController.presentedViewController)
    {
        viewController = viewController.presentedViewController;
    }
    
    return viewController;
}

@end
