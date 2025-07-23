" Vim compiler file for Odin
" Compiler: odin
" Maintainer: Jake Norton
" Last Change: 2025

if exists("current_compiler")
  finish
endif
let current_compiler = "odin"

" Save current cpoptions and set to vim default
let s:cpo_save = &cpo
set cpo&vim

" Set makeprg to use odin build command
" Adjust this based on your typical build command
"setlocal makeprg=odin\ build\ .\ -out:build

" Error format for Odin compiler
" This handles the common Odin error format:
" file.odin(line:column) Error: message
" file.odin(line:column) Warning: message
setlocal errorformat=
    \%f(%l:%c)\ Error:\ %m,
    \%f(%l:%c)\ Warning:\ %m,
    \%f(%l:%c)\ %m,
    \%f:%l:%c:\ %m,
    \%f:%l:\ %m,
    \%-G%.%#

" Restore cpoptions
let &cpo = s:cpo_save
unlet s:cpo_save
