"
" Adapted from https://github.com/vim/vim/blob/master/src/testdir/runtest.vim
"
" When debugging tests it can help to add messages to v:errors:
"    call add(v:errors, 'oh noes')
"

function RunTest(test)
  if exists("*SetUp")
    call SetUp()
  endif

  try
    execute 'call '.a:test
  catch
    call add(v:errors, 'Caught exception: '.v:exception.' @ '.v:throwpoint)
  endtry

  if exists("*TearDown")
    call TearDown()
  endif
endfunction

function Log(msg)
  call add(s:messages, a:msg)
endfunction

let g:testname = expand('%')
let s:done = 0
let s:fail = 0
let s:messages = []

call Log(g:testname.':')

" Source the test script.
try
  source %
catch
  " TODO distinguish errors and failures
  let s:fail += 1
  call Log('Caught exception: '.v:exception.' @ '.v:throwpoint)
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
for test in s:tests
  call RunTest(test)
  let s:done += 1

  let friendly_name = substitute(test[5:-3], '_', ' ', 'g')
  if len(v:errors) == 0
    call Log('ok     - '.friendly_name)
  else
    let s:fail += 1
    call Log('not ok - '.friendly_name)
    call Log(join(map(v:errors, '"# ".v:val'), "\n"))
    let v:errors = []
  endif
endfor

let summary = [
      \ s:done.(s:done == 1 ? ' test'    : ' tests'),
      \ s:fail.(s:fail == 1 ? ' failure' : ' failures'),
      \ ]
call Log('')
call Log(join(summary, ', '))

split messages.log
call append(line('$'), s:messages)
write

qall!

