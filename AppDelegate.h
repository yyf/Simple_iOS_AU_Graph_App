//
//  AppDelegate.h
//  Simple_iOS_AU_Graph_App
//
//  Created by Yuan-Yi Fan on 8/5/15. Modified from the MAT 594CR class example
//  Copyright (c) 2015 Yuan-Yi Fan. All rights reserved.
//

#import <UIKit/UIKit.h>

// include audio tool box to use helper API
#import <AudioToolbox/AudioToolbox.h>

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
	AUGraph graph;
	AUNode mixerNode, outputNode;
    
	AudioComponentInstance output, mixer;
    
    IBOutlet UISlider *freqSlider;
    IBOutlet UISlider *panSlider;
    
    int sineNodeCount;
}

//@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, retain) IBOutlet UIWindow *window;

- (IBAction) createSineNode:(id)sender;
- (IBAction) removeMixerNode:(id)sender;

@end
