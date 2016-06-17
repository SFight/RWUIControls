//
//  ViewController.m
//  UIControlDevApp
//
//  Created by SongJinJie on 16/6/17.
//  Copyright © 2016年 SongJinJie. All rights reserved.
//

#import "ViewController.h"

#import <RWUIControls/RWUIControls.h>

@interface ViewController ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) RWKnobControl *rotationKnob;
@property (nonatomic, strong) RWRibbonView *ribbonView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create UIImageView
    CGRect frame = self.view.bounds;
    frame.size.height *= 2/3.0;
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectInset(frame, 0, 20)];
    self.imageView.image = [UIImage imageNamed:@"sampleImage.jpg"];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    // Create RWKnobControl
    frame.origin.y += frame.size.height;
    frame.size.height /= 2;
    frame.size.width  = frame.size.height;
    self.rotationKnob = [[RWKnobControl alloc] initWithFrame:CGRectInset(frame, 10, 10)];
    CGPoint center = self.rotationKnob.center;
    center.x = CGRectGetMidX(self.view.bounds);
    self.rotationKnob.center = center;
    [self.view addSubview:self.rotationKnob];
    
    // Set up config on RWKnobControl
    self.rotationKnob.minimumValue = -M_PI_4;
    self.rotationKnob.maximumValue = M_PI_4;
    [self.rotationKnob addTarget:self
                          action:@selector(rotationAngleChanged:)
                forControlEvents:UIControlEventValueChanged];
    
    // Creates a sample ribbon view
    // Create UIImageView
    frame = self.view.bounds;
    frame.size.height *= 2/3.0;
    self.ribbonView = [[RWRibbonView alloc] initWithFrame:CGRectInset(frame, 0, 20)];
    UIImageView *iv = [[UIImageView alloc] initWithFrame:self.ribbonView.bounds];
    iv.image = [UIImage imageNamed:@"sampleImage.jpg"];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    [self.ribbonView addSubview:iv];
    [self.view addSubview:self.ribbonView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 旋转图片
- (void)rotationAngleChanged:(id)sender
{
//    self.imageView.transform = CGAffineTransformMakeRotation(self.rotationKnob.value);
    self.ribbonView.transform = CGAffineTransformMakeRotation(self.rotationKnob.value);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
