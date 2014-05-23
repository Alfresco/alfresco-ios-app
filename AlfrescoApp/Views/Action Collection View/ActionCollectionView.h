//
//  ActionCollectionViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 03/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActionCollectionRow.h"
#import "ActionCollectionItem.h"

@protocol ActionCollectionViewDelegate <NSObject>

- (void)didPressActionItem:(ActionCollectionItem *)actionItem cell:(UICollectionViewCell *)cell inView:(UICollectionView *)view;

@end

@interface ActionCollectionView : UIView

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, weak) IBOutlet id<ActionCollectionViewDelegate> delegate;

- (instancetype)initWithItems:(NSArray *)items delegate:(id<ActionCollectionViewDelegate>)delegate;

@end
