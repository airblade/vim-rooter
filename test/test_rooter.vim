function SetUp()
  " project/
  "   +-- _git/
  "   +-- a/
  "   |     +-- b/
  "   |           +- c.txt
  "   +-- foo foo/
  "   |     +-- bar.txt
  "   +-- baz.txt
  "   +-- quux.z
  " zab.txt -> project/baz.txt (symlink)
  " [a-c]/
  "   +-- xyz/
  "         +-- m.txt
  let tmpdir = resolve(fnamemodify(tempname(), ':h'))
  let s:project_dir = tmpdir.'/project'
  silent call mkdir(s:project_dir.'/_git', 'p')
  silent call mkdir(s:project_dir.'/foo foo', 'p')
  silent call writefile([], s:project_dir.'/foo foo/bar.txt')
  silent call mkdir(s:project_dir.'/a/b', 'p')
  silent call writefile([], s:project_dir.'/a/b/c.txt')
  silent call writefile([], s:project_dir.'/baz.txt')
  silent call writefile([], s:project_dir.'/quux.z')
  let s:wildcard_dir = tmpdir.'/[c-a]'
  silent call mkdir(s:wildcard_dir.'/xyz', 'p')
  silent call writefile([], s:wildcard_dir.'/xyz/m.txt')

  let s:symlink = tmpdir.'/zab.txt'
  silent call system("ln -nfs ".s:project_dir.'/baz.txt '.s:symlink)

  let s:non_project_file = tempname().'.txt'
  silent call writefile([], s:non_project_file)

  " Defaults
  let g:rooter_use_lcd = 0
  let g:rooter_patterns = ['_git/']
  let g:rooter_targets = '/,*.txt,*.z'
  let g:rooter_change_directory_for_non_project_files = ''
  let g:rooter_silent_chdir = 0
  let g:rooter_resolve_links = 0

  autocmd! User RooterChDir

  set suffixesadd=

  let s:cwd = getcwd()
endfunction

function TearDown()
  silent call delete(s:project_dir, 'rf')
  silent call delete(s:non_project_file)
  silent call delete(s:symlink)
  call setbufvar('%', 'rootDir', '')
  execute 'cd' s:cwd
endfunction


" NOTE: ideally there would be a test for opening vim without a file
" but since vim is already open when the tests are run, we cannot test it.

function Test_file_in_project()
  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_file_in_project_subdir()
  execute 'edit' s:project_dir.'/foo\ foo/bar.txt'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_ignores_suffixesadd()
  set suffixesadd=.txt
  let g:rooter_patterns = ['bar']
  execute 'edit' s:project_dir.'/foo\ foo/bar.txt'
  call assert_equal(s:cwd, getcwd())
endfunction

function Test_dir_in_project()
  execute 'edit' s:project_dir.'/foo\ foo'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_project_dir()
  execute 'edit' s:project_dir
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_non_project_file_default()
  execute 'edit' s:non_project_file
  call assert_equal(s:cwd, getcwd())
endfunction

function Test_non_project_file_change_to_parent()
  let g:rooter_change_directory_for_non_project_files = 'current'
  execute 'edit' s:non_project_file
  call assert_equal(expand('%:p:h'), getcwd())
endfunction

function Test_non_project_file_change_to_home()
  let g:rooter_change_directory_for_non_project_files = 'home'
  execute 'edit' s:non_project_file
  call assert_equal(expand('~'), getcwd())
endfunction

function Test_target_directories_only()
  let g:rooter_targets = '/'

  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(s:cwd, getcwd())

  execute 'edit' s:project_dir.'/foo\ foo'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_target_some_files_only()
  let g:rooter_targets = '*.txt'

  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(s:project_dir, getcwd())

  execute 'cd' s:cwd
  execute 'edit' s:project_dir.'/quux.z'
  call assert_equal(s:cwd, getcwd())
endfunction

function Test_resolve_symlinks()
  execute 'edit' s:symlink
  call assert_equal(s:cwd, getcwd())

  let g:rooter_resolve_links = 1
  call setbufvar('%', 'rootDir', '')
  Rooter
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_user_autocmd()
  let g:test_user_autocmd = 0
  autocmd User RooterChDir let g:test_user_autocmd = 1

  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(1, g:test_user_autocmd)

  let g:test_user_autocmd = 0
  execute 'edit' s:project_dir.'/quux.z'
  call assert_equal(0, g:test_user_autocmd)
endfunction

function Test_write_file_to_different_name()
  execute 'edit' s:non_project_file
  call assert_notequal(s:project_dir, getcwd())

  let new_name = s:project_dir.'/other.txt'
  silent execute 'saveas' new_name

  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_write_new_file()
  execute 'edit' s:project_dir.'/baz.txt'

  enew
  let g:rooter_change_directory_for_non_project_files = 'current'
  silent execute 'write' tempname().'.txt'

  call assert_equal(expand('%:p:h'), getcwd())
endfunction

function Test_root_is_directory()
  let g:rooter_patterns = ['=foo foo/']
  execute 'edit' s:project_dir.'/foo\ foo/bar.txt'
  call assert_equal(s:project_dir.'/foo foo', getcwd())
endfunction

function Test_root_has_ancestor()
  let g:rooter_patterns = ['!^project', '*.txt']
  execute 'edit' s:project_dir.'/foo\ foo/bar.txt'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_root_has_parent()
  let g:rooter_patterns = ['>a']
  execute 'edit' s:project_dir.'/a/b/c.txt'
  call assert_equal(s:project_dir.'/a/b', getcwd())
endfunction

function Test_glob()
  let g:rooter_patterns = ['*.z']
  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(s:project_dir, getcwd())

  let g:rooter_patterns = ['**/bar.txt']
  execute 'edit' s:project_dir.'/foo\ foo/bar.txt'
  call assert_equal(s:project_dir.'/foo foo', getcwd())

  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_has_file_in_subdirectory()
  let g:rooter_patterns = ['foo\ foo/bar.txt']
  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_toggle()
  RooterToggle
  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(s:cwd, getcwd())
  RooterToggle
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_exclude()
  let g:rooter_patterns = ['!_git']
  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(s:cwd, getcwd())
endfunction

function Test_root_contains_wildcards()
  let g:rooter_patterns = ['x?z']
  execute 'edit' s:wildcard_dir.'/xyz/m.txt'
  call assert_equal(s:wildcard_dir, getcwd())
endfunction
