{}:

let
  topLevel = import ../../../projects/bv-sandbox/nix;
in {
  inherit (topLevel)
    sel4-bv
    distrib
  ;
}
