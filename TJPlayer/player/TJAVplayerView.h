//
//  TJAVplayerView.h
//  TJPlayer
//
//  Created by YangTengJiao on 2019/7/24.
//  Copyright © 2019 YangTengJiao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "TJAVplayerViewDelegate.h"
#import "TJAVPlayerControlView.h"
NS_ASSUME_NONNULL_BEGIN

@interface TJAVplayerView : UIView
@property (nonatomic, weak) id <TJAVplayerViewDelegate> delegate;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayer *avPlayer;

@property (nonatomic, strong) TJAVPlayerControlView *controlView;


- (void)settingPlayerItemWithUrl:(NSURL *)playerUrl;

@end

NS_ASSUME_NONNULL_END
