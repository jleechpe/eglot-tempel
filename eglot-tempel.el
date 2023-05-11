;;; eglot-tempel.el --- Use eglot as inline template expander -*- lexical-binding: t -*-

;; Copyright (C) 2022 Jeffrey Walsh

;; Author: Jeff Walsh <fejfighter@gmail.com>
;; Created: 2022
;; Version: 0.4
;; Package-Requires: ((eglot "1.9")  (tempel "0.5") (emacs "24.1"))
;; Keywords: convenience, languages, tools
;; URL: https://github.com/fejfighter/eglot-tempel

;;; Commentary:

;; LSP can provide inline/template hinting for function completion,
;; Currently eglot only checks for yasnippet to enable this
;; feature.  This package patches the function or mocks yasnippet
;; (depending on what is installed) to use tempel.el for that feature
;; by translating the LSP template into a sexp used by tempel.el

(require 'tempel)
(require 'eglot)

;;; Code:
(defun eglot-tempel--convert (snippet)
  "Convert a SNIPPET returned from Eglot into a format usefful for tempel."
  (if (string-match "\\(\${\\([1-9]\\):\\([^}]*\\)}\\)\\|\\(\$[1-9]\\)\\|\\(\$0\\)\\|\\(\\.\\.\\.\\)" snippet 0)
      (cond
       ((match-string 1 snippet)
	(append `(,(substring snippet 0 (match-beginning 0))
  		  ,(list 'p (match-string 3 snippet) (match-string 2 snippet)))
		(eglot-tempel--convert (substring snippet (match-end 0)))))
       ((match-string 4 snippet)
	(append `(,(substring snippet 0 (match-beginning 0)) p)
		(eglot-tempel--convert (substring snippet (match-end 0)))))
       ((match-string 5 snippet)
	(append (list (substring snippet 0 (match-beginning 0)) 'q)
		(let ((rest (substring snippet (match-end 0))))
		  (if (= (length rest) 0) ()
		    (list rest)))))
       ((match-string 6 snippet)
	(append `(, (substring snippet 0 (match-beginning 0))
		    ,(list 'p "..."))
		    (eglot-tempel--convert (substring snippet (match-end 0))))))
    (list snippet 'q)))

(defun tempel-expand-yas-snippet (snippet &optional START END EXPAND-ENV)
  "Emulate yasnippet expansion function call.
SNIPPET - snippet for converting.
START END EXPAND-ENV are all ignored."
    (ignore START END EXPAND-ENV)
    (tempel-insert (eglot-tempel--convert snippet)))

(defun eglot-tempel--snippet-expansion-fn ()
  "An override of ‘eglot--snippet-expansion-fn’."
  #'tempel-expand-yas-snippet)

;;;###autoload
(define-minor-mode eglot-tempel-mode
  "Toggle eglot template support by tempel."
  :global t
    (if eglot-tempel-mode
        (advice-add #'eglot--snippet-expansion-fn
                    :override #'eglot-tempel--snippet-expansion-fn)
      (advice-remove #'eglot--snippet-expansion-fn
                     #'eglot-tempel--snippet-expansion-fn)))

(provide 'eglot-tempel)
;;; eglot-tempel.el ends here
