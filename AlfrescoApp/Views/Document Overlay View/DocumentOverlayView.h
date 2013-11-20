//
//  DocumentOverlay.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 20/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DocumentOverlayView;

@protocol DocumentOverlayDelegate <NSObject>

- (void)documentOverlay:(DocumentOverlayView *)documentOverlayView didPressCloseDocumentButton:(UIButton *)closeButton;
- (void)documentOverlay:(id)documentOverlayView didPressExpandCollapseButton:(UIButton *)expandCollapseButton;

@end

@interface DocumentOverlayView : UIView

@property (nonatomic, assign, readonly) BOOL isShowing;
@property (nonatomic, weak) id<DocumentOverlayDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame delegate:(id<DocumentOverlayDelegate>)delegate displayCloseButton:(BOOL)displayCloseButton displayExpandButton:(BOOL)displayExpandButton;
- (void)show;
- (void)hide;
- (void)toggleCloseButtonVisibility;

@end
