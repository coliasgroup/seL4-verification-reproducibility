{ lib
, runCommand
, writeText
, git

, scopeConfig
, hol4
, kernel
}:

# TODO
# prefix with "time" invocation

let
  # NOTE only change to this list since seL4-12.0.0 is the addition of "_start"
  ignoreList = [
    "_start" "c_handle_fastpath_call" "c_handle_fastpath_reply_recv" "restore_user_context"
  ] ++ scopeConfig.extraDecompileExclude;

  keep = "chooseThread";
  # keep = "create_untypeds_for_region";

  # ignoreFile = runCommand "ignore" {} ''
  #   cat ${kernel}/kernel.sigs | cut -d ' ' -f 2 | grep -v ${keep} | sed "s,StrictC',," | tr '\n' ',' | sed 's/,$/\n/' > $out
  # '';

  ignoreFile = writeText "ignore" (lib.concatStringsSep "," ignoreList);

  scriptIn = writeText "x.sml" ''
    load "decompileLib";
    val _ = decompileLib.decomp "@path@" true "@ignore@";
  '';

  unchecked = runCommand "decompilation-${scopeConfig.longBVName}" {
    nativeBuildInputs = [
      git
    ];
  }''
    target_dir=$(pwd)/target
    script=$(pwd)/script

    mkdir $target_dir
    cp ${kernel}/{kernel.elf.*,kernel.sigs} target

    substitute ${scriptIn} $script \
      --subst-var-by path $target_dir/kernel \
      --subst-var-by ignore $(cat ${ignoreFile})

    cd ${hol4}/examples/machine-code/graph
    echo "decompiling..."
    time ${hol4}/bin/hol < $script | tee $target_dir/log.txt | grep '\( of \)\|\(Export FAILED\)'
    cp -r $target_dir $out
  '';
  # TODO add "Exception-" to grep line above
in
# TODO longBVName in name
runCommand "decompilation-checked-${scopeConfig.longBVName}" {
  passthru = {
    inherit unchecked;
  };
} ''
  echo "checking ${unchecked}"

  if grep 'Export FAILED' ${unchecked}/log.txt ${lib.optionalString (scopeConfig.arch == "RISCV64") ''
    | grep -v -F ' __global_pointer$.' \
  ''}; then
    false
  fi

  if ! grep -Pzl 'Summary\n=======\n' ${unchecked}/log.txt; then
    echo "Summary not present" >&2
    false
  fi

  cp -r ${unchecked} $out
''
