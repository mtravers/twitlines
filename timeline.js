var tl;

function onLoad() {
    var eventSource = new Timeline.DefaultEventSource();
    
    var topTheme = Timeline.ClassicTheme.create();
    topTheme.event.iconWidth = 16;
    topTheme.event.iconHeight = 16;
    

    var bandInfos = [
	Timeline.createBandInfo({
	    eventSource:    eventSource,
	    theme:          topTheme,
            width:          "70%", 
            intervalUnit:   Timeline.DateTime.MINUTE, 
            intervalPixels: 50
	}),
	Timeline.createBandInfo({
	    eventSource:    eventSource,
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
