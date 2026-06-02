{ stdenvNoCC
, python312
, scopeConfig
}:

stdenvNoCC.mkDerivation {
  name = "l4v-source";

  src = scopeConfig.l4vSource;

  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  nativeBuildInputs = [
    python312
  ];

  postPatch = ''
    patchShebangs .
  '';

  installPhase = ''
    cp -r . $out
  '';
}
