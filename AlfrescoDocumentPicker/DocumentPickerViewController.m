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

#import "DocumentPickerViewController.h"
#import "UserAccount.h"
#import "UserAccountWrapper.h"
#import "KeychainUtils.h"
#import "AppConfiguration.h"
#import "SharedConstants.h"
#import "CustomFolderService.h"
#import "MBProgressHUD.h"
#import "AlfrescoFileManager+Extensions.h"
#import "NSFileManager+Extension.h"
#import "FileMetadata.h"
#import "PersistentQueueStore.h"
#import "Utilities.h"
#import <Google/Analytics.h>
#import "AnalyticsConstants.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "PinViewController.h"
#import "TouchIDManager.h"
#import "Utility.h"

static NSString * const kAccountsListIdentifier = @"AccountListNew";

@interface DocumentPickerViewController () <AKUserAccountListViewControllerDelegate,
                                            AKAlfrescoNodePickingListViewControllerDelegate,
                                            AKScopePickingViewControllerDelegate,
                                            AKSitesListViewControllerDelegate,
                                            AKLoginViewControllerDelegate,
                                            AKNamingViewControllerDelegate,
                                            AKLocalFilesViewControllerDelegate,
                                            AKFavoritesListViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIView *containingView;
@property (weak, nonatomic) IBOutlet UIView *appResetedView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) id<AKUserAccount> account;
@property (nonatomic, strong) UINavigationController *embeddedNavigationController;
@property (nonatomic, strong) PersistentQueueStore *queueStore;
@property (nonatomic, strong) CustomFolderService *customFolderService;

@end

@implementation DocumentPickerViewController

-(void)prepareForPresentationInMode:(UIDocumentPickerMode)mode
{
    self.navigationController.navigationBar.translucent = NO;
    
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
    self.embeddedNavigationController = navigationController;
    [self setRootEmbeddedController:navigationController];
    
    [self setupSecurityMechanism];
}

- (void) setupSecurityMechanism
{
    self.infoLabel.text = NSLocalizedString(@"document.picker.scope.launch.main.app", @"Please launch the Alfresco app before using this extension.");
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
    BOOL shouldResetEntireApp = [defaults boolForKey:kShouldResetEntireAppKey];
    
    if (shouldResetEntireApp)
    {
        self.appResetedView.hidden = NO;
    }
    else
    {
        self.appResetedView.hidden = YES;
        
        NSError *error;
        NSString *pin = [KeychainUtils retrieveItemForKey:kPinKey
                                                  inGroup:kSharedAppGroupIdentifier
                                                    error:&error];
        
        BOOL isPasscodeSet = (pin != nil);
        
        if (isPasscodeSet)
        {
            [self presentSecurityMechanism];
        }
    }
}

- (void)presentSecurityMechanism
{
    UINavigationController *navC = [PinViewController pinNavigationViewControllerWithFlow:PinFlowVerify animatedDismiss:NO completionBlock:^(PinFlowCompletionStatus status){
                                        if (status == PinFlowCompletionStatusReset)
                                        {
                                            NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
                                            [defaults setBool:YES forKey:kShouldResetEntireAppKey];
                                            [defaults synchronize];
                                            
                                            self.appResetedView.hidden = NO;
                                        }
                                        else if (status == PinFlowCompletionStatusCancel)
                                        {
                                            [self dismissGrantingAccessToURL:nil];
                                        }
                                    }];
    
    [self presentViewController:navC animated:NO completion:nil];
    
    if ([TouchIDManager shouldUseTouchID])
    {
        [TouchIDManager evaluatePolicyWithCompletionBlock:^(BOOL success, NSError *authenticationError){
            if (success)
            {
                [navC dismissViewControllerAnimated:NO completion:nil];
            }
        }];
    }
}

#pragma mark - Custom Getters and Setters

- (PersistentQueueStore *)queueStore
{
    if (!_queueStore)
    {
        _queueStore = [[PersistentQueueStore alloc] initWithGroupContainerIdentifier:kSharedAppGroupIdentifier];
    }
    return _queueStore;
}

#pragma mark - Private Methods

- (void)setRootEmbeddedController:(UIViewController *)controller
{
    [self addChildViewController:controller];
    [self.containingView addSubview:controller.view];
    // Constraints
    controller.view.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *view = @{@"childView" : controller.view};
    NSArray *vertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[childView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:view];
    NSArray *horizontal = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[childView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:view];
    [self.containingView addConstraints:vertical];
    [self.containingView addConstraints:horizontal];
    [controller didMoveToParentViewController:self];
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

- (NSURL *)configurationFileNameURLForAccount:(id<AKUserAccount>)account
{
    NSString *accountIdentifier = account.identifier;
    
    if (!account.isOnPremiseAccount)
    {
        accountIdentifier = [NSString stringWithFormat:@"%@-%@", accountIdentifier, account.selectedNetworkIdentifier];
    }
    
    NSString *configurationFileName = [accountIdentifier stringByAppendingPathExtension:[kAppConfigurationFileLocationOnServer pathExtension]];
    NSURL *sharedContainerURL = [[NSFileManager alloc] containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroupIdentifier];
    NSString *filePath = [sharedContainerURL.path stringByAppendingPathComponent:configurationFileName];
    
    return [NSURL fileURLWithPath:filePath];
}

- (NSArray *)scopeItemsForAccount:(id<AKUserAccount>)account myFilesFolder:(AlfrescoFolder *)myFilesFolder sharedFilesFolder:(AlfrescoFolder *)sharedFilesFolder
{
    // Default visibility
    BOOL showRepository = YES;
    BOOL showSites = YES;
    BOOL showFavourites = YES;
    BOOL showSharedFiles = !!sharedFilesFolder;
    BOOL showMyFiles = !!myFilesFolder;
    
    NSURL *configFilePathURL = [self configurationFileNameURLForAccount:account];
    BOOL appConfigurationFileExists = [[NSFileManager defaultManager] fileExistsAtPath:configFilePathURL.path];
    if (appConfigurationFileExists)
    {
        AppConfiguration *configuration = [[AppConfiguration alloc] initWithAppConfigurationFileURL:configFilePathURL];
        showRepository = [configuration visibilityInRootMenuForKey:kAppConfigurationRepositoryKey];
        showSites = [configuration visibilityInRootMenuForKey:kAppConfigurationSitesKey];
        showFavourites = [configuration visibilityInRootMenuForKey:kAppConfigurationFavoritesKey];
    }
    
    NSMutableArray *scopeItems = [NSMutableArray array];
    
    if (showRepository)
    {
        AKScopeItem *repoScope = [[AKScopeItem alloc] initWithIdentifier:kAppConfigurationRepositoryKey
                                                                scopeType:AKScopeType_Repository
                                                                    name:NSLocalizedString(@"document.picker.scope.repository", @"Respository")];
        [scopeItems addObject:repoScope];
    }
    if (showSites)
    {
        AKScopeItem *siteScope = [[AKScopeItem alloc] initWithIdentifier:kAppConfigurationSitesKey
                                                                scopeType:AKScopeType_Sites
                                                                    name:NSLocalizedString(@"document.picker.scope.sites", @"Sites")];
        [scopeItems addObject:siteScope];
    }
    if (showFavourites)
    {
        AKScopeItem *favouriteScope = [[AKScopeItem alloc] initWithIdentifier:kAppConfigurationFavoritesKey
                                                                     scopeType:AKScopeType_Favorites
                                                                         name:NSLocalizedString(@"document.picker.scope.favourites", @"Favourites")];
        [scopeItems addObject:favouriteScope];
    }
    if (showSharedFiles)
    {
        AKScopeItem *sharedFilesScope = [[AKScopeItem alloc] initWithIdentifier:kAppConfigurationSharedFilesKey
                                                                       scopeType:AKScopeType_SharedFiles
                                                                           name:NSLocalizedString(@"document.picker.scope.shared.files", @"Shared Files")
                                                                       userInfo:sharedFilesFolder];
        [scopeItems addObject:sharedFilesScope];
    }
    if (showMyFiles)
    {
        AKScopeItem *myFilesScope = [[AKScopeItem alloc] initWithIdentifier:kAppConfigurationMyFilesKey
                                                                   scopeType:AKScopeType_MyFiles
                                                                       name:NSLocalizedString(@"document.picker.scope.my.files", @"My Files")
                                                                   userInfo:myFilesFolder];
        [scopeItems addObject:myFilesScope];
    }
    
    return scopeItems;
}

- (void)displayScopeViewControllerFromController:(UIViewController *)controller forAccount:(id<AKUserAccount>)account session:(id<AlfrescoSession>)session completionBlock:(void (^)(void))completionBlock
{
    self.account = account;
    self.session = session;
    self.customFolderService = [[CustomFolderService alloc] initWithSession:session];
    
    void (^createAndPushScopeViewController)(NSArray *, id<AKScopePickingViewControllerDelegate>) = ^(NSArray *scopeItems, id<AKScopePickingViewControllerDelegate>scopeDelegate) {
        AKScopePickingViewController *scopePickingViewController = [[AKScopePickingViewController alloc] initWithScopeItems:scopeItems delegate:scopeDelegate];
        [self.embeddedNavigationController pushViewController:scopePickingViewController animated:YES];
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    };
    
    // Show a progress indicator
    MBProgressHUD *spinner = [self spinningHUDForView:controller.view];
    [controller.view addSubview:spinner];
    [spinner showAnimated:YES];
    // Get shared and my file folders
    [self.customFolderService retrieveMyFilesFolderWithCompletionBlock:^(AlfrescoFolder *myFilesFolder, NSError *error) {
        [self.customFolderService retrieveSharedFilesFolderWithCompletionBlock:^(AlfrescoFolder *sharedFilesFolder, NSError *error) {
            [spinner hideAnimated:YES];
            NSArray *scopeItems = [self scopeItemsForAccount:account myFilesFolder:myFilesFolder sharedFilesFolder:sharedFilesFolder];
            createAndPushScopeViewController(scopeItems, self);
        }];
    }];
}

- (MBProgressHUD *)spinningHUDForView:(UIView *)view
{
    MBProgressHUD *spinningHUD = [[MBProgressHUD alloc] initWithView:view];
    spinningHUD.removeFromSuperViewOnHide = YES;
    return spinningHUD;
}

- (MBProgressHUD *)progressHUDForView:(UIView *)view
{
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:view];
    progressHUD.mode = MBProgressHUDModeDeterminate;
    progressHUD.progress = 0.0f;
    progressHUD.removeFromSuperViewOnHide = YES;
    return progressHUD;
}

- (void)displayErrorAlertWithMessage:(NSString *)message error:(NSError *)error
{
    [self displayErrorAlertWithTitle:NSLocalizedString(@"error.generic.title", @"We hit a problem") message:message error:error];
}

- (void)displayErrorAlertWithTitle:(NSString *)title message:(NSString *)message error:(NSError *)error
{
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
    
    AlfrescoLogError(@"Error: %@", error.localizedDescription);
}

#pragma mark - AKUserAccountListViewControllerDelegate Methods

- (void)userAccountListViewController:(AKUserAccountListViewController *)accountListViewController
                 didLoginSuccessfully:(BOOL)loginSuccessful
                            toAccount:(id<AKUserAccount>)account
                      creatingSession:(id<AlfrescoSession>)session
                                error:(NSError *)error
{
    if (loginSuccessful)
    {
        [self displayScopeViewControllerFromController:accountListViewController forAccount:account session:session completionBlock:nil];
    }
    else
    {
        void (^loginBlock)(AlfrescoOAuthData *, AlfrescoSAMLData *) = ^void(AlfrescoOAuthData *oauthData, AlfrescoSAMLData *samlData){
            AKLoginService *loginService = [[AKLoginService alloc] init];
            [loginService loginToAccount:account networkIdentifier:account.selectedNetworkIdentifier completionBlock:^(BOOL successful, id<AlfrescoSession> session, NSError *loginError) {
                if (successful)
                {
                    NSError *accountSavingError = nil;
                    NSArray *accountList = [KeychainUtils savedAccountsForListIdentifier:kAccountsListIdentifier error:&accountSavingError];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"accountIdentifier == %@", account.identifier];
                    NSArray *accountArray = [accountList filteredArrayUsingPredicate:predicate];
                    UserAccount *keychainAccount = accountArray.firstObject;
                    
                    if (oauthData)
                    {
                        keychainAccount.oauthData = oauthData;
                    }
                    
                    if (samlData)
                    {
                        if(keychainAccount.samlData && !samlData.samlInfo)
                        {
                            samlData.samlInfo = keychainAccount.samlData.samlInfo;
                        }
                        keychainAccount.samlData = samlData;
                    }
                    
                    [KeychainUtils updateSavedAccount:keychainAccount forListIdentifier:kAccountsListIdentifier error:&accountSavingError];
                    if (accountSavingError)
                    {
                        AlfrescoLogError(@"Error accessing shared keychain. Error: %@", accountSavingError.localizedDescription);
                    }
                    [self displayScopeViewControllerFromController:accountListViewController forAccount:account session:session completionBlock:^{
                        // Remove the login controller from the nav stack
                        NSMutableArray *navigationStack = self.embeddedNavigationController.viewControllers.mutableCopy;
                        [navigationStack removeObjectAtIndex:(navigationStack.count-2)];
                        self.embeddedNavigationController.viewControllers = navigationStack;
                    }];
                }
                else
                {
                    [self displayErrorAlertWithMessage:loginError.localizedDescription error:loginError];
                }
            }];
        };
        
        if (account.isOnPremiseAccount)
        {
            NSString *urlString = [Utilities serverURLStringFromAccount:account];
            [AlfrescoSAMLAuthHelper checkIfSAMLIsEnabledForServerWithUrlString:urlString completionBlock:^(AlfrescoSAMLData *samlData, NSError *error) {
                
                if (error || [samlData isSamlEnabled] == NO)
                {
                    AKLoginViewController *loginViewController = [[AKLoginViewController alloc] initWithUserAccount:account delegate:self];
                    [self.embeddedNavigationController pushViewController:loginViewController animated:YES];
                }
                else
                {
                    AlfrescoSAMLUILoginViewController *loginController = [[AlfrescoSAMLUILoginViewController alloc] initWithBaseURLString:urlString completionBlock:^(AlfrescoSAMLData *samlData, NSError *error) {
                        if (error)
                        {
                            [self displayErrorAlertWithMessage:error.localizedDescription error:error];
                        }
                        else
                        {
                            account.samlData.samlTicket = samlData.samlTicket;
                            loginBlock(nil, samlData);
                        }
                    }];
                    
                    [self.embeddedNavigationController pushViewController:loginController animated:YES];
                    
                    [DocumentPickerViewController trackScreenWithName:kAnalyticsViewAccountSAML];
                }
            }];
        }
        else
        {
            AlfrescoOAuthUILoginViewController *loginController = [[AlfrescoOAuthUILoginViewController alloc] initWithAPIKey:CLOUD_OAUTH_KEY secretKey:CLOUD_OAUTH_SECRET completionBlock:^(AlfrescoOAuthData *oauthData, NSError *loginControllerError) {
                if (loginControllerError)
                {
                    [self displayErrorAlertWithMessage:loginControllerError.localizedDescription error:loginControllerError];
                }
                else
                {
                    account.oAuthData = oauthData;
                    loginBlock (oauthData, nil);
                }
            }];
            
            [self.embeddedNavigationController pushViewController:loginController animated:YES];
            
            [DocumentPickerViewController trackScreenWithName:kAnalyticsViewAccountOAuth];
        }
    }
}

- (void)didSelectLocalFilesOnUserAccountListViewController:(AKUserAccountListViewController *)accountListViewController
{
    AKLocalFileControllerType mode;
    
    if (self.documentPickerMode == UIDocumentPickerModeImport || self.documentPickerMode == UIDocumentPickerModeOpen)
    {
        mode = AKLocalFileControllerTypeFilePicker;
    }
    else
    {
        mode = AKLocalFileControllerTypeFolderPicker;
    }
    NSString *downloadContentPath = [[AlfrescoFileManager sharedManager] downloadsContentFolderPath];
    NSURL *downloadContentURL = [NSURL fileURLWithPath:downloadContentPath];
    AKLocalFilesViewController *localFileController = [[AKLocalFilesViewController alloc] initWithMode:mode url:downloadContentURL delegate:self];
    
    [self.embeddedNavigationController pushViewController:localFileController animated:YES];
}

#pragma mark Code used to handle selecting a document or a folder

- (void)handleSelectionFromController:(UIViewController *)controller selectedNodes:(NSArray *)selectedNodes
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    AlfrescoDocument *document = selectedNodes.firstObject;
    NSString *uniqueFilename = [Utilities filenameWithVersionFromFilename:document.name nodeIdentifier:document.identifier];
    NSURL *uniqueURL = [self.documentStorageURL URLByAppendingPathComponent:[Utilities nodeGUIDFromNodeIdentifierWithVersion:document.identifier]];
    
    if (![fileManager fileExistsAtPath:uniqueURL.path])
    {
        NSError *creationError = nil;
        [fileManager createDirectoryAtURL:uniqueURL withIntermediateDirectories:YES attributes:nil error:&creationError];
        
        if (creationError)
        {
            AlfrescoLogError(@"Unable to create folder at path: %@. Error: %@", uniqueURL, creationError.localizedDescription);
        }
    }
    
    NSURL *outURL = [uniqueURL URLByAppendingPathComponent:uniqueFilename];
    
    if (self.documentPickerMode == UIDocumentPickerModeImport)
    {
        // Show Progress HUD
        MBProgressHUD *progressHUD = [self progressHUDForView:controller.view];
        [controller.view addSubview:progressHUD];
        [progressHUD showAnimated:YES];
        
        NSOutputStream *outputStream = [NSOutputStream outputStreamWithURL:outURL append:NO];
        AlfrescoDocumentFolderService *docService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
        [docService retrieveContentOfDocument:document outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
            [progressHUD hideAnimated:YES];
            if (error)
            {
                [self displayErrorAlertWithMessage:error.localizedDescription error:error];
            }
            else
            {
                NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
                [coordinator coordinateWritingItemAtURL:outURL options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL *newURL) {
                    NSFileManager *fileManager = [[NSFileManager alloc] init];
                    [fileManager setAttributes:@{NSFileModificationDate : document.modifiedAt} ofItemAtPath:outURL.path error:nil];
                    [fileManager copyItemAtURL:outURL toURL:newURL error:nil];
                    
                    [DocumentPickerViewController trackEventWithAction:kAnalyticsEventActionOpen
                                                                 label:[DocumentPickerViewController mimeTypeForFileExtension:newURL.absoluteString]];
                }];
                
                [self dismissGrantingAccessToURL:outURL];
            }
        } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
            progressHUD.progress = (bytesTotal != 0) ? (float)bytesTransferred / (float)bytesTotal : 0;
        }];
    }
    else if (self.documentPickerMode == UIDocumentPickerModeOpen)
    {
        // Show Progress HUD
        MBProgressHUD *progressHUD = [self progressHUDForView:controller.view];
        progressHUD.mode = MBProgressHUDModeIndeterminate;
        [controller.view addSubview:progressHUD];
        [progressHUD showAnimated:YES];
        
        // Retrieve Permissions
        AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
        [documentService retrievePermissionsOfNode:document completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
            [progressHUD hideAnimated:YES];
            if (error)
            {
                [self displayErrorAlertWithMessage:error.localizedDescription error:error];
            }
            else
            {
                void (^cacheAndDismissBlock)(FileMetadataSaveLocation saveLocation) = ^(FileMetadataSaveLocation location) {
                    NSArray *fileURLs = [self.queueStore.queue valueForKey:@"fileURL"];
                    
                    FileMetadata *metadata = [[FileMetadata alloc] initWithAccountIdentififer:self.account.identifier networkIdentifier:self.account.selectedNetworkIdentifier repositoryNode:document fileURL:outURL sourceLocation:location mode:self.documentPickerMode];
                    
                    if (![fileURLs containsObject:outURL])
                    {
                        [self.queueStore addObjectToQueue:metadata];
                    }
                    else
                    {
                        NSUInteger indexOfMetadata = [fileURLs indexOfObject:outURL];
                        [self.queueStore replaceObjectInQueueAtIndex:indexOfMetadata withObject:metadata];
                    }
                    [self.queueStore saveQueue];
                    
                    [DocumentPickerViewController trackEventWithAction:kAnalyticsEventActionOpen
                                                                 label:[DocumentPickerViewController mimeTypeForFileExtension:outURL.absoluteString]];
                    
                    [self dismissGrantingAccessToURL:outURL];
                };
                
                if (permissions.canEdit)
                {
                    cacheAndDismissBlock(FileMetadataSaveLocationRepository);
                }
                else
                {
                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", "OK")
                                                                     style:UIAlertActionStyleCancel
                                                                   handler:^(UIAlertAction *action) {
                        cacheAndDismissBlock(FileMetadataSaveLocationLocalFiles);
                    }];
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"document.picker.scope.permissions.cannot.edit.title", "Permissions Error")
                                                                                   message:NSLocalizedString(@"document.picker.scope.permissions.cannot.edit.message", @"Permissions Message")
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:cancel];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }
        }];
        
        
    }
    else if (self.documentPickerMode == UIDocumentPickerModeExportToService || self.documentPickerMode == UIDocumentPickerModeMoveToService)
    {
        AlfrescoFolder *uploadFolder = selectedNodes.firstObject;
        AKNamingViewController *namingController = [[AKNamingViewController alloc] initWithURL:nil delegate:self userInfo:uploadFolder];
        [self.embeddedNavigationController pushViewController:namingController animated:YES];
    }
}

#pragma mark - AKLoginViewControllerDelegate Methods

- (void)loginViewController:(AKLoginViewController *)loginController
       didLoginSuccessfully:(BOOL)loginSuccessful
                  toAccount:(id<AKUserAccount>)account
                   username:(NSString *)username
                   password:(NSString *)password
            creatingSession:(id<AlfrescoSession>)session
                      error:(NSError *)error
{
    if (loginSuccessful)
    {
        [self displayScopeViewControllerFromController:loginController forAccount:account session:session completionBlock:^{
            // Remove the login controller from the nav stack
            NSMutableArray *navigationStack = self.embeddedNavigationController.viewControllers.mutableCopy;
            [navigationStack removeObjectAtIndex:(navigationStack.count-2)];
            self.embeddedNavigationController.viewControllers = navigationStack;
        }];
    }
    else
    {
        [self displayErrorAlertWithMessage:error.localizedDescription error:error];
    }
}

#pragma mark - AKScopePickingViewControllerDelegate Methods

- (void)scopePickingController:(AKScopePickingViewController *)scopePickingController didSelectScopeItem:(AKScopeItem *)scopeItem
{
    UIViewController *pushController = nil;
    
    if ([scopeItem.identifier isEqualToString:kAppConfigurationRepositoryKey])
    {
        pushController = [self folderOrDocumentPickingViewControllerWithRootFolder:nil delegate:self session:self.session];
    }
    else if ([scopeItem.identifier isEqualToString:kAppConfigurationSitesKey])
    {
        pushController = [[AKSitesListViewController alloc] initWithSession:self.session delegate:self];
    }
    else if ([scopeItem.identifier isEqualToString:kAppConfigurationFavoritesKey])
    {
        pushController = [self favouritesViewControllerWithDelegate:self session:self.session];
    }
    else if ([scopeItem.identifier isEqualToString:kAppConfigurationMyFilesKey])
    {
        pushController = [self folderOrDocumentPickingViewControllerWithRootFolder:(AlfrescoFolder *)scopeItem.userInfo delegate:self session:self.session];
    }
    else if ([scopeItem.identifier isEqualToString:kAppConfigurationSharedFilesKey])
    {
        pushController = [self folderOrDocumentPickingViewControllerWithRootFolder:(AlfrescoFolder *)scopeItem.userInfo delegate:self session:self.session];
    }
    
    [self.embeddedNavigationController pushViewController:pushController animated:YES];
}

- (UIViewController *)folderOrDocumentPickingViewControllerWithRootFolder:(AlfrescoFolder *)folder delegate:(id)delegate session:(id<AlfrescoSession>)session
{
    UIViewController *returnController = nil;
    
    if (self.documentPickerMode == UIDocumentPickerModeImport || self.documentPickerMode == UIDocumentPickerModeOpen)
    {
        returnController = [[AKAlfrescoNodePickingListViewController alloc] initAlfrescoDocumentPickerWithRootFolder:folder multipleSelection:NO selectedNodes:nil delegate:self session:session];
    }
    else
    {
        returnController = [[AKAlfrescoNodePickingListViewController alloc] initAlfrescoFolderPickerWithRootFolder:folder selectedNodes:nil delegate:self session:session];
    }
    
    return returnController;
}

- (UIViewController *)favouritesViewControllerWithDelegate:(id<AKFavoritesListViewControllerDelegate>)delegate session:(id<AlfrescoSession>)session
{
    AKFavoritesControllerType type;
    if (self.documentPickerMode == UIDocumentPickerModeImport || self.documentPickerMode == UIDocumentPickerModeOpen)
    {
        type = AKFavoritesControllerTypeFilePicker;
    }
    else
    {
        type = AKFavoritesControllerTypeFolderPicker;
    }
    
    AKFavoritesListViewController *favouritesListViewController = [[AKFavoritesListViewController alloc] initWithMode:type delegate:delegate session:session];
    return favouritesListViewController;
}

#pragma mark - AKSitesListViewControllerDelegate Methods

- (void)sitesListViewController:(AKSitesListViewController *)sitesListViewController
                  didSelectSite:(AlfrescoSite *)site
          documentLibraryFolder:(AlfrescoFolder *)documentLibraryFolder
                          error:(NSError *)error
{
    UIViewController *viewController = [self folderOrDocumentPickingViewControllerWithRootFolder:documentLibraryFolder delegate:self session:self.session];
    [self.embeddedNavigationController pushViewController:viewController animated:YES];
}

#pragma mark - AKAlfrescoNodePickingListViewController Methods

- (void)nodePickingListViewController:(AKAlfrescoNodePickingListViewController *)nodePickingListViewController didSelectNodes:(NSArray *)selectedNodes;
{
    [self handleSelectionFromController:nodePickingListViewController selectedNodes:selectedNodes];
}

#pragma mark - AKNamingViewControllerDelegate Methods
#pragma mark Code used to handle creating content on the repo or moving to Local Files

- (void)namingViewController:(AKNamingViewController *)namingController didEnterName:(NSString *)name userInfo:(id)userInfo
{
    // If a node, then uploading to the repo, else, move to 
    if ([userInfo isKindOfClass:[AlfrescoNode class]])
    {
        BOOL access = [self.originalURL startAccessingSecurityScopedResource];
        
        if (access)
        {
            NSString *enteredFileName = [name stringByDeletingPathExtension];
            NSString *enteredExtension = name.pathExtension;
            
            NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
            NSError *error = nil;
            [fileCoordinator coordinateReadingItemAtURL:self.originalURL options:NSFileCoordinatorReadingForUploading error:&error byAccessor:^(NSURL *newURL) {
                // Move the copy the file to the shared container
                NSString *pathExtension = (enteredExtension && enteredExtension.length > 0) ? enteredExtension : newURL.pathExtension;
                NSString *fileName = [enteredFileName stringByAppendingPathExtension:pathExtension];
                
                NSURL *outURL = [self.documentStorageURL URLByAppendingPathComponent:fileName];
                NSFileManager *fileManager = [[NSFileManager alloc] init];
                NSError *fileCopyError = nil;
                [fileManager copyItemAtURL:newURL toURL:outURL overwritingExistingFile:YES error:&fileCopyError];
                
                // Show Progress HUD
                MBProgressHUD *progressHUD = [self progressHUDForView:namingController.view];
                [namingController.view addSubview:progressHUD];
                [progressHUD showAnimated:YES];
                
                // Initiate the upload
                AlfrescoDocumentFolderService *docService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
                AlfrescoFolder *uploadFolder = (AlfrescoFolder *)userInfo;
                AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:newURL];
                
                NSInputStream *inputStream = [NSInputStream inputStreamWithURL:outURL];
                AlfrescoContentStream *contentStream = [[AlfrescoContentStream alloc] initWithStream:inputStream mimeType:contentFile.mimeType length:contentFile.length];
                [docService createDocumentWithName:fileName inParentFolder:uploadFolder contentStream:contentStream properties:nil completionBlock:^(AlfrescoDocument *document, NSError *error) {
                    [progressHUD hideAnimated:YES];
                    if (error)
                    {
                        [self displayErrorAlertWithMessage:error.localizedDescription error:error];
                    }
                    else
                    {
                        FileMetadata *metadata = [[FileMetadata alloc] initWithAccountIdentififer:self.account.identifier networkIdentifier:self.account.selectedNetworkIdentifier repositoryNode:document fileURL:outURL sourceLocation:FileMetadataSaveLocationRepository mode:self.documentPickerMode];
                        [self.queueStore addObjectToQueue:metadata];
                        [self.queueStore saveQueue];
                        
                        [DocumentPickerViewController trackEventWithAction:kAnalyticsEventActionCreate
                                                                     label:document.contentMimeType];
                        [self dismissGrantingAccessToURL:outURL];
                    }
                } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                    progressHUD.progress = (bytesTotal != 0) ? (float)bytesTransferred / (float)bytesTotal : 0;
                }];
            }];
            [self.originalURL stopAccessingSecurityScopedResource];
        }
    }
    else
    {
        BOOL access = [self.originalURL startAccessingSecurityScopedResource];
        
        if (access)
        {
            NSString *enteredFileName = [name stringByDeletingPathExtension];
            NSString *enteredExtension = name.pathExtension;
            NSString *pathExtension = (enteredExtension && enteredExtension.length > 0) ? enteredExtension : self.originalURL.pathExtension;
            NSString *fileName = [enteredFileName stringByAppendingPathExtension:pathExtension];
            
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            
            NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
            __block NSError *error = nil;
            [fileCoordinator coordinateReadingItemAtURL:self.originalURL options:NSFileCoordinatorReadingForUploading error:&error byAccessor:^(NSURL *newURL) {
                NSURL *completeDocumentStorageURL = [self.documentStorageURL URLByAppendingPathComponent:fileName];
                NSError *copyError = nil;
                [fileManager copyItemAtURL:newURL toURL:completeDocumentStorageURL overwritingExistingFile:YES error:&copyError];
                
                if (copyError)
                {
                    AlfrescoLogError(@"Unable to copy file from location: %@ to location: %@", newURL, completeDocumentStorageURL);
                }
                
                NSString *fullDestinationPath = [[[AlfrescoFileManager sharedManager] downloadsContentFolderPath] stringByAppendingPathComponent:fileName];
                NSURL *downloadPath = [NSURL fileURLWithPath:fullDestinationPath];
                
                void (^saveFileMetadataInfo)(NSString *) = ^(NSString *eventActionKey) {
                    [DocumentPickerViewController trackEventWithAction:eventActionKey
                                                                 label:[DocumentPickerViewController mimeTypeForFileExtension:downloadPath.absoluteString]];
                    
                    FileMetadata *metadata = [[FileMetadata alloc] initWithAccountIdentififer:self.account.identifier networkIdentifier:self.account.selectedNetworkIdentifier repositoryNode:nil fileURL:completeDocumentStorageURL sourceLocation:FileMetadataSaveLocationLocalFiles mode:self.documentPickerMode];
                    [self.queueStore addObjectToQueue:metadata];
                    [self.queueStore saveQueue];
                    
                    [self dismissGrantingAccessToURL:completeDocumentStorageURL];
                };
                
                if ([fileManager fileExistsAtPath:fullDestinationPath])
                {
                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No") style:UIAlertActionStyleCancel handler:nil];
                    UIAlertAction *overwrite = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        saveFileMetadataInfo(kAnalyticsEventActionUpdate);
                    }];
                    
                    NSString *title = NSLocalizedString(@"document.picker.scope.overwrite.title", @"Overwrite Title");
                    NSString *message = NSLocalizedString(@"document.picker.scope.overwrite.message", @"Overwrite Message");
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:cancel];
                    [alertController addAction:overwrite];
                    [self presentViewController:alertController animated:YES completion:nil];
                }
                else
                {
                    saveFileMetadataInfo(kAnalyticsEventActionCreate);
                }
            }];
            
            [self.originalURL stopAccessingSecurityScopedResource];
        }
    }
}

#pragma mark - AKNetworkActivity Methods

- (void)controller:(UIViewController *)controller didStartRequest:(AlfrescoRequest *)request
{
    MBProgressHUD *spinner = [self spinningHUDForView:controller.view];
    [controller.view addSubview:spinner];
    [spinner showAnimated:YES];
}

- (void)controller:(UIViewController *)controller didCompleteRequest:(AlfrescoRequest *)request error:(NSError *)error
{
    for (UIView *subview in controller.view.subviews)
    {
        if ([subview isKindOfClass:[MBProgressHUD class]])
        {
            MBProgressHUD *hud = (MBProgressHUD *)subview;
            [hud hideAnimated:YES];
        }
    }
}

#pragma mark - AKLocalFilesViewControllerDelegate Methods

- (void)localFileViewController:(AKLocalFilesViewController *)localFileViewController didSelectFolderURL:(NSURL *)folderURL
{
    AKNamingViewController *namingController = [[AKNamingViewController alloc] initWithURL:nil delegate:self userInfo:folderURL];
    [self.embeddedNavigationController pushViewController:namingController animated:YES];
}

- (void)localFileViewController:(AKLocalFilesViewController *)localFileViewController didSelectDocumentURLPaths:(NSArray *)documentURLPaths
{
    // Currently only support one file, so get the first URL from the array
    NSURL *fileURL = documentURLPaths.firstObject;
    NSURL *outURL = [self.documentStorageURL URLByAppendingPathComponent:fileURL.path.lastPathComponent];
    
    if (self.documentPickerMode == UIDocumentPickerModeImport)
    {
        // Move the file into the document storage URL
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
        [coordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL *newURL) {
            NSError *copyError = nil;
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            [fileManager copyItemAtURL:newURL toURL:outURL overwritingExistingFile:YES error:&copyError];
            
            if (copyError)
            {
                AlfrescoLogError(@"Unable to copy from: %@ to: %@", newURL, outURL);
            }
            else
            {
                [DocumentPickerViewController trackEventWithAction:kAnalyticsEventActionOpen
                                                             label:[DocumentPickerViewController mimeTypeForFileExtension:outURL.absoluteString]];
            }
        }];
        
        [self dismissGrantingAccessToURL:outURL];
    }
    else if (self.documentPickerMode == UIDocumentPickerModeOpen)
    {
        NSArray *fileURLs = [self.queueStore.queue valueForKey:@"fileURL"];
        
        if (![fileURLs containsObject:outURL])
        {
            FileMetadata *metadata = [[FileMetadata alloc] initWithAccountIdentififer:self.account.identifier networkIdentifier:self.account.selectedNetworkIdentifier repositoryNode:nil fileURL:outURL sourceLocation:FileMetadataSaveLocationLocalFiles mode:self.documentPickerMode];
            [self.queueStore addObjectToQueue:metadata];
            [self.queueStore saveQueue];
        }
        
        [DocumentPickerViewController trackEventWithAction:kAnalyticsEventActionOpen
                                                     label:[DocumentPickerViewController mimeTypeForFileExtension:outURL.absoluteString]];
        [self dismissGrantingAccessToURL:outURL];
    }
}

#pragma mark - AKFavoritesListViewControllerDelegate Methods

- (void)favoritesListViewController:(AKFavoritesListViewController *)favoritesListViewController didSelectNodes:(NSArray *)selectedNodes
{
    [self handleSelectionFromController:favoritesListViewController selectedNodes:selectedNodes];
}

#pragma mark - Utility

+ (void)trackEventWithAction:(NSString *)action label:(NSString *)label
{
    [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDocumentProvider
                                                         action:action
                                                          label:label
                                                          value:@1];
}

+ (void)trackScreenWithName:(NSString *)screenName
{
    [[AnalyticsManager sharedManager] trackScreenWithName:screenName];
}

// This method is a clone of Utility class's method mimeTypeForFileExtension:
// TODO: break up Utility in smaller functional pieces (FileUtility, UIUtility and so on) and get rid of this duplicate method.
+ (NSString *)mimeTypeForFileExtension:(NSString *)extension
{
    CFStringRef pathExtension = (__bridge_retained CFStringRef)extension;
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    if (NULL != type)
    {
        CFRelease(type);
    }
    if (NULL != pathExtension)
    {
        CFRelease(pathExtension);
    }
    
    if (mimeType.length == 0)
    {
        mimeType = @"application/octet-stream";
    }
    
    /**
     * Force the mimetype to audio/mp4 it iOS determined it should be audio/x-m4a
     * Otherwise the repo applies both audio and exif aspects to the node
     */
    if ([mimeType isEqualToString:@"audio/x-m4a"])
    {
        mimeType = @"audio/mp4";
    }
    
    return mimeType;
}

@end
