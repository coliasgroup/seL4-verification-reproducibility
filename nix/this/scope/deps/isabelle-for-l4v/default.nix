{ lib
, stdenv
, callPackage
, writeText
, runCommand
, isabelle

, scopeConfig
, mltonForL4v
}:

useSeL4IsabelleSource:

let
  inherit (scopeConfig) seL4IsabelleSource;

  components = callPackage ./components.nix {} {
    componentsDir = seL4IsabelleSource + "/Admin/components";
  };

  bundle = with components.componentLists; main ++ bundled;

  bundleList = writeText "x" ''
    #bundled components
    ${lib.concatMapStringsSep "\n" ({ name, ... }: "contrib/${name}") bundle}
  '';

  preparedSeL4Src = stdenv.mkDerivation {
    name = "sel4-isabelle-src";
    src = seL4IsabelleSource;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      cat ${bundleList} >> etc/components
      mkdir contrib
      ${lib.concatStrings (lib.forEach bundle ({ name, value }: ''
        cp -r ${value} contrib/${name}
      ''))}
      cp -r . $out
    '';
  };
      # rm -r Admin

  unpackedUpstreamSrc = stdenv.mkDerivation {
    name = "isabelle-src";
    inherit (isabelle) src;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      cp -r . $out
    '';
  };

  diff = runCommand "x" {} ''
    diff -rq ${unpackedUpstreamSrc} ${preparedSeL4Src}
  '';
in

lib.extendDerivation true {
  mlton = mltonForL4v;
  inherit unpackedUpstreamSrc;
  inherit preparedSeL4Src;
  inherit diff;
} (isabelle.overrideAttrs (attrs: lib.optionalAttrs useSeL4IsabelleSource {
  name = "${attrs.pname}-${attrs.version}-for-seL4";
  src = preparedSeL4Src;
  sourceRoot = null;
  postUnpack = ''
    oldSourceRoot=$sourceRoot
    sourceRoot=${attrs.dirname}
    mv $oldSourceRoot $sourceRoot
  '';
  prePatch = (attrs.prePatch or "") + ''
    touch heaps
  '';
}))
