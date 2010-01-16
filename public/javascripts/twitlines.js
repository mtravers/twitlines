var tl;
var eventSource;
var rangeLow = null;		// these are the dates of lowest and highest displayed items
var rangeHigh = null;
var lastQueryTime = null;
var queryUrl = null;
var queryInProgress = false;

function rateLimit(limit, func) {
    if (!queryInProgress && (lastQueryTime == null || new Date().getTime() > lastQueryTime.getTime() + limit)) {
	queryInProgress = true;
	func.call();
	queryInProgress = false;
	lastQueryTime = new Date();
    }
}

function updateVisible() {
    rateLimit(5000, function() {
	var band = tl._bands[0]; // more correct to look at lower band, but that produces too many updates
	var minDate = band.getMinVisibleDate();
	var maxDate = band.getMaxVisibleDate();
	//	     console.log('f' + minDate + ', ' + maxDate);
	loadDataIncremental(minDate, maxDate);
    });
}

var autoScroll = false;
var autoScrolling = false;

function toggle(elt) {
    $(elt).toggleClassName('down');
}


function startAutoscroll () {
    autoScroll=true;
    $('now2').addClassName('down')
    now();
}

function stopAutoscroll () {
    // set button state
    autoScroll = false;
    $('now2').removeClassName('down')
}

new PeriodicalExecuter(function () {
    if (autoScroll) { 
	now(); 
    } 
}, 30);

function now() {
    autoScrolling = true;	// +++ unwind protect
    tl.getBand(0).scrollToCenter(new Date(), function() {
	autoScrolling = false;
	updateVisible();
    });
}

function loadDataIncremental(low, high) {
    if (low < rangeLow) {
	loadData(null, true);
    }
    if (high > rangeHigh) {
	loadData(null, false);
    }
}

function newHome() {
    loadData("/twitlines/default");
}

function updateTwitterLink(url) {
    document.getElementById('standard').href = url;
}

function newSearch(term) {
    document.getElementById('sterm').value = term;
    loadData("/twitlines/search?term=" + escape(term));
    updateTwitterLink('http://twitter.com/#search?q=' + escape(term));
}

function addParam(url, param, value) {
    var first = url.indexOf('?') < 0;
    return url + (first ? "?" : "&") + param + "=" + value
}

// url is base url or null for incremental search
// earlier: true to load more earlier, else later
function loadData(url, earlier) {
    if (url == null) {
	// incremental
	url = addParam(queryUrl, "incremental", earlier ? "earlier" : "later")
    } else {
	// new query
	queryUrl = url;
	eventSource.clear();
	rangeLow = null
	rangeHigh = null;
    }
    tl.showLoadingMessage(); 
    Timeline.loadJSON(url, function(json, url) { 
	eventSource.loadJSON(json, url);
	updateRange(eventSource.getEarliestDate(), eventSource.getLatestDate());
	tl.hideLoadingMessage();
    });
}

function updateRange(low, high) {
    if (rangeLow == null || low < rangeLow)
	rangeLow = low;
    if (rangeHigh == null || high > rangeHigh)
	rangeHigh = high;
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
            intervalPixels: 45
	}),
	Timeline.createBandInfo({
	    eventSource:    eventSource,
	    theme:          topTheme,
	    timeZone:       -8,	// should be dynamic
            width:          "30%", 
            intervalUnit:   Timeline.DateTime.HOUR, 
            intervalPixels: 80
	})
    ];
    bandInfos[1].syncWith = 0;
    bandInfos[1].highlight = true;
    tl = Timeline.create(document.getElementById("my-timeline"), bandInfos);
    newHome();

    tl.getBand(0).addOnScrollListener(function(band) {
	if (!autoScrolling) {
	    updateVisible();
	    stopAutoscroll();
	}
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

// patched to show day of week
Timeline.GregorianDateLabeller.prototype.defaultLabelInterval = function(date, intervalUnit) {
    var text;
    var emphasized = false;
    
    date = SimileAjax.DateTime.removeTimeZoneOffset(date, this._timeZone);
    
    switch(intervalUnit) {
    case SimileAjax.DateTime.MILLISECOND:
        text = date.getUTCMilliseconds();
        break;
    case SimileAjax.DateTime.SECOND:
        text = date.getUTCSeconds();
        break;
    case SimileAjax.DateTime.MINUTE:
        var m = date.getUTCMinutes();
        if (m == 0) {
            text = date.getUTCHours() + ":00";
            emphasized = true;
        } else {
            text = m;
        }
        break;
	// patch starts here
    case SimileAjax.DateTime.HOUR:
	var h = date.getUTCHours();
	if (h == 0) {
	    var dayOfWeek = Timeline.GregorianDateLabeller.getDayName(date.getUTCDay(), this._locale);
	    text = dayOfWeek;
            emphasized = true;
	} else {
            text = h + ":00";
	}
        break;
    case SimileAjax.DateTime.DAY:
        text = Timeline.GregorianDateLabeller.getMonthName(date.getUTCMonth(), this._locale) + " " + date.getUTCDate();
        break;
    case SimileAjax.DateTime.WEEK:
        text = Timeline.GregorianDateLabeller.getMonthName(date.getUTCMonth(), this._locale) + " " + date.getUTCDate();
        break;
    case SimileAjax.DateTime.MONTH:
        var m = date.getUTCMonth();
        if (m != 0) {
            text = Timeline.GregorianDateLabeller.getMonthName(m, this._locale);
            break;
        } // else, fall through
    case SimileAjax.DateTime.YEAR:
    case SimileAjax.DateTime.DECADE:
    case SimileAjax.DateTime.CENTURY:
    case SimileAjax.DateTime.MILLENNIUM:
        var y = date.getUTCFullYear();
        if (y > 0) {
            text = date.getUTCFullYear();
        } else {
            text = (1 - y) + "BC";
        }
        emphasized = 
            (intervalUnit == SimileAjax.DateTime.MONTH) ||
            (intervalUnit == SimileAjax.DateTime.DECADE && y % 100 == 0) || 
            (intervalUnit == SimileAjax.DateTime.CENTURY && y % 1000 == 0);
        break;
    default:
        text = date.toUTCString();
    }
    return { text: text, emphasized: emphasized };
};

// unaccountably missing
Timeline.GregorianDateLabeller.getDayName = function(day, locale) {
    return Timeline.GregorianDateLabeller.dayNames[locale][day];
}

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
