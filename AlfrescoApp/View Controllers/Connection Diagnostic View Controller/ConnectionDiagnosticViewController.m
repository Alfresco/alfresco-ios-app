//
//  ConnectionDiagnosticViewController.m
//  AlfrescoApp
//
//  Created by Silviu Odobescu on 19/03/15.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import "ConnectionDiagnosticViewController.h"
#import "Constants.h"

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

@implementation ConnectionDiagnosticViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.tableViewDataSource = [NSMutableArray new];
    self.mainTableView.delegate = self;
    self.mainTableView.dataSource = self;
    self.mainTableView.rowHeight = UITableViewAutomaticDimension;
    
    self.mainTitle.title = @"Connection Diagnostic";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStartEvent:) name:kAlfrescoConfigurationDiagnosticDidStartEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEndEvent:) name:kAlfrescoConfigurationDiagnosticDidEndEventNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    if(self.parentVC && self.selectorToPerform)
    {
        if([self.parentVC respondsToSelector:self.selectorToPerform])
        {
            [self.parentVC performSelector:self.selectorToPerform withObject:nil afterDelay:0];
        }
    }
    [super viewWillAppear:animated];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
    return 40;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ConnectionDiagnosticEventCell *cell = (ConnectionDiagnosticEventCell *)[tableView dequeueReusableCellWithIdentifier:@"ConnectionDiagnosticEventCell" forIndexPath:indexPath];
    
    NSDictionary *dict = [self.tableViewDataSource objectAtIndex:indexPath.row];
    NSString *eventName = [dict objectForKey:kAlfrescoConfigurationDiagnosticDictionaryEventName];
    cell.eventText.text = NSLocalizedString([self translationKeyForEventName:eventName], @"");
    if([[dict objectForKey:kAlfrescoConfigurationDiagnosticDictionaryIsLoading] boolValue])
    {
        [cell.eventActivityIndicator startAnimating];
        cell.eventActivityIndicator.hidden = NO;
        cell.eventStatusImage.hidden = YES;
    }
    else
    {
        [cell.eventActivityIndicator stopAnimating];
        cell.eventActivityIndicator.hidden = YES;
        cell.eventStatusImage.hidden = NO;
        if([[dict objectForKey:kAlfrescoConfigurationDiagnosticDictionaryIsSuccess] boolValue])
        {
            cell.eventStatusImage.image = [[UIImage imageNamed:@"circle_tick"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.eventStatusImage.tintColor = [UIColor systemNoticeInformationColor];
        }
        else
        {
            cell.eventStatusImage.image = [[UIImage imageNamed:@"circle_cross"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.eventStatusImage.tintColor = [UIColor systemNoticeErrorColor];
        }
    }
    
    return cell;
}

#pragma mark - Public Methods
- (void)setupWithParrent:(UIViewController *)parent andSelector:(SEL)selector
{
    self.parentVC = parent;
    self.selectorToPerform = selector;
}

#pragma mark - Notifications methods

- (void) didStartEvent:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    
    [self.tableViewDataSource addObject:userInfo];
    [self.mainTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.tableViewDataSource.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) didEndEvent:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    
    NSArray *copyOfDataSource = [self.tableViewDataSource copy];
    for(int i = 0; i < copyOfDataSource.count; i++)
    {
        NSDictionary *dict = [copyOfDataSource objectAtIndex:i];
        if([[userInfo objectForKey:kAlfrescoConfigurationDiagnosticDictionaryEventName] isEqualToString:[dict objectForKey:kAlfrescoConfigurationDiagnosticDictionaryEventName]])
        {
            [self.tableViewDataSource replaceObjectAtIndex:i withObject:userInfo];
            [self.mainTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}


#pragma mark - Temp methods

- (NSString *) translationKeyForEventName:(NSString *)eventName
{
    NSString *stringToReturn;
    if([eventName isEqualToString:kAlfrescoConfigurationDiagnosticReachabilityEvent])
    {
        stringToReturn = @"connectiondiagnostic.reachabilityevent";
    }
    else if ([eventName isEqualToString:kAlfrescoConfigurationDiagnosticServerVersionEvent])
    {
        stringToReturn = @"connectiondiagnostic.serverversionevent";
    }
    else if ([eventName isEqualToString:kAlfrescoConfigurationDiagnosticRepositoriesAvailableEvent])
    {
        stringToReturn = @"connectiondiagnostic.repositoriesavailableevent";
    }
    else if ([eventName isEqualToString:kAlfrescoConfigurationDiagnosticConnectRepositoryEvent])
    {
        stringToReturn = @"connectiondiagnostic.connectrepositoryevent";
    }
    else if ([eventName isEqualToString:kAlfrescoConfigurationDiagnosticRetrieveRootFolderEvent])
    {
        stringToReturn = @"connectiondiagnostic.retrieverootfolderevent";
    }
    
    return stringToReturn;
}

@end
