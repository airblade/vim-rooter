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
" CONFIGURATION
"
"   g:rooter_patterns
"
"     This is an array of directories and files to look for.
"     By default it is an array of common VCS directories.
"     You can set your own patterns with something like:
"
"       let g:rooter_patterns = ['Rakefile', '.git/']
"
"     Note this overwrites the default patterns.
"
"
"   g:rooter_user_lcd
"
"     This tells Vim to use `lcd` instead of `cd` (the default)
"     when changing directory.  Set it like this:
"
"       let g:rooter_use_lcd = 1
"
"
"   g:rooter_manual_only
"
"     Set this to stop vim-rooter changing directory automatically:
"
"       let g:rooter_manual_only = 1
"
"
"   g:rooter_change_directory_for_non_project_files
"
"     Set this to change to a non-project file's directory.
"     Defaults to off.


if exists('g:loaded_rooter') || &cp
  finish
endif
let g:loaded_rooter = 1

" User configuration {{{

if !exists('g:rooter_use_lcd')
  let g:rooter_use_lcd = 0
endif

if !exists('g:rooter_patterns')
  let g:rooter_patterns = ['.git', '.git/', '_darcs/', '.hg/', '.bzr/', '.svn/']
endif

if !exists('g:rooter_change_directory_for_non_project_files')
  let g:rooter_change_directory_for_non_project_files = 0
endif

" }}}

" Utility {{{

function! s:IsVirtualFileSystem()
  return match(expand('%:p'), '^\w\+://.*') != -1
endfunction

function! s:IsNormalFile()
  return empty(&buftype)
endfunction

function! s:ChangeDirectory(directory)
  let cmd = g:rooter_use_lcd == 1 ? 'lcd' : 'cd'
  execute ':' . cmd . ' ' . fnameescape(a:directory)
endfunction

function! s:IsDirectory(pattern)
  return stridx(a:pattern, '/') != -1
endfunction

" }}}

" Core logic {{{

" Returns the project root directory of the current file, i.e the closest parent
" directory containing the given directory or file, or an empty string if no
" such directory or file is found.
function! s:FindInCurrentPath(pattern)
  let dir_current_file = fnameescape(expand('%:p:h'))

  if s:IsDirectory(a:pattern)
    let match = finddir(a:pattern, dir_current_file . ';')
    if empty(match)
      return ''
    endif
    return fnamemodify(match, ':p:h:h')
  else
    let match = findfile(a:pattern, dir_current_file . ';')
    if empty(match)
      return ''
    endif
    return fnamemodify(match, ':p:h')
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
  return ''
endfunction

" Changes the current working directory to the current file's
" root directory.
function! s:ChangeToRootDirectory()
  if s:IsVirtualFileSystem() || !s:IsNormalFile()
    return
  endif

  let root_dir = s:FindRootDirectory()
  if empty(root_dir)
    if g:rooter_change_directory_for_non_project_files
      call s:ChangeDirectory(expand('%:p:h'))
    endif
  else
    if exists('+autochdir')
      set noautochdir
    endif
    call s:ChangeDirectory(root_dir)
  endif
endfunction

" }}}

" Mappings and commands {{{

if !hasmapto("<Plug>RooterChangeToRootDirectory")
  map <silent> <unique> <Leader>cd <Plug>RooterChangeToRootDirectory
endif
noremap <unique> <script> <Plug>RooterChangeToRootDirectory <SID>ChangeToRootDirectory
noremap <SID>ChangeToRootDirectory :call <SID>ChangeToRootDirectory()<CR>

command! Rooter :call <SID>ChangeToRootDirectory()
if !exists('g:rooter_manual_only')
  augroup rooter
    autocmd!
    autocmd BufEnter *.rb,*.py,
          \*.html,*.haml,*.erb,
          \*.css,*.scss,*.sass,*.less,
          \*.js,*.rjs,*.coffee,
          \*.php,*.xml,*.yaml,*.yml,
          \*.markdown,*.md
          \ :Rooter
  augroup END
endif

" }}}

" vim:set ft=vim sw=2 sts=2  fdm=marker et:
