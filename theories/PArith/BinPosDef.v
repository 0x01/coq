(* -*- coding: utf-8 -*- *)
(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2010     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

(**********************************************************************)
(** * Binary positive numbers, operations *)
(**********************************************************************)

(** Initial development by Pierre Crégut, CNET, Lannion, France *)

(** The type [positive] and its constructors [xI] and [xO] and [xH]
    are now defined in [BinNums.v] *)

Require Export BinNums.

(** Postfix notation for positive numbers, allowing to mimic
    the position of bits in a big-endian representation.
    For instance, we can write [1~1~0] instead of [(xO (xI xH))]
    for the number 6 (which is 110 in binary notation).
*)

Notation "p ~ 1" := (xI p)
 (at level 7, left associativity, format "p '~' '1'") : positive_scope.
Notation "p ~ 0" := (xO p)
 (at level 7, left associativity, format "p '~' '0'") : positive_scope.

Local Open Scope positive_scope.
Local Unset Boolean Equality Schemes.
Local Unset Case Analysis Schemes.

Module Pos.

Definition t := positive.

(** * Operations over positive numbers *)

(** ** Successor *)

Fixpoint succ x :=
  match x with
    | p~1 => (succ p)~0
    | p~0 => p~1
    | 1 => 1~0
  end.

(** ** Addition *)

Fixpoint add x y :=
  match x, y with
    | p~1, q~1 => (add_carry p q)~0
    | p~1, q~0 => (add p q)~1
    | p~1, 1 => (succ p)~0
    | p~0, q~1 => (add p q)~1
    | p~0, q~0 => (add p q)~0
    | p~0, 1 => p~1
    | 1, q~1 => (succ q)~0
    | 1, q~0 => q~1
    | 1, 1 => 1~0
  end

with add_carry x y :=
  match x, y with
    | p~1, q~1 => (add_carry p q)~1
    | p~1, q~0 => (add_carry p q)~0
    | p~1, 1 => (succ p)~1
    | p~0, q~1 => (add_carry p q)~0
    | p~0, q~0 => (add p q)~1
    | p~0, 1 => (succ p)~0
    | 1, q~1 => (succ q)~1
    | 1, q~0 => (succ q)~0
    | 1, 1 => 1~1
  end.

Infix "+" := add : positive_scope.

(** ** Operation [x -> 2*x-1] *)

Fixpoint pred_double x :=
  match x with
    | p~1 => p~0~1
    | p~0 => (pred_double p)~1
    | 1 => 1
  end.

(** ** Predecessor *)

Definition pred x :=
  match x with
    | p~1 => p~0
    | p~0 => pred_double p
    | 1 => 1
  end.

(** ** The predecessor of a positive number can be seen as a [N] *)

Definition pred_N x :=
  match x with
    | p~1 => Npos (p~0)
    | p~0 => Npos (pred_double p)
    | 1 => N0
  end.

(** ** An auxiliary type for subtraction *)

Inductive mask : Set :=
| IsNul : mask
| IsPos : positive -> mask
| IsNeg : mask.

(** ** Operation [x -> 2*x+1] *)

Definition succ_double_mask (x:mask) : mask :=
  match x with
    | IsNul => IsPos 1
    | IsNeg => IsNeg
    | IsPos p => IsPos p~1
  end.

(** ** Operation [x -> 2*x] *)

Definition double_mask (x:mask) : mask :=
  match x with
    | IsNul => IsNul
    | IsNeg => IsNeg
    | IsPos p => IsPos p~0
  end.

(** ** Operation [x -> 2*x-2] *)

Definition double_pred_mask x : mask :=
  match x with
    | p~1 => IsPos p~0~0
    | p~0 => IsPos (pred_double p)~0
    | 1 => IsNul
  end.

(** ** Predecessor with mask *)

Definition pred_mask (p : mask) : mask :=
  match p with
    | IsPos 1 => IsNul
    | IsPos q => IsPos (pred q)
    | IsNul => IsNeg
    | IsNeg => IsNeg
  end.

(** ** Subtraction, result as a mask *)

Fixpoint sub_mask (x y:positive) {struct y} : mask :=
  match x, y with
    | p~1, q~1 => double_mask (sub_mask p q)
    | p~1, q~0 => succ_double_mask (sub_mask p q)
    | p~1, 1 => IsPos p~0
    | p~0, q~1 => succ_double_mask (sub_mask_carry p q)
    | p~0, q~0 => double_mask (sub_mask p q)
    | p~0, 1 => IsPos (pred_double p)
    | 1, 1 => IsNul
    | 1, _ => IsNeg
  end

with sub_mask_carry (x y:positive) {struct y} : mask :=
  match x, y with
    | p~1, q~1 => succ_double_mask (sub_mask_carry p q)
    | p~1, q~0 => double_mask (sub_mask p q)
    | p~1, 1 => IsPos (pred_double p)
    | p~0, q~1 => double_mask (sub_mask_carry p q)
    | p~0, q~0 => succ_double_mask (sub_mask_carry p q)
    | p~0, 1 => double_pred_mask p
    | 1, _ => IsNeg
  end.

(** ** Subtraction, result as a positive, returning 1 if [x<=y] *)

Definition sub x y :=
  match sub_mask x y with
    | IsPos z => z
    | _ => 1
  end.

Infix "-" := sub : positive_scope.

(** ** Multiplication *)

Fixpoint mul x y :=
  match x with
    | p~1 => y + (mul p y)~0
    | p~0 => (mul p y)~0
    | 1 => y
  end.

Infix "*" := mul : positive_scope.

(** ** Iteration over a positive number *)

Fixpoint iter (n:positive) {A} (f:A -> A) (x:A) : A :=
  match n with
    | xH => f x
    | xO n' => iter n' f (iter n' f x)
    | xI n' => f (iter n' f (iter n' f x))
  end.

(** ** Power *)

Definition pow (x y:positive) := iter y (mul x) 1.

Infix "^" := pow : positive_scope.

(** ** Division by 2 rounded below but for 1 *)

Definition div2 p :=
  match p with
    | 1 => 1
    | p~0 => p
    | p~1 => p
  end.

(** Division by 2 rounded up *)

Definition div2_up p :=
 match p with
   | 1 => 1
   | p~0 => p
   | p~1 => succ p
 end.

(** ** Number of digits in a positive number *)

Fixpoint size_nat p : nat :=
  match p with
    | 1 => S O
    | p~1 => S (size_nat p)
    | p~0 => S (size_nat p)
  end.

(** Same, with positive output *)

Fixpoint size p :=
  match p with
    | 1 => 1
    | p~1 => succ (size p)
    | p~0 => succ (size p)
  end.

(** ** Comparison on binary positive numbers *)

Fixpoint compare_cont (x y:positive) (r:comparison) {struct y} : comparison :=
  match x, y with
    | p~1, q~1 => compare_cont p q r
    | p~1, q~0 => compare_cont p q Gt
    | p~1, 1 => Gt
    | p~0, q~1 => compare_cont p q Lt
    | p~0, q~0 => compare_cont p q r
    | p~0, 1 => Gt
    | 1, q~1 => Lt
    | 1, q~0 => Lt
    | 1, 1 => r
  end.

Definition compare x y := compare_cont x y Eq.

Infix "?=" := compare (at level 70, no associativity) : positive_scope.

Definition min p p' :=
 match p ?= p' with
 | Lt | Eq => p
 | Gt => p'
 end.

Definition max p p' :=
 match p ?= p' with
 | Lt | Eq => p'
 | Gt => p
 end.

(** ** Boolean equality and comparisons *)

(** Nota: this [eqb] is not convertible with the generated [positive_beq], due
    to a different guard argument. We keep this version for compatibility. *)

Fixpoint eqb p q {struct q} :=
  match p, q with
    | p~1, q~1 => eqb p q
    | p~0, q~0 => eqb p q
    | 1, 1 => true
    | _, _ => false
  end.

Definition leb x y :=
 match x ?= y with Gt => false | _ => true end.

Definition ltb x y :=
 match x ?= y with Lt => true | _ => false end.

Infix "=?" := eqb (at level 70, no associativity) : positive_scope.
Infix "<=?" := leb (at level 70, no associativity) : positive_scope.
Infix "<?" := ltb (at level 70, no associativity) : positive_scope.

(** ** A Square Root function for positive numbers *)

(** We procede by blocks of two digits : if p is written qbb'
    then sqrt(p) will be sqrt(q)~0 or sqrt(q)~1.
    For deciding easily in which case we are, we store the remainder
    (as a mask, since it can be null).
    Instead of copy-pasting the following code four times, we
    factorize as an auxiliary function, with f and g being either
    xO or xI depending of the initial digits.
    NB: (sub_mask (g (f 1)) 4) is a hack, morally it's g (f 0).
*)

Definition sqrtrem_step (f g:positive->positive) p :=
 match p with
  | (s, IsPos r) =>
    let s' := s~0~1 in
    let r' := g (f r) in
    if s' <=? r' then (s~1, sub_mask r' s')
    else (s~0, IsPos r')
  | (s,_)  => (s~0, sub_mask (g (f 1)) 4)
 end.

Fixpoint sqrtrem p : positive * mask :=
 match p with
  | 1 => (1,IsNul)
  | 2 => (1,IsPos 1)
  | 3 => (1,IsPos 2)
  | p~0~0 => sqrtrem_step xO xO (sqrtrem p)
  | p~0~1 => sqrtrem_step xO xI (sqrtrem p)
  | p~1~0 => sqrtrem_step xI xO (sqrtrem p)
  | p~1~1 => sqrtrem_step xI xI (sqrtrem p)
 end.

Definition sqrt p := fst (sqrtrem p).


(** ** Greatest Common Divisor *)

Definition divide p q := exists r, p*r = q.
Notation "( p | q )" := (divide p q) (at level 0) : positive_scope.

(** Instead of the Euclid algorithm, we use here the Stein binary
   algorithm, which is faster for this representation. This algorithm
   is almost structural, but in the last cases we do some recursive
   calls on subtraction, hence the need for a counter.
*)

Fixpoint gcdn (n : nat) (a b : positive) : positive :=
  match n with
    | O => 1
    | S n =>
      match a,b with
	| 1, _ => 1
	| _, 1 => 1
	| a~0, b~0 => (gcdn n a b)~0
	| _  , b~0 => gcdn n a b
	| a~0, _   => gcdn n a b
	| a'~1, b'~1 =>
          match a' ?= b' with
	    | Eq => a
	    | Lt => gcdn n (b'-a') a
	    | Gt => gcdn n (a'-b') b
          end
      end
  end.

(** We'll show later that we need at most (log2(a.b)) loops *)

Definition gcd (a b : positive) := gcdn (size_nat a + size_nat b)%nat a b.

(** Generalized Gcd, also computing the division of a and b by the gcd *)

Fixpoint ggcdn (n : nat) (a b : positive) : (positive*(positive*positive)) :=
  match n with
    | O => (1,(a,b))
    | S n =>
      match a,b with
	| 1, _ => (1,(1,b))
	| _, 1 => (1,(a,1))
	| a~0, b~0 =>
           let (g,p) := ggcdn n a b in
           (g~0,p)
	| _, b~0 =>
           let '(g,(aa,bb)) := ggcdn n a b in
           (g,(aa, bb~0))
	| a~0, _ =>
           let '(g,(aa,bb)) := ggcdn n a b in
           (g,(aa~0, bb))
	| a'~1, b'~1 =>
           match a' ?= b' with
	     | Eq => (a,(1,1))
	     | Lt =>
	        let '(g,(ba,aa)) := ggcdn n (b'-a') a in
	        (g,(aa, aa + ba~0))
	     | Gt =>
		let '(g,(ab,bb)) := ggcdn n (a'-b') b in
		(g,(bb + ab~0, bb))
	   end
      end
  end.

Definition ggcd (a b: positive) := ggcdn (size_nat a + size_nat b)%nat a b.

(** Local copies of the not-yet-available [N.double] and [N.succ_double] *)

Definition Nsucc_double x :=
  match x with
  | N0 => Npos 1
  | Npos p => Npos p~1
  end.

Definition Ndouble n :=
  match n with
  | N0 => N0
  | Npos p => Npos p~0
  end.

(** Operation over bits. *)

(** Logical [or] *)

Fixpoint lor (p q : positive) : positive :=
  match p, q with
    | 1, q~0 => q~1
    | 1, _ => q
    | p~0, 1 => p~1
    | _, 1 => p
    | p~0, q~0 => (lor p q)~0
    | p~0, q~1 => (lor p q)~1
    | p~1, q~0 => (lor p q)~1
    | p~1, q~1 => (lor p q)~1
  end.

(** Logical [and] *)

Fixpoint land (p q : positive) : N :=
  match p, q with
    | 1, q~0 => N0
    | 1, _ => Npos 1
    | p~0, 1 => N0
    | _, 1 => Npos 1
    | p~0, q~0 => Ndouble (land p q)
    | p~0, q~1 => Ndouble (land p q)
    | p~1, q~0 => Ndouble (land p q)
    | p~1, q~1 => Nsucc_double (land p q)
  end.

(** Logical [diff] *)

Fixpoint ldiff (p q:positive) : N :=
  match p, q with
    | 1, q~0 => Npos 1
    | 1, _ => N0
    | _~0, 1 => Npos p
    | p~1, 1 => Npos (p~0)
    | p~0, q~0 => Ndouble (ldiff p q)
    | p~0, q~1 => Ndouble (ldiff p q)
    | p~1, q~1 => Ndouble (ldiff p q)
    | p~1, q~0 => Nsucc_double (ldiff p q)
  end.

(** [xor] *)

Fixpoint lxor (p q:positive) : N :=
  match p, q with
    | 1, 1 => N0
    | 1, q~0 => Npos (q~1)
    | 1, q~1 => Npos (q~0)
    | p~0, 1 => Npos (p~1)
    | p~0, q~0 => Ndouble (lxor p q)
    | p~0, q~1 => Nsucc_double (lxor p q)
    | p~1, 1 => Npos (p~0)
    | p~1, q~0 => Nsucc_double (lxor p q)
    | p~1, q~1 => Ndouble (lxor p q)
  end.

(** Shifts. NB: right shift of 1 stays at 1. *)

Definition shiftl_nat (p:positive)(n:nat) := nat_iter n xO p.
Definition shiftr_nat (p:positive)(n:nat) := nat_iter n div2 p.

Definition shiftl (p:positive)(n:N) :=
  match n with
    | N0 => p
    | Npos n => iter n xO p
  end.

Definition shiftr (p:positive)(n:N) :=
  match n with
    | N0 => p
    | Npos n => iter n div2 p
  end.

(** Checking whether a particular bit is set or not *)

Fixpoint testbit_nat (p:positive) : nat -> bool :=
  match p with
    | 1 => fun n => match n with
                      | O => true
                      | S _ => false
                    end
    | p~0 => fun n => match n with
                        | O => false
                        | S n' => testbit_nat p n'
                      end
    | p~1 => fun n => match n with
                        | O => true
                        | S n' => testbit_nat p n'
                      end
  end.

(** Same, but with index in N *)

Fixpoint testbit (p:positive)(n:N) :=
  match p, n with
    | p~0, N0 => false
    | _, N0 => true
    | 1, _ => false
    | p~0, Npos n => testbit p (pred_N n)
    | p~1, Npos n => testbit p (pred_N n)
  end.

(** ** From binary positive numbers to Peano natural numbers *)

Definition iter_op {A}(op:A->A->A) :=
  fix iter (p:positive)(a:A) : A :=
  match p with
    | 1 => a
    | p~0 => iter p (op a a)
    | p~1 => op a (iter p (op a a))
  end.

Definition to_nat (x:positive) : nat := iter_op plus x (S O).

(** ** From Peano natural numbers to binary positive numbers *)

(** A version preserving positive numbers, and sending 0 to 1. *)

Fixpoint of_nat (n:nat) : positive :=
 match n with
   | O => 1
   | S O => 1
   | S x => succ (of_nat x)
 end.

(* Another version that converts [n] into [n+1] *)

Fixpoint of_succ_nat (n:nat) : positive :=
  match n with
    | O => 1
    | S x => succ (of_succ_nat x)
  end.

End Pos.