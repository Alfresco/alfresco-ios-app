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
@class Account;

/* System Notices */
SystemNotice * displayErrorMessage(NSString *message);
SystemNotice * displayErrorMessageWithTitle(NSString *message, NSString *title);
SystemNotice * displayWarningMessageWithTitle(NSString *message, NSString *title);
SystemNotice * displayInformationMessage(NSString *message);
SystemNotice * displayInformationMessageWithTitle(NSString *message, NSString *title);
UIView * activeView(void);

UIImage *imageForType(NSString *type);
/*
 * resize image to a different size
 */
UIImage *resizeImage(UIImage *image, CGSize size);

NSString *relativeDateFromDate(NSDate *objDate);
NSString *stringForLongFileSize(unsigned long long size);

NSString *stringByRemovingHTMLTagsFromString(NSString *htmlString);

NSString *uniqueFileNameForNode(AlfrescoNode *node);
NSString *fileNameAppendedWithDate(NSString *name);

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
+ (NSString *)serverURLStringFromAccount:(Account *)account;

@end
