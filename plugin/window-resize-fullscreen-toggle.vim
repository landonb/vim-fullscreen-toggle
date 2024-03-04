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

" USAGE: Override these from your startup plug:
" 
"  let g:resize_fullscreen_use_secondary_display = 0
"  let g:resize_fullscreen_limit_w = 0.80
"  let g:resize_fullscreen_limit_h = 0.90
"  let g:resize_fullscreen_pixels_per_col = 7.014
"  let g:resize_fullscreen_pixels_per_row = 16.180
"
" MAYBE/2024-03-04: Let user set any of x,y,w,h directly,
" and/or let user specify offset_x_weight, e.g., to nudge
" window off-center (I like mine a little to the right of
" center).

" For toggling back.
let s:user_win_x = 0
let s:user_win_y = 0
let s:user_vim_x = 0
let s:user_vim_y = 0

" For resetting state_toggle if user moves window.
let s:prev_win_x = 0
let s:prev_win_y = 0
let s:prev_vim_x = 0
let s:prev_vim_y = 0

" For skipping user values if same dimensions as another state.
let s:full_win_x = 0
let s:full_win_y = 0
let s:full_vim_x = 0
let s:full_vim_y = 0

let s:state_toggle = 0
let s:mutex_ignore_next_vimresized = 0

" For s:state_toggle == 2
let s:partial_w = 0.80
let s:partial_h = 0.90

" DEVEL: Enable this for trace.
let s:trace = 0

function! s:ToggleResizeWindow(sticky_x)
  " Ignore the next two VimResized events, 1 each for set columns, winpos.
  let s:mutex_ignore_next_vimresized = 2

  if 0
    \ || (s:prev_win_x != getwinposx())
    \ || (s:prev_win_y != getwinposy())
    \ || (s:prev_vim_x != &columns)
    \ || (s:prev_vim_y != &lines)
    " User moved the window. (Note there's a VimResized event,
    " but no event for window moved, hence this state check.)
    " - Reset the state toggle, but not if recursed into this function.
    if s:state_toggle != -1
      if s:trace == 1
        echom 'RESET: prev_win: (' .. s:prev_win_x .. ', ' .. s:prev_win_y .. ') / '
          \ .. 'prev_vim: (' .. s:prev_vim_x .. ' x ' .. s:prev_vim_y .. ') / '
          \ .. 'getwinpos: (' .. getwinposx() .. ', ' .. getwinposy() .. ') / '
          \ .. 'size: (' .. &columns .. ' x ' .. &lines .. ')'
      endif
      let s:state_toggle = 0
    endif
  endif

  " Check if next state restores original user dimensions (state_toggle == 2),
  " unless those original dimensions match the current window (1st s:user_*
  " block) or if those original dimenstions match full screen (2nd s:user_*
  " block). I.e., skip this state if user dimensions same as one of the other
  " 2 states.
  if (s:state_toggle == 2)
    \ && (s:user_vim_x > 0)
    \ && (s:user_vim_y > 0)
    \ && (!(1
      \ && (s:user_win_x == getwinposx())
      \ && (s:user_win_y == getwinposy())
      \ && (s:user_vim_x == &columns)
      \ && (s:user_vim_y == &lines)))
    \ && (!(1
      \ && (s:user_win_x == s:full_win_x)
      \ && (s:user_win_y == s:full_win_y)
      \ && (s:user_vim_x == s:full_vim_x)
      \ && (s:user_vim_y == s:full_vim_y)))

    let s:state_toggle = 0

    if s:trace == 1
      echom 'toggle off: user_win: (' .. s:user_win_x .. ', ' .. s:user_win_y .. ') / '
        \ .. 'user_vim: (' .. s:user_vim_x .. ' x ' .. s:user_vim_y .. ') / '
        \ .. 'state_toggle: ' .. s:state_toggle .. ' / '
        \ .. 'sticky_x: ' .. a:sticky_x
    endif

    exec 'set columns=' .. s:user_vim_x .. ' lines=' .. s:user_vim_y
    exec 'winpos ' .. s:user_win_x .. ' ' .. s:user_win_y
  else
    let limit_w = 1
    let limit_h = 1

    if (abs(s:state_toggle) == 1)
      let s:state_toggle = 2

      if exists('g:resize_fullscreen_limit_w')
        let limit_w = g:resize_fullscreen_limit_w
      else
        let limit_w = s:partial_w
      endif

      if exists('g:resize_fullscreen_limit_h')
        let limit_h = g:resize_fullscreen_limit_h
      else
        let limit_h = s:partial_h
      endif
    else
      let s:state_toggle = 1

      let s:user_win_x = getwinposx()
      let s:user_win_y = getwinposy()
      let s:user_vim_x = &columns
      let s:user_vim_y = &lines
    endif

    " ***

    " ISOFF/2024-03-04: See comment below re: sloppy '999' approach.
    "
    " " MAGIC: Rather than measure the screen, just go Extra Big.
    " " - Gvim/MacVim will figure it out and restrict dimensions.
    " if a:sticky_x == 0
    "   set columns=999 lines=999
    " else
    "   " (lb): This is probably Very Somewhat specific to my 1920x1080 monitor.
    "   winpos 657 0
    "   set columns=179 lines=999
    " endif

    let use_secondary = 0
    if exists('g:resize_fullscreen_use_secondary_display')
      let use_secondary = g:resize_fullscreen_use_secondary_display
    endif

    let dimensions = s:DisplayOffsetAndResolution(use_secondary)
    let [xoff, yoff, size_w, size_h] = dimensions

    " MAYBE/2024-03-03: Find better way to translate display manager window
    " pixels to Vim lines and columns.
    " - Because we need both, pixels for :winpos, font units for set-columns/lines.
    " - SAVVY/2024-03-03: Based on guifont = 'Hack Nerd Font Mono 9' and whatever
    "   other monitor/display settings the author might be using, some values for
    "   a fullscreen GVim window in a 2560x1440 display (with a MATE titlebar, and
    "   3 rows of mate-panel):
    "     :echo &columns → 365 / :echo &lines → 89 / `wmctrl -lG | grep sampi` → 2560x1345
    "   It follows:
    "     2560/365 → 7.014 pixels/column / 1440/89 → 16.180 pixels/line

    let pixels_per_col = 7.014
    if exists('g:resize_fullscreen_pixels_per_col')
      let pixels_per_col = g:resize_fullscreen_pixels_per_col
    endif

    let pixels_per_row = 16.180
    if exists('g:resize_fullscreen_pixels_per_row')
      let pixels_per_row = g:resize_fullscreen_pixels_per_row
    endif

    let xoff = str2nr(xoff + ((size_w * (1 - limit_w)) / 2))
    let yoff = str2nr(yoff + ((size_h * (1 - limit_h)) / 2))

    let vim_x = str2nr(limit_w * size_w / pixels_per_col)
    let vim_y = str2nr(limit_h * size_h / pixels_per_row)

    if s:trace == 1
      echom 'DOAR: xoff: (' .. xoff .. ', ' .. yoff .. ') / '
        \ .. 'size: (' .. size_w .. ' x ' .. size_h .. ') // '
        \ .. 'new sz: (' .. vim_x .. ' x ' .. vim_y .. ') // '
        \ .. 'toggle on: user_win: (' .. s:user_win_x .. ', ' .. s:user_win_y .. ') / '
        \ .. 'user_vim: (' .. s:user_vim_x .. ' x ' .. s:user_vim_y .. ') / '
        \ .. 'state_toggle: ' .. s:state_toggle .. ' / '
        \ .. 'sticky_x: ' .. a:sticky_x
    endif

    let s:orig_win_x = getwinposx()
    let s:orig_win_y = getwinposy()
    let s:orig_vim_x = &columns
    let s:orig_vim_y = &lines

    execute 'set columns=' .. vim_x .. ' lines=' .. vim_y
    execute 'winpos ' .. xoff .. ' ' .. yoff
    "call s:SavePrevDimensions()

    if s:state_toggle == 1
      let s:full_win_x = getwinposx()
      let s:full_win_y = getwinposy()
      let s:full_vim_x = &columns
      let s:full_vim_y = &lines

      " If orig size was already fullscreen, than move on to next
      " state, partial fullscreen.
      if (1
        \ && (s:orig_win_x == s:full_win_x)
        \ && (s:orig_win_y == s:full_win_y)
        \ && (s:orig_vim_x == s:full_vim_x)
        \ && (s:orig_vim_y == s:full_vim_y))

        let s:state_toggle = -1

        call s:ToggleResizeWindow(a:sticky_x)
      endif
    endif
  endif

  call s:ResizeVerticalWindows()

  call s:SavePrevDimensions()
endfunction

function! s:SavePrevDimensions()
  let s:prev_win_x = getwinposx()
  let s:prev_win_y = getwinposy()
  let s:prev_vim_x = &columns
  let s:prev_vim_y = &lines
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" COPYD/2024-03-03: Thanks!
"   https://vi.stackexchange.com/a/37965

" REFER/2024-03-03: What you might see with two displays:
"   $ xrandr
"   Screen 0: minimum 320 x 200, current 4480 x 2520, maximum 16384 x 16384
"   eDP-1 connected 1920x1080+2560+1440 (normal left inverted right x axis y axis) 309mm x 174mm
"   ...
"   DP-1 connected primary 2560x1440+0+0 (normal left inverted right x axis y axis) 597mm x 336mm
"   ...
"   HDMI-1 disconnected (normal left inverted right x axis y axis)
"   ...

function! s:DisplayOffsetAndResolution(use_secondary) abort
  " Default, in case the command fails.
  let [xoff, yoff, dw, dh] = [0, 0, 1920, 1080]

  let filter_str = "' connected primary'"
  if a:use_secondary
    let filter_str = "-v " .. filter_str .. " | grep ' connected '"
  endif

  " Get resolution from xrandr, and match the resolution.
  let dimensions = system("xrandr --query | grep " .. filter_str)
  if v:shell_error > 0
    echom '- v:shell_error: ' .. v:shell_error
    return [xoff, yoff, dw, dh]
  endif

  let matches = dimensions->matchlist('\(\d\+\)x\(\d\+\)+\(\d\+\)+\(\d\+\)')
  if len(matches) == 0
    echom '- no matches'
    return [xoff, yoff, dw, dh]
  endif

  " Split resolution by [width]x[height] and convert the string to a
  " number.
  let [match_w, match_h, match_xoff, match_yoff] = matches[1:4]->map({_, match -> str2nr(match)})
  if match_w == 0 || match_h == 0
    echom '- match size 0'
    return [xoff, yoff, dw, dh]
  endif

  return [match_xoff, match_yoff, match_w, match_h]
endfun

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" CXREF: The following is an improved equal-width window resizer,
" akin to what dubs_project_tray does:
"   https://github.com/landonb/dubs_project_tray
"     DubsProjectTray_ToggleProject_Wrapper
" - MAYBE/2024-03-04: Port this solution back to dubs_project_tray,
"   I think it's a far better approach.

function! s:ResizeVerticalWindows()
  " Use mkview/loadview to store current view, i.e., to maintain
  " current folds (otherwise Vim resets them when you reenter buffer).
  " NOTE: Use silent to avoid "E35: No file name" warning message.
  silent! mkview

  let orig_winnr = winnr()

  let proj_winnr = -1
  if exists('g:proj_running')
    let proj_winnr = bufwinnr(g:proj_running)
  endif

  " Numbers of windows that view target buffer which we will delete.
  "  \ 'win_screenpos(v:val)[0] == 1 && !<SID>IsWindowSpecial(v:val)')
  let wnums = filter(range(1, winnr('$')),
    \ 'win_screenpos(v:val)[0] == 1 && (v:val != ' .. proj_winnr ..')')

  let wcols = copy(wnums)->map({_, wnum -> winwidth(wnum)})

  let total_cols = Reduce(function('ReducerAdd'), wcols)

  let equal_cols = str2nr(total_cols / len(wnums))

  for wnum in wnums
    execute wnum .. 'wincmd w | vertical resize ' .. equal_cols
  endfor

  " Move cursor back to starting window.
  execute orig_winnr . 'wincmd w'
endfunction

function! ReducerAdd(acc, head)
  return a:acc + a:head
endfunction

" ***

" COPYD/2024-03-04: https://stackoverflow.com/a/18812122
function! Reduce(f, list)
  let [acc; tail] = a:list

  while !empty(tail)
    let [head; tail] = tail
    let acc = a:f(acc, head)
  endwhile

  return acc
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

silent! unmap <silent> <unique> <script> <Plug>ToggleFullscreen_Fill
silent! unmap <silent> <unique> <script> <Plug>ToggleFullscreen_RightHalf

noremap <silent> <unique> <script> <Plug>ToggleFullscreen_Fill :call <SID>ToggleResizeWindow(0)<CR>
noremap <silent> <unique> <script> <Plug>ToggleFullscreen_RightHalf :call <SID>ToggleResizeWindow(1)<CR>

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

