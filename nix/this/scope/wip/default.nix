{ lib
, pkgs
, stdenv
, callPackage
, runCommand
, writeText
, writeScript
, writeShellApplication
, linkFarm
, runtimeShell
, mkShell
, fetchFromGitHub
, breakpointHook
, bashInteractive
, strace
, gdb
, cntr
, yices
, bitwuzla

, scopeConfig
, overrideConfig
, fetchGitFromColiasGroup
, gitignoreSource
, cleanHol4Source
, l4vWith
, graphRefine
, graphRefineWith
, graphRefineSolverLists
, python2WithDebuggingSymbols

, bv-ng

, this
, overrideScope
}:

let
  inherit (this) scopes;

  tmpSourceDir = ../../../../tmp/src;

  tmpSource = rec {
    seL4 = gitignoreSource (tmpSourceDir + "/seL4");
    HOL = cleanHol4Source (tmpSourceDir + "/HOL");

    graph-refine-local = gitignoreSource (tmpSourceDir + "/graph-refine");

    graph-refine-remote = fetchGitFromColiasGroup {
      repo = "graph-refine";
      rev = "961b8286a1b72e1515b4dc2c43fc8fefb065384c"; # branch handoff
    };

    # graph-refine = graph-refine-remote;
    graph-refine = graph-refine-local;
  };

in rec {

  theseScopes = [
    scopes.ARM.o1
    scopes.ARM.o2
    scopes.ARM.withGCC.gcc13.o1
    scopes.ARM.withGCC.gcc13.o2
    scopes.ARM.withGCC.gcc14.o1 # bad jump tables
    scopes.ARM.withGCC.gcc14.o2 # bad jump tables
    scopes.ARM.withGCC.clang.o1
    scopes.ARM.withGCC.clang.o2
    scopes.RISCV64.o1
    scopes.RISCV64.o2 # without chooseThread
    scopes.RISCV64.withGCC.gcc13.o1
    scopes.RISCV64.withGCC.gcc13.o2 # without chooseThread
    scopes.RISCV64.withGCC.gcc14.o1
    scopes.RISCV64.withGCC.gcc14.o2 # without chooseThread and create_untypeds_for_region
    scopes.RISCV64.withGCC.clang.o1
    scopes.RISCV64.withGCC.clang.o2
  ];

  decomp = writeText "x" (toString (lib.flip lib.concatMap theseScopes (scope:
    [ scope.decompilation ]
  )));

  # TODO graph-refine can't figure out mutual recursion for clang codegen
  save = writeText "x" (toString (lib.flip lib.concatMap theseScopes (scope:
    lib.optionals (scope.scopeConfig.arch == "ARM" && scope.scopeConfig.targetCCIsGCC) [
      scope.graphRefine.justSave
    ]
  )));

  # TODO graph-refine can't figure out mutual recursion for clang codegen
  coverage = writeText "x" (toString (lib.flip lib.concatMap theseScopes (scope:
    lib.optionals (scope.scopeConfig.arch == "ARM" && scope.scopeConfig.targetCCIsGCC) [
      scope.graphRefine.coverage
    ]
  )));

  preSearch = writeText "x" (toString (lib.flatten [
    decomp
    save
    coverage
  ]));

  keep = writeText "x" (toString (lib.flatten [
    preSearch
    scopes.ARM.o1.graphRefine.all
  ]));

  # nix-build -A scopes.ARM.withCC.gcc13.o1.wip.ex
  ex = with graphRefine; graphRefineWith {
    args = excludeArgs ++ defaultArgs ++ [
        "doNormalTransfer" # sat
        "decodeARMMMUInvocation" # except
        "reserve_region" # sat
        "handleFaultReply" # nosplit
    ];
    source = tmpSource.graph-refine;
    # solverList = debugSolverList;
    # keepBigLogs = true;
    # stackBounds = "${stackBounds}/StackBounds.txt";
  };

  stackBounds = with graphRefine; graphRefineWith {
    name = "stackBounds";
    args = excludeArgs;
  };

  rmUnreachable =
    let
      f = scope: scope.withRevs {
        seL4 = "2bb4da53d4a9e42d1ffc8b6fb5dd43d669375b2e";
        l4v = "da9ac959588d5a2bd0a3827d669a4c9dad3c9fff";
      };
    in
      (f this.scopes.ARM).cProofs;

  x64InitializeVars =
    let
      f = scope: scope.withRevs {
        seL4 = "4086a2b93186ba14fa7fe05216dd351687915dbe";
        l4v = "0464c75de3f5bb8b9c6c7ed4c167bf30e6330d5a";
      };
    in
      (f this.scopes.X64).cProofs;

  irqInvalidScopes =
    lib.flip lib.mapAttrs this.scopes (lib.const (scope: scope.withRevs {
      seL4 = "aa337966acce97651ad58609dcb63a3d719dc873";
      l4v = "da9ac959588d5a2bd0a3827d669a4c9dad3c9fff";
    }));

  irqInvalid = writeText "x" (toString (lib.flatten [
    irqInvalidScopes.ARM.cProofs
    irqInvalidScopes.ARM_HYP.cProofs
    irqInvalidScopes.AARCH64.cProofs
    irqInvalidScopes.ARM.o1.wip.getActiveIRQ
    irqInvalidScopes.ARM.o2.wip.getActiveIRQ
  ]));

  tip = writeText "x" (toString (lib.flatten [
    scopes.ARM.withChannel.tip.upstream.cProofs
    scopes.ARM_HYP.withChannel.tip.upstream.cProofs
    scopes.AARCH64.withChannel.tip.upstream.cProofs
    scopes.RISCV64.withChannel.tip.upstream.cProofs
    scopes.RISCV64_MCS.withChannel.tip.upstream.cProofs
    scopes.X64.withChannel.tip.upstream.cProofs
  ]));

  release = writeText "x" (toString (lib.flatten [
    scopes.ARM.withChannel.release.upstream.cProofs
    scopes.ARM_HYP.withChannel.release.upstream.cProofs
    scopes.AARCH64.withChannel.release.upstream.cProofs
    scopes.RISCV64.withChannel.release.upstream.cProofs
    scopes.X64.withChannel.release.upstream.cProofs
  ]));

  # cached = writeText "cached" (toString (lib.flatten [
  #   scopes.ARM.o1.withChannel.release.downstream.graphRefine.all
  #   scopes.ARM.o1.withChannel.release.upstream.graphRefine.all
  #   scopes.ARM.o2.withChannel.release.upstream.graphRefine.all
  #   o1.big
  #   o1.small
  #   o1.focused
  #   o1.example
  #   o2.big
  #   o2.small
  #   o2.focused
  #   o2.example
  #   scopes.ARM.o1.withChannel.release.downstream.l4vAll
  #   scopes.RISCV64.o1.withChannel.release.upstream.graphRefine.all.targetDir
  #   # scopes.RISCV64.o2.withChannel.release.upstream.decompilation # hangs? (8+ hours)
  #   scopes.RISCV64.o2.withChannel.release.upstream.forceSimplExport
  #   scopes.AARCH64.o1.withChannel.release.upstream.decompilation
  #   # scopes.AARCH64.o1.withChannel.release.upstream.forceSimplExport # unsupported
  # ]));

  todo = writeText "todo" (toString (lib.flatten [
    scopes.ARM.o1.withChannel.release.upstream.wip.keepHere
    scopes.ARM.o1.withChannel.tip.upstream.wip.keepHere
    # scopes.ARM.o1.withChannel.release.upstream.all
    # this.displayStatus
  ]));

  keepHere = writeText "keep-here" (toString (lib.flatten [
    (lib.forEach (lib.attrValues scopes) (scope':
      let
        scope = scope'.o1;
      in
        lib.optionals (scope'.scopeConfig.plat == "") [
          (if scope.scopeConfig.mcs || lib.elem scope.scopeConfig.arch [ "AARCH64" "X64" ]
            then scope.slow
            else scope.slower)
        ]
    ))
  ]));

  solvers = {
    online = {
      command = [ "yices-smt2" "--incremental" ];
      memory_mode = "word8";
      offline = {
        yices = {
          command = [ "yices-smt2" ];
          memory_modes = [ "word8" "word32" ];
          scopes = [ "all" "hyp" ];
        };
        bitwuzla = {
          command = [ "bitwuzla" ];
          memory_modes = [ "word8" "word32" ];
          scopes = [ "all" "hyp" ];
        };
      };
    };
  };

  check =
    let
      targetDir = big;
      # targetDir = small;
    in
      runCommand "sel4-bv-cli.log" {
        nativeBuildInputs = [
          bv-ng.sel4-bv
          yices
          bitwuzla
        ];
      } ''
        mkdir $out

        ( 
          time sel4-bv-cli \
            check \
            --target-dir ${targetDir} \
            --force-eval-stages \
            --reference-target-dir ${targetDir} \
            --c-function-prefix Kernel_C. \
            --rodata-section .rodata \
            --rodata-symbol kernel_device_frames \
            --rodata-symbol avail_p_regs \
            --ignore-function fastpath_call \
            --ignore-function fastpath_reply_recv \
            --ignore-function arm_swi_syscall \
            --ignore-function-early c_handle_syscall \
            --solvers ${builtins.toFile "solvers.json" (builtins.toJSON solvers)} \
            --just-compare-checks \
            --num-eval-cores 1 \
          ) 2>&1 | tee $out/log.txt
      '';
          # --include-function invokeTCB_WriteRegisters \
          # --mismatch-dir $tmp/mismatch/local-check \
          # --file-log $here/../../tmp/logs/test-check.log.txt \
          # --file-log-level debug \

  testWith = forSlow: bv-ng.sel4-bv-test {
    testFlags = [
      "--out-dir=$TMPDIR/test-out"
      "--graph-refine-dir=${scopeConfig.graphRefineSource}"
      "--for-fast=${big}"
      "--for-slow=${forSlow}"
      "-j1"
      # "-j$NIX_BUILD_CORES"
    ];
  };

  testSmall = testWith small;

  test = testWith big;

  bigProofsAll = [
    "all"
  ];

  bigProofs = graphRefine.all;

  # -O2
  focusedProofs = with graphRefine; graphRefineWith {
    args = excludeArgs ++ defaultArgs ++ [
      "handleInterruptEntry" # sat
      "handleSyscall" # sat
    ];
  };

  example =
    let
      files = [
        "kernel.elf.symtab"
        "kernel.elf.rodata"
        "CFunctions.txt"
        "ASMFunctions.txt"
        "StackBounds.txt"
        "inline-scripts.json"
        "proof-scripts.json"
      ];
    in
      runCommand "target-dir" {} ''
        mkdir $out
        cp ${bigProofs}/{${lib.concatStringsSep "," files}} $out
      '';

  useProofsFrom = proofs: { args, extra }:
    with graphRefine; graphRefineWith ({
      args = excludeArgs ++ defaultArgs ++ [
        "use-inline-scripts-of:${proofs}/inline-scripts.json"
        "use-proofs-of:${proofs}/proof-scripts.json" # TODO rename this arg to use-proof-scripts-of
      ] ++ args;
      stackBounds = "${proofs}/StackBounds.txt";
    } // extra);

  useProofs = useProofsFrom bigProofs;

  big = useProofs {
    args = [
      "hack-skip-smt-proof-checks"
    ] ++ lib.optionals (scopeConfig.optLevel == "-O2") [
      "-exclude"
        "lookupSourceSlot"
        "doNormalTransfer"
        "handleInterruptEntry"
        "Arch_maskCapRights"
        "makeUserPDE"
        "invokeTCB_WriteRegisters"
        "map_kernel_frame"
        "createNewObjects"
        "handleSyscall"
        "setMRs_fault"
        "emptySlot"
        "create_it_address_space"
        "setupCallerCap"
      "-exclude-end"
    ] ++ bigProofsAll;
    extra = {
      source = tmpSource.graph-refine;
    };
  };

  small = useProofs {
    args = [
      "hack-skip-smt-proof-checks"

      "Arch_switchToIdleThread"
      "initTimer"
      "cteDelete"
      "sendIPC"
      "create_frames_of_region"
      "create_untypeds"
      "setDomain"
      "branchFlushRange"
      "loadCapTransfer"
      "strncmp"
      "copyMRs"
      "setMRs_syscall_error"
    ];
    extra = {
      source = tmpSource.graph-refine;
    };
  };

  smallTrace = useProofs {
    args = [
      "loadCapTransfer"
      "copyMRs"
      "branchFlushRange"
    ];
    extra = {
      source = tmpSource.graph-refine;
      solverList = debugSolverList;
      keepBigLogs = true;
    };
  };

  smallTraceOfflineOnly = useProofs {
    args = [
      "hack-offline-solvers-only"

      "loadCapTransfer"
      "copyMRs"
      "branchFlushRange"
    ];
    extra = {
      source = tmpSource.graph-refine;
      solverList = debugSolverList;
      keepBigLogs = true;
    };
  };

  focused = useProofs {
    args = [
      "hack-skip-smt-proof-checks"

      # "copyMRs"
      # "handleFaultReply"
      # "unmapPage"
      # "handleInterruptEntry" # sat
      # "handleSyscall" # sat
      # "arch_clean_invalidate_L1_caches"
      "create_frames_of_region"
    ];
    extra = {
      source = tmpSource.graph-refine;
    };
  };

  focusedTrace = useProofs {
    args = [
      "handleVMFault"
    ];
    extra = {
      source = tmpSource.graph-refine;
      solverList = debugSolverList;
      keepBigLogs = true;
    };
  };

  inlineTrace = with graphRefine; graphRefineWith {
    args = excludeArgs ++ defaultArgs ++ [
      # "use-inline-scripts-of:${bigProofs_}/inline-scripts.json"
      "use-proofs-of:${bigProofs}/proof-scripts.json"
      "save-proof-checks:proof-checks.json"
      "save-smt-proof-checks:smt-proof-checks.json"
      "hack-skip-smt-proof-checks"
      "hack-offline-solvers-only"
      "handleVMFault"
    ];
    stackBounds = "${bigProofs}/StackBounds.txt";
    source = tmpSource.graph-refine;
    solverList = debugSolverList;
    keepBigLogs = true;
  };

  stackBoundsNoTrace = with graphRefine; graphRefineWith {
    args = excludeArgs ++ defaultArgs ++ [
      # "trace-to:report.txt"
      # "verbose"
    ];
    source = tmpSource.graph-refine;
  };

  stackBoundsTrace = with graphRefine; graphRefineWith {
    args = excludeArgs ++ defaultArgs;
    source = tmpSource.graph-refine;
    solverList = debugOnlineOnlySolverList;
    keepBigLogs = true;
  };

  # # #

  debugSolverList =
    let
      chosen = "yices";
    in
      graphRefineSolverLists.default.withOverriddenScope (self: super: {
        executables = lib.flip lib.mapAttrs super.executables (lib.const (old: [ wrapSolver "trace" ] ++ old));
        # executables = lib.flip lib.mapAttrs super.executables (k: v:
        #   (if k == chosen then [ wrap "trace" ] else []) ++ v
        # );
        # onlineSolver = {
        #   command = self.onlineCommands.${chosen};
        #   inherit (super.onlineSolver) config;
        # };
        # offlineSolverKey = {
        #   attr = chosen;
        #   inherit (super.offlineSolverKey) granularity;
        # };
        offlineSolverFilter = attr: lib.optionals (attr == chosen) [
          # self.granularities.byte
          self.granularities.machineWord
        ];
        # strategyFilter = attr: granularity: lib.optionals (attr == chosen) [
        #   "all"
        # ];
      });

  debugOnlineOnlySolverList = debugSolverList.withOverriddenScope (self: super: {
    offlineSolverFilter = attr: [];
  });

  wrapSolver = writeScript "wrap" ''
    #!${runtimeShell}

    set -u -o pipefail

    parent="$1"
    shift

    t=$(date +%s.%6N)
    d=$parent/$t

    mkdir -p $d

    echo "solver trace: $t" >&2

    echo $$ > $d/wrapper-pid.txt
    echo "$@" > $d/args.txt

    exec < <(tee $d/in.smt2) > >(tee $d/out.smt2) 2> >(tee $d/err.log >&2)

    bash -c 'echo $$ > '"$d/solver-pid.txt"' && exec "$@"' -- "$@"

    ret=$?

    echo $ret > $d/ret.txt

    exit $ret
  '';

  gdbShell = mkShell {
    nativeBuildInputs = [
      gdb
    ];

    script = "${python2WithDebuggingSymbols}/share/gdb/libpython.py";

    shellHook = ''
      d() {
        pid="$1"
        sudo gdb -p "$pid" -x "$script"
      }
    '';
  };

  scopeWithHol4Rev = { rev, ref ? "HEAD" }: overrideConfig {
    hol4Source = lib.cleanSource (builtins.fetchGit {
      url = "https://github.com/coliasgroup/HOL";
      inherit rev ref;
    });
  };
}

# NOTES
# - for debugging
#     extraNativeBuildInputs = [
#       breakpointHook
#       bashInteractive
#     ];
