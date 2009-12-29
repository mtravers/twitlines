var tl;

function onLoad() {
    var eventSource = new Timeline.DefaultEventSource();
    
    var topTheme = Timeline.ClassicTheme.create();
// does not work
//    topTheme.event.iconWidth = 16;
//    topTheme.event.iconHeight = 16;
    topTheme.event.track.height = 30;

    var bandInfos = [
	Timeline.createBandInfo({
	    eventSource:    eventSource,
	    theme:          topTheme,
	    timeZone:       8,	// should be dynamic
            width:          "70%", 
            intervalUnit:   Timeline.DateTime.MINUTE, 
            intervalPixels: 50
	}),
	Timeline.createBandInfo({
	    eventSource:    eventSource,
	    theme:          topTheme,
	    timeZone:       8,	// should be dynamic
            width:          "30%", 
            intervalUnit:   Timeline.DateTime.HOUR, 
            intervalPixels: 100
	})
    ];
    bandInfos[1].syncWith = 0;
    bandInfos[1].highlight = true;
    tl = Timeline.create(document.getElementById("my-timeline"), bandInfos);
    tl.showLoadingMessage(); 
    Timeline.loadJSON("twitter.json", function(json, url) { 
	eventSource.loadJSON(json, url);
	tl.hideLoadingMessage();
    });

    // patching this
    Timeline.OriginalEventPainter.prototype._onClickInstantEvent = function(icon, domEvt, evt) {
	var c = SimileAjax.DOM.getPageCoordinates(icon);
	// if click on a link, don't do the bubble
	if (domEvt.target.tagName != "A") {
	    this._showBubble(
		c.left + Math.ceil(icon.offsetWidth / 2),
		c.top + Math.ceil(icon.offsetHeight / 2),
		evt
	    );
	    this._fireOnSelect(evt.getID());
	    domEvt.cancelBubble = true;
	    SimileAjax.DOM.cancelEvent(domEvt);
	    return false;
	}
    }; 
}

var resizeTimerID = null;
function onResize() {
    if (resizeTimerID == null) {
        resizeTimerID = window.setTimeout(function() {
            resizeTimerID = null;
            tl.layout();
        }, 500);
    }
}
