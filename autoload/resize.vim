" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-fullscreen-toggle#💯
" License: https://creativecommons.org/publicdomain/zero/1.0/
"  vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Copyright © 2011-2024 Landon Bouma.

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" display-aware gVim/MacVim window fullsizer and resizer

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" AUDIENCE: Mostly MacVim users, but also useful for gVim with `xrandr`.

" USAGE: Press F11 to resize gVim/MacVim, and cycle through sizes.
"
" - BONUS: Shift-F11 toggle puts Vim in right-half of screen.
"
" - To use your own bindings, define g:TBVIMCreateDefaultMappings = 0
"   to skip the <F11> and <S-F11> mappings, and then define your own.

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
"   - This plugin is untested on Windows.

" NOTES: The Shift-F11 is similar to some desktop manager mappings:
"
"   - On macOS, consider also the Rectangle.app *Right Half* command.
"
"   - On MATE, see 'Tile window to east (right) side of screen' binding.
"
"   - But those mechanism will not resize the Vim window panes, whereas
"     this plugin with adjust vertical splits to equal widths.

" WORDS: Perhaps to differentiate from macOS 'Full Screen Mode'
"        this plugin should rather be called 'fillscreen'.

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" YOU: Uncomment next 'unlet', then <F9> to reload this file.
"      (Iff: https://github.com/landonb/vim-source-reloader)
"
" silent! unlet g:loaded_plugin_vim_fullscreen_toggle_autoload

if exists('g:loaded_plugin_vim_fullscreen_toggle_autoload') || &cp || v:version < 800
  finish
endif

let g:loaded_plugin_vim_fullscreen_toggle_autoload = 1

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
"
let s:part_win_x = 0
let s:part_win_y = 0
let s:part_vim_x = 0
let s:part_vim_y = 0

let s:state_toggle = 0
let s:mutex_ignore_next_vimresized = 0

" For s:state_toggle == 2
let s:partial_w = 0.80
let s:partial_h = 0.90

" DEVEL: Enable this for trace.
let s:trace = 0

function! resize#ToggleResizeWindow(sticky_x)
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
  " block) or if those original dimensions match full screen (2nd s:user_*
  " block). I.e., skip this state if user dimensions same as one of the other
  " 2 states.
  if (s:state_toggle == 2)
    \ && (s:user_vim_x > 0)
    \ && (s:user_vim_y > 0)
    \ && (!(1
      \ && (s:user_win_x == s:part_win_x)
      \ && (s:user_win_y == s:part_win_y)
      \ && (s:user_vim_x == s:part_vim_x)
      \ && (s:user_vim_y == s:part_vim_y)))
    \ && (!(1
      \ && (s:user_win_x == s:full_win_x)
      \ && (s:user_win_y == s:full_win_y)
      \ && (s:user_vim_x == s:full_vim_x)
      \ && (s:user_vim_y == s:full_vim_y)))

    if s:trace == 1
      echom 'toggle off: user_win: (' .. s:user_win_x .. ', ' .. s:user_win_y .. ') / '
        \ .. 'user_vim: (' .. s:user_vim_x .. ' x ' .. s:user_vim_y .. ') / '
        \ .. 'state_toggle: ' .. s:state_toggle .. ' / '
        \ .. 'sticky_x: ' .. a:sticky_x
    endif

    exec 'set columns=' .. s:user_vim_x .. ' lines=' .. s:user_vim_y
    exec 'winpos ' .. s:user_win_x .. ' ' .. s:user_win_y

    let s:state_toggle = 0
  else
    let limit_w = 1
    let limit_h = 1

    if (abs(s:state_toggle) == 1)
      " Fullscreen
      let s:state_toggle = 1

      " Set Totally Fullscreen vars
      let limit_w = 1
      let limit_h = 1
    else
      " Mostly fullscreen
      let s:state_toggle = 0

      " Remember original window dimensions.
      let s:user_win_x = getwinposx()
      let s:user_win_y = getwinposy()
      let s:user_vim_x = &columns
      let s:user_vim_y = &lines

      " Set Mostly Fullscreen vars
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

    " ***

    let use_secondary = 0
    if exists('g:resize_fullscreen_use_secondary_display')
      let use_secondary = g:resize_fullscreen_use_secondary_display
    endif

    let dimensions = resize#DisplayOffsetAndResolution(use_secondary)
    let [xoff, yoff, size_w, size_h] = dimensions

    if a:sticky_x == 1
      let limit_w = 0.5
      let xoff = str2nr(xoff + (size_w / 2))
    endif

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
    "call resize#SavePrevDimensions()

    if s:state_toggle == 0
      let s:part_win_x = getwinposx()
      let s:part_win_y = getwinposy()
      let s:part_vim_x = &columns
      let s:part_vim_y = &lines
    elseif s:state_toggle == 1
      let s:full_win_x = getwinposx()
      let s:full_win_y = getwinposy()
      let s:full_vim_x = &columns
      let s:full_vim_y = &lines
    endif

    " If orig size same as mostly fullscreen, means nothing changed
    " just now, so move on to next state, fully fullscreen.
    if (s:state_toggle == 0)
      \ && (s:orig_win_x == s:part_win_x)
      \ && (s:orig_win_y == s:part_win_y)
      \ && (s:orig_vim_x == s:part_vim_x)
      \ && (s:orig_vim_y == s:part_vim_y)

      let s:state_toggle = -1

      call resize#ToggleResizeWindow(a:sticky_x)
    elseif (s:state_toggle == 0)
      let s:state_toggle = 1
    elseif (s:state_toggle == 1)
      let s:state_toggle = 2
    endif
  endif

  call resize#ResizeVerticalWindows()

  call resize#SavePrevDimensions()
endfunction

function! resize#SavePrevDimensions()
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

function! resize#DisplayOffsetAndResolution(use_secondary) abort
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

function! resize#ResizeVerticalWindows()
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

  let total_cols = resize#Reduce(function('resize#ReducerAdd'), wcols)

  let equal_cols = str2nr(total_cols / len(wnums))

  for wnum in wnums
    execute wnum .. 'wincmd w | vertical resize ' .. equal_cols
  endfor

  " Move cursor back to starting window.
  execute orig_winnr . 'wincmd w'
endfunction

function! resize#ReducerAdd(acc, head)
  return a:acc + a:head
endfunction

" ***

" COPYD/2024-03-04: https://stackoverflow.com/a/18812122
function! resize#Reduce(f, list)
  let [acc; tail] = a:list

  while !empty(tail)
    let [head; tail] = tail
    let acc = a:f(acc, head)
  endwhile

  return acc
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

