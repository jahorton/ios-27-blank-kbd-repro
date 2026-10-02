# Minimal reproduction - Broken WKWebView rendering

This repository serves as a minimal reproduction of https://github.com/keymanapp/keyman/issues/16674, in which the rendering and interaction pipelines for a WKWebView hosted inside a UIInputView become completely severed.

We were able to completely remove our intended page from the pipeline and still reproduce the issue.

## Environment

- **OS**: iOS 27.  The issue does not reproduce on iOS 26.x or before

## Steps to Reproduce

1. Clone the repository: `git clone https://github.com/jahorton/ios-27-blank-kbd-repro.git`
2. Open the project in Xcode and run on any iOS device running 27.0 - simulated or otherwise.
3. Tap the top input field (labeled "In-app keyboard:") to display the UIInputView.

## Expected Result

The following should be displayed in place of a keyboard:

![Cyan page with red text](./imgs/cyanPage.png)

## Actual Result

The following will be displayed in place of a keyboard:

![Cyan page without text](./imgs/cyanBlank.png)

Inspecting the WKWebView via Safari (labeled "Blank keyboard repro") will demonstrate that:
- the page loaded properly
- the DOM tree will be an exact match to what "should be displayed" / the "Expected Result"
- any edit made to the DOM or CSS will not be reflected to the user
- hovering over an unrendered element to inspect it will still display its highlighted bounding box

This issue only occurs _within_ the host app; the page will display properly when used as a third-party custom keyboard on the same device.

# Related behaviors and observations

## Swapping the hosted page

When the repro state is active, absolutely no changes to the WebView's contents will be reflected back to the user - even if the hosted page is changed!  Toward that end, a second HTML page is provided:

![Red page with cyan text](./imgs/redPage.png)

Using the provided "Swap hosted page" button will swap the underlying HTML page, demonstrating this behavior.

The repro state will render the red page like this when armed:

![Red page with cyan text](./imgs/redBlank.png)

Both page's sourcefiles may be found within the `MainApp/resources/Hosted.bundle` folder.

## Swapping the active UIResponder

The repro state can be disarmed by simply swapping the active UIResponder.  Note that the UIResponder _must_ be swapped - removing and then re-enabling first-responder status on the same field will _not_ disarm the repro state.

Swapping via standard interaction or by the provided "Swap active responder" button will have the same effect of disarming the repro state.  Once such a swap has occurred, returning to the "In-app keyboard" text field will support expected behaviors:
- The page's text will now be fully rendered and visible.
- Swapping the hosted page will now work normally.

## Clearing the keyboard

Merely clearing the keyboard via `.resignFirstResponder` or by `.endEditing` will _not_ disarm the state.  In fact, doing so _programattically_ will actually _re-arm_ the repro state if the "In-app keyboard" field is the first responder to take focus - even if the "System keyboard" field was the previously-focused (first-responder) field!

## Failed workarounds

Three attempted workarounds are also available as in-app options; none of them will affect the issue-reproduction state in any form, though.

## In-app vs Third-party keyboard use

This minimal reproduction also offers its keyboard for use as a third-party custom keyboard, allowing it to be used for the "System keyboard" UITextField.  The issue and its related behaviors will never reproduce for the keyboard when used in this way, however.

The "Swap hosted page" button will _also_ swap the page displayed by the third-party custom keyboard mode.  They share the same state flag at all times.

## Suggested test sequences

Note that the two following sequences will produce different behavior:

1.  "Clear keyboard" > "Swap hosted page" > reactivate in-app keyboard field
2.  "Clear keyboard" > reactivate in-app keyboard field > "Swap hosted page"

Meanwhile the following two will produce the same behavior:

1.  "Clear keyboard" > reactivate in-app keyboard field > "Swap hosted page"
2.  "Clear keyboard" > reactivate in-app keyboard field > "Swap hosted page" > "Clear keyboard" > reactivate in-app keyboard field
    - As the responder will not have changed during this sequence after the first re-activation, the repro state never disarms.