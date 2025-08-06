{}:

let
  topLevel = import ../../../projects/binary-verification/nix;
in {
  inherit (topLevel)
    sel4-bv
    sel4-bv-test
    distrib
  ;
}
