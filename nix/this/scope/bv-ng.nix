{}:

let
  topLevel = import ../../../projects/bv-sandbox/nix;
in {
  inherit (topLevel)
    sel4-bv
    sel4-bv-test
    distrib
  ;
}
