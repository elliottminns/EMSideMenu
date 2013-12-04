//
//  ViewController.m
//  EMSideMenuSample
//
//  Created by Elliott Minns on 03/12/2013.
//  Copyright (c) 2013 elliottminns. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.contentView.backgroundColor = [UIColor redColor];
    self.sideMenuContainer.backgroundColor = [UIColor yellowColor];
    self.backgroundView.backgroundColor = [UIColor orangeColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
