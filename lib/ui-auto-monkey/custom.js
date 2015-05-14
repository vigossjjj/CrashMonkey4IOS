#import "UIAutoMonkey.js"
#import "buttonHandler.js"
#import "tuneup/tuneup.js"

// Configure the monkey: use the default configuration but a bit tweaked
monkey = new UIAutoMonkey();
monkey.config.numberOfEvents = 200; // turn off to make clear that we want minutes
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
					x: parseInt(UIATarget.localTarget().frontMostApp().rect().origin.x), 
					y: parseInt(UIATarget.localTarget().frontMostApp().rect().origin.y)
				},
			size: { 
					width: parseInt(UIATarget.localTarget().frontMostApp().rect().size.width), 
					height: parseInt(UIATarget.localTarget().frontMostApp().rect().size.height)
				}
		};// Ignore the UIAStatusBar area, avoid to drag out the notification page. 

//UI Holes handlers
var handlers = [];
// handlers.push(new ButtonHandler("Crash", 3, false));
// handlers.push(new ButtonHandler("weatherLeftBack", 10, false));
handlers.push(new ButtonHandler("WBBack", 10, true));
handlers.push(new ButtonHandler("取消", 3, true));
handlers.push(new ButtonHandler("CloseX", 3, true));
handlers.push(new ButtonHandler("确定", 3, false));
monkey.config.conditionHandlers = handlers;

//ANR settings
var aFingerprintFunction = function() {
    var mainWindow = UIATarget.localTarget().frontMostApp().mainWindow();
    //if an error occurs log it and make it the fingerprint
    try {
        var aString = mainWindow.elementAccessorDump("tree", true);
        // var aString = mainWindow.logElementTree();
        // var aString = mainWindow.logElementJSON(["name"])
        if (monkey.config.anrSettings.debug) {
            UIALogger.logDebug("fingerprintFunction tree=" + aString);
        }
    }
    catch (e) {
        aString = "fingerprintFunction error:" + e;
        UIALogger.logWarning(aString);
    }
    return aString;
};
monkey.config.anrSettings.fingerprintFunction = false;//false | aFingerprintFunction
monkey.config.anrSettings.eventsBeforeANRDeclared = 18; //throw exception if the fingerprint hasn't changed within this number of events
monkey.config.anrSettings.eventsBetweenSnapshots = 8; //how often (in events) to take a snapshot using the fingerprintFunction 
monkey.config.anrSettings.debug = true;  //log extra info on ANR state changes

// Release the monkey!
monkey.RELEASE_THE_MONKEY();