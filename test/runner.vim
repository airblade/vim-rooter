"
" Adapted from https://github.com/vim/vim/blob/master/src/testdir/runtest.vim
"
" When debugging tests it can help to write debug output:
"    call Debug('oh noes')
"

function RunTest(test)
  if exists("*SetUp")
    call SetUp()
  endif

  try
    execute 'call '.a:test
  catch
    call add(v:errors, 'Exception: '.v:exception.' @ '.v:throwpoint)
    let s:errored = 1
  endtry

  if exists("*TearDown")
    call TearDown()
  endif
endfunction

function Log(msg)
  call add(s:messages, a:msg)
endfunction

function Debug(msg)
  call add(v:errors, a:msg)
endfunction

" Shuffles list in place.
function Shuffle(list)
  " Fisher-Yates-Durstenfeld-Knuth
  let n = len(a:list)
  for i in range(0, n-2)
    let j = Random(0, n-i-1)
    let e = a:list[i]
    let a:list[i] = a:list[i+j]
    let a:list[i+j] = e
  endfor
  return a:list
endfunction

" Returns a pseudorandom integer i such that 0 <= i <= max
function Random(min, max)
  if has('unix')
    let i = system('echo $RANDOM')  " 0 <= i <= 32767
  else
    let i = system('echo %RANDOM%')  " 0 <= i <= 32767
  endif
  return i * (a:max - a:min + 1) / 32768 + a:min
endfunction

let g:testname = expand('%')
let s:errored = 0
let s:done = 0
let s:fail = 0
let s:errors = 0
let s:messages = []

call Log(g:testname.':')

" Source the test script.
try
  source %
catch
  let s:errors += 1
  call Log('Exception: '.v:exception.' @ '.v:throwpoint)
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

" Run the tests in random order.
for test in Shuffle(s:tests)
  call RunTest(test)
  let s:done += 1

  let friendly_name = substitute(test[5:-3], '_', ' ', 'g')
  if len(v:errors) == 0
    call Log('ok     - '.friendly_name)
  else
    if s:errored
      let s:errors += 1
      let s:errored = 0
    else
      let s:fail += 1
    endif
    call Log('not ok - '.friendly_name)
    call Log(join(map(v:errors, '"       # ".v:val'), "\n"))
    let v:errors = []
  endif
endfor

let summary = [
      \ s:done.(  s:done   == 1 ? ' test'    : ' tests'),
      \ s:errors.(s:errors == 1 ? ' error'   : ' errors'),
      \ s:fail.(  s:fail   == 1 ? ' failure' : ' failures'),
      \ ]
call Log('')
call Log(join(summary, ', '))

split messages.log
call append(line('$'), s:messages)
write

qall!

