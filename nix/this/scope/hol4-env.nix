{ lib
, mkShell
, writeText
, makeFontsConf
, python3, perl
, graphviz

, polymlForHol4
, mltonForHol4
, hol4Source

, emacsWithPackages
}:

let

  emacsForShell = emacsWithPackages (epkgs: [
  ]);

  localSrc = toString ../../../tmp/src/HOL;

  emacsInit = writeText "init.el" ''
    (transient-mark-mode 1)
    (load (concat "${localSrc}" "/tools/editor-modes/emacs/hol-mode"))
    (load (concat "${localSrc}" "/tools/editor-modes/emacs/hol-unicode"))
  '';
    # (load (concat (getenv "HOLDIR") "/tools/hol-mode"))
    # (load (concat (getenv "HOLDIR") "/tools/hol-unicode"))
in

mkShell {
  name = "hol4-env";

  nativeBuildInputs = [
    polymlForHol4 mltonForHol4
    python3 perl
    graphviz
    emacsForShell
  ];

  # TODO longer aliases to avoid collisions
  shellHook = ''
    HOLDIR=${localSrc}

    hc() {
      (cd $HOLDIR && poly < tools/smart-configure.sml)
    }

    hb() {
      (cd $HOLDIR && bin/build -j$(nproc))
    }

    hbe() {
      (cd $HOLDIR/examples/machine-code/graph && $HOLDIR/bin/Holmake -j$(nproc))
    }

    he() {
      emacs -l ${emacsInit}
    }
  '';
}
