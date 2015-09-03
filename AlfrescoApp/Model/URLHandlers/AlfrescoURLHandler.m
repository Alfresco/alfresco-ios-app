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
#import "AccountManager.h"
#import "KeychainUtils.h"
#import "UserAccountWrapper.h"
#import "PersonProfileViewController.h"
#import "SearchResultsTableViewController.h"

static NSString * const kAccountsListIdentifier = @"AccountListNew";
static NSString * const kHandlerPrefix = @"alfresco://";
static NSString * const kDocumentPath = @"document";
static NSString * const kFolderPath = @"folder";
static NSString * const kSitePath = @"site";
static NSString * const kUserPath = @"user";

typedef NS_ENUM(NSInteger, AlfrescoURLType)
{
    AlfrescoURLTypeNone,
    AlfrescoURLTypeDocument,
    AlfrescoURLTypeFolder,
    AlfrescoURLTypeSite,
    AlfrescoURLTypeUser
};

@interface AlfrescoURLHandler() < AKUserAccountListViewControllerDelegate >

@property (nonatomic, strong) UIViewController *viewControllerToPresent;
@property (nonatomic, strong) NSURL *urlReceived;
@property (nonatomic, strong) AlfrescoPersonService *personService;

@end

@implementation AlfrescoURLHandler

#pragma mark - URLHandlerProtocol

- (BOOL)canHandleURL:(NSURL *)url
{
    return [url.absoluteString hasPrefix:kHandlerPrefix];
}

- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation session:(id<AlfrescoSession>)session
{
    BOOL handled = NO;
    self.urlReceived = url;
    NSUInteger numberOfAccountsSetup = [[AccountManager sharedManager] totalNumberOfAddedAccounts];
    if(numberOfAccountsSetup > 0)
    {
        if(numberOfAccountsSetup > 1)
        {
            NSError *keychainError = nil;
            NSArray *savedAccounts = [KeychainUtils savedAccountsForListIdentifier:kAccountsListIdentifier error:&keychainError];
            
            if (keychainError)
            {
                AlfrescoLogError(@"Error accessing shared keychain. Error: %@", keychainError.localizedDescription);
            }
            
            // Create wrapper accounts
            NSArray *wrapperAccounts = [self createAlfrescoKitUserAccountsFromAppAccounts:savedAccounts];
            // Display the accounts controller
            AKUserAccountListViewController *userAccountViewController = [[AKUserAccountListViewController alloc] initWithAccountList:wrapperAccounts delegate:self];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:userAccountViewController];
            SwitchViewController *switchController = [self presentingViewController];
            if(switchController)
            {
                [UniversalDevice displayModalViewController:navigationController onController:switchController withCompletionBlock:nil];
            }
        }
        else
        {
            handled = [self handleURL:url session:session];
        }
    }

    
    return handled;
}

#pragma mark - Private methods
- (AlfrescoURLType)parseURLForAction:(NSString *)URLString
{
    //Removing the scheme from the url string
    NSString *urlWithoutScheme = [URLString stringByReplacingOccurrencesOfString:kHandlerPrefix withString:@""];
    
    AlfrescoURLType urlType = AlfrescoURLTypeNone;
    
    if([urlWithoutScheme hasPrefix:kDocumentPath])
    {
        urlType = AlfrescoURLTypeDocument;
    }
    else if ([urlWithoutScheme hasPrefix:kFolderPath])
    {
        urlType = AlfrescoURLTypeFolder;
    }
    else if ([urlWithoutScheme hasPrefix:kSitePath])
    {
        urlType = AlfrescoURLTypeSite;
    }
    else if ([urlWithoutScheme hasPrefix:kUserPath])
    {
        urlType = AlfrescoURLTypeUser;
    }
    
    return urlType;
}

- (void)presentViewControllerFromURL:(UIViewController *)controller
{
    SwitchViewController *switchController = [self presentingViewController];
    if(switchController)
    {
        NavigationViewController *navigationController = [[NavigationViewController alloc] initWithRootViewController:controller];
        [switchController displayURLViewController:navigationController];
    }
    
    if([[UniversalDevice rootMasterViewController] isKindOfClass:[MainMenuViewController class]])
    {
        MainMenuViewController *mainMenu = (MainMenuViewController *)[UniversalDevice rootMasterViewController];
        [mainMenu cleanSelection];
    }
}

- (SwitchViewController *)presentingViewController
{
    SwitchViewController *switchController = nil;
    if(IS_IPAD)
    {
        DetailSplitViewController *splitViewController = (DetailSplitViewController *)[UniversalDevice rootDetailViewController];
        if([splitViewController.masterViewController isKindOfClass:[SwitchViewController class]])
        {
            switchController = (SwitchViewController *)splitViewController.masterViewController;
        }
    }
    else if ([[UniversalDevice rootDetailViewController] isKindOfClass:[SwitchViewController class]])
    {
        switchController = (SwitchViewController *)[UniversalDevice rootDetailViewController];
    }
    
    return switchController;
}

- (BOOL)handleURL:(NSURL *)url session:(id<AlfrescoSession>)session
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
            self.personService = [[AlfrescoPersonService alloc] initWithSession:session];
            [self.personService retrievePersonWithIdentifier:username completionBlock:^(AlfrescoPerson *person, NSError *error) {
                if (error)
                {
                    NSString *errorTitle = NSLocalizedString(@"error.person.profile.no.profile.title", @"Profile Error Title");
                    NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.person.profile.no.profile.message", @"Profile Error Message"), username];
                    displayErrorMessageWithTitle(errorMessage, errorTitle);
                }
                else
                {
                    SearchResultsTableViewController *controller = [[SearchResultsTableViewController alloc] initWithDataType:SearchViewControllerDataSourceTypeSearchUsers session:session pushesSelection:YES];
                    controller.results = [NSMutableArray arrayWithObject:person];
                    controller.shouldAutoPushFirstResult = YES;
                    [self presentViewControllerFromURL:controller];
                }
            }];
            
            handled = YES;
        }
        break;
    }
    
    if (self.viewControllerToPresent)
    {
        [self presentViewControllerFromURL:self.viewControllerToPresent];
    }
    
    return handled;
}

- (NSArray *)createAlfrescoKitUserAccountsFromAppAccounts:(NSArray *)userAccounts
{
    NSMutableArray *returnAccounts = [NSMutableArray arrayWithCapacity:userAccounts.count];
    
    for (UserAccount *account in userAccounts)
    {
        UserAccountWrapper *wrapperAccount = [[UserAccountWrapper alloc] initWithUserAccount:account];
        [returnAccounts addObject:wrapperAccount];
    }
    
    return returnAccounts;
}

#pragma mark - AKUserAccountListViewControllerDelegate methods
- (void)userAccountListViewController:(AKUserAccountListViewController *)accountListViewController
                 didLoginSuccessfully:(BOOL)loginSuccessful
                            toAccount:(id<AKUserAccount>)account
                      creatingSession:(id<AlfrescoSession>)session
                                error:(NSError *)error
{
    if(!error)
    {
        SwitchViewController *switchController = [self presentingViewController];
        if(switchController)
        {
            [switchController dismissViewControllerAnimated:YES completion:^{
                [self handleURL:self.urlReceived session:session];
            }];
        }
    }
}

- (void)didSelectLocalFilesOnUserAccountListViewController:(AKUserAccountListViewController *)accountListViewController
{
    //nothing to do
}

- (void)controller:(UIViewController *)controller didStartRequest:(AlfrescoRequest *)request
{
    //nothing to do
}

- (void)controller:(UIViewController *)controller didCompleteRequest:(AlfrescoRequest *)request error:(NSError *)error
{
    //nothing to do
}

@end
