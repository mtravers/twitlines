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
    topTheme.event.instant.iconWidth = 24;
    topTheme.event.instant.iconHeight = 24;

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

// patch to unreverse event allocation
Timeline.OriginalEventPainter.prototype.paint = function() {
    // Paints the events for a given section of the band--what is
    // visible on screen and some extra.
    var eventSource = this._band.getEventSource();
    if (eventSource == null) {
        return;
    }
    
    this._eventIdToElmt = {};
    this._fireEventPaintListeners('paintStarting', null, null);
    this._prepareForPainting();
    
    var eventTheme = this._params.theme.event;
    var trackHeight = Math.max(eventTheme.track.height, eventTheme.tape.height + 
                        this._frc.getLineHeight());
    var metrics = {
           trackOffset: eventTheme.track.offset,
           trackHeight: trackHeight,
              trackGap: eventTheme.track.gap,
        trackIncrement: trackHeight + eventTheme.track.gap,
                  icon: eventTheme.instant.icon,
             iconWidth: eventTheme.instant.iconWidth,
            iconHeight: eventTheme.instant.iconHeight,
            labelWidth: eventTheme.label.width,
          maxLabelChar: eventTheme.label.maxLabelChar,
   impreciseIconMargin: eventTheme.instant.impreciseIconMargin
    }
    
    var minDate = this._band.getMinDate();
    var maxDate = this._band.getMaxDate();
    
    var filterMatcher = (this._filterMatcher != null) ? 
        this._filterMatcher :
        function(evt) { return true; };
    var highlightMatcher = (this._highlightMatcher != null) ? 
        this._highlightMatcher :
        function(evt) { return -1; };
    
    var iterator = eventSource.getEventIterator(minDate, maxDate);
    while (iterator.hasNext()) {
        var evt = iterator.next();
        if (filterMatcher(evt)) {
            this.paintEvent(evt, metrics, this._params.theme, highlightMatcher(evt));
        }
    }
    
    this._highlightLayer.style.display = "block";
    this._lineLayer.style.display = "block";
    this._eventLayer.style.display = "block";
    // update the band object for max number of tracks in this section of the ether
    this._band.updateEventTrackInfo(this._tracks.length, metrics.trackIncrement); 
    this._fireEventPaintListeners('paintEnded', null, null);
};


Timeline.OriginalEventPainter.prototype._findFreeTrackR = function(event, leftEdge) {
    var trackAttribute = event.getTrackNum();
    if (trackAttribute != null) {
        return trackAttribute; // early return since event includes track number
    }
    
    // normal case: find an open track
    for (var i = 0; i < this._tracks.length; i++) {
        var t = this._tracks[i];
        if (t < leftEdge) {
            break;
        }
    }
    return i;
};

Timeline.OriginalEventPainter.prototype.paintPreciseInstantEvent = function(evt, metrics, theme, highlightIndex) {
    var doc = this._timeline.getDocument();
    var text = evt.getText();
    
    var startDate = evt.getStart();
    var startPixel = Math.round(this._band.dateToPixelOffset(startDate));
    var iconRightEdge = Math.round(startPixel + metrics.iconWidth / 2);
    var iconLeftEdge = Math.round(startPixel - metrics.iconWidth / 2);

    var labelDivClassName = this._getLabelDivClassName(evt);
    var labelSize = this._frc.computeSize(text, labelDivClassName);
    var labelLeft = iconRightEdge + theme.event.label.offsetFromLine;
    var labelRight = labelLeft + labelSize.width;
    
    var leftEdge = iconLeftEdge;
    var rightEdge = labelRight;

    var track = this._findFreeTrackR(evt, leftEdge);
    
    var labelTop = Math.round(
        metrics.trackOffset + track * metrics.trackIncrement + 
        metrics.trackHeight / 2 - labelSize.height / 2);
        
    var iconElmtData = this._paintEventIcon(evt, track, iconLeftEdge, metrics, theme, 0);
    var labelElmtData = this._paintEventLabel(evt, text, labelLeft, labelTop, labelSize.width,
        labelSize.height, theme, labelDivClassName, highlightIndex);
    var els = [iconElmtData.elmt, labelElmtData.elmt];

    var self = this;
    var clickHandler = function(elmt, domEvt, target) {
        return self._onClickInstantEvent(iconElmtData.elmt, domEvt, evt);
    };
    SimileAjax.DOM.registerEvent(iconElmtData.elmt, "mousedown", clickHandler);
    SimileAjax.DOM.registerEvent(labelElmtData.elmt, "mousedown", clickHandler);
    
    var hDiv = this._createHighlightDiv(highlightIndex, iconElmtData, theme, evt);
    if (hDiv != null) {els.push(hDiv);}
    this._fireEventPaintListeners('paintedEvent', evt, els);

    
    this._eventIdToElmt[evt.getID()] = iconElmtData.elmt;
    this._tracks[track] = rightEdge;
}
