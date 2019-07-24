//
//  TJAVplayerViewDelegate.h
//  TJPlayer
//
//  Created by YangTengJiao on 2019/7/24.
//  Copyright © 2019 YangTengJiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
@class TJAVplayerView;

@protocol TJAVplayerViewDelegate <NSObject>

- (void)TJPlayerStausChange:(TJAVplayerView *)playerView playStatus:(AVPlayerItemStatus )status;

- (void)TJPlayerPlayFinished:(TJAVplayerView *)playerView;

- (void)TJPlayerViewSelected:(TJAVplayerView *)playerView selectType:(NSString *)type;


@end

NS_ASSUME_NONNULL_END
