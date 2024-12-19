" vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-fullscreen-toggle#💯
" License: https://creativecommons.org/publicdomain/zero/1.0/
"   Copyright © 2021-2024 Landon Bouma.

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

function! g:embrace#fullscreen_toggle#InitWindowSize()
  if has('gui_running')
    let timer_id = timer_start(
      \ s:empirical_timeout_msec,
      \ function('g:embrace#resize#ResetWindowMostlyFullscreen'),
      \ )
  endif
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" *** Mappings.

" Reminders:
" - noremap does not resolve {rhs} characters (so don't use when
"   <Plug> is in the {rhs}, or the <Plug> won't be resolved).
" - <silent> keeps the mapping from being echoed on the command line.
" - <unique> is strict, and the map fails if the {lhs} name is already defined.
" - <script> only resolves {rhs} characters using mappings local to this script.
" - <buffer> constrains a mapping to the current buffer only, not what we want.
" So while <silent> necessary, <unique> and <script> are not, but signal intent.
function! g:embrace#fullscreen_toggle#CreateMapPlugs()
  silent! unmap <silent> <unique> <script> <Plug>ToggleFullscreen_Fill
  silent! unmap <silent> <unique> <script> <Plug>ToggleFullscreen_RightHalf
  silent! unmap <silent> <unique> <script> <Plug>ToggleFullscreen_Reset

  noremap <silent> <unique> <script> <Plug>ToggleFullscreen_Fill :call g:embrace#resize#ToggleResizeWindow(0)<CR>
  noremap <silent> <unique> <script> <Plug>ToggleFullscreen_RightHalf :call g:embrace#resize#ToggleResizeWindow(1)<CR>
  noremap <silent> <unique> <script> <Plug>ToggleFullscreen_Reset :call g:embrace#resize#ResetWindowMostlyFullscreen(0)<CR>
endfunction

" ***

function! g:embrace#fullscreen_toggle#CreateMaps()
  call g:embrace#fullscreen_toggle#CreateMapPlugs()

  nnoremap <F11> <Plug>ToggleFullscreen_Fill
  inoremap <F11> <C-O><Plug>ToggleFullscreen_Fill

  nnoremap <S-F11> <Plug>ToggleFullscreen_RightHalf
  inoremap <S-F11> <C-O><Plug>ToggleFullscreen_RightHalf

  command! -nargs=0 ToggleFullscreenReset :call g:embrace#resize#ResetWindowMostlyFullscreen(0)
endfunction

