(***********************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team    *)
(* <O___,, *        INRIA-Rocquencourt  &  LRI-CNRS-Orsay              *)
(*   \VV/  *************************************************************)
(*    //   *      This file is distributed under the terms of the      *)
(*         *       GNU Lesser General Public License Version 2.1       *)
(***********************************************************************)

(** Some excerpts of Util and similar files to avoid depending on them
    and hence on Compat and Camlp4 *)

module Stringmap : Map.S with type key = string

val list_fold_left_i : (int -> 'a -> 'b -> 'a) -> int -> 'a -> 'b list -> 'a
val list_map_i : (int -> 'a -> 'b) -> int -> 'a list -> 'b list
val list_filter_i : (int -> 'a -> bool) -> 'a list -> 'a list
val list_chop : int -> 'a list -> 'a list * 'a list
val list_index0 : 'a -> 'a list -> int

val subst_command_placeholder : string -> string -> string

val home : string

val coqlib : string ref
val coqtop_path : string ref
