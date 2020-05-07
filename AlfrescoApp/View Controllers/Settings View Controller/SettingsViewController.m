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
 
#import "SettingsViewController.h"
#import "PreferenceManager.h"
#import "SettingToggleCell.h"
#import "SettingTextFieldCell.h"
#import "SettingLabelCell.h"
#import "AboutViewController.h"
#import "AccountManager.h"
#import "SettingButtonCell.h"
#import <MessageUI/MessageUI.h>
#import <sys/utsname.h>
#import "PinViewController.h"
#import "UniversalDevice.h"
#import "SecurityManager.h"
#import "TouchIDManager.h"
#import "KeychainUtils.h"

@interface SettingsViewController () <SettingsCellProtocol, MFMailComposeViewControllerDelegate>
@end

@implementation SettingsViewController

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // create and configure the table view
    self.tableView = [[ALFTableView alloc] initWithFrame:view.frame style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, kCellLeftInset, 0, 0);
    [view addSubview:self.tableView];
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.allowsPullToRefresh = NO;
    
    if (self.settingsType == SettingsTypeGeneral)
    {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                    target:self
                                                                                    action:@selector(doneButtonPressed:)];
        self.navigationItem.rightBarButtonItem = doneButton;
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferenceDidChange:) name:kSettingsDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appReseted:) name:kAppResetedNotification object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self buildTableDataSource];
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.settingsType == SettingsTypeGeneral)
    {
        [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewSettingsDetails];
    }
}

#pragma mark - Private Functions

- (void) buildTableDataSource
{
    NSString *pListPath = [[NSBundle mainBundle] pathForResource:@"UserPreferences" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:pListPath];
    
    switch (self.settingsType)
    {
        case SettingsTypeGeneral:
            self.title = NSLocalizedString([dictionary objectForKey:kSettingsLocalizedTitleKey], @"Settings Title");
            self.tableViewData = [self filteredPreferences:[dictionary objectForKey:kSettingsTableViewData]];
            break;
            
        case SettingsTypePasscode:
            self.title = NSLocalizedString([dictionary objectForKey:kSettingsPasscodeLockLocalizedTitleKey], @"Passcode Settings Title");
            self.tableViewData = [self filteredPreferences:[dictionary objectForKey:kSettingsPasscodeLockTableViewData]];
            break;
            
        default:
            break;
    }
}

- (NSMutableArray *)filteredPreferences:(NSMutableArray *)unfilteredPreferences
{
    NSMutableArray *filteredPreferences = unfilteredPreferences;
    
    if (self.settingsType == SettingsTypeGeneral)
    {
        // Remove Enterprise-only preferences
        BOOL hasPaidAccounts = [[AccountManager sharedManager] numberOfPaidAccounts] > 0;
        if (!hasPaidAccounts)
        {
            filteredPreferences = [self removePreferences:filteredPreferences withRestriction:kSettingsRestrictionHasPaidAccount];
        }
        
        // Remove Feedback option if no email capability
        BOOL canSendMail = [MFMailComposeViewController canSendMail];
        if (!canSendMail)
        {
            filteredPreferences = [self removePreferences:filteredPreferences withRestriction:kSettingsRestrictionCanSendEmail];
        }
    }
    else if (self.settingsType == SettingsTypePasscode)
    {
        BOOL shouldUsePasscodeLock = [[PreferenceManager sharedManager] shouldUsePasscodeLock];
        BOOL isTouchIDAvailable = [TouchIDManager isTouchIDAvailable];
        
        if (!shouldUsePasscodeLock || !isTouchIDAvailable)
        {
            filteredPreferences = [self removePreferences:filteredPreferences withRestriction:kSettingsRestrictionCanUseTouchID];
        }
    }
    
    return filteredPreferences;
}

- (NSMutableArray *)removePreferences:(NSMutableArray *)preferences withRestriction:(NSString *)restriction
{
    // Filter the groups first
    NSMutableArray *filteredPreferences = [NSMutableArray array];
    
    for (NSDictionary *unfilteredGroup in preferences)
    {
        NSMutableDictionary *filteredGroup = [unfilteredGroup mutableCopy];
        NSNumber *groupValue = [filteredGroup objectForKey:restriction];
        if (groupValue == nil || ![groupValue boolValue])
        {
            // Now filter the items
            NSMutableArray *filteredItems = [NSMutableArray array];
            for (NSDictionary *item in filteredGroup[kSettingsGroupCells])
            {
                NSNumber *itemValue = [item objectForKey:restriction];
                if (itemValue == nil || ![itemValue boolValue])
                {
                    [filteredItems addObject:item];
                }
            }
            if (filteredItems.count > 0)
            {
                filteredGroup[kSettingsGroupCells] = filteredItems;
                [filteredPreferences addObject:filteredGroup];
            }
        }
    }
    
    return filteredPreferences;
}

- (void)doneButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:self.dismissCompletionBlock];
}

- (Class)determineTableViewCellClassFromCellInfo:(NSDictionary *)cellInfo
{
    NSString *cellPreferenceType = [cellInfo objectForKey:kSettingsCellType];
    
    Class returnClass;
    
    if ([cellPreferenceType isEqualToString:kSettingsToggleCell])
    {
        returnClass = [SettingToggleCell class];
    }
    else if ([cellPreferenceType isEqualToString:kSettingsTextFieldCell])
    {
        returnClass = [SettingTextFieldCell class];
    }
    else if ([cellPreferenceType isEqualToString:kSettingsLabelCell])
    {
        returnClass = [SettingLabelCell class];
    }
    else if ([cellPreferenceType isEqualToString:kSettingsButtonCell])
    {
        returnClass = [SettingButtonCell class];
    }
    
    return returnClass;
}

- (NSString *)determineCellReuseIdentifierFromCellInfo:(NSDictionary *)cellInfo
{
    NSString *cellPreferenceType = [cellInfo objectForKey:kSettingsCellType];
    
    NSString *reuseIdentifier = nil;
    
    if ([cellPreferenceType isEqualToString:kSettingsToggleCell])
    {
        reuseIdentifier = kSettingsToggleCellReuseIdentifier;
    }
    else if ([cellPreferenceType isEqualToString:kSettingsTextFieldCell])
    {
        reuseIdentifier = kSettingsTextFieldCellReuseIdentifier;
    }
    else if ([cellPreferenceType isEqualToString:kSettingsLabelCell])
    {
        reuseIdentifier = kSettingsLabelCellReuseIdentifier;
    }
    else if ([cellPreferenceType isEqualToString:kSettingsButtonCell])
    {
        reuseIdentifier = kSettingsButtonCellReuseIdentifier;
    }
    
    return reuseIdentifier;
}

- (void)handleActionWithPreferenceIdentifier:(NSString *)preferenceIdentifier
{
    if ([preferenceIdentifier isEqualToString:kSettingsResetAccountsIdentifier])
    {
        [self resetAccountsHandler];
    }
    else if ([preferenceIdentifier isEqualToString:kSettingsResetEntireAppIdentifier])
    {
        [self resetEntireAppHandler];
    }
    else if ([preferenceIdentifier isEqualToString:kSettingsSendFeedbackIdentifier])
    {
        [self sendFeedbackHandler];
    }
    else if ([preferenceIdentifier isEqualToString:kSettingsSecurityUsePasscodeLockIdentifier])
    {
        [self enableOrDisablePasscodeHandler];
    }
    else if ([preferenceIdentifier isEqualToString:kSettingsChangePasscodeIdentifier])
    {
        [self changePasscodeHandler];
    }
}

- (void)resetAccountsHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"settings.reset.accounts.confirmation.title", @"Clear Accounts")
                                                                             message:NSLocalizedString(@"settings.reset.accounts.confirmation.message", @"Clear Accounts Message")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No")
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil];
    [alertController addAction:noAction];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          [self reloadDataAfterResetWithType:ResetTypeAccounts];
                                                      }];
    [alertController addAction:yesAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)resetEntireAppHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"settings.reset.confirmation.title", @"Clear Accounts, Cache and Downloads Title")
                                                                             message:NSLocalizedString(@"settings.reset.entire.app.confirmation.message", @"Clear Accounts, Cache and Downloads Message")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No")
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil];
    [alertController addAction:noAction];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes")
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * _Nonnull action) {
                                                          [self reloadDataAfterResetWithType:ResetTypeEntireApp];
                                                      }];
    [alertController addAction:yesAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)reloadDataAfterResetWithType:(ResetType)resetType
{
    __weak typeof(self) weakSelf = self;
    
    void (^reloadDataBlock)(BOOL) = ^(BOOL reset){
        if (reset)
        {
            [SecurityManager resetWithType:resetType];
        }
        
        [weakSelf buildTableDataSource];
        [weakSelf.tableView reloadData];
    };
    
    if ([[PreferenceManager sharedManager] shouldUsePasscodeLock])
    {
        UINavigationController *navController = [PinViewController pinNavigationViewControllerWithFlow:PinFlowVerify completionBlock:^(PinFlowCompletionStatus status){
            if (status == PinFlowCompletionStatusSuccess)
            {
                reloadDataBlock(YES);
            }
            else if (status == PinFlowCompletionStatusReset)
            {
                reloadDataBlock(NO);
            }
        }];
        [weakSelf presentViewController:navController animated:YES completion:nil];
        
        if ([TouchIDManager shouldUseTouchID])
        {
            [TouchIDManager evaluatePolicyWithCompletionBlock:^(BOOL success, NSError *authenticationError){
                if (success)
                {
                    [navController dismissViewControllerAnimated:NO completion:nil];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        reloadDataBlock(YES);
                    });
                }
            }];
        }
    }
    else
    {
        reloadDataBlock(YES);
    }
}

- (void)sendFeedbackHandler
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *emailController = [[MFMailComposeViewController alloc] init];
        emailController.mailComposeDelegate = self;
        [emailController setSubject:[self emailFeedbackSubject]];
        [emailController setToRecipients:@[kSettingsSendFeedbackAlfrescoRecipient]];
        
        // Content body template
        NSString *footer = [self emailFeedbackFooter];
        NSString *messageBody = [NSString stringWithFormat:@"<br><br>%@", footer];
        [emailController setMessageBody:messageBody isHTML:YES];
        emailController.modalPresentationStyle = UIModalPresentationPageSheet;
        
        [self presentViewController:emailController animated:YES completion:nil];
    }
    else
    {
        displayErrorMessageWithTitle(NSLocalizedString(@"error.no.email.accounts.message", @"No mail accounts"), NSLocalizedString(@"error.no.email.accounts.title", @"No mail accounts"));
    }
}

- (void)enableOrDisablePasscodeHandler
{
    BOOL shouldUsePasscodeLock = [[PreferenceManager sharedManager] shouldUsePasscodeLock];
    shouldUsePasscodeLock = !shouldUsePasscodeLock;
    UINavigationController *pinNavigationViewController;
    
    if (shouldUsePasscodeLock)
    {
        __weak typeof(self) weakSelf = self;
        pinNavigationViewController = [PinViewController pinNavigationViewControllerWithFlow:PinFlowSet completionBlock:^(PinFlowCompletionStatus status){
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf notifyFileProviderAboutUpdates];
            
            if (status == PinFlowCompletionStatusSuccess)
            {
                [[PreferenceManager sharedManager] updatePreferenceToValue:@(YES) preferenceIdentifier:kSettingsSecurityUsePasscodeLockIdentifier];
            }
        }];
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        pinNavigationViewController = [PinViewController pinNavigationViewControllerWithFlow:PinFlowUnset completionBlock:^(PinFlowCompletionStatus status)
        {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf notifyFileProviderAboutUpdates];
            
            switch (status)
            {
                case PinFlowCompletionStatusSuccess:
                {
                    [[PreferenceManager sharedManager] updatePreferenceToValue:@(NO) preferenceIdentifier:kSettingsSecurityUsePasscodeLockIdentifier];
                }
                    break;
                case PinFlowCompletionStatusReset:
                {
                    [[PreferenceManager sharedManager] updatePreferenceToValue:@(NO) preferenceIdentifier:kSettingsSecurityUsePasscodeLockIdentifier];
                    [SecurityManager resetWithType:ResetTypeEntireApp];
                }
                    break;
                    
                default:
                    break;
            }
        }];
    }
    
    [self presentViewController:pinNavigationViewController animated:YES completion:nil];
}

- (void)changePasscodeHandler
{
    __weak typeof(self) weakSelf = self;
    UINavigationController *pinNavigationViewController = [PinViewController pinNavigationViewControllerWithFlow:PinFlowChange completionBlock:^(PinFlowCompletionStatus status){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf notifyFileProviderAboutUpdates];
        
        switch (status) {
            case PinFlowCompletionStatusSuccess:
            {
                [[PreferenceManager sharedManager] updatePreferenceToValue:@(YES) preferenceIdentifier:kSettingsSecurityUsePasscodeLockIdentifier];
            }
                break;
            case PinFlowCompletionStatusReset:
            {
                [SecurityManager resetWithType:ResetTypeEntireApp];
            }
                break;
                
            default:
                break;
        }
    }];
    [self presentViewController:pinNavigationViewController animated:YES completion:nil];
}

- (void)notifyFileProviderAboutUpdates {
    if (@available(iOS 11.0, *)) {
        NSError *error = nil;
        NSString *itemIdentifier = [KeychainUtils retrieveItemForKey:kFileProviderCurrentItemIdentifier
                                                             inGroup:kSharedAppGroupIdentifier
                                                               error:&error];
        
        if (error) {
            AlfrescoLogError(@"An error occured while retrieving the current file provider item identifier. Reason:%@", error.localizedDescription);
        } else {
            [[NSFileProviderManager defaultManager] signalEnumeratorForContainerItemIdentifier:itemIdentifier
                                                                             completionHandler:^(NSError * _Nullable error) {}];
        }
        
        [[NSFileProviderManager defaultManager] signalEnumeratorForContainerItemIdentifier:NSFileProviderRootContainerItemIdentifier
                                                                         completionHandler:^(NSError * _Nullable error) {}];
    }
}

- (BOOL)cellEnabled:(SettingCell *)cell
{
    if ([cell.preferenceIdentifier isEqualToString:kSettingsSendDiagnosticsIdentifier])
    {
        return [[PreferenceManager sharedManager] isSendDiagnosticsEnable];
    }
    else if ([cell.preferenceIdentifier isEqualToString:kSettingsChangePasscodeIdentifier])
    {
        return [[PreferenceManager sharedManager] shouldUsePasscodeLock];
    }
    
    return YES;
}


#pragma mark - Feedback Utils

- (NSString *)emailFeedbackSubject
{
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *subjectString = [NSString stringWithFormat:@"iOS App v%@ Feedback", versionString];
    
    return subjectString;
}

- (NSString *)emailFeedbackFooter
{
    NSString *footerString = [NSString stringWithFormat: @"------<br>App: %@ %@ (%@)<br>Device: %@ (%@)<br>Locale: %@",
                              [self bundleIdentifier],
                              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                              [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                              [self deviceModel],
                              [self operatingSystemVersion],
                              [self localeIdentifier]];
    
    return footerString;
}

- (NSString *)deviceModel
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *code = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    return code;
}

- (NSString *)bundleIdentifier
{
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (NSString *)operatingSystemVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString *)localeIdentifier
{
    return [NSLocale currentLocale].localeIdentifier;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableViewData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.tableViewData objectAtIndex:section] objectForKey:kSettingsGroupCells] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *groupInfoDictionary = [self.tableViewData objectAtIndex:section];
    NSString *groupHeaderTitle = [groupInfoDictionary objectForKey:kSettingsGroupHeaderLocalizedKey];
    
    return NSLocalizedString(groupHeaderTitle, @"Section header title");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSDictionary *groupInfoDictionary = [self.tableViewData objectAtIndex:section];
    NSString *groupFooterTitle = [groupInfoDictionary objectForKey:kSettingsGroupFooterLocalizedKey];
    
    // TODO: Find a cleaner way to replace this section footer
    if ([groupFooterTitle isEqualToString:@"settings.security.passcode.lock.description"])
    {
        return [NSString stringWithFormat:NSLocalizedString(groupFooterTitle, @"Section footer title"), REMAINING_ATTEMPTS_MAX_VALUE];
    }
    else if ([groupFooterTitle isEqualToString:@"settings.send.diagnostics.description"])
    {
        if (![[PreferenceManager sharedManager] isSendDiagnosticsEnable])
        {
            groupFooterTitle = @"accountdetails.footer.main.menu.config.disabled";
        }
    }
    
    return NSLocalizedString(groupFooterTitle, @"Section footer title");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *groupInfoDictionary = [self.tableViewData objectAtIndex:indexPath.section];
    NSArray *groupCellsArray = [groupInfoDictionary objectForKey:kSettingsGroupCells];
    NSDictionary *currentCellInfo = [groupCellsArray objectAtIndex:indexPath.row];
    
    NSString *CellIdentifier = [self determineCellReuseIdentifierFromCellInfo:currentCellInfo];
    Class CellClass = [self determineTableViewCellClassFromCellInfo:currentCellInfo];
    
    SettingCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
    {
        cell = (SettingCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(CellClass) owner:self options:nil] lastObject];
        cell.delegate = self;
    }
    
    id preferenceValue = [[PreferenceManager sharedManager] preferenceForIdentifier:[currentCellInfo valueForKey:kSettingsCellPreferenceIdentifier]];
    
    [cell updateCellForCellInfo:currentCellInfo value:preferenceValue delegate:self];
    cell.enabled = [self cellEnabled:cell];
    
    return cell;
}

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingCell *cell = (SettingCell *)[tableView cellForRowAtIndexPath:indexPath];
    return cell.enabled;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SettingCell *cell = (SettingCell *)[tableView cellForRowAtIndexPath:indexPath];
    if ([cell.preferenceIdentifier isEqualToString:kSettingsAboutIdentifier])
    {
        AboutViewController *aboutViewController = [[AboutViewController alloc] init];
        [self.navigationController pushViewController:aboutViewController animated:YES];
    }
    else if ([cell.preferenceIdentifier isEqualToString:kSettingsPasscodeLockIdentifier])
    {
        SettingsViewController *passcodeSettingsViewController = [[SettingsViewController alloc] initWithSession:self.session];
        passcodeSettingsViewController.settingsType = SettingsTypePasscode;
        [self.navigationController pushViewController:passcodeSettingsViewController animated:YES];
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Notifications Handlers

- (void)preferenceDidChange:(NSNotification *)notification
{
    NSString *preferenceKeyChanged = notification.object;
    
    if ([preferenceKeyChanged isEqualToString:kSettingsSecurityUsePasscodeLockIdentifier])
    {
        [self buildTableDataSource];
        [self.tableView reloadData];
    }
}

- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification
{
    [self buildTableDataSource];
    [self.tableView reloadData];
}

- (void)appReseted:(NSNotification *)notification
{
    if (self.settingsType == SettingsTypePasscode)
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - SettingsCellProtocol Functions

- (void)valueDidChangeForCell:(SettingCell *)cell preferenceIdentifier:(NSString *)preferenceIdentifier value:(id)value
{
    // If it's an action cell that requires action, else, update the preferences
    if ([cell isKindOfClass:[SettingButtonCell class]])
    {
        [self handleActionWithPreferenceIdentifier:preferenceIdentifier];
    }
    else
    {
        [[PreferenceManager sharedManager] updatePreferenceToValue:value preferenceIdentifier:preferenceIdentifier];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate Methods

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    void (^completionBlock)(void) = nil;
    
    if (result == MFMailComposeResultFailed)
    {
        completionBlock = ^{
            displayErrorMessageWithTitle(NSLocalizedString(@"error.person.profile.email.failed.message", @"Email Failed Message"), NSLocalizedString(@"error.person.profile.email.failed.title", @"Sending Failed Title"));
        };
    }
    
    [controller dismissViewControllerAnimated:YES completion:completionBlock];
}

@end
