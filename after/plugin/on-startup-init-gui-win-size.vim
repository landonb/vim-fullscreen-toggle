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
"
"     au GUIEnter * simalt ~x

" ***

" Also, don't call resize right away, because, on startup, the
"   window dimensions have not settled yet.
"
"   - If we call too early, the plugin will misintrepret the
"     final dimensions, after they've settled, as user dimensions.
"     Then the first time you hit <F11>, instead of fullscreen, the
"     plugin will think the user manually resized the window, and
"     it'll resize mostly fullscreen, but the dimensions won't
"     actually change.
"
" - TNERR/2024-12-18: Via trial and error, it seems 75 msec. is too
"   quick on startup (toggler records window dimensions before they've
"   settled, so then next toggle assumes startup dims were user dims,
"   and then it resizes to mostly fullscreen (again), so you end up
"   with two toggle states using same dims (user and mostly fs)).
"
"   - I next tried 150 msec, which I haven't seen not work.
"     (I didn't try anything less; and it's not like this
"      affects startup time, anyway.)
"
" let l:empirical_timeout_msec = 75  " too quick!
let s:empirical_timeout_msec = 150

" ***

function! s:InitWindowSize()
  if exists('g:vim_fullscreen_toggle_disable')
      \ && g:vim_fullscreen_toggle_disable

    return
  endif

  if has('gui_running')
    let timer_id = timer_start(
      \ s:empirical_timeout_msec,
      \ function('g:embrace#resize#ResetWindowMostlyFullscreen'),
      \ )
  endif
endfunction

call s:InitWindowSize()

