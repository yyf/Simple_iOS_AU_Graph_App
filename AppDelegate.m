//
//  AppDelegate.m
//  Simple_iOS_AU_Graph_App
//
//  Created by Yuan-Yi Fan on 8/5/15. Modified from the MAT 594CR class example
//  Copyright (c) 2015 Yuan-Yi Fan. All rights reserved.
//

#import "AppDelegate.h"

#define NUM_CHANNELS 1
#define MAX_SINES 5

typedef struct  {
    float phase;
    float frequency;
} sine;

sine Sines[MAX_SINES];

@implementation AppDelegate

@synthesize window=_window;

static OSStatus playbackCallback(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData)
{
	
    sine* thisSine = (sine*)inRefCon;
	float my_sample;
	float increment = ((M_PI * 2.0) * thisSine->frequency) / 44100.0f;
	short* outputBuffer = ioData->mBuffers[0].mData;
	
	for(UInt16 n = 0; n < inNumberFrames; ++n) {
		my_sample = 0.0;
		my_sample += sinf(thisSine->phase);
		thisSine->phase += increment;
		my_sample *= 32768.0 / MAX_SINES;
		
		outputBuffer[n] = (SInt16)my_sample;
		
		if (thisSine->phase > (M_PI * 2)) {
			thisSine->phase -= M_PI * 2;
		}
	}
	
    // for doing chirp for each sine node
	//thisSine->frequency += 1.0;
	
	return noErr;
}




- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    //self.window.backgroundColor = [UIColor whiteColor];
    //[self.window makeKeyAndVisible];
//    return YES;
    
    [self.window makeKeyAndVisible];
    
    sineNodeCount = 0;
    
    // graph setup
    
    AudioComponentDescription mixerDescription, outputDescription;
    
    NewAUGraph(&graph);
    
    mixerDescription.componentFlags = 0;
    mixerDescription.componentFlagsMask = 0;
    mixerDescription.componentType = kAudioUnitType_Mixer;
    mixerDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
    mixerDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // add mixer node to the graph
    OSErr err = AUGraphAddNode(graph, &mixerDescription, &mixerNode);
    NSAssert(err == noErr, @"Error creating mixer node.");
    
    outputDescription.componentFlags = 0;
    outputDescription.componentFlagsMask = 0;
    outputDescription.componentType = kAudioUnitType_Output;
    outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    // add output node to the graph
    err = AUGraphAddNode(graph, &outputDescription, &outputNode);
    NSAssert(err == noErr, @"Error creating output node.");
    
    err = AUGraphOpen(graph);
    NSAssert(err == noErr, @"Error opening graph.");
    
    err = AUGraphConnectNodeInput(graph, mixerNode, 0, outputNode, 0);
    NSAssert(err == noErr, @"Error connecting mixer to output.");
    
    //get the 2 audio units
    err = AUGraphNodeInfo(graph, outputNode, &outputDescription, &output);
    err = AUGraphNodeInfo(graph, mixerNode,  &mixerDescription,  &mixer);
    
    // set number of channels for mixer audio unit
    int channelCount = MAX_SINES;
	AudioUnitSetProperty(mixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &channelCount, sizeof(channelCount));
    
    err = AUGraphInitialize(graph);
    NSAssert(err == noErr, @"Error initializing graph.");
    err = AUGraphStart(graph);
    NSAssert(err == noErr, @"Error starting graph.");
    
    CAShow(graph); // CAShow: prints out the internal state of an object to stdio
    
    // init audio sesstion
    AudioSessionInitialize(NULL, NULL, NULL, self); // change ARC to No in your build setting
	
	//set the audio category
	UInt32 audioCategory = kAudioSessionCategory_MediaPlayback;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
    
	Float32 preferredBufferSize = .001;
	AudioSessionSetProperty (kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);	
	AudioSessionSetActive(YES);
    
    return YES;
}

- (IBAction) createSineNode:(id)sender {

	AURenderCallbackStruct callback;
	callback.inputProc = playbackCallback;
	callback.inputProcRefCon = &Sines[sineNodeCount];
	AUGraphSetNodeInputCallback(graph, mixerNode, sineNodeCount, &callback);
	
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate =       44100.00;
	audioFormat.mFormatID =         kAudioFormatLinearPCM;
	audioFormat.mFormatFlags	 =  kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket =  1;
	audioFormat.mChannelsPerFrame = NUM_CHANNELS;
	audioFormat.mBitsPerChannel =   16;
	audioFormat.mBytesPerPacket =   2 * NUM_CHANNELS;
	audioFormat.mBytesPerFrame =    2 * NUM_CHANNELS;
	
	AudioUnitSetProperty(mixer, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, sineNodeCount, &audioFormat, sizeof(audioFormat));
    AudioUnitSetParameter ( mixer, kMultiChannelMixerParam_Pan, kAudioUnitScope_Input, sineNodeCount, [panSlider value], 0 );
    Sines[sineNodeCount].frequency = [freqSlider value];
    
	AUGraphUpdate(graph, nil);
    CAShow(graph);
    
    if(sineNodeCount++ >= MAX_SINES) {
        sineNodeCount = 0;
    }
}

- (IBAction) removeMixerNode:(id)sender {
    AUGraphRemoveNode(graph, mixerNode);
    AUGraphUpdate(graph, nil);
}

- (void)dealloc {
    DisposeAUGraph(graph);
    
    [_window release];
    [freqSlider release];
    [panSlider release];
    [super dealloc];
}

@end
