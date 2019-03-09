//
//  WXAudioModule.m
//  AFNetworking
//
//  Created by 郑江荣 on 2019/3/4.
//

#import "WXAudioModule.h"
#import <WeexPluginLoader/WeexPluginLoader.h>
#import "audio.h"
#import <FSAudioStream.h>

WX_PlUGIN_EXPORT_MODULE(audio, WXAudioModule)
@implementation WXAudioModule
WX_EXPORT_METHOD(@selector(play:))
WX_EXPORT_METHOD(@selector(pause))
WX_EXPORT_METHOD(@selector(stop))
WX_EXPORT_METHOD(@selector(seek:))
WX_EXPORT_METHOD_SYNC(@selector(isPlay))
WX_EXPORT_METHOD(@selector(volume:))
WX_EXPORT_METHOD(@selector(loop:))
WX_EXPORT_METHOD(@selector(setOnPrepared:))
WX_EXPORT_METHOD(@selector(setOnPlaying:))
WX_EXPORT_METHOD(@selector(setOnCompletion:))
WX_EXPORT_METHOD(@selector(setOnError:))
WX_EXPORT_METHOD(@selector(setOnStartPlay:))




-(void)play:(NSString*)url{
    if(![self.url isEqualToString:url]){
        self.url=url;
         [[audio sharedManager] playFromURL:[NSURL URLWithString:url]];
    }else{
        if (![audio sharedManager].isPlaying) {
            [[audio sharedManager] pause];
        }
    }
    [self addListener];
 
}

-(void)addListener{
    
    
    __weak typeof (self) weakself=self;
    [audio sharedManager].onStateChange = ^(FSAudioStreamState state) {
        if(state==kFsAudioStreamPlaying){
            //           [audio sharedManager].currentTimePlayed
            [weakself releaseTimer];
            _timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:weakself
                                                    selector:@selector(updateProcess)
                                                    userInfo:nil
                                                     repeats:YES];
            [_timer fire];
            if(weakself.onStartPlay){
                weakself.onStartPlay(@{}, true);
            }
          
        } if(state==kFsAudioStreamPlaybackCompleted){
            if(self.loop){
                [self play:self.url];
            }
        }
        
    };
    
  
}

-(void)updateProcess{
    
    if([audio sharedManager].isPlaying){
        
        unsigned current=([audio sharedManager].currentTimePlayed.minute*60+[audio sharedManager].currentTimePlayed.second)*1000;
        unsigned total=([audio sharedManager].duration.minute*60+[audio sharedManager].duration.second)*1000;
        float percent=(float)current/total;
        if(self.onPlaying)
            _onPlaying(@{@"current":@(current),@"total": @(total),@"percent":@(percent)},true);

    }
    
}

-(void)pause{
    if ([audio sharedManager].isPlaying) {
        [[audio sharedManager] pause];
    }
}

-(void)stop{
    self.url=nil;
     [self releaseTimer];
     [[audio sharedManager] stop];
}

-(void)seek:(float)time{
    
    FSStreamPosition position;
    // 赋值
    position.position = time;
    // 跳转进度
    [[audio sharedManager] seekToPosition:position];
}

-(BOOL)isPlay{
    return [audio sharedManager].isPlaying;
}

-(void)volume:(float)time{
    [audio sharedManager].volume=time;
}

-(void)loop:(BOOL)loop{
    self.loop=loop;
}
-(void)setOnStartPlay:(WXModuleKeepAliveCallback)callback{
    self.onStartPlay=callback;
}
-(void)setOnPrepared:(WXModuleKeepAliveCallback)callback{
    self.onPrepared=callback;
}
-(void)setOnPlaying:(WXModuleKeepAliveCallback)callback{
    _onPlaying=callback;
}
-(void)setOnCompletion:(WXModuleKeepAliveCallback)callback{
    
    __weak typeof (self) weakself=self;
    [audio sharedManager].onCompletion = ^{
        weakself.url=nil;
        [weakself releaseTimer];
        callback(@{},true);
    };
}

-(void)setOnError:(WXModuleKeepAliveCallback)callback{
    [audio sharedManager].onFailure = ^(FSAudioStreamError error, NSString *errorDescription) {
        callback(@{},true);
    };
}

-(void)releaseTimer{
    if (_timer) {
        if ([_timer isValid]) {
            [_timer invalidate];
            _timer = nil;
        }
    }
}

- (void)dealloc {
    [self releaseTimer];
}


@end
