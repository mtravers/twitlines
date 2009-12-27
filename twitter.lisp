(in-package :cl-user)

(use-package :net.aserve)


(require :cl-json)


(defvar *twitter-user* "mtraven")
(defvar *twitter-password* "wasteoftime")

(defvar *twitter-api-friends-template* 
  "http://twitter.com/statuses/friends/~a.json")

(defvar *twitter-api-followers-template* 
  "http://twitter.com/statuses/followers/~a.json")

(defvar *twitter-api-followers-template* 
  "http://twitter.com/statuses/followers/~a.json")

(defun get-url-authenticated (url name password)
  (sw::get-url url :basic-authorization (cons name password)))

(defun get-twitter-friends-timeline (&key (count 100))
  (json:decode-json-from-string 
   (sw::get-url (format nil "http://twitter.com/statuses/friends_timeline.json")
		:basic-authorization (cons *twitter-user* *twitter-password*)
		:query `(("count" . ,count)))))

'(with-open-file (s "/misc/working/cru-timeline/friend_timeline.json" :direction :output :if-exists :supersede)
  (write-string (get-twitter-friends-timeline :count 100) s))
   
(setq tj (get-twitter-friends-timeline :count 20))

;;; input: array of events, lisp encoded
(defun twitter->timeline-json (twit-json)
  `(; whatevers
    (:events 
     ,@(mt:collecting
	(dolist (event twit-json)
	  (flet ((field (field &optional (from event))
		   (let ((v (mt:assocdr field from)))
		     (if (stringp v)
			 (8ify-string v)
			 v))))
	  (mt:collect
	   `((:title . ,(format nil "~A: ~A" (field :screen_name (field :user)) (field :text)))
	     (:start . ,(field :created_at))
;	   (:link . ...)
	   ))))))))

(net.aserve:publish :path "/twitter.json"
		    :function 'publish-timeline-twitter
		    :content-type "application/x-javascript; charset=utf-8")

(defun publish-timeline-twitter (req ent)
  (with-http-response (req ent :content-type "application/x-javascript; charset=utf-8")
    (with-http-body (req ent :external-format (crlf-base-ef :utf-16))
      (json:encode-json 
       (twitter->timeline-json 
	(get-twitter-friends-timeline :count 100))
       net.aserve::*html-stream*))))	;??? why isn't this defined.
	       

;;; motherfucking lisp can't handle non-8-bit-chars.  What decade is this?
;;; Actually its aserve dying, not lisp itself. Maybe time to switch to fucking hunchentoot.
(defun 8ify-string (s)
  (dotimes (n (length s))
    (unless (typep (char s n) 'standard-char)
      (setf (char s n) #\-)))
  s)