{ lib
, callPackage, newScope
, pkgs
, oldPkgs
, writeText
, linkFarm
}:

rec {

  mkScope = scopeConfigArgs: lib.makeScope newScope
    (self:
      ((callPackage ./scope {} self) // {
        scopeConfig = lib.makeOverridable mkScopeConfig scopeConfigArgs;
        overrideConfig = f: self.overrideScope (self: super: {
          scopeConfig = super.scopeConfig.override f;
        });
      } // mkScopeExtension {
        inherit (self) overrideConfig;
        superScopeConfig = self.scopeConfig;
      }));

  mkScopeConfig =
    { arch
    , mcs ? false
    , features ? lib.optionalString mcs "MCS"
    , plat ? "" # TODO none should be null
    , optLevel ? null

    , targetCCWrapperAttr ? defaultCCWrapperAttr
    , targetPkgsBase ? if targetCCWrapperAttr == "gcc6" then oldPkgs else pkgs
    , targetPkgs ? targetPkgsAccessByL4vArch."${arch}" targetPkgsBase
    , targetCCWrapper ?
        if lib.hasPrefix "clang" targetCCWrapperAttr
        then pkgs."${targetCCWrapperAttr}"
        else (targetPkgsAccessByL4vArch."${arch}" targetPkgsBase).buildPackages."${targetCCWrapperAttr}"
    , targetCC ? targetCCWrapper.cc
    , targetCCIsGCC ? targetCCWrapper.isGNU
    , targetCCIsClang ? targetCCWrapper.isClang
    , targetCCKind ? if targetCCIsGCC then "gcc" else if targetCCIsClang then "clang" else throw ""
    , targetBintools ?
        if targetCCIsClang
        then pkgs.llvmPackages.bintools-unwrapped
        else targetCCWrapper.bintools.bintools
    , targetPrefix ? targetCCWrapper.targetPrefix

    , localSeL4Source ? ../../projects/seL4
    , seL4Source ? gitignoreSource localSeL4Source
    , localL4vSource ? ../../projects/l4v
    , l4vSource ? cleanL4vSource localL4vSource
    , localHol4Source ? ../../projects/HOL4
    , hol4Source ? cleanHol4Source localHol4Source
    , localGraphRefineSource ? ../../projects/graph-refine
    , graphRefineSource ? gitignoreSource localGraphRefineSource
    , localBinaryVerificationSource ? ../../projects/binary-verification
    , binaryVerificationSource ? gitignoreSource localBinaryVerificationSource
    , seL4IsabelleSource ? defaultSeL4IsabelleSource
    , useSeL4Isabelle ? true

    , l4vName ? "${arch}${nameModification features}${nameModification plat}"
    , bvName ? "${l4vName}${optLevel}" # TODO add compiler+version, and use in drv names
    , longBVName ? "${bvName}-${targetCCKind}-${targetCC.version}"

    , bvLiftSupport ? lib.elem arch [ "ARM" "RISCV64" ]
    , bvLowerSupport ? lib.elem arch [ "ARM" "RISCV64" ] && !mcs
    , bvSupport ? bvLiftSupport && bvLowerSupport && lib.elem arch [ "ARM" ]
    , extraKernelCFlags ? lib.concatLists [
        # GCC 14+ use codgen for jump tables that the decompiler can't yet handle.
        # Note that jump tables in some decode* functions slow graph-refine way down, but only on
        # GCC <= 13 because jump tables are disabled otherwise.
        (lib.optionals
          (arch == "ARM" && targetCCIsGCC && lib.versionAtLeast targetCC.version "14")
          [ "-fno-jump-tables" ])
        (lib.optionals
          (arch == "ARM" && targetCCIsGCC && lib.versionAtLeast targetCC.version "13" && optLevel == "-O2")
          [ "-fno-tree-fre" "-fno-gcse" "-fno-tree-pre" ])
      ]
    , extraDecompileExclude ? []
    , bvExclude ?
      lib.concatLists [
        (lib.optionals
          (arch == "ARM")
          [ "init_freemem" ])
        (lib.optionals
          (arch == "ARM" && targetCCIsGCC && lib.versions.major targetCC.version == "13" && optLevel == "-O2")
          [
            # "decodeARMMMUInvocation"
            "decodeUntypedInvocation"
            "create_frames_of_region"
          ])
      ]
    }:
    {
      inherit
        arch mcs features plat
        optLevel
        targetPkgs
        targetCC targetCCKind targetCCIsGCC targetCCIsClang targetBintools targetPrefix
        seL4Source
        l4vSource
        hol4Source
        graphRefineSource
        binaryVerificationSource
        seL4IsabelleSource
        useSeL4Isabelle
        extraKernelCFlags
        extraDecompileExclude
        bvLiftSupport
        bvLowerSupport
        bvSupport
        bvExclude
        l4vName
        bvName
        longBVName
      ;
    };

  archs = {
    arm = "ARM";
    armHyp = "ARM_HYP";
    aarch64 = "AARCH64";
    riscv64 = "RISCV64";
    x64 = "X64";
  };

  schedulers = {
    legacy = false;
    mcs = true;
  };

  schedulerNameFromWhetherMCS = mcs: if mcs then "mcs" else "legacy";

  isMCSVerifiedForArch = lib.flip lib.hasAttr {
    arm = null;
    riscv64 = null;
  };

  verifiedSchedulersForArch = archName: [ "legacy" ] ++ lib.optional (isMCSVerifiedForArch archName) "mcs";

  platsForArchAndScheduler = { arch, mcs }: {
    AARCH64 = lib.optionals (!mcs) [
      "bcm2711"
      "hikey"
      "odroidc2"
      "odroidc4"
      "zynqmp"
    ];
    ARM = lib.optionals (!mcs) [
      "exynos4"
      "exynos5410"
      "exynos5422"
      "hikey"
      "tk1"
      "zynq7000"
      "zynqmp"
      "imx8mm"
    ];
    ARM_HYP = [
      "exynos5"
      "exynos5410"
    ];
  }.${arch} or [];

  optLevels = {
    o0 = "-O0";
    o1 = "-O1";
    o2 = "-O2";
    o3 = "-O3";
  };

  relevantOptLevels = {
    inherit (optLevels) o1 o2;
  };

  defaultCCWrapperAttr = "gcc";

  targetCCWrapperAttrs = lib.listToAttrs (map (v: lib.nameValuePair v v) [
    "gcc6" "gcc13" "gcc14" "gcc15" "gcc"
    "clang_18" "clang"
  ]);

  targetPkgsAccessByL4vArch = {
    "ARM" = x: x.pkgsCross.arm-embedded;
    "ARM_HYP" = x: x.pkgsCross.arm-embedded;
    "AARCH64" = x: x.pkgsCross.aarch64-embedded;
    "RISCV64" = x: x.pkgsCross.riscv64-embedded;
    "X64" = x: x;
  };

  nameModification = tag: lib.optionalString (tag != "") "_${tag}";

  gitignore = callPackage ./gitignore.nix {};

  inherit (gitignore) gitignoreSource;

  cleanL4vSource = src:
    let
      gitignoreFilter = gitignore.gitignoreFilterWith {
        basePath = src;
        # TODO this isn't working
        # extraRulesWithContextDir = [
        #   {
        #     contextDir = src + "/spec/haskell";
        #     rules = ''
        #       !src/SEL4/Object/Structures.lhs-boot
        #     '';
        #   }
        # ];
      };
    in
    lib.cleanSourceWith {
      inherit src;
      filter = path: type: gitignoreFilter path type || lib.hasSuffix "Structures.lhs-boot" path;
    };

  cleanHol4Source = src: lib.cleanSourceWith {
    inherit src;
    filter = gitignore.gitignoreFilterWith {
      basePath = src;
      extraRules = ''
        !/sigobj/README
        # HACK, TODO fix global gitignore issue
        *.so
      '';
    };
  };

  defaultSeL4IsabelleSource = downstreamGitIsabelleSource;
  # defaultSeL4IsabelleSource = upstreamGitIsabelleSource;

  downstreamGitIsabelleSource = builtins.fetchGit {
    url = "https://github.com/seL4/isabelle.git";
    ref = "ts-2025";
    rev = "836be93892924dfa8eaa1f262ce9d03fc0eef71e";
  };

  upstreamGitIsabelleSource = builtins.fetchGit {
    url = "https://github.com/seL4/isabelle.git";
    ref = "Isabelle2025";
    rev = "5cdba83cd9c7ee47081acb2df0e4a7b7a755cdce";
  };

  mkKeepRef = rev: "refs/tags/keep/${builtins.substring 0 32 rev}";

  fetchGitFromColiasGroup = { repo, rev }: builtins.fetchGit rec {
    url = "https://github.com/coliasgroup/${repo}.git";
    ref = mkKeepRef rev;
    inherit rev;
  };

  mkSourceAttrsFromRevs =
    { seL4 ? null
    , l4v ? null
    , hol4 ? null
    , graphRefine ? null
    , binaryVerification ? null
    , seL4Isabelle ? null
    } @ revs:
    lib.listToAttrs
      (lib.concatLists
        (lib.flip lib.mapAttrsToList revs (repo: rev:
          lib.optional
            (rev != null)
            (lib.nameValuePair "${repo}Source" (fetchGitFromColiasGroup {
              inherit repo rev;
            })))));

  channelSources = {
    release = {
      upstream = {
        legacy = mkSourceAttrsFromRevs {
          seL4 = "cd6d3b8c25d49be2b100b0608cf0613483a6fffa"; # seL4/seL4:13.0.0
          l4v = "205306814b6311b4781af1eb9534f674733a9735"; # direct downstream of seL4/l4v:seL4-13.0.0
        };
      };
      downstream = {
        legacy = mkSourceAttrsFromRevs {
          seL4 = "954b98b253abdbe14bcf6ffb41dcc24e52e51e9f"; # coliasgroup:verification-reproducability
          l4v = "0b3a9f606000a49ef3dd05fc16ee5a44375f1b1d";
          # l4v = throw "todo";
        };
      };
    };
    tip = {
      upstream =
        let
        in {
          legacy = mkSourceAttrsFromRevs {
            seL4 = "c5b23791ea9f65efc4312c161dd173b7238c5e80"; # tracks u/master
            l4v = "3370365c879423236fb43338403224341204d575";
          };
          mcs = mkSourceAttrsFromRevs {
            seL4 = "5dd34db6298a476a57b89cf24176dd15e674eae5"; # behind u/master
            l4v = "e16ea558bedb1177c9ed9d65e4bde86f2e304687";
          };
        };
      downstream =
        let
        in {
          legacy = mkSourceAttrsFromRevs {
            seL4 = "e125c3b55385edca57bce14450e6ef661a3cf115"; # direct downstream of upstream.legacy.seL4
            l4v = "dd5c8f88a07ada43aa4f7b2bbd22cbef276f484d";
          };
          mcs = mkSourceAttrsFromRevs {
            seL4 = throw "todo";
            l4v = throw "todo";
          };
        };
    };
  };

  mkScopeExtension = { overrideConfig, superScopeConfig }:
    lib.fix (self: {
      withOptLevel = lib.flip lib.mapAttrs optLevels (_: optLevel:
        overrideConfig {
          inherit optLevel;
        }
      );

      inherit (self.withOptLevel) o0 o1 o2 o3;

      # TODO rename to withCC
      withCC = lib.flip lib.mapAttrs targetCCWrapperAttrs (_: targetCCWrapperAttr:
        overrideConfig {
          inherit targetCCWrapperAttr;
        }
      );

      withSeL4Isabelle = overrideConfig {
        useSeL4Isabelle = true;
      };

      withoutSeL4Isabelle = overrideConfig {
        useSeL4Isabelle = false;
      };

      withChannel =
        let
          schedulerName = schedulerNameFromWhetherMCS superScopeConfig.mcs;
        in
          lib.flip lib.mapAttrs channelSources (_isRelease: isReleaseAttrs:
            lib.flip lib.mapAttrs isReleaseAttrs (_isUpstream: isUpstreamAttrs:
              overrideConfig (isUpstreamAttrs.${schedulerName})
            )
          );

      withRevs = revs: overrideConfig (mkSourceAttrsFromRevs revs);

      # HACK
      inherit fetchGitFromColiasGroup gitignoreSource cleanHol4Source;
    });

  mkScopesWith = getName: configs: lib.listToAttrs (lib.forEach configs (config: rec {
    name = getName value.scopeConfig;
    value = mkScope config;
  }));

  mkL4vScopes = mkScopesWith (scopeConfig: scopeConfig.l4vName);

  mkBVScopes = mkScopesWith (scopeConfig: scopeConfig.bvName);

  namedConfigs =
    lib.flip lib.concatMap (lib.attrNames archs) (archName:
      let
        arch = archs.${archName};
      in
      lib.flip lib.concatMap (verifiedSchedulersForArch archName) (schedulerName:
        let
          mcs = schedulers.${schedulerName};
        in
        lib.flip lib.concatMap (platsForArchAndScheduler { inherit arch mcs; } ++ [ "" ]) (plat:
          [
            {
              inherit arch mcs plat;
            }
          ]
        )
      )
    );

  scopes = mkL4vScopes namedConfigs;

  scopesWithOptLevels =
    let
      configs = lib.flip lib.concatMap namedConfigs (config:
        lib.flip lib.concatMap (lib.attrValues relevantOptLevels) (optLevel:
          lib.singleton (config // {
            inherit optLevel;
          })
        )
      );
    in
      mkBVScopes configs;

  byChannel =
    lib.flip lib.mapAttrs channelSources (_:
      lib.mapAttrs (_:
        lib.mapAttrs (_: configAttrs:
          mkL4vScopes (lib.forEach namedConfigs (config: config // configAttrs))
        )
      )
    );

  defaultScope = bvDefaultScope;

  bvDefaultScope = scopes.ARM.o1.withCC.gcc6;

  tests = writeText "aggregate-tests" (toString (lib.flatten [
    (lib.forEach (lib.attrValues scopesWithOptLevels) (scope: lib.optionals (scope.scopeConfig.plat == "") [
      (
        scope.slower
      )
    ]))
  ]));

  cached = writeText "aggregate-cached" (toString (lib.flatten [
    # TODO
    defaultScope.wip.cached
  ]));

  displayStatus =
    let
      mk = f: scope: {
        name = scope.scopeConfig.bvName;
        path = f scope;
      };
      all = scope: scope.graphRefine.all;
      justTargetDir = scope: scope.graphRefine.all.targetDir;
    in
      linkFarm "display-status" [
        (mk all scopes.ARM.o1.withChannel.release.downstream)
        (mk all scopes.ARM.o2.withChannel.release.downstream)
        (mk justTargetDir scopes.RISCV64.o1.withChannel.release.upstream)
        (mk justTargetDir scopes.RISCV64.o2.withChannel.release.upstream)
      ];

  allConfigs = lib.flip lib.concatMap namedConfigs (config:
    lib.flip lib.concatMap (lib.attrValues optLevels) (optLevel:
      lib.flip lib.concatMap (lib.attrValues targetCCWrapperAttrs) (targetCCWrapperAttr:
        lib.singleton (config // {
          inherit optLevel targetCCWrapperAttr;
        })
      )
    )
  );

  all = writeText "aggregate-all" (toString (lib.flatten [
    displayStatus
    (lib.forEach (map mkScope allConfigs) (scope:
      scope.all
    ))
  ]));

}
