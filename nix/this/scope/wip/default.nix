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
      rev = "4a2a0e3ba6a341b125e6abc08eb85b18804daae5"; # branch nspin/wip/bv-sandbox
    };

    graph-refine = graph-refine-remote;
    # graph-refine = graph-refine-local;
  };

in rec {

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

  getActiveIRQ = graphRefineWith {
    name = "x";
    args = graphRefine.defaultArgs ++ [
      "deps:Kernel_C.getActiveIRQ"
    ];
  };

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

  keep = writeText "keep" (toString (lib.flatten [
    # this.scopes.arm.legacy.o1.all
    # this.displayStatus

    (lib.forEach (map this.mkScopeFomNamedConfig this.namedConfigs) (scope:
      [
        (if scope.scopeConfig.mcs || lib.elem scope.scopeConfig.arch [ "AARCH64" "X64" ] then scope.slow else scope.slower)
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
      "--for-slow=${small}"
    ];
  };

  testSmall = testWith small;

  test = testWith big;

  bigProofsAll = [
    "all"
    # "loadCapTransfer"
    # "copyMRs"
    # "branchFlushRange"
  ];

  bigProofs = scopes.ARM.o1.withChannel.release.upstream.wip.bigProofs_;
  bigProofs_ = with graphRefine; graphRefineWith {
    name = "all";
    argLists = [
      (excludeArgs ++ defaultArgs ++ [
        "save-proof-checks:proof-checks.json"
        "save-smt-proof-checks:smt-proof-checks.json"
      ] ++ bigProofsAll)
    ];
  };

  focusedProofs = scopes.ARM.o1.withChannel.release.upstream.wip.focusedProofs_;
  focusedProofs_ = with graphRefine; graphRefineWith {
    name = "all";
    argLists = [
      (excludeArgs ++ defaultArgs ++ [
        "save-proof-checks:proof-checks.json"
        "save-smt-proof-checks:smt-proof-checks.json"

        "handleInterruptEntry" # sat
        # "handleSyscall" # sat
      ])
    ];
    # source = tmpSource.graph-refine;
  };

  example = scopes.ARM.o1.withChannel.release.upstream.wip.example_;
  example_ =
    let
      files = [
        "kernel.elf.symtab"
        "kernel.elf.rodata"
        "CFunctions.txt"
        "ASMFunctions.txt"
        "StackBounds.txt"
        "inline-scripts.json"
        "proofs.json"
      ];
    in
      runCommand "target-dir" {} ''
        mkdir $out
        cp ${bigProofs_}/{${lib.concatStringsSep "," files}} $out
      '';

  mkHs' = proofs: { args, extra }:
    with graphRefine; graphRefineWith ({
      name = "hs";
      argLists = [
        (excludeArgs ++ defaultArgs ++ [
          "use-inline-scripts-of:${proofs}/inline-scripts.json"
          "use-proofs-of:${proofs}/proofs.json"
          "save-proof-checks:proof-checks.json"
          "save-smt-proof-checks:smt-proof-checks.json"
        ] ++ args)
      ];
      stackBounds = "${proofs}/StackBounds.txt";
    } // extra);

  mkHs = mkHs' bigProofs_;

  big = scopes.ARM.o1.withChannel.release.upstream.wip.big_;
  big_ = mkHs {
    args = [
      "hack-skip-smt-proof-checks"
    ] ++ bigProofsAll;
    extra = {
      source = tmpSource.graph-refine;
    };
  };

  small = scopes.ARM.o1.withChannel.release.upstream.wip.small_;
  small_ = mkHs {
    args = [
      "hack-skip-smt-proof-checks"

      # "loadCapTransfer"
      # "copyMRs"
      # "branchFlushRange"

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

      # "handleSyscall" # sat
    ];
    extra = {
      source = tmpSource.graph-refine;
    };
  };

  smallTrace = scopes.ARM.o1.withChannel.release.upstream.wip.smallTrace_;
  smallTrace_ = mkHs {
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

  smallTraceOfflineOnly = scopes.ARM.o1.withChannel.release.upstream.wip.smallTraceOfflineOnly_;
  smallTraceOfflineOnly_ = mkHs {
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

  focused = scopes.ARM.o1.withChannel.release.upstream.wip.focused_;
  # focused_ = mkHs' focusedProofs_ {
  focused_ = mkHs {
    args = [
      "hack-skip-smt-proof-checks"

      "handleInterruptEntry" # sat
      "handleSyscall" # sat

      # "Arch_switchToIdleThread"
      # "initTimer"
      # "cteDelete"
      # "sendIPC"
      # "handleSyscall" # sat
      # "branchFlushRange"
      # "setMRs_syscall_error"
      # "copyMRs"
      # "decodeInvocation"
      # "handleFaultReply"
      # "reserve_region"
      # "create_frames_of_region"
      # "create_untypeds"
      # "setDomain"
      # "branchFlushRange"
      # "loadCapTransfer"
      # "strncmp"
      # "copyMRs"
    ];
    extra = {
      source = tmpSource.graph-refine;
    };
  };

  focusedTrace = scopes.ARM.o1.withChannel.release.upstream.wip.focusedTrace_;
  focusedTrace_ = mkHs {
    args = [
      # "hack-offline-solvers-only"
      # "loadCapTransfer"
      # "decodeSetSpace"
      "handleVMFault"
      # "sendIPC"
      # "branchFlushRange"
      # "copyMRs"
      # "strncmp"
      # "handleSyscall" # sat
    ];
    extra = {
      source = tmpSource.graph-refine;
      solverList = debugSolverList;
      keepBigLogs = true;
    };
  };

  inlineTrace = scopes.ARM.o1.withChannel.release.upstream.wip.inlineTrace_;
  inlineTrace_ = with graphRefine; graphRefineWith {
    args = excludeArgs ++ defaultArgs ++ [
      # "use-inline-scripts-of:${bigProofs_}/inline-scripts.json"
      "use-proofs-of:${bigProofs_}/proofs.json"
      "save-proof-checks:proof-checks.json"
      "save-smt-proof-checks:smt-proof-checks.json"
      "hack-skip-smt-proof-checks"
      "hack-offline-solvers-only"
      "handleVMFault"
    ];
    stackBounds = "${bigProofs_}/StackBounds.txt";
    source = tmpSource.graph-refine;
    solverList = debugSolverList;
    keepBigLogs = true;
  };

  stackBoundsNoTrace = scopes.ARM.o1.withChannel.release.upstream.wip.stackBoundsNoTrace_;
  stackBoundsNoTrace_ = with graphRefine; graphRefineWith {
    args = excludeArgs ++ defaultArgs ++ [
      # "trace-to:report.txt"
      # "verbose"
    ];
    source = tmpSource.graph-refine;
  };

  stackBoundsTrace = scopes.ARM.o1.withChannel.release.upstream.wip.stackBoundsTrace_;
  stackBoundsTrace_ = with graphRefine; graphRefineWith {
    args = excludeArgs ++ defaultArgs;
    source = tmpSource.graph-refine;
    solverList = debugOnlineOnlySolverList;
    keepBigLogs = true;
  };

  earlySearch = scopes.ARM.o1.withChannel.release.upstream.wip.earlySearch_;
  earlySearch_ = with graphRefine; graphRefineWith {
    name = "early-search";
    argLists = [
      (excludeArgs ++ defaultArgs ++ [
        "coverage"
      ])
    ];
    source = tmpSource.graph-refine-local;
    stackBounds = "${bigProofs_}/StackBounds.txt";
  };

  earlySearchFast = scopes.ARM.o1.withChannel.release.upstream.wip.earlySearchFast_;
  earlySearchFast_ = with graphRefine; graphRefineWith {
    name = "early-search-fast";
    argLists = [
      (excludeArgs ++ defaultArgs ++ [
        "coverage"
      ])
    ];
    source = tmpSource.graph-refine-remote;
    stackBounds = "${bigProofs_}/StackBounds.txt";
  };

  aaa = scopes.ARM.o1.withChannel.release.upstream.wip.aaa_;
  aaa_ = with graphRefine; graphRefineWith {
    name = "all";
    argLists = [
      (excludeArgs ++ defaultArgs ++ [
        "use-inline-scripts-of:${bigProofs_}/inline-scripts.txt"
        "use-proofs-of:${bigProofs_}/proofs.txt"

        "save-proof-checks:proof-checks.txt"
        "save-smt-proof-checks:smt-proof-checks.txt"
        "hack-skip-smt-proof-checks"
        # "hack-offline-solvers-only"

        # "loadCapTransfer"
        # "copyMRs"
        # "branchFlushRange"

        "all"
      ])
    ];
    stackBounds = "${bigProofs_}/StackBounds.txt";
    source = tmpSource.graph-refine;
    # solverList = debugSolverList;
    # keepBigLogs = true;
  };

  bbb = scopes.ARM.o1.withChannel.release.upstream.wip.bbb_;
  bbb_ = with graphRefine; graphRefineWith {
    name = "all";
    argLists = [
      (excludeArgs ++ defaultArgs ++ [
        "use-inline-scripts-of:${bigProofs_}/inline-scripts.txt"
        "use-proofs-of:${bigProofs_}/proofs.txt"

        "save-smt-proof-checks:smt-proof-checks.json"
        "hack-skip-smt-proof-checks"
        # "hack-offline-solvers-only"

        "memzero"

        # "all"
      ])
    ];
    stackBounds = "${bigProofs_}/StackBounds.txt";
    source = tmpSource.graph-refine;
    solverList = debugSolverList;
    keepBigLogs = true;
  };

  o2 = scopes.ARM.o2.withChannel.release.upstream;
  o1 = scopes.ARM.o1.withChannel.release.upstream;
  o2w = o2.wip;
  o1w = o1.wip;
  rm = scopes.RISCV64_MCS.o1.release.upstream;
  rmt = rm.graphRefine.all.targetDir;

  stackBounds = graphRefineWith {
    name = "stack-bounds";
    args = graphRefine.saveArgs;
  };

  g = o2.wip.g_;
  g_ = graphRefineWith {
    args = graphRefine.saveArgs ++ [
      "trace-to:report.txt"
      # "coverage"
      "loadCapTransfer"
      "copyMRs"
      "branchFlushRange"
    ];
    stackBounds = "${stackBounds}/StackBounds.txt";
    # solverList = debugSolverList;
    # keepBigLogs = true;
    # source = tmpSource.graph-refine;
  };

  h = o2.wip.h_;
  h_ = graphRefineWith {
    args = graphRefine.saveArgs ++ [
      # "trace-to:report.txt"
      "verbose"
      # "coverage"
      "save-proof-checks:proof-checks.txt"
      "use-proofs-of:${g_}/proofs.txt"
      "use-inline-scripts-of:${g_}/inline-scripts.txt"

      "loadCapTransfer"
      "Arch_switchToIdleThread"
      "sameRegionAs"
      # "copyMRs"
      # "branchFlushRange"
    ];
    stackBounds = "${stackBounds}/StackBounds.txt";
    # solverList = debugSolverList;
    # keepBigLogs = true;
    source = tmpSource.graph-refine;
  };

  bvWip = o2.wip.bvWip_;

  bvWip_ = graphRefineWith {
    args = graphRefine.saveArgs ++ [
      "trace-to:report.txt"
      # "coverage"
      "loadCapTransfer"
    ];
    stackBounds = "${stackBounds}/StackBounds.txt";
    solverList = debugSolverList;
    keepBigLogs = true;
    source = tmpSource.graph-refine;
  };

  o1bad = graphRefineWith {
    args = graphRefine.saveArgs ++ [
      # "verbose"
      "trace-to:report.txt"
      "init_freemem"
    ];
    stackBounds = "${stackBounds}/StackBounds.txt";
  };

  o2c = o2.graphRefineWith {
    args = o2.graphRefine.saveArgs ++ [
      "trace-to:report.txt"
      "-exclude"
        "init_freemem"
        "decodeARMMMUInvocation"
      "-end-exclude"
      "coverage"
    ];
  };

  o2a = o2.graphRefineWith {
    args = o2.graphRefine.saveArgs ++ [
      "trace-to:report.txt"
      "-exclude"
        "init_freemem"
        "decodeARMMMUInvocation"
      "-end-exclude"
      "all"
    ];
  };

  es2 = o2w.es_;
  es1 = o1w.es_;
  es_ = graphRefineWith {
    args = graphRefine.saveArgs ++ [
      "verbose"
      # "trace-to:report.txt"

      # "emptySlot"
      # "setupCallerCap"
      # "invokeTCB_WriteRegisters"
      # "makeUserPDE"
      # "lookupSourceSlot" # x
      # "loadCapTransfer" # x
      # "Arch_maskCapRights" # x
      "setupCallerCap"
      # "map_kernel_frame"
    ];
    solverList = debugSolverList;
    keepBigLogs = true;
    stackBounds = "${stackBounds}/StackBounds.txt";
    source = tmpSource.graph-refine;
  };

    # extraNativeBuildInputs = [
    #   breakpointHook
    #   bashInteractive
    # ];

  debugSolverList =
    let
      chosen = "yices";
      # chosen = "bitwuzla";
      scope = graphRefineSolverLists.overrideScope (self: super: {
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
    in
      scope.solverList;

  debugOnlineOnlySolverList =
    let
      chosen = "yices";
      scope = graphRefineSolverLists.overrideScope (self: super: {
        executables = lib.flip lib.mapAttrs super.executables (lib.const (old: [ wrapSolver "trace" ] ++ old));
        offlineSolvers = {};
      });
    in
      scope.solverList;

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
