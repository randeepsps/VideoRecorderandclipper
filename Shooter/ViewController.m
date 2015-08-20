//
//  ViewController.m
//  Shooter
//
//  Created by Geppy Parziale on 2/24/12.
//  Copyright (c) 2012 iNVASIVECODE, Inc. All rights reserved.
//

#import "ViewController.h"

float startTime;
float endTime;

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>
//- (CAAnimation *)animationForRotationX:(float)x Y:(float)y andZ:(float)z;
@end



@implementation ViewController
@synthesize PreviewLayer;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupCameraSession];
    
}

- (void)setupCameraSession
{    
    ICLog;
    
    // Session
    CaptureSession = [AVCaptureSession new];
    //[session setSessionPreset:AVCaptureSessionPreset1920x1080];
    [CaptureSession setSessionPreset:AVCaptureSessionPresetHigh];
    
    AVCaptureDevice *VideoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (VideoDevice)
    {
        NSError *error;
        VideoInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:VideoDevice error:&error];
        if (!error)
        {
            if ([CaptureSession canAddInput:VideoInputDevice])
                [CaptureSession addInput:VideoInputDevice];
            else
                NSLog(@"Couldn't add video input");
        }
        else
        {
            NSLog(@"Couldn't create video input");
        }
    }
    else
    {
        NSLog(@"Couldn't create video capture device");
    }
    
    //ADD AUDIO INPUT
    NSLog(@"Adding audio input");
    AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error];
    if (audioInput)
    {
        [CaptureSession addInput:audioInput];
    }
    
    //----- ADD OUTPUTS -----
    
    //ADD VIDEO PREVIEW LAYER
    NSLog(@"Adding video preview layer");
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:CaptureSession]];
    
    //PreviewLayer.orientation = AVCaptureVideoOrientationLandscapeRight;		//<<SET ORIENTATION.  You can deliberatly set this wrong to flip the image and may actually need to set it wrong to get the right image
    
    [[self PreviewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    //ADD MOVIE FILE OUTPUT
    NSLog(@"Adding movie file output");
    MovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    Float64 TotalSeconds = 60;			//Total seconds
    int32_t preferredTimeScale = 30;	//Frames per second
    CMTime maxDuration = CMTimeMakeWithSeconds(TotalSeconds, preferredTimeScale);	//<<SET MAX DURATION
    MovieFileOutput.maxRecordedDuration = maxDuration;
    
    MovieFileOutput.minFreeDiskSpaceLimit = 1024 * 1024;						//<<SET MIN FREE SPACE IN BYTES FOR RECORDING TO CONTINUE ON A VOLUME
    
    if ([CaptureSession canAddOutput:MovieFileOutput])
        [CaptureSession addOutput:MovieFileOutput];
    
    //SET THE CONNECTION PROPERTIES (output properties)
    [self CameraSetOutputProperties];			//(We call a method as it also has to be done after changing camera)

    NSLog(@"Setting image quality");
    [CaptureSession setSessionPreset:AVCaptureSessionPresetMedium];
    if ([CaptureSession canSetSessionPreset:AVCaptureSessionPreset640x480])		//Check size based configs are supported before setting them
        [CaptureSession setSessionPreset:AVCaptureSessionPreset640x480];
    
    //----- DISPLAY THE PREVIEW LAYER -----
    //Display it full screen under out view controller existing controls
    NSLog(@"Display the preview layer");
    CGRect layerRect = [[[self view] layer] bounds];
    [PreviewLayer setBounds:layerRect];
    [PreviewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),
                                          CGRectGetMidY(layerRect))];
    //[[[self view] layer] addSublayer:[[self CaptureManager] previewLayer]];
    //We use this instead so it goes on a layer behind our UI controls (avoids us having to manually bring each control to the front):
    UIView *CameraView = [[UIView alloc] init];
    [[self view] addSubview:CameraView];
    [self.view sendSubviewToBack:CameraView];
    
    [[CameraView layer] addSublayer:PreviewLayer];
    
    //----- START THE CAPTURE SESSION RUNNING -----
    [CaptureSession startRunning];
    
    UIButton *btnslice = [UIButton buttonWithType:UIButtonTypeCustom];
    btnslice.frame = CGRectMake(220, 480, 100, 40);
    [btnslice setTitle:@"Slice" forState:UIControlStateNormal];
    [btnslice addTarget:self action:@selector(slice) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnslice];
    
    UIButton *btnstart = [UIButton buttonWithType:UIButtonTypeCustom];
    btnstart.frame = CGRectMake(20, 480, 100, 40);
    [btnstart setTitle:@"Start/Stop" forState:UIControlStateNormal];
    [btnstart addTarget:self action:@selector(StartStopButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnstart];
    
    _lblRunningTime = [[UILabel alloc] initWithFrame:CGRectMake(15, 450, 100, 30)];
    [self.view addSubview:_lblRunningTime];
    
}

-(void)slice
{
   // NSDate *end = [NSDate date];
    // do stuff...
   // NSDate *minusTenSecs = [[NSDate date] dateByAddingTimeInterval:-1*10];
    
    NSString *strCurrTime = [NSString stringWithFormat:@"%02d:%02d", self.timeMin, self.timeSec];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"mm:ss"];
    NSDate *datee = [dateFormatter dateFromString:strCurrTime];
    [dateFormatter setDateFormat:@"ss"];
    NSString *strEndTime = [dateFormatter stringFromDate:datee];
    endTime = [strEndTime floatValue];
    //
    NSDate *minusTenSecs = [datee dateByAddingTimeInterval:-1*10];
    [dateFormatter setDateFormat:@"ss"];
    NSString *strStartTime = [dateFormatter stringFromDate:minusTenSecs];
    startTime = [strStartTime floatValue];
    
}

- (void) CameraSetOutputProperties
{
    //SET THE CONNECTION PROPERTIES (output properties)
    AVCaptureConnection *CaptureConnection = [MovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //Set landscape (if required)
    if ([CaptureConnection isVideoOrientationSupported])
    {
        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;		//<<<<<SET VIDEO ORIENTATION IF LANDSCAPE
        [CaptureConnection setVideoOrientation:orientation];
    }
    /*
    //Set frame rate (if requried)
    CMTimeShow(CaptureConnection.videoMinFrameDuration);
    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
    
    if (CaptureConnection.supportsVideoMinFrameDuration)
        CaptureConnection.videoMinFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
    if (CaptureConnection.supportsVideoMaxFrameDuration)
        CaptureConnection.videoMaxFrameDuration = CMTimeMake(1, CAPTURE_FRAMES_PER_SECOND);
    
    CMTimeShow(CaptureConnection.videoMinFrameDuration);
    CMTimeShow(CaptureConnection.videoMaxFrameDuration);
     */
}

//********** GET CAMERA IN SPECIFIED POSITION IF IT EXISTS **********
- (AVCaptureDevice *) CameraWithPosition:(AVCaptureDevicePosition) Position
{
    NSArray *Devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *Device in Devices)
    {
        if ([Device position] == Position)
        {
            return Device;
        }
    }
    return nil;
}

//********** CAMERA TOGGLE **********
- (IBAction)CameraToggleButtonPressed:(id)sender
{
    if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1)		//Only do if device has multiple cameras
    {
        NSLog(@"Toggle camera");
        NSError *error;
        //AVCaptureDeviceInput *videoInput = [self videoInput];
        AVCaptureDeviceInput *NewVideoInput;
        AVCaptureDevicePosition position = [[VideoInputDevice device] position];
        if (position == AVCaptureDevicePositionBack)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionFront] error:&error];
        }
        else if (position == AVCaptureDevicePositionFront)
        {
            NewVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self CameraWithPosition:AVCaptureDevicePositionBack] error:&error];
        }
        
        if (NewVideoInput != nil)
        {
            [CaptureSession beginConfiguration];		//We can now change the inputs and output configuration.  Use commitConfiguration to end
            [CaptureSession removeInput:VideoInputDevice];
            if ([CaptureSession canAddInput:NewVideoInput])
            {
                [CaptureSession addInput:NewVideoInput];
                VideoInputDevice = NewVideoInput;
            }
            else
            {
                [CaptureSession addInput:VideoInputDevice];
            }
            
            //Set the connection properties again
            [self CameraSetOutputProperties];
            
            [CaptureSession commitConfiguration];
        }
    }
}

//********** START STOP RECORDING BUTTON **********
- (IBAction)StartStopButtonPressed:(id)sender
{
    
    if (!WeAreRecording)
    {
        //----- START RECORDING -----
        NSLog(@"START RECORDING");
        WeAreRecording = YES;
        
        //Create temporary URL to record to
        NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
        NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:outputPath])
        {
            NSError *error;
            if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
            {
                //Error - handle if requried
            }
        }
        
        self.timeMin = 0;
        self.timeSec = 0;
        
        //Format the string 00:00
        NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", self.timeMin, self.timeSec];
        //Display on your label
        //[timeLabel setStringValue:timeNow];
        _lblRunningTime.text= timeNow;
        
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTick:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];

        //Start recording
        [MovieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
        
    }
    else
    {
        //----- STOP RECORDING -----
        NSLog(@"STOP RECORDING");
        WeAreRecording = NO;
        [self.timer invalidate];
        _lblRunningTime.text = @"";
        [MovieFileOutput stopRecording];
        
        
    }
}

- (void)timerTick:(NSTimer *)timer {
    self.timeSec++;
    if (self.timeSec == 60)
    {
        self.timeSec = 0;
        self.timeMin++;
    }
    //Format the string 00:00
    NSString* timeNow = [NSString stringWithFormat:@"%02d:%02d", self.timeMin, self.timeSec];
    //Display on your label
    _lblRunningTime.text= timeNow;
}

//********** DID FINISH RECORDING TO OUTPUT FILE AT URL **********
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
    
    NSLog(@"didFinishRecordingToOutputFileAtURL - enter");
    
    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr)
    {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value)
        {
            RecordedSuccessfully = [value boolValue];
        }
    }
    if (RecordedSuccessfully)
    {
        //----- RECORDED SUCESSFULLY -----
        NSLog(@"didFinishRecordingToOutputFileAtURL - success");
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputFileURL])
        {
            [library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
                                        completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 if (error)
                 {
                     
                 }
             }];
            //[self splitVideo:[NSString stringWithFormat:@"%@",outputFileURL]];
            
            [self split:outputFileURL];
        }
    }
}

-(void)split:(NSURL *)videoToTrimURL
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoToTrimURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
    outputURL = [outputURL stringByAppendingPathComponent:@"output.mp4"];
    // Remove Existing File
    [manager removeItemAtPath:outputURL error:nil];
    
    
    exportSession.outputURL = [NSURL fileURLWithPath:outputURL];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
    CMTime start = CMTimeMakeWithSeconds(startTime, 1);
    CMTime duration = CMTimeMakeWithSeconds(endTime, 1);
    CMTimeRange range = CMTimeRangeMake(start, duration);
    exportSession.timeRange = range;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         switch (exportSession.status) {
             case AVAssetExportSessionStatusCompleted:
                 [self writeVideoToPhotoLibrary:[NSURL fileURLWithPath:outputURL]];
                 NSLog(@"Export Complete %d %@", exportSession.status, exportSession.error);
                 break;
             case AVAssetExportSessionStatusFailed:
                 NSLog(@"Failed:%@",exportSession.error);
                 break;
             case AVAssetExportSessionStatusCancelled:
                 NSLog(@"Canceled:%@",exportSession.error);
                 break;
             default:
                 break;
         }
         
         //[exportSession release];
     }];
}

-(void)writeVideoToPhotoLibrary:(NSURL *)nsurlToSave
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    NSURL *recordedVideoURL= nsurlToSave;
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:recordedVideoURL])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:recordedVideoURL completionBlock:^(NSURL *assetURL, NSError *error)
        {
            
        }];
}
    //[library release]
}

- (void)splitVideo:(NSString *)outputURL
{
    
    @try
    {
        //NSString *videoBundleURL = [[NSBundle mainBundle] pathForResource:@"vid" ofType:@"mp4"];
        NSString *documentdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *tileDirectory = [documentdir stringByAppendingPathComponent:@"vid.mp4"];
        
        AVAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:tileDirectory] options:nil];
        
        NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
        
        if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality])
        {
            
            [self trimVideo:tileDirectory assetObject:asset];
            
        }
        tileDirectory = nil;
        
        //[asset release];
        asset = nil;
        
        compatiblePresets = nil;
    }
    @catch (NSException * e)
    {
        NSLog(@"Exception Name:%@ Reason:%@",[e name],[e reason]);
    }
}

- (void)trimVideo:(NSString *)outputURL assetObject:(AVAsset *)asset
{
    
    @try
    {
        
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:asset presetName:AVAssetExportPresetLowQuality];
        
        exportSession.outputURL = [NSURL fileURLWithPath:outputURL];
        
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        CMTime start = CMTimeMakeWithSeconds(startTime, 1);
        
        CMTime duration = CMTimeMakeWithSeconds(endTime, 1);
        
        CMTimeRange range = CMTimeRangeMake(start, duration);
        
        exportSession.timeRange = range;
        
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        
        [self checkExportSessionStatus:exportSession];
        
        // [exportSession release];
        exportSession = nil;
        
    }
    @catch (NSException * e)
    {
        NSLog(@"Exception Name:%@ Reason:%@",[e name],[e reason]);
    }
}

- (void)checkExportSessionStatus:(AVAssetExportSession *)exportSession
{
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void)
     {
         
         switch ([exportSession status])
         {
                 
             case AVAssetExportSessionStatusCompleted:
                 
                 NSLog(@"Export Completed");
                 break;
                 
             case AVAssetExportSessionStatusFailed:
                 
                 NSLog(@"Error in exporting:%d", [exportSession status]);
                 break;
                 
             default:
                 break;
                 
         }
     }];
}

@end
