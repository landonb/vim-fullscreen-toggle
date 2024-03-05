" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-fullscreen-toggle#💯
" License: https://creativecommons.org/publicdomain/zero/1.0/
"  vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Copyright © 2011-2024 Landon Bouma.

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" YOU: Uncomment next 'unlet', then <F9> to reload this file.
"      (Iff: https://github.com/landonb/vim-source-reloader)
"
" silent! unlet g:loaded_plugin_vim_fullscreen_toggle_after

if exists('g:loaded_plugin_vim_fullscreen_toggle_after') || &cp || v:version < 800
  finish
endif

let g:loaded_plugin_vim_fullscreen_toggle_after = 1

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

noremap <silent> <unique> <script> <Plug>ToggleFullscreen_Fill :call resize#ToggleResizeWindow(0)<CR>
noremap <silent> <unique> <script> <Plug>ToggleFullscreen_RightHalf :call resize#ToggleResizeWindow(1)<CR>

" If user resizes Vim, reset the fullscreen toggle state, so next fullscreen
" call starts at s:state_toggle == 0, which will begin the cycle anew:
"   fullscreen → partially full → reset to user's original view

" ISOFF/2024-03-04: This was previous implementation, which used '999' values:
" - If you over-extend the Vim window, it'll resize twice, once to the too-large
"   (999) value(s), then it'll resize to the max necessary to fit the display.
"   - However, if there are 2 displays, Vim will use the entirety of both
"     displays. So the '999' trick is not very robust, and we no longer use it.
"
" autocmd VimResized *
"   \ if (&lines == 999) || (&columns == 999) |
"   \   let s:mutex_ignore_next_vimresized = 1 |
"   \ elseif (s:mutex_ignore_next_vimresized == 0) |
"   \   let s:state_toggle = 0 |
"   \ else |
"   \   let s:mutex_ignore_next_vimresized = 0 |
"   \ endif

augroup plugin_view_fullscreen_toggle
  autocmd!
  " ISOFF/2024-03-04: This works, but we can also save dimensions at end
  " of ToggleResizeWindow, and then compare them to the values at the start
  " of the next call to ToggleResizeWindow — and if they're different, assume
  " user moved or resized window. Note the new approach also detects if the
  " window was moved, for which there is no Vim event, so using VimResized
  " here, while it works for resize, does nothing for an offset change/move.
  "
  " autocmd VimResized *
  "   \ if (s:mutex_ignore_next_vimresized > 0) |
  "   \   let s:mutex_ignore_next_vimresized -= 1 |
  "   \   echom 'DECREMENT s:mutex_ignore_next_vimresized' |
  "   \ else |
  "   \   let s:state_toggle = 0 |
  "   \   echom 'RESET s:state_toggle' |
  "   \ endif
augroup END

" ***

function! s:CreateMaps()
  nmap <F11> <Plug>ToggleFullscreen_Fill
  imap <F11> <C-O><Plug>ToggleFullscreen_Fill

  nmap <S-F11> <Plug>ToggleFullscreen_RightHalf
  imap <S-F11> <C-O><Plug>ToggleFullscreen_RightHalf
endfunction

if !exists("g:TBVIMCreateDefaultMappings") || g:TBVIMCreateDefaultMappings
  call s:CreateMaps()
endif

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

