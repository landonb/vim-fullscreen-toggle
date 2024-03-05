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

This plugin restricts the resize to just one monitor, and
it also adjusts vertical splits to be equal widths.

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
--------

To use your own mappings, define ``g:TBVIMCreateDefaultMappings = 0`` to
inhibit the ``<F11>`` and ``<S-F11>`` mappings, and then define your own.

Installation
============

Installation is easy using the packages feature (see ``:help packages``).

To install the package so that it will automatically load on Vim startup,
use a ``start`` directory, e.g.,

.. code-block:: bash

    mkdir -p ~/.vim/pack/landonb/start
    cd ~/.vim/pack/landonb/start

If you want to test the package first, make it optional instead
(see ``:help pack-add``):

.. code-block:: bash

    mkdir -p ~/.vim/pack/landonb/opt
    cd ~/.vim/pack/landonb/opt

Clone the project to the desired path:

.. code-block:: bash

    git clone https://github.com/landonb/vim-fullscreen-toggle.git

If you installed to the optional path, tell Vim to load the package:

.. code-block:: vim

   :packadd! vim-fullscreen-toggle

Just once, tell Vim to build the online help:

.. code-block:: vim

   :Helptags

Then whenever you want to reference the help from Vim, run:

.. code-block:: vim

   :help vim-fullscreen-toggle

