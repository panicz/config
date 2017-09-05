; emacs -batch -f batch-byte-compile scheme.el

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))

(package-initialize)

(require 'rainbow-delimiters)

(require 'rainbow-mode)

(require 'web-mode)

(add-hook 'c-mode-hook #'hs-minor-mode)
(add-hook 'c++-mode-hook #'hs-minor-mode)
(add-hook 'js-mode-hook #'hs-minor-mode)
(add-hook 'javascript-mode-hook #'hs-minor-mode)
(add-hook 'java-mode-hook #'hs-minor-mode)
(add-hook 'php-mode-hook #'hs-minor-mode)
(add-hook 'python-mode-hook #'hs-minor-mode)
(add-hook 'scheme-mode-hook #'hs-minor-mode)
(add-hook 'scheme-mode-hook #'pretty-symbols-mode)
(add-hook 'scheme-mode-hook #'rainbow-delimiters-mode)

(add-hook 'emacs-lisp-mode-hook #'hs-minor-mode)
(add-hook 'common-lisp-mode-hook #'hs-minor-mode)

(global-set-key "\C-c\C-w" 'hs-hide-all)
(global-set-key "\C-c\C-s" 'hs-show-all)

(setq
 backup-by-copying t      ; don't clobber symlinks
 backup-directory-alist
 '(("." . "~/.emacs.d/saves"))    ; don't litter my fs tree
 delete-old-versions t
 kept-new-versions 6
 kept-old-versions 2
 version-control t)

(defun toggle-hiding ()
  (interactive)
  (if (eq major-mode 'web-mode)
      (web-mode-fold-or-unfold)
    (hs-toggle-hiding)))

(global-set-key "\C-]" 'toggle-hiding)

(defun pear/php-mode-init()
  "Set some buffer-local variables."
  (setq case-fold-search t)
  (setq indent-tabs-mode nil)
  (setq fill-column 78)
  (c-set-offset 'arglist-cont 0)
  (setq c-basic-offset 2)
  (c-set-offset 'arglist-intro '+)
  (c-set-offset 'arglist-close '0)
)

(require 'cl)

(defun find-files-upwards (files-to-find)
  "Recursively searches each parent directory starting from the default-directory.
looking for a file with name file-to-find.  Returns the path to it
or nil if not found."
  (labels
      ((find-file-r (path)
                    (let* ((parent (file-name-directory path))
                           (possible-files (mapcar
					    #'(lambda(file-to-find)
						(concat parent file-to-find))
					    files-to-find)))
                      (cond
                       ((find-if #'(lambda(possible-file)
				     (file-exists-p possible-file))
				 possible-files)) ; Found
                       ;; The parent of ~ is nil and the parent of / is itself.
                       ;; Thus the terminating condition for not finding the file
                       ;; accounts for both.
                       ((or (null parent) 
			    (equal parent (directory-file-name parent)))
			nil) ; Not found
                       (t (find-file-r 
			   (directory-file-name parent))))))) ; Continue
    (find-file-r default-directory)))

(let ((my-tags-file (find-files-upwards '("TAGS"))))
  (when my-tags-file
    (message "Loading tags file: %s" my-tags-file)
    (visit-tags-table my-tags-file)))

(add-hook 'php-mode-hook 'pear/php-mode-init)

(require 'php-mode)

(require 'geiser)

(setq geiser-active-implementations '(guile))

(setq geiser-repl-use-other-window nil)

(setq geiser-guile-load-path '("." ".." "../.." "~/.guile.d"))

(require 'ac-geiser)

(add-hook 'geiser-mode-hook 'ac-geiser-setup)

(add-hook 'geiser-repl-mode-hook 'ac-geiser-setup)

(eval-after-load "auto-complete"
    '(add-to-list 'ac-modes 'geiser-repl-mode))

(run-guile)

(require 'auto-complete)

(global-auto-complete-mode 't)

;(geiser-add-to-load-path ".")
;(geiser-add-to-load-path "..")
;(geiser-add-to-load-path "../..")
;(geiser-add-to-load-path "/home/panicz/.guile.d")

(defadvice save-buffers-kill-emacs (around no-query-kill-emacs activate)
  "Prevent annoying \"Active processes exist\" query when you quit Emacs."
  (flet ((process-list ())) ad-do-it))


(global-set-key [(control right)] 'forward-word)
(global-set-key [(control left)] 'backward-word)

(global-set-key "\M-0" 'forward-sexp)
(global-set-key "\M-9" 'backward-sexp)

(global-set-key "\M-\d" 'backward-kill-sexp)

(menu-bar-mode nil)

(setq inhibit-startup-message t)
(setq inhibit-startup-screen t)
(setq column-number-mode t)
(setq display-time-24hr-format t)
(setq display-time-load-average nil)
(setq linum-format "%d ")
(global-set-key "\C-c\C-l" 'global-linum-mode)

(display-time)
(setq display-time-load-average nil)
(show-paren-mode t)
(setq delete-selection-mode t)
(global-set-key "\C-h" 'goto-line)

(require 'auto-complete)

(defun join-strings (separator strings)
  (mapconcat 'identity strings separator))

(defun find-sexp-at-point ()
  (interactive)
  (let ((sexp (thing-at-point 'sexp)))
    (cond ((string-match-p "^\".*\"$" sexp)
	   (find-file (substring sexp 1 -1)))
	  ((string-match-p "^[^ ()]+$" sexp)
	   (find-tag sexp))
	  ((string-match-p "^([^()]+)$" sexp)
	   (geiser-edit-module sexp))
	  )))

(defun directory-containing (file)
  (join-strings "/" (butlast (split-string file "/") 1)))

(defun rgrep-sexp-at-point ()
  (interactive)
  (let ((sexp (thing-at-point 'sexp))
	(dir (directory-containing (find-files-upwards '(".git" ".hg"
							 ".dir-locals.el"
							 "TAGS")))))
    (rgrep sexp "*.[ch]" dir)))

(eval-after-load "grep"
  '(grep-compute-defaults))

(defun find-sexp-at-point/other-window ()
  (interactive)
  (let ((sexp (thing-at-point 'sexp)))
    (cond ((string-match-p "^\".*\"$" sexp)
	   (find-file-other-window (substring sexp 1 -1)))
	  ((string-match-p "^[^ ()]+$" sexp)
	   (find-tag-other-window sexp)))))

;; ((string-match-p "^(.*)$" sexp)
;;  (print "list"))
;; ((string-match-p "^#(.*)$" sexp)
;;  (print "vector"))

(global-set-key (kbd "<f1>") 'find-sexp-at-point/other-window)
(global-set-key (kbd "<f2>") 'find-sexp-at-point)

(global-set-key (kbd "<f3>") 'split-window-horizontally)
(global-set-key (kbd "<f4>") 'split-window-vertically)

(global-set-key (kbd "<f5>") 'rgrep-sexp-at-point)
(global-set-key (kbd "<f6>") 'shrink-window-horizontally)

(global-set-key (kbd "<f7>") 'enlarge-window)
(global-set-key (kbd "<f8>") 'shrink-window)


;; (mapcar #'buffer-name (buffer-list))
(defvar *restricted-buffers*
  '("TAGS"
    "*Backtrace*"
    "*Messages*"
    "*scratch*"
    " *Minibuf-1*"
    "*Help*"
    "* Guile REPL *"
    " *Minibuf-0*"
    " *code-conversion-work*"
    " *Echo Area 0*"
    " *Echo Area 1*"
    " tq-temp-Guile REPL"
    " *geiser font lock*"
    "*Buffer List*"
    "*geiser messages*"
    "*Geiser dbg*"
    "*Directory*"
    "*Completions*"))

(defun next-user-buffer ()
  "Switch to next buffer that is not on the *restricted-buffers* list"
  (interactive)
  (next-buffer)
  (if (set-difference (mapcar #'buffer-name (buffer-list)) *restricted-buffers*)
      (while (member (buffer-name) *restricted-buffers*)
	(next-buffer))))

(defun previous-user-buffer ()
  "Switch to previous buffer that is not on the *restricted-buffers* list"
  (interactive)
  (previous-buffer)
  (if (set-difference (mapcar #'buffer-name (buffer-list)) 
		      *restricted-buffers*
		      :test #'equal)
      (while (member (buffer-name) *restricted-buffers*)
	(previous-buffer))))

(defun kill-whitespace-or-sexp ()
  "Kill the whitespace between two non-whitespace characters"
  (interactive "*")
  (save-excursion
    (save-restriction
      (save-match-data
	(if (string-match "[ \t\r\n]" (string (char-after)))
	    (progn
	      ;;(re-search-backward "[^ \t\r\n]" nil t)
	      (re-search-forward "[ \t\r\n]+" nil t)
	      (replace-match "" nil nil))
	  (kill-sexp))))))

(defun unmark-forward-paragraph ()
  (interactive)
  (forward-paragraph))

(global-set-key (kbd "M-<delete>") 'kill-whitespace-or-sexp)


(global-set-key [(meta down)] 'next-user-buffer)
(global-set-key [(meta up)] 'previous-user-buffer)

(global-set-key [(meta right)] 'next-multiframe-window)
(global-set-key [(meta left)] 'previous-multiframe-window)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("f641bdb1b534a06baa5e05ffdb5039fb265fde2764fbfd9a90b0d23b75f3936b" "8ea9451c2f2dd285da5dc19288ee6d5b8c55b91fb3ed038f8761efc457467efa" "fc89666d6de5e1d75e6fe4210bd20be560a68982da7f352bd19c1033fb7583ba" "72ac74b21322d3b51235f3b709c43c0721012e493ea844a358c7cd4d57857f1f" "a81bc918eceaee124247648fc9682caddd713897d7fd1398856a5b61a592cb62" default)))
 '(safe-local-variable-values
   (quote
    ((c-fill-style . "BSD")
     (c-indent-style . "bsd")
     (c-default-style . "bsd")
     (c-indent-style . "linux")))))


(put 'with-default 'scheme-indent-function 1)
(put 'without-default 'scheme-indent-function 1)
(put 'specify 'scheme-indent-function 1)

(put 'for 'scheme-indent-function 3)

(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")

;(load-theme 'billw)
 
(autoload 'scheme-smart-complete "scheme-complete" nil t)

(eval-after-load 'scheme
  '(define-key scheme-mode-map "\e\t" 'scheme-smart-complete))


(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(rainbow-delimiters-depth-1-face ((t (:foreground "color-214"))))
 '(rainbow-delimiters-depth-2-face ((t (:foreground "color-190"))))
 '(rainbow-delimiters-depth-3-face ((t (:foreground "color-118"))))
 '(rainbow-delimiters-depth-4-face ((t (:foreground "color-46"))))
 '(rainbow-delimiters-depth-5-face ((t (:foreground "color-39"))))
 '(rainbow-delimiters-depth-6-face ((t (:foreground "color-27"))))
 '(rainbow-delimiters-depth-7-face ((t (:foreground "color-93"))))
 '(rainbow-delimiters-depth-8-face ((t (:foreground "color-128"))))
 '(rainbow-delimiters-depth-9-face ((t (:foreground "color-160"))))
 '(rainbow-delimiters-mismatched-face ((t (:inherit rainbow-delimiters-unmatched-face :stipple nil :background "red" :foreground "black" :inverse-video t))))
 '(rainbow-delimiters-unmatched-face ((t (:background "red" :foreground "white")))))
