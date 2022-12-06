" GVim Fullscreen Toggle. Most useful on macOS.
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-fullscreen-toggle
" License: https://creativecommons.org/publicdomain/zero/1.0/
"  vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Copyright © 2011-2021 Landon Bouma.

" AUDIENCE: Mostly MacVim users.

" USAGE: Press F11 to toggle fullscreen.
"
" BONUS: Try Shift-F11 to toggle tiling toward the right.

" WHY THIS PLUGIN:
"
"   - In GNOME and MATE, the *Maximize* and *Unmaximize* features are similar.
"
"     (So you might not (I really don't) find a need for this plugin on Linux.)
"
"     The Maximize features are reachable many different ways:
"
"     - Double-click the titlebar.
"
"     - Right-click the titlebar and choose Maximize or Unmaximize.
"
"     - Press <Alt-Space> and then <x>.
"
"     In fact, Maximize works better, as it'll expand the window completely
"     to the edges of the available desktop space, whereas this plugin
"     expands to nearest the column or row. I.e., you'll likely see a
"     tidge of space between Vim and screen-edge after pressing F11.
"
"   - On macOS, however, there is no obvious equivalent to GNOME/MATE Maximize.
"
"     - You can double-click the titlebar to 'Zoom' the window, but that only
"       maximizes the height, and it leaves the window width unchanged. (That
"       feature is also found at Window > Zoom, and Shift-Cmd-Z.)
"
"     - You can click the green circle in the titlebar, or choose the Window >
"       Toggle Full Screen Mode option (Shift-Cmd-F), which *will* make the
"       window fullscreen, but it also puts the window all alone on a new
"       Mission Control 'space', which not only might break your Alt-Tab usage
"       (I've got mine setup to only switch between windows on the same space),
"       but it's also annoyingly slow (I almost never use Full Screen Mode on
"       macOS because it takes so long to animate the changing of the spaces,
"       and it's also visually disruptive, super annoying to me).
"
"     - However, there is a great windowing application called Rectangle
"       that I highly recommend.
"
"         https://rectangleapp.com/
"
"       Specifically, the Rectangle *Maximize* command works similar to
"       this plugin. (See also *Restore* to undo the maximize.)
"
"   - On Windows, this plugin probably works. It did for me 10 years ago
"     when I was a regular Cygwin user, but I haven't tested again since.
"     But like Linux, Windows already has a comparable Maximize feature
"     built-in, so a Windows user might not find this plugin that useful.

" NOTES: The Shift-F11 toggle may not tile to the right how you want.
"
"   - It works well for me on my 1920x1080 monitor with the default
"     columns value below, but you might need to set a different value.
"
"   - On macOS, consider also the Rectangle.app *Right Half* command.

" NAMING: Perhaps to differentiate from macOS 'Full Screen Mode'
"         this plugin should rather be called 'fillscreen'.

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" YOU: Uncomment next 'unlet', then <F9> to reload this file.
"      (Iff: https://github.com/landonb/vim-source-reloader)
"
" silent! unlet g:loaded_plugin_view_fullscreen_toggle

if exists('g:loaded_plugin_view_fullscreen_toggle') || &cp || v:version < 800
  finish
endif

let g:loaded_plugin_view_fullscreen_toggle = 1

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" For toggling back.
let s:prev_vim_y = 999
let s:prev_vim_x = 999
let s:prev_win_y = 0
let s:prev_win_x = 0

function! s:ToggleResizeWindow(sticky_x)
  if exists('s:is_toggle_enabled')
     \ && (1 == s:is_toggle_enabled)
    exec "set" . " lines=" . s:prev_vim_y . " columns=" . s:prev_vim_x
    exec "winpos " . s:prev_win_x . " " . s:prev_win_y
    let s:is_toggle_enabled = 0
  else
    let s:prev_win_y = getwinposy()
    let s:prev_win_x = getwinposx()
    let s:prev_vim_y = &lines
    let s:prev_vim_x = &columns
    " MAGIC: Rather than measure the screen, just go Extra Big.
    " - Gvim/MacVim will figure it out and restrict dimensions.
    if a:sticky_x == 0
      set columns=999 lines=999
    else
      " (lb): This is probably Very Somewhat specific to my 1920x1080 monitor.
      winpos 657 0
      set columns=179 lines=999
    endif
    let s:is_toggle_enabled = 1
  endif
endfunction
let s:is_toggle_enabled = 0

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

noremap <silent> <unique> <script> <Plug>ToggleFullscreen_Fill :call <SID>ToggleResizeWindow(0)<CR>
noremap <silent> <unique> <script> <Plug>ToggleFullscreen_RightHalf :call <SID>ToggleResizeWindow(1)<CR>

let s:ignore_next_resized = 0
autocmd VimResized *
  \ if (&lines == 999) || (&columns == 999) |
  \   let s:ignore_next_resized = 1 |
  \ elseif (s:ignore_next_resized == 0) |
  \   let s:is_toggle_enabled = 0 |
  \ else |
  \   let s:ignore_next_resized = 0 |
  \ endif

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

