#import <GameController/GameController.h>
#import <UIKit/UIKit.h>

// For spoofing device specifications
#define DEVICE_MODEL "iPad16,6"
#define OEM_ID "A2925"

// Setting keys
#define kSettingsKey @"fnmactweak.settings"
#define kLookXKey @"lookMultiplierX"
#define kLookYKey @"lookMultiplierY"
#define kADSXKey @"adsMultiplierX"
#define kADSYKey @"adsMultiplierY"

// Key for hiding/revealing mouse pointer
extern GCKeyCode TRIGGER_KEY;
extern GCKeyCode POPUP_KEY;

// Aim sensitivity settings
extern float LOOK_MULTIPLIER_X;
extern float LOOK_MULTIPLIER_Y;
extern float ADS_MULTIPLIER_X;
extern float ADS_MULTIPLIER_Y;

// Keyboard handler
extern GCKeyboardValueChangedHandler keyboardChangedHandler;
extern BOOL isMouseLocked;
extern BOOL isAlreadyFocused;

// UI and popup stuff
extern UIWindow *popupWindow;
extern BOOL isPopupVisible;