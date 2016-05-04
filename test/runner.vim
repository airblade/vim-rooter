"
" Adapted from https://github.com/vim/vim/blob/master/src/testdir/runtest.vim
"
" When debugging tests it can help to add messages to v:errors:
"    call add(v:errors, 'oh noes')
"

function RunTest(test)
  echo 'Executing '.a:test
  if exists("*SetUp")
    call SetUp()
  endif

  call add(s:messages, 'Executing '.a:test)
  let s:done += 1
  try
    execute 'call '.a:test
  catch
    call add(v:errors, 'Caught exception in '.a:test.': '.v:exception.' @ '.v:throwpoint)
  endtry

  if exists("*TearDown")
    call TearDown()
  endif
endfunction

let g:testname = expand('%')
let s:done = 0
let s:fail = 0
let s:errors = []
let s:messages = []

" Source the test script.
try
  source %
catch
  let s:fail += 1
  call add(s:errors, 'Caught exception: '.v:exception.' @ '.v:throwpoint)
endtry

" Locate the test functions.
set nomore
redir @q
silent function /^Test_
redir END
let s:tests = split(substitute(@q, 'function \(\k*()\)', '\1', 'g'))

" If there is another argument, filter test-functions' names against it.
if argc() > 1
  let s:tests = filter(s:tests, 'v:val =~ argv(1)')
endif

" Run the tests.
" TODO: randomise the order of tests.
for s:test in s:tests
  call RunTest(s:test)

  if len(v:errors) > 0
    let s:fail += 1
    call add(s:errors, 'Found errors in '.s:test.':')
    call extend(s:errors, v:errors)
    let v:errors = []
  endif
endfor

if len(s:errors) > 0
  " Append errors to test.log
  split test.log
  call append(line('$'), '')
  call append(line('$'), 'From '.g:testname.':')
  call append(line('$'), s:errors)
  write
endif

let message = 'Executed '.s:done.(s:done > 1 ? ' tests' : ' test')
echo message
call add(s:messages, message)
if s:fail > 0
  let message = s:fail.' FAILED:'
  echo message
  call add(s:messages, message)
  call extend(s:messages, s:errors)
endif

split messages.log
call append(line('$'), '')
call append(line('$'), 'From ' . g:testname . ':')
call append(line('$'), s:messages)
write

qall!

