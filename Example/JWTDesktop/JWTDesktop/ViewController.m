//
//  ViewController.m
//  JWTDesktop
//
//  Created by Lobanov Dmitry on 23.05.16.
//  Copyright © 2016 JWT. All rights reserved.
//

#import "ViewController.h"
#import <JWT/JWT.h>
#import <JWT/JWTAlgorithmFactory.h>
#import <Masonry/Masonry.h>
#import "JWTTokenTextTypeDescription.h"

#import "JWTDecriptedViewController.h"
typedef NS_ENUM(NSInteger, SignatureValidationType) {
    SignatureValidationTypeUnknown,
    SignatureValidationTypeValid,
    SignatureValidationTypeInvalid
};

@interface ViewController() <NSTextViewDelegate, NSTableViewDelegate, NSTableViewDataSource>
@property (weak) IBOutlet NSTextField *algorithmLabel;
@property (weak) IBOutlet NSPopUpButton *algorithmPopUpButton;
@property (unsafe_unretained) IBOutlet NSTextView *encodedTextView;
@property (unsafe_unretained) IBOutlet NSTextView *decodedTextView;
@property (weak) IBOutlet NSTableView *decodedTableView;
@property (weak) IBOutlet NSView * decriptedView;
@property (strong, nonatomic, readwrite) JWTDecriptedViewController *decriptedViewController;
@property (weak) IBOutlet NSTextField *signatureStatusLabel;

// Data
@property (nonatomic, readwrite) NSDictionary *signatureDecorations;
@property (assign, nonatomic, readwrite) SignatureValidationType signatureValidation;

// Tests
@property (nonatomic, readwrite) JWTBuilder *builder;
@property (strong, nonatomic, readwrite) JWTTokenTextTypeDescription *tokenDescription;
@end


@implementation ViewController

#pragma mark - Helpers
- (JWTTokenTextTypeDescription *)tokenDescription {
    if (!_tokenDescription) {
        _tokenDescription = [JWTTokenTextTypeDescription new];
    }
    return _tokenDescription;
}

#pragma mark - Supply JWT Methods
- (NSString *)chosenAlgorithmName {
    return [self.algorithmPopUpButton selectedItem].title;
}

- (NSString *)chosenSecret {
    return @"secret";
}

- (NSDictionary *)JWTFromToken:(NSString *)token skipSignatureVerification:(BOOL)skipVerification {
    NSLog(@"JWT ENCODED TOKEN: %@", token);
    NSString *algorithmName = [self chosenAlgorithmName];
    NSLog(@"JWT Algorithm NAME: %@", algorithmName);
    NSString *secret = [self chosenSecret];
    
    JWTBuilder *builder = [JWTBuilder decodeMessage:token].secret(secret).algorithmName(algorithmName).options(@(skipVerification));
    NSDictionary *decoded = builder.decode;
    NSLog(@"JWT ERROR: %@", builder.jwtError);
    NSLog(@"JWT DICTIONARY: %@", decoded);
    self.builder = builder;
    return decoded;
}

#pragma mark - Data
- (NSArray *)availableAlgorithms {
    return [JWTAlgorithmFactory algorithms];
}

- (NSArray *)availableAlgorithmsNames {
    return [[self availableAlgorithms] valueForKey:@"name"];
}

- (NSDictionary *)signatureDecorations {
    if (!_signatureDecorations) {
        _signatureDecorations = @{
            @(SignatureValidationTypeUnknown) : @{@"stringValue" : @"Signature Unknown", @"textColor" : [NSColor darkGrayColor]},
            @(SignatureValidationTypeValid) : @{@"stringValue" : @"Signature Valid", @"textColor" : [NSColor colorWithRed:0 green:185/255.0f blue:241/255.0f alpha:1.0f]},
            @(SignatureValidationTypeInvalid) : @{@"stringValue" : @"Signature Invalid", @"textColor" : [NSColor redColor]}
        };
    }
    return _signatureDecorations;
}

- (NSColor *)signatureColorForValidation:(SignatureValidationType)validation {
    NSDictionary *defaultValue = [self signatureDecorations][@(SignatureValidationTypeUnknown)];
    return [([self signatureDecorations][@(validation)] ?: defaultValue) valueForKey:@"textColor"];
}

- (NSString *)signatureTitleForValidation:(SignatureValidationType)validation {
    NSDictionary *defaultValue = [self signatureDecorations][@(SignatureValidationTypeUnknown)];
    return [([self signatureDecorations][@(validation)] ?: defaultValue) valueForKey:@"stringValue"];
}

- (NSColor *)tokenTextColorForType:(JWTTokenTextType)type {
    return [self.tokenDescription tokenTextColorForType:type];
}

#pragma mark - Setup
- (void)setupTop {
    // top label.
    self.algorithmLabel.stringValue = @"Algorithm";
    
    // pop up button.
    [self.algorithmPopUpButton removeAllItems];
    [self.algorithmPopUpButton addItemsWithTitles:[self availableAlgorithmsNames]];
    [self.algorithmPopUpButton setAction:@selector(popUpButtonValueChanged:)];
    [self.algorithmPopUpButton setTarget:self];
}

- (void)setupBottom {
    self.signatureStatusLabel.alignment       = NSTextAlignmentCenter;
    self.signatureStatusLabel.textColor       = [NSColor whiteColor];
    self.signatureStatusLabel.drawsBackground = YES;
    self.signatureValidation = SignatureValidationTypeUnknown;
}

- (void)setupEncodingDecodingViews {
    self.encodedTextView.delegate = self;
//    self.decodedTextView.delegate = self;
    self.decodedTableView.delegate = self;
    self.decodedTableView.dataSource = self;
    
    //thanks!
    //http://stackoverflow.com/questions/7545490/how-can-i-have-the-only-column-of-my-nstableview-take-all-the-width-of-the-table
    NSTableView *tableView = self.decodedTableView;
    [tableView  setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
    [tableView.tableColumns.firstObject setResizingMask:NSTableColumnAutoresizingMask];
    //AND
    [tableView sizeLastColumnToFit];
}

- (void)setupDecorations {
    [self setupTop];
    [self setupBottom];
}

- (void)setupDecriptedViews {
    NSView *view = self.decriptedView;
    self.decriptedViewController = [JWTDecriptedViewController new];
    [view addSubview:self.decriptedViewController.view];
    // maybe add contstraints.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDecorations];
    [self setupEncodingDecodingViews];
    [self setupDecriptedViews];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear {
    [super viewWillAppear];
    NSView *view = self.decriptedView;
    [self.decriptedViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(view);
    }];
}

//- (void)setRepresentedObject:(id)representedObject {
//    [super setRepresentedObject:representedObject];
//
//    // Update the view, if already loaded.
//}

#pragma mark - General Helpers
- (id)extendedArray:(NSArray *)array objectAtIndex:(NSInteger)index {
    if (array.count) {
        return index >= array.count ? nil : [array objectAtIndex:index];
    }
    return nil;
}

- (NSAttributedString *)array:(NSArray *)parts componentsJoinedByAttributedString:(NSAttributedString *)string{
    
    NSMutableAttributedString *result = [[self extendedArray:parts objectAtIndex:0] mutableCopy];
    
    for (NSInteger index = 1; index < parts.count; ++index) {
        NSAttributedString *part = parts[index];
        [result appendAttributedString:string];
        [result appendAttributedString:part];
    }
    
    return result;
}


#pragma mark - PopUp Button
- (void)popUpButtonValueChanged:(id)sender {
    // recalculate jwt //
    NSLog(@"now value is: %@", [self chosenAlgorithmName]);
}
#pragma mark - Signature Customization
- (void)setSignatureValidation:(SignatureValidationType)signatureValidation {
    self.signatureStatusLabel.backgroundColor = [self signatureColorForValidation:signatureValidation];
    self.signatureStatusLabel.stringValue     = [self signatureTitleForValidation:signatureValidation];
    _signatureValidation = signatureValidation;
}

- (void)signatureReactOnVerifiedToken:(BOOL)verified {
    SignatureValidationType type = verified ? SignatureValidationTypeValid : SignatureValidationTypeInvalid;
    self.signatureValidation = type;
}

#pragma mark - Encoding Customization
- (NSString *)textPartFromTexts:(NSArray *)texts withType:(JWTTokenTextType)type {
    NSString *result = nil;
    switch (type) {
        case JWTTokenTextTypeHeader: {
            result = (NSString *)[self extendedArray:texts objectAtIndex:0];
            break;
        }
        case JWTTokenTextTypePayload: {
            result = (NSString *)[self extendedArray:texts objectAtIndex:1];
            break;
        }
        case JWTTokenTextTypeSignature: {
            if (texts.count > 2) {
                result = (NSString *)[[texts subarrayWithRange:NSMakeRange(2, texts.count - 2)] componentsJoinedByString:@"."];
                break;
            }
            break;
        }
        default: break;
    }
    return result;
}

- (NSDictionary *)encodedTextViewAttributesForTokenTextType:(JWTTokenTextType)type {
    NSMutableDictionary *attributes = [[self encodedTextViewDefaultTextAttributes] mutableCopy];
    attributes[NSForegroundColorAttributeName] = [self tokenTextColorForType:type];
    return [attributes copy];
}

- (NSDictionary *)encodedTextViewDefaultTextAttributes {
    return @{
             NSFontAttributeName : [NSFont boldSystemFontOfSize:22],
             };
}

- (NSAttributedString *)encodedTextViewAttributedTextStringForEncodingText:(NSString *)text {
    NSArray *texts = [text componentsSeparatedByString:@"."];
    // next step, determine text color!
    // add missing dots.
    // restore them like this:
    // color text if you can
    
    NSArray *parts = @[];
    for (JWTTokenTextType part = JWTTokenTextTypeHeader; part <= JWTTokenTextTypeSignature; ++part) {
        id currentPart = [self textPartFromTexts:texts withType:part];
        if (currentPart) {
            // colorize
            NSDictionary *options = [self encodedTextViewAttributesForTokenTextType:part];
            NSAttributedString *currentPartAttributedString = [[NSAttributedString alloc] initWithString:currentPart attributes:options];
            parts = [parts arrayByAddingObject:currentPartAttributedString];
        }
    }
    
    NSDictionary *options = [self encodedTextViewAttributesForTokenTextType:JWTTokenTextTypeDefault];
    
    NSAttributedString *dot = [[NSAttributedString alloc] initWithString:@"." attributes:options];
    NSAttributedString *result = [self array:parts componentsJoinedByAttributedString:dot];
    return result;
}

#pragma mark - Decoding Customization
- (NSString *)stringFromDecodedJWTToken:(NSDictionary *)jwt {
    NSError *error = nil;
    NSData *data = nil;
    NSString *resultString = nil;
    
    if (jwt) {
        data = [NSJSONSerialization dataWithJSONObject:jwt options:NSJSONWritingPrettyPrinted error:&error];
    }
    
    if (data && !error) {
        resultString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return resultString ?: @"";
}

#pragma mark - EncodedTextView / <NSTextViewDelegate>

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString {
    
    if (textView == self.encodedTextView) {
        NSTextStorage * textStore = [textView textStorage];
        [textStore replaceCharactersInRange:affectedCharRange withString:replacementString];
        [textStore replaceCharactersInRange:NSMakeRange(0, textStore.string.length) withAttributedString:[self encodedTextViewAttributedTextStringForEncodingText:textView.string]];
        // react on changes.
        // recompute jwt of this token.
        // draw jwt
        NSRange range = NSMakeRange(0, self.decodedTextView.string.length);
        NSString *string = [self stringFromDecodedJWTToken:[self JWTFromToken:textStore.string skipSignatureVerification:YES]];
        [self signatureReactOnVerifiedToken:[self JWTFromToken:textStore.string skipSignatureVerification:NO]!=nil];
        // will be udpated.
        self.decriptedViewController.builder = self.builder;
        // not used.
        [self.decodedTextView replaceCharactersInRange:range withString:string];
        return NO;
    }
    return NO;
}

#pragma mark - DecodedTableView / <NSTableViewDataSource>

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 4;
}

#pragma mark - DecodedTableView / <NSTableViewDelegate>
- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
    return row % 2 == 0;
}
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    // choose by row is section or not
    if (row % 2) {
        // section
        NSView *cell = [tableView makeViewWithIdentifier:@"Cell" owner:self];
        ((NSTableCellView *)cell).textField.stringValue = @"AH";
        return cell;
    }
    else {
        NSView *cell = [tableView makeViewWithIdentifier:@"Cell" owner:self];
        ((NSTableCellView *)cell).textField.stringValue = @"OH";
        //    return nil;
        return cell;
    }
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    // calculate height of row.
//    NSView * view = [tableView viewAtColumn:0 row:row makeIfNecessary:NO];
    return 40;
}

@end
