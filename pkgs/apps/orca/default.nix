{ lib, stdenv, requireFile, autoPatchelfHook, makeWrapper
, openmpi, openssh
} :

let
  version = "5.0.2";

in stdenv.mkDerivation {
  pname = "orca";
  inherit version;

  src = requireFile {
    name = "orca_5_0_2_linux_x86-64_shared_openmpi411.tar.xz";
    sha256 = "3a26a1a5fbc69e7dca0192237b5e16b69886df31751ae59f7396461428aeee96";
    message = "Please get a copy of orca-${version} from https://orcaforum.kofo.mpg.de (it's free).";
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [ openmpi stdenv.cc.cc.lib ];

  installPhase = ''
    mkdir -p $out/bin $out/lib $out/share/doc/orca

    cp autoci_* $out/bin
    cp orca_* $out/bin
    cp orca $out/bin
    cp otool_* $out/bin

    cp -r ORCACompoundMethods $out/bin/.

    cp *.so.5 $out/lib/.

    cp *.pdf $out/share/doc/orca

    wrapProgram $out/bin/orca --prefix PATH : '${openmpi}/bin:${openssh}/bin'
  '';

  doInstallCheck = true;

  installCheckPhase = ''
    cat << EOF > inp
    ! RHF STO-3G NORI PATOM
    %output
    PrintLevel=Normal
    Print[ P_MOs         ] 1
    end
    %pal nprocs 4 #### no. of procs #####
    end
    %maxcore 1000
    #### give all coords in Angstrom #######
    * xyz 0 1
    O       0.000000  0.000000  0.000000
    H       0.758602  0.000000  0.504284
    H       0.758602  0.000000 -0.504284
    *
    EOF

    export OMPI_MCA_rmaps_base_oversubscribe=1
    $out/bin/orca inp > log

    echo "Check for sucessful run:"
    grep "ORCA TERMINATED NORMALLY" log
    echo "Check for correct energy:"
    grep "FINAL SINGLE POINT ENERGY" log | grep 74.880174
  '';

  passthru = { mpi = openmpi; };

  meta = with lib; {
    description = "Ab initio quantum chemistry program package";
    homepage = "https://orcaforum.kofo.mpg.de/";
    license = licenses.unfree;
    maintainers = [ maintainers.markuskowa ];
    platforms = [ "x86_64-linux" ];
  };
}
