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
#import "FilteredTaskViewController.h"
#import "TaskViewFilter.h"

static NSString * const kHandlerPrefix = @"alfresco://";

static NSString * const kLinkTypeDocument = @"document";
static NSString * const kLinkTypeFolder = @"folder";
static NSString * const kLinkTypeSite = @"site";
static NSString * const kLinkTypeUser = @"user";
static NSString * const kLinkTypeTasks = @"tasks";

static NSString * const kParamTypeObjectId = @"id";
static NSString * const kParamTypeFilter = @"filter";
static NSString * const kParamTypePath = @"path";


@interface AlfrescoURLHandler() < AKUserAccountListViewControllerDelegate >

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
    if (numberOfAccountsSetup > 0)
    {
        if (numberOfAccountsSetup > 1)
        {
            NSError *keychainError = nil;
            NSArray *savedAccounts = [KeychainUtils savedAccountsForListIdentifier:kAccountsListIdentifier error:&keychainError];
            
            if (keychainError)
            {
                AlfrescoLogError(@"Error accessing shared keychain. Error: %@", keychainError.localizedDescription);
                return NO;
            }
            
            // Create wrapper accounts
            NSArray *wrapperAccounts = [self createAlfrescoKitUserAccountsFromAppAccounts:savedAccounts];
            // Display the accounts controller
            AKUserAccountListViewController *userAccountViewController = [[AKUserAccountListViewController alloc] initWithAccountList:wrapperAccounts delegate:self];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:userAccountViewController];
            SwitchViewController *switchController = [self presentingViewController];
            if (switchController)
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

- (void)presentViewControllerFromURL:(UIViewController *)controller
{
    SwitchViewController *switchController = [self presentingViewController];
    if (switchController)
    {
        NavigationViewController *navigationController = [[NavigationViewController alloc] initWithRootViewController:controller];
        [switchController displayURLViewController:navigationController];
    }
    
    if ([[UniversalDevice rootMasterViewController] isKindOfClass:[MainMenuViewController class]])
    {
        MainMenuViewController *mainMenu = (MainMenuViewController *)[UniversalDevice rootMasterViewController];
        [mainMenu cleanSelection];
    }
}

- (SwitchViewController *)presentingViewController
{
    SwitchViewController *switchController = nil;
    if (IS_IPAD)
    {
        DetailSplitViewController *splitViewController = (DetailSplitViewController *)[UniversalDevice rootDetailViewController];
        if ([splitViewController.masterViewController isKindOfClass:[SwitchViewController class]])
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
    UIViewController *viewControllerToPresent = nil;

    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *linkType = [components.host lowercaseString];
    // Note: first path component is likely to be "/"
    NSArray *pathComponents = [components.path pathComponents];

    if (pathComponents.count > 1)
    {
        // Common params
        NSString *paramValueId = nil;
        
        /**
         * kParamTypeObjectId
         */
        if (pathComponents.count > 2 && [pathComponents[1] isEqualToString:kParamTypeObjectId])
        {
            paramValueId = pathComponents[2];
        }
        else
        {
            paramValueId = pathComponents[1];
        }
        
        /**
         * Document
         */
        if ([linkType isEqualToString:kLinkTypeDocument])
        {
            if (paramValueId.length > 0)
            {
                NSString *nodeRef = [NSString stringWithFormat:@"workspace://SpacesStore/%@", paramValueId];
                viewControllerToPresent = [[FileFolderCollectionViewController alloc] initWithDocumentNodeRef:nodeRef session:session];
                handled = YES;
            }
        }

        /**
         * Folder
         */
        else if ([linkType isEqualToString:kLinkTypeFolder])
        {
            if (paramValueId.length > 0)
            {
                NSString *nodeRef = [NSString stringWithFormat:@"workspace://SpacesStore/%@", paramValueId];
                viewControllerToPresent = [[FileFolderCollectionViewController alloc] initWithNodeRef:nodeRef folderPermissions:nil folderDisplayName:nil listingContext:nil session:session];
                handled = YES;
            }
        }

        /**
         * Site
         */
        else if ([linkType isEqualToString:kLinkTypeSite])
        {
            if (paramValueId.length > 0)
            {
                viewControllerToPresent = [[FileFolderCollectionViewController alloc] initWithSiteShortname:paramValueId sitePermissions:nil siteDisplayName:nil listingContext:nil session:session];
                handled = YES;
            }
        }

        /**
         * User
         */
        else if ([linkType isEqualToString:kLinkTypeUser])
        {
            if (paramValueId.length > 0)
            {
                self.personService = [[AlfrescoPersonService alloc] initWithSession:session];
                [self.personService retrievePersonWithIdentifier:paramValueId completionBlock:^(AlfrescoPerson *person, NSError *error) {
                    if (error)
                    {
                        NSString *errorTitle = NSLocalizedString(@"error.person.profile.no.profile.title", @"Profile Error Title");
                        NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.person.profile.no.profile.message", @"Profile Error Message"), paramValueId];
                        displayErrorMessageWithTitle(errorMessage, errorTitle);
                    }
                    else
                    {
                       SearchResultsTableViewController *controller = [[SearchResultsTableViewController alloc] initWithDataType:SearchViewControllerDataSourceTypeSearchUsers session:session pushesSelection:YES dataSourceArray:@[person]];
                        controller.shouldAutoPushFirstResult = YES;
                        [self presentViewControllerFromURL:controller];
                    }
                }];
                handled = YES;
            }
        }

        /**
         * Task
         */
        else if ([linkType isEqualToString:kLinkTypeTasks])
        {
            /**
             * kParamTypeFilter
             */
            if (pathComponents.count > 1 && [pathComponents[1] isEqualToString:kParamTypeFilter] && components.queryItems.count > 0)
            {
                NSMutableDictionary *filters = [[NSMutableDictionary alloc] init];
                
                // Pull out the filter parameters from the queryString; they must follow the same format as the view configuration
                for (NSURLQueryItem *queryItem in components.queryItems)
                {
                    if (queryItem.name.length > 0 && queryItem.value.length > 0)
                    {
                        filters[queryItem.name] = queryItem.value;
                    }
                }

                if (filters.count > 0)
                {
                    TaskViewFilter *taskFilter = [[TaskViewFilter alloc] initWithDictionary:filters];
                    viewControllerToPresent = [[FilteredTaskViewController alloc] initWithFilter:taskFilter listingContext:nil session:session];
                    handled = YES;
                }
            }
        }
    }
    
    if (viewControllerToPresent)
    {
        [self presentViewControllerFromURL:viewControllerToPresent];
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
        // Another account is selected.
        if (![[AccountManager sharedManager].selectedAccount.accountIdentifier isEqualToString:[account identifier]])
        {
            [[AccountManager sharedManager].allAccounts enumerateObjectsUsingBlock:^(UserAccount *userAccount, NSUInteger idx, BOOL *stop){
                if ([userAccount.accountIdentifier isEqualToString:[account identifier]])
                {
                    [[AccountManager sharedManager] selectAccount:userAccount selectNetwork:[account selectedNetworkIdentifier] alfrescoSession:session];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:nil];
                    *stop = YES;
                }
            }];
        }

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
