" Dubs Vim initial GUI dimensions and placement.
" Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
" Online: https://github.com/landonb/dubs_appearance
" License: https://creativecommons.org/publicdomain/zero/1.0/

if exists("g:loaded_plugin_init_gui_win_size") || &cp
  finish
endif
let g:loaded_plugin_init_gui_win_size = 1

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Start up window size
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" Start Mostly Fullscreen
" ------------------------------------------------------
" Start with a reasonably sized window for GUIs
" (ignore for CLI so we don't change terminal size)

" - SAVVY: If this is disabled, default `gvim --servername sampi <file>`
"   creates GVim window centered in display, at something like 60% of
"   the display width, and ~70% of the height, at least on a 2560x1440
"   display — I see the equivalent of:
"     set columns=179 lines=65
"     winpos 648 181
"
" - ALTLY: To start maximized in MATE (using MATE's <Alt-space x>) try:
"     au GUIEnter * simalt ~x

if has("gui_running")
  call resize#ToggleResizeWindow(0)
endif

