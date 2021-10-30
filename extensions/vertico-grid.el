;;; vertico-grid.el --- Grid display for Vertico -*- lexical-binding: t -*-

;; Copyright (C) 2021  Free Software Foundation, Inc.

;; Author: Daniel Mendler <mail@daniel-mendler.de>
;; Maintainer: Daniel Mendler <mail@daniel-mendler.de>
;; Created: 2021
;; Version: 0.1
;; Package-Requires: ((emacs "27.1") (vertico "0.14"))
;; Homepage: https://github.com/minad/vertico

;; This file is part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package is a Vertico extension providing a grid display.

;;; Code:

(require 'vertico)

(defcustom vertico-grid-columns 4
  "Number of grid columns."
  :type 'integer
  :group 'vertico)

(defcustom vertico-grid-padding 2
  "Padding between columns."
  :type 'integer
  :group 'vertico)

(defcustom vertico-grid-rows 6
  "Number of grid rows."
  :type 'integer
  :group 'vertico)

(defun vertico-grid--arrange-candidates ()
  "Arrange candidates."
  (let* ((count (* vertico-grid-rows vertico-grid-columns))
         (start (* count (floor (max 0 vertico--index) count)))
         (width (- (/ (window-width) vertico-grid-columns) vertico-grid-padding))
         (pad (make-string vertico-grid-padding ?\s))
         (candidates
          (seq-map-indexed (lambda (cand index)
                             (setq index (+ index start))
                             (when (string-match-p "\n" cand)
                               (setq cand (vertico--truncate-multiline cand width)))
                             (truncate-string-to-width
                              (string-trim
                               (replace-regexp-in-string
                                "[ \t]+" (if (= index vertico--index)
                                             #(" " 0 1 (face vertico-current)) " ")
                                (vertico--format-candidate cand "" "" index start)))
                              width 0 ?\s))
          (funcall vertico--highlight-function
                   (seq-subseq vertico--candidates start
                               (min (+ start count)
                                    vertico--total)))))
         (lines))
    (dotimes (row vertico-grid-rows)
      (let ((line))
        (dotimes (col vertico-grid-columns)
          (setq line (concat line
                             (nth (+ row (* col vertico-grid-rows)) candidates)
                             pad)))
        (push (concat line "\n") lines)))
    (nreverse lines)))

(defun vertico-grid-left (&optional n)
  "Move N columns to the left in the grid."
  (interactive "p")
  (vertico-grid-right (- (or n 1))))

(defun vertico-grid-right (&optional n)
  "Move N columns to the right in the grid."
  (interactive "p")
  (let* ((page (* vertico-grid-rows vertico-grid-columns))
         (p (/ vertico--index page))
         (q (mod vertico--index page))
         (x (/ q vertico-grid-rows))
         (y (mod q vertico-grid-rows))
         (z (+ (* p page) (* vertico-grid-columns y) x (or n 1))))
    (setq x (mod z vertico-grid-columns)
          y (/ z vertico-grid-columns))
    (vertico--goto (+ (* x vertico-grid-rows) (mod y vertico-grid-rows)
                      (* (/ y vertico-grid-rows) page)))))

;;;###autoload
(define-minor-mode vertico-grid-mode
  "Grid display for Vertico."
  :global t :group 'vertico
  (cond
   (vertico-grid-mode
    (define-key vertico-map [remap left-char] #'vertico-grid-left)
    (define-key vertico-map [remap right-char] #'vertico-grid-right)
    (advice-add #'vertico--arrange-candidates :override #'vertico-grid--arrange-candidates))
   (t
    (assq-delete-all 'left-char (assq 'remap vertico-map))
    (assq-delete-all 'right-char (assq 'remap vertico-map))
    (advice-remove #'vertico--arrange-candidates #'vertico-grid--arrange-candidates))))

(provide 'vertico-grid)
;;; vertico-grid.el ends here