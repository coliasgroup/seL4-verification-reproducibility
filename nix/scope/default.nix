{ lib
, texlive
}:

self: with self; {

  rawSources = {
    seL4 = lib.cleanSource ../../projects/seL4;
    l4v = lib.cleanSource ../../projects/l4v;
    hol4 = lib.cleanSource ../../projects/HOL4;
    graph-refine = lib.cleanSource ../../projects/graph-refine;
  };

  sources = {
    inherit (rawSources) hol4 graph-refine;
    seL4 = callPackage ./sel4-source.nix {};
    l4v = callPackage ./l4v-source.nix {};
  };

  texlive-env = with texlive; combine {
    inherit
      collection-fontsrecommended
      collection-latexextra
      collection-metapost
      collection-bibtexextra
      ulem
    ;
  };

  armv7Pkgs = import ../../nixpkgs {
    crossSystem = {
      system = "armv7l-linux";
      config = "armv7l-unknown-linux-gnueabi";
    };
  };

  hol4 = callPackage ./hol4.nix {};

  isabelle-sha1 = callPackage ./isabelle-sha1.nix {};

  initial-heaps = callPackage ./initial-heaps.nix {};

  specs = callPackage ./specs.nix {};

  tests = callPackage ./tests.nix {
    # verbose = true;
    testTargets = [
      "CRefine"
      "SimplExportAndRefine"
    ];
  };

  bv = callPackage ./bv.nix {};

  all = [
    specs
    tests
    hol4
  ];
}