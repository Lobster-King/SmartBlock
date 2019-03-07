//
//  BaseView.m
//  SmartBlock
//
//  Created by lobster on 2019/2/25.
//  Copyright © 2019 lobster. All rights reserved.
//

#import "BaseView.h"
#import "SecondView.h"
#import "NSObject+SmartBlock.h"

@implementation BaseView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor redColor];
        [self setUpSubviews];
    }
    return self;
}

- (void)setUpSubviews {
    SecondView *view = [[SecondView alloc]initWithFrame:CGRectMake(0, 0, 200, 200)];
    view.center = self.center;
    [self addSubview:view];
    
    [self observeCallBackUsingKey:@"BaseViewCallBack" callBack:^(){
        
    }];
}

- (void)dealloc {
    NSLog(@"%s",__func__);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
