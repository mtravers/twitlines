var tl;
var eventSource;

function loadData(search) {
    var url = "/twitlines/default";
    if (search != null) {
	// +++ needs urlencoding probably
	url = "/twitlines/search?term=" + search;
    } 
    tl.showLoadingMessage(); 
    Timeline.loadJSON(url, function(json, url) { 
	eventSource.clear();
	eventSource.loadJSON(json, url);
	tl.hideLoadingMessage();
    });
}

function onLoad() {

    eventSource = new Timeline.DefaultEventSource();
    var topTheme = Timeline.ClassicTheme.create();
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

    // patching to do right thing when clicking on embedded link
    Timeline.OriginalEventPainter.prototype._onClickInstantEvent = function(icon, domEvt, evt) {
	var c = SimileAjax.DOM.getPageCoordinates(icon);
	// if click on a link, don't do the bubble
	if (domEvt.target.tagName != "A") {
	    // punt bubble, it's useless -- instead open tweet in new window
	    open(evt.getLink(), "_blank");
	    this._fireOnSelect(evt.getID());
	    domEvt.cancelBubble = true;
	    SimileAjax.DOM.cancelEvent(domEvt);
	    return false;
	}
    }; 

    // patched to force size of icon to 24
    Timeline.OriginalEventPainter.prototype._paintEventIcon = function(evt, iconTrack, left, metrics, theme, tapeHeight) {
	// If no tape, then paint the icon in the middle of the track.
	// If there is a tape, paint the icon below the tape + impreciseIconMargin
	var icon = evt.getIcon();
	icon = icon != null ? icon : metrics.icon;
	
	var top; // top of the icon
	if (tapeHeight > 0) {
            top = metrics.trackOffset + iconTrack * metrics.trackIncrement + 
		tapeHeight + metrics.impreciseIconMargin;
	} else {
            var middle = metrics.trackOffset + iconTrack * metrics.trackIncrement +
                metrics.trackHeight / 2;
            top = Math.round(middle - metrics.iconHeight / 2);
	}
	//    var img = SimileAjax.Graphics.createTranslucentImage(icon);
	var img = document.createElement("img");
	img.setAttribute("src", icon);
	img.setAttribute("width", 24);
	img.setAttribute("height", 24);
	var iconDiv = this._timeline.getDocument().createElement("div");
	iconDiv.className = this._getElClassName('timeline-event-icon', evt, 'icon');
	iconDiv.id = this._encodeEventElID('icon', evt);
	iconDiv.style.left = left + "px";
	iconDiv.style.top = top + "px";
	iconDiv.appendChild(img);

	if(evt._title != null)
            iconDiv.title = evt._title;

	this._eventLayer.appendChild(iconDiv);
	
	return {
            left:   left,
            top:    top,
            width:  metrics.iconWidth,
            height: metrics.iconHeight,
            elmt:   iconDiv
	};
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
