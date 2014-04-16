//
//  Utility.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "Utility.h"
#import "AppDelegate.h"
#import "NavigationViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UserAccount.h"
#import "Constants.h"
#import "RootRevealControllerViewController.h"
#import "DetailSplitViewController.h"
#import "UniversalDevice.h"
#import "ContainerViewController.h"

static NSDictionary *smallIconMappings;
static NSDictionary *largeIconMappings;
static NSDateFormatter *dateFormatter;
static CGFloat const kZoomAnimationSpeed = 0.2f;

@interface Utility ()

+ (NSDateFormatter *)dateFormatter;

@end

/**
 * Notice Messages
 */
SystemNotice *displayErrorMessage(NSString *message)
{
    return displayErrorMessageWithTitle(message, nil);
}

SystemNotice *displayErrorMessageWithTitle(NSString *message, NSString *title)
{
    return [SystemNotice showErrorNoticeInView:activeView() message:message title:title];
}

SystemNotice *displayWarningMessageWithTitle(NSString *message, NSString *title)
{
    return [SystemNotice showWarningNoticeInView:activeView() message:message title:title];
}

SystemNotice *displayInformationMessage(NSString *message)
{
    return [SystemNotice showInformationNoticeInView:activeView() message:message];
}

SystemNotice *displayInformationMessageWithTitle(NSString *message, NSString *title)
{
    return [SystemNotice showInformationNoticeInView:activeView() message:message title:title];
}

UIView *activeView(void)
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    ContainerViewController *containerController = (ContainerViewController *)appDelegate.window.rootViewController;
    
    if (appDelegate.window.rootViewController.presentedViewController)
    {
        //To work around a system notice that is tried to be presented in a modal view controller
        return appDelegate.window.rootViewController.presentedViewController.view;
    }
    else if (IS_IPAD)
    {
        return containerController.view;
    }
    return appDelegate.window.rootViewController.view;
}

UIImage *smallImageForType(NSString *type)
{
    type = [type lowercaseString];
    
    if (!smallIconMappings)
    {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:kSmallThumbnailImageMappingPlist ofType:@"plist"];
        smallIconMappings = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    }
    
    NSString *imageName = [smallIconMappings objectForKey:type];
    
    if (!imageName)
    {
        imageName = @"generic.png";
    }
    
    return [UIImage imageNamed:imageName];
}

UIImage *largeImageForType(NSString *type)
{
    type = [type lowercaseString];
    
    if (!largeIconMappings)
    {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:kLargeThumbnailImageMappingPlist ofType:@"plist"];
        largeIconMappings = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    }
    
    NSString *imageName = [largeIconMappings objectForKey:type];
    
    if (!imageName)
    {
        imageName = @"generic.png";
    }
    
    return [UIImage imageNamed:imageName];
}

/*
 * resize image to a different size
 * @param image: image to be resized
 * @param size:  resizing size
 */
UIImage *resizeImage(UIImage *image, CGSize size)
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}


NSString *relativeDateFromDate(NSDate *objDate)
{
    if (nil == objDate)
    {
		return @"";
	}
    
    NSDate *todayDate = [NSDate date];
    double ti = [objDate timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    
    NSString *key = nil;
    int diff = 0;
    
    if (ti < 1)
    {
        key = @"relative.date.just-now";
    }
    else if (ti < 60)
    {
        key = @"relative.date.less-than-a-minute-ago";
    }
    else if (ti < 3600)
    {
        diff = round(ti / 60);
        key = (diff > 1) ? @"relative.date.n-minutes-ago" : @"relative.date.one-minute-ago";
    }
    else if (ti < 86400)
    {
        diff = round(ti / 60 / 60);
        key = (diff > 1) ? @"relative.date.n-hours-ago" : @"relative.date.one-hour-ago";
    }
    else
    {
        diff = round(ti / 60 / 60 / 24);
        key = (diff > 1) ? @"relative.date.n-days-ago" : @"relative.date.one-day-ago";
    }
    
    return [NSString stringWithFormat:NSLocalizedString(key, @"Localized relative date string"), diff];
}

NSString *stringForLongFileSize(unsigned long long size)
{
	double floatSize = size;
	if (size < 1023)
    {
        return([NSString stringWithFormat:@"%llu %@", size, NSLocalizedString(@"file.size.bytes", @"file bytes, used as follows: '100 bytes'")]);
    }
    
	floatSize = floatSize / 1024;
	if (floatSize < 1023)
    {
        return([NSString stringWithFormat:@"%1.1f %@",floatSize, NSLocalizedString(@"file.size.kilobytes", @"Abbreviation for Kilobytes, used as follows: '17KB'")]);
    }
    
	floatSize = floatSize / 1024;
	if (floatSize < 1023)
    {
        return([NSString stringWithFormat:@"%1.1f %@",floatSize, NSLocalizedString(@"file.size.megabytes", @"Abbreviation for Megabytes, used as follows: '2MB'")]);
    }
    
	floatSize = floatSize / 1024;
	
    return ([NSString stringWithFormat:@"%1.1f %@",floatSize, NSLocalizedString(@"file.size.gigabytes", @"Abbrevation for Gigabyte, used as follows: '1GB'")]);
}

NSString *stringByRemovingHTMLTagsFromString(NSString *htmlString)
{
    if (!htmlString)
    {
        return nil;
    }
    
    NSRange range;
    NSString *string = htmlString;
    
    while ((range = [string rangeOfString:@"<[^>]+>" options:NSRegularExpressionSearch]).location != NSNotFound)
    {
        string = [string stringByReplacingCharactersInRange:range withString:@""];
    }
    
    // also replace &nbsp; with " "
    return [string stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
}

NSString *uniqueFileNameForNode(AlfrescoNode *node)
{
    NSString *lastModificationDateString = [[Utility dateFormatter] stringFromDate:node.modifiedAt];
    NSString *nodeIdentifier = node.identifier;
    
    NSRange versionNumberRange = [node.identifier rangeOfString:@";"];
    if (versionNumberRange.location != NSNotFound)
    {
        nodeIdentifier = [node.identifier substringToIndex:versionNumberRange.location];
    }
    NSString *nodeUniqueIdentifier = [NSString stringWithFormat:@"%@%@", nodeIdentifier, lastModificationDateString];
    
    NSMutableCharacterSet *wantedCharacters = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [wantedCharacters invert];
    NSString *fileNameString = [[nodeUniqueIdentifier componentsSeparatedByCharactersInSet:wantedCharacters] componentsJoinedByString:@""];
    
    return fileNameString;
}

NSData *jsonDataFromDictionary(NSDictionary *dictionary)
{
    NSData *jsonData = nil;
    
    if ([NSJSONSerialization isValidJSONObject:dictionary])
    {
        NSError *jsonError = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&jsonError];
        if (jsonError == nil)
        {
            jsonData = data;
        }
    }
    return jsonData;
}

NSDictionary *dictionaryOfVariableBindingsWithArray(NSArray *views)
{
    NSMutableDictionary *returnDictionary = nil;
    
    if (views)
    {
        returnDictionary = [NSMutableDictionary dictionaryWithCapacity:views.count];
        
        NSString *keyTemplateFormat = @"view%d";
        for (int i = 0; i < views.count; i++)
        {
            UIView *currentView = views[i];
            NSString *keyForCurrentView = [NSString stringWithFormat:keyTemplateFormat, i];
            [returnDictionary setObject:currentView forKey:keyForCurrentView];
        }
    }
    
    return returnDictionary;
}

/*
 * appends current timestamp to name
 * @param name: current filename
 */
NSString *fileNameAppendedWithDate(NSString *name)
{
    NSString *dateString = [[Utility dateFormatter] stringFromDate:[NSDate date]];
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", name.stringByDeletingPathExtension, dateString];
    return fileName;
}

NSString *filenameAppendedWithDateModififed(NSString *filenameOrPath, AlfrescoNode *node)
{
    NSString *dateString = [[Utility dateFormatter] stringFromDate:node.modifiedAt];
    NSString *fileExtension = filenameOrPath.pathExtension;
    NSString *filePathOrName = [[NSString stringWithFormat:@"%@%@", filenameOrPath.stringByDeletingPathExtension, dateString] stringByAppendingPathExtension:fileExtension];
    return filePathOrName;
}

//void clearOutdatedCacheFiles()
//{
//    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
//    
//    void (^removeOldCachedDataBlock)(NSString *filePath) = ^(NSString *filePath) {
//        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:nil];
//        
//        NSDate *lastModifiedDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
//        
//        NSDate *today = [NSDate date];
//        NSCalendar *gregorianCalender = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
//        NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
//        [offsetComponents setDay:-kNumberOfDaysToKeepCachedData];
//        NSDate *oldestCacheDate = [gregorianCalender dateByAddingComponents:offsetComponents toDate:today options:0];
//        
//        if ([lastModifiedDate compare:oldestCacheDate] == NSOrderedAscending)
//        {
//            NSError *deleteError = nil;
//            [fileManager removeItemAtPath:filePath error:&deleteError];
//            
//            if (deleteError)
//            {
//                AlfrescoLogError([deleteError localizedDescription]);
//            }
//        }
//    };
//    
//    NSString *tmpFolderPath = [fileManager temporaryDirectory];
//    NSString *thumbnailFolderPath = [[fileManager homeDirectory] stringByAppendingPathComponent:kThumbnailMappingFolder];
//    
//    NSError *tmpFolderEnumerationError = nil;
//    [fileManager enumerateThroughDirectory:tmpFolderPath includingSubDirectories:YES withBlock:removeOldCachedDataBlock error:&tmpFolderEnumerationError];
//    
//    if (tmpFolderEnumerationError)
//    {
//        AlfrescoLogError([tmpFolderEnumerationError localizedDescription]);
//    }
//    
//    NSError *thumbnailEnumerationError = nil;
//    [fileManager enumerateThroughDirectory:thumbnailFolderPath includingSubDirectories:YES withBlock:removeOldCachedDataBlock error:&thumbnailEnumerationError];
//    
//    if (thumbnailEnumerationError)
//    {
//        AlfrescoLogError([thumbnailEnumerationError localizedDescription]);
//    }
//}
//
//void uncaughtExceptionHandler(NSException *exception)
//{
//    [Utility clearDefaultFileSystem];
//    
//    NSLog(@"Stack: %@", [exception callStackReturnAddresses]);
//}

@implementation Utility

+ (NSDateFormatter *)dateFormatter
{
    if (!dateFormatter)
    {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    }
    return dateFormatter;
}

+ (BOOL)isValidEmail:(NSString *)emailAddress
{
    BOOL isEmail = NO;
    
    NSUInteger locationOfAtSymbol = [emailAddress rangeOfString:@"@"].location;
    if (emailAddress.length > 0 && locationOfAtSymbol != NSNotFound && locationOfAtSymbol < emailAddress.length - 1)
    {
        isEmail = YES;
    }
    
    return isEmail;
}

+ (BOOL)isVideo:(NSString *)filePath
{
    BOOL filePathIsVideo = NO;
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[filePath pathExtension], NULL);
    
    if (UTTypeConformsTo(UTI, (__bridge CFStringRef)@"public.movie"))
    {
        filePathIsVideo = YES;
    }
    CFRelease(UTI);
    
    return filePathIsVideo;
}

+ (BOOL)isAudio:(NSString *)filePath
{
    BOOL filePathIsAudio = NO;
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[filePath pathExtension], NULL);
    
    if (UTTypeConformsTo(UTI, (__bridge CFStringRef)@"public.audio"))
    {
        filePathIsAudio = YES;
    }
    CFRelease(UTI);
    
    return filePathIsAudio;
}

+ (BOOL)isAudioOrVideo:(NSString *)filePath
{
    return [self isAudio:filePath] || [self isVideo:filePath];
}

+ (void)writeInputStream:(NSInputStream *)inputStream toOutputStream:(NSOutputStream *)outputStream completionBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock
{
    if (!inputStream || !outputStream)
    {
        NSError *error = [NSError errorWithDomain:@"Provided a nil input or output stream" code:-1 userInfo:nil];
        if (completionBlock != NULL)
        {
            completionBlock(NO, error);
        }
        return;
    }
    
    [inputStream open];
    [outputStream open];
    
    NSUInteger bufferReadSize = 64 * 1024;
    while ([inputStream hasBytesAvailable])
    {
        NSInteger nRead;
        uint8_t buffer[bufferReadSize];
        nRead = [inputStream read:buffer maxLength:bufferReadSize];
        
        [outputStream write:buffer maxLength:nRead];
    }
    
    [inputStream close];
    [outputStream close];
    
    if (completionBlock != NULL)
    {
        completionBlock(YES, nil);
    }
}

+ (NSString *)randomAlphaNumericStringOfLength:(NSUInteger)length
{
    NSString *alphaNumerics = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSUInteger alphaNumericLength = [alphaNumerics length];
        
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
        
    for (int i = 0; i < length; i++)
    {
        int randomIndex = arc4random() % alphaNumericLength;
        [randomString appendFormat:@"%C", [alphaNumerics characterAtIndex:randomIndex]];
    }
        
    return randomString;
}

+ (NSString *)mimeTypeForFileExtension:(NSString *)extension
{
    CFStringRef pathExtension = (__bridge_retained CFStringRef)extension;
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    if (NULL != type)
    {
        CFRelease(type);
    }
    if (NULL != pathExtension)
    {
        CFRelease(pathExtension);
    }
    return mimeType;
}

+ (NSString *)fileExtensionFromMimeType:(NSString *)mimeType
{
    CFStringRef MIMEType = (__bridge CFStringRef)mimeType;
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, NULL);
    NSString *fileExtension = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
    
    if (uti != NULL)
    {
        CFRelease(uti);
    }
    
    return fileExtension;
}

+ (NSString *)serverURLStringFromAccount:(UserAccount *)account
{
    return [NSString stringWithFormat:kAlfrescoOnPremiseServerURLTemplate, account.protocol, account.serverAddress, account.serverPort];
}

+ (void)zoomAppLevelOutWithCompletionBlock:(void (^)(void))completionBlock
{
    [UIView animateWithDuration:kZoomAnimationSpeed delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        RootRevealControllerViewController *revealViewController = (RootRevealControllerViewController *)[UniversalDevice revealViewController];
        UIView *revealView = revealViewController.view;
        revealView.transform = CGAffineTransformMakeScale(0.9f, 0.9f);
    } completion:^(BOOL finished) {
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
}

+ (void)resetAppZoomLevelWithCompletionBlock:(void (^)(void))completionBlock
{
    [UIView animateWithDuration:kZoomAnimationSpeed delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        RootRevealControllerViewController *revealViewController = (RootRevealControllerViewController *)[UniversalDevice revealViewController];
        UIView *revealView = revealViewController.view;
        revealView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    } completion:^(BOOL finished) {
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
}
    
+ (void)colorButtonsForActionSheet:(UIActionSheet *)actionSheet tintColor:(UIColor *)tintColor
{
    NSArray *actionSheetButtons = actionSheet.subviews;
    for (UIView *view in actionSheetButtons)
    {
        if ([view isKindOfClass:[UIButton class]])
        {
            UIButton *button = (UIButton *)view;
            [button setTitleColor:tintColor forState:UIControlStateNormal];
        }
    }
}

+ (UIImage *)imageForPriority:(NSNumber *)priority
{
    NSInteger priorityValue = priority.integerValue;
    
    UIImage *priorityImage = nil;
    
    switch (priorityValue) {
        case 1:
            priorityImage = [UIImage imageNamed:@"task_priority_high.png"];
            break;
            
        case 2:
            priorityImage = [UIImage imageNamed:@"task_priority_medium.png"];
            break;
        case 3:
            priorityImage = [UIImage imageNamed:@"task_priority_low.png"];
            break;
            
        default:
            break;
    }
    
    return priorityImage;
}

@end
