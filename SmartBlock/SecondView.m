//
//  SecondView.m
//  SmartBlock
//
//  Created by lobster on 2019/2/25.
//  Copyright © 2019 lobster. All rights reserved.
//

#import "SecondView.h"
#import "ThridView.h"

@implementation SecondView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor greenColor];
        [self setUpSubviews];
    }
    return self;
}

- (void)setUpSubviews {
    ThridView *view = [[ThridView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    view.center = self.center;
    [self addSubview:view];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
