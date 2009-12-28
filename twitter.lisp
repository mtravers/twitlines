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
	    (let ((user (field :screen_name (field :user))))
	      (mt:collect
	       `(
;;; Links show up nice in timeline, but not in bubble.
;;;  villain: /misc/sourceforge/simile-widgets-read-only/timeline/trunk/src/webapp/api/scripts/sources.js:554 createTextNode
		 (:title . ,(format nil "~A: ~A" user (linkify-string (break-string (field :text)))))
;;; Nope, redundant.
;		 (:description . ,(field :text))
		 (:start . ,(field :created_at))
;		 (:link . ,(format nil "http://twitter.com/~A/status/~A" user (field :id)))
		 (:link . ,(if (equal (field :text) (linkify-string (field :text)))
			       (format nil "http://twitter.com/~A/status/~A" user (field :id))
			       nil))
;		 (:icon . ,(field :profile_image_url (field :user)))
;;; smaller, but still too big for timeline...
		 (:icon . ,(format nil "http://twivatar.org/~A/mini" user))
;;; use the big one in bubble
		 (:image . ,(field :profile_image_url (field :user)))
		 ))
	      )))))))

(net.aserve:publish :path "/twitter.json"
		    :function 'publish-timeline-twitter
		    :content-type "application/x-javascript; charset=utf-8")

;;; "works", but inter-item spacing is wrong.  Also needs to look for a word boundary, duh.
(defun break-string (s)
  (let ((split (position #\Space s :start (floor (length s) 2))))
    (if split
	(format nil "~A<br/>~A" (subseq s 0 split) (subseq s split))
	s
	)))

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

(defparameter url-scanner (cl-ppcre:create-scanner "http://\\S+"))
(defun linkify-string (s)
  (cl-ppcre:regex-replace-all url-scanner s "<a href='\\&' target='twitgraphview'>\\&</a>")
  )
