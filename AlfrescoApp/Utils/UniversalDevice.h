//
//  UniversalDevice.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@interface UniversalDevice : NSObject

/*
 * Pushes a FolderPreviewController. If running on the iPad, the controller is added to the detail view.
 * If on the iPhone/iPod, the controller is pushed on the navigation controller provided.
 */
+ (void)pushToDisplayFolderPreviewControllerForAlfrescoDocument:(AlfrescoFolder *)folder
                                                    permissions:(AlfrescoPermissions *)permissions
                                                        session:(id<AlfrescoSession>)session
                                           navigationController:(UINavigationController *)navigationController
                                                       animated:(BOOL)animated;

/*
 * Pushes a DocumentPreviewController. If running on the iPad, the controller is added to the detail view.
 * If on the iPhone/iPod, the controller is pushed on the navigation controller provided.
 */
+ (void)pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)document
                                                      permissions:(AlfrescoPermissions *)permissions
                                                      contentFile:(NSString *)contentFilePath
                                                 documentLocation:(InAppDocumentLocation)documentLocation
                                                          session:(id<AlfrescoSession>)session
                                             navigationController:(UINavigationController *)navigationController
                                                         animated:(BOOL)animated;

/*
 * Pushes a DownloadDocumentPreviewController. If running on the iPad, the controller is added to the detail view.
 * If on the iPhone/iPod, the controller is pushed on the navigation controller provided.
 */
+ (void)pushToDisplayDownloadDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)document
                                                              permissions:(AlfrescoPermissions *)permissions
                                                              contentFile:(NSString *)contentFilePath
                                                         documentLocation:(InAppDocumentLocation)documentLocation
                                                                  session:(id<AlfrescoSession>)session
                                                     navigationController:(UINavigationController *)navigationController
                                                                 animated:(BOOL)animated;

/*
 * Pushes the view controller provided. If running on the iPad, the controller is added to the detail view.
 * If on the iPhone/iPod, the controller is pushed on the navigation controller provided.
 */
+ (void)pushToDisplayViewController:(UIViewController *)viewController
          usingNavigationController:(UINavigationController *)navigationController
                           animated:(BOOL)animated;

/*
 * Displays the view controller provided as a modal view. If running on the iPad, the presenation style is set to UIModalPresentationFormSheet
 * before the controller is displayed.
 */
+ (void)displayModalViewController:(UIViewController *)viewController
                      onController:(UIViewController *)controller
               withCompletionBlock:(void (^)(void))completionBlock;

/*
 * Returns the controller currently being displayed in the detail view. If running on the iPhone/iPod nil is returned.
 */
+ (UIViewController *)controllerDisplayedInDetailNavigationController;

/*
 * Returns the node identifier of the current view displayed in the detail view controller.
 * If on a iPhone/iPod device, or the node displayed is not present. Nil is returned.
 *
 * NOTE: View controllers must conform to the ItemInDetailViewProtocol.
 */
+ (NSString *)detailViewItemIdentifier;

/*
 * Clears the detail view controller. If on iPhone/iPod devices, the user is popped to the root view controller.
 */
+ (void)clearDetailViewController;

/*
 * Returns the container view controller.
 * This is the app's root view controller.
 */
+ (UIViewController *)containerViewController;

/*
 * Returns the reveal view controller.
 */
+ (UIViewController *)revealViewController;

/*
 * Returns the revealing master view controller.
 */
+ (UIViewController *)rootMasterViewController;

/*
 * Returns the revealing detail view controller.
 */
+ (UIViewController *)rootDetailViewController;

@end
