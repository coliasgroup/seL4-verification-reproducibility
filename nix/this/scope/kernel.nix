{ lib
, runCommand
, cmake, ninja
, dtc, libxml2
, python3Packages
, perl

, patchedSeL4Source
, scopeConfig
, standaloneCParser
, isabelleForL4v
}:

# NOTE
# CONFIG_OPTIMISATION is more correct but KERNEL_CMAKE_EXTRA_OPTIONS is more
# backwards-compatible.

let
  files = [
    "kernel_all.c_pp"
    "kernel.elf"
    "kernel.elf.rodata"
    "kernel.elf.txt"
    "kernel.elf.symtab"
    "kernel.sigs"
  ];

in
runCommand "kernel" {

  nativeBuildInputs = [
    cmake ninja
    dtc libxml2
    python3Packages.sel4-deps
    scopeConfig.targetCC
    scopeConfig.targetBintools
    perl
    isabelleForL4v
    isabelleForL4v.mlton
  ];

  L4V_ARCH = scopeConfig.arch;
  L4V_FEATURES = scopeConfig.features;
  L4V_PLAT = scopeConfig.plat;
  TOOLPREFIX = scopeConfig.targetPrefix;

  OBJDUMP = "${scopeConfig.targetPrefix}objdump";

  L4V_REPO_PATH = standaloneCParser;
  SOURCE_ROOT = patchedSeL4Source;

  KERNEL_CMAKE_EXTRA_OPTIONS = "-DKernelOptimisation=${scopeConfig.optLevel}";

} ''
  export HOME=$(mktemp -d --suffix=-home)

  export ISABELLE_HOME=$(isabelle env sh -c 'echo $ISABELLE_HOME')

  export KERNEL_BUILD_ROOT=$out

  make -f $L4V_REPO_PATH/spec/cspec/c/kernel.mk \
    ${lib.concatMapStringsSep " " (file: "$KERNEL_BUILD_ROOT/${file}") files}
''
