{ lib
, runCommand
, cmake, ninja
, dtc, libxml2
, python3Packages
, perl
, which

, patchedSeL4Source
, scopeConfig
, toolchainAttrs
, standaloneCParser
, isabelleForL4v
, mltonForL4v

, pkgsBuildBuild
}:

assert scopeConfig.optLevel != null;

runCommand "kernel-${scopeConfig.longBVName}" ({

  nativeBuildInputs = [
    cmake ninja
    dtc libxml2
    which
    python3Packages.sel4-deps
    scopeConfig.targetCC
    scopeConfig.targetBintools
    perl
    isabelleForL4v
    mltonForL4v
  ];

  L4V_ARCH = scopeConfig.arch;
  L4V_FEATURES = scopeConfig.features;
  L4V_PLAT = scopeConfig.plat;

  OBJDUMP = "${scopeConfig.targetPrefix}objdump";

  L4V_REPO_PATH = standaloneCParser;
  SOURCE_ROOT = patchedSeL4Source;

  CONFIG_OPTIMISATION = scopeConfig.optLevel;

} // toolchainAttrs) ''
  export HOME=$(mktemp -d --suffix=-home)

  export ISABELLE_HOME=$(isabelle env sh -c 'echo $ISABELLE_HOME')

  export KERNEL_BUILD_ROOT=build

  export KERNEL_EXPORT_DIR=$out

  make -f $L4V_REPO_PATH/spec/cspec/c/kernel.mk kernel_export
''
