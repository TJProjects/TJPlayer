//
//  TJAVplayerView.m
//  TJPlayer
//
//  Created by YangTengJiao on 2019/7/24.
//  Copyright © 2019 YangTengJiao. All rights reserved.
//

#import "TJAVplayerView.h"

@interface TJAVplayerView()
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation TJAVplayerView

- (instancetype)init
{
    if (self = [super init]) {
        // 让view的layerClass为AVPlayerLayer类，那么self.layer就为AVPlayerLayer的实例
        self.playerLayer = (AVPlayerLayer *)self.layer;
        self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
        // 初始化playerLayer的player
        self.playerLayer.player = self.avPlayer;
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self setupNotification];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 让view的layerClass为AVPlayerLayer类，那么self.layer就为AVPlayerLayer的实例
        self.playerLayer = (AVPlayerLayer *)self.layer;
        self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
        // 初始化playerLayer的player
        self.playerLayer.player = self.avPlayer;
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self setupNotification];
    }
    return self;
}
- (AVPlayer *)avPlayer
{
    if (!_avPlayer) {
        _avPlayer = [[AVPlayer alloc] init];
        // 设置默认音量
        //        _avPlayer.volume = 0.5;
        // 获取系统声音
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        float oldVolume = 0.5;
        if (audioSession.outputVolume > 0) {
            oldVolume = audioSession.outputVolume;
        } else {
            oldVolume = 0.5;
        }
        _avPlayer.volume = oldVolume;
    }
    return _avPlayer;
}
+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (void)setupNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}/**
  *    即将进入后台的处理
  */
- (void)applicationWillEnterForeground {
    [self play];
}

/**
 *    即将返回前台的处理
 */
- (void)applicationWillResignActive {
    [self pause];
}
- (void)settingPlayerItemWithUrl:(NSURL *)playerUrl
{
    [self settingPlayerItem:[[AVPlayerItem alloc] initWithURL:playerUrl]];
}

- (void)settingPlayerItem:(AVPlayerItem *)playerItem
{
    _playerItem = playerItem;
    [self removeObserver];
    [self pause];
    /*
     replaceCurrentItemWithPlayerItem: 用于切换视频
     */
    // 设置当前playerItem
    [self.avPlayer replaceCurrentItemWithPlayerItem:playerItem];
    [self addObserver];
    
    [self settingControlUI];
}
- (void)settingControlUI
{
    self.activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self addSubview:self.activityIndicator];
    //设置小菊花的frame
    self.activityIndicator.frame= CGRectMake(self.bounds.size.width/2.0-50, self.bounds.size.height/2.0-50, 100, 100);
    //设置小菊花颜色
    self.activityIndicator.color = [UIColor whiteColor];
    //设置背景颜色
    self.activityIndicator.backgroundColor = [UIColor clearColor];
    [self.activityIndicator startAnimating];
    
    self.controlView = [[TJAVPlayerControlView alloc] initWithFrame:self.bounds];
    __weak typeof(self) weakSelf = self;
    self.controlView.controlViewBlock = ^(NSString *type,NSString *info) {
        if ([type isEqualToString:@"play"]) {
            [weakSelf play];
        } else if ([type isEqualToString:@"pause"]) {
            [weakSelf pause];
        } else if ([type isEqualToString:@"back"]) {
            [weakSelf removeSelf];
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(TJPlayerViewSelected:selectType:)]) {
                [weakSelf.delegate TJPlayerViewSelected:weakSelf selectType:@"back"];
            }
        } else if ([type isEqualToString:@"slip"]) {
            float progress = [info floatValue];
            float time = progress*CMTimeGetSeconds(weakSelf.playerItem.duration);
            [weakSelf.playerItem seekToTime:CMTimeMake(time, 1.0) completionHandler:^(BOOL finished) {
                if (finished) {
                    weakSelf.controlView.isSliping = NO;
                }
            }];
        } else {
            
        }
    };
    [self addSubview:self.controlView];
}
- (void)addObserver{
    // 监控它的status也可以获得播放状态
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    //监控缓冲加载
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    //监控播放完成
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    //监控时间进度(根据API提示，如果要监控时间进度，这个对象引用计数器要+1，retain)
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        // 获取 item 当前播放秒
        float currentPlayTime = (double)weakSelf.avPlayer.currentItem.currentTime.value/ weakSelf.avPlayer.currentItem.currentTime.timescale;
        [weakSelf updateVideoSlider:currentPlayTime];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        // 播放状态
        AVPlayerItemStatus status = [[change objectForKey:@"new"] integerValue];
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                [self play];
                [self.activityIndicator stopAnimating];
            }
                break;
            case AVPlayerItemStatusFailed:
                NSLog(@"加载失败");
                [self.activityIndicator stopAnimating];
                break;
            case AVPlayerItemStatusUnknown:
                NSLog(@"未知资源");
                [self.activityIndicator stopAnimating];
                break;
            default:
                break;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(TJPlayerStausChange:playStatus:)]) {
            [self.delegate TJPlayerStausChange:self playStatus:status];
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        NSArray *array = playerItem.loadedTimeRanges;
        // 缓冲时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //缓冲总长度
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        [self updateVideoBufferProgress:totalBuffer];
    }
}
// 更新进度条时间
- (void)updateVideoSlider:(float)currentPlayTime
{
    CMTime duration = _playerItem.duration;
    [self.controlView showProgressWith:currentPlayTime duration:CMTimeGetSeconds(duration) progress:currentPlayTime / CMTimeGetSeconds(duration)];
    static float oldtime = 0;
    if (oldtime < currentPlayTime) {
        [self.activityIndicator stopAnimating];
    }
    oldtime = currentPlayTime;
}
// 更新缓冲进度
- (void)updateVideoBufferProgress:(NSTimeInterval)buffer
{
    CMTime duration = _playerItem.duration;
    [self.activityIndicator startAnimating];
    //    self.controlView.playerSilder.bufferValue = buffer / CMTimeGetSeconds(duration);
}
- (void)playFinished:(NSNotification *)notifi
{
    [self.playerItem seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        
    }];
    [self pause];
    if (self.delegate && [self.delegate respondsToSelector:@selector(TJPlayerPlayFinished:)]) {
        [self.delegate TJPlayerPlayFinished:self];
    }
}

- (void)play{
    [self.avPlayer play];
    [self.controlView showPlayView];
}

- (void)pause
{
    [self.avPlayer pause];
    [self.controlView showPauseView];
}

- (void)removeSelf {
    [self removeFromSuperview];
}
- (void)removeObserver
{
    // 移除监听 和通知
    // 监控它的status也可以获得播放状态
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    // 缓冲加载
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    // 播放完成
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.avPlayer removeTimeObserver:self.timeObserver];
}
- (void)dealloc
{
    [self removeObserver];
    // 注销通知
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _avPlayer = nil;
    NSLog(@"TJAVplayerView dealloc");
}

@end
