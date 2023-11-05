;;; ipl-mode.el --- Emacs mode for Imandra Protocol Language
;;
;; Copyright (c) 2023 Imandra, Inc.
;;
;; Author: Matt Bray <matt@imandra.ai>
;; Author: Nicola Mometto <nicola@imandra.ai>
;; URL: https://github.com/imandra-ai/ipl-mode
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(defconst ipl-builtins-extra
  '("None"
    "Some"
    "add"
    "abs"
    "delete"
    "get"
    "getDefault"
    "insert"
    "intOfString"
    "mapAdd"
    "remove"
    "strLen"
    "subset"
    "toFloat"
    "toInt"
    "truncate"))

(defconst ipl-builtins
  '("false"
    "true"
    "||"
    "&&"
    "!"
    "="
    ">"
    "<"
    ";"))

(defconst ipl-keywords
  '(
    "TimeStampPrecisions"
    "VerificationPacks"
    "action"
    "alias"
    "anonymous"
    "assignFrom"
    "assignable"
    "break"
    "case"
    "dataset"
    "datatype"
    "declare"
    "default"
    "description"
    "else"
    "enum"
    "events"
    "extend"
    "for"
    "forall"
    "function"
    "if"
    "ign"
    "ignore"
    "imandramarkets"
    "import"
    "in"
    "interLibraryCheck"
    "internal"
    "invalid"
    "invalidfield"
    "let"
    "library"
    "libraryMarker"
    "message"
    "messageFlows"
    "micro"
    "milli"
    "missingfield"
    "name"
    "opt"
    "optional"
    "outbound"
    "overloadFunction"
    "overrideFieldTypes"
    "precision"
    "present"
    "receive"
    "record"
    "reject"
    "repeating"
    "repeatingGroup"
    "req"
    "require"
    "return"
    "scenario"
    "send"
    "service"
    "template"
    "testfile"
    "then"
    "unique"
    "using"
    "valid"
    "validate"
    "when"
    "with"))

(defun ipl--block-indentation ()
  (let ((curline (line-number-at-pos)))
    (save-excursion
      (condition-case nil
          (progn
            (backward-up-list)
            (unless (= curline (line-number-at-pos))
              (current-indentation)))
        (scan-error nil)))))

(defun ipl--previous-indentation ()
  (save-excursion
    (forward-line -1)
    (let (finish)
      (while (not finish)
        (cond ((bobp) (setq finish t))
              (t
               (let ((line (buffer-substring-no-properties
                            (line-beginning-position) (line-end-position))))
                 (if (not (string-match-p "\\`\\s-*\\'" line))
                     (setq finish t)
                   (forward-line -1))))))
      (current-indentation))))

(defun ipl-indent-line ()
  (interactive)
  (let* ((curpoint (point))
         (pos (- (point-max) curpoint)))
    (back-to-indentation)
    (let ((block-indentation (ipl--block-indentation)))
      (delete-region (line-beginning-position) (point))
      (if block-indentation
          (if (looking-at "[]}]")
              (indent-to block-indentation)
            (indent-to (+ block-indentation standard-indent)))
        (indent-to (ipl--previous-indentation)))
      (when (> (- (point-max) pos) (point))
        (goto-char (- (point-max) pos))))))

(define-derived-mode ipl-mode
  text-mode "IPL"
  "Major mode for Imandra Protocol Language."
  (progn
    (setq comment-start "//")
    (setq comment-start-skip "//\\s *")
    (setq ipl-highlights
          `(("//.+" . font-lock-comment-face)
            ("/\\*.+\\*/" . font-lock-comment-face)
            ("@+[A-Za-z.]+:?" . font-lock-preprocessor-face)
            ("\\(@description:\\)\\(.+\\)" . ((1 font-lock-preprocessor-face)
                                              (2 font-lock-string-face)))
            ("function\\s-+\\([a-zA-Z0-9]+\\)" . ((1 font-lock-function-name-face)))
            ("\\(:\\)\\s-*\\([A-Za-z0-9.[:blank:]]+\\)"
             . ((1 font-lock-builtin-face)
                ;; (2 font-lock-type-face)
                ;; conflicts with case syntax :/
                ;; we need to use a function to do this properly,
                ;; as emacs doesn't support look-behind
                ))
            ("\\(:[*?]\\)\\s-*\\([A-Za-z0-9.[:blank:]]+\\)"
             . ((1 font-lock-builtin-face)
                (2 font-lock-type-face)
                ))
            ("\"[0-9]+\"\\s-*\\(:\\) *\\([A-Za-z0-9.[:blank:]]+\\)"
             . ((1 font-lock-builtin-face)
                (2 font-lock-type-face)
                ))
            ("\"[^\"]+\"" . font-lock-string-face)
            ("'[^']+'" . font-lock-string-face)
            ("[^A-Za-z0-9.]\\([A-Z][A-Za-z0-9.]+\\)\\." . ((1 font-lock-reference-face)))
            (,(regexp-opt ipl-keywords 'words) . font-lock-keyword-face)
            (,(regexp-opt ipl-builtins ) . font-lock-builtin-face)))
    (setq font-lock-defaults '(ipl-highlights))
    (set (make-local-variable 'standard-indent) 2)
    (set (make-local-variable 'indent-line-function) #'ipl-indent-line)))

(provide 'ipl-mode)
