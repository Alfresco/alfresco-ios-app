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

@protocol CollectionViewMultiSelectDelegate <NSObject>

- (BOOL) isItemSelected:(NSIndexPath *) indexPath;

@end

@protocol DataSourceInformationProtocol <NSObject>

- (NSInteger) indexOfNode:(AlfrescoNode *)node;
- (BOOL) isNodeAFolderAtIndex:(NSIndexPath *)indexPath;

@end

@interface BaseCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, weak) id<CollectionViewMultiSelectDelegate> collectionViewMultiSelectDelegate;
@property (nonatomic, weak) id<DataSourceInformationProtocol> dataSourceInfoDelegate;

@property (nonatomic) NSUInteger numberOfColumns;
@property (nonatomic) CGFloat itemHeight; // an item height of -1 would result in a square cell

@property (nonatomic, strong) NSIndexPath *selectedIndexPathForSwipeToDelete;
@property (nonatomic, getter=isEditing) BOOL editing;
@property (nonatomic) BOOL shouldSwipeToDelete;
@property (nonatomic) BOOL shouldShowSmallThumbnail;

- (instancetype)initWithNumberOfColumns:(NSInteger)numberOfColumns itemHeight:(CGFloat)itemHeight shouldSwipeToDelete:(BOOL) shouldSwipeToDelete hasHeader:(BOOL)hasHeader;

- (void) selectedIndexPathForSwipeWasDeleted;

@end
