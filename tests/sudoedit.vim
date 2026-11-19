" Tests for detecting the file type of temporary files created by sudoedit(8)
"
" sudoedit edits a copy of the file in $TMPDIR whose name is the original name
" with the random part of mkstemps(3) inserted, for example:
"
"   ssh_config.Ab3xY9z1
"   testaB3xY9z1.sh
"
" The file names below use such names so that the detection can be tested
" without actually running sudoedit.  They are arbitrary examples; detection
" must work for every file type, not only for these names.

func! s:DetectTempFile(name, lines)
  call writefile(a:lines, a:name)
  silent execute 'edit ' . fnameescape(a:name)
  let filetype = &filetype
  " A detected file type has to enable syntax highlighting as well.
  let syntax = get(b:, 'current_syntax', '')
  silent bwipe!
  call delete(a:name)
  return [filetype, syntax]
endfunc

func! NewTest_sudoedit_detection()
  filetype plugin indent on
  syntax enable

  let dir = tempname()
  call mkdir(dir, 'p')

  " [temporary name, contents, expected file type]
  let checks = [
        \ ['ssh_config.Ab3xY9z1',
        \  ['Host *', '    ForwardAgent no'],
        \  'sshconfig'],
        \ ['Makefile.Ab3xY9z1',
        \  ['all:', '\t@echo hello'],
        \  'make'],
        \ ['Dockerfile.Ab3xY9z1',
        \  ['FROM scratch'],
        \  'dockerfile'],
        \ ['Ab3xY9z1.gitignore',
        \  ['build/', '*.o'],
        \  'gitignore'],
        \ ['testaB3xY9z1.sh',
        \  [],
        \  'sh'],
        \ ['xrdp.Ab3xY9z1',
        \  ['#!/bin/sh', 'echo hello'],
        \  'sh'],
        \ ['scriptaB3xY9z1.py',
        \  ['import os', 'print(os.getcwd())'],
        \  'python'],
        \ ['mainaB3xY9z1.c',
        \  ['#include <stdio.h>', 'int main(void) { return 0; }'],
        \  'c'],
        \ ['dataaB3xY9z1.json',
        \  ['{"answer": 42}'],
        \  'json'],
        \ ['readmeaB3xY9z1.md',
        \  ['# Title', 'Some text'],
        \  'markdown'],
        \ ['settings.Ab3xY9z1',
        \  ['# A configuration file', 'option = value'],
        \  'conf'],
        \ ]

  for [name, lines, expected] in checks
    let [filetype, syntax] = s:DetectTempFile(dir . '/' . name, lines)
    call assert_equal(expected, filetype, 'for sudoedit file ' . name)
    call assert_notequal('', syntax, 'no syntax for sudoedit file ' . name)
  endfor

  " A regular file name must keep working as before.
  let [filetype, syntax] = s:DetectTempFile(dir . '/test.vim', ['let g:test = 1'])
  call assert_equal('vim', filetype, 'for regular file name')
  call assert_notequal('', syntax, 'no syntax for regular file name')

  call delete(dir, 'rf')
endfunc
