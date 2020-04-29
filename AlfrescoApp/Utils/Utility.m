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
 
#import "Utility.h"
#import "AppDelegate.h"
#import "NavigationViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "UserAccount.h"
#import "Constants.h"
#import "RootRevealViewController.h"
#import "DetailSplitViewController.h"
#import "UniversalDevice.h"
#import "ContainerViewController.h"
#import "LocationManager.h"


static NSDictionary *smallIconMappings;
static NSDictionary *largeIconMappings;
static NSDateFormatter *dateFormatter;
static CGFloat const kZoomAnimationSpeed = 0.2f;
static NSDictionary *helpURLLocaleIdentifiers;

/**
 * TaskPriority lightweight class
 */
@implementation TaskPriority
+ (TaskPriority *)taskPriorityWithImageName:(NSString *)imageName summary:(NSString *)summary
{
    TaskPriority *taskPriority = [TaskPriority new];
    taskPriority.image = [UIImage imageNamed:imageName];
    taskPriority.summary = summary;
    return taskPriority;
}
@end


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

SystemNotice *displayWarningMessage(NSString *message)
{
    return [SystemNotice showWarningNoticeInView:activeView() message:message];
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
    UIView *view = nil;
    
    if (appDelegate.window.rootViewController.presentedViewController)
    {
        //To work around a system notice that is tried to be presented in a modal view controller
        UIViewController *presentedViewController = appDelegate.window.rootViewController.presentedViewController;
        
        if ([presentedViewController isKindOfClass:[UIAlertController class]])
        {
            view = presentedViewController.view.superview;
        }
        else
        {
            view = presentedViewController.view;
        }
    }
    else
    {
        view = appDelegate.window.rootViewController.view;
    }
    
    return view;
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
        imageName = @"small_document.png";
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
        imageName = @"large_document.png";
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

NSString *relativeTimeFromDate(NSDate *date)
{
    if (nil == date)
    {
		return @"";
	}

    NSDate *today = [NSDate date];
    NSDate *earliest = [today earlierDate:date];
    BOOL isTodayEarlierDate = (today == earliest);
    NSDate *latest = isTodayEarlierDate ? date : today;

    NSString *(^relativeDateString)(NSString *key, NSInteger param) = ^NSString *(NSString *key, NSInteger param) {
        NSString *dateKey = [NSString stringWithFormat:@"relative.date.%@.%@", isTodayEarlierDate ? @"future" : @"past", key];
        return [NSString stringWithFormat:NSLocalizedString(dateKey, @"Date string"), param];
    };

    NSTimeInterval seconds_ago = [latest timeIntervalSinceDate:earliest];
    
    if (seconds_ago < 2)
    {
        return NSLocalizedString(@"relative.date.just-now", @"Just now");
    }

    double minutes_ago = round(seconds_ago / 60);
    if (seconds_ago < 60)
    {
        return relativeDateString(@"n-seconds", seconds_ago);
    }
    if (minutes_ago == 1)
    {
        return relativeDateString(@"one-minute", 0);
    }

    double hours_ago = round(minutes_ago / 60);
    if (minutes_ago < 60)
    {
        return relativeDateString(@"n-minutes", minutes_ago);
    }
    if (hours_ago == 1)
    {
        return relativeDateString(@"one-hour", 0);
    }

    double days_ago = round(hours_ago / 24);
    if (hours_ago < 24)
    {
        return relativeDateString(@"n-hours", hours_ago);
    }
    if (days_ago == 1)
    {
        return relativeDateString(@"one-day", 0);
    }

    double weeks_ago = round(days_ago / 7);
    if (days_ago < 7)
    {
        return relativeDateString(@"n-days", days_ago);
    }
    if (weeks_ago == 1)
    {
        return relativeDateString(@"one-week", 0);
    }
 
    double months_ago = round(days_ago / 30);
    if (days_ago < 30)
    {
        return relativeDateString(@"n-weeks", weeks_ago);
    }
    if (months_ago == 1)
    {
        return relativeDateString(@"one-month", 0);
    }
    
    double years_ago = round(days_ago / 365);
    if (days_ago < 365)
    {
        return relativeDateString(@"n-months", months_ago);
    }
    if (years_ago == 1)
    {
        return relativeDateString(@"one-year", 0);
    }
    
    return relativeDateString(@"n-years", years_ago);
}

NSString *relativeDateFromDate(NSDate *date)
{
    if (nil == date)
    {
        return @"";
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger preservedComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
    
    // Only keep the date components
    NSDate *today = [calendar dateFromComponents:[calendar components:preservedComponents fromDate:[NSDate date]]];
    date = [calendar dateFromComponents:[calendar components:preservedComponents fromDate:date]];

    NSDate *earliest = [today earlierDate:date];
    BOOL isTodayEarlierDate = (today == earliest);
    NSDate *latest = isTodayEarlierDate ? date : today;
    
    NSString *(^relativeDateString)(NSString *key, NSInteger param) = ^NSString *(NSString *key, NSInteger param) {
        NSString *dateKey = [NSString stringWithFormat:@"relative.date.%@.%@", isTodayEarlierDate ? @"future" : @"past", key];
        return [NSString stringWithFormat:NSLocalizedString(dateKey, @"Date string"), param];
    };
    
    NSTimeInterval seconds_ago = [latest timeIntervalSinceDate:earliest];
    if (seconds_ago < 86400) // 24*60*60
    {
        return NSLocalizedString(@"relative.date.today", @"Today");
    }
    
    double days_ago = round(seconds_ago / 86400); // 24*60*60
    if (days_ago == 1)
    {
        return relativeDateString(@"one-day", 0);
    }
    
    double weeks_ago = round(days_ago / 7);
    if (days_ago < 7)
    {
        return relativeDateString(@"n-days", days_ago);
    }
    if (weeks_ago == 1)
    {
        return relativeDateString(@"one-week", 0);
    }
    
    double months_ago = round(days_ago / 30);
    if (days_ago < 30)
    {
        return relativeDateString(@"n-weeks", weeks_ago);
    }
    if (months_ago == 1)
    {
        return relativeDateString(@"one-month", 0);
    }
    
    double years_ago = round(days_ago / 365);
    if (days_ago < 365)
    {
        return relativeDateString(@"n-months", months_ago);
    }
    if (years_ago == 1)
    {
        return relativeDateString(@"one-year", 0);
    }
    
    return relativeDateString(@"n-years", years_ago);
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
    NSString *fileExtension = name.pathExtension;
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", name.stringByDeletingPathExtension, dateString];
    
    if (fileExtension.length > 0)
    {
        fileName = [fileName stringByAppendingPathExtension:fileExtension];
    }
    
    return fileName;
}

NSString *filenameAppendedWithDateModified(NSString *filenameOrPath, AlfrescoNode *node)
{
    NSString *dateString = [[Utility dateFormatter] stringFromDate:node.modifiedAt];
    NSString *fileExtension = filenameOrPath.pathExtension;
    NSString *filePathOrName = [NSString stringWithFormat:@"%@_%@", filenameOrPath.stringByDeletingPathExtension, dateString];
    if (fileExtension.length > 0)
    {
        filePathOrName = [filePathOrName stringByAppendingPathExtension:fileExtension];
    }
    return filePathOrName;
}

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

+ (BOOL)isValidFolderName:(NSString *)folderName
{
    BOOL isValid = NO;
    
    if ([folderName length] != 0)
    {
        NSString *regexPattern = @"([\"*\\\\><?/:;|]+)|([.]?[.]+$)";
        NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:regexPattern options:NSRegularExpressionCaseInsensitive error:nil];
        NSUInteger regexMatches = [regex numberOfMatchesInString:folderName options:0 range:NSMakeRange(0, [folderName length])];
        
        if (regexMatches == 0)
        {
            isValid = YES;
        }
    }

    return isValid;
}

+ (BOOL)isVideo:(NSString *)filePath
{
    BOOL filePathIsVideo = NO;
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[filePath pathExtension], NULL);
    
    if (UTI != NULL)
    {
        if (UTTypeConformsTo(UTI, (__bridge CFStringRef)@"public.movie"))
        {
            filePathIsVideo = YES;
        }
        CFRelease(UTI);
    }
    
    return filePathIsVideo;
}

+ (BOOL)isAudio:(NSString *)filePath
{
    BOOL filePathIsAudio = NO;
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[filePath pathExtension], NULL);
    
    if (UTI != NULL)
    {
        if (UTTypeConformsTo(UTI, (__bridge CFStringRef)@"public.audio"))
        {
            filePathIsAudio = YES;
        }
        CFRelease(UTI);
    }
    
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

// This method has a clone in DocumentPickerViewControllerClass.
// TODO: break up Utility in smaller functional pieces (FileUtility, UIUtility and so on) and get rid of the clone.
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
    
    if (mimeType.length == 0)
    {
        mimeType = @"application/octet-stream";
    }

    /**
     * Force the mimetype to audio/mp4 it iOS determined it should be audio/x-m4a
     * Otherwise the repo applies both audio and exif aspects to the node
     */
    if ([mimeType isEqualToString:@"audio/x-m4a"])
    {
        mimeType = @"audio/mp4";
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
    NSURLComponents *url = [[NSURLComponents alloc] init];
    url.scheme = account.protocol;
    url.host = account.serverAddress;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    url.port = [formatter numberFromString:account.serverPort];
    url.path = account.serviceDocument;

    return [url string];
}

+ (void)zoomAppLevelOutWithCompletionBlock:(void (^)(void))completionBlock
{
    [UIView animateWithDuration:kZoomAnimationSpeed delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        RootRevealViewController *revealViewController = (RootRevealViewController *)[UniversalDevice revealViewController];
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
        RootRevealViewController *revealViewController = (RootRevealViewController *)[UniversalDevice revealViewController];
        UIView *revealView = revealViewController.view;
        revealView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    } completion:^(BOOL finished) {
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
}
    
+ (TaskPriority *)taskPriorityForPriority:(NSNumber *)priority
{
    TaskPriority *taskPriority = nil;
    
    switch (priority.integerValue)
    {
        case 1:
            taskPriority = [TaskPriority taskPriorityWithImageName:@"task_priority_high.png" summary:NSLocalizedString(@"tasks.priority.high", @"High Priority")];
            break;
            
        case 2:
            taskPriority = [TaskPriority taskPriorityWithImageName:@"task_priority_medium.png" summary:NSLocalizedString(@"tasks.priority.medium", @"Medium Priority")];
            break;

        case 3:
            taskPriority = [TaskPriority taskPriorityWithImageName:@"task_priority_low.png" summary:NSLocalizedString(@"tasks.priority.low", @"Low Priority")];
            break;
            
        default:
            break;
    }
    
    return taskPriority;
}

+ (NSString *)displayNameForProcessDefinition:(NSString *)processDefinitionIdentifier
{
    NSString *displayNameKey = @"tasks.process.unnamed";
    
    if ([processDefinitionIdentifier hasPrefix:kAlfrescoWorkflowJBPMEngine])
    {
        displayNameKey = [NSString stringWithFormat:@"tasks.process.%@", processDefinitionIdentifier];
    }
    else
    {
        NSArray *components = [processDefinitionIdentifier componentsSeparatedByString:@":"];
        if (components.count == 3)
        {
            displayNameKey = [NSString stringWithFormat:@"tasks.process.%@", components[0]];
        }
        else
        {
            displayNameKey = [NSString stringWithFormat:@"tasks.process.%@", [processDefinitionIdentifier stringByReplacingOccurrencesOfString:kAlfrescoWorkflowActivitiEngine withString:@""]];
        }
    }
    
    return NSLocalizedString(displayNameKey, @"Localized process name");
}

+ (UIImage *)cropImageIntoSquare:(UIImage *)originalImage
{
    UIImage *croppedImage = nil;
    
    float originalImageWidth = originalImage.size.width;
    float originalImageHeight = originalImage.size.height;
    
    float cropWidthHeight = fminf(originalImageWidth, originalImageHeight);
    
    float startXPosition = (originalImageWidth - cropWidthHeight) / 2;
    float startYPosition = (originalImageHeight - cropWidthHeight) / 2;
    
    CGRect cropRect = CGRectMake(startXPosition, startYPosition, cropWidthHeight, cropWidthHeight);
    
    CGImageRef image = CGImageCreateWithImageInRect([originalImage CGImage], cropRect);
    
    if (image != NULL)
    {
        croppedImage = [UIImage imageWithCGImage:image scale:originalImage.scale orientation:originalImage.imageOrientation];
        CGImageRelease(image);
    }
    
    return croppedImage;
}

+ (void)createBorderedButton:(UIButton *)button label:(NSString *)label color:(UIColor *)color
{
    // Colour-matched rounded border
    button.layer.borderWidth = 1.0f;
    button.layer.borderColor = color.CGColor;
    button.layer.cornerRadius = 4.0f;
    button.layer.masksToBounds = YES;
    
    // Edge inserts
    button.contentEdgeInsets = UIEdgeInsetsMake(8.0f, 8.0f, 8.0f, 8.0f);

    // Normal and highlight state
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    [button setTitle:[label uppercaseString] forState:UIControlStateNormal];
    [button setTitle:[label uppercaseString] forState:UIControlStateHighlighted];
    [button setTitleColor:color forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];

    // Generate highlighted background image
    UIGraphicsBeginImageContextWithOptions(button.frame.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setFill];
    CGContextFillRect(context, CGRectMake(0, 0, button.frame.size.width, button.frame.size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [button setBackgroundImage:image forState:UIControlStateHighlighted];
}

+ (NSArray *)localisationsThatRequireTwoRowsInActionView
{
    return @[kAlfrescoISO6391ItalianCode, kAlfrescoISO6391GermanCode, kAlfrescoISO6391SpanishCode, kAlfrescoISO6391JapaneseCode];
}

+ (NSString *)helpURLLocaleIdentifierForAppLocale
{
    return [Utility helpURLLocaleIdentifierForLocale:[[NSBundle mainBundle] preferredLocalizations].firstObject];
}

+ (NSString *)helpURLLocaleIdentifierForLocale:(NSString *)locale
{
    NSString *urlLanguageKey = nil;
    
    if (!helpURLLocaleIdentifiers)
    {
        NSString *plistPath = [[NSBundle mainBundle] pathForResource:kAlfrescoHelpURLPlistFilename ofType:@"plist"];
        helpURLLocaleIdentifiers = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    }
    
    urlLanguageKey = helpURLLocaleIdentifiers[locale];
    
    // if locale language is not in the dictionary, default to english
    if (!urlLanguageKey)
    {
        urlLanguageKey = helpURLLocaleIdentifiers[kAlfrescoISO6391EnglishCode];
    }
    
    return urlLanguageKey;
}

- (NSString *)accountIdentifierForAccount:(UserAccount *)userAccount
{
    NSString *accountIdentifier = userAccount.accountIdentifier;
    
    if (userAccount.accountType == UserAccountTypeCloud)
    {
        accountIdentifier = [NSString stringWithFormat:@"%@-%@", accountIdentifier, userAccount.selectedNetworkId];
    }
    return accountIdentifier;
}

+ (void)showLocalizedAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(title, @"")
                                                                             message:NSLocalizedString(message, @"")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil];
    [alertController addAction:okAction];
    UIAlertAction *changeSettingsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"permissions.settings.button", @"Change Settings")
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
                                                                   [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                                                               }];
    [alertController addAction:changeSettingsAction];
    [[UniversalDevice topPresentedViewController] presentViewController:alertController animated:YES completion:nil];
}

+ (NSData *)dataFromImage:(UIImage *)image metadata:(NSDictionary *)metadata mimetype:(NSString *)mimetype
{
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef)mimetype, NULL);
    CGImageDestinationRef imageDataDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, uti, 1, NULL);
    
    if (imageDataDestination == NULL)
    {
        AlfrescoLogError(@"Failed to create image destination");
        imageData = nil;
    }
    else
    {
        if (metadata)
        {
            CGImageDestinationAddImage(imageDataDestination, image.CGImage, (__bridge CFDictionaryRef)metadata);
        }
        else
        {
            CGImageDestinationAddImage(imageDataDestination, image.CGImage, NULL);
        }
        
        if (CGImageDestinationFinalize(imageDataDestination) == NO)
        {
            AlfrescoLogError(@"Failed to finalise");
            imageData = nil;
        }
        CFRelease(imageDataDestination);
    }
    
    CFRelease(uti);
    
    return imageData;
}

+ (NSDictionary *)metadataByAddingGPSToMetadata:(NSDictionary *)metadata
{
    NSMutableDictionary *returnedMetadata = [metadata mutableCopy];
    
    CLLocationCoordinate2D coordinates = [[LocationManager sharedManager] currentLocationCoordinates];
    
    NSDictionary *gpsDictionary = @{(NSString *)kCGImagePropertyGPSLatitude : [NSNumber numberWithFloat:fabs(coordinates.latitude)],
                                    (NSString *)kCGImagePropertyGPSLatitudeRef : ((coordinates.latitude >= 0) ? @"N" : @"S"),
                                    (NSString *)kCGImagePropertyGPSLongitude : [NSNumber numberWithFloat:fabs(coordinates.longitude)],
                                    (NSString *)kCGImagePropertyGPSLongitudeRef : ((coordinates.longitude >= 0) ? @"E" : @"W")
    };
    
    [returnedMetadata setValue:gpsDictionary forKey:(NSString *)kCGImagePropertyGPSDictionary];
    
    return returnedMetadata;
}


+ (NSDictionary *)metadataByAddingOrientation:(NSInteger)orientation toMetadata:(NSDictionary *)metadata
{
    NSMutableDictionary *returnedMetadata = [metadata mutableCopy];
    [returnedMetadata setValue:[NSNumber numberWithInteger:orientation] forKey:(NSString *)kCGImagePropertyOrientation];
    
    return returnedMetadata;
}

@end
