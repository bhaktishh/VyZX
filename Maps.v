Require Export externals.QuantumLib.Prelim.
Require Import Coq.Arith.Peano_dec.

Definition partial_map A : Type := (list nat) * (nat -> option A).

Definition empty_map {A} : partial_map A := ([], (fun _ => None)).

Fixpoint Inb n (l : list nat) : bool :=
  match l with
  | [] => false
  | h::l' => if h =? n then true else Inb n l'
  end.

Definition insert {A} (pm : partial_map A) (key : nat) (val : A) : partial_map A :=
  match pm with
  (keys, map) => (if Inb key keys then keys else key :: keys,
                    fun n => if (n =? key) then (Some val) else map n)
  end.

Lemma Inb_In : forall (l : list nat) (n : nat),
  Inb n l = true <-> In n l.
Proof.
  intros.
  split; intros.
  - induction l.
    + simpl in H.
      discriminate H.
    + simpl in H.
      bdestruct (a =? n).
      * constructor.
        assumption.
      * simpl.
        right.
        apply IHl.
        apply H. 
  - induction l.
    + contradiction.
    + simpl in H.
      simpl.
      destruct H.
      * subst. 
        rewrite Nat.eqb_refl.
        easy.
      * bdestruct (a =? n); [ easy | ].
        apply IHl.
        apply H.
Qed.     

Lemma Not_Inb_In : forall (l : list nat) (n : nat),
  Inb n l = false <-> ~ In n l.
Proof.
  intros.
  rewrite <- not_true_iff_false.
  apply not_iff_compat.
  apply Inb_In.
Qed.

Definition remove {A} (pm : partial_map A) (key : nat) : partial_map A :=
  match pm with
  (keys, map) => (List.remove eq_nat_dec key keys, 
                  fun n => if (n =? key) then None else map n)
  end.

Definition contains {A} (pm : partial_map A) (key : nat) := 
  match pm with
  (keys, _) => Inb key keys 
  end.

Definition get {A} (pm : partial_map A) (key : nat) :=
  if (contains pm key) then (snd pm) key else None.

Definition size {A} (pm : partial_map A) := 
  match pm with
  (keys, _) => length keys
  end.

Fixpoint to_list_helper {A} (keys : list nat) (map : nat -> option A) : list (nat * A) :=
  match keys with
  | [] => []
  | key :: keys' => match get (keys, map) key with
                    | None => to_list_helper keys' map
                    | Some v => (key, v) :: to_list_helper keys' map
                    end
  end.

Notation "a !! pm" := (get pm a) (at level 20).
Notation "a ?? pm" := (contains pm a) (at level 20).
Notation "<[ key ↦ val ; pm ]>" := (insert pm key val) (at level 30).
Notation "<[ key ↦ val ]>" := (insert empty_map key val) (at level 30).
Notation "<[ pm -- key ]>" := (remove pm key) (at level 30).

Definition to_list {A} (pm : partial_map A) : list (nat * A) :=
  match pm with
  (keys, map) => to_list_helper keys map
  end.

Lemma insert_contains : forall {A} (pm : partial_map A) key (a : A), 
  key ?? (<[ key ↦ a; pm ]>) = true.
Proof.
  intros.
  unfold insert.
  unfold contains.
  destruct pm.
  destruct (Inb key l) eqn:H; [ assumption | simpl; rewrite Nat.eqb_refl; easy ].
Qed.

Lemma insert_Some : forall {A} (pm : partial_map A) key (a : A), 
  key !! (<[ key ↦ a; pm ]>) = Some a.
Proof.
  intros.
  unfold get.
  destruct pm.
  rewrite insert_contains.
  unfold insert.
  simpl.
  rewrite Nat.eqb_refl.
  easy.
Qed.

Lemma insert_to_list :  forall {A} (pm : partial_map A) key a,
  In (key, a) (to_list (<[ key ↦ a; pm ]>)).
Proof.
  intros.
  simpl.
  unfold to_list.
  unfold insert.
  destruct pm.
  induction l.
  - simpl.
    rewrite Nat.eqb_refl.
    constructor.
    easy.
  - simpl.  
    bdestruct (a0 =? key).
    + subst.
      simpl.
      rewrite Nat.eqb_refl.
      constructor.
      easy.
    + destruct (Inb key l) eqn:H'.
      * simpl.
        rewrite <- Nat.eqb_neq in H.
        rewrite H.
        destruct (o a0); [ simpl; right | ]; apply IHl.
      * simpl.
        rewrite Nat.eqb_refl.
        constructor.
        easy.
Qed.

Lemma remove_no_contains : forall {A} (pm : partial_map A) key,
  key ?? (<[ pm -- key]>) = false.
Proof.
  intros.
  unfold remove.
  destruct pm.
  unfold contains.
  rewrite Not_Inb_In.
  apply remove_In.
Qed.

Lemma remove_None : forall {A} (pm : partial_map A) key , 
  key !! (<[ pm -- key]>) = None.
Proof.
  intros.
  destruct pm.
  unfold get.
  rewrite remove_no_contains.
  easy.
Qed.


Lemma remove_contains_size : forall {A} (pm : partial_map A) key,
  key ?? pm = true -> (size (<[ pm -- key]>)) < size pm.
Proof.
  intros.
  unfold size.
  unfold remove.
  destruct pm.
  unfold contains in H.
  rewrite Inb_In in H.
  apply remove_length_lt.
  assumption.
Qed.

Lemma get_implies_contains : forall {A} (pm : partial_map A) key a, key !! pm = Some a -> key ?? pm = true.
Proof.
  intros.
  unfold get in H.
  destruct (key ?? pm); [ reflexivity | discriminate H ].
Qed.


Lemma empty_no_contains : forall {A} (pm : partial_map A) key, size pm = 0 -> key ?? pm = false.
Proof.
  intros.
  destruct pm.
  unfold size in H.
  rewrite length_zero_iff_nil in H.
  simpl.
  subst.
  easy.
Qed.

Lemma In_if_lookup : forall {A} (pm : partial_map A) key a, (forall x y : A, {x = y} + {x <> y}) -> key !! pm = Some a -> In (key, a) (to_list pm).
Proof.
  intros.
  generalize dependent a.
  generalize dependent key.
  destruct pm.
  induction l; intros.
  - simpl.
    simpl in H.
    discriminate.
  - simpl.
    destruct (o a) eqn:H'.
    + simpl.
      specialize (X a1 a0).
      destruct X.
      * subst.
        bdestruct (a =? key).
        subst.
        rewrite H.
        -- left.
           easy.
        -- unfold get.
           simpl.
           rewrite Nat.eqb_refl.
           rewrite H'.
           right.
           apply IHl.
           simpl in H.
           unfold get in *.
           simpl in H.
           bdestruct (a =? key); [ contradiction | ].
           destruct (Inb key l) eqn: H2.
           ++ simpl.
              rewrite H2.
              apply H.
           ++ discriminate H.   
      * simpl in IHl.
        bdestruct (key =? a).
        -- subst.
           rewrite H.
           right.
           unfold get in H.
           simpl in H.
           rewrite Nat.eqb_refl in H.
           destruct (a ?? (l, o)) eqn:H1.
           ++ apply IHl.
              unfold get.
              rewrite H1.
              simpl.
              assumption.
           ++ exfalso.
              rewrite H in H'.
              inversion H'.
              contradict n.
              symmetry.
              apply H2.
        -- simpl.
           unfold get.
           simpl.
           rewrite Nat.eqb_refl.
           rewrite H'.
           right.
           apply IHl.
           unfold get in H.
           simpl in H.
           bdestruct (a =? key); [ symmetry in H1; contradiction | ].
           unfold get.
           simpl.
           assumption.
    + simpl in IHl.
      unfold get.
      simpl.
      rewrite Nat.eqb_refl.
      rewrite H'.
      apply IHl.
      unfold get in H.
      simpl in H.
      bdestruct (a =? key).
      * exfalso.
        subst.
        rewrite H in H'.
        discriminate H'.
      * unfold get.
        simpl.
        apply H.
Qed.

Lemma Lookup_if_in : forall {A} (pm : partial_map A) key a, (forall x y : A, {x = y} + {x <> y}) -> In (key, a) (to_list pm) -> key !! pm = Some a.
Proof.
  intros.
  generalize dependent key.
  generalize dependent a.
  destruct pm.
  induction l; intros.
  - simpl in H.
    contradiction.
  - simpl in H.
    unfold get.
    simpl.
    bdestruct (a =? key).
    + unfold get in H.
      simpl in H.
      rewrite Nat.eqb_refl in H.
      destruct (o a) eqn:H'.
      * simpl in H.
        specialize (X a0 a1).
        simpl in IHl.
        destruct H.
        rewrite pair_equal_spec in H.
        destruct H.
        subst.
        assumption.
        specialize (IHl a0 key).
        unfold get in IHl.
        destruct (key ?? (l, o)) eqn:H''.
        ++ simpl in IHl.
           apply IHl.
           assumption.
        ++ specialize (IHl H).
           discriminate IHl.  
      * subst.
        specialize (IHl a0 key).
        unfold get in IHl.
        destruct (key ?? (l, o)) eqn:H''.
        ++ simpl in IHl.
           apply IHl.
           assumption.
        ++ simpl in IHl.
           specialize (IHl H).
           discriminate.
    + unfold get in H.
      simpl in H.
      rewrite Nat.eqb_refl in H.
      simpl.
      specialize (IHl a0 key).
      unfold get in IHl.
      simpl in IHl.
      apply IHl.
      destruct (o a) eqn:H'.
      * simpl in H.
        destruct H.
        ++ apply pair_equal_spec in H.
           destruct H.
           subst.
           contradiction.
        ++ exact H.
      * exact H.   
Qed.

Lemma contain_to_list : forall {A} (pm : partial_map A) key a,
  (forall x y : A, {x = y} + {x <> y}) -> key ?? pm = true -> key !! pm = Some a -> In (key, a) (to_list pm).
Proof.
  intros.
  destruct pm.
  generalize dependent a.
  induction l; intros.
  - simpl in H.
    discriminate H.
  - simpl.
    simpl in IHl.
    destruct (o a).
    + simpl.
      simpl in H0.
      simpl in H.
      bdestruct (a =? key).
      * simpl.
        left.
        admit.
      * right.
        apply IHl; assumption.
    + apply IHl.
      simpl in H.
      simpl in H0.
      bdestruct (a =? key).
      * admit. 
      * assumption.
      * simpl in H0.
        assumption.
Qed. 

Definition map {A B} (pm : partial_map A) (f : A -> B) : partial_map B :=
  match pm with
  (keys, map) => (keys, (fun n => 
                                match (map n) with
                                | None => None
                                | Some v => Some (f v)
                                end
                        )
  )
  end.

Definition alter {A} (pm : partial_map A) (f : option A -> option A) key : partial_map A :=  
  match pm with
    (keys, map) => match f (map key) with
                   | None => remove pm key
                   | Some v => insert pm key v
                   end
  end.

Definition map_opt {A B} (pm : partial_map A) (f : A -> option B) : partial_map B :=
  match pm with
  (keys, map) => (List.filter 
                    (
                      fun key => match (map key) with
                                 | None => false
                                 | Some v => match (f v) with
                                             | None => false
                                             | Some _ => true
                                             end
                                 end
                    ) keys, 
                    (fun n =>   match (map n) with
                                | None => None
                                | Some v => (f v)
                                end
                        )
                    )
end.

Definition graph_multi_map := partial_map (partial_map nat).

Definition multi_add (gmm : graph_multi_map) from to :=
  match (from !! gmm) with
  | None => <[ from ↦ (<[to ↦ 1]>); gmm ]>
  | Some m => match (to !! m) with
              | None => <[ from ↦ (<[to ↦ 1; m]>); gmm ]>
              | Some n' => <[ from ↦ (<[to ↦ S n'; m]>); gmm ]>
              end
  end.

Definition multi_remove (gmm : graph_multi_map) from to :=
  match (from !! gmm) with
  | None => gmm
  | Some m => match (to !! m) with
              | None => gmm
              | Some n' => <[ from ↦ (<[to ↦ (pred n'); m]>); gmm ]>
              end
  end.

Definition multi_clear (gmm : graph_multi_map) from to :=
    match (from !! gmm) with
    | None => gmm
    | Some m => match (to !! m) with
                | None => gmm
                | Some n' => <[ from ↦ (<[m -- to]>); gmm ]>
                end
    end.

Definition multi_get (gmm : graph_multi_map) from to :=
  match (from !! gmm) with
  | None => 0
  | Some m => match (to !! m) with
              | None => 0
              | Some v => v
              end
  end.

Notation "<( from , to )> !!! gmm" := (multi_get gmm from to) (at level 20).
Notation "<( from , to )> ++ gmm" := (multi_add gmm from to) (at level 20).
Notation "<( from , to )> -- gmm" := (multi_remove gmm from to) (at level 20).
Notation "<( from , to )> ~~ gmm" := (multi_clear gmm from to) (at level 20).


Definition is_adjancent (gmm: graph_multi_map) from to :=
  <(from,to)> !!! gmm > 0.


Lemma multi_add_increases : forall (gmm : graph_multi_map) from to,
  S (<(from, to)> !!! gmm) = <(from, to)> !!! (<(from,to)> ++ gmm).
Proof.
  intros.
  unfold multi_get, multi_add.
  destruct (from !! gmm).
  - destruct (to !! p); rewrite 2 insert_Some; easy.
  - rewrite 2 insert_Some; easy.
Qed.

Lemma multi_add_adjacent : forall (gmm : graph_multi_map) from to,
  is_adjancent (<(from,to)> ++ gmm) from to.
Proof.
  intros.
  unfold is_adjancent.
  rewrite <- multi_add_increases.
  apply gt_Sn_O.
Qed.

Lemma multi_remove_decreases : forall (gmm : graph_multi_map) from to,
  pred (<(from, to)> !!! gmm) = <(from, to)> !!! (<(from,to)> -- gmm).
Proof.
  intros.
  unfold multi_get, multi_remove.
  destruct (from !! gmm) eqn:H.
  - destruct (to !! p) eqn:H1.
    + rewrite 2 insert_Some.
      easy.
    + rewrite H.
      rewrite H1.
      reflexivity. 
  - rewrite H. easy.
Qed.

Lemma multi_remove_not_adjacent_1 : forall (gmm : graph_multi_map) from to,
  (<(from, to)> !!! gmm) <= 1 -> ~ is_adjancent (<(from,to)> -- gmm) from to.
Proof.
  intros.
  unfold is_adjancent.
  rewrite <- multi_remove_decreases.
  destruct (<(from, to)> !!! gmm); [ | destruct (<(from, to)> !!! gmm)].
  1,2: simpl;unfold not; intros; inversion H0.
  all: inversion H; subst; simpl.
  - contradict H3.
    auto.
  - inversion H3.
  - inversion H.
    subst.
    discriminate H4.
  - inversion H4.
  - inversion H.
    simpl.
    unfold not; intros.
    inversion H0.
    inversion H1.
  - inversion H1. 
Qed.

Lemma multi_remove_adjacent_gt_1 : forall (gmm : graph_multi_map) from to,
  (<(from, to)> !!! gmm) > 1 -> is_adjancent (<(from,to)> -- gmm) from to.
Proof.
  intros.
  unfold is_adjancent.
  rewrite <- multi_remove_decreases.
  destruct (<(from, to)> !!! gmm).
  - inversion H.
  - rewrite pred_Sn.
    simpl.
    apply gt_S_n.
    assumption.
Qed.

Lemma multi_clear_0 : forall (gmm : graph_multi_map) from to,
  0 = <(from, to)> !!! (<(from,to)> ~~ gmm).
Proof.
  intros.
  unfold multi_get, multi_clear.
  destruct (from !! gmm) eqn:H.
  - destruct (to !! p) eqn:H1.
    + rewrite insert_Some.
      rewrite remove_None.
      easy.
    + rewrite H.
      rewrite H1.
      reflexivity. 
  - rewrite H. easy.
Qed.

Lemma multi_clear_not_adjacent : forall (gmm : graph_multi_map) from to,
  ~ is_adjancent (<(from,to)> ~~ gmm) from to.
Proof.
  intros.
  unfold is_adjancent.
  rewrite <- multi_clear_0.
  unfold not; intros.
  inversion H.
Qed.


Definition multi_to_list_sub_list (t : (nat * partial_map nat)) :=
  match t with
  (x, y) => (x, List.filter (fun tpl => match tpl with
                                       | (_, n) => negb (n =? 0)
                                       end)
                                       (to_list y))
  end.

Definition multi_list_flatten (t : (nat * list (nat * nat))) :=
  match t with
  | (n, l) => List.map (fun el => match el with
                                  | (m, k) => (n, m, k)
                                  end) l
  end.

Definition multi_to_list (gmm : graph_multi_map) := 
  concat (List.map multi_list_flatten (List.map multi_to_list_sub_list (to_list gmm))).

Lemma is_adjancent_in_list : forall gmm from to,
  is_adjancent gmm from to -> exists c, In ((from, to), c) (multi_to_list gmm).
Proof.
  intros.
  unfold multi_to_list.

(*
Lemma Lookup_None_iff_

Global Instance pmap_FMap : FMap partial_map.
Proof.
  intros.
  unfold FMap.
  intros.
  apply (@map A B); assumption.
Qed.


Global Instance pmap_Lookup : forall A, Lookup nat A (partial_map A).
Proof.
  unfold Lookup.
  intros.
  destruct X.
  apply o.
  apply H.
Qed.

Global Instance pmap_Empty : forall A, Empty (partial_map A).
Proof.
  unfold Empty.
  intros.
  apply empty_map.
Qed.

Global Instance pmap_palter : forall A, PartialAlter nat A (partial_map A).
Proof.
  unfold PartialAlter.
  intros.
  apply alter; assumption.
Qed.

Global Instance pmap_omap : OMap partial_map.
Proof.
  unfold OMap.
  intros.
  apply (@map_opt A B); assumption.
Qed.

Global Instance pmap_merge : Merge partial_map.
Proof.
  unfold Merge.
  intros.
Admitted.

Global Instance pmap_to_list : forall A, FinMapToList nat A (partial_map A).
Proof.
  intros.
  unfold FinMapToList.
  apply to_list.
Qed.

Global Instance nat_dec : EqDecision nat.
Proof.
  unfold EqDecision.
  intros.
  unfold Decision.
  apply eq_nat_dec.
Qed.

Global Instance pmap : FinMap nat partial_map.
Proof.
  constructor; intros.
*)


    