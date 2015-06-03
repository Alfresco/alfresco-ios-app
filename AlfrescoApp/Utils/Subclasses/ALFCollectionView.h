/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

@protocol SwipeToDeleteDelegate <NSObject>

- (void) collectionView:(UICollectionView *)collectionView didSwipeToDeleteItemAtIndex:(NSIndexPath *)indexPath;

@end

@interface ALFCollectionView : UICollectionView < UIGestureRecognizerDelegate >

@property (nonatomic, strong) id<SwipeToDeleteDelegate> swipeToDeleteDelegate;

@property (nonatomic, getter=isEditing) BOOL editing;                             // default is NO. setting is not animated.
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

@property (nonatomic) BOOL isInDeleteMode;

@end
