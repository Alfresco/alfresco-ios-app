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

#import "ConnectionDiagnosticViewController.h"

@interface ConnectionDiagnosticEventCell()
@property (weak, nonatomic) IBOutlet UIImageView *eventStatusImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *eventActivityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *eventText;
@end

@implementation ConnectionDiagnosticEventCell
@end

@interface ConnectionDiagnosticViewController ()
@property (weak, nonatomic) IBOutlet UITableView *mainTableView;
@property (weak, nonatomic) IBOutlet UINavigationItem *mainTitle;
@property (nonatomic, strong) NSMutableArray *tableViewDataSource;
@property (nonatomic, weak) UIViewController *parentVC;
@property (nonatomic, assign) SEL selectorToPerform;
@end

static const CGFloat kTableCellHeight = 60.f;

@implementation ConnectionDiagnosticViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableViewDataSource = [NSMutableArray new];
    self.mainTableView.delegate = self;
    self.mainTableView.dataSource = self;
    self.mainTableView.rowHeight = UITableViewAutomaticDimension;
    
    self.mainTitle.title = NSLocalizedString(@"connectiondiagnostic.title", @"Connection Diagnostic");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStartEvent:) name:kAlfrescoConfigurationDiagnosticDidStartEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEndEvent:) name:kAlfrescoConfigurationDiagnosticDidEndEventNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.parentVC && self.selectorToPerform)
    {
        if ([self.parentVC respondsToSelector:self.selectorToPerform])
        {
            [self.parentVC performSelector:self.selectorToPerform withObject:nil afterDelay:0];
        }
    }
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewAccountCreateDiagnostics];
}

- (void)dealloc
{
    _mainTableView.delegate = nil;
    _mainTableView.dataSource = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillLayoutSubviews
{
    self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.navigationController.view.frame.size.width, self.navigationController.view.frame.size.height - self.view.frame.origin.y);
}

#pragma mark - UITableViewDelegate and UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewDataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kTableCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ConnectionDiagnosticEventCell *cell = (ConnectionDiagnosticEventCell *)[tableView dequeueReusableCellWithIdentifier:@"ConnectionDiagnosticEventCell" forIndexPath:indexPath];
    
    NSDictionary *diagnostic = [self.tableViewDataSource objectAtIndex:indexPath.row];
    NSString *eventName = [diagnostic objectForKey:kAlfrescoConfigurationDiagnosticDictionaryEventName];
    cell.eventText.text = NSLocalizedString([self translationKeyForEventName:eventName], @"");
    AlfrescoConnectionDiagnosticStatus connectionStatus = [[diagnostic objectForKey:kAlfrescoConfigurationDiagnosticDictionaryStatus] integerValue];
    
    switch (connectionStatus)
    {
        case AlfrescoConnectionDiagnosticStatusLoading:
        {
            [cell.eventActivityIndicator startAnimating];
            cell.eventActivityIndicator.hidden = NO;
            cell.eventStatusImage.hidden = YES;
            break;
        }
            
        case AlfrescoConnectionDiagnosticStatusSuccess:
        {
            [cell.eventActivityIndicator stopAnimating];
            cell.eventActivityIndicator.hidden = YES;
            cell.eventStatusImage.hidden = NO;
            cell.eventStatusImage.image = [[UIImage imageNamed:@"circle_tick"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.eventStatusImage.tintColor = [UIColor systemNoticeInformationColor];
            break;
        }
            
        case AlfrescoConnectionDiagnosticStatusFailure:
        {
            [cell.eventActivityIndicator stopAnimating];
            cell.eventActivityIndicator.hidden = YES;
            cell.eventStatusImage.hidden = NO;
            cell.eventStatusImage.image = [[UIImage imageNamed:@"circle_cross"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.eventStatusImage.tintColor = [UIColor systemNoticeErrorColor];
            break;
        }
    }
    
    return cell;
}

#pragma mark - Public Methods

- (void)setupWithParent:(UIViewController *)parent andSelector:(SEL)selector
{
    self.parentVC = parent;
    self.selectorToPerform = selector;
}

#pragma mark - Notifications methods

- (void)didStartEvent:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    
    [self.tableViewDataSource addObject:userInfo];
    [self.mainTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.tableViewDataSource.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)didEndEvent:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSArray *copyOfDataSource = [self.tableViewDataSource copy];

    for (NSUInteger index = 0; index < copyOfDataSource.count; index++)
    {
        NSDictionary *dict = [copyOfDataSource objectAtIndex:index];
        if ([[userInfo objectForKey:kAlfrescoConfigurationDiagnosticDictionaryEventName] isEqualToString:[dict objectForKey:kAlfrescoConfigurationDiagnosticDictionaryEventName]])
        {
            [self.tableViewDataSource replaceObjectAtIndex:index withObject:userInfo];
            [self.mainTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}


#pragma mark - Localization method

- (NSString *)translationKeyForEventName:(NSString *)eventName
{
    static NSDictionary *eventToKeyMap;
    
    if (!eventToKeyMap)
    {
        eventToKeyMap = @{ kAlfrescoConfigurationDiagnosticReachabilityEvent : @"connectiondiagnostic.event.reachability",
                           kAlfrescoConfigurationDiagnosticServerVersionEvent : @"connectiondiagnostic.event.serverversion",
                           kAlfrescoConfigurationDiagnosticRepositoriesAvailableEvent : @"connectiondiagnostic.event.repositoriesavailable",
                           kAlfrescoConfigurationDiagnosticConnectRepositoryEvent : @"connectiondiagnostic.event.connectrepository",
                           kAlfrescoConfigurationDiagnosticRetrieveRootFolderEvent : @"connectiondiagnostic.event.retrieverootfolder"
                           };
    }

    NSString *translationKey = nil;

    if (eventName)
    {
        translationKey = eventToKeyMap[eventName];
    }
    
    return translationKey;
}

@end
