function SetUp()
  " project/
  "   +-- .git/
  "   +-- foo foo/
  "   |     +-- bar.txt
  "   +-- baz.txt
  "   +-- quux.z
  " zab.txt -> project/baz.txt (symlink)
  let tmpdir = resolve(fnamemodify(tempname(), ':h'))
  let s:project_dir = tmpdir.'/project'
  silent call mkdir(s:project_dir.'/_git', 'p')
  silent call mkdir(s:project_dir.'/foo foo', 'p')
  silent call writefile([], s:project_dir.'/foo foo/bar.txt')
  silent call writefile([], s:project_dir.'/baz.txt')
  silent call writefile([], s:project_dir.'/quux.z')

  let s:symlink = tmpdir.'/zab.txt'
  silent call system("ln -nfs ".s:project_dir.'/baz.txt '.s:symlink)

  let s:non_project_file = tempname()
  silent call writefile([], s:non_project_file)

  let g:rooter_patterns = ['_git/']  " TODO: also test a file rooter pattern
  let s:cwd = getcwd()
  let s:targets = g:rooter_targets
  let g:rooter_targets = '/,*'

  let s:suffixesadd = &suffixesadd
endfunction

function TearDown()
  silent call delete(s:project_dir, 'rf')
  silent call delete(s:non_project_file)
  silent call delete(s:symlink)
  let g:rooter_targets = s:targets
  let g:rooter_resolve_links = 0
  let &suffixesadd = s:suffixesadd
  execute ':cd' s:cwd
endfunction



function Test_file_in_project()
  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_file_in_project_subdir()
  execute 'edit' s:project_dir.'/foo\ foo/bar.txt'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_ignores_suffixesadd()
  let &suffixesadd = '.txt'
  let g:rooter_patterns = ['bar']
  execute 'edit' s:project_dir.'/foo\ foo/bar.txt'
  execute ':Rooter'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_dir_in_project()
  execute 'edit' s:project_dir.'/foo\ foo'
  " FIXME: test fails without invoking Rooter manually.  I have no idea why.
  execute ':Rooter'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_project_dir()
  execute 'edit' s:project_dir
  " FIXME: test fails without invoking Rooter manually.  I have no idea why.
  execute ':Rooter'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_non_project_file_default()
  let cwd = getcwd()
  execute 'edit' s:non_project_file
  call assert_equal(cwd, getcwd())
endfunction

function Test_non_project_file_change_to_parent()
  let g:rooter_change_directory_for_non_project_files = 'current'
  execute 'edit' s:non_project_file
  call assert_equal(expand('%:p:h'), getcwd())
  let g:rooter_change_directory_for_non_project_files = ''
endfunction

function Test_non_project_file_change_to_home()
  let g:rooter_change_directory_for_non_project_files = 'home'
  execute 'edit' s:non_project_file
  call assert_equal(expand('~'), getcwd())
  let g:rooter_change_directory_for_non_project_files = ''
endfunction

function Test_target_directories_only()
  let cwd = getcwd()
  let g:rooter_targets = '/'

  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(cwd, getcwd())

  execute 'edit' s:project_dir.'/foo\ foo'
  " FIXME: test fails without invoking Rooter manually.  I have no idea why.
  execute ':Rooter'
  call assert_equal(s:project_dir, getcwd())
endfunction

function Test_target_some_files_only()
  let cwd = getcwd()
  let g:rooter_targets = '*.txt'

  execute 'edit' s:project_dir.'/baz.txt'
  call assert_equal(s:project_dir, getcwd())

  execute ':cd' cwd
  execute 'edit' s:project_dir.'/quux.z'
  call assert_equal(cwd, getcwd())
endfunction

function Test_resolve_symlinks()
  let cwd = getcwd()
  call assert_notequal(s:project_dir, cwd)
  execute 'edit' s:symlink
  call assert_equal(cwd, getcwd())

  let g:rooter_resolve_links = 1
  execute ':Rooter'
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

  autocmd! User RooterChDir
endfunction

function Test_write_file_to_different_name()
  execute 'edit' s:non_project_file
  let cwd = getcwd()

  let new_name = s:project_dir.'/other.txt'
  silent execute 'saveas' new_name

  call assert_notequal(cwd, getcwd())
endfunction

function Test_write_new_file()
  execute 'edit' s:project_dir.'/baz.txt'
  let cwd = getcwd()

  enew
  let g:rooter_change_directory_for_non_project_files = 'current'
  silent execute 'write' tempname()

  call assert_notequal(cwd, getcwd())
endfunction

function Test_directory_is_ancestor()
  let g:rooter_patterns = ['foo foo/']
  execute 'edit' s:project_dir.'/foo\ foo/bar.txt'

  execute ':Rooter'
  call assert_equal(s:project_dir.'/foo foo', getcwd())
endfunction

