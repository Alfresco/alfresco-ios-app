//
//  AlfrescoFormViewController.m
//  DynamicFormPrototype
//
//  Created by Gavin Cornwell on 14/05/2014.
//  Copyright (c) 2014 Gavin Cornwell. All rights reserved.
//

#import "AlfrescoFormViewController.h"
#import "AlfrescoFormFieldGroup.h"
#import "AlfrescoFormCell.h"
#import "AlfrescoFormDateCell.h"
#import "AlfrescoFormListOfValuesCell.h"
#import "AlfrescoFormListOfValuesConstraint.h"

@interface AlfrescoFormViewController ()
@property (nonatomic, strong, readwrite) AlfrescoForm *form;
@property (nonatomic, strong) NSMutableDictionary *cells;
@end

@implementation AlfrescoFormViewController

#pragma mark - Initialisation

- (instancetype)initWithForm:(AlfrescoForm *)form
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        self.form = form;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(evaluateDoneButtonState)
                                                 name:kAlfrescoFormFieldChangedNotification
                                               object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add done button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneButtonClicked:)];
    
    // set form title
    self.title = self.form.title;
    
    // configure form
    [self configureForm];
}

- (void)configureForm
{
    self.cells = [NSMutableDictionary dictionary];
    
    for (AlfrescoFormFieldGroup *group in self.form.groups)
    {
        for (AlfrescoFormField *field in group.fields)
        {
            AlfrescoFormCell *formCell = nil;
            
            if (field.type == AlfrescoFormFieldTypeString || field.type == AlfrescoFormFieldTypeNumber ||
                field.type == AlfrescoFormFieldTypeEmail || field.type == AlfrescoFormFieldTypeURL)
            {
                AlfrescoFormConstraint *constraint = [field constraintWithIdentifier:kAlfrescoFormConstraintListOfValues];
                if (constraint != nil)
                {
                    formCell = [[AlfrescoFormListOfValuesCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                }
                else
                {
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AlfrescoFormTextCell" owner:self options:nil];
                    formCell = [nib lastObject];
                }
            }
            else if (field.type == AlfrescoFormFieldTypeBoolean)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"AlfrescoFormBooleanCell" owner:self options:nil];
                formCell = [nib lastObject];
            }
            else if (field.type == AlfrescoFormFieldTypeDate || field.type == AlfrescoFormFieldTypeDateTime)
            {
                formCell = [[AlfrescoFormDateCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
            }
            else if (field.type == AlfrescoFormFieldTypeCustom)
            {
                // temporarily create a basic cell to show the label and value
                formCell = [[AlfrescoFormCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                formCell.label = ((UITableViewCell*)formCell).textLabel;
                ((UITableViewCell*)formCell).detailTextLabel.text = [field.value description];
            }
            else
            {
                // throw exeception if we can't handle the field
                @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                               reason:[NSString stringWithFormat:@"%@ field has an unrecognised type", field.identifier] userInfo:nil];
            }
            
            // finish common configuration of the cell and store it
            formCell.field = field;
            self.cells[field.identifier] = formCell;
        }
    }
    
    // set the state of the done button
    [self evaluateDoneButtonState];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections, will equal the number of groups
    return self.form.groups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section, will be the number of fields in the group.
    AlfrescoFormFieldGroup *group = self.form.groups[section];
    return group.fields.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self formCellForInexPath:indexPath];
}

#pragma mark - Table view delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    AlfrescoFormFieldGroup *group = self.form.groups[section];
    return group.label;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    AlfrescoFormFieldGroup *group = self.form.groups[section];
    return group.summary;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoFormCell *formCell = [self formCellForInexPath:indexPath];
    
    if (formCell.isSelectable)
    {
        return indexPath;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoFormCell *formCell = [self formCellForInexPath:indexPath];
    [formCell didSelectCellWithNavigationController:self.navigationController];
}

#pragma mark - Event handlers

- (void)doneButtonClicked:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(formViewController:didEndEditingOfForm:)])
    {
        [self.delegate formViewController:self didEndEditingOfForm:self.form];
    }
}

- (void)evaluateDoneButtonState
{
    BOOL isFormValid = self.form.valid;
    
    if (isFormValid && [self.delegate respondsToSelector:@selector(formViewController:canPersistForm:)])
    {
        isFormValid = [self.delegate formViewController:self canPersistForm:self.form];
    }
    
    // if form is not valid disable the done button
    self.navigationItem.rightBarButtonItem.enabled = isFormValid;
}

#pragma mark - Helper methods

- (AlfrescoFormCell *)formCellForInexPath:(NSIndexPath *)indexPath
{
    AlfrescoFormFieldGroup *group = self.form.groups[indexPath.section];
    AlfrescoFormField *field = group.fields[indexPath.row];
    return self.cells[field.identifier];
}

@end
