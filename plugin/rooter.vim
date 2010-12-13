" Vim plugin to change the working directory to the project root
" (identified by the presence of a known SCM tool directory).
"
" Copyright 2010 Andrew Stewart, <boss@airbladesoftware.com>
" Released under the MIT licence.
"
" This will happen automatically for typical Ruby webapp files.
"
" You can invoke it manually with <Leader>cd (usually \cd).
" To change the mapping, put this in your .vimrc:
"
"     map <silent> <unique> <Leader>foo <Plug>RooterChangeToRootDirectory
"
" ... where <Leader>foo is your preferred mapping.


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
" Functions
"

" Find the root directory of the current file, i.e the closest parent directory 
" containing a <scm_type> directory, or an empty string if no such directory 
" is found.
function! s:FindSCMDirectory(scm_type)
  let dir_current_file = expand("%:p:h")

  " If we're inside of the scm dir (.git) treat it as a miss
  " This makes vim-rooter play nice with plugins like fugitive
  if match(dir_current_file, a:scm_type)
    return ""
  endif

  let scm_dir = finddir(a:scm_type, dir_current_file . ";")
  " If we're at the project root or we can't find one above us
  if scm_dir == a:scm_type || empty(scm_dir)
    return ""
  else
    return substitute(scm_dir, "/" . a:scm_type . "$", "", "")
  endif
endfunction

" Returns the root directory for the current file based on the list of 
" known SCM directory names.
function! s:FindRootDirectory()
  " add any future tools here
  let scm_list = ['_darcs', '.hg', '.git']
  for scmdir in scm_list
    let result = s:FindSCMDirectory(scmdir)
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
    exe ":cd " . root_dir
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
autocmd BufEnter *.rb,*.html,*.haml,*.erb,*.rjs,*.css,*.js :Rooter

"
" Boilerplate
"

let &cpo = s:save_cpo

" vim:set ft=vim sw=2 sts=2 et:
