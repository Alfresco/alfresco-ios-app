//
//  TagPickerViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"

@protocol TagPickerViewControllerDelegate <NSObject>

- (void)didCompleteSelectingTags:(NSArray *)selectedTags;

@end

@interface TagPickerViewController : ParentListViewController

- (id)initWithSelectedTags:(NSArray *)selectedTags session:(id<AlfrescoSession>)session delegate:(id<TagPickerViewControllerDelegate>)delegate;

@end
