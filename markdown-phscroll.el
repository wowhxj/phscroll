;;; markdown-phscroll.el --- Scroll Markdown tables  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Randolph

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of
;; the License, or (at your option) any later version.

;;; Commentary:

;; Enable horizontal scrolling for tables in `markdown-mode' and
;; `gfm-mode' while leaving line wrapping enabled elsewhere.

;;; Code:

(require 'markdown-mode)
(require 'phscroll)

(defvar-local markdown-phscroll-font-lock-keywords
    (list '(markdown-phscroll--fontify)))

;;;###autoload
(define-minor-mode markdown-phscroll-mode
  "Apply partial horizontal scrolling to Markdown tables."
  :type 'boolean
  :init-value nil
  :group 'phscroll
  (if markdown-phscroll-mode
      (progn
	(setq-local phscroll-update-area-display-on-modified nil)
	(phscroll-mode 1)
	(font-lock-add-keywords
	 nil markdown-phscroll-font-lock-keywords t)
	(font-lock-flush))
    (font-lock-remove-keywords
     nil markdown-phscroll-font-lock-keywords)
    (setq-local phscroll-update-area-display-on-modified t)
    (phscroll-delete-all)
    (phscroll-mode -1)))

(defun markdown-phscroll--fontify (limit)
  "Create or remove table scrolling areas before LIMIT."
  (when markdown-phscroll-mode
    (save-match-data
      (save-excursion
	(save-restriction
	  (widen)
	  (let ((scan-beg (phscroll-line-begin))
		(scan-end limit))
	    ;; A GFM separator determines whether neighboring rows form a
	    ;; table, so rescan the whole existing area after partial edits.
	    (dolist (area (phscroll-enum-area scan-beg scan-end))
	      (setq scan-beg (min scan-beg (phscroll-area-begin area))
		    scan-end (max scan-end (phscroll-area-end area))))
	    (phscroll-invalidate-region scan-beg scan-end)
	    (goto-char scan-beg)
	    (let ((unscrolled-beg scan-beg))
	      (while (re-search-forward "|" scan-end t)
		(when (markdown-table-at-point-p)
		  (let ((table-beg (markdown-table-begin))
			(table-end (markdown-table-end)))
		    (when (< unscrolled-beg table-beg)
		      (phscroll-remove-region unscrolled-beg table-beg))
		    (phscroll-cover-region table-beg table-end)
		    (setq unscrolled-beg table-end)
		    (goto-char table-end))))
	      (when (< unscrolled-beg scan-end)
		(phscroll-remove-region unscrolled-beg scan-end))))))))
  nil)

;;;###autoload
(defun markdown-phscroll-activate ()
  "Enable `markdown-phscroll-mode' in Markdown buffers."
  (interactive)
  (add-hook 'markdown-mode-hook #'markdown-phscroll-mode))

;;;###autoload
(defun markdown-phscroll-deactivate ()
  "Stop enabling `markdown-phscroll-mode' in Markdown buffers."
  (interactive)
  (remove-hook 'markdown-mode-hook #'markdown-phscroll-mode))

(with-eval-after-load "markdown-mode"
  (markdown-phscroll-activate))

(provide 'markdown-phscroll)
;;; markdown-phscroll.el ends here
