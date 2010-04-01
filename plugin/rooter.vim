" Vim plugin to change the working directory to the project root
" (identified by the presence of a .git directory).
"
" Copyright 2010 Andrew Stewart, <boss@airbladesoftware.com>
" Released under the MIT licence.
"
" You can invoke this manually with <Leader>cd (usually \cd).
" This will happen automatically for typical Ruby webapp files.
"
" Install in ~/.vim/plugin/rooter.vim

if exists("loaded_rooter")
  finish
endif
let loaded_rooter = 1

let s:save_cpo = &cpo
set cpo&vim

"
" Functions
"

" Changes the current working directory to the root of the current file's
" project (if and only if it finds a .git directory).
function! s:ChangeToRootDirectory()
  let dir_current_file = expand("%:p:h")
  let git_dir = finddir(".git", dir_current_file . ";")
  if git_dir != ""
    let root_dir = substitute(git_dir, "/.git$", "", "")
    exe ":cd " . root_dir
  end
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

let &cpo = s:save_cpo

" vim:set ft=vim sw=2 sts=2 et:
