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
  
@class ActionCollectionItem;

@protocol ActionViewDelegate <NSObject>
@optional
- (void)displayProgressIndicator;
- (void)hideProgressIndicator;
@end

@interface ActionViewHandler : NSObject

@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) id<AlfrescoSession> session;

- (instancetype)initWithAlfrescoNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session controller:(UIViewController *)controller;
- (AlfrescoRequest *)pressedLikeActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedUnlikeActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedFavouriteActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedUnfavouriteActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedEmailActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath documentLocation:(InAppDocumentLocation)location;
- (AlfrescoRequest *)pressedDownloadActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedPrintActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath documentLocation:(InAppDocumentLocation)location presentFromView:(UIView *)view inView:(UIView *)inView;
- (AlfrescoRequest *)pressedOpenInActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath documentLocation:(InAppDocumentLocation)location presentFromView:(UIView *)view inView:(UIView *)inView;
- (AlfrescoRequest *)pressedDeleteActionItem:(ActionCollectionItem *)actionItem;
- (void)pressedDeleteLocalFileActionItem:(ActionCollectionItem *)actionItem documentPath:(NSString *)documentPath;
- (AlfrescoRequest *)pressedCreateSubFolderActionItem:(ActionCollectionItem *)actionItem inFolder:(AlfrescoFolder *)folder;
- (AlfrescoRequest *)pressedEditActionItem:(ActionCollectionItem *)actionItem forDocumentWithContentPath:(NSString *)contentPath;
- (void)pressedRenameActionItem:(ActionCollectionItem *)actionItem atPath:(NSString *)path;
- (void)pressedUploadActionItem:(ActionCollectionItem *)actionItem presentFromView:(UIView *)view inView:(UIView *)inView;
- (void)pressedSendForReviewActionItem:(ActionCollectionItem *)actionItem node:(AlfrescoDocument *)document;
- (void)pressedUploadNewVersion:(ActionCollectionItem *)actionItem node:(AlfrescoDocument *)document;
- (void)pressedSyncActionItem:(ActionCollectionItem *)actionItem;
- (void)pressedUnsyncActionItem:(ActionCollectionItem *)actionItem;

@end
