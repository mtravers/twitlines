var tl;
var eventSource;

function loadData(search) {
    var url = "twitter.json";
    if (search != null) {
	url = url + "?search=" + search;
    }
    Timeline.loadJSON(url, function(json, url) { 
	eventSource.clear();
	tl.showLoadingMessage(); 
	eventSource.loadJSON(json, url);
	tl.hideLoadingMessage();
    });
}

function onLoad() {

    eventSource = new Timeline.DefaultEventSource();
    var topTheme = Timeline.ClassicTheme.create();
// does not work
//    topTheme.event.iconWidth = 16;
//    topTheme.event.iconHeight = 16;
    topTheme.event.track.height = 30;

    var bandInfos = [
	Timeline.createBandInfo({
	    eventSource:    eventSource,
	    theme:          topTheme,
	    timeZone:       -8,	// should be dynamic
            width:          "70%", 
            intervalUnit:   Timeline.DateTime.MINUTE, 
            intervalPixels: 50
	}),
	Timeline.createBandInfo({
	    eventSource:    eventSource,
	    theme:          topTheme,
	    timeZone:       -8,	// should be dynamic
            width:          "30%", 
            intervalUnit:   Timeline.DateTime.HOUR, 
            intervalPixels: 100
	})
    ];
    bandInfos[1].syncWith = 0;
    bandInfos[1].highlight = true;
    tl = Timeline.create(document.getElementById("my-timeline"), bandInfos);
    loadData();

    // load new data on scroll -- not yet
     tl.getBand(0).addOnScrollListener(function(band) {
 	var minDate = band.getMinDate();
 	var maxDate = band.getMaxDate();
//	 console.log('f' + minDate + ', ' + maxDate);
//	 if (... need to reload events ...) {
//             tl.loadXML(...);
// 	}
     });

    // patching this
    Timeline.OriginalEventPainter.prototype._onClickInstantEvent = function(icon, domEvt, evt) {
	var c = SimileAjax.DOM.getPageCoordinates(icon);
	// if click on a link, don't do the bubble
	if (domEvt.target.tagName != "A") {
	    // punt bubble, it's useless
// 	    this._showBubble(
// 		c.left + Math.ceil(icon.offsetWidth / 2),
// 		c.top + Math.ceil(icon.offsetHeight / 2),
// 		evt
// 	    );
	    open(evt.getLink(), "_blank");
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
