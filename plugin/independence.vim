""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" independence.vim
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"
" Authors:      Andy Dawson <andydawson76 AT gmail DOT com>
" Version:      0.2.0
" Licence:      http://www.opensource.org/licenses/mit-license.php
"               The MIT License
" URL:          http://github.com/AD7six/vim-independence
"
"-----------------------------------------------------------------------------
"
" Section: Documentation
"
" The vim independence plugin loads a .vimrc file from your git project root
" if it exists
"
" This allows you to override your vim settings on a project by project basis

" Section: Plugin header
"
" loaded_independence is set to 1 when initialization begins, and 2 when it
" completes.

if exists('g:loaded_independence')
    finish
endif
let g:loaded_independence=1

" Section: Event group setup
augroup Independence
    autocmd VimEnter,BufNewFile,BufRead * call s:LoadConfig()
augroup END

" Section: Script variables

" Currently none

" Section: Utility functions
" These functions are not/should not be directly accessible

" Function: LoadConfig()
let s:loaded_configs = {}

" If the file .vimrc exists in the root of a git project - load it
function s:LoadConfig()
    let l:query  = expand('%:p:h')

    if &ft ==? 'help'
        return
    endif

    if executable('git')
        let l:roots = systemlist('git -C ' . shellescape(l:query) . ' rev-parse --show-toplevel --git-dir 2>/dev/null')
    endif

    " roots[] is either empty, or [ '/git/worktree/', '/git/git-dir/.git' ]
    let l:toload = []

    if ! exists('l:roots[0]')
        if g:vim_independence_load_vimrc != 0
            call add(l:toload, l:query . '/.vimrc')
        endif
    else
        " Start with working tree
        let l:root = l:roots[0]

        if g:vim_independence_load_parent_vimrc != 0
            " Find all of the .vimrc files from bottom-up
            call add(l:toload, l:query . '/.vimrc')
            while l:query != l:root
                let l:query = fnamemodify(l:query,':h')
                call add(l:toload, l:query . '/.vimrc')
            endwhile
        else
            " Load the vimrc local to the root of the repository
            if g:vim_independence_load_root_vimrc != 0
                call add(l:toload, l:root . '/.vimrc')
            endif
            " Load the vimrc local to the edited file.
            if g:vim_independence_load_vimrc != 0
                call add(l:toload, l:query . '/.vimrc')
            endif
        endif

        " Follow up with git-dir/info/vimrc
        let l:root = fnamemodify(l:roots[1],':p')

        if g:vim_independence_load_git_vimrc != 0
            call add(l:toload, l:root.'info/.vimrc')
            call add(l:toload, l:root.'info/vimrc')
        endif
    endif

    if g:vim_independence_sandbox == 0
        let l:sandbox = ''
    else
        let l:sandbox = 'sandbox '
    endif

    " Load all the .vimrc files from top-down
    for l:vimrc in reverse(l:toload)
        if !has_key(s:loaded_configs,l:vimrc)
            let s:loaded_configs[l:vimrc] = 1
            if filereadable(l:vimrc)
                exec ':' . l:sandbox . 'source ' . l:vimrc
            endif
        endif
    endfor
endfunction

" Globals which can be customised

" Enable sandboxing by default
if !exists( 'g:vim_independence_sandbox' )
    let g:vim_independence_sandbox = 1
endif

" Enable loading vimrc from git-dir/info
if !exists( 'g:vim_independence_load_git_vimrc' )
    let g:vim_independence_load_git_vimrc = 1
endif

" Enable loading vimrc from the root of the git working tree
if !exists( 'g:vim_independence_load_root_vimrc' )
    let g:vim_independence_load_vimrc = 1
endif

" Enable loading vimrc from the directory of the file being edited
if !exists( 'g:vim_independence_load_vimrc' )
    let g:vim_independence_load_vimrc = 1
endif

" Enable loading all intermediate vimrc files between the file path
" and the root of the git repository working tree.
if !exists( 'g:vim_independence_load_parent_vimrc' )
    let g:vim_independence_load_parent_vimrc = 1
endif

" Section: Plugin completion
let g:loaded_independence=2
