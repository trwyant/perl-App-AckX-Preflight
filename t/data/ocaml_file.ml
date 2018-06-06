#!/usr/bin/env ocaml
(** This is documentation for the entire file *)

open Printf

(* This is a comment
 * (* Note that comments nest *)
 * so that this is still a comment *)
(*** This is a comment, rather than documentation *)

(** This is more
 * documentation *)

let name = if Array.length Sys.argv > 1
    then Sys.argv.(1)
    else "world";;
printf "Hello %s!\n" name;;
