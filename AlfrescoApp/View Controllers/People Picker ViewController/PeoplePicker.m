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
 
#import "PeoplePicker.h"
#import "PeoplePickerViewController.h"
#import "NavigationViewController.h"

@interface PeoplePicker()

@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UINavigationController *peoplePickerNavigationController;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) MultiSelectContainerView *multiSelectContainerView;
@property (nonatomic, strong) NSMutableArray *peopleAlreadySelected;
@property (nonatomic, strong) PeoplePickerViewController *peoplePickerViewController;
@property (nonatomic, assign) BOOL isMultiSelectToolBarVisible;

@end

@implementation PeoplePicker

- (instancetype)initWithSession:(id<AlfrescoSession>)session navigationController:(UINavigationController *)navigationController
{
    return [self initWithSession:session navigationController:navigationController delegate:nil];
}

- (instancetype)initWithSession:(id<AlfrescoSession>)session navigationController:(UINavigationController *)navigationController delegate:(id<PeoplePickerDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        _session = session;
        _navigationController = navigationController;
        _delegate = delegate;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
}

- (void)startWithPeople:(NSArray *)people mode:(PeoplePickerMode)mode modally:(BOOL)modally;
{
    self.mode = mode;
    self.peopleAlreadySelected = [people mutableCopy];
    
    if (!self.multiSelectContainerView)
    {
        self.multiSelectContainerView = [[MultiSelectContainerView alloc] initWithFrame:CGRectZero];
        self.multiSelectContainerView.toolbar.multiSelectDelegate = self;
    }
    
    [self.multiSelectContainerView show];
    [self replaceSelectedPeopleWithPeople:self.peopleAlreadySelected];
    
    self.peoplePickerViewController = [[PeoplePickerViewController alloc] initWithSession:self.session peoplePicker:self];
    if (modally)
    {
        NavigationViewController *modalNavigationController = [[NavigationViewController alloc] initWithRootViewController:self.peoplePickerViewController];
        modalNavigationController.modalPresentationStyle = UIModalPresentationPageSheet;
        [self.navigationController presentViewController:modalNavigationController animated:YES completion:nil];
        self.peoplePickerNavigationController = modalNavigationController;
    }
    else
    {
        [self.navigationController pushViewController:self.peoplePickerViewController animated:YES];
        self.peoplePickerNavigationController = self.navigationController;
    }
}

- (void)cancel
{
    [self cancelWithCompletionBlock:nil];
}

- (void)cancelWithCompletionBlock:(PeoplePickerDismissedCompletionBlock)completionBlock
{
    if (self.peoplePickerNavigationController.viewControllers.firstObject == self.peoplePickerViewController)
    {
        [self.peoplePickerViewController dismissViewControllerAnimated:YES completion:^{
            self.peoplePickerNavigationController = nil;
            if (completionBlock)
            {
                completionBlock(self);
            }
        }];
    }
    else
    {
        // pop to view controller just before Picker contollers
        NSInteger nextViewControllerIndex = [self.navigationController.viewControllers indexOfObject:self.peoplePickerViewController];
        NSInteger previousControllerIndex = nextViewControllerIndex > 0 ? (nextViewControllerIndex - 1) : NSNotFound;
        
        if (previousControllerIndex != NSNotFound)
        {
            UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:previousControllerIndex];
            [self.navigationController popToViewController:previousViewController animated:YES];
        }
    }
}

- (BOOL)isPersonSelected:(AlfrescoPerson *)person
{
    __block BOOL isSelected = NO;
    [self.multiSelectContainerView.toolbar.selectedItems enumerateObjectsUsingBlock:^(AlfrescoPerson *selectedPerson, NSUInteger index, BOOL *stop) {
        
        if ([person.identifier isEqualToString:selectedPerson.identifier])
        {
            isSelected = YES;
            *stop = YES;
        }
    }];
    return isSelected;
}

- (void)deselectPerson:(AlfrescoPerson *)person
{
    __block id existingPerson = nil;
    [self.multiSelectContainerView.toolbar.selectedItems enumerateObjectsUsingBlock:^(AlfrescoPerson *selectedPerson, NSUInteger index, BOOL *stop) {
        
        if ([person.identifier isEqualToString:selectedPerson.identifier])
        {
            existingPerson = selectedPerson;
            *stop = YES;
        }
    }];
    [self.multiSelectContainerView.toolbar userDidDeselectItem:existingPerson];
}

- (void)deselectAllPeople
{
    [self.multiSelectContainerView.toolbar userDidDeselectAllItems];
}

- (void)selectPerson:(AlfrescoPerson *)person
{
    __block BOOL personExists = NO;
    [self.multiSelectContainerView.toolbar.selectedItems enumerateObjectsUsingBlock:^(AlfrescoPerson *selectedPerson, NSUInteger index, BOOL *stop) {
        
        if ([person.identifier isEqualToString:selectedPerson.identifier])
        {
            personExists = YES;
            *stop = YES;
        }
    }];
    
    if (!personExists)
    {
        [self.multiSelectContainerView.toolbar userDidSelectItem:person];
    }
}

- (void)replaceSelectedPeopleWithPeople:(NSArray *)people
{
    [self.multiSelectContainerView.toolbar replaceSelectedItemsWithItems:people];
}

- (NSArray *)selectedPeople
{
    return self.multiSelectContainerView.toolbar.selectedItems;
}

- (void)showMultiSelectToolBar
{
    if (!self.isMultiSelectToolBarVisible)
    {
        [self.navigationController.view addSubview:self.multiSelectContainerView];
        self.isMultiSelectToolBarVisible = YES;
    }
}

- (void)hideMultiSelectToolBar
{
    if (self.isMultiSelectToolBarVisible)
    {
        [self.multiSelectContainerView removeFromSuperview];
        self.isMultiSelectToolBarVisible = NO;
    }
}

- (void)pickingPeopleComplete
{
    if (!self.shouldSuppressAutoCloseWhenDone)
    {
        [self cancel];
    }
    
    if ([self.delegate respondsToSelector:@selector(peoplePicker:didSelectPeople:)])
    {
        [self.delegate peoplePicker:self didSelectPeople:self.multiSelectContainerView.toolbar.selectedItems];
    }
}

@end
