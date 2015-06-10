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
 
#import "AppConfigurationManager.h"
#import "AccountManager.h"
#import "MainMenuVisibilityScope.h"
#import "MainMenuItem.h"

static NSString * const kMainMenuConfigurationDefaultsKey = @"Configuration";

@interface AppConfigurationManager ()
@end

@implementation AppConfigurationManager

+ (AppConfigurationManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static AppConfigurationManager *sharedConfigurationManager = nil;
    dispatch_once(&onceToken, ^{
        sharedConfigurationManager = [[self alloc] init];
    });
    return sharedConfigurationManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRemoved:) name:kAlfrescoAccountRemovedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noMoreAccounts:) name:kAlfrescoAccountsListEmptyNotification object:nil];
        
        [self setupConfigurationFileFromBundleIfRequiredWithCompletionBlock:^(NSString *configurationFilePath) {
            NSDictionary *parameters = @{kAlfrescoConfigServiceParameterFolder: configurationFilePath.stringByDeletingLastPathComponent,
                                         kAlfrescoConfigServiceParameterFileName: configurationFilePath.lastPathComponent};
            
            self.configService = [[AlfrescoConfigService alloc] initWithDictionary:parameters];
            
            [self.configService retrieveDefaultProfileWithCompletionBlock:^(AlfrescoProfileConfig *defaultProfile, NSError *defaultProfileError) {
                if (defaultProfileError)
                {
                    AlfrescoLogError(@"Error retieving the default profile. Error: %@", defaultProfileError.localizedDescription);
                }
                else
                {
                    self.selectedProfile = defaultProfile;
                }
            }];
        }];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray *)visibleItemIdentifiersForAccount:(UserAccount *)account
{
    NSMutableDictionary *savedDictionary = ((NSDictionary *)[[NSUserDefaults standardUserDefaults] valueForKey:kMainMenuConfigurationDefaultsKey]).mutableCopy;
    NSString *accountIdentifier = account.accountIdentifier;
    
    MainMenuVisibilityScope *visibility = [NSKeyedUnarchiver unarchiveObjectWithData:savedDictionary[accountIdentifier]];
    
    return visibility.visibleIdentifiers;
}

- (NSArray *)hiddenItemIdentifiersForAccount:(UserAccount *)account
{
    NSMutableDictionary *savedDictionary = ((NSDictionary *)[[NSUserDefaults standardUserDefaults] valueForKey:kMainMenuConfigurationDefaultsKey]).mutableCopy;
    NSString *accountIdentifier = account.accountIdentifier;
    
    MainMenuVisibilityScope *visibility = [NSKeyedUnarchiver unarchiveObjectWithData:savedDictionary[accountIdentifier]];
    
    return visibility.hiddenIdentifiers;
}

- (void)saveVisibleMenuItems:(NSArray *)visibleMenuItems hiddenMenuItems:(NSArray *)hiddenMenuItems forAccount:(UserAccount *)account
{
    NSArray *orderedVisibleIdentifiers = [visibleMenuItems valueForKey:@"itemIdentifier"];
    NSArray *orderedHiddenIdentifiers = [hiddenMenuItems valueForKey:@"itemIdentifier"];
    
    NSString *accountIdentifier = account.accountIdentifier;
    MainMenuVisibilityScope *visibility = [MainMenuVisibilityScope visibilityScopeWithVisibleIdentifiers:orderedVisibleIdentifiers hiddenIdentifiers:orderedHiddenIdentifiers];
    
    NSDictionary *accountDictionaryToPersist = @{accountIdentifier : [NSKeyedArchiver archivedDataWithRootObject:visibility]};
    
    NSMutableDictionary *savedDictionary = ((NSDictionary *)[[NSUserDefaults standardUserDefaults] valueForKey:kMainMenuConfigurationDefaultsKey]).mutableCopy;
    
    if (!savedDictionary)
    {
        savedDictionary = [NSMutableDictionary dictionary];
    }
    
    [savedDictionary addEntriesFromDictionary:accountDictionaryToPersist];
    
    [[NSUserDefaults standardUserDefaults] setObject:savedDictionary forKey:kMainMenuConfigurationDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)orderedArrayFromUnorderedMainMenuItems:(NSArray *)unorderedMenuItems usingOrderedIdentifiers:(NSArray *)orderListIdentifiers appendNotFoundObjects:(BOOL)append;
{
    NSMutableArray *sortedItems = [NSMutableArray array];
    // Array holding all objects that have not been found in the ordered list of identifiers
    NSMutableArray *notFoundObjects = [NSMutableArray arrayWithArray:unorderedMenuItems];
    
    if (orderListIdentifiers)
    {
        [orderListIdentifiers enumerateObjectsUsingBlock:^(NSString *objectIdentifier, NSUInteger idx, BOOL *stop) {
            NSPredicate *search = [NSPredicate predicateWithFormat:@"itemIdentifier like %@", objectIdentifier];
            MainMenuItem *object = [unorderedMenuItems filteredArrayUsingPredicate:search].firstObject;
            if (object)
            {
                [sortedItems addObject:object];
                [notFoundObjects removeObject:object]; // remove the object if it has been found
            }
        }];
        
        // if we want the not found objects to be appended to the result array
        if (append)
        {
            [sortedItems addObjectsFromArray:notFoundObjects];
        }
    }
    else
    {
        sortedItems = unorderedMenuItems.mutableCopy;
    }
    
    return sortedItems;
}

- (void)setVisibilityForMenuItems:(NSArray *)menuItems forAccount:(UserAccount *)account
{
    NSArray *hiddenIdentifiers = [self hiddenItemIdentifiersForAccount:account];
    
    [hiddenIdentifiers enumerateObjectsUsingBlock:^(NSString *objectIdentifier, NSUInteger idx, BOOL *stop) {
        NSPredicate *search = [NSPredicate predicateWithFormat:@"itemIdentifier like %@", objectIdentifier];
        MainMenuItem *object = [menuItems filteredArrayUsingPredicate:search].firstObject;
        if (object)
        {
            object.hidden = YES;
        }
    }];
}

#pragma mark - Notification Method

- (void)sessionReceived:(NSNotification *)notification
{
    // TODO
}

- (void)accountRemoved:(NSNotification *)notification
{
    // TODO
}

- (void)noMoreAccounts:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAppConfigurationUpdatedNotification object:self userInfo:nil];
}

#pragma mark - Private Methods

- (void)setupConfigurationFileFromBundleIfRequiredWithCompletionBlock:(void (^)(NSString *configurationFilePath))completionBlock
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    
    // File location to the configuration file
    NSString *completeDestinationPath = [[fileManager defaultConfigurationFolderPath] stringByAppendingPathComponent:kAlfrescoEmbeddedConfigurationFileName];
    if (![fileManager fileExistsAtPath:completeDestinationPath])
    {
        NSString *fileLocationInBundle = [[NSBundle mainBundle] pathForResource:kAlfrescoEmbeddedConfigurationFileName.stringByDeletingPathExtension ofType:kAlfrescoEmbeddedConfigurationFileName.pathExtension];
        
        NSError *copyError = nil;
        [fileManager copyItemAtPath:fileLocationInBundle toPath:completeDestinationPath error:&copyError];
        
        if (copyError)
        {
            AlfrescoLogError(@"Unable to copy file from path: %@, to path: %@", fileLocationInBundle, completeDestinationPath);
        }
    }
    
    if (completionBlock != NULL)
    {
        completionBlock(completeDestinationPath);
    }
}

- (NSString *)accountIdentifierForAccount:(UserAccount *)userAccount
{
    NSString *accountIdentifier = userAccount.accountIdentifier;
    
    if (userAccount.accountType == UserAccountTypeCloud)
    {
        accountIdentifier = [NSString stringWithFormat:@"%@-%@", accountIdentifier, userAccount.selectedNetworkId];
    }
    
    return accountIdentifier;
}

@end
