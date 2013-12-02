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

Coming soon...

### Manual Installation

All you need to do is drop 'EMSideMenu' files into your project, and add `#include "EMSideMenu.h"` to the top of classes that will use it.

## Example Usage

Create a root or main view controller which will act as the container for the content and the menu, this view controller should inherit from EMSideMenu. To set the content view use either:

```objective-c
- (void)replaceContentWithView:(UIView *)newView;
```

or

```objective-c
- (void)replaceContentWithViewController:(UIViewController *)newController;
```

depending on your preferred set up.

To add the Side Menu to the container add it as a subview to the EMSideMenu's attribute, example:

```objective-c
 [self.sideMenuContainer addSubview:menuViewController.view];
```

finally to show or hide the SideMenu, call the toggle menu method of the sideMenu

```objective-c
[self toggleMenu];
```

