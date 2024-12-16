" vim:tw=0:ts=2:sw=2:et:norl:ft=vim
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-fullscreen-toggle#💯
" License: https://creativecommons.org/publicdomain/zero/1.0/
"   Copyright © 2011-2024 Landon Bouma.

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" display-aware gVim/MacVim window fullsizer and resizer

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" AUDIENCE: Mostly MacVim users, but also useful for gVim with `xrandr`.

" USAGE: Press F11 to resize gVim/MacVim, and cycle through sizes.
"
" - BONUS: Shift-F11 toggle puts Vim in right-half of screen.
"
" - To use your own bindings, define g:vim_fullscreen_toggle_disable = 1
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

" ALERT: After reloading this plugin, (getwinposx(), getwinposy()) is 0,0
"        until user drags or resizes the window again.

" WORDS: Perhaps to differentiate from macOS 'Full Screen Mode'
"        this plugin should rather be called 'fillscreen'.

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
let s:half_win_x = 0
let s:half_win_y = 0
let s:half_vim_x = 0
let s:half_vim_y = 0

let s:st_reset = 0
let s:st_init = 1
let s:st_mostly_fs = 2
let s:st_fullscreen = 3
let s:st_user_dims = 4

let s:state_toggle = s:st_init

" For s:state_toggle == s:st_mostly_fs
let s:partial_w = 0.80
let s:partial_h = 0.90

let s:resize_pending = 0

" DEVEL: Enable this for trace.
let s:trace = 0
" let s:trace = 1

function! g:embrace#resize#ToggleResizeWindow(sticky_x, new_state = '') abort
  if a:new_state != ''
    let s:state_toggle = a:new_state
  endif

  " If user tries toggling too fast, s:prev_* won't be caught up.
  if s:resize_pending

    return
  endif

  call s:SaveCurrDimensions()

  " Check if user moved the window. (Note there's a VimResized event,
  " but no event for window moved, hence this state check.)
  if s:state_toggle == s:st_init
    \ || (s:prev_win_x != s:curr_win_x)
    \ || (s:prev_win_y != s:curr_win_y)
    \ || (s:prev_vim_x != s:curr_vim_x)
    \ || (s:prev_vim_y != s:curr_vim_y)
    if s:trace == 1
      echom 'RESET: prev_win: (' .. s:prev_win_x .. ', ' .. s:prev_win_y .. ') / '
        \ .. 'prev_vim: (' .. s:prev_vim_x .. ' x ' .. s:prev_vim_y .. ') / '
        \ .. 'curr_win: (' .. s:curr_win_x .. ', ' .. s:curr_win_y .. ') / '
        \ .. 'curr_vim: (' .. s:curr_vim_x .. ' x ' .. s:curr_vim_y .. ')'
    endif

    let s:state_toggle = s:st_mostly_fs

    if s:state_toggle != s:st_init
      call s:SaveUserDimensions()
    endif
  endif

  " ***

  call EmbraceResizeSavePrevDimensions('reset')

  if s:trace == 1
    echom 'user dim: user_win: (' .. s:user_win_x .. ', ' .. s:user_win_y .. ') / '
      \ .. 'user_vim: (' .. s:user_vim_x .. ' x ' .. s:user_vim_y .. ') / '
      \ .. 'state_toggle: ' .. s:state_toggle .. ' / '
      \ .. 'sticky_x: ' .. a:sticky_x
  endif

  " Check if next state restores original user dimensions,
  " unless those original dimensions match the current window
  " (1st s:user_* block) or if those original dimensions match
  " full screen (2nd s:user_* block).
  " - I.e., skip this state if the user dimensions are the same
  "   as either one of the other 2 states.
  if (s:state_toggle == s:st_user_dims)
    if 1
      \ && (s:user_vim_x > 0)
      \ && (s:user_vim_y > 0)
      \ && (!(1
        \ && (s:user_win_x == s:half_win_x)
        \ && (s:user_win_y == s:half_win_y)
        \ && (s:user_vim_x == s:half_vim_x)
        \ && (s:user_vim_y == s:half_vim_y)))
      \ && (!(1
        \ && (s:user_win_x == s:full_win_x)
        \ && (s:user_win_y == s:full_win_y)
        \ && (s:user_vim_x == s:full_vim_x)
        \ && (s:user_vim_y == s:full_vim_y)))

      if s:trace == 1 | echom 'USER dim' | endif

      exec 'set columns=' .. s:user_vim_x .. ' lines=' .. s:user_vim_y
      exec 'winpos ' .. s:user_win_x .. ' ' .. s:user_win_y
    else
      " No user window size.
      if s:trace == 1 | echom 'no user dim' | endif

      let s:state_toggle = s:st_mostly_fs
    endif
  endif

  " ***

  if (s:state_toggle != s:st_user_dims)
    let limit_w = 1
    let limit_h = 1

    if s:state_toggle == s:st_fullscreen
      " Set Totally Fullscreen vars
      let limit_w = 1
      let limit_h = 1
    else
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

    let use_secondary = 0
    if exists('g:resize_fullscreen_use_secondary_display')
      let use_secondary = g:resize_fullscreen_use_secondary_display
    endif

    let dimensions = s:DisplayOffsetAndResolution(use_secondary)
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
    " - SAVVY/2024-12-16: These same values work well for the author
    "   in macOS on the same monitor, with hidden menubar and Dock.

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
        \ .. 'state_toggle: ' .. s:state_toggle .. ' / '
        \ .. 'sticky_x: ' .. a:sticky_x
    endif

    execute 'set columns=' .. vim_x .. ' lines=' .. vim_y
    execute 'winpos ' .. xoff .. ' ' .. yoff
  endif

  " ***

  if (s:state_toggle == s:st_user_dims)
    let s:state_toggle = s:st_mostly_fs
  elseif (s:state_toggle == s:st_mostly_fs)
    let s:state_toggle = s:st_fullscreen
  elseif (s:state_toggle == s:st_fullscreen)
    let s:state_toggle = s:st_user_dims
  endif

  call s:ResizeVerticalWindows()

  " Vim might still be resizing. Be patient.
  " - See comment above VimResized, below, for more.

  " Just FYI when tracing, to see that dims. not immed. updated.
  call EmbraceResizeSavePrevDimensions('after')

  let s:resize_pending = 1

  " At too quick a callback, if you run the toggle too fast, it won't
  " capture the correct resize dimensions, and the user dims. will be
  " overwritten (so then you'll be toggling between just mostly
  " fullyscreen and fully fullscreen).
  " - At 75 msec. or more, author has not been able to break the cycle.
  "   - At 0, 25, or 50 msec., if I <F11> quickly, I can break it.
  let empirical_timeout_msec = 75

  let timer_id = timer_start(l:empirical_timeout_msec, "EmbraceResizeSavePrevDimensions")
endfunction

" ***

function! s:SaveCurrDimensions() abort
  let s:curr_win_x = getwinposx()
  let s:curr_win_y = getwinposy()
  let s:curr_vim_x = &columns
  let s:curr_vim_y = &lines
endfunction

function! EmbraceResizeSavePrevDimensions(timer_id_or_msg = 0) abort
  let s:prev_win_x = getwinposx()
  let s:prev_win_y = getwinposy()
  let s:prev_vim_x = &columns
  let s:prev_vim_y = &lines

  let s:resize_pending = 0

  if s:trace == 1
    echom 'PREV: prev_win: (' .. s:prev_win_x .. ', ' .. s:prev_win_y .. ') / '
      \ .. 'prev_vim: (' .. s:prev_vim_x .. ' x ' .. s:prev_vim_y .. ') / '
      \ .. 'timer_id_or_msg: ' .. a:timer_id_or_msg
  endif
endfunction

function! s:SaveUserDimensions() abort
  let s:user_win_x = getwinposx()
  let s:user_win_y = getwinposy()
  let s:user_vim_x = &columns
  let s:user_vim_y = &lines
endfunction

" ***

" This event fires twice before the end of ToggleResizeWindow, i.e.,
" after each of the `set columns` and `winpos` calls. But it shows
" the same (old) dimensions as calling EmbraceResizeSavePrevDimensions()
" (or checking dim) at the end of ToggleResizeWindow.
" - Hence the timer kludge, because this doesn't work.
"
"   augroup embrace_resize_autocommands
"     au!
"
"     autocmd VimResized * call EmbraceResizeSavePrevDimensions(-1)
"   augroup END

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

  let system_cmd = s:SussDisplayResolutionCommand(a:use_secondary)

  " Get resolution from xrandr/osascript, and match for the resolution.
  let dimensions = system(system_cmd)
  if v:shell_error > 0
    echom 'vim-fillscreen-toggle: system call failed: ' .. v:shell_error

    return [xoff, yoff, dw, dh]
  endif

  let pattern = s:SussDisplayResolutionPattern()

  let matches = dimensions->matchlist(pattern)
  if len(matches) == 0
    echom 'vim-fillscreen-toggle: no matches!?'

    return [xoff, yoff, dw, dh]
  endif

  " Split resolution by [width]x[height] and convert the string to a
  " number.
  let [match_w, match_h, match_xoff, match_yoff] = matches[1:4]->map({_, match -> str2nr(match)})
  if match_w == 0 || match_h == 0
    echom 'vim-fillscreen-toggle: match size 0!?'

    return [xoff, yoff, dw, dh]
  endif

  return [match_xoff, match_yoff, match_w, match_h]
endfunction

function! s:SussDisplayResolutionCommand(use_secondary) abort
  if has("gui_gtk2") || has("gui_gtk3")
    return s:SussDisplayResolutionCommand_GTK(a:use_secondary)
  elseif has("macunix")
    return s:SussDisplayResolutionCommand_macOS(a:use_secondary)
  endif
endfunction

function! s:SussDisplayResolutionPattern() abort
  if has("gui_gtk2") || has("gui_gtk3")
    return s:SussDisplayResolutionPattern_GTK()
  elseif has("macunix")
    return s:SussDisplayResolutionPattern_macOS()
  endif
endfunction

function! s:SussDisplayResolutionCommand_GTK(use_secondary) abort
  let l:filter_str = "' connected primary'"
  if a:use_secondary
    let l:filter_str = "-v " .. l:filter_str .. " | grep ' connected '"
  endif

  let l:system_cmd = "xrandr --query | grep " .. l:filter_str

  return l:system_cmd
endfunction

" E.g., '0x0+2560+1440'
function! s:SussDisplayResolutionPattern_GTK() abort
  return '\(\d\+\)x\(\d\+\)+\(\d\+\)+\(\d\+\)'
endfunction

" BWARE/2024-04-14: Author only has 1 monitor attached to macOS.
" - Not sure if/how AppleScript works with 2. If not, `system_profiler`
"   returns resolutions for each attached monitor (though without
"   extra monitor to test, not sure how they're listed).
"   - E.g.,:
"       system_profiler SPDisplaysDataType | grep Resolution:
" - REFER: For possible multiple-monitor support, see old article
"   with broken like to solution:
"     https://daringfireball.net/2006/12/display_size_applescript_the_lazy_way
" - BWARE: AppleScript fails if Desktop is disabled ("hidden"):
"     defaults write com.apple.finder CreateDesktop -bool false
"
"   function! s:SussDisplayResolutionCommand_macOS__AppleScript(use_secondary) abort
"     " E.g., '0, 0, 2560, 1440' → '2560, 1440, 0, 0'
"     return "osascript -e 'tell application \"Finder\" to get bounds of window of desktop'"
"       \ . " | sed -E 's/^([0-9]+), ([0-9]+), ([0-9]+), ([0-9]+)$/\\3, \\4, \\1, \\2/'"
"   endfunction
"
" E.g.,
"   $ system_profiler SPDisplaysDataType
"   Graphics/Displays:
"
"       Apple M2:
"
"       ...
"             Resolution: 2560 x 1440 (QHD/WQHD - Wide Quad High Definition)
function! s:SussDisplayResolutionCommand_macOS(use_secondary) abort
  return "system_profiler SPDisplaysDataType"
    \ . " | grep '^ \\+Resolution:'"
    \ . " | head -n 1"
    \ . " | sed 's/ \\+/ /g'"
    \ . " | cut -d' ' -f3,5"
    \ . " | sed 's/\\([^ ]\\+\\) \\(.*\\)/\\1, \\2, 0, 0/'"
endfunction

" E.g., '2560, 1440, 0, 0' (reordered osascript output)
function! s:SussDisplayResolutionPattern_macOS() abort
  return '\(\d\+\), \(\d\+\), \(\d\+\), \(\d\+\)'
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" CXREF: The following is an improved equal-width window resizer,
" akin to what dubs_project_tray does:
"   https://github.com/landonb/dubs_project_tray
"     DubsProjectTray_ToggleProject_Wrapper
" - MAYBE/2024-03-04: Port this solution back to dubs_project_tray,
"   I think it's a far better approach.

function! s:ResizeVerticalWindows() abort
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

  let total_cols = g:embrace#resize#Reduce(function('s:ReducerAdd'), wcols)

  let equal_cols = str2nr(total_cols / len(wnums))

  for wnum in wnums
    execute wnum .. 'wincmd w | vertical resize ' .. equal_cols
  endfor

  " Move cursor back to starting window.
  execute orig_winnr . 'wincmd w'
endfunction

function! s:ReducerAdd(acc, head) abort
  return a:acc + a:head
endfunction

" ***

" COPYD/2024-03-04: https://stackoverflow.com/a/18812122
function! g:embrace#resize#Reduce(fcn, list) abort
  let [acc; tail] = a:list

  while !empty(tail)
    let [head; tail] = tail
    let acc = a:fcn(acc, head)
  endwhile

  return acc
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

