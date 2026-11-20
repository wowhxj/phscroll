;;; phscroll-test.el --- Tests for partial scrolling  -*- lexical-binding: t; -*-

;;; Code:

(require 'ert)
(require 'phscroll)

(ert-deftest phscroll-column-uses-pixel-width-when-enabled ()
  (with-temp-buffer
    (insert "abcd")
    (setq-local phscroll-calculate-in-pixels t)
    (cl-letf (((symbol-function 'frame-char-width)
	       (lambda (&optional _) 10))
	      ((symbol-function 'phscroll-text-pixel-width)
	       (lambda (_beg _end &optional _window) 100)))
      (should (= (phscroll-column (point-max)) 10)))))

(ert-deftest phscroll-scroll-point-uses-pixel-coordinate ()
  (with-temp-buffer
    (insert "abcdefghijklmnopqrst")
    (let ((area (phscroll-region (point-min) (point-max))))
      (setq-local phscroll-calculate-in-pixels t)
      (goto-char (1- (point-max)))
      (let ((hscroll-margin 0)
	    (hscroll-step 1))
	(cl-letf (((symbol-function 'frame-char-width)
		   (lambda (&optional _) 10))
		  ((symbol-function 'phscroll-text-pixel-width)
		   (lambda (beg end &optional _window)
		     (* 20 (- end beg))))
		  ((symbol-function 'phscroll-window-width-at)
		   (lambda (_pos _window) 10))
		  ((symbol-function 'phscroll-update-area-display)
		   #'ignore))
	  (phscroll-scroll-point (point))
	  (should (= (phscroll-get-scroll-column area) 29)))))))

(ert-deftest phscroll-pixel-width-ignores-existing-line-veils ()
  (with-temp-buffer
    (insert "abcdefghij")
    (let ((ov (make-overlay (point-min) (+ (point-min) 3))))
      (overlay-put ov 'phscroll-line-veil t)
      (overlay-put ov 'display ">")
      (overlay-put ov 'after-string " ")
      (cl-letf (((symbol-function 'window-text-pixel-size)
		 (lambda (_window beg end &rest _)
		   (should-not (overlay-get ov 'display))
		   (should-not (overlay-get ov 'after-string))
		   (cons (* 10 (- end beg)) 10))))
	(should (= (phscroll-text-pixel-width
		    (point-min) (point-max))
		   100)))
      (should (equal (overlay-get ov 'display) ">"))
      (should (equal (overlay-get ov 'after-string) " ")))))

(ert-deftest phscroll-pixel-prefix-covers-scroll-boundary ()
  (with-temp-buffer
    (insert "abc")
    (let ((str (phscroll-buffer-substring (point-min) (point-max))))
      (cl-letf (((symbol-function 'frame-char-width)
		 (lambda (&optional _) 10))
		((symbol-function 'phscroll-find-max-pos-fits-in-width-px)
		 (lambda (_beg _end _width &optional _window)
		   (cons (+ (point-min) 1) 15)))
		((symbol-function 'phscroll-text-pixel-width)
		 (lambda (_beg _end &optional _window) 30)))
	(let ((result (phscroll-substring-over-width-px str 2)))
	  (should (= (cdr (car result)) (+ (point-min) 2)))
	  (should (= (cdr result) 3.0)))))))

(ert-deftest phscroll-pixel-mode-clips-left-by-rendered-width ()
  (with-temp-buffer
    (insert "abcdefghij")
    (setq-local phscroll-calculate-in-pixels t)
    (let ((line-beg (line-beginning-position))
	  (line-end (line-end-position)))
      (cl-letf (((symbol-function 'phscroll-window-width-at)
		 (lambda (_pos _window) 10))
		((symbol-function 'phscroll-substring-over-width-px)
		 (lambda (str width)
		   (if (= (car str) line-beg)
		       (cons (cons (car str) (+ (car str) 2)) width)
		     (cons str width)))))
	(phscroll-update-current-line-display
	 line-beg line-end 6 nil)
	(should
	 (cl-some (lambda (ov)
		    (and (overlay-get ov 'phscroll-line-veil)
			 (= (overlay-start ov) line-beg)
			 (= (overlay-end ov) (+ line-beg 2))))
		  (overlays-in line-beg line-end)))))))

(ert-deftest phscroll-shifts-visible-alignment-spaces ()
  (with-temp-buffer
    (insert "abcdef" (propertize "    " 'display '(space :align-to 12)) "|xyz")
    (goto-char (point-min))
    (let ((phscroll-calculate-in-pixels nil)
          (phscroll-use-fringe t))
      (cl-letf (((symbol-function 'phscroll-window-width-at)
                 (lambda (_pos _window) 10)))
        (phscroll-update-current-line-display (point-min) (point-max) 3 nil)
        (should (equal (get-char-property 7 'display) '(space :align-to 9)))
        (should-not (get-char-property 11 'display)) ; Final visible pipe.
        (should (equal (get-char-property 12 'display) '(right-fringe right-arrow)))
        (phscroll-remove-line-veils (point-min) (point-max))
        (phscroll-update-current-line-display (point-min) (point-max) 8 nil)
        (let ((veil (cl-find-if (lambda (ov) (overlay-get ov 'phscroll-line-veil))
                                (overlays-at (point-min)))))
          (should (= (overlay-end veil) 11))
          (should (equal (overlay-get veil 'display)
                         '(space :width 4))))))))

(provide 'phscroll-test)
;;; phscroll-test.el ends here
