(* -*- coq-prog-args: ("-emacs-U" "-nois") -*- *)
(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, * CNRS-Ecole Polytechnique-INRIA Futurs-Universite Paris Sud *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(* Typeclass-based setoids, tactics and standard instances.
   TODO: explain clrewrite, clsubstitute and so on.
 
   Author: Matthieu Sozeau
   Institution: LRI, CNRS UMR 8623 - Universit�copyright Paris Sud
   91405 Orsay, France *)

(* $Id: FSetAVL_prog.v 616 2007-08-08 12:28:10Z msozeau $ *)

Require Import Coq.Program.Program.
Require Import Coq.Classes.Init.

Set Implicit Arguments.
Unset Strict Implicit.

Require Export Coq.Classes.Relations.
Require Export Coq.Classes.Morphisms.

Definition equiv [ Equivalence A R ] : relation A := R.

(** Shortcuts to make proof search possible (unification won't unfold equiv). *)

Definition equivalence_refl [ sa : Equivalence A ] : Reflexive equiv.
Proof. eauto with typeclass_instances. Qed.

Definition equivalence_sym [ sa : Equivalence A ] : Symmetric equiv.
Proof. eauto with typeclass_instances. Qed.

Definition equivalence_trans [ sa : Equivalence A ] : Transitive equiv.
Proof. eauto with typeclass_instances. Qed.

(** Overloaded notations for setoid equivalence and inequivalence. Not to be confused with [eq] and [=]. *)

(** Subset objects should be first coerced to their underlying type, but that notation doesn't work in the standard case then. *)
(* Notation " x == y " := (equiv (x :>) (y :>)) (at level 70, no associativity) : type_scope. *)

Notation " x == y " := (equiv x y) (at level 70, no associativity) : type_scope.

Notation " x =/= y " := (complement equiv x y) (at level 70, no associativity) : type_scope.

(** Use the [clsubstitute] command which substitutes an equality in every hypothesis. *)

Ltac clsubst H := 
  match type of H with
    ?x == ?y => clsubstitute H ; clear H x
  end.

Ltac clsubst_nofail :=
  match goal with
    | [ H : ?x == ?y |- _ ] => clsubst H ; clsubst_nofail
    | _ => idtac
  end.
  
(** [subst*] will try its best at substituting every equality in the goal. *)

Tactic Notation "clsubst" "*" := clsubst_nofail.

Lemma nequiv_equiv_trans : forall [ Equivalence A ] (x y z : A), x =/= y -> y == z -> x =/= z.
Proof with auto.
  intros; intro.
  assert(z == y) by relation_sym.
  assert(x == y) by relation_trans.
  contradiction.
Qed.

Lemma equiv_nequiv_trans : forall [ Equivalence A ] (x y z : A), x == y -> y =/= z -> x =/= z.
Proof.
  intros; intro. 
  assert(y == x) by relation_sym.
  assert(y == z) by relation_trans.
  contradiction.
Qed.

Open Scope type_scope.

Ltac equiv_simplify_one :=
  match goal with
    | [ H : ?x == ?x |- _ ] => clear H
    | [ H : ?x == ?y |- _ ] => clsubst H
    | [ |- ?x =/= ?y ] => let name:=fresh "Hneq" in intro name
  end.

Ltac equiv_simplify := repeat equiv_simplify_one.

Ltac equivify_tac :=
  match goal with
    | [ s : Equivalence ?A, H : ?R ?x ?y |- _ ] => change R with (@equiv A R s) in H
    | [ s : Equivalence ?A |- context C [ ?R ?x ?y ] ] => change (R x y) with (@equiv A R s x y)
  end.

Ltac equivify := repeat equivify_tac.

(** Every equivalence relation gives rise to a morphism, as it is transitive and symmetric. *)

Instance [ sa : Equivalence A ] => equiv_morphism : ? Morphism (equiv ++> equiv ++> iff) equiv :=
  respect := respect.

(** The partial application too as it is reflexive. *)

Instance [ sa : Equivalence A ] (x : A) => 
  equiv_partial_app_morphism : ? Morphism (equiv ++> iff) (equiv x) :=
  respect := respect. 

Definition type_eq : relation Type :=
  fun x y => x = y.

Program Instance type_equivalence : Equivalence Type type_eq.

  Solve Obligations using constructor ; unfold type_eq ; program_simpl.

Ltac morphism_tac := try red ; unfold arrow ; intros ; program_simpl ; try tauto.

Ltac obligations_tactic ::= morphism_tac.

(** These are morphisms used to rewrite at the top level of a proof, 
   using [iff_impl_id_morphism] if the proof is in [Prop] and
   [eq_arrow_id_morphism] if it is in Type. *)

Program Instance iff_impl_id_morphism : ? Morphism (iff ++> impl) id.

(* Program Instance eq_arrow_id_morphism : ? Morphism (eq +++> arrow) id. *)

(* Definition compose_respect (A B C : Type) (R : relation (A -> B)) (R' : relation (B -> C)) *)
(*   (x y : A -> C) : Prop := forall (f : A -> B) (g : B -> C), R f f -> R' g g. *)

(* Program Instance (A B C : Type) (R : relation (A -> B)) (R' : relation (B -> C)) *)
(*   [ mg : ? Morphism R' g ] [ mf : ? Morphism R f ] =>  *)
(*   compose_morphism : ? Morphism (compose_respect R R') (g o f). *)

(* Next Obligation. *)
(* Proof. *)
(*   apply (respect (m0:=mg)). *)
(*   apply (respect (m0:=mf)). *)
(*   assumption. *)
(* Qed. *)

(** Partial equivs don't require reflexivity so we can build a partial equiv on the function space. *)

Class PartialEquivalence (carrier : Type) (pequiv : relation carrier) :=
  pequiv_prf :> PER carrier pequiv.

(** Overloaded notation for partial equiv equivalence. *)

(* Infix "=~=" := pequiv (at level 70, no associativity) : type_scope. *)

(** Reset the default Program tactic. *)

Ltac obligations_tactic ::= program_simpl.