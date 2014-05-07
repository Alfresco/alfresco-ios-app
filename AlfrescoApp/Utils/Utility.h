//
//  Utility.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SystemNotice.h"

@class AlfrescoNode;
@class UserAccount;


/**
 * TaskPriority lightweight class
 */
@interface TaskPriority : NSObject
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) UIColor *tintColor;
@property (nonatomic, retain) NSString *summary;
@end


/**
 * System Notices
 */
SystemNotice *displayErrorMessage(NSString *message);
SystemNotice *displayErrorMessageWithTitle(NSString *message, NSString *title);
SystemNotice *displayWarningMessageWithTitle(NSString *message, NSString *title);
SystemNotice *displayInformationMessage(NSString *message);
SystemNotice *displayInformationMessageWithTitle(NSString *message, NSString *title);
UIView *activeView(void);

UIImage *smallImageForType(NSString *type);
UIImage *largeImageForType(NSString *type);

/*
 * resize image to a different size
 */
UIImage *resizeImage(UIImage *image, CGSize size);

NSString *relativeDateFromDate(NSDate *objDate);
NSString *stringForLongFileSize(unsigned long long size);

NSString *stringByRemovingHTMLTagsFromString(NSString *htmlString);

NSString *uniqueFileNameForNode(AlfrescoNode *node);
NSString *fileNameAppendedWithDate(NSString *name);
NSString *filenameAppendedWithDateModified(NSString *filenameOrPath, AlfrescoNode *node);

NSData *jsonDataFromDictionary(NSDictionary *dictionary);

NSDictionary *dictionaryOfVariableBindingsWithArray(NSArray *views);

//void clearOutdatedCacheFiles();

//void uncaughtExceptionHandler(NSException *exception);

@interface Utility : NSObject

+ (BOOL)isValidEmail:(NSString *)emailAddress;
+ (BOOL)isVideo:(NSString *)filePath;
+ (BOOL)isAudio:(NSString *)filePath;
+ (BOOL)isAudioOrVideo:(NSString *)filePath;
//+ (void)writeInputStream:(NSInputStream *)inputStream toOutputStream:(NSOutputStream *)outputStream completionBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock;
+ (NSString *)randomAlphaNumericStringOfLength:(NSUInteger)length;
//+ (void)clearDefaultFileSystem;
//+ (BOOL)isAudioOrVideoAndSupported:(NSString *)filePath;
//+ (BOOL)isAudioOrVideoAndNotSupported:(NSString *)filePath;
+ (NSString *)mimeTypeForFileExtension:(NSString *)extension;
+ (NSString *)fileExtensionFromMimeType:(NSString *)mimeType;
+ (NSString *)serverURLStringFromAccount:(UserAccount *)account;
+ (void)zoomAppLevelOutWithCompletionBlock:(void (^)(void))completionBlock;
+ (void)resetAppZoomLevelWithCompletionBlock:(void (^)(void))completionBlock;
+ (void)colorButtonsForActionSheet:(UIActionSheet *)actionSheet tintColor:(UIColor *)tintColor;
+ (TaskPriority *)taskPriorityForPriority:(NSNumber *)priority;
+ (UIImage *)cropImageIntoSquare:(UIImage *)originalImage;

@end
