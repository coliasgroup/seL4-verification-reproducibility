{ stdenv
, python3
, scopeConfig
}:

stdenv.mkDerivation {
  name = "l4v-source";

  src = scopeConfig.l4vSource;

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  nativeBuildInputs = [
    python3
  ];

  patches = [
    ./improve-psutil-check.patch
  ];

  postPatch = ''
    patchShebangs .

    for x in tools/c-parser/tools/{mllex,mlyacc}/Makefile; do
      substituteInPlace $x --replace /bin/echo echo
    done

    sed -i -E 's/^(license: +)GPL$/\1GPL-2.0-only/' spec/haskell/SEL4.cabal

    substituteInPlace spec/haskell/Makefile \
      --replace 'sandbox: .stack-work' 'sandbox:' \
      --replace 'CABAL=stack exec -- ./stack-path cabal' 'CABAL=cabal' \
      --replace 'CABAL_SANDBOX=$(CABAL) v1-sandbox' 'CABAL_SANDBOX=true' \
      --replace 'CABAL_UPDATE=$(CABAL) v1-update' 'CABAL_UPDATE=true'
  '';

  installPhase = ''
    cp -r . $out
  '';
}
