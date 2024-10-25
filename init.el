;;; package --- init.el
;;; Code:

;; ---------------------------
;; 基础配置
;; ---------------------------
;; 重载init.el
(defun reload-init-file ()
  "Reload Emacs configuration file."
  (interactive)
  (load-file user-init-file))

(global-set-key (kbd "C-c r") 'reload-init-file)


;; 禁用欢迎页面，显示 *scratch* 缓冲区
(setq inhibit-startup-screen t)
(setq initial-scratch-message nil)

;; 启动时将 *scratch* buffer 设为 text-mode
(setq initial-major-mode 'text-mode)

;; 关闭自动备份文件
(setq make-backup-files nil)

;; 启用行号显示，编程模式下使用相对行号
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode t)
(defun my/disable-line-numbers-in-some-modes ()
  "Disable line numbers in specific modes."
  (when (derived-mode-p 'treemacs-mode)
    (display-line-numbers-mode 0)))
(add-hook 'after-change-major-mode-hook 'my/disable-line-numbers-in-some-modes)

;; 设置包管理源
(require 'package)
(setq package-archives '(("gnu"    . "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
                         ("melpa"  . "https://melpa.org/packages/")))
(package-initialize)

;; 自动安装 use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(setq use-package-always-ensure t)

;; ---------------------------
;; 界面美化
;; ---------------------------

;; 隐藏菜单栏
(menu-bar-mode -1)

(use-package doom-themes
  :config (load-theme 'doom-one t))

(add-to-list 'custom-theme-load-path "~/.emacs.d/themes")
(load-theme 'dracula t)

(defun centered-window-mode-enable ()
  "Enable centered window mode when only one window is visible and there is no split."
  (when (and (= (count-windows) 1)
             (not (window-in-direction 'right)))
    ;; Enable centering and width restriction
    (setq-default left-margin-width (/ (- (window-total-width) 120) 2))
    (setq-default right-margin-width (/ (- (window-total-width) 120) 2))
    (set-window-buffer nil (current-buffer))
    (message "Centered window mode enabled")))

(defun centered-window-mode-disable ()
  "Disable centered window mode and reset margins."
  ;; Disable centering and reset margins
  (setq-default left-margin-width 0)
  (setq-default right-margin-width 0)
  (set-window-buffer nil (current-buffer))
  (message "Centered window mode disabled"))

(defun toggle-centered-window ()
  "Toggle centered window mode.
Enable if currently disabled and only one window without splits;
disable otherwise."
  (interactive)
  (if (bound-and-true-p centered-window-mode)
      (progn
        (centered-window-mode-disable)
        (setq centered-window-mode nil))
    (if (= (count-windows) 1)
        (progn
          (centered-window-mode-enable)
          (setq centered-window-mode t))
      (message "Centered window mode cannot be enabled with splits."))))

(defun handle-window-configuration-change ()
  "Disable centered window mode automatically when splits are present."
  (if (> (count-windows) 1)
        (progn
        (centered-window-mode-disable)
        (setq centered-window-mode nil))))

;; Automatically handle window splitting or closing events
(add-hook 'window-configuration-change-hook 'handle-window-configuration-change)

(defun split-window-advice (orig-fun &rest args)
  "Advice to disable centered window mode before splitting the window."
  (when (bound-and-true-p centered-window-mode)
    (centered-window-mode-disable)
    (setq centered-window-mode nil))
  (apply orig-fun args))

;; Add advice to split-window (C-x 2 & 3)
(advice-add 'split-window-below :around #'split-window-advice)
(advice-add 'split-window-right :around #'split-window-advice)

;; Bind to F10 key for toggling
(global-set-key (kbd "<f10>") 'toggle-centered-window)

;; Enable the mode by default if there is no horizontal split
(when (display-graphic-p)
  (centered-window-mode-enable)
  (setq centered-window-mode t))

;; ---------------------------
;; 编辑体验优化
;; ---------------------------
;; F11: 跳转到上一个窗口
(global-set-key (kbd "<f11>") (lambda () (interactive) (other-window -1)))
;; F12: 跳转到下一个窗口
(global-set-key (kbd "<f12>") (lambda () (interactive) (other-window 1)))

(use-package ivy
  :ensure t
  :config
  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t
        enable-recursive-minibuffers t
	ivy-auto-select-single-candidate t))

(use-package counsel
  :after ivy
  :config (counsel-mode 1))

(use-package company
  :init (global-company-mode))

(use-package smartparens
  :config (smartparens-global-mode t))

;; ---------------------------
;; 文件管理和项目管理
;; ---------------------------
(use-package projectile
  :config
  (projectile-mode +1)
  (setq projectile-completion-system 'ivy)
  :bind-keymap ("C-c p" . projectile-command-map))

(use-package treemacs
  :bind (("M-0" . treemacs-select-window)
         ("C-x t 1" . treemacs-delete-other-windows)))

(use-package treemacs-projectile
  :after (treemacs projectile))

;; ---------------------------
;; 编程相关
;; ---------------------------
;; 全局启用语法检查，只在编程模式下使用 flycheck
(use-package flycheck
  :hook (prog-mode . flycheck-mode))

;; Rust 开发相关配置
(use-package rust-mode
  :mode "\\.rs\\'"
  :config (setq rust-format-on-save t))

(use-package racer
  :hook ((rust-mode . racer-mode)
         (racer-mode . eldoc-mode)
         (racer-mode . company-mode))
  :config
  (setq racer-rust-src-path (expand-file-name
                             (concat (string-trim (shell-command-to-string "rustc --print sysroot"))
                                     "/lib/rustlib/src/rust/library"))))

(use-package flycheck-rust
  :after (rust-mode flycheck)
  :hook (rust-mode . flycheck-rust-setup))

;; ---------------------------
;; Markdown 支持
;; ---------------------------
(setq markdown-command "pandoc")
(add-hook 'markdown-mode-hook 'company-mode)

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("8c7e832be864674c220f9a9361c851917a93f921fedb7717b1b5ece47690c098" default))
 '(package-selected-packages
   '(lua-mode gnu-elpa-keyring-update dracula-theme flycheck-rust rust-mode racer markdown-mode doom-themes smartparens treemacs-projectile projectile treemacs flycheck company)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

