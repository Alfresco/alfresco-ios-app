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

#import "BaseLayoutAttributes.h"

@implementation BaseLayoutAttributes

- (id)copyWithZone:(NSZone *)zone
{
    BaseLayoutAttributes *newAttributes = [super copyWithZone:zone];
    if(newAttributes)
    {
        //Setting show delete button to NO to avoid showing it when attributes are copied
        //(ex: when an item that is not the last one in the list is deleted via swipe to delete)
        newAttributes.showDeleteButton = NO;
        newAttributes.editing = self.isEditing;
        newAttributes.animated = self.animated;
        newAttributes.isSelectedInEditMode = self.isSelectedInEditMode;
        newAttributes.thumbnailContentTrailingSpace = self.thumbnailContentTrailingSpace;
        newAttributes.shouldShowSmallThumbnailImage = self.shouldShowSmallThumbnailImage;
        newAttributes.shouldShowSeparatorView = self.shouldShowSeparatorView;
        newAttributes.shouldShowAccessoryView = self.shouldShowAccessoryView;
        newAttributes.shouldShowNodeDetails = self.shouldShowNodeDetails;
        newAttributes.nodeNameHorizontalDisplacement = self.nodeNameHorizontalDisplacement;
        newAttributes.nodeNameVerticalDisplacement = self.nodeNameVerticalDisplacement;
        newAttributes.folderNameNoStatusVerticalDisplacement = self.folderNameNoStatusVerticalDisplacement;
        newAttributes.folderNameWithStatusVerticalDisplacement = self.folderNameWithStatusVerticalDisplacement;
        newAttributes.shouldShowStatusViewOverImage = self.shouldShowStatusViewOverImage;
        newAttributes.nodeNameFont = self.nodeNameFont;
        newAttributes.shouldShowEditBelowContent = self.shouldShowEditBelowContent;
        newAttributes.editImageTopSpace = self.editImageTopSpace;
        newAttributes.filenameAligment = self.filenameAligment;
    }
    
    return newAttributes;
}

- (BOOL)isEqual:(id)object
{
    if([object isKindOfClass:[BaseLayoutAttributes class]])
    {
        BaseLayoutAttributes *otherAttributes = (BaseLayoutAttributes *)object;
        if((self.showDeleteButton == otherAttributes.showDeleteButton)
           && (self.isEditing == otherAttributes.isEditing)
           && (self.animated == otherAttributes.animated)
           && (self.isSelectedInEditMode == otherAttributes.isSelectedInEditMode)
           && (self.thumbnailContentTrailingSpace == otherAttributes.thumbnailContentTrailingSpace)
           && (self.shouldShowSmallThumbnailImage == otherAttributes.shouldShowSmallThumbnailImage)
           && (self.shouldShowSeparatorView == otherAttributes.shouldShowSeparatorView)
           && (self.shouldShowAccessoryView == otherAttributes.shouldShowAccessoryView)
           && (self.shouldShowNodeDetails == otherAttributes.shouldShowNodeDetails)
           && (self.nodeNameHorizontalDisplacement == otherAttributes.nodeNameHorizontalDisplacement)
           && (self.nodeNameVerticalDisplacement == otherAttributes.nodeNameVerticalDisplacement)
           && (self.folderNameNoStatusVerticalDisplacement == otherAttributes.folderNameNoStatusVerticalDisplacement)
           && (self.folderNameWithStatusVerticalDisplacement == otherAttributes.folderNameWithStatusVerticalDisplacement)
           && (self.shouldShowStatusViewOverImage == otherAttributes.shouldShowStatusViewOverImage)
           && (self.nodeNameFont == otherAttributes.nodeNameFont)
           && (self.shouldShowEditBelowContent == otherAttributes.shouldShowEditBelowContent)
           && (self.editImageTopSpace == otherAttributes.editImageTopSpace)
           && (self.filenameAligment == otherAttributes.filenameAligment))
        {
            return [super isEqual:object];
        }
    }
    return NO;
}

@end
