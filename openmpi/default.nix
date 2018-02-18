{ stdenv, fetchurl, gfortran, perl, libnl, rdma-core, zlib

# Enable the Sun Grid Engine bindings
, enableSGE ? false

# Pass PATH/LD_LIBRARY_PATH to point to current mpirun by default
, enablePrefix ? false

# Compile Fortran interface with default integer size 8 byte
, ILP64 ? false
}:

let
  majorVersion = "3.0";
  minorVersion = "0";

in stdenv.mkDerivation rec {
  name = "openmpi-${majorVersion}.${minorVersion}";

  src = fetchurl {
    url = "http://www.open-mpi.org/software/ompi/v${majorVersion}/downloads/${name}.tar.bz2";
    sha256 = "1mw2d94k6mp4scg1wnkj50vdh734fy5m2ygyrj65s4mh3prbz6gn";
  };

  postPatch = ''
    patchShebangs ./
  '';

  buildInputs = with stdenv; [ gfortran zlib ]
    ++ lib.optional isLinux libnl
    ++ lib.optional (isLinux || isFreeBSD) rdma-core;

  nativeBuildInputs = [ perl ];

  configureFlags = with stdenv; []
    ++ lib.optional isLinux  "--with-libnl=${libnl.dev}"
    ++ lib.optional enableSGE "--with-sge"
    ++ lib.optional enablePrefix "--enable-mpirun-prefix-by-default"
    ++ lib.optional ILP64 "--with-wrapper-fcflags=-fdefault-integer-8"
    ;

  FCFLAGS="${if ILP64 then "-fdefault-integer-8" else ""}";

  enableParallelBuilding = true;

  postInstall = ''
    rm -f $out/lib/*.la
   '';

  doCheck = true;

  meta = with stdenv.lib; {
    homepage = http://www.open-mpi.org/;
    description = "Open source MPI-3 implementation";
    longDescription = "The Open MPI Project is an open source MPI-3 implementation that is developed and maintained by a consortium of academic, research, and industry partners. Open MPI is therefore able to combine the expertise, technologies, and resources from all across the High Performance Computing community in order to build the best MPI library available. Open MPI offers advantages for system and software vendors, application developers and computer science researchers.";
    maintainers = with maintainers; [ markuskowa ];
    license = licenses.bsd3;
    platforms = platforms.unix;
  };
}
