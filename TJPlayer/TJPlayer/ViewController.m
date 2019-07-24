//
//  ViewController.m
//  TJPlayer
//
//  Created by YangTengJiao on 2019/7/24.
//  Copyright © 2019 YangTengJiao. All rights reserved.
//

#import "ViewController.h"
#import "TJAVplayerView.h"

@interface ViewController () <TJAVplayerViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)playerTest:(id)sender {
    TJAVplayerView *playerView = [[TJAVplayerView alloc] initWithFrame:self.view.bounds];
    playerView.delegate = self;
    [self.view addSubview:playerView];
    NSString *moviePath = [[NSBundle mainBundle] pathForResource:@"guideVideo" ofType:@"mp4"];
    [playerView settingPlayerItemWithUrl:[NSURL fileURLWithPath:moviePath]];
    
}

- (void)TJPlayerStausChange:(TJAVplayerView *)playerView playStatus:(AVPlayerItemStatus)status {
    
}

- (void)TJPlayerPlayFinished:(TJAVplayerView *)playerView {
    NSLog(@"TJPlayerPlayFinished");
    [playerView removeFromSuperview];
}

@end
