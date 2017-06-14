" Copyright 2017 Google Inc. All rights reserved.
"
" Licensed under the Apache License, Version 2.0 (the "License");
" you may not use this file except in compliance with the License.
" You may obtain a copy of the License at
"
"     http://www.apache.org/licenses/LICENSE-2.0
"
" Unless required by applicable law or agreed to in writing, software
" distributed under the License is distributed on an "AS IS" BASIS,
" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
" See the License for the specific language governing permissions and
" limitations under the License.


let s:plugin = maktaba#plugin#Get('codefmt')
let s:registry = s:plugin.GetExtensionRegistry()

call s:plugin.Flag('fecs_executable', 'fecs')

""
" @private
" Formatter: js-beautify
function! fecsfmt#GetFormatter() abort
  let l:formatter = {
      \ 'name': 'fecs',
      \ 'setup_instructions': 'Install fecs ' .
          \ '(https://www.npmjs.com/package/fecs).'}

  function l:formatter.IsAvailable() abort
    return executable(s:plugin.Flag('fecs_executable'))
  endfunction

  function l:formatter.AppliesToBuffer() abort
    return &filetype is# 'css' || &filetype is# 'html' || &filetype is# 'json' ||
        \ &filetype is# 'javascript'
  endfunction

  ""
  " Reformat the current buffer with js-beautify or the binary named in
  " @flag(js_beautify_executable), only targeting the range between {startline} and
  " {endline}.
  " @throws ShellError
  function l:formatter.FormatRange(startline, endline) abort
    let l:cmd = [s:plugin.Flag('fecs_executable'), 'format', '--stream=true', '--type=js']
    " if &filetype != ""
    "   let l:cmd = l:cmd + ['--type', &filetype]
    " endif

    call maktaba#ensure#IsNumber(a:startline)
    call maktaba#ensure#IsNumber(a:endline)

    let l:lines = getline(1, line('$'))
    " Hack range formatting by formatting range individually, ignoring context.
    let l:input = join(l:lines[a:startline - 1 : a:endline - 1], "\n")

    let l:result = maktaba#syscall#Create(l:cmd).WithStdin(l:input).Call()
    let l:formatted = split(l:result.stdout, "\n")
    " Special case empty slice: neither l:lines[:0] nor l:lines[:-1] is right.
    let l:before = a:startline > 1 ? l:lines[ : a:startline - 2] : []
    let l:full_formatted = l:before + l:formatted + l:lines[a:endline :]

    call maktaba#buffer#Overwrite(1, line('$'), l:full_formatted)
  endfunction

  return l:formatter
endfunction

call s:registry.AddExtension(fecsfmt#GetFormatter())
