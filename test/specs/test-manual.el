;;; test-manual.el --- Flycheck: Specs for documentation  -*- lexical-binding: t; -*-

;; Copyright (C) 2013-2016 Sebastian Wiesner and Flycheck contributors

;; Author: Sebastian Wiesner <swiesner@lunaryorn.com>

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'flycheck)
(require 'buttercup)
(require 'cl-lib)
(require 'seq)

(describe "Manual"
  (let* ((source-dir (locate-dominating-file default-directory "Cask"))
         (languages (expand-file-name "doc/languages.texi" source-dir)))

    (defun flycheck/collect-languages (pattern)
      "Collect all PATTERN matches from the list of languages."
      (let ((matches))
        (with-temp-buffer
          (insert-file-contents languages)
          (goto-char (point-min))
          (while (re-search-forward pattern nil 'noerror)
            (let ((match (intern (match-string 1))))
              (cl-pushnew match matches))))
        matches))


    (let ((checkers (flycheck/collect-languages
                     (rx "@flyc{" (group (1+ (not (any "}")))) "}"))))

      (it "should document all syntax checkers"
        (expect (seq-difference flycheck-checkers checkers)
                :to-equal nil))

      (it "should not document syntax checkers that don't exist"
        (expect (seq-difference checkers flycheck-checkers)
                :to-equal nil)))

    (let ((documented-options (flycheck/collect-languages
                               (rx line-start "@flycoption"
                                   (opt "x") (1+ space)
                                   (group (1+ not-newline)) line-end)))
          (all-options (seq-mapcat (lambda (c)
                                     (flycheck-checker-get c 'option-vars))
                                   flycheck-checkers)))

      (it "should document all options"
        (expect (seq-difference all-options documented-options)
                :to-equal nil))

      (it "should not document options that don't exist"
        (expect (seq-difference documented-options all-options)
                :to-equal nil))))

  (let ((documented-file-vars (flycheck/collect-languages
                               (rx line-start "@flycconfigfile{"
                                   (group (1+ (not (any "," "}")))) ",")))
        (all-file-vars (delq nil
                             (seq-map (lambda (c)
                                        (flycheck-checker-get
                                         c 'config-file-var))
                                      flycheck-checkers))))
    (it "should document all configuration file variables"
      (expect (seq-difference all-file-vars documented-file-vars)
              :to-equal nil))

    (it "should not document configuration file variables that don't exist"
        (expect (seq-difference documented-file-vars all-file-vars)
                :not :to-be-truthy))))

;;; test-manual.el ends here
