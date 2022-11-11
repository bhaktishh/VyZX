From VyZX Require Export ZXCore.
From VyZX Require Export Proportional.


Lemma cast_id :
forall {n m} prfn prfm (zx : ZX n m),
  Cast n m prfn prfm zx ∝ zx.
Proof.
intros; subst.
prop_exists_nonzero 1.
rewrite Cast_semantics.
simpl; lma.
Qed.

#[export] Hint Rewrite @cast_id : cast_simpl_db.


Lemma cast_stack_l : forall {nTop nTop' mTop mTop' nBot mBot} eqnTop eqmTop 
                          (zxTop : ZX nTop mTop) (zxBot : ZX nBot mBot),
(Cast nTop' mTop' eqnTop eqmTop zxTop) ↕ zxBot ∝ 
Cast (nTop' + nBot) (mTop' + mBot)  
     (f_equal2_plus _ _ _ _ (eqnTop) eq_refl)
     (f_equal2_plus _ _ _ _ (eqmTop) eq_refl)
     (zxTop ↕ zxBot).
Proof.
intros.
subst.
repeat rewrite cast_id.
reflexivity.
Qed.

Lemma cast_stack_r : forall {nTop mTop nBot nBot' mBot mBot'} eqnBot eqmBot 
                          (zxTop : ZX nTop mTop) (zxBot : ZX nBot mBot),
zxTop ↕ (Cast nBot' mBot' eqnBot eqmBot zxBot) ∝ 
Cast (nTop + nBot') (mTop + mBot')  
     (f_equal2_plus _ _ _ _ eq_refl eqnBot)
     (f_equal2_plus _ _ _ _ eq_refl eqmBot)
     (zxTop ↕ zxBot).
Proof.
intros.
subst.
repeat rewrite cast_id.
reflexivity.
Qed.


#[export] Hint Rewrite @cast_stack_l @cast_stack_r : cast_simpl_db.

Ltac simpl_casts := (autorewrite with cast_simpl_db). 

Lemma cast_contract :
forall {n0 m0 n1 m1 n2 m2} prfn01 prfm01 prfn12 prfm12 (zx : ZX n0 m0),
  Cast n2 m2 prfn12 prfm12 
    (Cast n1 m1 prfn01 prfm01
      zx) ∝
  Cast n2 m2 (eq_trans prfn12 prfn01) (eq_trans prfm12 prfm01) 
    zx.
Proof.
intros; subst.
prop_exists_nonzero 1.
simpl; lma.
Qed.


#[export] Hint Rewrite @cast_contract : cast_simpl_db.

Lemma cast_symm :
forall {n0 m0 n1 m1} prfn prfm prfn' prfm' (zx0 : ZX n0 m0) (zx1 : ZX n1 m1),
  Cast n1 m1 prfn prfm zx0 ∝ zx1 <->
  zx0 ∝ Cast n0 m0 prfn' prfm' zx1.
Proof.
intros.
split; intros.
- subst.
  rewrite cast_id.
  rewrite cast_id in H.
  easy.
- subst.
  rewrite cast_id.
  rewrite cast_id in H.
  easy.
Qed.


Lemma cast_contract_l : forall {n m n0 m0 n1 m1} prfn0 prfm0 prfn1 prfm1 (zx0 : ZX n0 m0) (zx1 : ZX n1 m1),
Cast n m prfn0 prfm0 zx0 ∝ Cast n m prfn1 prfm1 zx1 <->
Cast n1 m1 (eq_trans (eq_sym prfn1) prfn0) (eq_trans (eq_sym prfm1) prfm0) zx0 ∝ zx1.
Proof.
intros; split; intros.
- rewrite <- cast_symm in H.
  rewrite cast_contract in H.
  exact H.
- rewrite <- cast_symm.
  rewrite cast_contract.
  exact H.
Qed.

#[export] Hint Rewrite @cast_contract_l : cast_simpl_db.


Lemma cast_contract_r : forall {n m n0 m0 n1 m1} prfn0 prfm0 prfn1 prfm1 (zx0 : ZX n0 m0) (zx1 : ZX n1 m1),
Cast n m prfn0 prfm0 zx0 ∝ Cast n m prfn1 prfm1 zx1 <->
zx0 ∝ Cast n0 m0 (eq_trans (eq_sym prfn0) prfn1) (eq_trans (eq_sym prfm0) prfm1) zx1.
Proof.
intros; split; intros.
- rewrite cast_symm in H.
  rewrite cast_contract in H.
  exact H.
- rewrite cast_symm.
  rewrite cast_contract.
  exact H.
Qed.

Lemma cast_simplify :
forall {n n' m m'} prfn0 prfm0 prfn1 prfm1  (zx0 zx1 : ZX n m),
zx0 ∝ zx1 ->
Cast n' m' prfn0 prfm0 zx0 ∝ Cast n' m' prfn1 prfm1 zx1.
Proof.
intros.
simpl_casts.
easy.
Qed.

Lemma cast_backwards :
forall {n0 m0 n1 m1} prfn prfm prfn' prfm' (zx0 : ZX n0 m0) (zx1 : ZX n1 m1),
  Cast n1 m1 prfn prfm zx0 ∝ zx1 <->
  Cast n0 m0 prfn' prfm' zx1 ∝ zx0.
Proof.
intros.
split; symmetry; subst;
simpl_casts; [rewrite H | rewrite <- H]; 
simpl_casts; easy.
Qed.
