#####################
Vim Fullscreen Toggle
#####################

About This Plugin
=================

Display-aware Vim fullscreen toggle.

Fullscreen Window Commands
==========================

This plugin is a dual-display-aware version of an old trick::

  set columns=999 lines=999

which will resize a gVim/MacVim window to fill the screen.

But that trick breaks when there's more than one monitor attached.

This plugin restricts the resize to just one monitor.

After resizing, It also adjusts vertical splits to be equal widths.

===========================  ============================  ==============================================================================
 Key Mapping                  Description                   Notes
===========================  ============================  ==============================================================================
 ``<F11>``                    Change gVim/MacVim            Cycles through 3 different window sizes:
                              window dimensions             fullscreen → mostly fullscreen → original size → (repeat).
                                                            If the original size when user first presses ``<F11>``
                                                            is already fullscreen or mostly fullscreen, the plugin
                                                            will only cycle through 2 sizes: fullscreen → mostly fullscreen → (repeat).
---------------------------  ----------------------------  ------------------------------------------------------------------------------
``<Shift-F11>``               Restrict to right-half of     Like ``<F11>``, cycles through 3 different window sizes,
                              display                       but sets window width and position to right-half of display.
===========================  ============================  ==============================================================================

Override
========

By default, this plugin will define both ``<F11>`` and ``<S-F11>`` maps,
and it'll run on startup (to set window dimensions to mostly fullscreen).

If you'd like to define your own maps and to call resize on your own time,
you can inhibit the default behavior by setting a global variable::

  let g:vim_fullscreen_toggle_disable = 1

Installation
============

.. |help-packages| replace:: ``:h packages``
.. _help-packages: https://vimhelp.org/repeat.txt.html#packages

.. |INSTALL.md| replace:: ``INSTALL.md``
.. _INSTALL.md: INSTALL.md

Take advantage of Vim's packages feature (|help-packages|_)
and install under ``~/.vim/pack``, e.g.,:

.. code-block::

  mkdir -p ~/.vim/pack/embrace-vim/start
  cd ~/.vim/pack/embrace-vim/start
  git clone https://github.com/embrace-vim/vim-fullscreen-toggle.git

  " Build help tags
  vim -u NONE -c "helptags vim-fullscreen-toggle/doc" -c q

- Alternatively, install under ``~/.vim/pack/embrace-vim/opt`` and call
  ``:packadd vim-fullscreen-toggle`` to load the plugin on-demand.

For more installation tips — including how to easily keep the
plugin up-to-date — please see |INSTALL.md|_.

Attribution
===========

.. |embrace-vim| replace:: ``embrace-vim``
.. _ORG_NAME: https://github.com/embrace-vim

.. |@landonb| replace:: ``@landonb``
.. _@landonb: https://github.com/landonb

The |embrace-vim|_ logo by |@landonb|_ contains
`coffee cup with straw by farra nugraha from Noun Project
<https://thenounproject.com/icon/coffee-cup-with-straw-6961731/>`__
(CC BY 3.0).

