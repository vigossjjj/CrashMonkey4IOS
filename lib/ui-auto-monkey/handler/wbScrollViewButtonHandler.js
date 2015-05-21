// Copyright (c) 2015 Yahoo inc. (http://www.yahoo-inc.com)

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

"use strict";
//Conforms to the ConditionHandler protocol in UIAutoMonkey
//Usage 
//  var handlers = [ ];
//  var handlerInterval = 20;  //every how many events to process. Can vary by each handler, but often useful to group them
//  handlers.push(new ButtonHandler("Done", handlerInterval, false));  //every 20 events, press "Done" button if found as a top level button (no nav bar). 
//  ...
//  config.conditionHandlers = handlers
//  
function WBScrollViewButtonHandler(buttonName, checkEveryNumber, useNavBar, scrollViewIndex, optionalIsTrueFunction) {
	this.buttonName = buttonName;
	this.scrollViewIndex = scrollViewIndex;
	this.checkEveryNumber = checkEveryNumber || 10;
	if (useNavBar == undefined) {
		useNavBar = true;
	};
	this.useNavBar = useNavBar;
	this.optionalIsTrueFunction = optionalIsTrueFunction || null;
	//stats
	this.statsIsTrueInvokedCount = 0;
	this.statsIsTrueReturnedTrue = 0;
	this.statsIsTrueReturnedFalse = 0;
	this.statsHandleInvokedCount = 0;
	this.statsHandleNotValidAndVisibleCount = 0;
	this.statsHandleErrorCount = 0;
}

// return true if we our button is visible 
WBScrollViewButtonHandler.prototype.isTrue = function(target, eventCount, mainWindow) {
	this.statsIsTrueInvokedCount++;
	var result;
	if (this.optionalIsTrueFunction == null) {
		var aButton = this.findButton(target);
        // result = aButton.isNotNil() && aButton.validAndVisible();
        result = aButton.isNotNil() && aButton.isValid();
    } else {
	    result = this.optionalIsTrueFunction(target, eventCount, mainWindow);
    }
    if (result) {
	  this.statsIsTrueReturnedTrue++;
    } else {
	  this.statsIsTrueReturnedFalse++;
    };
    return result;
};

WBScrollViewButtonHandler.prototype.findButton = function(target) {
	return this.useNavBar ? 
	    target.frontMostApp().mainWindow().navigationBar().buttons()[this.buttonName]:
        target.frontMostApp().mainWindow().scrollViews()[this.scrollViewIndex].buttons()[this.buttonName];
};
	
//every checkEvery() number of events our isTrue() method will be queried.
WBScrollViewButtonHandler.prototype.checkEvery = function() {
    return this.checkEveryNumber;
};

// if true then after we handle an event consider the particular Monkey event handled, and don't process the other condition handlers.
WBScrollViewButtonHandler.prototype.isExclusive = function() {
    return true;
};

// Press our button
WBScrollViewButtonHandler.prototype.handle = function(target, mainWindow) {
	this.statsHandleInvokedCount++;
	var button = this.findButton(target);
	if (button.isValid()) {
		try{
			var x = button.rect().origin.x;
			var y = button.rect().origin.y;
			target.tap({x:x, y:y});
		} catch(err) {
			this.statsHandleErrorCount++;
			UIALogger.logWarning(err);
		}
	} else {
		this.statsHandleNotValidAndVisibleCount++
		//UIALogger.logWarning(this.toString() + " button is not validAndVisible");
	};
};

WBScrollViewButtonHandler.prototype.toString = function() {
	return ["MonkeyTest::WBScrollViewButtonHandler(" + this.buttonName, this.checkEveryNumber, this.useNavBar, this.scrollViewIndex, ")"].join();
};

WBScrollViewButtonHandler.prototype.logStats = function() {
	UIALogger.logDebug([this.toString(),
	    "IsTrueInvokedCount", this.statsIsTrueInvokedCount,
		"IsTrueReturnedTrue", this.statsIsTrueReturnedTrue,
		"IsTrueReturnedFalse", this.statsIsTrueReturnedFalse,
		"HandleInvokedCount", this.statsHandleInvokedCount,
		"HandleNotValidAndVisibleCount", this.statsHandleNotValidAndVisibleCount,
		"HandleErrorCount", this.statsHandleErrorCount].join());
};