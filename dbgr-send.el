(require 'load-relative)
(require-relative-list
 '("dbgr-buffer"))

(defvar dbgr-send-command-fn
  (function (lambda (command-str) 
	    (comint-goto-process-mark)
	    (insert command-str)
	    (comint-send-input))) ;; Note: comint specific!
  "Should be a function which takes one string parameter without
any trailing newline. The function will be applied in the debugger process
buffer.")

;; Here are some other possibilities for functions.
;; Comint-specific: doesn't insert input into the buffer which is
;; what gud-call does.
;;   (apply comint-input-sender (list proc command))
;;
;; Works on any process-oriented buffer, not just comint.
;;   (process-send-string (get-buffer-process (current-buffer))
;;                        (concat command "\n"))


(defun dbgr-send-command (command &optional opt-buffer)
  "Invoke the debugger COMMAND adding that command and the
results into the command buffer."
  (let* ((buffer (or opt-buffer (current-buffer)))
	 (cmdbuf (dbgr-get-cmdbuf buffer)))
    (if cmdbuf
	(with-current-buffer cmdbuf
	  (let ((proc (get-buffer-process cmdbuf)))
	    (or proc (error "Command process buffer is not running"))
	    (funcall dbgr-send-command-fn command)
	    ))
      (error "Can't find command process buffer")
      )))

(defun dbgr-expand-format-string (fmt-str &optional opt-num-str opt-buffer)
  "Expands commands format characters inside FMT-STRING using values
from the debugging session. OPT-NUM-STR is an optional number string.
If present %-escapes in the string arguments are expanded. These are:

  %f -- Name (without directory) of current source file.
  %F -- Name (without directory or extension) of current source file.
  %d -- Directory of current source file.
  %l -- Number of current source line.
  %p -- Prefix argument to the command (if any) as a number.
"
  (let* ((buffer (or opt-buffer (current-buffer)))
	 (srcbuf (dbgr-get-srcbuf buffer))
	 (src-file-name (and srcbuf (buffer-file-name srcbuf)))
	 (num-arg (and opt-num-str (int-to-string opt-num-str)))
	 result)
    (while (and fmt-str
		(let ((case-fold-search nil))
		  (string-match "\\([^%]*\\)%\\([dfFlp]\\)" fmt-str)))
      (let* ((key-str (match-string 2 fmt-str))
	     (key (string-to-char key-str)))
	(setq result 
	      (concat 
	       result (match-string 1 fmt-str) 
	       (cond
		((eq key ?f)
		 (or (and src-file-name
			  (file-name-nondirectory src-file-name))
		     "*source-file-not-found-for-%f*"))
		((eq key ?F)
		 (or (and src-file-name
			  (file-name-sans-extension
			   (file-name-nondirectory src-file-name)))
		     "*source-file-not-found-for-%F"))
		((eq key ?d)
		 (or (and src-file-name
			  (file-name-directory src-file-name))
		     "*source-file-not-found-for-%d"))
		((eq key ?l)
		 (if srcbuf
		     (with-current-buffer srcbuf
		       (int-to-string
			(save-restriction
			  (widen)
			  (+ (count-lines (point-min) (point))
			     (if (bolp) 1 0)))))
		   "source-buffer-not-found-for-%l"))
		;; ((eq key ?e)
		;;  (gud-find-expr))
		;; ((eq key ?a)
		;;  (gud-read-address))
		;; ((eq key ?c)
		;;   (gud-find-class srcbuf))
		((eq key ?p) num-arg)
		(t key)))))
      (setq fmt-str (substring fmt-str (match-end 2))))
    ;; There might be text left in FMT-STR when the loop ends.
    (concat result fmt-str)))

(provide 'dbgr-send)
