" vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/embrace-vim/vim-fullscreen-toggle#💯
" License: https://creativecommons.org/publicdomain/zero/1.0/
"   Copyright © 2021-2024 Landon Bouma.

" -------------------------------------------------------------------

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:loaded_vim_fullscreen_toggle_plugin
endif

if exists('g:loaded_vim_fullscreen_toggle_plugin') || &cp

  finish
endif

let g:loaded_vim_fullscreen_toggle_plugin = 1

" -------------------------------------------------------------------

" The :winpos (or getwinpos()) feature this plugin uses is not
" availabing in Neovide or nvim.
" - This plugin can still *resize* the window, but it cannot
"   move it's x,y within the Desktop Environment.
if has('nvim')
  echom 'ALERT: vim-fullscreen-toggle only works in vim-gtk or MacVim, not nvim or Neovide'

  finish
endif

" -------------------------------------------------------------------

" Reminders:
" - noremap does not resolve {rhs} characters (so don't use when
"   <Plug> is in the {rhs}, or the <Plug> won't be resolved).
" - <silent> keeps the mapping from being echoed on the command line.
" - <unique> is strict, and the map fails if the {lhs} name is already defined.
" - <script> only resolves {rhs} characters using mappings local to this script.
" - <buffer> constrains a mapping to the current buffer only, not what we want.
" So while <silent> necessary, <unique> and <script> are not, but signal intent.
function! s:CreateMapPlugs()
  silent! unmap <silent> <unique> <script> <Plug>ToggleFullscreen_Fill
  silent! unmap <silent> <unique> <script> <Plug>ToggleFullscreen_RightHalf
  silent! unmap <silent> <unique> <script> <Plug>ToggleFullscreen_Reset

  noremap <silent> <unique> <script> <Plug>ToggleFullscreen_Fill
    \ :call g:embrace#resize#ToggleResizeWindow(0)<CR>
  noremap <silent> <unique> <script> <Plug>ToggleFullscreen_RightHalf
    \ :call g:embrace#resize#ToggleResizeWindow(1)<CR>
  noremap <silent> <unique> <script> <Plug>ToggleFullscreen_Reset
    \ :call g:embrace#resize#ResetWindowMostlyFullscreen(0)<CR>
endfunction

function! s:CreateMaps()
  if get(g:, 'vim_fullscreen_toggle_create_maps', 0)

    return
  endif

  " Wires <F11>, <S-F11>, and :ToggleFullscreenReset.
  " - CXREF:
  "   ~/.kit/nvim/embrace-vim/start/vim-fullscreen-toggle/autoload/embrace/fullscreen_toggle.vim
  call g:embrace#fullscreen_toggle#CreateMaps()
endfunction

" -------------------------------------------------------------------

call s:CreateMapPlugs()

call s:CreateMaps()

