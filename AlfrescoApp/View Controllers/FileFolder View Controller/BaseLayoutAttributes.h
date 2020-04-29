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

@interface BaseLayoutAttributes : UICollectionViewLayoutAttributes

@property (nonatomic) BOOL showDeleteButton;
@property (nonatomic, getter=isEditing) BOOL editing;
@property (nonatomic) BOOL animated;
@property (nonatomic) BOOL isSelectedInEditMode;

@property (nonatomic) CGFloat thumbnailContentTrailingSpace;
@property (nonatomic) BOOL shouldShowSmallThumbnailImage;
@property (nonatomic) BOOL shouldShowSeparatorView;
@property (nonatomic) BOOL shouldShowAccessoryView;
@property (nonatomic) BOOL shouldShowNodeDetails;
@property (nonatomic) CGFloat nodeNameHorizontalDisplacement;
@property (nonatomic) CGFloat nodeNameVerticalDisplacement;
@property (nonatomic) CGFloat folderNameNoStatusVerticalDisplacement;
@property (nonatomic) CGFloat folderNameWithStatusVerticalDisplacement;
@property (nonatomic) BOOL shouldShowStatusViewOverImage;

@property (nonatomic, strong) UIFont *nodeNameFont;

@property (nonatomic) BOOL shouldShowEditBelowContent;
@property (nonatomic) CGFloat editImageTopSpace;
@property (nonatomic) NSTextAlignment filenameAligment;

@end
