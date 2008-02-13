Require Import List.
Require Import ZArith.
Require String. Open Scope string_scope.
Ltac Case s := let c := fresh "case" in set (c := s).

Set Implicit Arguments.
Unset Strict Implicit.

Inductive sv : Set :=
| I : Z -> sv
| S : list sv -> sv.

Section sv_induction.

Variables
  (VP: sv -> Prop)
  (LP: list sv -> Prop)

  (VPint: forall n, VP (I n))
  (VPset: forall vs, LP vs -> VP (S vs))
  (lpcons: forall v vs, VP v -> LP vs -> LP (v::vs))
  (lpnil: LP nil).

Fixpoint setl_value_indp (x:sv) {struct x}: VP x :=
  match x as x return VP x with
  | I n => VPint n
  | S vs =>
    VPset
    ((fix values_indp (vs:list sv) {struct vs}: (LP vs) :=
      match vs as vs return LP vs with
      | nil => lpnil
      | v::vs => lpcons (setl_value_indp v) (values_indp vs)
      end) vs)
  end.
End sv_induction.

Inductive slt : sv -> sv -> Prop :=
| IC : forall z, slt (I z) (I z)
| IS : forall vs vs', slist_in vs vs' -> slt (S vs) (S vs')

with sin : sv ->  list sv -> Prop :=
| Ihd : forall s s' sv', slt s s' -> sin s (s'::sv')
| Itl : forall s s' sv', sin s sv' -> sin s (s'::sv')

with slist_in : list sv -> list sv -> Prop :=
| Inil : forall sv',
  slist_in nil sv'
| Icons : forall s sv sv',
  sin s sv' ->
  slist_in sv sv' ->
  slist_in (s::sv) sv'.

Hint Constructors sin slt slist_in.

Require Import Program.

Program Fixpoint lt_dec (x y:sv) { struct x } : {slt x y}+{~slt x y} :=
  match x with
    | I x => 
      match y with
        | I y => if (Z_eq_dec x y) then left else right
        | S ys => right
      end
    | S xs => 
      match y with
        | I y => right
        | S ys =>
          let fix list_in (xs ys:list sv) {struct xs} : 
            {slist_in xs ys} + {~slist_in xs ys} :=
            match xs with
              | nil => left
              | x::xs =>
                let fix elem_in (ys:list sv) : {sin x ys}+{~sin x ys} :=
                  match ys with
                    | nil => right
                    | y::ys => if lt_dec x y then left else if elem_in
                      ys then left else right
                  end
                in 
                if elem_in ys then 
                  if list_in xs ys then left else right
                else right
            end
            in if list_in xs ys then left else right
      end
  end.

Next Obligation. intro; apply H; inversion H0; subst; trivial. Defined.
Next Obligation. intro; inversion H. Defined.
Next Obligation. intro H; inversion H. Defined.
Next Obligation. intro; inversion H; subst. Defined.
Next Obligation.
  contradict H. inversion H; subst. assumption. 
  contradict H0; assumption. Defined.
Next Obligation.
  contradict H0. inversion H0; subst. assumption. Defined.
Next Obligation.
  contradict H. inversion H; subst. assumption. Defined.
Next Obligation.
  contradict H. inversion H; subst; auto. Defined.
