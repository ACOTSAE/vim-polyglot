" File type detection for files edited through sudoedit(8).
"
" sudoedit(8) does not edit the file itself: it edits a temporary copy that is
" created in $TMPDIR (usually /var/tmp).  The name of that copy is derived from
" the original file name by inserting the random part of mkstemps(3):
"
"   <name>.XXXXXXXX        when <name> has no extension
"   <stem>XXXXXXXX.<ext>   when <name> has an extension
"
" (the template has eight X characters, six of which are replaced by random
" [0-9A-Za-z] characters).  The random part becomes the "extension" (or mangles
" the real one), so file name based detection cannot recognize the buffer any
" more and no syntax highlighting is enabled.
"
" sudoedit does not tell the editor the name of the original file.  When no
" file type was detected, strip the random characters and run Vim's regular
" detection again with the reconstructed name.  That reuses the built-in file
" name patterns as well as Vim's own content heuristics (scripts.vim and the
" generic "conf" fallback), so it works for every file type instead of only
" for a fixed set of file names.
"
" Used through polyglot#sudoedit#Detect(), called from
" autoload/polyglot/init.vim for new and reloaded buffers.

" Line continuation is used here, remove 'C' from 'cpoptions'
let s:cpo_save = &cpo
set cpo&vim

" Set while the file type detection is re-run.  That detection includes the
" autocommand which called us, so recursion has to be avoided.
let s:busy = 0

" The random part inserted by mkstemps(3) in sudoedit's temporary names.
let s:random = '[0-9A-Za-z]\{8}'

" Return a list with the original file names that could have produced {name}.
func! s:OriginalNames(name) abort
  let names = []

  " <stem>XXXXXXXX.<ext> -> <stem>.<ext>
  let matches = matchlist(a:name, '^\(.*\)' . s:random . '\(\.[^.]\+\)$')
  if !empty(matches)
    call add(names, matches[1] . matches[2])
  endif

  " <name>.XXXXXXXX -> <name>
  let matches = matchlist(a:name, '^\(.\+\)\.' . s:random . '$')
  if !empty(matches)
    call add(names, matches[1])
  endif

  return names
endfunc

" Run the regular file type detection with {name} as the file name.  Returns 1
" when a useful file type was found.
func! s:DetectName(name) abort
  let before = &l:filetype
  silent! execute 'doautocmd <nomodeline> filetypedetect BufRead '
        \ . fnameescape(a:name)
  let after = &l:filetype
  " "conf" is only Vim's generic fallback, don't treat it as a real match.
  return after !=# before && after !=# '' && after !=# 'conf'
endfunc

" Called from the filetypedetect autocommand for new and reloaded buffers.
" Does nothing when a file type was already detected with confidence.
func! polyglot#sudoedit#Detect() abort
  if s:busy
    return
  endif

  " A file type set with ":setf FALLBACK" does not count as detected, so
  " &l:filetype can be "conf" here while did_filetype() is false.
  if &l:filetype !=# '' && &l:filetype !=# 'conf'
    return
  endif

  let s:busy = 1
  try
    let name = expand('<amatch>:t')
    let original_names = name ==# '' ? [] : s:OriginalNames(name)
    if empty(original_names)
      return
    endif

    for candidate in original_names
      if candidate ==# '' || candidate ==# name
        continue
      endif
      if s:DetectName(candidate)
        return
      endif
    endfor
  finally
    let s:busy = 0
  endtry
endfunc

" Restore 'cpoptions'
let &cpo = s:cpo_save
unlet s:cpo_save
