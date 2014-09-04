
Touches_Responder
-----------------

This sample application demonstrates how to handle touches, including multiple touches that move multiple objects.  After the application launches, three colored pieces appear onscreen that the user can move independently. Touches cause up to three lines of text to be displayed at the top of the screen.

The top line displays the touch phase for the current touch event: touches began, touches moved, or touches ended.

The second line displays the number of touches that are being tracked by the current event. Keep in mind that this number can change quickly if the user is initiating and ending multiple touch events.

The third line displays information about multiple taps. The number of taps appear when the user taps two or more times quickly in succession.

To get an idea of how touch handling works, trying moving just one piece and observe the phase changes. Next, investigate how taps work by touching the screen twice in succession, first slowly and then with increasing frequency until the touches are registered as taps.

After you see how single touches work, try moving more than one piece. The application reports how many touches it's tracking. Note that the application also tracks touches that are not within a piece.

If you drag one piece over another, the top piece "captures" the piece below, hiding it. This demonstrates how, with one touch, you can drag multiple items. If you want to "unstick" pieces, double tap anywhere on the background (not on the pieces).

Before your application can handle multiple events, it must enable them, either by setting the flag in Interface Builder, or by calling setMultipleTouchEnabled:. The methods touchesBegan:withEvent:, touchesMoved:withEvent:, touchesEnded:withEvent: show how to handle each phase of a multiple touch event. By looking at the code, you'll see that to handle multiple touches at the same time, you need to iterate through all the touch objects passed to each of the touch handling methods, handling each touch separately. Touches does this by calling a "dispatch" method that checks to see which piece the touch is in, and the takes the appropriate action. 

Main Class
----------

APLViewController
This view controller implements the touches methods that respond to user interaction. It animates and moves pieces onscreen in response to touch events. It also displays text that shows the touch phase and other information about touches.

================================================================================
Copyright (C) 2008-2013 Apple Inc. All rights reserved.
