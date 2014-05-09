//
//  PeoplePickerViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 28/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

static NSString * const kCustomCellReuseIdentifier = @"CustomPersonCell";
static NSString * const kDefaultCellReuseIdentifier = @"DefaultPersonCell";

static NSInteger const kSearchResultsIndex = 0;

#import "PeoplePickerViewController.h"
#import "AvatarManager.h"
#import "PersonCell.h"
#import "MBProgressHud.h"

@interface PeoplePickerViewController ()

@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, weak) PeoplePicker *peoplePicker;
@property (nonatomic, strong) NSArray *tableViewData;
@property (nonatomic, strong) NSArray *groupHeaderTitles;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

@end

@implementation PeoplePickerViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session peoplePicker:(PeoplePicker *)peoplePicker
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self)
    {
        _session = session;
        _peoplePicker = peoplePicker;
    }
    return self;
}

- (void)viewDidLoad
{
    self.personService = [[AlfrescoPersonService alloc] initWithSession:self.session];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
    [self.searchBar becomeFirstResponder];
    
    self.title = NSLocalizedString(@"people.picker.title", @"Choose Assignee");
    self.searchBar.placeholder = NSLocalizedString(@"people.picker.search.title", @"Search People");
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonPressed:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    [self.tableView setEditing:YES];
    [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    
    NSMutableArray *searchResults = [@[NSLocalizedString(@"people.picker.search.no.results", @"No Search Results")] mutableCopy];
    NSMutableArray *selectedPeople = self.peoplePicker.selectedPeople ? [self.peoplePicker.selectedPeople mutableCopy] : [NSMutableArray array];
    
    self.tableViewData = @[searchResults, selectedPeople];
    self.groupHeaderTitles = @[NSLocalizedString(@"people.picker.search.results.section.title", @"Searched Results"), NSLocalizedString(@"people.picker.selected.people.section.title", @"Selected People")];
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([PersonCell class]) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kCustomCellReuseIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kDefaultCellReuseIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.hidesBackButton = YES;
}

- (void)cancelButtonPressed:(id)sender
{
    [self.peoplePicker cancel];
}

- (void)doneButtonPressed:(id)sender
{
    [self.peoplePicker pickingPeopleComplete];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableViewData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewData[section] count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = self.tableViewData[indexPath.section][indexPath.row];
    return [item isKindOfClass:[AlfrescoPerson class]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *tableCell = nil;
    id item = self.tableViewData[indexPath.section][indexPath.row];
    
    if ([item isKindOfClass:[AlfrescoPerson class]])
    {
        PersonCell *cell = [tableView dequeueReusableCellWithIdentifier:kCustomCellReuseIdentifier];
        AlfrescoPerson *person = (AlfrescoPerson *)item;
        cell.nameLabel.text = person.fullName;
        
        AvatarManager *avatarManager = [AvatarManager sharedManager];
        
        [avatarManager retrieveAvatarForPersonIdentifier:person.identifier session:self.session completionBlock:^(UIImage *image, NSError *error) {
            cell.avatarImageView.image = image;
        }];
        
        if ([self.peoplePicker isPersonSelected:person])
        {
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        tableCell = cell;
    }
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDefaultCellReuseIdentifier forIndexPath:indexPath];
        cell.textLabel.text = item;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        tableCell = cell;
    }
    
    return tableCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = self.tableViewData[indexPath.section][indexPath.row];
    
    if ([item isKindOfClass:[AlfrescoPerson class]])
    {
        AlfrescoPerson *person = (AlfrescoPerson *)item;
        if (self.peoplePicker.mode == PeoplePickerModeSingleSelect)
        {
            [self.peoplePicker deselectAllPeople];
            [self.peoplePicker selectPerson:person];
            [self.peoplePicker pickingPeopleComplete];
        }
        else
        {
            [self.peoplePicker selectPerson:person];
            [self updateSelectedPeopleSectionData:person];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = self.tableViewData[indexPath.section][indexPath.row];
    
    if ([item isKindOfClass:[AlfrescoPerson class]])
    {
        AlfrescoPerson *person = (AlfrescoPerson *)item;
        [self.peoplePicker deselectPerson:person];
        [tableView reloadData];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = nil;
    
    if ([self.tableViewData[section] count] != 0)
    {
        headerTitle = self.groupHeaderTitles[section];
    }
    return headerTitle;
}

#pragma mark - Private Methods

- (void)updateSelectedPeopleSectionData:(AlfrescoPerson *)selectedPerson
{
    NSMutableArray *selectedPeople = self.tableViewData.lastObject;
    
    __block BOOL personExists = NO;
    [selectedPeople enumerateObjectsUsingBlock:^(AlfrescoPerson *person, NSUInteger index, BOOL *stop) {
        if ([person.identifier isEqualToString:selectedPerson.identifier])
        {
            personExists = YES;
            *stop = YES;
        }
    }];
    
    if (!personExists)
    {
        [selectedPeople addObject:selectedPerson];
    }
    [self.tableView reloadData];
}

#pragma mark - Search Bar Delegates

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:self.tableView];
    [progressHUD show:YES];
    
    [self.personService searchWithKeywords:self.searchBar.text completionBlock:^(NSArray *array, NSError *error) {
        [progressHUD hide:YES];
        
        NSMutableArray *searchResults = self.tableViewData[kSearchResultsIndex];
        [searchResults removeAllObjects];
        
        if (error || array.count == 0)
        {
            [searchResults addObject:NSLocalizedString(@"people.picker.search.no.results", @"No Search Results")];
        }
        else
        {
            [searchResults addObjectsFromArray:array];
        }
        [self.tableView reloadData];
    }];
}

@end
