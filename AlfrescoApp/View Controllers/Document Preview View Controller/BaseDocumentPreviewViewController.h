//
//  BaseDocumentPreviewViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 14/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PagedScrollView.h"
#import "ActionCollectionView.h"
#import "ActionViewHandler.h"
#import <MessageUI/MessageUI.h>
#import "MBProgressHUD.h"
#import "ItemInDetailViewProtocol.h"
#import "NodeUpdatableProtocol.h"

typedef NS_ENUM(NSUInteger, PagingScrollViewSegmentType)
{
    PagingScrollViewSegmentTypeFilePreview = 0,
    PagingScrollViewSegmentTypeMetadata,
    PagingScrollViewSegmentTypeVersionHistory,
    PagingScrollViewSegmentTypeComments,
    PagingScrollViewSegmentType_MAX
};

@interface BaseDocumentPreviewViewController : UIViewController <ActionCollectionViewDelegate, PagedScrollViewDelegate, ActionViewDelegate, ItemInDetailViewProtocol, NodeUpdatableProtocol>

// LayoutConstraints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *segmentControlHeightConstraint;

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
