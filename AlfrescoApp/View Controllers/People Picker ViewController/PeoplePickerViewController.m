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
 
static NSString * const kCustomCellReuseIdentifier = @"CustomPersonCell";
static NSString * const kDefaultCellReuseIdentifier = @"DefaultPersonCell";

static NSInteger const kSearchResultsIndex = 0;

#import "PeoplePickerViewController.h"
#import "AvatarManager.h"
#import "PersonCell.h"

@interface PeoplePickerViewController ()

@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, weak) PeoplePicker *peoplePicker;
@property (nonatomic, strong) NSArray *tableViewData;
@property (nonatomic, strong) NSArray *groupHeaderTitles;
@property (nonatomic, strong) UIBarButtonItem *doneButton;

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.personService = [[AlfrescoPersonService alloc] initWithSession:self.session];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
    
    self.title = NSLocalizedString(@"people.picker.title", @"Choose Assignee");
    self.searchBar.placeholder = NSLocalizedString(@"people.picker.search.title", @"Search People");
    [self.searchBar becomeFirstResponder];
    
    if (self.peoplePicker.mode != PeoplePickerModeSingleSelectAutoConfirm)
    {
        self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                        target:self
                                                                        action:@selector(doneButtonPressed:)];
        self.doneButton.enabled = NO;
        self.navigationItem.rightBarButtonItem = self.doneButton;
    }
    
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewUserListing];
}

- (void)cancelButtonPressed:(id)sender
{
    [self.peoplePicker cancel];
}

- (void)doneButtonPressed:(id)sender
{
    [self.peoplePicker pickingPeopleComplete];
}

- (void)dealloc
{
    _tableView.delegate = nil;
    _searchBar.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        
        AvatarConfiguration *configuration = [AvatarConfiguration defaultConfigurationWithIdentifier:person.identifier session:self.session];
        configuration.ignoreCache = YES;
        [[AvatarManager sharedManager] retrieveAvatarWithConfiguration:configuration completionBlock:^(UIImage *image, NSError *error) {
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

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.peoplePicker.mode == PeoplePickerModeSingleSelectManualConfirm)
    {
        [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = self.tableViewData[indexPath.section][indexPath.row];
    
    if ([item isKindOfClass:[AlfrescoPerson class]])
    {
        AlfrescoPerson *person = (AlfrescoPerson *)item;
        if (self.peoplePicker.mode == PeoplePickerModeMultiSelect)
        {
            [self.peoplePicker selectPerson:person];
            [self updateSelectedPeopleSectionData:person];
        }
        else
        {
            [self.peoplePicker deselectAllPeople];
            [self.peoplePicker selectPerson:person];

            if (self.peoplePicker.mode == PeoplePickerModeSingleSelectAutoConfirm)
            {
                [self.peoplePicker pickingPeopleComplete];
            }
        }
    }
    
    self.doneButton.enabled = self.peoplePicker.selectedPeople.count > 0;
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

    self.doneButton.enabled = self.peoplePicker.selectedPeople.count > 0;
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

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
    self.personService = [[AlfrescoPersonService alloc] initWithSession:self.session];
}

#pragma mark - Search Bar Delegates

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:self.tableView];
    [progressHUD showAnimated:YES];
    
    [self.personService searchWithKeywords:self.searchBar.text completionBlock:^(NSArray *array, NSError *error) {
        [progressHUD hideAnimated:YES];
        
        NSMutableArray *searchResults = self.tableViewData[kSearchResultsIndex];
        [searchResults removeAllObjects];
        
        if (error || array.count == 0)
        {
            [searchResults addObject:NSLocalizedString(@"people.picker.search.no.results", @"No Search Results")];
            displayErrorMessage([ErrorDescriptions descriptionForError:error]);
            [Notifier notifyWithAlfrescoError:error];
        }
        else
        {
            [searchResults addObjectsFromArray:array];
        }
        [self.tableView reloadData];
    }];
}

@end
