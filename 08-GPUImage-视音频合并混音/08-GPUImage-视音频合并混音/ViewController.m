//
//  ViewController.m
//  08-GPUImage-视音频合并混音
//
//  Created by 黄进文 on 16/9/20.
//  Copyright © 2016年 evenCoder. All rights reserved.
//

#import "ViewController.h"
#import "GPUImage.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "TH/THImageMovieWriter.h"
#import "TH/THImageMovie.h"

@interface ViewController () {
    
    THImageMovie *jMovieOne;
    THImageMovie *jMovieTwo;
    GPUImageOutput<GPUImageInput> *jFilter;
    dispatch_group_t recordSyncingDispatchGroup;
}

@property (nonatomic, strong) UILabel *jLabel;

@property (nonatomic, strong) THImageMovieWriter *jMovieWriter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GPUImageView *jImageView = [[GPUImageView alloc] initWithFrame:self.view.bounds];
    self.view = jImageView;
    
    self.jLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 120, 45)];
    self.jLabel.textColor = [UIColor orangeColor];
    [self.view addSubview:self.jLabel];
    
    jFilter = [[GPUImageDissolveBlendFilter alloc] init];
    [(GPUImageDissolveBlendFilter *)jFilter setMix:0.5];
    
    // 获取视频
    NSURL *movieURL01 = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@".m4v"];
    jMovieOne = [[THImageMovie alloc] initWithURL:movieURL01];
    jMovieOne.runBenchmark = YES;
    jMovieOne.playAtActualSpeed = YES;
    
    NSURL *movieURL02 = [[NSBundle mainBundle] URLForResource:@"movie" withExtension:@".m4v"];
    jMovieTwo = [[THImageMovie alloc] initWithURL:movieURL02];
    jMovieTwo.runBenchmark = YES;
    jMovieTwo.playAtActualSpeed = YES;
    
    NSArray *jMovies = @[jMovieOne, jMovieTwo];
    
    // 合并保存视频路径
    NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"movies.m4v"];
    unlink([filePath UTF8String]); // 删除旧文件
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    // 保存视频
    self.jMovieWriter = [[THImageMovieWriter alloc] initWithMovieURL:fileURL size:CGSizeMake(720.0, 1280.0) movies:jMovies];
    
    // 响应链
    [jMovieOne addTarget:jFilter];
    [jMovieTwo addTarget:jFilter];
    // 显示到界面
    [jFilter addTarget:jImageView];
    [jFilter addTarget:self.jMovieWriter];
    
    [jMovieOne startProcessing];
    [jMovieTwo startProcessing];
    [self.jMovieWriter startRecording];
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [displayLink setPaused:NO];
    
    // 保存视频
    __weak typeof(self) weakSelf = self;
    [self.jMovieWriter setCompletionBlock:^{
        
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->jFilter removeTarget:strongSelf->_jMovieWriter];
        [strongSelf->jMovieOne endProcessing];
        [strongSelf->jMovieTwo endProcessing];
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(filePath)) {
            
            [library writeVideoAtPathToSavedPhotosAlbum:fileURL completionBlock:^(NSURL *assetURL, NSError *error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil
                                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil
                                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                    }

                });
            }];
        }
        else {
            NSLog(@"error msg)");
        }
    }];
}

- (void)updateProgress:(CADisplayLink *)link {
    
    self.jLabel.text = [NSString stringWithFormat:@"progress: %d%%", (int)(jMovieOne.progress * 100)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)printDuration:(NSURL *)url {
    
    NSDictionary *inputOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *inputAsset = [[AVURLAsset alloc] initWithURL:url options:inputOptions];
    
    [inputAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"tracks"] completionHandler:^{
        
        NSLog(@"movie: %@ duration: %.2f", url.lastPathComponent, CMTimeGetSeconds(inputAsset.duration));
    }];
}

- (void)setupAudioAssetReader {
    
    NSMutableArray *audioTracks = [NSMutableArray array];
    for (GPUImageMovie *movie in @[jMovieOne, jMovieTwo]) {
        
        AVAsset *asset = movie.asset;
        if (asset) {
            
            NSArray *_audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            if (_audioTracks.count > 0) {
                
                [audioTracks addObject:_audioTracks.firstObject];
            }
        }
    }
    NSLog(@"audioTracks: %@", audioTracks);
    
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    for (AVAssetTrack *track in audioTracks) {
        
        if (![track isKindOfClass:[NSNull class]]) {
            
            NSLog(@"track url: %@ duration: %.2f", track.asset, CMTimeGetSeconds(track.asset.duration));
            AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio                                   preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, track.asset.duration)
                                                ofTrack:track
                                                 atTime:kCMTimeZero error:nil];
        }
    }
    
    NSMutableArray *videoTracks = [NSMutableArray array];
    
    for(GPUImageMovie *movie in @[jMovieOne, jMovieTwo]){
        AVAsset *asset = movie.asset;
        if(asset){
            NSArray *_videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            if(_videoTracks.count > 0){
                [videoTracks addObject:_videoTracks.firstObject];
            }
        }
    }
    
    NSLog(@"videoTracks: %@", videoTracks);
    
    for(AVAssetTrack *track in videoTracks){
        if(![track isKindOfClass:[NSNull class]]){
            NSLog(@"track url: %@ duration: %.2f", track.asset, CMTimeGetSeconds(track.asset.duration));
            AVMutableCompositionTrack *compositionCommentaryTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo                                   preferredTrackID:kCMPersistentTrackID_Invalid];
            [compositionCommentaryTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, track.asset.duration)
                                                ofTrack:track
                                                 atTime:kCMTimeZero error:nil];
        }
    }
    // AVAudioMix *audioMix = [AVMutableAudioMix audioMix];
}

@end







































