;;; blueprint-mode.el --- Major Mode for Blueprint Language files -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 Alexander Bisono
;;
;; This program is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
;; PARTICULAR PURPOSE. See the GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program. If not, see <https://www.gnu.org/licenses/>.
;;
;;
;; Author: Alexander Bisono <sbisonol@gmail.com>
;; Maintainer: Alexander Bisono <sbisonol@gmail.com>
;; Created: May 24, 2022
;; Modified: August 2, 2022
;; Version: 0.1.4
;; Homepage: https://github.com/drbluefall/blueprint-mode
;; Package-Requires: ((emacs "24.3"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; This file provides support and LSP integration for `.blp' files, used with the Blueprint Compiler.
;;
;;; Code:

(defgroup blueprint nil
  "GTK Blueprint Compiler."
  :link '(url-link "https://gitlab.gnome.org/jwestman/blueprint-compiler"))

(defcustom blueprint-tab-width 2
  "Blueprint tab width."
  :group 'blueprint
  :type 'number)

(defvar blueprint-mode-syntax-table nil)
(setq blueprint-mode-syntax-table
      (let ((st (make-syntax-table prog-mode-syntax-table)))

        ;; Support C-style comments.
        (modify-syntax-entry ?/  ". 124b" st)
        (modify-syntax-entry ?*  ". 23"   st)
        (modify-syntax-entry ?\n "> b"    st)
        (modify-syntax-entry ?\^m "> b"   st)

        ;; Treat underscores and dashes as part of symbols.
        (modify-syntax-entry ?- "_" st)
        (modify-syntax-entry ?- "_" st)

        st))

(defvar blueprint--font-lock-defaults nil)
(setq blueprint--font-lock-defaults
      (let* (
             ;; Define basic keywords
             (bp-keywords '("accessibility" "attributes" "bind"
                            "item" "layout" "menu" "section"
                            "submenu" "swapped" "using" "template"))

             (bp-constants '("start" "end" "false" "no" "yes" "true" "horizontal" "vertical"))

             ;; turn those into regexes
             (bp-keywords-regex (regexp-opt bp-keywords 'symbols))
             (bp-constants-regex (regexp-opt bp-constants 'symbols))
             ;; Define some custom ones
             (bp-starting-dot "^\\.")
             (bp-signal-arrow "=>")
             (bp-signal-function-regex "\\([[:alnum:]:_-]+\\)()")
             (bp-signal-name-regex "\\([[:alpha:]_-]+\\(::[[:alpha:]_-]+\\)?\\)[[:space:]]+=>")
             (bp-property-regex "[A-Za-z_-]+:\\|styles")
             (bp-property-regex-alt "\\[[=A-Za-z_-]+\\]")
             (bp-namespace-regex "\\(\\w+\\)\\.")
             (bp-class-regex "[[:upper:]]\\w+"))
        `((,bp-keywords-regex . font-lock-keyword-face)
          (,bp-signal-function-regex . '(1 font-lock-function-name-face))
          (,bp-signal-name-regex . '(1 font-lock-variable-name-face))
          (,bp-property-regex . font-lock-variable-name-face)
          (,bp-property-regex-alt . font-lock-variable-name-face)
          (,bp-starting-dot . font-lock-keyword-face)
          (,bp-signal-arrow . font-lock-keyword-face)
          (,bp-constants-regex . font-lock-constant-face)
          (,bp-class-regex . font-lock-type-face)
          (,bp-namespace-regex . '(1 font-lock-type-face)))))

(defun blueprint--line-starts-with-close-paren ()
  (save-excursion
    (beginning-of-line-text)
    (let ((char (char-after)))
      (or (char-equal char ?})
          (char-equal char ?\])))))

(defun blueprint--line-indentation ()
  "Returns how many indentation level the current line add or
remove"
  (let* ((start (line-beginning-position))
         (end (line-end-position))
         (open-parens (count-matches "{" start end))
         (open-parens (+ open-parens (count-matches "\\[" start end)))
         (close-parens (count-matches "}" start end))
         (close-parens (+ close-parens (count-matches "\\]" start end)))
         (close-parens (if (blueprint--line-starts-with-close-paren)
                           (1- close-parens)
                         close-parens)))
    (- open-parens close-parens)))

(defun blueprint--current-line-empty-p ()
  (save-excursion
    (beginning-of-line)
    (looking-at-p "[[:blank:]]*$")))

(defun blueprint--prev-line-indentation ()
  "Returns the indentation level of previous line"
  (save-excursion
    (if (= (line-number-at-pos) 1)
        0
      (previous-line)
      (if (blueprint--current-line-empty-p)
          (blueprint--prev-line-indentation)
        (+ (current-indentation) (* blueprint-tab-width (blueprint--line-indentation)))))))

(defun blueprint--indent-function ()
  "Indent function"
  (if (= (line-number-at-pos) 1)
      0
    (let ((level (if (blueprint--line-starts-with-close-paren)
                     (- blueprint-tab-width)
                   0)))
      (indent-line-to (+ level (blueprint--prev-line-indentation))))))

;;;###autoload
(define-derived-mode blueprint-mode prog-mode "Blueprint"
  "Major mode for Blueprint Compiler files."
  (setq-local font-lock-defaults '(blueprint--font-lock-defaults)
              comment-use-syntax t
              comment-start "// "
              mode-name "GTK+ Blueprint"
              indent-line-function #'blueprint--indent-function)
  (set-syntax-table blueprint-mode-syntax-table))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.blp\\'" . blueprint-mode))

(defun blueprint-enable-lsp-support ()
  "Setup `lsp-mode' integration."
  (declare (obsolete "This function has been supersceded by the `lsp-blueprint' module.
Currently, this function is a wrapper around a `require' call to
`lsp-blueprint', but it is recommended to `require' it directly." "0.1.4"))
  (require 'lsp-blueprint))

(provide 'blueprint-mode)
;;; blueprint-mode.el ends here
