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

#import <UIKit/UIKit.h>
#import "MainMenuBuilder.h"
#import "MainMenuGroup.h"

typedef NS_ENUM(NSUInteger, MainMenuGroupType)
{
    MainMenuGroupTypeHeader,
    MainMenuGroupTypeContent,
    MainMenuGroupTypeFooter
};

@class MainMenuViewController;

@protocol MainMenuViewControllerDelegate <NSObject>

@optional
- (void)mainMenuViewController:(MainMenuViewController *)controller didDeselectItem:(MainMenuItem *)menuItem inSectionItem:(MainMenuSection *)sectionItem;

@required
- (void)mainMenuViewController:(MainMenuViewController *)controller didSelectItem:(MainMenuItem *)menuItem inSectionItem:(MainMenuSection *)sectionItem;

@end

@interface MainMenuViewController : UIViewController

@property (nonatomic, copy) NSString *title;
@property (nonatomic, weak, readonly) id<MainMenuViewControllerDelegate> delegate;

// View
@property (nonatomic, strong) UIColor *backgroundColour;
@property (nonatomic, strong) UIColor *selectionColor;

- (instancetype)initWithTitle:(NSString *)title menuBuilder:(MainMenuBuilder *)builder delegate:(id<MainMenuViewControllerDelegate>)delegate;

- (void)selectMenuItemWithIdentifier:(NSString *)identifier fallbackIdentifier:(NSString *)fallbackIdentifier;
- (void)loadGroupType:(MainMenuGroupType)groupType completionBlock:(void (^)(void))completionBlock;
- (void)reloadGroupType:(MainMenuGroupType)groupType completionBlock:(void (^)(void))completionBlock;

- (void)sectionsForGroupType:(MainMenuGroupType)groupType completionBlock:(void (^)(NSArray *sections))completionBlock;

- (void)updateMainMenuItemWithIdentifier:(NSString *)identifier withImage:(UIImage *)updateImage;
- (void)updateMainMenuItemWithIdentifier:(NSString *)identifier withAvatarImage:(UIImage *)avatarImage;
- (void)updateMainMenuItemWithIdentifier:(NSString *)identifier withText:(NSString *)updateText;
- (void)updateMainMenuItemWithIdentifier:(NSString *)identifier withDescription:(NSString *)updateDescription;
- (void)clearGroupType:(MainMenuGroupType)groupType;

- (void)visibilityForSectionHeadersHidden:(BOOL)hidden animated:(BOOL)animated;

- (void)cleanSelection;

@end

