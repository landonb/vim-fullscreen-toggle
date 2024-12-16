" vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-fullscreen-toggle#💯
" License: https://creativecommons.org/publicdomain/zero/1.0/
"   Copyright © 2021-2024 Landon Bouma.

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" USAGE: Unlet var (or nix finish) & press <F9> to reload this plugin.
" USING: https://github.com/landonb/vim-source-reloader#↩️
"
"  silent! unlet g:loaded_vim_fullscreen_toggle_create_maps

if exists("g:loaded_vim_fullscreen_toggle_create_maps") || &cp || v:version < 800

  finish
endif

let g:loaded_vim_fullscreen_toggle_create_maps = 1

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

silent! unmap <silent> <unique> <script> <Plug>ToggleFullscreen_Fill
silent! unmap <silent> <unique> <script> <Plug>ToggleFullscreen_RightHalf

noremap <silent> <unique> <script> <Plug>ToggleFullscreen_Fill :call g:embrace#resize#ToggleResizeWindow(0)<CR>
noremap <silent> <unique> <script> <Plug>ToggleFullscreen_RightHalf :call g:embrace#resize#ToggleResizeWindow(1)<CR>

" ***

function! s:CreateMaps()
  if exists("g:vim_fullscreen_toggle_disable")
      \ && g:vim_fullscreen_toggle_disable

    return
  endif

  nnoremap <F11> <Plug>ToggleFullscreen_Fill
  inoremap <F11> <C-O><Plug>ToggleFullscreen_Fill

  nnoremap <S-F11> <Plug>ToggleFullscreen_RightHalf
  inoremap <S-F11> <C-O><Plug>ToggleFullscreen_RightHalf
endfunction

call s:CreateMaps()

