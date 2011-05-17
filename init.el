(message "*****  .emacs loading  *****")

;=== Emacs Configuration
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq initial-scratch-message ";; Welcome to *scratch*, a built in lisp interpreter. 
;; Evaluate lisp expresions here with C-j.
n")
(setq make-backup-files nil)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(show-paren-mode t)
(blink-cursor-mode nil)
;(explicit-shell-file-name nil)

;; Always start in a bash terminal session if no file is specified
;(term "/bin/bash")

;; Inhibit startup message
(setq inhibit-startup-screen t)
;; Do not make backup files
(setq make-backup-files nil)
;; When emacs asks for "yes" or "no", let "y" or "n" suffice
(fset 'yes-or-no-p 'y-or-n-p)
;; Switch buffers the easy way
(iswitchb-mode 1)
;; Scroll one line (not half a page) when moving past the bottom of
;; the window
(setq scroll-step 1)
;; Show keystrokes in minibuffer immediately
(setq echo-keystrokes 0.01)
;(setq tab-width 4) ; ??
;(global-font-lock-mode t) ;colors not displaying correctly? use screen
;(setq inhibit-splash-screen t)

;; Show column-number in the mode line
(column-number-mode 1)

;; ==================================================
;; Global key bindings
;; ==================================================
;; Go to line N
(global-set-key (kbd "\M-g") 'goto-line)

;; Similar to "C-l" but places me more to the top. I use this a lot.
;(global-set-key (kbd "C-\'f6") '(lambda nil "" (interactive) (recenter 8)))

;; Use electric buffer list
(global-set-key (kbd "\C-x\C-b") 'electric-buffer-list)

(add-to-list 'load-path' "~/Dropbox/.emacs.d")
(setq load-path (cons "~/Dropbox/.emacs.d/site-lisp" load-path))
(setq load-path (cons "~/Dropbox/.emacs.d/org-7.4/lisp" load-path))

;;(global-font-lock-mode 1)

;=== php-mode
(autoload 'php-mode "php-mode" "PHP editing mode" t)
(add-to-list 'auto-mode-alist '("\\.php\\'" . php-mode))
(add-to-list 'auto-mode-alist '("\\.phph\\'" . php-mode))
(add-to-list 'auto-mode-alist '("\\.module$" . php-mode))

;=== org-mode
(require 'org-install)
(add-to-list 'auto-mode-alist '("\\.\\(org\\|org_archive\\|txt\\)$" . org-mode))
(define-key global-map "\C-cl" 'org-store-link)
(define-key global-map "\C-ca" 'org-agenda)
(define-key global-map "\C-cb" 'org-iswitchb)
(setq org-log-done t)
(setq org-directory "~/Dropbox/org")
(setq org-default-notes-file (concat org-directory "/refile.org"))
(setq org-agenda-files (file-expand-wildcards (concat org-directory "/*.org")))
;; (setq org-agenda-files (list (concat org-directory "/work.org")
;;                              (concat org-directory "/business.org")
;;                              (concat org-directory "/home.org")))

;=== org-mode clock
;; from http://doc.norang.ca/org-mode.html#Clocking
;;
;; Resume clocking tasks when emacs is restarted
(org-clock-persistence-insinuate)
;;
;; Yes it's long... but more is better ;)
(setq org-clock-history-length 28)
;; Resume clocking task on clock-in if the clock is open
(setq org-clock-in-resume t)
;; Change task state to NEXT when clocking in
;(setq org-clock-in-switch-to-state (quote bh/clock-in-to-next))
;; Separate drawers for clocking and logs
(setq org-drawers (quote ("PROPERTIES" "LOGBOOK" "CLOCK")))
;; Save clock data in the CLOCK drawer and state changes and notes in the LOGBOOK drawer
(setq org-clock-into-drawer "CLOCK")
;; Sometimes I change tasks I'm clocking quickly - this removes clocked tasks with 0:00 duration
(setq org-clock-out-remove-zero-time-clocks t)
;; Clock out when moving task to a done state
(setq org-clock-out-when-done t)
;; Save the running clock and all clock history when exiting Emacs, load it on startup
(setq org-clock-persist (quote history))
;; Enable auto clock resolution for finding open clocks
(setq org-clock-auto-clock-resolution (quote when-no-clock-is-running))
;; Include current clocking task in clock reports
(setq org-clock-report-include-clocking-task t)

(setq bh/keep-clock-running nil)

(defun bh/clock-in ()
  (interactive)
  (setq bh/keep-clock-running t)
  (org-agenda nil "c"))

(defun bh/clock-out ()
  (interactive)
  (setq bh/keep-clock-running nil)
  (when (org-clock-is-active)
    (org-clock-out)))

(defun bh/clock-in-default-task ()
  (save-excursion
    (org-with-point-at org-clock-default-task
      (org-clock-in))))

(defun bh/clock-out-maybe ()
  (when (and bh/keep-clock-running (not org-clock-clocking-in) (marker-buffer org-clock-default-task))
    (bh/clock-in-default-task)))

(add-hook 'org-clock-out-hook 'bh/clock-out-maybe 'append)

;; Remove empty CLOCK drawers on clock out
(defun bh/remove-empty-drawer-on-clock-out ()
  (interactive)
  (save-excursion
    (beginning-of-line 0)
    (org-remove-empty-drawer-at "CLOCK" (point))))

(add-hook 'org-clock-out-hook 'bh/remove-empty-drawer-on-clock-out 'append)

(defun bh/clock-in-to-next (kw)
  "Switch task from TODO to NEXT when clocking in.
Skips capture tasks and tasks with subtasks"
  (if (and (string-equal kw "TODO")
           (not (and (boundp 'org-capture-mode) org-capture-mode)))
      (let ((subtree-end (save-excursion (org-end-of-subtree t)))
            (has-subtask nil))
        (save-excursion
          (forward-line 1)
          (while (and (not has-subtask)
                      (< (point) subtree-end)
                      (re-search-forward "^\*+ " subtree-end t))
            (when (member (org-get-todo-state) org-not-done-keywords)
              (setq has-subtask t))))
        (when (not has-subtask)
          "NEXT"))))

;=== capture-mode with org-mode
;;from http://doc.norang.ca/org-mode.html#Capture
(define-key global-map "\C-cr" 'org-capture)

;http://sachachua.com/blog/2008/01/capturing-notes-with-remember/
(setq capture-data-file org-default-notes-file)

(defun capture-review-file ()
  "Open 'capture-data-file'."
  (interactive)
  (find-file-other-window capture-data-file))
(define-key global-map "\C-cR" 'capture-review-file)

;; capture templates for: TODO tasks, Notes
(setq org-capture-templates (quote (
                                    ("t" "todo" entry (file (concat org-directory "/refile.org")) "* TODO %?
  %U
  %a" :clock-in t :clock-resume t)
                                    ("n" "note" entry (file (concat org-directory "/refile.org")) "* %?                                                                            :NOTE:
  %U
  %a
  :CLOCK:
  :END:" :clock-in t :clock-resume t)
                                     )))

;; org-refile
;; from http://doc.norang.ca/org-mode.html
; Use IDO for target completion
(setq org-completion-use-ido t)

; Targets include this file and any file contributing to the agenda - up to 5 levels deep
(setq org-refile-targets (quote ((org-agenda-files :maxlevel . 5) (nil :maxlevel . 5))))

; Targets start with the file name - allows creating level 1 tasks
(setq org-refile-use-outline-path (quote file))

; Targets complete in steps so we start with filename, TAB shows the next level of targets etc
(setq org-outline-path-complete-in-steps t)

; Allow refile to create parent tasks with confirmation
(setq org-refile-allow-creating-parent-nodes (quote confirm))

; Use IDO only for buffers
; set ido-mode to buffer and ido-everywhere to t via the customize interface
; '(ido-mode (quote both) nil (ido))
; '(ido-everywhere t)

;=== w3m web browser
;; install in ubuntu 32-bit Lucid:
;; sudo apt-get install w3m-el-snapshot
(require 'w3m-load)
(setq w3m-use-cookies t)
;; http://www.emacswiki.org/emacs/WThreeMHintsAndTips#toc1
(setq browse-url-browser-function 'w3m-browse-url
          browse-url-new-window-flag t)
(autoload 'w3m-browse-url "w3m" "Ask a WWW browser to show a URL." t)

;; from Ben Livengood's init.el
;; hook to browse at point
;; for browsing
(define-key global-map "\C-cb" 'browse-url-at-point)

;; Google Suggest
;; http://www.emacswiki.org/emacs/WThreeMHintsAndTips#toc10
;; 'Intrigued by the Firefox google bar completion, I hacked the following function for use with emacs-w3m:'
(defun google-suggest ()
  "Search 'w3m-search-default-engine' with google completion candidates."
  (interactive)
  (w3m-search w3m-search-default-engine
              (completing-read  "Google search: "
                                (dynamic-completion-table
                                 'google-suggest-aux))))

(defun google-suggest-aux (input)
  (with-temp-buffer
    (insert
     (shell-command-to-string
      (format "w3m -dump_source %s"
              (shell-quote-argument
               (format
                "http://www.google.com/complete/search?hl=en&js=true&qu=%s"
                input)))))
    (read
     (replace-regexp-in-string "," ""
                               (progn
                                 (goto-char (point-min))
                                 (re-search-forward "\(" (point-max) t 2)
                                 (backward-char 1)
                                 (forward-sexp)
                                 (buffer-substring-no-properties
                                  (1- (match-end 0)) (point)))))))

(require 'mime-w3m)

;=== email sending and reading
; Setup email sending for gmail
; Invoke with M-x mail or C-x m

(require 'smtpmail)
(require 'starttls)

(setq send-mail-function 'smtpmail-send-it
      message-send-mail-function 'smtpmail-send-it
      smtpmail-starttls-credentials '(("smtp.gmail.com" 587 nil nil))
      smtpmail-auth-credentials (expand-file-name "~/Dropbox/.emacs.d/.authinfo")
      smtpmail-default-smtp-server "smtp.gmail.com"
      smtpmail-smtp-server "smtp.gmail.com"
      smtpmail-smtp-service 587
      user-mail-address "daniel.raymond.andrews@gmail.com"
      smtpmail-debug-info t)

(setq message-send-mail-function 'smtpmail-send-it
      smtpmail-starttls-credentials '(("smtp.gmail.com" 587 nil nil))
      smtpmail-auth-credentials '(("smtp.gmail.com" 587 "daniel.raymond.andrews@gmail.com" nil))
      smtpmail-auth-credentials (expand-file-name "~/Dropbox/.emacs.d/.authinfo")
      smtpmail-default-smtp-server "smtp.gmail.com"
      smtpmail-smtp-server "smtp.gmail.com"
      smtpmail-smtp-service 587
      smtpmail-local-domain "gmail.com")

;=== wanderlust
(autoload 'wl "wl" "Wanderlust" t)
(autoload 'wl-other-frame "wl" "Wanderlust on new frame." t)
(autoload 'wl-draft "wl-draft" "Write draft with Wanderlust." t)
(autoload 'wl-user-agent-compose "wl-draft" "Compose with Wanderlust." t)

;; copied freely from http://www.mail-archive.com/emacs-orgmode@gnu.org/msg20250/wlconfiguration.org
;; Tell Emacs my E-Mail address
;; Without this Emacs thinks my E-Mail is something like <myname>@ubuntu-asus
(setq user-mail-address "daniel.raymond.andrews@gmail.com")

;; Uncomment the line below if you have problems with accented letters
;; (setq-default mime-transfer-level 8) ;; default value is 7
  
;; Most of the configuration for wanderlust is in the .wl file. The line below
;; makes sure it will be opened with emacs-lisp-mode
(add-to-list 'auto-mode-alist '("\.wl$" . emacs-lisp-mode))

;; IMAP
(setq elmo-imap4-default-server "imap.gmail.com")
(setq elmo-imap4-default-user "daniel.raymond.andrews@gmail.com") 
(setq elmo-imap4-default-authenticate-type 'clear) 
(setq elmo-imap4-default-port '993)
(setq elmo-imap4-default-stream-type 'ssl)

(setq elmo-imap4-use-modified-utf7 t) 

(setq wl-insert-message-id nil) ; let the SMTP servers handle the message-id and stop warning from wanderlust

;; SMTP
(setq wl-smtp-connection-type 'starttls)
(setq wl-smtp-posting-port 587)
(setq wl-smtp-authenticate-type "plain")
(setq wl-smtp-posting-user "daniel.raymond.andrews@gmail.com")
(setq wl-smtp-posting-server "smtp.gmail.com")
(setq wl-local-domain "gmail.com")

;(setq wl-message-id-domain nil)
(setq wl-default-folder "%inbox")
(setq wl-default-spec "%")
(setq wl-draft-folder "%[Gmail]/Drafts") ; Gmail IMAP
(setq wl-trash-folder "%[Gmail]/Trash")

(setq wl-folder-check-async t) 

(setq elmo-imap4-use-modified-utf7 t)

;=== big-brother-database bbdb
;; (setq bbdb-file "~/Dropbox/.emacs.d/bbdb-2.35")           ;; keep ~/ clean; set before loading
;; (require 'bbdb) 
;; (bbdb-initialize)
;; (setq 
;;     bbdb-offer-save 1                        ;; 1 means save-without-asking
;;     bbdb-use-pop-up t                        ;; allow popups for addresses
;;     bbdb-electric-p t                        ;; be disposable with SPC
;;     bbdb-popup-target-lines  1               ;; very small
;;     bbdb-dwim-net-address-allow-redundancy t ;; always use full name
;;     bbdb-quiet-about-name-mismatches 2       ;; show name-mismatches 2 secs
;;     bbdb-always-add-address t                ;; add new addresses to existing...
;;                                              ;; ...contacts automatically
;;     bbdb-canonicalize-redundant-nets-p t     ;; x@foo.bar.cx => x@bar.cx
;;     bbdb-completion-type nil                 ;; complete on anything
;;     bbdb-complete-name-allow-cycling t       ;; cycle through matches
;;                                              ;; this only works partially
;;     bbbd-message-caching-enabled t           ;; be fast
;;     bbdb-use-alternate-names t               ;; use AKA
;;     bbdb-elided-display t                    ;; single-line addresses

;;     ;; auto-create addresses from mail
;;     bbdb/mail-auto-create-p 'bbdb-ignore-some-messages-hook   
;;     bbdb-ignore-some-messages-alist ;; don't ask about fake addresses
;;     ;; NOTE: there can be only one entry per header (such as To, From)
;;     ;; http://flex.ee.uec.ac.jp/texi/bbdb/bbdb_11.html

;;     '(( "From" . "no.?reply\\|DAEMON\\|daemon\\|facebookmail\\|twitter")))
;; )

;=== misc custom elisp functions
(defun insert-date-string ()
  "Insert a nicely formated date string."
  (interactive)
  (insert (format-time-string "%H:%M")))

;; C-c i calls insert-date-string
(global-set-key (kbd "C-c i") 'insert-date-string)

;;; Use "%" to jump to the matching parenthesis.
(defun goto-match-paren (arg)
  "Go to the matching parenthesis if on parenthesis, otherwise insert
the character typed."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
    ((looking-at "\\s\)") (forward-char 1) (backward-list 1))
    (t                    (self-insert-command (or arg 1))) ))
(global-set-key "%" `goto-match-paren)

;;; Toggle two windows so they are split vertically or horizontally
(defun my-toggle-window-split ()
  "Vertical split shows more of each line, horizontal split shows
more lines. This code toggles between them. It only works for
frames with exactly two windows."
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
             (next-win-buffer (window-buffer (next-window)))
             (this-win-edges (window-edges (selected-window)))
             (next-win-edges (window-edges (next-window)))
             (this-win-2nd (not (and (<= (car this-win-edges)
                                         (car next-win-edges))
                                     (<= (cadr this-win-edges)
                                         (cadr next-win-edges)))))
             (splitter
              (if (= (car this-win-edges)
                     (car (window-edges (next-window))))
                  'split-window-horizontally
                'split-window-vertically)))
        (delete-other-windows)
        (let ((first-win (selected-window)))
          (funcall splitter)
          (if this-win-2nd (other-window 1))
          (set-window-buffer (selected-window) this-win-buffer)
          (set-window-buffer (next-window) next-win-buffer)
          (select-window first-win)
          (if this-win-2nd (other-window 1))))))

(global-set-key [(control c) (|)] 'my-toggle-window-split) 

(defun back-window ()
  (interactive)
  (other-window -1)
)

(define-key global-map [?\C-\"] 'back-window) ;; can't find a way to bind w/ arguement

(defun switch-back-and-forth ()
  "switch to the 'other' buffer"
  (interactive)
  (switch-to-buffer (other-buffer))
)
(define-key global-map [f10] 'switch-back-and-forth) ;; defined above

(defun edit-emacs ()
  "Load the ~/Dropbox/.emacs.d/init.el file automatically."
  (interactive)
  (find-file "~/Dropbox/.emacs.d/init.el")
)

;;http://www.emacswiki.org/emacs/EmacsNiftyTricks
;; (defadvice save-buffers-kill-emacs (around no-query-kill-emacs activate)
;;   "Prevent annoying \"Active processes exist\" query when you quit Emacs."
;;   (flet ((process-list ())) ad-do-it))

(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(org-agenda-files (quote ("~/Dropbox/org/work.org" "~/Dropbox/org/2010_taxes.org" "~/Dropbox/org/4HWW_RNW.org" "~/Dropbox/org/business.org" "~/Dropbox/org/dropbox.org" "~/Dropbox/org/emacs.org" "~/Dropbox/org/home.org" "~/Dropbox/org/notes.org" "~/Dropbox/org/org.org" "~/Dropbox/org/reading.org" "~/Dropbox/org/refile.org" "~/Dropbox/org/w3m.org" "~/Dropbox/org/weekly_todo.org"))))
(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )

(message "*****  .emacs loaded  *****")