//
//  PeoplePicker.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 05/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MultiSelectActionsToolbar.h"

extern CGFloat const kMultiSelectToolBarHeight;

typedef NS_ENUM(NSInteger, PeoplePickerMode)
{
    PeoplePickerModeMultiSelect,
    PeoplePickerModeSingleSelect,
    
};

@protocol PeoplePickerDelegate <NSObject>

@optional
- (void)peoplePickerUserDidSelectPeople:(NSArray *)selectedPeople peoplePickerMode:(PeoplePickerMode)peoplePickerMode;
- (void)peoplePickerUserRemovedPerson:(AlfrescoPerson *)person peoplePickerMode:(PeoplePickerMode)peoplePickerMode;

@end

@interface PeoplePicker : NSObject <MultiSelectActionsDelegate>

@property (nonatomic, assign) PeoplePickerMode peoplePickerMode;
@property (nonatomic, weak) id<PeoplePickerDelegate> delegate;

- (instancetype)initWithSession:(id<AlfrescoSession>)session navigationController:(UINavigationController *)navigationController;
- (void)startPeoplePickerWithPeople:(NSMutableArray *)people peoplePickerMode:(PeoplePickerMode)peoplePickerMode;
- (void)cancelPeoplePicker;

- (BOOL)isPersonSelected:(AlfrescoPerson *)person;
- (void)deselectPerson:(AlfrescoPerson *)person;
- (void)deselectAllPeople;
- (void)selectPerson:(AlfrescoPerson *)person;
- (void)replaceSelectedPeopleWithPeople:(NSArray *)people;
- (NSArray *)selectedPeople;

- (void)pickingPeopleComplete;

- (void)showMultiSelectToolBar;
- (void)hideMultiSelectToolBar;

@end
