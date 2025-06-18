---
title: "Running MPI.jl locally"
order: 10.1
exercise_number: 12
chapter: 3
section: 3
layout: "md.jlmd"
image: ""
tags: ["module3", "track_parallel", "exercises"]
---

## Configuration

There are multiple MPI implementations

- OpenMPI
- MPICH
- Intel MPI
- Microsoft MPI
- IBM Spectrum MPI
- MVAPICH
- Cray MPICH
- Fujitsu MPI
- HPE MPT/HMPT

```julia-repl
julia> using MPI

julia> MPI.versioninfo()

MPIPreferences:
  binary:  MPICH_jll
  abi:     MPICH

Package versions
  MPI.jl:             0.20.22
  MPIPreferences.jl:  0.1.11
  MPICH_jll:          4.3.0+1

Library information:
  libmpi:  /home/vchuravy/.julia/artifacts/05d8c79b270470018e9de8dd24ddb6d7954aff9d/lib/libmpi.so
  libmpi dlpath:  /home/vchuravy/.julia/artifacts/05d8c79b270470018e9de8dd24ddb6d7954aff9d/lib/libmpi.so
  MPI version:  4.1.0
  Library version:
    MPICH Version:      4.3.0
    MPICH Release date: Mon Feb  3 09:09:47 AM CST 2025
    MPICH ABI:          17:0:5
    MPICH Device:       ch3:nemesis
    MPICH configure:    --build=x86_64-linux-musl --disable-dependency-tracking --disable-doc --enable-fast=ndebug,O3 --enable-static=no --host=x86_64-linux-gnu --prefix=/workspace/destdir --with-device=ch3 --with-hwloc=/workspace/destdir
    MPICH CC:           cc     -DNDEBUG -DNVALGRIND -O3
    MPICH CXX:          c++   -DNDEBUG -DNVALGRIND -O3
    MPICH F77:          gfortran   -O3
    MPICH FC:           gfortran   -O3
    MPICH features:
```

On Unix, `MPI.jl` will install and use `MPICH` through the `MPICH_jll` package. 

### MPIPreferences

To switch which MPI implementation `MPI.jl` uses you can use the package `MPIPreferences.jl`.

For more information see: [https://juliaparallel.org/MPI.jl/stable/configuration/](https://juliaparallel.org/MPI.jl/stable/configuration/)

When executing on a cluster you will likely need to configure `MPI.jl` to use the system provided MPI.



## Installing `mpiexecjl`



