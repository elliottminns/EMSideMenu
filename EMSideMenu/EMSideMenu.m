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

const NSTimeInterval kSlideAnimationDuration = 0.20;
const CGFloat kMinScale = 0.61;
const CGFloat kMaxScale = 1.00;
const CGFloat k3DMaxXTranslation = 115;
const CGFloat k2DMaxXTranslation = 270;
const CGFloat kMaxZTranslation = 10;
const CGFloat kMaxDegrees = 32;
const CGFloat kMaxSidebarScale = 2.5;
const CGFloat kMaxBackgroundScale = 1.7;

@interface EMSideMenu()
@property (nonatomic, assign) CATransform3D contentOriginal, menuOpen, sideBarOpen, sideBarOriginal;
@property (nonatomic, assign) CGPoint originalPoint;
@property (nonatomic, assign) CGRect originFramePosition;
@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, assign) BOOL dragging;
@property (nonatomic, assign) CGFloat maxXTranslation;
@end

@implementation EMSideMenu

- (void)viewDidLoad {
    [super viewDidLoad];
    self.type = self.type;
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

    self.menuOpen = layerTransformation;
    self.shadowOffset = CGSizeZero;
    self.shadowRadius = 100.0f;
    self.shadowOpacity = 3.0;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.view layoutSubviews];
    
    if (!self.shadowOff) {
        self.contentContainer.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.contentContainer.layer.shadowOffset = self.shadowOffset;
        self.contentContainer.layer.shadowRadius = self.shadowRadius;
        self.contentContainer.layer.shadowOpacity = self.shadowOpacity;
        self.contentContainer.layer.masksToBounds = NO;
        self.contentContainer.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.contentView.bounds].CGPath;
        
        [self.view sendSubviewToBack:self.backgroundView];
    }
    
    if (self.type == kEMSideMenu3D) {
        self.sideMenuContainer.layer.zPosition = -1000;
        self.backgroundView.layer.zPosition = -1010;
        self.sideMenuContainer.alpha = 0.0f;
    }
    
    if (self.state == kStateMenu) {
        CGRect frame = self.originFramePosition;
        frame.origin.x += self.maxXTranslation;
        self.contentView.frame = frame;
    }
}

- (void)setType:(EMSideMenuType)type {
    _type = type;
    if (type == kEMSideMenu3D) {
        self.maxXTranslation = k3DMaxXTranslation;
    } else {
        self.maxXTranslation = k2DMaxXTranslation;
    }
}

- (void)showMenuView:(NSTimeInterval)duration {
    if (self.type == kEMSideMenu3D) {
        [self open3DAnimation:duration];
    } else {
        [self open2DAnimation:duration];
    }
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
    // set up an animation for the transition between the views
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.5];
    [animation setType:kCATransitionFade];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[self.contentContainer layer] addAnimation:animation forKey:@"SwitchToView1"];
    [self.contentViewController.view removeFromSuperview];
    /*
    for (UIView *subview in self.contentContainer.subviews) {
        if (subview && [subview isKindOfClass:[UIView class]]) {
            [subview removeFromSuperview];
        }
    }*/
    
    [self.contentContainer addSubview:newView];
    
    // Add autolayout.
    NSDictionary *views = NSDictionaryOfVariableBindings(newView);
    newView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[newView]-0-|" options:0 metrics:nil views:views]];
    [self.contentContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[newView]-0-|" options:0 metrics:nil views:views]];
    
    if (self.state == kStateMenu) {
        [self toggleMenu];
    }
}

- (void)replaceContentWithViewController:(UIViewController *)newController {
    Class currentClass = [self.contentViewController class];
    Class newClass = [newController class];
    
    if (currentClass == [UINavigationController class] && newClass == [UINavigationController class]) {
        currentClass = [((UINavigationController *)self.contentViewController).viewControllers.firstObject class];
        newClass = [((UINavigationController *)newController).viewControllers.firstObject class];
    }

    if (currentClass != newClass) {
        [self addChildViewController:newController];
        [self replaceContentWithView:newController.view];
        [self.contentViewController removeFromParentViewController];
        _contentViewController = newController;
    } else if (self.state == kStateMenu) {
        [self toggleMenu];
    }
}

- (IBAction)menuButtonPressed:(id)sender {
    [self toggleMenu];
}

- (void)hideMenuView:(NSTimeInterval)duration {
    
    if (self.type == kEMSideMenu3D) {
        [self close3DAnimation:duration];
    } else {
        [self close2DAnimation:duration];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {    
    if (touch.view.exclusiveTouch) {
        return NO;
    }
    
    // Loop through the parents of the view.
    UIView *view = touch.view;
    
    UIView *tableViewCell = view;
    while (tableViewCell && ![tableViewCell isKindOfClass:[UITableViewCell class]]) {
        tableViewCell = tableViewCell.superview;
    }
    
    if ([tableViewCell isKindOfClass:[UITableViewCell class]]) {
        // Find out if the view supports editing.
        return NO;
    }
    
    UIView *control = view;
    if ([control isKindOfClass:[UIControl class]] && ![control isKindOfClass:[UIButton class]]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint translation = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:gestureRecognizer.view];
    return fabs(translation.x) > fabs(translation.y);
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
        
        if (self.type == kEMSideMenu3D) {
            CGFloat xTranslation = self.maxXTranslation * delta;
            CGFloat zTranslation = kMaxZTranslation * delta;
            CGFloat scale = kMaxScale - ((kMaxScale - kMinScale) * delta);
            CGFloat degrees = 0 - ((0 - kMaxDegrees) * delta);
            CGFloat menuAlpha = delta;
            CGFloat sidebarScale = kMaxSidebarScale - ((kMaxSidebarScale - 1.0) * delta);
            
            if (scale > kMaxScale) {
                scale = kMaxScale;
            }
            
            if (xTranslation > self.maxXTranslation) {
                xTranslation = self.maxXTranslation;
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
        } else {
            CGFloat xTranslation = self.maxXTranslation * delta;
            CGRect frame = self.originFramePosition;
            frame.origin.x += xTranslation;
            self.contentView.frame = frame;
        }
        
        if (self.menuDelegate &&
            [self.menuDelegate respondsToSelector:@selector(menuView:isPanning:)]) {
            [self.menuDelegate menuView:self isPanning:delta];
        }
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

#pragma mark - Animations

- (void)open3DAnimation:(NSTimeInterval)duration {
    if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuViewWillOpen:)]) {
        [self.menuDelegate menuViewWillOpen:self];
    }
    CALayer *layer = self.contentView.layer;
    
    self.state = kStateAnimating;
    self.contentContainer.userInteractionEnabled = NO;
    
    CGRect frame = self.originFramePosition;
    frame.origin.x += self.maxXTranslation;
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

- (void)close3DAnimation:(NSTimeInterval)duration {
    if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuViewWillClose:)]) {
        [self.menuDelegate menuViewWillClose:self];
    }
    CALayer *layer = self.contentView.layer;
    self.state = kStateAnimating;
    CGRect frame = self.contentView.frame;
    frame.origin.x -= self.maxXTranslation;
    self.contentContainer.userInteractionEnabled = YES;
    
    if (!self.dragging) {
        self.sideMenuContainer.layer.transform = CATransform3DIdentity;
    }
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:0
                     animations:^{
                         if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuViewAnimatingOpen:)]) {
                             [self.menuDelegate menuViewAnimatingOpen:self];
                         }
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

- (void)open2DAnimation:(NSTimeInterval)duration {
    if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuViewWillOpen:)]) {
        [self.menuDelegate menuViewWillOpen:self];
    }
    self.state = kStateAnimating;
    self.contentContainer.userInteractionEnabled = NO;
    
    CGRect frame = self.originFramePosition;
    frame.origin.x += self.maxXTranslation;
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:0
                     animations:^{
                         if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuViewAnimatingOpen:)]) {
                             [self.menuDelegate menuViewAnimatingOpen:self];
                         }
                         self.contentView.frame = frame;
                         self.sideMenuContainer.alpha = 1.0f;
                     } completion:^(BOOL finished) {
                         self.state = kStateMenu;
                         [self.contentView addGestureRecognizer:self.tap];
                     }];
}

- (void)close2DAnimation:(NSTimeInterval)duration {
    if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuViewWillClose:)]) {
        [self.menuDelegate menuViewWillClose:self];
    }
    self.state = kStateAnimating;
    CGRect frame = self.contentView.frame;
    frame.origin.x -= self.maxXTranslation;
    self.contentContainer.userInteractionEnabled = YES;
    
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:0
                     animations:^{
                         if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuViewAnimatingClose:)]) {
                             [self.menuDelegate menuViewAnimatingClose:self];
                         }
                         self.contentView.frame = self.originFramePosition;
                     } completion:^(BOOL finished) {
                         self.state = kStateContent;
                         [self.contentView removeGestureRecognizer:self.tap];
                         if (self.menuDelegate && [self.menuDelegate respondsToSelector:@selector(menuViewDidClose:)]) {
                             [self.menuDelegate menuViewDidClose:self];
                         }
                     }];
}

@end
