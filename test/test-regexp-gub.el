(require 'test-simple)
(load-file "../realgud/common/buffer/command.el")
(load-file "../realgud/debugger/gub/init.el")
(load-file "./regexp-helper.el")

(test-simple-start)

; Some setup usually done in setting up the buffer.
; We customize this for this debugger.
; FIXME: encapsulate this.
(setq dbg-name "gub")

(note "gub prompt")
(set (make-local-variable 'prompt-pat)
     (gethash "prompt" realgud-gub-pat-hash))
(prompt-match "gub[0]: ")
(prompt-match "gub[20]: ")
(prompt-match "gub[32@5]: ")

(setup-regexp-vars realgud-gub-pat-hash)
(set (make-local-variable 'tb)
     (gethash "lang-backtrace"  realgud-gub-pat-hash))

(note "go lang traceback")
(setq text "/usr/local/go/src/pkg/runtime/panic.c:482 (0x805c956)")

(assert-t (numberp (tb-loc-match text)) "go traceback location")
(assert-equal "/usr/local/go/src/pkg/runtime/panic.c"
	      (match-string (realgud-loc-pat-file-group tb)
			    text) "extract traceback file name")
(assert-equal "482"
	      (match-string (realgud-loc-pat-line-group tb)
			    text)   "extract traceback line number")

(end-tests)
