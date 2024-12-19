" vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-fullscreen-toggle#💯
" License: https://creativecommons.org/publicdomain/zero/1.0/
"   Copyright © 2021-2024 Landon Bouma.

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

