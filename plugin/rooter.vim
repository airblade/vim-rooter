" Vim plugin to change the working directory to the project root.
"
" The project root is identified by the presence of a directory,
" such as a VCS directory, or a file, such as a Rakefile.  See
" the Options section below for how to configure this.
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
"   g:rooter_patterns
"
"   This is an array of directories and files to look for.
"   By default it is an array of common VCS directories.
"   You can set your own patterns with something like:
"
"     let g:rooter_patterns = ['Rakefile', '.git/']
"
"   Note this overwrites the default patterns.
"
"
"   g:rooter_user_lcd
"
"   This tells Vim to use `lcd` instead of `cd` (the default)
"   when changing directory.  Set it like this:
"
"     let g:rooter_use_lcd = 1
"
"
"   g:rooter_manual_only
"
"   Set this to stop vim-rooter changing directory automatically:
"
"     let g:rooter_manual_only = 1


"
" Boilerplate
"

if exists("g:loaded_rooter")
  finish
else
  let g:loaded_rooter = 1
endif

let s:save_cpo = &cpo
set cpo&vim


"
" User configuration
"
"
if !exists("g:rooter_use_lcd")
  let g:rooter_use_lcd = 0
endif

if !exists('g:rooter_patterns')
  let g:rooter_patterns = ['.git/', '.git', '_darcs/', '.hg/', '.bzr/', '.svn/']
endif

"
" Functions
"

" Find the root directory of the current file, i.e the closest parent directory
" containing a <pattern> directory, or an empty string if no such directory
" is found.
function! s:FindInCurrentPath(pattern)
  " Don't try to change directories when on a virtual filesystem (netrw, fugitive,...).
  if match(expand('%:p'), '^\w\+://.*') != -1
    return ""
  endif

  let dir_current_file = fnameescape(expand("%:p:h"))
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
  for pattern in g:rooter_patterns
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
      exe ":lcd " . fnameescape(root_dir)
    else
      exe ":cd " . fnameescape(root_dir)
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
if !exists("g:rooter_manual_only")
  augroup rooter
    autocmd!
    autocmd BufEnter *.rb,*.py,
          \*.html,*.haml,*.erb,
          \*.css,*.scss,*.sass,*.less,
          \*.js,*.rjs,*.coffee,
          \*.php,*.xml,*.yaml,
          \*.markdown,*.md
          \ :Rooter
  augroup END
endif

"
" Boilerplate
"

let &cpo = s:save_cpo

" vim:set ft=vim sw=2 sts=2 et:
