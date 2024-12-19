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
"
"   - This plugin likely does not work in Wayland.

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
"  let g:fstoggle_use_secondary_display = 0
"  let g:fstoggle_partial_w = 0.80
"  let g:fstoggle_partial_h = 0.90
"  let g:fstoggle_pixels_per_col = 7.014
"  let g:fstoggle_pixels_per_row = 16.180

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" At too quick a callback, if you run the toggle too fast, it won't
" capture the correct resize dimensions, and the user dims. will be
" overwritten (so then you'll be toggling between just mostly
" fullyscreen and fully fullscreen).
" - At at least 125 msec. or below, if author mashes <F11> 'too quickly',
"   I see issues detecting valid dims changes. This causes user dims to
"   be forgotten.
"   - For example, many times after going to fullscreen, if the timer_start
"     callback runs too soon, it doesn't capture the new 0,0 x,y for
"     fullscreen, but some other nonzero x,y values. Indeed, after <F11>
"     to fully fullscreen, when I'd inspect the dims manually:
"       echom 'x,y: ' .. getwinposx() .. 'x' .. getwinposy()
"     I'd see 0,0 (fullscreen), which wasn't what the timer callback
"     reported. But with a longer delay, the timer callback seems to
"     read the settled coordinates. (This isn't a perfect science. I
"     tried to monitor VimResized, but it, too, would fire before
"     getwinposx(), getwinposy(), &columns, and &lines would start to
"     report the new values. And I'm not aware what else we might do
"     other than use a kludgy timer callback.)
if !exists('g:fullscreen_toggle_timeout')
  let g:fullscreen_toggle_timeout = 250
endif

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" The state machine toggle states.
let s:st_init = 1
let s:st_mostly_fs = 2
let s:st_fullscreen = 3
let s:st_user_dims = 4

let s:state_toggle = s:st_init

" Percentage of fullscreen width and height,
"   for s:state_toggle == s:st_mostly_fs
"
" USAGE: User can override with, e.g.:
"   let g:fstoggle_partial_w = 0.80
"   let g:fstoggle_partial_h = 0.90
let s:partial_w = 0.80
let s:partial_h = 0.90

" MAYBE/2024-03-03: Find better way to translate display manager window
" pixels to Vim lines and columns.
" - Because we need both, pixels for :winpos, font units for set-columns/lines.
" - SAVVY/2024-03-03: Based on guifont = 'Hack Nerd Font Mono 9' and whatever
"   other monitor/display settings the author might be using, some values for
"   a fullscreen GVim window in a 2560x1440 display (with a MATE titlebar, and
"   3 rows of mate-panel):
"     :echo &columns → 365 / :echo &lines → 89 / `wmctrl -lG | grep vim` → 2560x1345
"   It follows:
"     2560/365 → 7.014 pixels/column / 1440/89 → 16.180 pixels/line
" - SAVVY/2024-12-16: These same values work well for the author
"   in macOS on the same monitor, with hidden menubar and hidden Dock.
"
" USAGE: User can Override with, e.g.:
"   let g:fstoggle_pixels_per_col = 7.014
"   let g:fstoggle_pixels_per_row = 16.180
let s:pixels_per_col = 7.014
let s:pixels_per_row = 16.180

let s:resize_pending = 0

" DEVEL: Enable this for trace.
let s:trace = 0
let s:info = 0
"  let s:trace = 1
"  let s:info = 1
"
" Enable this while debugging to clear messages when you source this file.
"  messages clear

function! g:embrace#resize#ToggleResizeWindow(sticky_x, new_state = '') abort
  if a:new_state != ''
    let s:state_toggle = a:new_state
  endif

  " If user tries toggling too fast, s:prev_dim won't be caught up.
  if s:resize_pending
    echom 'fullscreen-toggle: too fast!'

    return
  endif

  let s:resize_pending = 1

  let l:curr_dim = s:GetCurrDimensions()

  let l:user_old = s:user_dim
  let l:state_old = s:state_toggle

  " Check if user moved the window. (Note there's a VimResized event,
  " but no event for window moved, hence this state check.)
  if s:state_toggle == s:st_init
      \ || !s:DimensionsEqual(s:prev_dim, l:curr_dim, 'prev', 'curr')
    if s:trace == 1
      echom 'RESET: '
        \ .. s:DimensionsAsString(s:prev_dim, 'prev') .. ' / '
        \ .. s:DimensionsAsString(l:curr_dim, 'curr')
    endif

    if s:state_toggle != s:st_init
      let s:user_dim = l:curr_dim
    endif

    let s:state_toggle = s:st_mostly_fs
  endif

  if s:trace == 1 || s:info == 1
    echom 'STATE: ' .. s:state_toggle
      \ .. ' (was: ' .. l:state_old .. ')'
      \ .. ' / ' .. 'sticky_x: ' .. a:sticky_x
      \ .. ' / ' .. s:DimensionsAsString(s:prev_dim, 'prev')
      \ .. ' / ' .. s:DimensionsAsString(l:curr_dim, 'curr')
      \ .. ' / ' .. s:DimensionsAsString(s:user_dim, 'user')
      \ .. ' / ' .. s:DimensionsAsString(l:user_old, 'uold')
  endif

  " ***

  " Check if next state restores user dimensions, unless those dimensions
  " match either the fullscreen or mostly fullscreen dimensions.
  if (s:state_toggle == s:st_user_dims)
    if (s:user_dim[s:dim_vim_x] > 0) && (s:user_dim[s:dim_vim_y] > 0)
        \ && !s:DimensionsEqual(s:user_dim, s:most_dim, 'user', 'most')
        \ && !s:DimensionsEqual(s:user_dim, s:full_dim, 'user', 'full')
      if s:trace == 1 | echom 'apply USER dim' | endif

      exec 'set columns=' .. s:user_dim[s:dim_vim_x] .. ' lines=' .. s:user_dim[s:dim_vim_y]
      exec 'winpos ' .. s:user_dim[s:dim_win_x] .. ' ' .. s:user_dim[s:dim_win_y]
    else
      " No user window size.
      if s:trace == 1 | echom 'no user dim' | endif

      let s:state_toggle = s:st_mostly_fs
    endif
  endif

  " ***

  if (s:state_toggle != s:st_user_dims)
    if s:state_toggle == s:st_fullscreen
      " Set Totally Fullscreen vars
      let l:partial_w = 1
      let l:partial_h = 1
    else
      " Set Mostly Fullscreen vars
      if exists('g:fstoggle_partial_w')
        let l:partial_w = g:fstoggle_partial_w
      else
        let l:partial_w = s:partial_w
      endif

      if exists('g:fstoggle_partial_h')
        let l:partial_h = g:fstoggle_partial_h
      else
        let l:partial_h = s:partial_h
      endif
    endif

    " ***

    let l:use_secondary = 0
    if exists('g:fstoggle_use_secondary_display')
      let l:use_secondary = g:fstoggle_use_secondary_display
    endif

    let l:dimensions = s:DisplayOffsetAndResolution(l:use_secondary)
    let [l:xoff, l:yoff, l:size_w, l:size_h] = l:dimensions

    if a:sticky_x == 1
      let l:partial_w = 0.5
      let l:xoff = str2nr(l:xoff + (l:size_w / 2))
    endif

    if exists('g:fstoggle_pixels_per_col')
      let l:pixels_per_col = g:fstoggle_pixels_per_col
    else
      let l:pixels_per_col = s:pixels_per_col
    endif

    if exists('g:fstoggle_pixels_per_row')
      let l:pixels_per_row = g:fstoggle_pixels_per_row
    else
      let l:pixels_per_row = s:pixels_per_row
    endif

    let l:xoff = str2nr(l:xoff + ((l:size_w * (1 - l:partial_w)) / 2))
    let l:yoff = str2nr(l:yoff + ((l:size_h * (1 - l:partial_h)) / 2))

    let l:vim_x = str2nr(l:partial_w * l:size_w / l:pixels_per_col)
    let l:vim_y = str2nr(l:partial_h * l:size_h / l:pixels_per_row)

    if s:trace == 1
      echom 'resiz: xoff: (' .. l:xoff .. ', ' .. l:yoff .. ') / '
        \ .. 'size: (' .. l:size_w .. ' x ' .. l:size_h .. ') // '
        \ .. 'new sz: (' .. l:vim_x .. ' x ' .. l:vim_y .. ') // '
        \ .. 'state_toggle: ' .. s:state_toggle .. ' / '
        \ .. 'sticky_x: ' .. a:sticky_x
    endif

    execute 'set columns=' .. l:vim_x .. ' lines=' .. l:vim_y
    execute 'winpos ' .. l:xoff .. ' ' .. l:yoff
  endif

  " ***

  call s:ResizeVerticalWindows()

  " Vim might still be resizing. Be patient.
  " - See comment above VimResized, below, for more.

  " Just FYI when tracing, shows that dims. not immed. updated.
  if s:trace == 1
    echom 'AFTER: ' .. s:DimensionsAsString(s:GetCurrDimensions(), 'curr')
  endif

  let timer_id = timer_start(g:fullscreen_toggle_timeout, "EmbraceResizeSavePrevDimensions")
endfunction

" ***

function! EmbraceResizeSavePrevDimensions(timer_id = 0) abort
  let s:prev_dim = s:GetCurrDimensions()

  call s:CaptureState()

  call s:StepState()

  let s:resize_pending = 0

  if s:trace == 1
    echom 'TIMER: next state: ' .. s:state_toggle
      \ .. ' / ' .. s:DimensionsAsString(s:prev_dim, 'prev')
  endif
endfunction

function! s:CaptureState() abort
  if (s:state_toggle == s:st_user_dims)
    " Should be the same:
    "   let s:user_dim = s:prev_dim
  elseif (s:state_toggle == s:st_mostly_fs)
    let s:most_dim = s:prev_dim
  elseif (s:state_toggle == s:st_fullscreen)
    let s:full_dim = s:prev_dim
  endif
endfunction

function! s:StepState() abort
  if (s:state_toggle == s:st_user_dims)
    let s:state_toggle = s:st_mostly_fs
  elseif (s:state_toggle == s:st_mostly_fs)
    let s:state_toggle = s:st_fullscreen
  elseif (s:state_toggle == s:st_fullscreen)
    let s:state_toggle = s:st_user_dims
  endif
endfunction

" ***

let s:dim_win_x = 0
let s:dim_win_y = 1
let s:dim_vim_x = 2
let s:dim_vim_y = 3

function! s:GetCurrDimensions() abort
  let l:win_x = getwinposx()
  let l:win_y = getwinposy()
  let l:vim_x = &columns
  let l:vim_y = &lines

  return [l:win_x, l:win_y, l:vim_x, l:vim_y]
endfunction

function! s:ResetDimensions() abort
  let l:win_x = 0
  let l:win_y = 0
  let l:vim_x = 0
  let l:vim_y = 0

  return [l:win_x, l:win_y, l:vim_x, l:vim_y]
endfunction

function! s:DimensionsEqual(lhs_dim, rhs_dim, lhs_name = '', rhs_name = '') abort
  let l:is_equal = 1
    \ && (a:lhs_dim[s:dim_win_x] == a:rhs_dim[s:dim_win_x])
    \ && (a:lhs_dim[s:dim_win_y] == a:rhs_dim[s:dim_win_y])
    \ && (a:lhs_dim[s:dim_vim_x] == a:rhs_dim[s:dim_vim_x])
    \ && (a:lhs_dim[s:dim_vim_y] == a:rhs_dim[s:dim_vim_y])

  if !l:is_equal
    if s:trace == 1
      echom "dim unequal: " .. a:lhs_name .. " != " .. a:rhs_name
    endif
  endif

  return l:is_equal
endfunction

function! s:DimensionsAsString(dims, name) abort
  return a:name .. '_dim: ('
    \ .. printf('%4d', a:dims[s:dim_win_x]) .. ', '
    \ .. printf('%4d', a:dims[s:dim_win_y]) .. ' | '
    \ .. printf('%4d', a:dims[s:dim_vim_x]) .. ' x '
    \ .. printf('%4d', a:dims[s:dim_vim_y]) .. ')'
endfunction

function! s:ResetTrackingVars() abort
  " For toggling back to user dimensions.
  let s:user_dim = s:ResetDimensions()

  " For tracking when user changes dims.
  let s:prev_dim = s:ResetDimensions()

  " For tracking fullscreen dimensions.
  let s:full_dim = s:ResetDimensions()

  " For tracking mostly-fullscreen dims.
  let s:most_dim = s:ResetDimensions()
endfunction

call s:ResetTrackingVars()

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
  let [l:xoff, l:yoff, l:dw, l:dh] = [0, 0, 1920, 1080]

  let l:system_cmd = s:SussDisplayResolutionCommand(a:use_secondary)

  " Get resolution from xrandr/osascript, and match for the resolution.
  let l:dimensions = system(l:system_cmd)
  if v:shell_error > 0
    echom 'vim-fillscreen-toggle: system call failed: ' .. v:shell_error

    return [l:xoff, l:yoff, l:dw, l:dh]
  endif

  let l:pattern = s:SussDisplayResolutionPattern()

  let l:matches = dimensions->matchlist(l:pattern)
  if len(l:matches) == 0
    echom 'vim-fillscreen-toggle: no matches!?'

    return [l:xoff, l:yoff, l:dw, l:dh]
  endif

  " Split resolution by [width]x[height] and convert each string to a
  " number.
  let [l:match_w, l:match_h, l:match_xoff, l:match_yoff]
    \ = matches[1:4]->map({_, match -> str2nr(match)})

  if l:match_w == 0 || l:match_h == 0
    echom 'vim-fillscreen-toggle: match size 0!?'

    return [l:xoff, l:yoff, l:dw, l:dh]
  endif

  return [l:match_xoff, l:match_yoff, l:match_w, l:match_h]
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

  let l:orig_winnr = winnr()

  let l:proj_winnr = -1
  if exists('g:proj_running')
    let l:proj_winnr = bufwinnr(g:proj_running)
  endif

  " Numbers of windows that view target buffer which we will delete.
  "  \ 'win_screenpos(v:val)[0] == 1 && !<SID>IsWindowSpecial(v:val)')
  let wnums = filter(range(1, winnr('$')),
    \ 'win_screenpos(v:val)[0] == 1 && (v:val != ' .. l:proj_winnr ..')')

  let l:wcols = copy(wnums)->map({_, wnum -> winwidth(wnum)})

  let l:total_cols = s:Reduce(function('s:ReducerAdd'), l:wcols)

  let l:equal_cols = str2nr(l:total_cols / len(l:wnums))

  for l:wnum in wnums
    execute l:wnum .. 'wincmd w | vertical resize ' .. l:equal_cols
  endfor

  " Move cursor back to starting window.
  execute l:orig_winnr . 'wincmd w'
endfunction

function! s:ReducerAdd(acc, head) abort
  return a:acc + a:head
endfunction

" ***

" COPYD/2024-03-04: https://stackoverflow.com/a/18812122
function! s:Reduce(fcn, list) abort
  let [l:acc; l:tail] = a:list

  while !empty(l:tail)
    let [l:head; l:tail] = tail
    let l:acc = a:fcn(l:acc, l:head)
  endwhile

  return l:acc
endfunction

" +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ "

" Call on startup if you always want the same initial dimensions.
"
" - Accepts timer_id (or whatever...; ignored) because you'll want
"   to schedule callback with timer_start while window dims settle.

function! g:embrace#resize#ResetWindowMostlyFullscreen(...) abort
  " Sticky-X is used to resize to one-half of the display.
  let l:sticky_x = 0

  " Specify reset to clear state and resize *mostly fullscreen*.
  let l:new_state = s:st_init

  call g:embrace#resize#ToggleResizeWindow(l:sticky_x, l:new_state)
endfunction

