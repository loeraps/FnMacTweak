#import "./popupViewController.h"

#import "../globals.h"

// Load settings
static void loadSettings() {
    NSDictionary* settings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kSettingsKey];

    if (settings) {
        LOOK_MULTIPLIER_X = [settings[kLookXKey] floatValue] ?: 100.0f;
        LOOK_MULTIPLIER_Y = [settings[kLookYKey] floatValue] ?: 100.0f;
        ADS_MULTIPLIER_X = [settings[kADSXKey] floatValue] ?: 100.0f;
        ADS_MULTIPLIER_Y = [settings[kADSYKey] floatValue] ?: 100.0f;
    }
}

@interface popupViewController ()

@property UITextField* lookXField;
@property UITextField* lookYField;
@property UITextField* adsXField;
@property UITextField* adsYField;
@property UILabel* savedLabel;
- (void)saveButtonTapped:(UIButton*)sender;

@end

@implementation popupViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    loadSettings();

    self.view.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.9];
    
    // Add title
    UILabel* title = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, 270, 30)];
    title.text = @"Sensitivity Settings";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:title];
    
    // Regular Sensitivity Section
    [self addLabel:@"Regular Sensitivity Multiplier (in %)" atPosition:CGRectMake(20, 70, 270, 20)];
    
    [self addLabel:@"X:" atPosition:CGRectMake(20, 100, 20, 30)];
    self.lookXField = [self addTextField:CGRectMake(50, 100, 100, 30) withValue:LOOK_MULTIPLIER_X];
    
    [self addLabel:@"Y:" atPosition:CGRectMake(180, 100, 20, 30)];
    self.lookYField = [self addTextField:CGRectMake(210, 100, 100, 30) withValue:LOOK_MULTIPLIER_Y];
    
    // ADS Sensitivity Section
    [self addLabel:@"Right-Click Sensitivity Multiplier (in %)" atPosition:CGRectMake(20, 150, 270, 20)];
    
    [self addLabel:@"X:" atPosition:CGRectMake(20, 180, 20, 30)];
    self.adsXField = [self addTextField:CGRectMake(50, 180, 100, 30) withValue:ADS_MULTIPLIER_X];
    
    [self addLabel:@"Y:" atPosition:CGRectMake(180, 180, 20, 30)];
    self.adsYField = [self addTextField:CGRectMake(210, 180, 100, 30) withValue:ADS_MULTIPLIER_Y];
    
    // Save Button
    UIButton* saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    saveButton.frame = CGRectMake(100, 240, 120, 40);
    saveButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    [saveButton setTitle:@"Save Settings" forState:UIControlStateNormal];
    [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveButton.layer.cornerRadius = 8;
    [saveButton addTarget:self action:@selector(saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:saveButton];
    
    // Saved feedback label (hidden initially)
    self.savedLabel = [[UILabel alloc] initWithFrame:CGRectMake(100, 300, 120, 30)];
    self.savedLabel.text = @"Saved!";
    self.savedLabel.textColor = [UIColor greenColor];
    self.savedLabel.textAlignment = NSTextAlignmentCenter;
    self.savedLabel.alpha = 0;
    [self.view addSubview:self.savedLabel];
    
    // Make window draggable
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:panGesture];
}

// Helper method to add labels
- (UILabel*)addLabel:(NSString*)text atPosition:(CGRect)frame {
    UILabel* label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:label];
    return label;
}

// Helper method to add text fields
- (UITextField*)addTextField:(CGRect)frame withValue:(float)value {
    UITextField* field = [[UITextField alloc] initWithFrame:frame];
    field.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    field.textColor = [UIColor whiteColor];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.keyboardType = UIKeyboardTypeDecimalPad;
    field.text = [NSString stringWithFormat:@"%.2f", value];
    field.textAlignment = NSTextAlignmentCenter;

    field.keyboardType = UIKeyboardTypeDecimalPad;
    field.delegate = self;

    [self.view addSubview:field];
    return field;
}

// Handle dragging the window
- (void)handlePan:(UIPanGestureRecognizer*)gesture {
    CGPoint translation = [gesture translationInView:self.view];
    if (gesture.state == UIGestureRecognizerStateChanged) {
        self.view.window.frame = CGRectOffset(self.view.window.frame, translation.x, translation.y);
        [gesture setTranslation:CGPointZero inView:self.view];
    }
}

// Save button handler
- (void)saveButtonTapped:(UIButton*)sender {
    // Update the global variables
    LOOK_MULTIPLIER_X = [self.lookXField.text floatValue];
    LOOK_MULTIPLIER_Y = [self.lookYField.text floatValue];
    ADS_MULTIPLIER_X = [self.adsXField.text floatValue];
    ADS_MULTIPLIER_Y = [self.adsYField.text floatValue];
    
    // Save to NSUserDefaults
    NSDictionary* settings = @{
        kLookXKey: @(LOOK_MULTIPLIER_X),
        kLookYKey: @(LOOK_MULTIPLIER_Y),
        kADSXKey: @(ADS_MULTIPLIER_X),
        kADSYKey: @(ADS_MULTIPLIER_Y)
    };
    
    [[NSUserDefaults standardUserDefaults] setObject:settings forKey:kSettingsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Show saved indicator
    [self showSavedIndicator];
}

// Show the saved indicator with animation
- (void)showSavedIndicator {
    self.savedLabel.alpha = 0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.savedLabel.alpha = 1;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                self.savedLabel.alpha = 0;
            }];
        });
    }];
}

// Only allow valid decimals (0-9 and .)
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string {
    NSCharacterSet *allowedCharacters = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
    NSCharacterSet *disallowedCharacters = [allowedCharacters invertedSet];

    // Block disallowed characters
    if ([string rangeOfCharacterFromSet:disallowedCharacters].location != NSNotFound) {
        return NO;
    }

    // Block multiple decimal points
    if ([textField.text containsString:@"."] && [string isEqualToString:@"."]) {
        return NO;
    }

    return YES;
}

@end
