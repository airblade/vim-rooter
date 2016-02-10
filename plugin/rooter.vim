" Vim plugin to change the working directory to the project root.
"
" Copyright 2010-2014 Andrew Stewart, <boss@airbladesoftware.com>
" Released under the MIT licence.

if exists('g:loaded_rooter') || &cp
  finish
endif
let g:loaded_rooter = 1

" Turn off autochdir.  If you're using this plugin then you don't want it.
if exists('+autochdir') && &autochdir
  set noautochdir
endif

" User configuration {{{

if !exists('g:rooter_use_lcd')
  let g:rooter_use_lcd = 0
endif

if !exists('g:rooter_patterns')
  let g:rooter_patterns = ['.git', '.git/', '_darcs/', '.hg/', '.bzr/', '.svn/']
endif

if !exists('g:rooter_autocmd_patterns')
  let g:rooter_autocmd_patterns = '*'
endif

if !exists('g:rooter_change_directory_for_non_project_files')
  let g:rooter_change_directory_for_non_project_files = 0
endif

if !exists('g:rooter_silent_chdir')
  let g:rooter_silent_chdir = 0
endif

if !exists('g:rooter_resolve_links')
  let g:rooter_resolve_links = 0
endif

" }}}

" Utility {{{

function! s:IsVirtualFileSystem()
  return match(expand('%:p'), '^\w\+:[\/][\/].*') != -1
endfunction

function! s:IsNormalFile()
  return empty(&buftype)
endfunction

function! s:ChangeDirectory(directory)
  if a:directory !=# getcwd()
    let cmd = g:rooter_use_lcd == 1 ? 'lcd' : 'cd'
    let dir = fnameescape(a:directory)
    execute ':' . cmd . ' ' . dir
    if !g:rooter_silent_chdir
      echo dir
    endif
  endif
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
  let current_file = expand('%:p')
  if g:rooter_resolve_links
    let current_file = resolve(current_file)
  endif
  let dir_current_file = fnameescape(fnamemodify(current_file, ':h'))

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

function! s:InspectFileSystemForRootDirectory()
  for pattern in g:rooter_patterns
    let result = s:FindInCurrentPath(pattern)
    if !empty(result)
      return result
    endif
  endfor
  return ''
endfunction

" Returns the root directory for the current file based on the list of known SCM patterns.
function! FindRootDirectory()
  let root_dir = getbufvar('%', 'rootDir')
  if empty(root_dir)
    let root_dir = s:InspectFileSystemForRootDirectory()
    if !empty(root_dir)
      call setbufvar('%', 'rootDir', root_dir)
    endif
  endif
  return root_dir
endfunction

" Changes the current working directory to the current file's
" root directory.
function! s:ChangeToRootDirectory()
  if s:IsVirtualFileSystem() || !s:IsNormalFile()
    return
  endif

  let root_dir = FindRootDirectory()

  if empty(root_dir)
    if g:rooter_change_directory_for_non_project_files
      call s:ChangeDirectory(expand('%:p:h'))
    endif
  else
    call s:ChangeDirectory(root_dir)
  endif
endfunction

" }}}

" Mappings and commands {{{

if !get(g:, 'rooter_disable_map', 0) && !hasmapto('<Plug>RooterChangeToRootDirectory')
  map <silent> <unique> <Leader>cd <Plug>RooterChangeToRootDirectory
  sunmap <silent> <unique> <Leader>cd
endif
noremap <unique> <script> <Plug>RooterChangeToRootDirectory <SID>ChangeToRootDirectory
noremap <SID>ChangeToRootDirectory :call <SID>ChangeToRootDirectory()<CR>

command! Rooter :call <SID>ChangeToRootDirectory()
if !exists('g:rooter_manual_only')
  augroup rooter
    autocmd!
    exe 'autocmd BufEnter ' . g:rooter_autocmd_patterns . ' :Rooter'
  augroup END
endif

" }}}

" vim:set ft=vim sw=2 sts=2  fdm=marker et:
