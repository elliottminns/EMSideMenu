EMSideMenu
==========

A configurable side menu for iOS

## Requirements
* Xcode 5 or higher
* Apple LLVM compiler
* iOS 7.0 or higher
* ARC

## Installation

### Cocoapods

To install via Cocoapods, add the following line to your Podfile.

``
pod 'EMSideMenu'
``

### Manual Installation

All you need to do is drop 'EMSideMenu' files into your project, and add `#include "EMSideMenu.h"` to the top of classes that will use it.

## Example Usage

Create a view controller which inherits from EMSideMenu, this will act as the container for the content and the menu. That's all for a basic use case! 

To change or add a new view as the current content view one of two methods.
   
```objective-c
- (void)replaceContentWithView:(UIView *)newView;
```

This will add the newView parameter to the content view or

```objective-c
- (void)replaceContentWithViewController:(UIViewController *)newController;
```

which will take the view property for the newController and set it as the content view, this also adds the viewController as a child view controller to the EMSideMenu.

To add the Side Menu to the container add it as a subview to the EMSideMenu's attribute or replace it entirely, example:

```objective-c
 [self.sideMenuContainer addSubview:menuViewController.view];
```

To show or hide the SideMenu, call the toggle menu method of the sideMenu.

```objective-c
[self toggleMenu];
```

## Other properties

* Shadow - This is toggled using the shadowOn property. Does what it says on the tin.
