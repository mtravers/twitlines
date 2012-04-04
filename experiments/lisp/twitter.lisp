(in-package :wu)
;(require :cl-json)
;(use-package :net.aserve)


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
   (sw::get-url (format nil "http://twitter.com/statuses/home_timeline.json")
		:basic-authorization (cons *twitter-user* *twitter-password*)
		:query `(("count" . ,count)))))

;;; only returns 20
(defun get-twitter-public-timeline ()
  (json:decode-json-from-string 
   (sw::get-url (format nil "http://twitter.com/statuses/public_timeline.json")
		)))

(defun get-twitter-search (&key (count 100) term)
  (json:decode-json-from-string 
   (sw::get-url (format nil "http://search.twitter.com/search.json")
		:query `(("q" . ,term)
			 ("rpp" . ,count))
		)))

#|
(with-open-file (s "/misc/working/cru-timeline/friend_timeline.json" :direction :output :if-exists :supersede)
  (write-string (get-twitter-friends-timeline :count 100) s))
   
(setq tj (get-twitter-friends-timeline :count 20))
|#

;;; input: array of events, lisp encoded
(defun twitter->timeline-json (twit-json)
  `((:events 
     ,@(mt:collecting
	(dolist (event twit-json)
	  (flet ((field (field &optional (from event))
		   (let ((v (mt:assocdr field from)))
		     (if (stringp v)
			 (8ify-string v)
			 v))))
	    (let ((user (field :screen_name (field :user))))
	      (mt:collect
	       (timeline-entry-json
		:user user
		:text (field :text)
		:time (field :created_at)
		:id (field :id)
		:image (field :profile_image_url (field :user)))
	       )
	      )))))))

;;; Search has a slightly different format, sigh
(defun twitter-search->timeline-json (twit-search-json)
  `((:events
     ,@(mt:collecting
	(dolist (event (mt:assocdr :results twit-search-json))
	  (flet ((field (field &optional (from event))
		   (let ((v (mt:assocdr field from)))
		     (if (stringp v)
			 (8ify-string v)
			 v))))
	    (mt:collect
	     (timeline-entry-json
	      :user (field :from_user)
	      :text (field :text)
	      :time (field :created_at)
	      :id (field :id)
	      :image (field :profile_image_url))
	     )))))))
     
  

(defun timeline-entry-json (&key user text time id image)
  `(
;;; Links show up nice in timeline, but not in bubble.
;;;  villain: /misc/sourceforge/simile-widgets-read-only/timeline/trunk/src/webapp/api/scripts/sources.js:554 createTextNode
;;; Also, see here: http://simile.mit.edu/mail/ReadMsg?listId=9&msgId=16981
    (:title . ,(linkify-string (break-string (format nil "~A: ~A" user text))))
;;; Nope, redundant.
;		 (:description . ,(field :text))
    (:start . ,time)
    
    ,@(if t ; (equal text (linkify-string text))
	  `((:link . ,(format nil "http://twitter.com/~A/status/~A" user id)))
	  nil)
;		 (:icon . ,(field :profile_image_url (field :user)))
;;; smaller, but still too big for timeline...
    (:icon . ,(format nil "http://twivatar.org/~A/mini" user))
;;; use the big one in bubble (bubble putend)
;    (:image . ,image)
    ))



(net.aserve:publish :path "/twitter.json"
		    :function 'publish-timeline-twitter
		    :content-type "application/x-javascript; charset=utf-8")

;;; "works", but inter-item spacing is wrong.  Also should look backwards for word boundary as well.
(defun break-string (s)
  (let ((split (position #\Space s :start (floor (length s) 2))))
    (if split
	(format nil "~A <br/>~A" (subseq s 0 split) (subseq s split))
	s
	)))

(defun publish-timeline-twitter (req ent)
  (with-http-response (req ent :content-type "application/x-javascript; charset=utf-8")
    (with-http-body (req ent :external-format (crlf-base-ef :utf-16))
      (let ((search (request-query-value "search" req)))
	(json:encode-json 
	 (if search
	     (twitter-search->timeline-json
	      (get-twitter-search :count 100 :term search))
	     (twitter->timeline-json 
	      (get-twitter-friends-timeline :count 100)))
	 net.aserve::*html-stream*)))))	;??? why isn't this defined.
	       

;;; motherfucking lisp can't handle non-8-bit-chars.  What decade is this?
;;; Actually its aserve dying, not lisp itself. Maybe time to switch to fucking hunchentoot.
(defun 8ify-string (s)
  (dotimes (n (length s))
    (unless (typep (char s n) 'standard-char)
      (setf (char s n) #\-)))
  s)

(defparameter url-scanner (cl-ppcre:create-scanner "http://\\S+"))
(defparameter @-scanner (cl-ppcre:create-scanner "@([A-Za-z0-9-]+)"))
(defparameter uname-scanner  (cl-ppcre:create-scanner "\\A([A-Za-z0-9-]+):"))

(defun linkify-string (s)
  (setf s (cl-ppcre:regex-replace-all url-scanner s "<a href='\\&' target='_blank'>\\&</a>"))
  (setf s (cl-ppcre:regex-replace-all uname-scanner s "<a href='http://twitter.com/\\1' target='_blank'>\\1</a>:"))
  (cl-ppcre:regex-replace-all @-scanner s "@<a href='http://twitter.com/\\1' target='_blank'>\\1</a>")
  )
