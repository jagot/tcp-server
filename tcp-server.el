;;; echo-server.el --- -*- lexical-binding: t -*-
;;
;; Copyright (C) 2016-2017 York Zhao <gtdplatform@gmail.com>

;; Author: York Zhao <gtdplatform@gmail.com>
;; Created: June 1, 2016
;; Version: 0.1
;; Keywords: TCP, Server, Network, Socket
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 3 of the License, or (at your option) any later
;; version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program. If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Running "M-x tcp-server-start" will prompt user to enter a port number to
;; listen to.
;;
;;; Code:

(defvar tcp-server-clients '()
  "Alist where KEY is a client process and VALUE is the string")

(defvar tcp-server-servers '()
  "Alist where KEY is the port number the server is listening at")

(defun tcp-server-start (port)
  "Start a TCP server listening at PORT"
  (interactive
   (list (read-number "Enter the port number to listen to: " 9999)))
  (let* ((proc-name (format "tcp-server:%d" port))
         (buffer-name (format "*%s*" proc-name)))
    (unless (process-status proc-name)
      (make-network-process :name proc-name :buffer buffer-name
                            :family 'ipv4 :service port
                            :sentinel 'tcp-server-sentinel
                            :filter 'tcp-server-filter :server 't)
      ;; (push (cons port buffer-name) tcp-server-servers)
      (with-current-buffer buffer-name (text-mode))
      (setq tcp-server-clients '()))))

(defun tcp-server-stop (port)
  "Stop an emacs TCP server at PORT"
  (interactive
   (list (read-number "Enter the port number the server is listening to: "
                      9999)))
  (while  tcp-server-clients
    (delete-process (car (car tcp-server-clients)))
    (setq tcp-server-clients (cdr tcp-server-clients)))
  (delete-process (format "tcp-server:%d" port)))

(defun tcp-server-filter (proc string)
  (let ((buffer (process-contact proc :buffer))
        (inhibit-read-only t))
    (and buffer
         (get-buffer buffer)
         (with-current-buffer buffer
           (save-excursion
             (goto-char (point-max))
             (insert string))))))

(defun tcp-server-sentinel (proc msg)
  (cond
   ((string-match "open from .*\n" msg)
    (setq tcp-server-clients (push (cons proc "") tcp-server-clients))
    (tcp-server-log proc "client connected\n"))
   ((string= msg "connection broken by remote peer\n")
    (setq tcp-server-clients (assq-delete-all proc tcp-server-clients))
    (tcp-server-log proc "client has quit\n"))))

(defun tcp-server-log (client string)
  "If a server buffer exists, write STRING to it for logging purposes."
  (let ((server-buffer (process-contact client :buffer)))
    (when server-buffer
      (with-current-buffer server-buffer
        (goto-char (point-max))
        (insert (current-time-string) (format " %s: " client) string)))))


(provide 'tcp-server)

;;; tcp-server.el ends here
