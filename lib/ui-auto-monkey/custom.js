#import "UIAutoMonkey.js"
#import "tuneup/tuneup.js"

// Configure the monkey: use the default configuration but a bit tweaked
monkey = new UIAutoMonkey();
monkey.config.numberOfEvents = 50; // total number of monkey event
monkey.config.delayBetweenEvents = 0.05;
monkey.config.eventWeights = {
			tap: 100,
			drag: 10,
			flick: 10,
			orientation: 1,
			lock: 1,
			pinchClose: 1,
			pinchOpen: 1,
			shake: 1
		};

monkey.config.touchProbability = {
			multipleTaps: 0.05,
			multipleTouches: 0.05,
			longPress: 0.05
		};

monkey.config.frame = {
			origin: 
				{ 
					x: parseInt(UIATarget.localTarget().rect().origin.x),
					y: parseInt(UIATarget.localTarget().rect().origin.y)+20
				},
			size: 
				{ 
					width: parseInt(UIATarget.localTarget().rect().size.width),
					height: parseInt(UIATarget.localTarget().rect().size.height)-20
				}
		};// Ignore the UIAStatusBar area, avoid to drag out the notification page. 

// Release the monkey!
monkey.RELEASE_THE_MONKEY();
