" Vim plugin to change the working directory to the project root.
"
" Copyright 2010-2020 Andrew Stewart, <boss@airbladesoftware.com>
" Released under the MIT licence.

if exists('g:loaded_rooter') || &cp
  finish
endif
let g:loaded_rooter = 1

let s:nomodeline = (v:version > 703 || (v:version == 703 && has('patch442'))) ? '<nomodeline>' : ''

if exists('+autochdir') && &autochdir && (!exists('g:rooter_manual_only') || !g:rooter_manual_only)
  set noautochdir
endif

if !exists('g:rooter_use_lcd')
  let g:rooter_use_lcd = 0
endif

if !exists('g:rooter_patterns')
  let g:rooter_patterns = ['.git', '_darcs', '.hg', '.bzr', '.svn', 'Makefile']
endif

if !exists('g:rooter_targets')
  let g:rooter_targets = '/,*'
endif

if !exists('g:rooter_change_directory_for_non_project_files')
  let g:rooter_change_directory_for_non_project_files = ''
endif

if !exists('g:rooter_silent_chdir')
  let g:rooter_silent_chdir = 0
endif

if !exists('g:rooter_resolve_links')
  let g:rooter_resolve_links = 0
endif


" For third-parties.  Not used by plugin.
function! FindRootDirectory()
  return s:root()
endfunction


command! -bar Rooter call <SID>rooter()


if !exists('g:rooter_manual_only') || !g:rooter_manual_only
  augroup rooter
    autocmd!
    autocmd VimEnter,BufEnter * nested Rooter
    autocmd BufWritePost * nested call setbufvar('%', 'rootDir', '') | Rooter
  augroup END
endif


function! s:rooter()
  if !s:activate() | return | endif

  let root = getbufvar('%', 'rootDir')
  if empty(root)
    let root = s:root()
    call setbufvar('%', 'rootDir', root)
  endif

  if empty(root)
    call s:rootless()
    return
  endif

  if root != getcwd()
    call s:cd(root)
  endif
endfunction


" Returns true if we should change to the buffer's root directory, false otherwise.
function! s:activate()
  if !empty(&buftype) | return 0 | endif

  let patterns = split(g:rooter_targets, ',')
  let fn = expand('%:p', 1)

  " directory
  if fn[-1:] == '/'
    return index(patterns, '/') != -1
  endif

  " file
  if !filereadable(fn) | return 0 | endif
  if !exists('*glob2regpat') | return 1 | endif

  for p in filter(copy(patterns), 'v:val != "/"')
    if fn =~ glob2regpat(p)
      return 1
    endif
  endfor

  return 0
endfunction


" Returns the root directory or an empty string if no root directory found.
function! s:root()
  let dir = s:current()

  " breadth-first search
  while len(dir) > 1
    for pattern in g:rooter_patterns
      if pattern[0] == '='
        let match = s:is(dir, pattern[1:])
      else
        let match = s:has(dir, pattern)
      endif
      if match | return dir | endif
    endfor

    let dir = s:parent(dir)
  endwhile

  return ''
endfunction


" dir        - full path to a directory
" identifier - a directory name
function! s:is(dir, identifier)
  let identifier = substitute(a:identifier, '/$', '', '')
  return fnamemodify(a:dir, ':t') ==# identifier
endfunction


" dir        - full path to a directory
" identifier - a file name or a directory name; may be a glob
function! s:has(dir, identifier)
  return !empty(globpath(a:dir, a:identifier, 1))
endfunction


" Returns full path of directory of current file name (which may be a directory).
function! s:current()
  let fn = expand('%:p', 1)
  if g:rooter_resolve_links | let fn = resolve(fn) | endif
  let dir = fnamemodify(fn, ':h')
  if empty(dir) | let dir = getcwd() | endif  " opening vim without a file
  return dir
endfunction


" Returns full path of dir's parent directory.
function! s:parent(dir)
  return fnamemodify(a:dir, ':h')
endfunction


function! s:cd(dir)
  let cmd = g:rooter_use_lcd == 1 ? 'lcd' : 'cd'
  execute cmd fnameescape(a:dir)
  if !g:rooter_silent_chdir | echo 'cwd: '.a:dir | endif
  if exists('#User#RooterChDir')
    execute 'doautocmd' s:nomodeline 'User RooterChDir'
  endif
endfunction


function! s:rootless()
  let dir = ''
  if g:rooter_change_directory_for_non_project_files ==? 'current'
    let dir = s:current()
  elseif g:rooter_change_directory_for_non_project_files ==? 'home'
    let dir = $HOME
  endif
  if !empty(dir) | call s:cd(dir) | endif
endfunction


" vim:set ft=vim sw=2 sts=2 et:
