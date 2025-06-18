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

```julia-repl
julia> using MPI
julia> MPI.install_mpiexecjl()
```

By default, it will install to `~/.julia/bin`, but you can also choose to install it somewhere else

As an example to install it in the current working directory.

```
julia> using MPI
julia> MPI.install_mpiexecjl(destdir=".")
```

After installing it, you can use it to start Julia.

```
mpiexecjl --project=/path/to/project -n 4 julia script.jl
# or
./mpiexecjl --project=/path/to/project -n 4 julia script.jl
```

## Exercises

MPI.jl has a series of examples:

- [Hello word](https://juliaparallel.org/MPI.jl/v0.20/examples/01-hello/)
- [Broadcast](https://juliaparallel.org/MPI.jl/v0.20/examples/02-broadcast/)
- [Reduce](https://juliaparallel.org/MPI.jl/v0.20/examples/03-reduce/)
- [Send/receive](https://juliaparallel.org/MPI.jl/v0.20/examples/04-sendrecv/)

### Diffusion

In [exercise 2](https://vchuravy.dev/rse-course/exercises/exercise_2_accelerated/) we looked at a diffusion kernel.
Instead of implementing this on the GPU you can also implement it with MPI.

!!! note
    The "hard" part is the handling of the boundary-conditions and ghost cells. So focus on that in the beginning.
    How are you going to split the computational domain? Who needs to talk to whom?