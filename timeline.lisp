(in-package :wu)

(publish :path "/timeline"
	 :function 'html-timeline)

(publish-file :path "/timeline.js"
	      :file "/misc/working/cru-timeline/timeline.js")

(defun html-timeline (req ent)
  (with-http-response (req ent)
    (with-http-body (req ent)
      (html
       (:head
	((:script :src "http://static.simile.mit.edu/timeline/api-2.3.0/timeline-api.js?bundle=true" :type "text/javascript"))
	((:script :src "timeline.js" :type "text/javascript")))
       ((:body :onload "onLoad();" :onresize "onResize();")
	((:div :id "my-timeline" :style "height: 500px; border: 1px solid #aaa")))))))

