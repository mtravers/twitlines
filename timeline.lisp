(in-package :wu)

(publish :path "/timeline"
	 :function 'html-timeline)

(publish-file :path "/timeline.js"
	      :file "/misc/sourceforge/twitline/timeline.js")

(defun html-timeline (req ent)
  (with-http-response (req ent)
    (with-http-body (req ent)
      (html
       (:head
	;; normal
;	((:script :src "http://static.simile.mit.edu/timeline/api-2.3.0/timeline-api.js?bundle=true" :type "text/javascript"))
	;; for debugging
	(:script
	 (:princ "var Timeline_ajax_url = 'http://api.simile-widgets.org/ajax/2.2.1/simile-ajax-api.js?bundle=false'"))
	((:script :src "http://static.simile.mit.edu/timeline/api-2.3.0/timeline-api.js?bundle=false" :type "text/javascript"))

	((:script :src "timeline.js" :type "text/javascript"))
	((:style :type "text/css")
;;; margin-left is to clear the icon.
;;; the icon-size params do not work, for some reason (style from timeline css overrides -- why there and not elsewhere is mysterious)
#[[
	 body { background: #111; color: #aaa; font-family: arial, helvetica, sans-serif;}
	.timeline-event-label,.timeline-event-tape{font-size: 10px; color: #fff; background: #222; padding: 2px; margin-left:11px; margin-top: 8px}	 
	 .timeline-event-label a { color:#ff0;}
	 .timeline-event-icon {width: 16px; height:16px; }
	 
]]
	))
       ((:body :onload "onLoad();" :onresize "onResize();")
	((:div :id "my-timeline" :style "height: 500px; border: 1px solid #aaa")))))))

