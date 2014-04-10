//
//  ActionViewHandler.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 06/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ActionCollectionItem;

@protocol ActionViewDelegate <NSObject>
@optional
- (void)displayProgressIndicator;
- (void)hideProgressIndicator;
@end

@interface ActionViewHandler : NSObject

- (instancetype)initWithAlfrescoNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session controller:(UIViewController *)controller;
- (AlfrescoRequest *)pressedLikeActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedUnlikeActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedFavouriteActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedUnfavouriteActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedEmailActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedDownloadActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedPrintActionItem:(ActionCollectionItem *)actionItem presentFromView:(UIView *)view inView:(UIView *)inView;
- (AlfrescoRequest *)pressedOpenInActionItem:(ActionCollectionItem *)actionItem presentFromView:(UIView *)view inView:(UIView *)inView;
- (AlfrescoRequest *)pressedDeleteActionItem:(ActionCollectionItem *)actionItem;
- (AlfrescoRequest *)pressedCreateSubFolderActionItem:(ActionCollectionItem *)actionItem inFolder:(AlfrescoFolder *)folder;
- (AlfrescoRequest *)pressedEditActionItem:(ActionCollectionItem *)actionItem forDocumentWithContentPath:(NSString *)contentPath;
- (void)pressedRenameActionItem:(ActionCollectionItem *)actionItem atPath:(NSString *)path;
- (void)pressedUploadActionItem:(ActionCollectionItem *)actionItem presentFromView:(UIView *)view inView:(UIView *)inView;
- (void)pressedSendForReviewActionItem:(ActionCollectionItem *)actionItem node:(AlfrescoDocument *)document;

@end
