//
//  BaseFileFolderListViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 17/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ParentListViewController.h"
#import "AlfrescoNodeCell.h"
#import "SyncManager.h"
#import "FavouriteManager.h"
#import "Utility.h"
#import "ThumbnailManager.h"

@interface BaseFileFolderListViewController : ParentListViewController <UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoSearchService *searchService;
@property (nonatomic, strong) AlfrescoFolder *displayFolder;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) MBProgressHUD *searchProgressHUD;

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session;
- (void)retrieveContentOfFolder:(AlfrescoFolder *)folder
            usingListingContext:(AlfrescoListingContext *)listingContext
                completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock;

@end
