//
//  ViewController.m
//  JsonToClass
//
//  Created by MWeit on 16/3/19.
//  Copyright © 2016年 Weit. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (weak) IBOutlet NSTextField *textField;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (weak) IBOutlet NSButton *generateButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

}

- (IBAction)generateButtonOnClicked:(NSButton *)sender {
    
    NSString *className = [self.textField.stringValue capitalizedString];
 
    NSError *error;
    
    // 将json文字转换成字典
    NSData *data = [self.textView.string dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];

    if (jsonDictionary == nil) {
        self.textView.string = @"json格式不正确";
        return;
    }
    
    [self generateModelProtocolClass];
    // 生成class文件
    [self generateClassWithClassName:className data:jsonDictionary];
    
    self.textView.string = @"转换成功，文件已放到您的桌面！若有系统关键字还请自行更改。";
}

- (void)generateClassWithClassName:(NSString *)className data:(id)obj {
    
    // 获取.h文件框架
    NSString *hFilePath = [[NSBundle mainBundle] pathForResource:@"HFile" ofType:@"xyz"];
    NSMutableString *hFile = [NSMutableString stringWithContentsOfFile:hFilePath  encoding:NSUTF8StringEncoding error:nil];
    
    // 获取.m文件框架
    NSString *mFilePath = [[NSBundle mainBundle] pathForResource:@"MFile" ofType:@"xyz"];
    NSMutableString *mFile = [NSMutableString stringWithContentsOfFile:mFilePath encoding:NSUTF8StringEncoding error:nil];
    
    [hFile replaceOccurrencesOfString:@"@ClassName@" withString:className options:0 range:NSMakeRange(0, hFile.length)];
    
    // 设置属性
    NSMutableString *properties = [NSMutableString string];
    
    NSString *property;
    
    if ([obj isKindOfClass:[NSArray class]]) {
        NSString *name = [NSString stringWithFormat:@"%@DetailModel", [className capitalizedString]];
        [self generateClassWithClassName:className data:[obj firstObject]];
        [self importHaderFileToClassWithHFile:hFile inportString:[name stringByAppendingString:@".h"]];
        property = [NSString stringWithFormat:@"@property (copy, nonatomic) NSArray *%@;\n", name];
        
        [properties appendString:property];
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        for (NSString *tempKey in [obj allKeys]) {
            NSString *key = [self verifySystemkeyword:tempKey];
            id value = obj[key];
            
            if ([value isKindOfClass:[NSString class]]) {
                
                property = [NSString stringWithFormat:@"@property (copy, nonatomic) NSString *%@;\n", key];
            } else if ([value isKindOfClass:[NSArray class]]) {
                
                NSString *name = [NSString stringWithFormat:@"%@Model", [key capitalizedString]];
                [self generateClassWithClassName:name data:[value firstObject]];
                [self importHaderFileToClassWithHFile:hFile inportString:[name stringByAppendingString:@".h"]];

                property = [NSString stringWithFormat:@"@property (copy, nonatomic) NSArray *%@;\n", key];
            } else if ([value isKindOfClass:[NSDictionary class]]) {
                NSString *name = [NSString stringWithFormat:@"%@Model", [key capitalizedString]];
                
                [self generateClassWithClassName:name data:value];
                [self importHaderFileToClassWithHFile:hFile inportString:[name stringByAppendingString:@".h"]];
                property = [NSString stringWithFormat:@"@property (strong, nonatomic) %@ *%@;\n", name, key];
            } else if ([[value className] isEqualToString:@"__NSCFBoolean"]) {
                property = [NSString stringWithFormat:@"@property (assign, nonatomic, getter=is%@) BOOL %@;\n", [[key copy] capitalizedString], key];
            } else if ([[value className] isEqualToString:@"__NSCFNumber"]) {
                property = [NSString stringWithFormat:@"@property (copy, nonatomic) NSNumber *%@;\n", key];
            } else {
                property = [NSString stringWithFormat:@"@property (strong, nonatomic) id %@;\n", key];
            }
            
            [properties appendString:property];
        }
    }
    
    [hFile replaceOccurrencesOfString:@"@property@" withString:properties options:0 range:NSMakeRange(0, hFile.length)];
    
    [mFile replaceOccurrencesOfString:@"@ClassName@" withString:className options:0 range:NSMakeRange(0, mFile.length)];
    
    NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject];
    NSString *hSavePath = [NSString stringWithFormat:@"%@/%@.h", savePath, className];
    NSString *mSavePath = [NSString stringWithFormat:@"%@/%@.m", savePath, className];
    
    [hFile writeToFile:hSavePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    [mFile writeToFile:mSavePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

- (void)generateModelProtocolClass {
    
    // 获取.h文件框架
    NSString *hFilePath = [[NSBundle mainBundle] pathForResource:@"ModelProtocolHFile" ofType:@"xyz"];
    NSMutableString *hFile = [NSMutableString stringWithContentsOfFile:hFilePath  encoding:NSUTF8StringEncoding error:nil];
    
    // 获取.m文件框架
    NSString *mFilePath = [[NSBundle mainBundle] pathForResource:@" ModelProtocolMFile" ofType:@"xyz"];
    NSMutableString *mFile = [NSMutableString stringWithContentsOfFile:mFilePath encoding:NSUTF8StringEncoding error:nil];
    
    
    NSString *savePath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject];
    NSString *hSavePath = [NSString stringWithFormat:@"%@/NSObject+WTModel.h", savePath];
    NSString *mSavePath = [NSString stringWithFormat:@"%@/NSObject+WTModel.m", savePath];
    
    [hFile writeToFile:hSavePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    [mFile writeToFile:mSavePath atomically:NO encoding:NSUTF8StringEncoding error:nil];
}


#pragma mark - Private

- (void)importHaderFileToClassWithHFile:(NSMutableString *)hFile inportString:(NSString *)text {
    NSString *importString = [NSString stringWithFormat:@"#import \"%@\"\n", text];

    [hFile insertString:importString atIndex:63];
}

- (NSString *)verifySystemkeyword:(NSString *)text {
    
    if ([text isEqualToString:@"id"] ||
        [text isEqualToString:@"class"] ||
        [text isEqualToString:@"description"]) {
        
        return [NSString stringWithFormat:@"a%@", [text capitalizedString]];
    }
    return text;
}

@end
