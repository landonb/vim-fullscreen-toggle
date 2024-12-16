" vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-fullscreen-toggle#💯
" License: https://creativecommons.org/publicdomain/zero/1.0/
"   Copyright © 2021-2024 Landon Bouma.

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" USAGE: Unlet var (or nix finish) & press <F9> to reload this plugin.
" USING: https://github.com/landonb/vim-source-reloader#↩️
"
"  silent! unlet g:loaded_vim_fullscreen_toggle_on_startup

if exists("g:loaded_vim_fullscreen_toggle_on_startup") || &cp

  finish
endif

let g:loaded_vim_fullscreen_toggle_on_startup = 1

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" *** Start up window size

" Start GUI GVim mostly fullscreen.
"
" - Ignore for CLI Vim so we don't change terminal size.
"
" - SAVVY: If this is disabled, default `gvim --servername foo <file>`
"   creates GVim window centered in display, at something like 60% of
"   the display width, and ~70% of the height, at least on author's
"   2560x1440 display — I see the equivalent of:
"     set columns=179 lines=65
"     winpos 648 181
"
" - ALTLY: To start maximized in MATE (using MATE's <Alt-space x>) try:
"     au GUIEnter * simalt ~x

if has("gui_running")
  call g:embrace#resize#ToggleResizeWindow(0)
endif

