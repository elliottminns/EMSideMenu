//
//  EMSideMenu.m
//  EMSideMenu
//
//  Created by Elliott Minns on 14/11/2013.
//  Copyright (c) 2013 Elliott Minns. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "EMSideMenu.h"

typedef enum {
    kStateContent,
    kStateMenu,
    kStateAnimating
} MenuState;

const NSTimeInterval kSlideAnimationDuration = 0.20;
const CGFloat kMinScale = 0.61;
const CGFloat kMaxScale = 1.00;
const CGFloat kMaxXTranslation = 115;
const CGFloat kMaxZTranslation = 10;
const CGFloat kMaxDegrees = 32;
const CGFloat kMaxSidebarScale = 2.5;
const CGFloat kMaxBackgroundScale = 1.7;

@interface EMSideMenu()
@property (nonatomic, assign) MenuState state;
@property (nonatomic, assign) CATransform3D contentOriginal, menuOpen, sideBarOpen, sideBarOriginal;
@property (nonatomic, assign) CGPoint originalPoint;
@property (nonatomic, assign) CGRect originFramePosition;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, assign) BOOL dragging;
@end

@implementation EMSideMenu

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialiseViews];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(contentPan:)];
    pan.delegate = self;
    pan.cancelsTouchesInView = NO;
    [self.contentView addGestureRecognizer:pan];
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentTap:)];
    
    self.contentOriginal = self.contentView.layer.transform;

    self.originFramePosition = self.contentView.frame;
    
    CATransform3D layerTransformation = CATransform3DIdentity;
    layerTransformation.m34 = 1.0 / -500;
    layerTransformation = CATransform3DRotate(layerTransformation, -kMaxDegrees * M_PI / 180.0f, 0.0f, 1.0f, 0.0f);
    layerTransformation = CATransform3DScale(layerTransformation, kMinScale, kMinScale, kMinScale);
    
    self.sideBarOriginal = self.sideMenuContainer.layer.transform;
    
    CATransform3D sideBarOpen = CATransform3DMakeScale(kMaxSidebarScale, kMaxSidebarScale, 1.0f);
    self.sideBarOpen = sideBarOpen;
    
    self.contentContainer.clipsToBounds = YES;
    self.sideMenuContainer.alpha = 0.0f;

    self.menuOpen = layerTransformation;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.view layoutSubviews];
    
    if (self.shadowsOn) {
        self.contentContainer.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.contentContainer.layer.shadowOffset = CGSizeMake(0, 0);
        self.contentContainer.layer.shadowRadius = 100.0f;
        self.contentContainer.layer.shadowOpacity = 1.0;
        self.contentContainer.layer.masksToBounds = NO;
        self.contentContainer.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.contentContainer.bounds].CGPath;
        self.contentContainer.layer.zPosition = 300;
    }
    [self.view sendSubviewToBack:self.backgroundView];
    self.sideMenuContainer.layer.zPosition = -1000;
    self.backgroundView.layer.zPosition = -1010;
}

- (void)initialiseViews {
    if (!self.sideMenuContainer) {
        self.sideMenuContainer = [[UIView alloc] initWithFrame:self.view.bounds];
        self.sideMenuContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.sideMenuContainer.backgroundColor = [UIColor clearColor];
        [self.view addSubview:self.sideMenuContainer];
    }
    
    if (!self.contentView) {
        self.contentView = [[UIView alloc] initWithFrame:self.view.bounds];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [self.view insertSubview:self.contentView aboveSubview:self.sideMenuContainer];
    }
    
    if (!self.contentContainer) {
        self.contentContainer = [[UIView alloc] initWithFrame:self.view.bounds];
        self.contentContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:self.contentContainer];
    }
    
    if (!self.backgroundView) {
        self.backgroundView = [[UIView alloc] initWithFrame:self.view.bounds];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    }
    
    if (!self.backgroundView.superview) {
        [self.view addSubview:self.backgroundView];
    }
}

- (void)showMenuView:(NSTimeInterval)duration {
    CALayer *layer = self.contentView.layer;
    
    self.state = kStateAnimating;
    self.contentContainer.userInteractionEnabled = NO;

    self.state = kStateMenu;
    CGRect frame = self.originFramePosition;
    frame.origin.x += kMaxXTranslation;
    if (!self.dragging) {
        self.sideMenuContainer.layer.transform = self.sideBarOpen;
    }
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:0
                     animations:^{
                         layer.transform = self.menuOpen;
                         self.contentView.frame = frame;
                         self.sideMenuContainer.alpha = 1.0f;
                         self.sideMenuContainer.layer.transform = CATransform3DIdentity;
                     } completion:^(BOOL finished) {
                         self.state = kStateMenu;
                         [self.contentView addGestureRecognizer:self.tap];
                         self.sideMenuContainer.layer.transform = CATransform3DIdentity;
                     }];
    
}

- (void)toggleMenu {
    switch (self.state) {
        case kStateContent:
            [self showMenuView:kSlideAnimationDuration];
            break;
        case kStateMenu:
            [self hideMenuView:kSlideAnimationDuration];
            break;
        default:
            break;
    }
}

- (void)setShadowsOn:(BOOL)shadowsOn {
    _shadowsOn = shadowsOn;
    [self.view setNeedsDisplay];
}

- (void)presentModalViewController:(UIViewController *)modalController {
    self.modalContentViewController = modalController;
    [self addChildViewController:self.modalContentViewController];
    [self.view addSubview:self.modalContentViewController.view];
}

- (void)dismissModalViewController {
    [self.modalContentViewController.view removeFromSuperview];
    [self.modalContentViewController removeFromParentViewController];
    self.modalContentViewController = nil;
}

- (void)replaceContentWithView:(UIView *)newView {
    [self initialiseViews];
    // set up an animation for the transition between the views
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.5];
    [animation setType:kCATransitionFade];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[self.contentContainer layer] addAnimation:animation forKey:@"SwitchToView1"];
    
    for (UIView *subview in self.contentContainer.subviews) {
        [subview removeFromSuperview];
    }
    
    [self.contentContainer addSubview:newView];
    
    if (self.state == kStateMenu) {
        [self toggleMenu];
    }
}

- (void)replaceContentWithViewController:(UIViewController *)newController {
    if ([self.contentViewController class] != [newController class]) {
        [self.contentViewController removeFromParentViewController];
        _contentViewController = newController;
        [self addChildViewController:newController];
        [self replaceContentWithView:self.contentViewController.view];
    } else if (self.state == kStateMenu) {
        [self toggleMenu];
    }
}

- (IBAction)menuButtonPressed:(id)sender {
    [self toggleMenu];
}

- (void)hideMenuView:(NSTimeInterval)duration {
    CALayer *layer = self.contentView.layer;
    self.state = kStateAnimating;
    CGRect frame = self.contentView.frame;
    frame.origin.x -= kMaxXTranslation;
    self.contentContainer.userInteractionEnabled = YES;
    
    if (!self.dragging) {
        self.sideMenuContainer.layer.transform = CATransform3DIdentity;
    }
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:0
                     animations:^{
                         layer.transform = CATransform3DIdentity;
                         self.contentView.frame = self.originFramePosition;
                         self.sideMenuContainer.alpha = 0;
                         self.sideMenuContainer.layer.transform = self.sideBarOpen;
                     } completion:^(BOOL finished) {
                         self.state = kStateContent;
                         [self.contentView removeGestureRecognizer:self.tap];
                         self.sideMenuContainer.layer.transform = CATransform3DIdentity;
                     }];
    
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {    
    if (touch.view.exclusiveTouch) {
        return NO;
    }
    
    return YES;
}


- (void)contentPan:(UIPanGestureRecognizer *)gr {
    CGPoint point = [gr translationInView:self.view];
    
    if (gr.state == UIGestureRecognizerStateBegan) {
        self.originalPoint = self.contentView.frame.origin;
        self.dragging = YES;
    }
    
    if (gr.state == UIGestureRecognizerStateBegan || gr.state == UIGestureRecognizerStateChanged) {
        CGFloat delta = (self.state == kStateMenu) ? (point.x + self.originalPoint.x) / self.originalPoint.x : point.x / self.view.frame.size.width;
        
        if (delta > 1.00) {
            delta = 1.00;
        }
        if (delta < 0.00) {
            delta = 0.00;
        }
        CGFloat xTranslation = kMaxXTranslation * delta;
        CGFloat zTranslation = kMaxZTranslation * delta;
        CGFloat scale = kMaxScale - ((kMaxScale - kMinScale) * delta);
        CGFloat degrees = 0 - ((0 - kMaxDegrees) * delta);
        CGFloat menuAlpha = delta;
        CGFloat sidebarScale = kMaxSidebarScale - ((kMaxSidebarScale - 1.0) * delta);
        
        if (scale > kMaxScale) {
            scale = kMaxScale;
        }
        
        if (xTranslation > kMaxXTranslation) {
            xTranslation = kMaxXTranslation;
        }
        
        if (zTranslation > kMaxZTranslation) {
            zTranslation = kMaxZTranslation;
        }
        
        if (degrees > kMaxDegrees) {
            degrees = kMaxDegrees;
        }
        
        CATransform3D layerTransformation = CATransform3DIdentity;
        layerTransformation.m34 = 1.0 / -500;
        layerTransformation = CATransform3DRotate(layerTransformation, -degrees * M_PI / 180.0f, 0.0f, 1.0f, 0.0f);
        layerTransformation = CATransform3DScale(layerTransformation, scale, scale, scale);
        CGRect frame = self.originFramePosition;
        frame.origin.x += xTranslation;
        self.contentView.frame = frame;
        CALayer *layer = self.contentView.layer;
        layer.transform = layerTransformation;
        self.sideMenuContainer.layer.transform = CATransform3DScale(CATransform3DIdentity, 2.5, 2.5, 1.0);
        self.sideMenuContainer.layer.transform = CATransform3DScale(CATransform3DIdentity, sidebarScale, sidebarScale, 1.0);
        self.sideMenuContainer.alpha = menuAlpha;
    }
    
    if (gr.state == UIGestureRecognizerStateEnded) {
        CGFloat delta = (self.state == kStateMenu) ? (point.x + self.originalPoint.x) / self.originalPoint.x : point.x / self.view.frame.size.width;
        NSTimeInterval duration = kSlideAnimationDuration;
        if (self.state == kStateContent && delta > 0.4) {
            [self showMenuView:duration];
        } else if (self.state == kStateContent) {
            [self hideMenuView:duration];
        } else if (self.state == kStateMenu && delta < 0.6) {
            [self hideMenuView:duration];
        } else if (self.state == kStateMenu) {
            [self showMenuView:duration];
        }
        self.dragging = NO;
    }
    
}

- (void)contentTap:(UITapGestureRecognizer *)gr {
    [self hideMenuView:kSlideAnimationDuration];
}

@end
