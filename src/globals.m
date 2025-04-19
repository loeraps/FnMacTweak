#import "./globals.h"

#import <GameController/GameController.h>
#import <UIKit/UIKit.h>

// Key for hiding/revealing mouse pointer
GCKeyCode TRIGGER_KEY;
GCKeyCode POPUP_KEY;

// Aim sensitivity settings
float LOOK_MULTIPLIER_X = 100.0f;
float LOOK_MULTIPLIER_Y = 100.0f;
float ADS_MULTIPLIER_X = 100.0f;
float ADS_MULTIPLIER_Y = 100.0f;

// Keyboard handler
GCKeyboardValueChangedHandler keyboardChangedHandler = nil;
BOOL isMouseLocked = false;
BOOL isAlreadyFocused = false;

// UI and popup stuff
UIWindow *popupWindow = nil;
BOOL isPopupVisible = false;