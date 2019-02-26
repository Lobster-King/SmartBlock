//
//  ViewController.m
//  SmartBlock
//
//  Created by lobster on 2019/2/25.
//  Copyright © 2019 lobster. All rights reserved.
//

#import "ViewController.h"
#import "BaseView.h"
#import "NSObject+SmartBlock.h"

@interface ViewController ()

@property (nonatomic, strong) BaseView *baseView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.baseView = [[BaseView alloc]initWithFrame:CGRectMake(0, 0, 300, 300)];
    self.baseView.center = self.view.center;
    [self.view addSubview:self.baseView];
    
//    __weak typeof(self)weakSelf = self;
//    [self observeCallBackUsingKey:@"touchCallBack" callBack:^(NSString *msg) {
//        NSLog(@"%s",__func__);
//        weakSelf.view.backgroundColor = [UIColor orangeColor];
//    } destructionOption:BlockDestructionDefault];
//
    [NSThread detachNewThreadSelector:@selector(addObserber) toTarget:self withObject:nil];
    
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)addObserber {
    NSLog(@"注册block线程：%@",[NSThread currentThread]);
    __weak typeof(self)weakSelf = self;
    [self observeCallBackUsingKey:@"touchCallBack" callBack:^(NSString *msg) {
        NSLog(@"block执行线程：%@",[NSThread currentThread]);
        dispatch_async(dispatch_get_main_queue(), ^{
           weakSelf.view.backgroundColor = [UIColor orangeColor];
        });
    } destructionOption:BlockDestructionDefault blockRunModeOption:BlockRunModeOnObserverThread];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}

- (void)testObjc:(NSString *)obj {
    
}


@end
