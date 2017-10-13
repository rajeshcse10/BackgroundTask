//
//  ViewController.m
//  MyBackgroundTask
//
//  Created by MacBook Pro Retina on 10/11/17.
//  Copyright © 2017 MacBook Pro Retina. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
@interface ViewController ()
@property(nonatomic,strong) NSMutableArray *bgTaskIdList;
@property (weak, nonatomic) IBOutlet UILabel *stepsLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;

@end


@implementation ViewController{
    int foreground_counter;
    int background_counter;
    CMPedometer *pedometer;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self registerNotification];
}
-(void) getPedometerUpdate{
    [pedometer startPedometerUpdatesFromDate:[NSDate date] withHandler:^(CMPedometerData * _Nullable pedometerData, NSError * _Nullable error) {
        if(error == nil){
            NSLog(@"Step count:%@    Distance:%@",pedometerData.numberOfSteps,pedometerData.distance);
            [self updateLabelwithData:pedometerData];
        }
    }];
    
}
-(void)updateLabelwithData:(CMPedometerData *)pedometerData{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.stepsLabel.text = [NSString stringWithFormat:@"Steps:%@",pedometerData.numberOfSteps];
        self.distanceLabel.text = [NSString stringWithFormat:@"Distance:%.3f",[pedometerData.distance floatValue]];
    });
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _bgTaskIdList = [NSMutableArray array];
    pedometer = [[CMPedometer alloc] init];
    background_counter = 0;
    foreground_counter = 0;
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        //NSLog(@"Timer : %lld",c++);
        if([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground){
            //NSLog(@"Background counter : %d",background_counter++);
            background_counter++;
            if(background_counter > 10){
                //[self endAllBackgroundTasks];
                [self createBackgroungTask];
                background_counter = 0;
            }
        }
        else{
            //NSLog(@"Foreground counter : %d",foreground_counter++);
            foreground_counter++;
        }
    }];
}
-(void)registerNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartLocationTracking:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartLocationTracking:) name:UIApplicationWillEnterForegroundNotification object:nil];
}
-(void)deregisterNotification{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}
-(void)restartLocationTracking:(NSNotification*)noti
{
    if([noti.name isEqualToString:UIApplicationDidEnterBackgroundNotification])
    {
        [self createBackgroungTask];
        background_counter = 0;
    }
    else if([noti.name isEqualToString:UIApplicationWillEnterForegroundNotification])
    {
        [self endAllBackgroundTasks];
        foreground_counter = 0;
    }
}
-(void) createBackgroungTask{
    UIApplication *app = [UIApplication sharedApplication];
    if([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]){
        //NSLog(@"Multitasking Supported");
        __block UIBackgroundTaskIdentifier bgTaskId = UIBackgroundTaskInvalid;
        bgTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
            //NSLog(@"background task %lu expired", (unsigned long)bgTaskId);
            
            //[self.bgTaskIdList removeObject:@(bgTaskId)];
            //[app endBackgroundTask:bgTaskId];
            //bgTaskId = UIBackgroundTaskInvalid;
        }];
        
        //NSLog(@"started background task %lu", (unsigned long)bgTaskId);
        [self.bgTaskIdList addObject:@(bgTaskId)];
        [self endBackgroundTasks];
        
    }
}
-(void)endBackgroundTasks
{
    [self drainBGTaskList:NO];
}

-(void)endAllBackgroundTasks
{
    [self drainBGTaskList:YES];
}

-(void)drainBGTaskList:(BOOL)all
{
    UIApplication* application = [UIApplication sharedApplication];
    if([application respondsToSelector:@selector(endBackgroundTask:)]){
        NSUInteger count=self.bgTaskIdList.count;
        for ( NSUInteger i=(all?0:1); i<count; i++ )
        {
            UIBackgroundTaskIdentifier bgTaskId = [[self.bgTaskIdList objectAtIndex:0] integerValue];
            //NSLog(@"ending background task with id : %lu", (unsigned long)bgTaskId);
            [application endBackgroundTask:bgTaskId];
            bgTaskId = UIBackgroundTaskInvalid;
            [self.bgTaskIdList removeObjectAtIndex:0];
        }
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    
}
-(void) viewDidDisappear:(BOOL)animated{
    [self viewDidDisappear:animated];
    
}

- (IBAction)startAction:(id)sender {
    [self getPedometerUpdate];
}

- (IBAction)endAction:(id)sender {
    [pedometer stopPedometerUpdates];
    [self deregisterNotification];
    self.stepsLabel.text  = @"";
    self.distanceLabel.text = @"";
}

@end
