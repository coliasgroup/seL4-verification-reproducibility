(set-option :produce-models true)
(set-logic QF_AUFBV)
(define-fun load-word32 ((m (Array (_ BitVec 30) (_ BitVec 32))) (p (_ BitVec 32)))
	(_ BitVec 32)
(select m ((_ extract 31 2) p)))
(define-fun store-word32 ((m (Array (_ BitVec 30) (_ BitVec 32))) (p (_ BitVec 32)) (v (_ BitVec 32)))
	(Array (_ BitVec 30) (_ BitVec 32))
(store m ((_ extract 31 2) p) v))
(define-fun load-word64 ((m (Array (_ BitVec 30) (_ BitVec 32))) (p (_ BitVec 32)))
	(_ BitVec 64)
(bvor ((_ zero_extend 32) (load-word32 m p))
	(bvshl ((_ zero_extend 32)
		(load-word32 m (bvadd p #x00000004))) #x0000000000000020)))
(define-fun store-word64 ((m (Array (_ BitVec 30) (_ BitVec 32))) (p (_ BitVec 32)) (v (_ BitVec 64)))
        (Array (_ BitVec 30) (_ BitVec 32))
(store-word32 (store-word32 m p ((_ extract 31 0) v))
	(bvadd p #x00000004) ((_ extract 63 32) v)))
(define-fun word8-shift ((p (_ BitVec 32))) (_ BitVec 32)
(bvshl ((_ zero_extend 30) ((_ extract 1 0) p)) #x00000003))
(define-fun word8-get ((p (_ BitVec 32)) (x (_ BitVec 32))) (_ BitVec 8)
((_ extract 7 0) (bvlshr x (word8-shift p))))
(define-fun load-word8 ((m (Array (_ BitVec 30) (_ BitVec 32))) (p (_ BitVec 32))) (_ BitVec 8)
(word8-get p (load-word32 m p)))
(define-fun word8-put ((p (_ BitVec 32)) (x (_ BitVec 32)) (y (_ BitVec 8)))
  (_ BitVec 32) (bvor (bvshl ((_ zero_extend 24) y) (word8-shift p))
	(bvand x (bvnot (bvshl #x000000FF (word8-shift p))))))
(define-fun store-word8 ((m (Array (_ BitVec 30) (_ BitVec 32))) (p (_ BitVec 32)) (v (_ BitVec 8)))
	(Array (_ BitVec 30) (_ BitVec 32))
(store-word32 m p (word8-put p (load-word32 m p) v)))
(define-fun mem-dom ((p (_ BitVec 32)) (d (Array (_ BitVec 32) (_ BitVec 1)))) Bool
(not (= (select d p) #b0)))
(define-fun mem-eq ((x (Array (_ BitVec 30) (_ BitVec 32))) (y (Array (_ BitVec 30) (_ BitVec 32)))) Bool (= x y))
(define-fun word32-eq ((x (_ BitVec 32)) (y (_ BitVec 32)))
    Bool (= x y))
(define-fun word2-xor-scramble ((a (_ BitVec 2)) (x (_ BitVec 2))
   (b (_ BitVec 2)) (c (_ BitVec 2)) (y (_ BitVec 2)) (d (_ BitVec 2))) Bool
(bvult (bvadd (bvxor a x) b) (bvadd (bvxor c y) d)))
(declare-fun unspecified-precond () Bool)
(declare-fun rodata-witness () (_ BitVec 32))
(declare-fun rodata-witness-val () (_ BitVec 32))
(assert (or (and (bvule #xe0004414 rodata-witness) (bvule rodata-witness #xe000444b)) (and (bvule #xe001b37c rodata-witness) (bvule rodata-witness #xe001b46b))))
(assert (= (bvand rodata-witness #x00000003) #x00000000))
(define-fun rodata ((m (Array (_ BitVec 30) (_ BitVec 32)))) Bool (and (= (load-word32 m #xe001b380) #x00000001) 
  (= (load-word32 m #xe001b3c0) #x00000000) 
  (= (load-word32 m #xe001b384) #x00000002) 
  (= (load-word32 m #xe001b388) #x00000003) 
  (= (load-word32 m #xe001b3ac) #x00000011) 
  (= (load-word32 m #xe001b38c) #x00000004) 
  (= (load-word32 m #xe001b444) #x0000000e) 
  (= (load-word32 m #xe001b390) #x00000005) 
  (= (load-word32 m #xe0004418) #x2ff00000) 
  (= (load-word32 m #xe001b394) #x00000006) 
  (= (load-word32 m #xe001b408) #x0000000d) 
  (= (load-word32 m #xe001b398) #x00000007) 
  (= (load-word32 m #xe001b3c4) #x00000000) 
  (= (load-word32 m #xe001b45c) #xfff02600) 
  (= (load-word32 m #xe000441c) #x00a01000) 
  (= (load-word32 m #xe001b404) #x00000011) 
  (= (load-word32 m #xe0004420) #xfff01000) 
  (= (load-word32 m #xe001b3b0) #x0000000d) 
  (= (load-word32 m #xe0004424) #x00000001) 
  (= (load-word32 m #xe001b400) #x00000049) 
  (= (load-word32 m #xe0004428) #x00000000) 
  (= (load-word32 m #xe001b39c) #x00000011) 
  (= (load-word32 m #xe001b454) #xe0010000) 
  (= (load-word32 m #xe001b468) #xfff01000) 
  (= (load-word32 m #xe000442c) #x00a00000) 
  (= (load-word32 m #xe001b3fc) #x00000001) 
  (= (load-word32 m #xe001b43c) #x00000006) 
  (= (load-word32 m #xe0004430) #xfff02000) 
  (= (load-word32 m #xe001b3c8) #x00000000) 
  (= (load-word32 m #xe0004434) #x00000001) 
  (= (load-word32 m #xe001b440) #x00000007) 
  (= (load-word32 m #xe001b438) #x00000005) 
  (= (load-word32 m #xe0004438) #x00000000) 
  (= (load-word32 m #xe001b3b4) #x00000010) 
  (= (load-word32 m #xe000443c) #x00a02000) 
  (= (load-word32 m #xe001b44c) #x00000013) 
  (= (load-word32 m #xe001b434) #x00000004) 
  (= (load-word32 m #xe0004440) #xfff03000) 
  (= (load-word32 m #xe001b3a0) #x0000000d) 
  (= (load-word32 m #xe0004444) #x00000001) 
  (= (load-word32 m #xe001b458) #x00000003) 
  (= (load-word32 m #xe001b430) #x00000003) 
  (= (load-word32 m #xe0004448) #x00000000) 
  (= (load-word32 m #xe001b40c) #x00000010) 
  (= (load-word32 m #xe001b3cc) #x00000000) 
  (= (load-word32 m #xe001b42c) #x00000002) 
  (= (load-word32 m #xe001b3d0) #x00000000) 
  (= (load-word32 m #xe001b3b8) #x00000000) 
  (= (load-word32 m #xe001b464) #xfff02100) 
  (= (load-word32 m #xe001b3d4) #x00000000) 
  (= (load-word32 m #xe001b428) #x0000000c) 
  (= (load-word32 m #xe001b3d8) #x00000000) 
  (= (load-word32 m #xe001b3a4) #x0000000e) 
  (= (load-word32 m #xe001b3dc) #x00000002) 
  (= (load-word32 m #xe001b424) #x0000000b) 
  (= (load-word32 m #xe001b3e0) #x00000003) 
  (= (load-word32 m #xe001b410) #x00000000) 
  (= (load-word32 m #xe001b3e4) #x00000004) 
  (= (load-word32 m #xe001b448) #x00000012) 
  (= (load-word32 m #xe001b420) #x0000000a) 
  (= (load-word32 m #xe001b3e8) #x00000005) 
  (= (load-word32 m #xe001b3bc) #x00000000) 
  (= (load-word32 m #xe001b3ec) #x00000000) 
  (= (load-word32 m #xe001b41c) #x00000009) 
  (= (load-word32 m #xe001b3f0) #x0000000f) 
  (= (load-word32 m #xe001b3a8) #x00000010) 
  (= (load-word32 m #xe001b450) #xe0000000) 
  (= (load-word32 m #xe001b3f4) #x00000002) 
  (= (load-word32 m #xe001b418) #x00000008) 
  (= (load-word32 m #xe001b3f8) #x0000002a) 
  (= (load-word32 m #xe0004414) #x10000000) 
  (= (load-word32 m #xe001b460) #xfff03000) 
  (= (load-word32 m #xe001b37c) #x00000000) 
  (= (load-word32 m #xe001b414) #x00000001) 
  (= (load-word32 m rodata-witness) rodata-witness-val)))
(define-fun implies-rodata ((m (Array (_ BitVec 30) (_ BitVec 32)))) Bool (= (load-word32 m rodata-witness) rodata-witness-val))
(declare-fun ptr_dst___ptr_to_void_v_init () (_ BitVec 32))
(declare-fun ptr_src___ptr_to_void_v_init () (_ BitVec 32))
(declare-fun n___unsigned_long_v_init () (_ BitVec 32))
(declare-fun Mem_init () (Array (_ BitVec 30) (_ BitVec 32)))
(declare-fun GhostAssertions_init () (Array (_ BitVec 50) (_ BitVec 32)))
(declare-fun ret_init () (_ BitVec 32))
(declare-fun r0_init () (_ BitVec 32))
(declare-fun r1_init () (_ BitVec 32))
(declare-fun r2_init () (_ BitVec 32))
(declare-fun r3_init () (_ BitVec 32))
(declare-fun r4_init () (_ BitVec 32))
(declare-fun r5_init () (_ BitVec 32))
(declare-fun r6_init () (_ BitVec 32))
(declare-fun r7_init () (_ BitVec 32))
(declare-fun r8_init () (_ BitVec 32))
(declare-fun r9_init () (_ BitVec 32))
(declare-fun r10_init () (_ BitVec 32))
(declare-fun r11_init () (_ BitVec 32))
(declare-fun r12_init () (_ BitVec 32))
(declare-fun r13_init () (_ BitVec 32))
(declare-fun r14_init () (_ BitVec 32))
(declare-fun r15_init () (_ BitVec 32))
(declare-fun r16_init () (_ BitVec 32))
(declare-fun r17_init () (_ BitVec 32))
(declare-fun r18_init () (_ BitVec 32))
(declare-fun r19_init () (_ BitVec 32))
(declare-fun r20_init () (_ BitVec 32))
(declare-fun r21_init () (_ BitVec 32))
(declare-fun r22_init () (_ BitVec 32))
(declare-fun r23_init () (_ BitVec 32))
(declare-fun r24_init () (_ BitVec 32))
(declare-fun r25_init () (_ BitVec 32))
(declare-fun r26_init () (_ BitVec 32))
(declare-fun r27_init () (_ BitVec 32))
(declare-fun r28_init () (_ BitVec 32))
(declare-fun r29_init () (_ BitVec 32))
(declare-fun r30_init () (_ BitVec 32))
(declare-fun r31_init () (_ BitVec 32))
(declare-fun mode_init () (_ BitVec 32))
(declare-fun n_init () Bool)
(declare-fun z_init () Bool)
(declare-fun c_init () Bool)
(declare-fun v_init () Bool)
(declare-fun mem_init () (Array (_ BitVec 30) (_ BitVec 32)))
(declare-fun dom_init () (Array (_ BitVec 32) (_ BitVec 1)))
(declare-fun stack_init () (Array (_ BitVec 30) (_ BitVec 32)))
(declare-fun dom_stack_init () (Array (_ BitVec 32) (_ BitVec 1)))
(declare-fun clock_init () (_ BitVec 64))
(declare-fun ret_addr_input_init () (_ BitVec 32))
(define-fun path_cond_to_26_ASM () Bool true)
(define-fun v_after_26 () Bool false)
(define-fun c_after_26 () Bool (not (= (bvand (bvadd (bvadd ((_ zero_extend 32) r2_init) ((_ zero_extend 32) #xffffffff)) #x0000000000000001) #x0000000100000000) #x0000000000000000)))
(define-fun z_after_26 () Bool (word32-eq r2_init #x00000000))
(define-fun n_after_26 () Bool (not (word32-eq (bvand r2_init #x80000000) #x00000000)))
(define-fun cond_at_29 () Bool z_after_26)
(define-fun path_cond_to_19_ASM () Bool (and (not cond_at_29) path_cond_to_26_ASM))
(define-fun r1_after_31 () (_ BitVec 32) (bvadd r1_init #xffffffff))
(define-fun r2_after_33 () (_ BitVec 32) (bvadd r0_init r2_init))
(define-fun query_mem-eqmem_initMem_in () Bool (mem-eq mem_init Mem_init))
(define-fun query_rodataMem_init () Bool (rodata Mem_init))
(define-fun path_cond_to_15_C () Bool true)
(define-fun loop_4_count_after_6 () (_ BitVec 32) #x00000000)
(define-fun cond_at_17_17=0 () Bool true)
(define-fun path_cond_to_22_17=1_ASM () Bool (and cond_at_17_17=0 path_cond_to_19_ASM))
(define-fun query_bvaddr1_after_31_x00 () (_ BitVec 32) (bvadd r1_after_31 #x00000001))
(define-fun query_load-word8mem_initbv () (_ BitVec 8) (load-word8 mem_init (bvadd r1_after_31 #x00000001)))
(define-fun r12_after_22_17=1 () (_ BitVec 32) ((_ zero_extend 24) (load-word8 mem_init (bvadd r1_after_31 #x00000001))))
(define-fun r1_after_22_17=1 () (_ BitVec 32) (bvadd r1_after_31 #x00000001))
(define-fun cond_at_20_17=1 () Bool true)
(define-fun path_cond_to_24_17=1_ASM () Bool (and cond_at_20_17=1 path_cond_to_22_17=1_ASM))
(define-fun query_bvandr0_init_xffffff () (_ BitVec 32) (bvand r0_init #xfffffffd))
(define-fun query_load-word32mem_initb () (_ BitVec 32) (load-word32 mem_init (bvand r0_init #xfffffffd)))
(define-fun mem_after_24_17=1 () (Array (_ BitVec 30) (_ BitVec 32)) (store-word8 mem_init r0_init ((_ extract 7 0) r12_after_22_17=1)))
(define-fun r3_after_24_17=1 () (_ BitVec 32) (bvadd r0_init #x00000001))
(define-fun v_after_23_17=1 () Bool (and (= (not (word32-eq (bvand r3_after_24_17=1 #x80000000) #x00000000)) (word32-eq (bvand r2_after_33 #x80000000) #x00000000)) (not (= (not (word32-eq (bvand r3_after_24_17=1 #x80000000) #x00000000)) (not (word32-eq (bvand (bvsub r3_after_24_17=1 r2_after_33) #x80000000) #x00000000))))))
(define-fun c_after_23_17=1 () Bool (not (= (bvand (bvadd (bvadd ((_ zero_extend 32) r3_after_24_17=1) ((_ zero_extend 32) (bvnot r2_after_33))) #x0000000000000001) #x0000000100000000) #x0000000000000000)))
(define-fun z_after_23_17=1 () Bool (word32-eq r3_after_24_17=1 r2_after_33))
(define-fun n_after_23_17=1 () Bool (not (word32-eq (bvand (bvsub r3_after_24_17=1 r2_after_33) #x80000000) #x00000000)))
(define-fun cond_at_35_17=1 () Bool (not z_after_23_17=1))
(define-fun path_cond_to_25_17=1_ASM () Bool (and cond_at_35_17=1 path_cond_to_24_17=1_ASM))
(define-fun cond_at_17_17=1 () Bool true)
(define-fun path_cond_to_22_17=2_ASM () Bool (and cond_at_17_17=1 path_cond_to_25_17=1_ASM))
(define-fun query_bvaddr1_after_22_17= () (_ BitVec 32) (bvadd r1_after_22_17=1 #x00000001))
(define-fun query_load-word8mem_after_ () (_ BitVec 8) (load-word8 mem_after_24_17=1 (bvadd r1_after_22_17=1 #x00000001)))
(define-fun r12_after_22_17=2 () (_ BitVec 32) ((_ zero_extend 24) (load-word8 mem_after_24_17=1 (bvadd r1_after_22_17=1 #x00000001))))
(define-fun r1_after_22_17=2 () (_ BitVec 32) (bvadd r1_after_22_17=1 #x00000001))
(define-fun cond_at_20_17=2 () Bool true)
(define-fun path_cond_to_24_17=2_ASM () Bool (and cond_at_20_17=2 path_cond_to_22_17=2_ASM))
(define-fun query_bvandr3_after_24_17= () (_ BitVec 32) (bvand r3_after_24_17=1 #xfffffffd))
(define-fun query_load-word32mem_after () (_ BitVec 32) (load-word32 mem_after_24_17=1 (bvand r3_after_24_17=1 #xfffffffd)))
(define-fun mem_after_24_17=2 () (Array (_ BitVec 30) (_ BitVec 32)) (store-word8 mem_after_24_17=1 r3_after_24_17=1 ((_ extract 7 0) r12_after_22_17=2)))
(define-fun r3_after_24_17=2 () (_ BitVec 32) (bvadd r3_after_24_17=1 #x00000001))
(define-fun v_after_23_17=2 () Bool (and (= (not (word32-eq (bvand r3_after_24_17=2 #x80000000) #x00000000)) (word32-eq (bvand r2_after_33 #x80000000) #x00000000)) (not (= (not (word32-eq (bvand r3_after_24_17=2 #x80000000) #x00000000)) (not (word32-eq (bvand (bvsub r3_after_24_17=2 r2_after_33) #x80000000) #x00000000))))))
(define-fun c_after_23_17=2 () Bool (not (= (bvand (bvadd (bvadd ((_ zero_extend 32) r3_after_24_17=2) ((_ zero_extend 32) (bvnot r2_after_33))) #x0000000000000001) #x0000000100000000) #x0000000000000000)))
(define-fun z_after_23_17=2 () Bool (word32-eq r3_after_24_17=2 r2_after_33))
(define-fun n_after_23_17=2 () Bool (not (word32-eq (bvand (bvsub r3_after_24_17=2 r2_after_33) #x80000000) #x00000000)))
(define-fun cond_at_35_17=2 () Bool (not z_after_23_17=2))
(define-fun path_cond_to_25_17=2_ASM () Bool (and cond_at_35_17=2 path_cond_to_24_17=2_ASM))
(define-fun cond_at_17_17=2 () Bool true)
(define-fun path_cond_to_22_17=3_ASM () Bool (and cond_at_17_17=2 path_cond_to_25_17=2_ASM))
(define-fun query_bvaddr1_after_22_17=.1 () (_ BitVec 32) (bvadd r1_after_22_17=2 #x00000001))
(define-fun query_load-word8mem_after_.1 () (_ BitVec 8) (load-word8 mem_after_24_17=2 (bvadd r1_after_22_17=2 #x00000001)))
(define-fun r12_after_22_17=3 () (_ BitVec 32) ((_ zero_extend 24) (load-word8 mem_after_24_17=2 (bvadd r1_after_22_17=2 #x00000001))))
(define-fun r1_after_22_17=3 () (_ BitVec 32) (bvadd r1_after_22_17=2 #x00000001))
(define-fun cond_at_20_17=3 () Bool true)
(define-fun path_cond_to_24_17=3_ASM () Bool (and cond_at_20_17=3 path_cond_to_22_17=3_ASM))
(define-fun cond_at_5_4=1 () Bool (not (word32-eq n___unsigned_long_v_init #x00000000)))
(define-fun path_cond_to_13_4=1_C () Bool (and cond_at_5_4=1 path_cond_to_15_C))
(define-fun ptr () (_ BitVec 32) #xe0004414)
(declare-fun pvalid () Bool)
(assert (=> pvalid (and (not (word32-eq ptr #x00000000)) (=> (bvult #x00000000 #x00000038) (bvule ptr (bvsub #x00000000 #x00000038))))))
(assert pvalid)
(define-fun ptr.1 () (_ BitVec 32) #xe001b37c)
(declare-fun pvalid.1 () Bool)
(assert (=> pvalid.1 (and (not (word32-eq ptr.1 #x00000000)) (=> (bvult #x00000000 #x000000f0) (bvule ptr.1 (bvsub #x00000000 #x000000f0))))))
(assert (=> (and pvalid.1 pvalid) (or false (or false (or (bvult (bvadd ptr.1 (bvsub #x000000f0 #x00000001)) ptr) (bvult (bvadd ptr (bvsub #x00000038 #x00000001)) ptr.1))))))
(assert (and (=> (and false pvalid) pvalid.1) (=> (and false pvalid.1) pvalid)))
(assert pvalid.1)
(define-fun ptr.2 () (_ BitVec 32) ptr_dst___ptr_to_void_v_init)
(declare-fun pvalid.2 () Bool)
(assert (=> pvalid.2 (and (not (word32-eq ptr.2 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule ptr.2 (bvsub #x00000000 #x00000001))))))
(assert (=> (and pvalid.2 pvalid) (or false (or false (or (bvult (bvadd ptr.2 (bvsub #x00000001 #x00000001)) ptr) (bvult (bvadd ptr (bvsub #x00000038 #x00000001)) ptr.2))))))
(assert (and (=> (and false pvalid) pvalid.2) (=> (and false pvalid.2) pvalid)))
(assert (=> (and pvalid.2 pvalid.1) (or false (or false (or (bvult (bvadd ptr.2 (bvsub #x00000001 #x00000001)) ptr.1) (bvult (bvadd ptr.1 (bvsub #x000000f0 #x00000001)) ptr.2))))))
(assert (and (=> (and false pvalid.1) pvalid.2) (=> (and false pvalid.2) pvalid.1)))
(define-fun ptr.3 () (_ BitVec 32) ptr_src___ptr_to_void_v_init)
(declare-fun pvalid.3 () Bool)
(assert (=> pvalid.3 (and (not (word32-eq ptr.3 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule ptr.3 (bvsub #x00000000 #x00000001))))))
(assert (=> (and pvalid.3 pvalid) (or false (or false (or (bvult (bvadd ptr.3 (bvsub #x00000001 #x00000001)) ptr) (bvult (bvadd ptr (bvsub #x00000038 #x00000001)) ptr.3))))))
(assert (and (=> (and false pvalid) pvalid.3) (=> (and false pvalid.3) pvalid)))
(assert (=> (and pvalid.3 pvalid.1) (or false (or false (or (bvult (bvadd ptr.3 (bvsub #x00000001 #x00000001)) ptr.1) (bvult (bvadd ptr.1 (bvsub #x000000f0 #x00000001)) ptr.3))))))
(assert (and (=> (and false pvalid.1) pvalid.3) (=> (and false pvalid.3) pvalid.1)))
(define-fun cond_at_13_4=1 () Bool (and (and pvalid.2 (and (not (word32-eq ptr_dst___ptr_to_void_v_init #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule ptr_dst___ptr_to_void_v_init (bvsub #x00000000 #x00000001))))) (and pvalid.3 (and (not (word32-eq ptr_src___ptr_to_void_v_init #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule ptr_src___ptr_to_void_v_init (bvsub #x00000000 #x00000001)))))))
(define-fun path_cond_to_12_4=1_C () Bool (and cond_at_13_4=1 path_cond_to_13_4=1_C))
(define-fun query_ptr_src___ptr_to_voi () (_ BitVec 32) ptr_src___ptr_to_void_v_init)
(define-fun query_load-word8Mem_initpt () (_ BitVec 8) (load-word8 Mem_init ptr_src___ptr_to_void_v_init))
(define-fun query_bvandptr_dst___ptr_t () (_ BitVec 32) (bvand ptr_dst___ptr_to_void_v_init #xfffffffd))
(define-fun query_load-word32Mem_initb () (_ BitVec 32) (load-word32 Mem_init (bvand ptr_dst___ptr_to_void_v_init #xfffffffd)))
(define-fun Mem_after_12_4=1 () (Array (_ BitVec 30) (_ BitVec 32)) (store-word8 Mem_init ptr_dst___ptr_to_void_v_init (load-word8 Mem_init ptr_src___ptr_to_void_v_init)))
(define-fun n___unsigned_long_v_after_11_4=1 () (_ BitVec 32) (bvsub n___unsigned_long_v_init #x00000001))
(define-fun p___ptr_to_unsigned_char_v_after_9_4=1 () (_ BitVec 32) (bvadd ptr_dst___ptr_to_void_v_init #x00000001))
(define-fun q___ptr_to_unsigned_char_v_after_7_4=1 () (_ BitVec 32) (bvadd ptr_src___ptr_to_void_v_init #x00000001))
(define-fun loop_4_count_after_3_4=1 () (_ BitVec 32) (bvadd loop_4_count_after_6 #x00000001))
(define-fun cond_at_5_4=2 () Bool (not (word32-eq n___unsigned_long_v_after_11_4=1 #x00000000)))
(define-fun path_cond_to_13_4=2_C () Bool (and cond_at_5_4=2 path_cond_to_12_4=1_C))
(define-fun ptr.4 () (_ BitVec 32) p___ptr_to_unsigned_char_v_after_9_4=1)
(declare-fun pvalid.4 () Bool)
(assert (=> pvalid.4 (and (not (word32-eq ptr.4 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule ptr.4 (bvsub #x00000000 #x00000001))))))
(assert (=> (and pvalid.4 pvalid) (or false (or false (or (bvult (bvadd ptr.4 (bvsub #x00000001 #x00000001)) ptr) (bvult (bvadd ptr (bvsub #x00000038 #x00000001)) ptr.4))))))
(assert (and (=> (and false pvalid) pvalid.4) (=> (and false pvalid.4) pvalid)))
(assert (=> (and pvalid.4 pvalid.1) (or false (or false (or (bvult (bvadd ptr.4 (bvsub #x00000001 #x00000001)) ptr.1) (bvult (bvadd ptr.1 (bvsub #x000000f0 #x00000001)) ptr.4))))))
(assert (and (=> (and false pvalid.1) pvalid.4) (=> (and false pvalid.4) pvalid.1)))
(define-fun ptr.5 () (_ BitVec 32) q___ptr_to_unsigned_char_v_after_7_4=1)
(declare-fun pvalid.5 () Bool)
(assert (=> pvalid.5 (and (not (word32-eq ptr.5 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule ptr.5 (bvsub #x00000000 #x00000001))))))
(assert (=> (and pvalid.5 pvalid) (or false (or false (or (bvult (bvadd ptr.5 (bvsub #x00000001 #x00000001)) ptr) (bvult (bvadd ptr (bvsub #x00000038 #x00000001)) ptr.5))))))
(assert (and (=> (and false pvalid) pvalid.5) (=> (and false pvalid.5) pvalid)))
(assert (=> (and pvalid.5 pvalid.1) (or false (or false (or (bvult (bvadd ptr.5 (bvsub #x00000001 #x00000001)) ptr.1) (bvult (bvadd ptr.1 (bvsub #x000000f0 #x00000001)) ptr.5))))))
(assert (and (=> (and false pvalid.1) pvalid.5) (=> (and false pvalid.5) pvalid.1)))
(define-fun cond_at_13_4=2 () Bool (and (and pvalid.4 (and (not (word32-eq p___ptr_to_unsigned_char_v_after_9_4=1 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule p___ptr_to_unsigned_char_v_after_9_4=1 (bvsub #x00000000 #x00000001))))) (and pvalid.5 (and (not (word32-eq q___ptr_to_unsigned_char_v_after_7_4=1 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule q___ptr_to_unsigned_char_v_after_7_4=1 (bvsub #x00000000 #x00000001)))))))
(define-fun path_cond_to_12_4=2_C () Bool (and cond_at_13_4=2 path_cond_to_13_4=2_C))
(define-fun query_q___ptr_to_unsigned_ () (_ BitVec 32) q___ptr_to_unsigned_char_v_after_7_4=1)
(define-fun query_load-word8Mem_after_ () (_ BitVec 8) (load-word8 Mem_after_12_4=1 q___ptr_to_unsigned_char_v_after_7_4=1))
(define-fun query_bvandp___ptr_to_unsi () (_ BitVec 32) (bvand p___ptr_to_unsigned_char_v_after_9_4=1 #xfffffffd))
(define-fun query_load-word32Mem_after () (_ BitVec 32) (load-word32 Mem_after_12_4=1 (bvand p___ptr_to_unsigned_char_v_after_9_4=1 #xfffffffd)))
(define-fun Mem_after_12_4=2 () (Array (_ BitVec 30) (_ BitVec 32)) (store-word8 Mem_after_12_4=1 p___ptr_to_unsigned_char_v_after_9_4=1 (load-word8 Mem_after_12_4=1 q___ptr_to_unsigned_char_v_after_7_4=1)))
(define-fun n___unsigned_long_v_after_11_4=2 () (_ BitVec 32) (bvsub n___unsigned_long_v_after_11_4=1 #x00000001))
(define-fun p___ptr_to_unsigned_char_v_after_9_4=2 () (_ BitVec 32) (bvadd p___ptr_to_unsigned_char_v_after_9_4=1 #x00000001))
(define-fun q___ptr_to_unsigned_char_v_after_7_4=2 () (_ BitVec 32) (bvadd q___ptr_to_unsigned_char_v_after_7_4=1 #x00000001))
(define-fun loop_4_count_after_3_4=2 () (_ BitVec 32) (bvadd loop_4_count_after_3_4=1 #x00000001))
(define-fun cond_at_5_4=3 () Bool (not (word32-eq n___unsigned_long_v_after_11_4=2 #x00000000)))
(define-fun path_cond_to_13_4=3_C () Bool (and cond_at_5_4=3 path_cond_to_12_4=2_C))
(define-fun ptr.6 () (_ BitVec 32) p___ptr_to_unsigned_char_v_after_9_4=2)
(declare-fun pvalid.6 () Bool)
(assert (=> pvalid.6 (and (not (word32-eq ptr.6 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule ptr.6 (bvsub #x00000000 #x00000001))))))
(assert (=> (and pvalid.6 pvalid.1) (or false (or false (or (bvult (bvadd ptr.6 (bvsub #x00000001 #x00000001)) ptr.1) (bvult (bvadd ptr.1 (bvsub #x000000f0 #x00000001)) ptr.6))))))
(assert (and (=> (and false pvalid.1) pvalid.6) (=> (and false pvalid.6) pvalid.1)))
(assert (=> (and pvalid.6 pvalid) (or false (or false (or (bvult (bvadd ptr.6 (bvsub #x00000001 #x00000001)) ptr) (bvult (bvadd ptr (bvsub #x00000038 #x00000001)) ptr.6))))))
(assert (and (=> (and false pvalid) pvalid.6) (=> (and false pvalid.6) pvalid)))
(define-fun ptr.7 () (_ BitVec 32) q___ptr_to_unsigned_char_v_after_7_4=2)
(declare-fun pvalid.7 () Bool)
(assert (=> pvalid.7 (and (not (word32-eq ptr.7 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule ptr.7 (bvsub #x00000000 #x00000001))))))
(assert (=> (and pvalid.7 pvalid.1) (or false (or false (or (bvult (bvadd ptr.7 (bvsub #x00000001 #x00000001)) ptr.1) (bvult (bvadd ptr.1 (bvsub #x000000f0 #x00000001)) ptr.7))))))
(assert (and (=> (and false pvalid.1) pvalid.7) (=> (and false pvalid.7) pvalid.1)))
(assert (=> (and pvalid.7 pvalid) (or false (or false (or (bvult (bvadd ptr.7 (bvsub #x00000001 #x00000001)) ptr) (bvult (bvadd ptr (bvsub #x00000038 #x00000001)) ptr.7))))))
(assert (and (=> (and false pvalid) pvalid.7) (=> (and false pvalid.7) pvalid)))
(define-fun cond_at_13_4=3 () Bool (and (and pvalid.6 (and (not (word32-eq p___ptr_to_unsigned_char_v_after_9_4=2 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule p___ptr_to_unsigned_char_v_after_9_4=2 (bvsub #x00000000 #x00000001))))) (and pvalid.7 (and (not (word32-eq q___ptr_to_unsigned_char_v_after_7_4=2 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule q___ptr_to_unsigned_char_v_after_7_4=2 (bvsub #x00000000 #x00000001)))))))
(define-fun path_cond_to_12_4=3_C () Bool (and cond_at_13_4=3 path_cond_to_13_4=3_C))
(define-fun query_q___ptr_to_unsigned_.1 () (_ BitVec 32) q___ptr_to_unsigned_char_v_after_7_4=2)
(define-fun query_load-word8Mem_after_.1 () (_ BitVec 8) (load-word8 Mem_after_12_4=2 q___ptr_to_unsigned_char_v_after_7_4=2))
(define-fun query_bvandp___ptr_to_unsi.1 () (_ BitVec 32) (bvand p___ptr_to_unsigned_char_v_after_9_4=2 #xfffffffd))
(define-fun query_load-word32Mem_after.1 () (_ BitVec 32) (load-word32 Mem_after_12_4=2 (bvand p___ptr_to_unsigned_char_v_after_9_4=2 #xfffffffd)))
(define-fun Mem_after_12_4=3 () (Array (_ BitVec 30) (_ BitVec 32)) (store-word8 Mem_after_12_4=2 p___ptr_to_unsigned_char_v_after_9_4=2 (load-word8 Mem_after_12_4=2 q___ptr_to_unsigned_char_v_after_7_4=2)))
(define-fun n___unsigned_long_v_after_11_4=3 () (_ BitVec 32) (bvsub n___unsigned_long_v_after_11_4=2 #x00000001))
(define-fun p___ptr_to_unsigned_char_v_after_9_4=3 () (_ BitVec 32) (bvadd p___ptr_to_unsigned_char_v_after_9_4=2 #x00000001))
(define-fun q___ptr_to_unsigned_char_v_after_7_4=3 () (_ BitVec 32) (bvadd q___ptr_to_unsigned_char_v_after_7_4=2 #x00000001))
(define-fun loop_4_count_after_3_4=3 () (_ BitVec 32) (bvadd loop_4_count_after_3_4=2 #x00000001))
(define-fun cond_at_5_4=4 () Bool (not (word32-eq n___unsigned_long_v_after_11_4=3 #x00000000)))
(define-fun path_cond_to_13_4=4_C () Bool (and cond_at_5_4=4 path_cond_to_12_4=3_C))
(define-fun ptr.8 () (_ BitVec 32) p___ptr_to_unsigned_char_v_after_9_4=3)
(declare-fun pvalid.8 () Bool)
(assert (=> pvalid.8 (and (not (word32-eq ptr.8 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule ptr.8 (bvsub #x00000000 #x00000001))))))
(assert (=> (and pvalid.8 pvalid.1) (or false (or false (or (bvult (bvadd ptr.8 (bvsub #x00000001 #x00000001)) ptr.1) (bvult (bvadd ptr.1 (bvsub #x000000f0 #x00000001)) ptr.8))))))
(assert (and (=> (and false pvalid.1) pvalid.8) (=> (and false pvalid.8) pvalid.1)))
(assert (=> (and pvalid.8 pvalid) (or false (or false (or (bvult (bvadd ptr.8 (bvsub #x00000001 #x00000001)) ptr) (bvult (bvadd ptr (bvsub #x00000038 #x00000001)) ptr.8))))))
(assert (and (=> (and false pvalid) pvalid.8) (=> (and false pvalid.8) pvalid)))
(define-fun ptr.9 () (_ BitVec 32) q___ptr_to_unsigned_char_v_after_7_4=3)
(declare-fun pvalid.9 () Bool)
(assert (=> pvalid.9 (and (not (word32-eq ptr.9 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule ptr.9 (bvsub #x00000000 #x00000001))))))
(assert (=> (and pvalid.9 pvalid.1) (or false (or false (or (bvult (bvadd ptr.9 (bvsub #x00000001 #x00000001)) ptr.1) (bvult (bvadd ptr.1 (bvsub #x000000f0 #x00000001)) ptr.9))))))
(assert (and (=> (and false pvalid.1) pvalid.9) (=> (and false pvalid.9) pvalid.1)))
(assert (=> (and pvalid.9 pvalid) (or false (or false (or (bvult (bvadd ptr.9 (bvsub #x00000001 #x00000001)) ptr) (bvult (bvadd ptr (bvsub #x00000038 #x00000001)) ptr.9))))))
(assert (and (=> (and false pvalid) pvalid.9) (=> (and false pvalid.9) pvalid)))
(define-fun cond_at_13_4=4 () Bool (and (and pvalid.8 (and (not (word32-eq p___ptr_to_unsigned_char_v_after_9_4=3 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule p___ptr_to_unsigned_char_v_after_9_4=3 (bvsub #x00000000 #x00000001))))) (and pvalid.9 (and (not (word32-eq q___ptr_to_unsigned_char_v_after_7_4=3 #x00000000)) (=> (bvult #x00000000 #x00000001) (bvule q___ptr_to_unsigned_char_v_after_7_4=3 (bvsub #x00000000 #x00000001)))))))
(define-fun path_cond_to_12_4=4_C () Bool (and cond_at_13_4=4 path_cond_to_13_4=4_C))
(define-fun query_bvandr3_after_24_17=.1 () (_ BitVec 32) (bvand r3_after_24_17=2 #xfffffffd))
(define-fun query_load-word32mem_after.1 () (_ BitVec 32) (load-word32 mem_after_24_17=2 (bvand r3_after_24_17=2 #xfffffffd)))
(define-fun mem_after_24_17=3 () (Array (_ BitVec 30) (_ BitVec 32)) (store-word8 mem_after_24_17=2 r3_after_24_17=2 ((_ extract 7 0) r12_after_22_17=3)))
(define-fun r3_after_24_17=3 () (_ BitVec 32) (bvadd r3_after_24_17=2 #x00000001))
(define-fun v_after_23_17=3 () Bool (and (= (not (word32-eq (bvand r3_after_24_17=3 #x80000000) #x00000000)) (word32-eq (bvand r2_after_33 #x80000000) #x00000000)) (not (= (not (word32-eq (bvand r3_after_24_17=3 #x80000000) #x00000000)) (not (word32-eq (bvand (bvsub r3_after_24_17=3 r2_after_33) #x80000000) #x00000000))))))
(define-fun c_after_23_17=3 () Bool (not (= (bvand (bvadd (bvadd ((_ zero_extend 32) r3_after_24_17=3) ((_ zero_extend 32) (bvnot r2_after_33))) #x0000000000000001) #x0000000100000000) #x0000000000000000)))
(define-fun z_after_23_17=3 () Bool (word32-eq r3_after_24_17=3 r2_after_33))
(define-fun n_after_23_17=3 () Bool (not (word32-eq (bvand (bvsub r3_after_24_17=3 r2_after_33) #x80000000) #x00000000)))
(define-fun cond_at_35_17=3 () Bool (not z_after_23_17=3))
(define-fun path_cond_to_25_17=3_ASM () Bool (and cond_at_35_17=3 path_cond_to_24_17=3_ASM))
(define-fun cond_at_17_17=3 () Bool true)
(define-fun path_cond_to_22_17=4_ASM () Bool (and cond_at_17_17=3 path_cond_to_25_17=3_ASM))
(define-fun query_bvaddr1_after_22_17=.2 () (_ BitVec 32) (bvadd r1_after_22_17=3 #x00000001))
(define-fun query_load-word8mem_after_.2 () (_ BitVec 8) (load-word8 mem_after_24_17=3 (bvadd r1_after_22_17=3 #x00000001)))
(define-fun r12_after_22_17=4 () (_ BitVec 32) ((_ zero_extend 24) (load-word8 mem_after_24_17=3 (bvadd r1_after_22_17=3 #x00000001))))
(define-fun r1_after_22_17=4 () (_ BitVec 32) (bvadd r1_after_22_17=3 #x00000001))
(define-fun cond_at_20_17=4 () Bool true)
(define-fun path_cond_to_24_17=4_ASM () Bool (and cond_at_20_17=4 path_cond_to_22_17=4_ASM))
(define-fun path_cond_to_Err_4=0_1_C () Bool (or false (and (not cond_at_13_4=1) path_cond_to_13_4=1_C)))
(assert (not (=> (word32-eq r0_init ptr_dst___ptr_to_void_v_init) (=> (word32-eq r1_init ptr_src___ptr_to_void_v_init) (=> (word32-eq r2_init n___unsigned_long_v_init) (=> (mem-eq mem_init Mem_init) (=> (rodata Mem_init) (=> (word32-eq (bvand r13_init #x00000003) #x00000000) (=> (word32-eq ret_init r14_init) (=> (word32-eq (bvand ret_init #x00000003) #x00000000) (=> (word32-eq ret_addr_input_init r0_init) (=> (bvule #x00000000 r13_init) (=> (=> path_cond_to_12_4=4_C path_cond_to_12_4=4_C) (=> (=> path_cond_to_24_17=4_ASM path_cond_to_24_17=4_ASM) (=> (=> path_cond_to_22_17=4_ASM path_cond_to_22_17=4_ASM) (=> (=> path_cond_to_Err_4=0_1_C false) (=> (=> true path_cond_to_22_17=2_ASM) (=> (=> true path_cond_to_22_17=3_ASM) (word32-eq (bvmul (bvadd #x00000001 #x00000000) #x00000004) #x00000000)))))))))))))))))))
