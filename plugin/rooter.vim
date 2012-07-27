" Vim plugin to change the working directory to the project root
" (identified by the presence of a known SCM tool directory).
"
" Copyright 2010 Andrew Stewart, <boss@airbladesoftware.com>
" Released under the MIT licence.
"
" This will happen automatically for typical Ruby webapp files.
" If you don't want it to happen automatically, create the file
" `.vim/after/plugin/vim-rooter.vim` with the single command:
"
"     autocmd! rooter
"
" You can invoke it manually with <Leader>cd (usually \cd).
" To change the mapping, put this in your .vimrc:
"
"     map <silent> <unique> <Leader>foo <Plug>RooterChangeToRootDirectory
"
" ... where <Leader>foo is your preferred mapping.
"
" Options:
"   let g:rooter_use_lcd = 1
"     Use :lcd instead of :cd
"


"
" Boilerplate
"

if exists("loaded_rooter")
  finish
endif
let loaded_rooter = 1

let s:save_cpo = &cpo
set cpo&vim


"
" User configuration
"
"
if !exists("g:rooter_use_lcd")
  let g:rooter_use_lcd = 0
endif

if (!exists('g:rooter_patterns'))
  let g:rooter_patterns = []
endif

"
" Functions
"

" Find the root directory of the current file, i.e the closest parent directory
" containing a <pattern> directory, or an empty string if no such directory
" is found.
function! s:FindInCurrentPath(pattern)
  " Don't try to change directories when on a virtual filesystem (netrw, fugitive,...).
  if match(expand('%:p'), '^\<.\+\>://.*') != -1
    return ""
  endif

  let dir_current_file = expand("%:p:h")
  let pattern_dir = ""

  " Check for directory or a file
  if (stridx(a:pattern, "/")) != -1
    let pattern = substitute(a:pattern, "/", "", "")
    let pattern_dir = finddir(a:pattern, dir_current_file . ";")
  else
    let pattern_dir = findfile(a:pattern, dir_current_file . ";")
  endif

  " If we're at the project root or we can't find one above us
  if pattern_dir == a:pattern || empty(pattern_dir)
    return ""
  else
    return substitute(pattern_dir, a:pattern . "$", "", "")
  endif
endfunction

" Returns the root directory for the current file based on the list of
" known SCM directory names.
function! s:FindRootDirectory()
  " add any future tools here
  let pattern_list = g:rooter_patterns + ['tags', '.git/', '_darcs/', '.hg/', '.bzr/', '.svn/']
  for pattern in pattern_list
    let result = s:FindInCurrentPath(pattern)
    if !empty(result)
      return result
    endif
  endfor
endfunction

" Changes the current working directory to the current file's
" root directory.
function! s:ChangeToRootDirectory()
  let root_dir = s:FindRootDirectory()
  if !empty(root_dir)
    if exists('+autochdir')
      set noautochdir
    endif
    if g:rooter_use_lcd ==# 1
      exe ":lcd " . root_dir
    else
      exe ":cd " . root_dir
    endif
  endif
endfunction

"
" Mappings
"

if !hasmapto("<Plug>RooterChangeToRootDirectory")
  map <silent> <unique> <Leader>cd <Plug>RooterChangeToRootDirectory
endif
noremap <unique> <script> <Plug>RooterChangeToRootDirectory <SID>ChangeToRootDirectory
noremap <SID>ChangeToRootDirectory :call <SID>ChangeToRootDirectory()<CR>

"
" Commands
"

command! Rooter :call <SID>ChangeToRootDirectory()
augroup rooter
  autocmd!
  autocmd BufEnter *.rb,*.html,*.haml,*.erb,*.rjs,*.css,*.js :Rooter
augroup END

"
" Boilerplate
"

let &cpo = s:save_cpo

" vim:set ft=vim sw=2 sts=2 et:
