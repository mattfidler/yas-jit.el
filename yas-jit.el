;;; yas-jit.el --- Loads Yasnippets on demand (makes start up faster)
;;
;; Filename: yas-jit.el
;; Description: Loads Yasnippets on demand (makes startup faster)
;; Author: Matthew L. Fidler
;; Maintainer: Matthew L. Fidler
;; Created: Wed Oct 27 08:14:43 2010 (-0500)
;; Version: 0.8.6
;; Last-Updated: Mon Jun 25 14:09:04 2012 (-0500)
;;           By: Matthew L. Fidler
;;     Update #: 202
;; URL: http://www.emacswiki.org/emacs/download/yas-jit.el
;; Keywords: Yasnippet fast loading.
;; Compatibility: Emacs 23.2 with Yasnippet 0.6 or 0.7
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; Usage:
;;   Instead of using
;;
;;   (require 'yasnippet)
;;   (setq yas/root-directory snippet-directory)
;;   (yas/load-directory yas/root-directory)
;;
;;   which takes some time on initial loading, use
;;
;;   (require 'yas-jit)
;;   (setq yas/root-directory snippet-directory)
;;   (yas/jit-load)
;;
;;   For yasnippet 0.6 the root directory is something like:
;;   (setq yas/root-directory "~/.emacs.d/snippets/text-mode/")
;;
;;   For yasnippet 0.7 the root directory is something like:
;;
;;   (setq yas/root-directory "~/.emacs.d/snippets/");;
;;
;;   This is because the root directory assumes that each load-path
;;   contains directories of modes with snippets.
;;
;;   Also note that yasnippet requires something in the hash,
;;   otherwise it loads everything.  Therefore text-mode snippets are
;;   loaded by default.
;;
;;   This will probably not be put in the trunk of yasnippet.
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;; 25-Jun-2012    Matthew L. Fidler  
;;    Last-Updated: Mon Jun 25 14:07:22 2012 (-0500) #201 (Matthew L. Fidler)
;;    Updated to work with the latest trunk
;; 12-Dec-2011      
;;    Last-Updated: Mon Dec 12 09:22:00 2011 (-0600) #176 (us041375)
;;    Deleted cache on menu-based ``reload-all''
;; 12-Dec-2011    Matthew L. Fidler  
;;    Last-Updated: Mon Dec 12 08:52:51 2011 (-0600) #160 (Matthew L. Fidler)
;;    Added yas/jit-compile-bundle to allow file-names to be saved.
;; 28-Nov-2011    Matthew L. Fidler  
;;    Last-Updated: Mon Nov 28 09:21:45 2011 (-0600) #155 (Matthew L. Fidler)
;;    Changed (save-excursion (set-buffer x)) to (with-currend-buffer x)
;; 28-Nov-2011    Matthew L. Fidler  
;;    Last-Updated: Mon Nov 28 08:55:36 2011 (-0600) #153 (Matthew L. Fidler)
;;    Possibly fixed the cache deletion problem.
;; 22-Nov-2011    Matthew L. Fidler  
;;    Last-Updated: Tue Nov 22 10:00:26 2011 (-0600) #146 (Matthew L. Fidler)
;;    Put a comment to show the cache that yas/jit is trying to delete
;; 29-Sep-2011    Matthew L. Fidler  
;;    Last-Updated: Thu Sep 29 16:09:31 2011 (-0500) #137 (Matthew L. Fidler)
;;    Updated documentation section of file
;; 29-Sep-2011    Matthew L. Fidler  
;;    Last-Updated: Thu Sep 29 08:31:22 2011 (-0500) #133 (Matthew L. Fidler)
;;    Fixed bug checking for yasnippet loading.  Thanks Sandro Munda
;; 12-May-2011    Matthew L. Fidler  
;;    Last-Updated: Thu May 12 09:42:24 2011 (-0500) #119 (Matthew L. Fidler)
;;    Made alias for yas/snippet-dirs for backward-compatibility with yasnippet 0.6
;; 12-May-2011    Matthew L. Fidler  
;;    Last-Updated: Thu May 12 09:33:46 2011 (-0500) #115 (Matthew L. Fidler)

;;    Checked for yas/extra-modes.  If not present don't load the
;;    extra modes with this function.

;; 12-May-2011    Matthew L. Fidler  
;;    Last-Updated: Mon Nov  1 11:33:51 2010 (-0500) #113 (Matthew L. Fidler)
;;    Allowed loading of yasnippet bundle.
;; 01-Apr-2011    Matthew L. Fidler
;;    Last-Updated: Mon Nov  1 11:33:51 2010 (-0500) #113 (Matthew L. Fidler)
;;    Allow caching of mode snippets into a single file.
;; 22-Feb-2011    Matthew L. Fidler
;;    Last-Updated: Mon Nov  1 11:33:51 2010 (-0500) #113 (Matthew L. Fidler)
;;
;;    Add Caching of directories to allow an even faster loadup when
;;    no snippets have changed. (Don't have to traverse the
;;    directories)
;;
;; 27-Oct-2010    Matthew L. Fidler
;;    Last-Updated: Wed Oct 27 22:31:46 2010 (-0500) #107 (Matthew L. Fidler)

;;    Changed JIT reload-all to load the modes of all open buffers
;;    instead of just the currently open mode

;; 27-Oct-2010    Matthew L. Fidler
;;    Last-Updated: Wed Oct 27 11:45:14 2010 (-0500) #95 (Matthew L. Fidler)
;;    Added hook.  Should (in theory) work well.
;; 27-Oct-2010    Matthew L. Fidler
;;    Last-Updated: Wed Oct 27 10:43:47 2010 (-0500) #74 (Matthew L. Fidler)
;;    Changed yas/minor-mode-on definition
;; 27-Oct-2010    Matthew L. Fidler
;;    Last-Updated: Wed Oct 27 10:25:30 2010 (-0500) #65 (Matthew L. Fidler)

;;    Tried setting root directory to text-mode so that yas will not
;;    load anything until the hook is called

;; 27-Oct-2010    Matthew L. Fidler
;;    Initial Release
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'cl)
(require 'yasnippet nil t)
(require 'yasnippet-bundle nil t)
(when (and (not (featurep 'yasnippet)) (not (featurep 'yasnippet-bundle)))
  (error "Cannot load yasnippet."))

(if (and (not (fboundp 'yas/snippet-dirs))
	 (fboundp 'yas/guess-snippet-directories))
    (defun yas/snippet-dirs ()
      (if (listp yas/root-directory) yas/root-directory (list yas/root-directory))))

(defvar yas/jit-loads '()
  "Alist of JIT loads for yas.")
(defvar yas/get-jit-loads-again 't)

(defcustom yas/jit-use-cache-dir nil
  "Cache the directories used for Yasnippet."
  :type 'boolean
  :group 'yasnippet)

(defcustom yas/jit-cache-snippets t
  "Combine snippets of a directory into a single file for each mode."
  :type 'boolean
  :group 'yasnippet)

(defcustom yas/jit-delete-cache-on-interactive-reload-all t
  "Removes the snippet cache on a menu-based reload all."
  :type 'boolean
  :group 'yasnippet)

(defun yas/jit-cache ()
  "Cache JIT loading to make it load even faster"
  (with-temp-file "~/.yas-jit-cache.el"
    (insert ";;Yasnippet JIT cache\n(setq yas/get-jit-loads-again nil)\n")
    (insert (format  "(setq yas/jit-loads '(%s))"
		     (mapconcat
		      (lambda(a)
			(format "(%s \"%s\")" (symbol-name (nth 0 a))
				(abbreviate-file-name (nth 1 a))))
		      yas/jit-loads
		      "\n")))))

(defun yas/jit-delete-cache ()
  "Delete cache"
  (interactive)
  (when (file-readable-p "~/.yas-jit-cache.el")
    (delete-file "~/.yas-jit-cache.el"))
  (let ((f (yas/jit-dir-snippet-cache (file-name-directory (buffer-file-name)))))
    (message "Looking to delete cache: %s" f)
    (when (file-readable-p f)
      (delete-file f))))

;;;###autoload
(defun yas/get-jit-loads ()
  "* Loads Snippet directories just in time.  Should speed up the start-up of Yasnippet"
  (if (and yas/jit-use-cache-dir (file-readable-p "~/.yas-jit-cache.el"))
      (progn
	(load-file "~/.yas-jit-cache.el")
        (let ((major-mode 'text-mode))
          (yas/jit-hook))
	(setq yas/get-jit-loads-again nil))
    (when yas/get-jit-loads-again
      (let* ((dirs (yas/snippet-dirs))
             files
             modes
             (files '())
             (debug-on-error 't)
             jit)
        (when dirs
          (mapc (lambda(x)
                  (setq files (append files (directory-files x 't))))
                (yas/snippet-dirs))
          (setq modes
                (remove-if-not
                 #'(lambda(file)
                     (and (file-directory-p file)
                          (not (string-match "^[.]" (file-name-nondirectory file)))))
                 (directory-files (pop dirs) 't)))
          (setq jit (mapcar (lambda(x) (list (intern (file-name-nondirectory x)) x) ) modes))
          ;; Now add more directories.
          (when (> (length dirs) 0)
            (mapc
             (lambda(dir)
               (let ( (modes (remove-if-not
                              #'(lambda(file)
                                  (and (file-directory-p file)
                                       (not (string-match "^[.]" (file-name-nondirectory file)))))
                              (directory-files dir 't))))
                 (mapc (lambda(mode)
                         (if (not (assoc (intern (file-name-nondirectory mode)) jit))
                             (add-to-list 'jit (list (intern (file-name-nondirectory mode)) mode))
                           (setq jit (mapcar
                                      (lambda(m)
                                        (if (eq (intern (file-name-nondirectory mode)) (car m))
                                            (append m (list mode))
                                          m))
                                      jit))))
                       modes)))
             dirs))
          (setq yas/jit-loads jit)
          (when yas/jit-use-cache-dir
            (yas/jit-cache))
          (let ((major-mode 'text-mode))
            (yas/jit-hook)))
        (setq yas/get-jit-loads-again nil)))))

(defun yas/jit-hook ()
  "Have Yas load directories as needed. Derived from `yas/direct-keymaps-set-vars'"
  (interactive)
  (let ((modes-to-activate (list major-mode))
        (mode major-mode)
        (debug-on-error 't)
        (debug-on-quit 't))
    (while (setq mode (get mode 'derived-mode-parent))
      (push mode modes-to-activate))
    (when (fboundp 'yas/extra-modes)
      (dolist (mode (yas/extra-modes))
	(push mode modes-to-activate)))
    (dolist (mode modes-to-activate)
      (let ((test-mode mode)
            (other-modes '())
            cur-mode
            tmp)
        (setq tmp (assoc test-mode yas/jit-loads))
        (while tmp
          (setq yas/get-jit-loads-again 't) ;; Get loads since some of the JIT loads have left.
          (setq cur-mode (pop tmp))
          (setq yas/jit-loads
                (remove-if
                 #'(lambda(x)
                     (eq cur-mode (car x)))
                 yas/jit-loads))
          (mapc (lambda(dir)
                  (cond
		   (yas/jit-cache-snippets
                    (let ((snippet-cache (yas/jit-dir-snippet-cache dir)))
		      (if (not (file-exists-p snippet-cache))
			  (progn
			    (message "Caching snippets in %s" dir)
			    (yas/jit-compile-dir dir snippet-cache)))
                      (message "Loading snippets in cached file, %s " snippet-cache)
                      (if (fboundp 'yas/compile-snippets)
                          (yas/load-directory-1 dir cur-mode
                                                (if (not (file-readable-p (concat dir "/.yas-parents")))
                                                    nil
                                                  (mapcar #'intern
                                                          (split-string
                                                           (with-temp-buffer
                                                             (insert-file-contents (concat dir "/.yas-parents"))
                                                             (buffer-substring-no-properties (point-min)
                                                                                             (point-max)))))))
                        (load-file snippet-cache))))
                   (t
		    (message "Loading snippet directory %s" dir)
		    (yas/load-directory-1 dir cur-mode
					  (if (not (file-readable-p (concat dir "/.yas-parents")))
					      nil
					    (mapcar #'intern
						    (split-string
						     (with-temp-buffer
						       (insert-file-contents (concat dir "/.yas-parents"))
						       (buffer-substring-no-properties (point-min)
										       (point-max)))))))))
                  (when (file-exists-p (concat dir "/.yas-parents"))
                    (with-temp-buffer
                      (insert-file-contents (concat dir "/.yas-parents"))
                      (mapc (lambda(x)
                              (add-to-list 'other-modes x))
                            (split-string (buffer-substring (point-min) (point-max)) nil 't)))))
                tmp)
          (setq other-modes (remove-if-not #'(lambda(x) (assoc (intern x) yas/jit-loads)) other-modes))
          (setq tmp nil)
          (when (> (length other-modes) 0)
            (setq test-mode (intern (pop other-modes)))
            (setq tmp (assoc test-mode yas/jit-loads))))))))

;;;###autoload
(defalias 'yas/jit-load 'yas/get-jit-loads)

(defun yas/jit-hook-run ()
  "* Run yas/jit-hook and setup hooks again..."
  (add-hook 'after-change-major-mode-hook 'yas/jit-hook-run)
  (add-hook 'find-file-hook 'yas/jit-hook-run)
  (add-hook 'change-major-mode-hook 'yas/jit-hook-run)
  (yas/jit-hook))

(add-hook 'after-change-major-mode-hook 'yas/jit-hook-run)
(add-hook 'find-file-hook 'yas/jit-hook-run)
(add-hook 'change-major-mode-hook 'yas/jit-hook-run)
(add-hook 'write-contents-hook 'yas/jit-delete-cache)

(add-hook 'snippet-mode-hook
          (lambda()
            (add-hook 'after-save-hook 'yas/jit-delete-cache nil t)
            (add-hook 'write-contents-hook 'yas/jit-delete-cache nil t)))

(defadvice yas/reload-all (around yas-jit-advice)
  "Makes Reload-all actually delete any caches."
  (when (and yas/jit-delete-cache-on-interactive-reload-all
             (interactive-p))
    (when (file-readable-p "~/.yas-jit-cache.el")
      (delete-file "~/.yas-jit.cache.el"))
    (setq yas/get-jit-loads-again t)
    (yas/get-jit-loads)
    (mapc (lambda(dirs)
            (let ((cache (yas/jit-dir-snippet-cache
                          (nth 1 dirs))))
              (when (file-readable-p cache)
                (delete-file cache))))
          yas/jit-loads))
  ad-do-it)

(ad-activate 'yas/reload-all)

(defun yas/load-snippet-dirs ()
  "Reload the directories listed in `yas/snippet-dirs' or
   prompt the user to select one."
  (if yas/snippet-dirs
      (progn
        (yas/get-jit-loads)
        (let ( (modes '())
               (bufs (buffer-list)))
          ;; Load snippets for major modes of all open buffers
          (mapc (lambda(x)
                  (with-current-buffer x
                    (yas/jit-hook) ;; Load current mode's snippets.
                    ))
                bufs)))
    (call-interactively 'yas/load-directory)))

(defun yas/jit-dir-snippet-cache (dir)
  "Returns the load-file based on the directory listed."
  (if (fboundp 'yas/compile-snippets)
      (progn
        (concat dir "/.yas-compiled-snippets.el"))
    (let ((d dir) mode d..)
      (when (string-match "[/\\]$" d)
        (setq d (substring d 0 -1)))
      (when (string-match "[/\\]\\([^/\\]*\\)$" d)
        (setq mode (match-string 1 d))
        (setq d.. (replace-match "" t t d)))
      (concat d.. "/.yas-" mode "-snippets.el"))))


;;; Lifted from yas/compile-bundle.  Needs to keep the file-name
;;; though.

(defun yas/jit-compile-bundle
  (&optional yasnippet yasnippet-bundle snippet-roots code dropdown use-file)
  "Compile snippets in SNIPPET-ROOTS to a single bundle file.

YASNIPPET is the yasnippet.el file path.

YASNIPPET-BUNDLE is the output file of the compile result.

SNIPPET-ROOTS is a list of root directories that contains the
snippets definition.

CODE is the code to be placed at the end of the generated file
and that can initialize the YASnippet bundle.

Last optional argument DROPDOWN is the filename of the
dropdown-list.el library.

Here's the default value for all the parameters:

(yas/jit-compile-bundle \"yasnippet.el\"
                        \"yasnippet-bundle.el\"
                        \"snippets\")
\"(yas/initialize-bundle)
### autoload
(require 'yasnippet-bundle)`\"
\"dropdown-list.el\")
"
(interactive (concat "ffind the yasnippet.el file: \nFTarget bundle file: "
                     "\nDSnippet directory to bundle: \nMExtra code? \nfdropdown-library: "))

(let* ((yasnippet (or yasnippet
                      "yasnippet.el"))
       (yasnippet-bundle (or yasnippet-bundle
                             "./yasnippet-bundle.el"))
       (snippet-roots (or snippet-roots
                          "snippets"))
       (dropdown (or dropdown
                     "dropdown-list.el"))
       (code (or (and code
                      (condition-case err (read code) (error nil))
                      code)
                 (concat "(yas/initialize-bundle)"
                         "\n;;;###autoload" ; break through so that won't
                         "(require 'yasnippet-bundle)")))
       (dirs (or (and (listp snippet-roots) snippet-roots)
                 (list snippet-roots)))
       (bundle-buffer nil))
  (with-temp-file yasnippet-bundle
    (insert ";;; yasnippet-bundle.el --- "
            "Yet another snippet extension (Auto compiled bundle)\n")
    (insert-file-contents yasnippet)
    (goto-char (point-max))
    (insert "\n")
    (when dropdown
      (insert-file-contents dropdown))
    (goto-char (point-max))
    (insert ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n")
    (insert ";;;;      Auto-generated code         ;;;;\n")
    (insert ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n")
    (insert "(defun yas/initialize-bundle ()\n"
            "  \"Initialize YASnippet and load snippets in the bundle.\"")
    (flet ((yas/define-snippets
            (mode snippets &optional parent-or-parents)
            (insert ";;; snippets for " (symbol-name mode) ", subdir " (file-name-nondirectory (replace-regexp-in-string "/$" "" default-directory)) "\n")
            (let ((literal-snippets (list)))
              (dolist (snippet snippets)
                (let ((key                    (first   snippet))
                      (template-content       (second  snippet))
                      (name                   (third   snippet))
                      (condition              (fourth  snippet))
                      (group                  (fifth   snippet))
                      (expand-env             (sixth   snippet))
                      (file                   (if use-file
                                                  (replace-regexp-in-string
                                                   "root/" ""
                                                   (abbreviate-file-name
                                                    (seventh snippet)))
                                                nil)) ;; (seventh snippet)) ;; omit on purpose
                      (binding                (eighth  snippet))
                      (uuid                    (ninth   snippet)))
                  (push `(,key
                          ,template-content
                          ,name
                          ,condition
                          ,group
                          ,expand-env
                          ,file
                          ,binding
                          ,uuid)
                        literal-snippets)))
              (insert (pp-to-string `(yas/define-snippets ',mode ',literal-snippets ',parent-or-parents)))
              (insert "\n\n"))))
      (dolist (dir dirs)
        (dolist (subdir (yas/subdirs dir))
          (let ((file (concat subdir "/.yas-setup.el")))
            (when (file-readable-p file)
              (insert "\n;; Supporting elisp for subdir " (file-name-nondirectory subdir) "\n\n")
              (with-temp-buffer
                (insert-file-contents file)
                (replace-regexp "^;;.*$" "" nil (point-min) (point-max))
                (replace-regexp "^[\s\t]*\n\\([\s\t]*\n\\)+" "\n" nil (point-min) (point-max))
                (kill-region (point-min) (point-max)))
              (yank)))
          (yas/load-directory-1 subdir nil nil))))
    
    (insert (pp-to-string `(yas/global-mode 1)))
    (insert ")\n\n" code "\n")
    
    ;; bundle-specific provide and value for yas/dont-activate
    (let ((bundle-feature-name (file-name-nondirectory
                                (file-name-sans-extension
                                 yasnippet-bundle))))
      (insert (pp-to-string `(set-default 'yas/dont-activate
                                          #'(lambda ()
                                              (and (or yas/snippet-dirs
                                                       (featurep ',(make-symbol bundle-feature-name)))
                                                   (null (yas/get-snippet-tables)))))))
      (insert (pp-to-string `(provide ',(make-symbol bundle-feature-name)))))
    
    (insert ";;; "
            (file-name-nondirectory yasnippet-bundle)
            " ends here\n"))))

;;;###autoload
(defun yas/jit-compile-dir (dir &optional out)
  "Compiles directory into a \"bundle\".  Useful for caching purposes."
  (interactive "fDirectory to compile/cache:")
  (if (fboundp 'yas/compile-snippets)
      (progn
        (yas/compile-snippets dir out)
        (while (not (file-exists-p out))
          (sleep 1))
        ;;;
        (with-temp-buffer
          (insert-file-contents out)
          (goto-char (point-min))
          (when (search-forward "(yas/define-snippets 'nil" nil t)
            (replace-match (concat "(yas/define-snippets '"
                                   (file-name-nondirectory (substring (file-name-directory out) 0 -1))))
            (write-file out))))
    (let ((empty-file (make-temp-file "yasnippet" nil ".el"))
          mode
          (d dir)
          (d.. ))
      (when (string-match "[/\\]$" d)
        (setq d (substring d 0 -1)))
      (when (string-match "[/\\]\\([^/\\]*\\)$" d)
        (setq mode (match-string 1 d))
        (setq d.. (replace-match "" t t d)))
      (if (not (file-exists-p (concat d.. "/root")))
          (make-directory (concat d.. "/root")))
      (rename-file d (concat d.. "/root/" mode))
      
      (yas/jit-compile-bundle (if (file-readable-p (concat d.. "/root/" mode "/.yas-setup.el"))
                                  (concat d.. "/root/" mode "/.yas-setup.el")
                                empty-file)
                              (concat d.. "/.yas-" mode "-snippets.el")
                              `(,(concat d.. "/root/")) (concat ) empty-file
                              t
                              )
      (rename-file (concat d.. "/root/" mode ) d)
      (delete-directory (concat d.. "/root"))
      (delete-file empty-file)
      (save-excursion
        (let ((coding-system-for-write 'no-conversion))
          (set-buffer (find-file-noselect (concat d.. "/.yas-" mode "-snippets.el")))
          (goto-char (point-min))
          (when (search-forward "(yas/define-snippets" nil t)
            (goto-char (match-beginning 0))
            (delete-region (point-min) (point))
            (forward-sexp)
            (delete-region (point) (point-max)))
          (goto-char (point-min))
          (when (file-readable-p (concat d ".yas-setup.el"))
            (insert ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; .yas-setup.el
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n")
            (insert-file-contents (concat d ".yas-setup.el"))
            (insert "\n;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; end .yas-setup.el
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n"))
          (save-buffer (current-buffer))
          (kill-buffer (current-buffer)))))))

(provide 'yas-jit)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; yas-jit.el ends here
