{ stdenvForHol4
, writeText
, makeFontsConf
, python3, perl
, graphviz

, polymlForHol4
, mltonForHol4
, decompilerSource

, emacsWithPackages

, hol4-core
}:

# TODO
# Address:
# Fontconfig error: No writable cache directories

# TODO
# ./bin/build -j $NIX_BUILD_CORES
# ./bin/build --relocbuild

let

  emacsForShell = emacsWithPackages (epkgs: [
  ]);

  localSrc = toString ../../../projects/HOL4;

  emacsInit = writeText "init.el" ''
    (transient-mark-mode 1)
    (load (concat "${localSrc}" "/tools/editor-modes/emacs/hol-mode"))
    (load (concat "${localSrc}" "/tools/editor-modes/emacs/hol-unicode"))
  '';
    # (load (concat (getenv "PWD") "/tools/hol-mode"))
    # (load (concat (getenv "PWD") "/tools/hol-unicode"))
in

stdenvForHol4.mkDerivation {
  name = "decompiler";

  src = decompilerSource;

  phases = [ "unpackPhase" "patchPhase" "buildPhase" ];

  # depsBuildBuid = [
  #   emacsForShell
  # ];

  nativeBuildInputs = [
    polymlForHol4 mltonForHol4
    python3 perl
    graphviz
  ];

  postPatch = ''
    patchShebangs .
  '';

  buildPhase = ''
    holdir=$out
    cp -r --preserve=timestamps ${hol4-core} $holdir
    chmod -R +w $holdir
    cp -r . $holdir/examples
    cd $holdir

    poly < tools/smart-configure.sml
    bin/build --relocbuild
    cd examples/machine-code/graph
    $holdir/bin/Holmake -j $NIX_BUILD_CORES
  '';

  # TODO longer aliases to avoid collisions
  # shellHook = ''
  #   holdir=$PWD

  #   c() {
  #     poly < tools/smart-configure.sml
  #   }

  #   b() {
  #     bin/build -j$(nproc)
  #   }

  #   be() {
  #     (cd examples/machine-code/graph && $holdir/bin/Holmake -j$(nproc))
  #   }

  #   e() {
  #     emacs -l ${emacsInit}
  #   }

  #   ee() {
  #     echo emacs -l ${emacsInit}
  #   }
  # '';
}
