//
//  UploadFormViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "UploadFormViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "AlfrescoDocumentFolderService.h"
#import "AlfrescoFileManager.h"
#import "AlfrescoFolder.h"
#import "AlfrescoTaggingService.h"
#import "TagPickerViewController.h"
#import "UniversalDevice.h"
#import "Utility.h"
#import "AlfrescoErrors.h"
#import "UIAlertView+ALF.h"
#import <ImageIO/ImageIO.h>
#import "LocationManager.h"

NS_ENUM(NSUInteger, UploadFormCellTypes)
{
    UploadFormCellTypeName = 0,
    UploadFormCellTypeTags,
    UploadFormCellTypePreview,
};

static const NSString * kAudioFileName = @"audio.m4a";

@interface UploadFormViewController()

@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoTaggingService *tagService;
@property (nonatomic, strong) AlfrescoFolder *uploadToFolder;
@property (nonatomic, weak) id<UploadFormViewControllerDelegate> delegate;
@property (nonatomic, strong) UIImage *imageToUpload;
@property (nonatomic, strong) NSURL *documentURL;
@property (nonatomic, strong) NSString *fileExtension;
@property (nonatomic, strong) NSArray *cells;
@property (nonatomic, weak) UITextField *nameTextField;
@property (nonatomic, weak) UILabel *tagsLabel;
@property (nonatomic, strong) NSArray *tagsToApplyToDocument;
@property (nonatomic, weak) UITextField *activeTextField;
@property (nonatomic, weak) UIBarButtonItem *uploadButton;
@property (nonatomic, assign) UploadFormType uploadFormType;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) NSDictionary *metadata;

@end

@implementation UploadFormViewController

- (id)initWithSession:(id<AlfrescoSession>)session uploadImage:(UIImage *)image fileExtension:(NSString *)extension metadata:(NSDictionary *)metadata inFolder:(AlfrescoFolder *)currentFolder uploadFormType:(UploadFormType)formType delegate:(id<UploadFormViewControllerDelegate>)delegate;
{
    self = [self initWithSession:session folder:currentFolder delegate:delegate];
    
    self.imageToUpload = image;
    self.fileExtension = [extension lowercaseString];
    self.metadata = metadata;
    self.uploadFormType = formType;
    
    return self;
}

- (id)initWithSession:(id<AlfrescoSession>)session uploadDocumentPath:(NSString *)documentPath inFolder:(AlfrescoFolder *)currentFolder uploadFormType:(UploadFormType)formType delegate:(id<UploadFormViewControllerDelegate>)delegate
{
    self = [self initWithSession:session folder:currentFolder delegate:delegate];
    
    self.documentURL = [NSURL fileURLWithPath:documentPath];
    self.fileExtension = [documentPath.pathExtension lowercaseString];
    self.uploadFormType = formType;
    
    return self;
}

- (id)initWithSession:(id<AlfrescoSession>)session createAndUploadAudioToFolder:(AlfrescoFolder *)currentFolder delegate:(id<UploadFormViewControllerDelegate>)delegate
{
    self = [self initWithSession:session folder:currentFolder delegate:delegate];
    
    self.uploadFormType = UploadFormTypeAudio;
    
    return self;
}

- (id)initWithSession:(id<AlfrescoSession>)session folder:(AlfrescoFolder *)currentFolder delegate:(id<UploadFormViewControllerDelegate>)delegate
{
    self = [super initWithSession:session];
    if (self)
    {
        self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
        self.tagService = [[AlfrescoTaggingService alloc] initWithSession:self.session];
        self.uploadToFolder = currentFolder;
        self.delegate = delegate;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeAudioFileFromDefaultFileSystem];
}

- (void)loadView
{
    static NSInteger xPosition = 100;
    static NSInteger imagePreviewHeight = 300;
    static NSInteger topBottomPadding = 10;
    static NSInteger rightPadding = 4;
    static CGFloat documentIconWidth = 32.0f;
    static CGFloat documentIconHeight = 32.0f;
    static CGFloat indentation = 12.0f;
    
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // TableView
    UITableView *tableView = [[UITableView alloc] initWithFrame:view.frame style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizesSubviews = YES;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin
    | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [view addSubview:tableView];
    
    /**
     * Name cell
     */
    UITableViewCell *nameCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    nameCell.textLabel.text = NSLocalizedString(@"upload.photo.namecell.title", @"Name Title");
    UITextField *nameTextField = [[UITextField alloc] initWithFrame:CGRectMake(xPosition,
                                                                               topBottomPadding,
                                                                               nameCell.frame.size.width - xPosition - rightPadding,
                                                                               nameCell.frame.size.height - (topBottomPadding * 2))];
    nameTextField.placeholder = NSLocalizedString(@"upload.photo.namecell.textfield.placeholder.text", @"Placeholder Text");
    nameTextField.textAlignment = NSTextAlignmentRight;
    nameTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    nameTextField.delegate = self;
    nameTextField.returnKeyType = UIReturnKeyDone;
    self.nameTextField = nameTextField;
    [nameCell.contentView addSubview:nameTextField];

    /**
     * Tags cell
     */
    UITableViewCell *tagsCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    tagsCell.textLabel.text = NSLocalizedString(@"upload.photo.tagscell.title", @"Tags Title");
    tagsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    UILabel *tagsLabel = [[UILabel alloc] initWithFrame:CGRectMake(xPosition,
                                                                   topBottomPadding,
                                                                   tagsCell.frame.size.width - xPosition - rightPadding,
                                                                   tagsCell.frame.size.height - (topBottomPadding * 2))];
    tagsLabel.backgroundColor = [UIColor clearColor];
    tagsLabel.textAlignment = NSTextAlignmentRight;
    tagsLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    tagsLabel.text = NSLocalizedString(@"upload.photo.tagcell.textlabel.placeholder.text", @"Placeholder Text");
    self.tagsLabel = tagsLabel;
    [tagsCell.contentView addSubview:tagsLabel];
    
    /**
     * Preview cell
     */
    UITableViewCell *previewCell = nil;
    if (self.uploadFormType == UploadFormTypeImageCreated || self.uploadFormType == UploadFormTypeImagePhotoLibrary)
    {
        // Preview cell for images
        previewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        previewCell.frame = CGRectMake(0, 0, 320, imagePreviewHeight);
        previewCell.textLabel.text = NSLocalizedString(@"upload.photo.photocell.title", @"Photo Title");
        UIImageView *imagePreviewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(xPosition,
                                                                                           topBottomPadding,
                                                                                           previewCell.frame.size.width - xPosition - rightPadding,
                                                                                           previewCell.frame.size.height - (topBottomPadding * 2))];
        imagePreviewImageView.image = self.imageToUpload;
        imagePreviewImageView.contentMode = UIViewContentModeScaleAspectFit;
        imagePreviewImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
        [previewCell.contentView addSubview:imagePreviewImageView];
    }
    else if (self.uploadFormType == UploadFormTypeDocument ||
             (self.uploadFormType == UploadFormTypeVideoCreated || self.uploadFormType == UploadFormTypeVideoPhotoLibrary))
    {
        // Preview cell for documents
        nameTextField.text = [self.documentURL.lastPathComponent stringByDeletingPathExtension];
        previewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        
        NSString *previewCellLabelTitle = nil;
        
        switch (self.uploadFormType)
        {
            case UploadFormTypeDocument:
                previewCellLabelTitle = NSLocalizedString(@"upload.documentTitleCell.label", @"Document Label");
                break;
                
            case UploadFormTypeVideoCreated:
            case UploadFormTypeVideoPhotoLibrary:
                previewCellLabelTitle = NSLocalizedString(@"upload.videoTitleCell.label", @"Video Label");
                break;
                
            default:
                break;
        }
        
        previewCell.textLabel.text = previewCellLabelTitle;
        
        CGSize documentNameSize  = [self.documentURL.lastPathComponent sizeWithFont:nameTextField.font];
        CGSize previewCellSize = previewCell.frame.size;
        CGSize documentIconImageViewSize = CGSizeMake(documentIconWidth, documentIconHeight);
        CGSize previewCellLabelSize = [previewCellLabelTitle sizeWithFont:nameTextField.font];
        CGFloat nameFieldMaxWidth = tableView.frame.size.width - previewCellLabelSize.width - documentIconImageViewSize.width - indentation * 4;

        documentNameSize.width = fminf(documentNameSize.width, nameFieldMaxWidth);
        
        UITextField *documentTitleField = [[UITextField alloc] initWithFrame:CGRectMake(previewCellSize.width - (documentNameSize.width + rightPadding),
                                                                                        topBottomPadding,
                                                                                        documentNameSize.width,
                                                                                        nameCell.frame.size.height - (topBottomPadding * 2))];
        documentTitleField.text = self.documentURL.lastPathComponent;
        documentTitleField.enabled = NO;
        documentTitleField.textAlignment = NSTextAlignmentRight;
        documentTitleField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        
        UIImageView *documentIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(documentTitleField.frame.origin.x - documentIconImageViewSize.width,
                                                                                           topBottomPadding / 2,
                                                                                           documentIconImageViewSize.width,
                                                                                           documentIconImageViewSize.height)];
        documentIconImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        documentIconImageView.image = imageForType(self.documentURL.pathExtension);
        
        [previewCell.contentView addSubview:documentTitleField];
        [previewCell.contentView addSubview:documentIconImageView];
    }
    else if (self.uploadFormType == UploadFormTypeAudio)
    {
        CGFloat buttonStartPosition = 100.0f;
        CGFloat audioButtonHeight = 30.0f;
        CGFloat audioButtonWidth = 90.0f;
        
        // create a configure audio cell
        previewCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        previewCell.frame = CGRectMake(0,
                                       0,
                                       320,
                                       (topBottomPadding * 2) + audioButtonHeight);
        previewCell.textLabel.text = NSLocalizedString(@"upload.audio.cell.label", @"Audio Title");
        previewCell.accessoryType = UITableViewCellAccessoryNone;
        // record button
        UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        recordButton.frame = CGRectMake(buttonStartPosition,
                                        topBottomPadding,
                                        audioButtonWidth,
                                        audioButtonHeight);
        [recordButton setTitle:NSLocalizedString(@"upload.audio.cell.button.record", @"Record Button Text") forState:UIControlStateNormal];
        [recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        recordButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [previewCell addSubview:recordButton];
        self.recordButton = recordButton;
        // play button
        UIButton *playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        playButton.frame = CGRectMake((buttonStartPosition + audioButtonWidth + topBottomPadding),
                                      topBottomPadding,
                                      audioButtonWidth,
                                      audioButtonHeight);
        [playButton setTitle:NSLocalizedString(@"upload.audio.cell.button.play", @"Play Button Text") forState:UIControlStateNormal];
        [playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        playButton.enabled = NO;
        playButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
        [previewCell addSubview:playButton];
        self.playButton = playButton;
    }
    
    // IMPORTANT: If changing the number or order of these cells, be sure to update the UploadFormCellTypes enum definition to match
    self.cells = @[nameCell, tagsCell, previewCell];
    
    // add a touch event
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tapGesture.delegate = self;
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:tapGesture];
    
    view.autoresizesSubviews = YES;
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = [self titleForUploadForm];
    
    UIBarButtonItem *uploadButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload", @"Upload")
                                                                     style:UIBarButtonItemStyleDone
                                                                    target:self
                                                                    action:@selector(uploadDocument:)];
    
    uploadButton.enabled = (self.documentURL.lastPathComponent.length > 0) ? YES : NO;
    [self.navigationItem setRightBarButtonItem:uploadButton];
    self.uploadButton = uploadButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel Button")
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(closeUploadForm:)];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.nameTextField];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.nameTextField.text.length == 0)
    {
        [self.nameTextField becomeFirstResponder];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.cells objectAtIndex:indexPath.row];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [(UITableViewCell *)[self.cells objectAtIndex:indexPath.row] frame].size.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (selectedCell == [self.cells objectAtIndex:UploadFormCellTypeTags])
    {
        TagPickerViewController *tagPickerController = [[TagPickerViewController alloc] initWithSelectedTags:self.tagsToApplyToDocument session:self.session delegate:self];
        [self.navigationController pushViewController:tagPickerController animated:YES];
    }
}

#pragma mark - Private Functions

- (NSString *)titleForUploadForm
{
    NSString *title = nil;
    
    switch (self.uploadFormType)
    {
        case UploadFormTypeImageCreated:
        case UploadFormTypeImagePhotoLibrary:
        {
            title = NSLocalizedString(@"upload.photo.title", @"Upload Form Title - Photo");
        }
        break;
            
        case UploadFormTypeDocument:
        {
            title = NSLocalizedString(@"upload.document.title", @"Upload Form Title - Document");
        }
        break;
        
        case UploadFormTypeVideoCreated:
        case UploadFormTypeVideoPhotoLibrary:
        {
            title = NSLocalizedString(@"upload.video.title", @"Upload Form Title - Video");
        }
        break;
            
        case UploadFormTypeAudio:
        {
            title = NSLocalizedString(@"upload.audio.title", @"Upload Form Title - Audio");
        }
        break;
            
        default:
            break;
    }
    
    return title;
}

- (void)recordButtonPressed:(id)sender
{
    if (self.audioRecorder.isRecording)
    {
        [self.audioRecorder stop];
        
        NSError *sessionPlaybackError = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&sessionPlaybackError];
        
        if (sessionPlaybackError)
        {
            AlfrescoLogError(@"AVAudioSession setting back to Playback", [sessionPlaybackError localizedDescription]);
        }
        
        [self updateButton:self.recordButton withText:NSLocalizedString(@"upload.audio.cell.button.record", @"Record Button") forControlState:UIControlStateNormal];
        self.playButton.enabled = YES;
    }
    else
    {
        NSError *error = nil;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];
        
        if (error)
        {
            AlfrescoLogError(@"Audio Session Error: %@", error.localizedDescription);
            return;
        }
        
        NSString *recordPath = [NSTemporaryDirectory() stringByAppendingPathComponent:(NSString *)kAudioFileName];
        
        NSDictionary *recordSettings = @{AVSampleRateKey : [NSNumber numberWithFloat:44100.0],
                                         AVFormatIDKey : [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
                                         AVNumberOfChannelsKey : [NSNumber numberWithInt:1],
                                         AVEncoderAudioQualityKey : [NSNumber numberWithInt:AVAudioQualityMax]};
        
        AVAudioRecorder *newRecorder = [[AVAudioRecorder alloc] initWithURL:[NSURL fileURLWithPath:recordPath] settings:recordSettings error:&error];
        
        self.audioRecorder = newRecorder;
        
        if (error)
        {
            AlfrescoLogError(@"Error trying to record audio: %@", error.description);
            [[AVAudioSession sharedInstance] setActive:NO error:nil];
        }
        else
        {
            self.audioRecorder.delegate = self;
            [self.audioRecorder prepareToRecord];
            [self.audioRecorder record];
            
            self.playButton.enabled = NO;
            
            [self updateButton:self.recordButton withText:NSLocalizedString(@"upload.audio.cell.button.stop", @"Stop Recording") forControlState:UIControlStateNormal];
        }
    }
}

- (void)playButtonPressed:(id)sender
{
    NSString *filePathString = [NSTemporaryDirectory() stringByAppendingPathComponent:(NSString *)kAudioFileName];
    
    if (self.audioPlayer.isPlaying)
    {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
        
        NSError *sessionInactiveError = nil;
        [[AVAudioSession sharedInstance] setActive:NO error:&sessionInactiveError];
        
        if (sessionInactiveError)
        {
            AlfrescoLogError(@"AVAudioSession inactive error: %@", [sessionInactiveError localizedDescription]);
        }
        
        [self updateButton:self.playButton withText:NSLocalizedString(@"upload.audio.cell.button.play", @"Play Button") forControlState:UIControlStateNormal];
        self.recordButton.enabled = YES;
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:filePathString])
    {
        NSError *playbackSessionError = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&playbackSessionError];
        
        if(playbackSessionError)
        {
            AlfrescoLogError(@"Audio Session Error: %@", [playbackSessionError localizedDescription]);
            self.playButton.enabled = YES;
            return;
        }
        
        NSError *playerCreationError = nil;
        AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePathString] error:&playerCreationError];
        player.delegate = self;
        self.audioPlayer = player;
        
        if (playerCreationError)
        {
            AlfrescoLogError(@"Error creating the player: %@", [playerCreationError localizedDescription]);
        }
        else
        {
            [self updateButton:self.playButton withText:NSLocalizedString(@"upload.audio.cell.button.stop", @"Stop Button") forControlState:UIControlStateNormal];
            self.recordButton.enabled = NO;
            [self.audioPlayer play];
        }
    }
}

- (BOOL)audioReadyForUpload
{
    if (self.audioRecorder && !self.audioRecorder.isRecording)
    {
        return YES;
    }
    return NO;
}

- (void)removeAudioFileFromDefaultFileSystem
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *pathToFileOnDefaultFileSystem = [NSTemporaryDirectory() stringByAppendingPathComponent:(NSString *)kAudioFileName];
    
    if ([fileManager fileExistsAtPath:pathToFileOnDefaultFileSystem])
    {
        NSError *fileDeletionError = nil;
        [fileManager removeItemAtPath:pathToFileOnDefaultFileSystem error:&fileDeletionError];
        
        if (fileDeletionError)
        {
            AlfrescoLogError(@"Audio Deletion Error: %@", [fileDeletionError localizedDescription]);
        }
    }
}

- (NSData *)dataFromImage:(UIImage *)image metadata:(NSDictionary *)metadata mimetype:(NSString *)mimetype
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
        CGImageDestinationAddImage(imageDataDestination, image.CGImage, (__bridge CFDictionaryRef)metadata);
        
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

- (void)uploadDocument:(NSString *)name completionBlock:(void (^)(BOOL filenameExistsInParentFolder))completionBlock
{
    __weak UploadFormViewController *weakSelf = self;
        
    // name of the file to be uploaded
    NSString *documentNameWithPathExtension = name;
    // Default mimeType: binary
    NSString *mimeType = @"application/octet-stream";
    
    if (weakSelf.fileExtension != nil && ![weakSelf.fileExtension isEqualToString:@""])
    {
        documentNameWithPathExtension = [NSString stringWithFormat:@"%@.%@", name, weakSelf.fileExtension];
        mimeType = [Utility mimeTypeForFileExtension:weakSelf.fileExtension];
    }
    
    // create the content file
    AlfrescoContentFile *contentFile = nil;
    
    if (weakSelf.uploadFormType == UploadFormTypeImageCreated || weakSelf.uploadFormType == UploadFormTypeImagePhotoLibrary)
    {
        contentFile = [[AlfrescoContentFile alloc] initWithData:[weakSelf dataFromImage:weakSelf.imageToUpload metadata:weakSelf.metadata mimetype:mimeType] mimeType:mimeType];
    }
    else
    {
        contentFile = [[AlfrescoContentFile alloc] initWithUrl:weakSelf.documentURL];
    }
    
    // create the read stream
    NSString *pathToTempFile = [contentFile.fileUrl path];
    NSInputStream *readStream = [[AlfrescoFileManager sharedManager] inputStreamWithFilePath:pathToTempFile];
    
    [weakSelf showHUD];
    AlfrescoContentStream *contentStream = [[AlfrescoContentStream alloc] initWithStream:readStream mimeType:mimeType length:contentFile.length];
    
    [weakSelf.documentService createDocumentWithName:documentNameWithPathExtension inParentFolder:weakSelf.uploadToFolder contentStream:contentStream properties:nil aspects:nil completionBlock:^(AlfrescoDocument *document, NSError *error) {
        if (document)
        {
            NSError *deleteAfterUploadError = nil;
            [[AlfrescoFileManager sharedManager] removeItemAtPath:pathToTempFile error:&deleteAfterUploadError];
            
            if (deleteAfterUploadError)
            {
                AlfrescoLogError(@"Error deleting file after upload: %@", [ErrorDescriptions descriptionForError:error]);
            }
            
            if (self.tagsToApplyToDocument)
            {
                [weakSelf showHUD];
                [weakSelf.tagService addTags:weakSelf.tagsToApplyToDocument toNode:document completionBlock:^(BOOL succeeded, NSError *error) {
                    [weakSelf hideHUD];
                    if (succeeded)
                    {
                        [weakSelf dismissViewControllerAnimated:YES completion:^{
                            [weakSelf.delegate didFinishUploadingNode:document];
                        }];
                    }
                    else
                    {
                        // display error
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.upload.addtags.failed", @"Adding tags failed"), [ErrorDescriptions descriptionForError:error]]);
                    }
                }];
            }
            else
            {
                [weakSelf dismissViewControllerAnimated:YES completion:^{
                    [weakSelf.delegate didFinishUploadingNode:document];
                }];
            }
        }
        else
        {
            if ((error.code == kAlfrescoErrorCodeDocumentFolderNodeAlreadyExists || error.code == kAlfrescoErrorCodeDocumentFolder) && completionBlock != NULL)
            {
                completionBlock(YES);
                return;
            }
            else
            {
                // display error
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.upload.failed", @"Upload failed"), [ErrorDescriptions descriptionForError:error]]);
            }
        }
        [weakSelf hideHUD];
        if (completionBlock != NULL)
        {
            completionBlock(NO);
        }
    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
        //
    }];
}

- (void)uploadDocument:(id)sender
{
    UIBarButtonItem *uploadButton = (UIBarButtonItem *)sender;
    uploadButton.enabled = NO;
    __block NSString *documentName = [[self.nameTextField.text stringByDeletingPathExtension] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self uploadDocument:documentName completionBlock:^(BOOL filenameExistsInParentFolder) {
        uploadButton.enabled = YES;
        if (filenameExistsInParentFolder)
        {
            documentName = fileNameAppendedWithDate(documentName);
            [self uploadDocument:documentName completionBlock:nil];
        }
    }];
}

- (void)dismissKeyboard
{
    [self.activeTextField resignFirstResponder];
}

- (void)closeUploadForm:(id)sender
{
    if ([self shouldConfirmDismissalOfModalViewController])
    {
        UIAlertView *confirmationAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"upload.confirm.dismissal.title", @"Dismiss Title")
                                                                    message:NSLocalizedString(@"upload.confirm.dismissal.message", @"Dismissal Message")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"upload.confirm.dismissal.cancel", @"Cancel Upload")
                                                          otherButtonTitles:NSLocalizedString(@"Upload", @"Upload"), nil];
        [confirmationAlert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
            if (isCancelButton)
            {
                [self dismissViewControllerAnimated:YES completion:^{
                    [self.delegate didCancelUpload];
                }];
            }
        }];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:^{
            [self.delegate didCancelUpload];
        }];
    }
}

- (void)enableOrDisableUploadButton
{
    if (self.uploadFormType == UploadFormTypeAudio)
    {
        if (self.nameTextField.text.length > 0 && [self audioReadyForUpload])
        {
            self.uploadButton.enabled = YES;
        }
        else
        {
            self.uploadButton.enabled = NO;
        }
    }
    else if (self.nameTextField.text.length > 0)
    {
        self.uploadButton.enabled = YES;
    }
    else
    {
        self.uploadButton.enabled = NO;
    }
}

- (void)updateButton:(UIButton *)button withText:(NSString *)buttonText forControlState:(UIControlState)state
{
    [button setTitle:buttonText forState:state];
    [self enableOrDisableUploadButton];
    [button setNeedsDisplay];
}

- (BOOL)shouldConfirmDismissalOfModalViewController
{
    BOOL shouldConfirm = NO;
    
    switch (self.uploadFormType)
    {
        case UploadFormTypeImageCreated:
        case UploadFormTypeVideoCreated:
        {
            shouldConfirm = YES;
        }
        break;
            
        case UploadFormTypeAudio:
        {
            if (self.audioRecorder)
            {
                shouldConfirm = YES;
            }
        }
        break;
            
        case UploadFormTypeDocument:
        case UploadFormTypeImagePhotoLibrary:
        case UploadFormTypeVideoPhotoLibrary:
        break;
    }
    
    return shouldConfirm;
}

#pragma mark - TagPickerViewController delegate

- (void)didCompleteSelectingTags:(NSArray *)selectedTags
{
    // Update the tags label
    if (selectedTags.count > 0)
    {
        self.tagsLabel.text = [selectedTags componentsJoinedByString:@", "];
    }
    else
    {
        self.tagsLabel.text = NSLocalizedString(@"upload.photo.tagcell.textlabel.placeholder.text", @"No Tags");
    }
    
    self.tagsToApplyToDocument = selectedTags;
}

#pragma mark - UITextFieldDelegate Functions

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeTextField = nil;
}

- (void)textFieldDidChange:(NSNotification *)note
{
    [self enableOrDisableUploadButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self dismissKeyboard];
    return YES;
}

#pragma mark - UIGestureRecognizerDelegate Functions

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (![touch.view isKindOfClass:[UITableViewCell class]])
    {
        return NO;
    }
    return YES;
}

#pragma mark - AVAudioPlayerDelegate Functions

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (flag)
    {
        [self.playButton setTitle:NSLocalizedString(@"upload.audio.cell.button.play", @"Play Button") forState:UIControlStateNormal];
        self.audioPlayer = nil;
        self.recordButton.enabled = YES;
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    AlfrescoLogError(@"AVAudioPlayer decoder error: %@", [ErrorDescriptions descriptionForError:error]);
}

#pragma mark - AVAudioRecorderDelegate Functions

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    if (flag)
    {
        [self enableOrDisableUploadButton];
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    AlfrescoLogError(@"AVAudioRecorder decoder error: %@", [ErrorDescriptions descriptionForError:error]);
}

@end
