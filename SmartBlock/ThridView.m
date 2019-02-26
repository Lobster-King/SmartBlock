//
//  ThridView.m
//  SmartBlock
//
//  Created by lobster on 2019/2/25.
//  Copyright © 2019 lobster. All rights reserved.
//

#import "ThridView.h"
#import "NSObject+SmartBlock.h"

@implementation ThridView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor yellowColor];
        [self setUpSubviews];
    }
    return self;
}

- (void)setUpSubviews {
    UILabel *text = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 80)];
    [text setFont:[UIFont systemFontOfSize:13]];
    [text setNumberOfLines:0];
    [text setText:@"点我！然后我穿越山和大海把值传给contrller～～～"];
    [self addSubview:text];
    
    text.center = self.center;
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    /*改变controller view的背景色，跨多个view回调*/
    [self callBackUsingKey:@"touchCallBack",@"msg",nil];
}

@end
