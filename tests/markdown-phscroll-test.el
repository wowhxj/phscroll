;;; markdown-phscroll-test.el --- Markdown scroll tests	 -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)
(require 'markdown-mode)
(require 'markdown-phscroll)

(ert-deftest markdown-phscroll-mode-activates-in-markdown-buffers ()
  (with-temp-buffer
    (markdown-mode)
    (should markdown-phscroll-mode)
    (should phscroll-mode)))

(ert-deftest markdown-phscroll-fontifies-gfm-without-leading-pipes ()
  (with-temp-buffer
    (gfm-mode)
    (insert "Name | Description\n"
	    "-----|------------\n"
	    "Alpha | A deliberately wide table value\n")
    (font-lock-ensure)
    (goto-char (point-min))
    (search-forward "Alpha")
    (should (phscroll-get-area-at (point)))))

(ert-deftest markdown-phscroll-fontifies-tables-only ()
  (with-temp-buffer
    (markdown-mode)
    (insert "Wrapped prose with | an inline pipe.\n\n"
	    "| Name | Description |\n"
	    "|------|-------------|\n"
	    "| Alpha | A deliberately wide table value |\n\n"
	    "```text\n"
	    "| Not | A table inside a code block |\n"
	    "```\n")
    (font-lock-ensure)
    (goto-char (point-min))
    (let ((prose-pos (point))
	  (table-pos (progn (search-forward "Alpha") (point)))
	  (code-pos (progn (search-forward "Not") (point))))
      (should-not (phscroll-get-area-at prose-pos))
      (should (phscroll-get-area-at table-pos))
      (should-not (phscroll-get-area-at code-pos)))))

(ert-deftest markdown-phscroll-rescans-edited-gfm-separator ()
  (with-temp-buffer
    (gfm-mode)
    (insert "Name | Value\n"
	    "-----|------\n"
	    "One  | Two\n")
    (font-lock-ensure)
    (goto-char (point-min))
    (should (phscroll-get-area-at (point)))
    (forward-line 1)
    (let ((beg (line-beginning-position))
	  (end (line-end-position)))
      (delete-region beg end)
      (insert "not a separator")
      (font-lock-flush beg (line-end-position))
      (font-lock-ensure beg (line-end-position)))
    (goto-char (point-min))
    (should-not (phscroll-get-area-at (point)))
    (forward-line 2)
    (should-not (phscroll-get-area-at (point)))))

(ert-deftest markdown-phscroll-removes-area-after-table-edit ()
  (with-temp-buffer
    (markdown-mode)
    (insert "| Name | Value |\n"
	    "|------|-------|\n"
	    "| One  | Two   |\n")
    (font-lock-ensure)
    (goto-char (point-min))
    (should (phscroll-get-area-at (point)))
    (while (re-search-forward "^|" nil t)
      (replace-match "x"))
    (font-lock-flush)
    (font-lock-ensure)
    (goto-char (point-min))
    (should-not (phscroll-get-area-at (point)))))

(provide 'markdown-phscroll-test)
;;; markdown-phscroll-test.el ends here
