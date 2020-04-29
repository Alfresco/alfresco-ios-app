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
  
#import <MessageUI/MessageUI.h>

#import "PagedScrollView.h"
#import "ActionCollectionView.h"
#import "ActionViewHandler.h"
#import "ItemInDetailViewProtocol.h"
#import "NodeUpdatableProtocol.h"

typedef NS_ENUM(NSUInteger, PagingScrollViewSegmentType)
{
    PagingScrollViewSegmentTypeFilePreview = 0,
    PagingScrollViewSegmentTypeMetadata,
    PagingScrollViewSegmentTypeVersionHistory,
    PagingScrollViewSegmentTypeComments,
    PagingScrollViewSegmentTypeMap,
    PagingScrollViewSegmentType_MAX
};

@interface BaseDocumentPreviewViewController : UIViewController <ActionCollectionViewDelegate, PagedScrollViewDelegate, ActionViewDelegate, ItemInDetailViewProtocol, NodeUpdatableProtocol>

// LayoutConstraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *segmentControlHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *actionViewHeightConstraint;

// IBOutlets
@property (nonatomic, weak) IBOutlet UISegmentedControl *pagingSegmentControl;
@property (nonatomic, weak) IBOutlet PagedScrollView *pagingScrollView;
@property (nonatomic, weak) IBOutlet ActionCollectionView *actionMenuView;

// Data Model
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoDocument *document;
@property (nonatomic, strong) NSString *documentContentFilePath;
@property (nonatomic, strong) NSMutableArray *pagingControllers;
@property (nonatomic, strong) ActionViewHandler *actionHandler;
@property (nonatomic, strong) AlfrescoPermissions *documentPermissions;
@property (nonatomic, assign) InAppDocumentLocation documentLocation;
// Services
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoRatingService *ratingService;

// Views
@property (nonatomic, strong) MBProgressHUD *progressHUD;

- (instancetype)initWithAlfrescoDocument:(AlfrescoDocument *)document
                             permissions:(AlfrescoPermissions *)permissions
                         contentFilePath:(NSString *)contentFilePath
                        documentLocation:(InAppDocumentLocation)documentLocation
                                 session:(id<AlfrescoSession>)session;
- (void)localiseUI;

@end
