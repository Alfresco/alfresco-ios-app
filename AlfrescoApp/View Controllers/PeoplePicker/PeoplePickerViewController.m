//
//  PeoplePickerViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 28/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

static NSString * const kCellReuseIdentifier = @"PersonCell";

#import "PeoplePickerViewController.h"
#import "AvatarManager.h"
#import "PersonCell.h"

@interface PeoplePickerViewController ()

@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, strong) PeoplePicker *peoplePicker;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

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
    
    self.title = NSLocalizedString(@"people.picker.title", @"Choose Assignee");
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonPressed:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    [self.searchDisplayController.searchResultsTableView setEditing:YES];
    [self.searchDisplayController.searchResultsTableView setAllowsMultipleSelectionDuringEditing:YES];
    [self.tableView setEditing:YES];
    [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    
    UIEdgeInsets edgeInset = UIEdgeInsetsMake(0.0, 0.0, kMultiSelectToolBarHeight, 0.0);
    self.searchDisplayController.searchResultsTableView.contentInset = edgeInset;
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([PersonCell class]) bundle:nil];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:kCellReuseIdentifier];
    [self.tableView registerNib:nib forCellReuseIdentifier:kCellReuseIdentifier];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.hidesBackButton = YES;
}

- (void)cancelButtonPressed:(id)sender
{
    [self.peoplePicker cancelPeoplePicker];
}

- (void)doneButtonPressed:(id)sender
{
    [self.peoplePicker pickingPeopleComplete];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    if (tableView == self.tableView)
    {
        numberOfRows = [[self.peoplePicker selectedPeople] count];
    }
    else
    {
        numberOfRows = self.searchResults.count;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PersonCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    
    AlfrescoPerson *person = nil;
    
    if (tableView == self.tableView)
    {
        person = [self.peoplePicker selectedPeople][indexPath.row];
    }
    else
    {
        person = self.searchResults[indexPath.row];
    }
    
    cell.nameLabel.text = person.fullName;
    
    AvatarManager *avatarManager = [AvatarManager sharedManager];
    
    [avatarManager retrieveAvatarForPersonIdentifier:person.identifier session:self.session completionBlock:^(UIImage *image, NSError *error) {
        
        cell.avatarImageView.image = image;
    }];
    
    if ([self.peoplePicker isPersonSelected:person])
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoPerson *person = nil;
    
    if (tableView == self.tableView)
    {
        person = [self.peoplePicker selectedPeople][indexPath.row];
    }
    else
    {
        person = self.searchResults[indexPath.row];
    }
    
    if (self.peoplePicker.peoplePickerMode == PeoplePickerModeSingleSelect)
    {
        [self.peoplePicker deselectAllPeople];
        [self.peoplePicker selectPerson:person];
        [self.peoplePicker pickingPeopleComplete];
    }
    else
    {
        [self.peoplePicker selectPerson:person];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoPerson *person = nil;
    
    if (tableView == self.tableView)
    {
        person = [self.peoplePicker selectedPeople][indexPath.row];
    }
    else
    {
        person = self.searchResults[indexPath.row];
    }
    
    [self.peoplePicker deselectPerson:person];
    [tableView reloadData];
}

#pragma mark - Search Bar Delegates

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.personService searchWithKeywords:self.searchBar.text completionBlock:^(NSArray *array, NSError *error) {
        
        if (!error)
        {
            self.searchResults = array;
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.tableView reloadData];
}

@end
