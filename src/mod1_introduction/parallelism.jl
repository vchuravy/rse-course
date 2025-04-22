### A Pluto.jl notebook ###
# v0.20.6

#> [frontmatter]
#> chapter = "1"
#> section = "2"
#> order = "2"
#> title = "Parallelism"
#> date = "2025-04-23"
#> tags = ["module1", "track_parallel"]
#> layout = "layout.jlhtml"
#> 
#>     [[frontmatter.author]]
#>     name = "Valentin Churavy"
#>     url = "https://vchuravy.dev"

using Markdown
using InteractiveUtils

# ╔═╡ 07565449-7cf6-47f2-b8f7-5a1bb2cd56ce
using PlutoUI, PlutoTeachingTools

# ╔═╡ 5c4c21e4-1a90-11f0-2f05-47d877772576
using Hwloc

# ╔═╡ df284ffd-14eb-41eb-a4b8-94f4d7cee298
ChooseDisplayMode()

# ╔═╡ 6044b1cf-97b2-428c-8d2c-d3cf078599f3
PlutoUI.TableOfContents(; depth=4)

# ╔═╡ 4af02ca9-0b62-463e-ab58-7eea703ed638
md"""
# Parallelism
"""

# ╔═╡ 97ee45b8-77a7-48b8-96ef-ad38b68cfe9e
md"""
## Notions of scalability
"""

# ╔═╡ 1fccadd6-498f-4d10-8740-81f4e2114e03
md"""
## Node-level

This notebook uses **$(Threads.nthreads()) threads**
"""

# ╔═╡ 6327d081-fabd-4b9d-9627-01f18a537409
with_terminal() do
	Sys.cpu_summary()
end

# ╔═╡ 0b1b3a0d-ee2a-4a97-98b7-e6a40da9465e
with_terminal() do
	Hwloc.topology()
end

# ╔═╡ c8c5bf61-c6ca-495f-82f1-fbf84d29be57
md"""
### Shared-memory parallelism

- Julia is task-based (`M:N`-threading, green threads)
- `Channel`, locks and atomics

```julia
function pfib(n::Int)
    if n <= 1
        return n
    end
    t = Threads.@spawn pfib(n-2)
    return pfib(n-1) + fetch(t)::Int
end
```

```julia
using Base.Threads: @threads
function prefix_threads!(⊕, y::AbstractVector)
	l = length(y)
	k = ceil(Int, log2(l))
	# do reduce phase
	for j = 1:k
		@threads for i = 2^j:2^j:min(l, 2^k)
			@inbounds y[i] = y[i - 2^(j - 1)] ⊕ y[i]
		end
	end
	# do expand phase
	for j = (k - 1):-1:1
		@threads for i = 3*2^(j - 1):2^j:min(l, 2^k)
			@inbounds y[i] = y[i - 2^(j - 1)] ⊕ y[i]
		end
	end
	return y
end
A = fill(1, 500_000)
prefix_threads!(+, A)
```

From

> Nash et al., (2021). Basic Threading Examples in JuliaLang v1.3. JuliaCon Proceedings, 1(1), 54, https://doi.org/10.21105/jcon.00054
"""

# ╔═╡ d0d64acb-2eb5-4bbe-aac0-05a2ef1bd97a
md"""
### Composable parallelism

- The issue with BLAS
"""

# ╔═╡ 971b0fc4-cf03-44e6-a515-fdb74a36003f
md"""
### Acelerated
"""

# ╔═╡ 2cc61da7-f7b2-46fa-85c8-ed5cdd3e412a
md"""
#### Composable infrastructure

##### Core
- GPUCompiler.jl: Takes native Julia code and compiles it directly to GPUs
- GPUArrays.jl: High-level array based common functionality
- KerneAbstractions.jl: Vendor-agnostic kernel programming language
- Adapt.jl: Translate complex structs across the host-device boundary

##### Vendor specific
- CUDA.jl
- AMDGPU.jl
- oneAPI.jl
- Metal.jl

"""

# ╔═╡ b21b17f7-bc3e-4286-ad0b-3004e1bb4d78
md"""
#### Different layers of abstraction

##### Vendor-specific
```julia
using CUDA

function saxpy!(a,X,Y)
	i = (blockIdx().x - 1) * blockDim().x + threadIdx().x
	if i <= length(Y)
		@inbounds Y[i] = a * X[i] + Y[i]
	end
	return nothing
end

@cuda threads=32 blocks=cld(length(Y), 32) saxpy!(a, X, Y)
```

##### KernelAbstractions

```julia
using KernelAbstractions
using CUDA

@kernel function saxpy!(a, @Const(X), Y)
    I = @index(Global)
    @inbounds Y[I] = a * X[I] + Y[I]
end

saxpy!(CUDABackend())(a, X, Y, ndrange=length(Y))
```

##### Array abstractions

```julia
Y .= a .* X .+ Y
```

"""

# ╔═╡ 38b99eb2-a6dc-4872-ab86-8f21cb4c7f59
md"""
### High-level array based programming

Julia and GPUArrays.jl provide support for an efficient GPU programming environment build around array abstractions and higher-order functions.

- **Vocabulary of operations**: `map`, `broadcast`, `scan`, `reduce`, ... 
  Map naturally onto GPU execution models
- **Compiled to efficient code**: multiple dispatch, specialization
  Write generic, reusable applications
- BLAS (matrix-multiply, ...), and other libraries like FFT

> Array operators using multiple dispatch: a design methodology for array implementations in dynamic languages 
> 
> (doi:10.1145/2627373.2627383)

> Rapid software prototyping for heterogeneous and distributed platforms 
>
> (doi:10.1016/j.advengsoft.2019.02.002)
"""

# ╔═╡ a10ab271-4a58-47d3-90d6-8d48745ce712
md"""
Array types -- **where** memory resides and **how** code is executed.

|  |  |
| --- | --- |
|  `A = Matrix{Float64}(undef, 64, 32)`   | CPU   |
|  `A = CuMatrix{Float64}(undef, 64, 32)`   | Nvidia GPU   |
|  `A = ROCMatrix{Float64}(undef, 64, 32)`   | AMD GPU   |

!!! info
    Data movement is explicit.
"""

# ╔═╡ 33d2c72d-f6f1-4805-b3a6-1c6c6e79caa3
md"""
### What makes an application portable?

1. Can I **run** it on a different compute architecture
    1. Different CPU architectures
    2. We live in a mult GPU vendor world
2. Does it **compute** the same thing?
    1. Can I develop on one platform and move to another later?
3. Does it achieve the same **performance**?
4. Can I take advantage of platform **specific** capabilities?

> Productivity meets Performance: Julia on A64FX (doi:10.1109/CLUSTER51413.2022.00072)
"""

# ╔═╡ 1b20ca8f-81a4-4f28-8c9e-02fd3c3b986a
md"""
### Adapt.jl

[Adapt.jl](https://github.com/JuliaGPU/Adapt.jl) is a lightweight dependency that you can use to convert complex structures from CPU to GPU.

```julia
using Adapt
adapt(CuArray, ::Adjoint{Array})::Adjoint{CuArray}
```

```julia
struct Model{T<:Number, AT<:AbstractArray{T}}
   data::AT
end

Adapt.adapt_structure(to, x::Model) = Model(adapt(to, x.data))


cpu = Model(rand(64, 64));
using CUDA

gpu = adapt(CuArray, cpu)
Model{Float64, CuArray{Float64, 2, CUDA.Mem.DeviceBuffer}}(...)
```
"""

# ╔═╡ b4a9d35e-eeb2-41a4-9159-0e9b78d51ef6
md"""
## Multi-Node / Distributed
"""

# ╔═╡ 5cdd4e72-835f-4123-91d0-a5da8bf8f365
md"""
```julia
using MPI
MPI.Init()

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)
size = MPI.Comm_size(comm)

dst = mod(rank+1, size)
src = mod(rank-1, size)

N = 4

send_mesg = Array{Float64}(undef, N)
recv_mesg = Array{Float64}(undef, N)

fill!(send_mesg, Float64(rank))

rreq = MPI.Irecv!(recv_mesg, comm; source=src, tag=src+32)

sreq = MPI.Isend(send_mesg, comm; dest=dst, tag=rank+32)

stats = MPI.Waitall([rreq, sreq])

MPI.Barrier(comm)
```
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Hwloc = "0e44f5e4-bd66-52a0-8798-143a42290a1d"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Hwloc = "~3.3.0"
PlutoTeachingTools = "~0.2.15"
PlutoUI = "~0.7.60"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.4"
manifest_format = "2.0"
project_hash = "2ef4f35dfb1a556952ee119fd453ea81ab443df6"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "062c5e1a5bf6ada13db96a4ae4749a4c2234f521"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.3.9"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.Hwloc]]
deps = ["CEnum", "Hwloc_jll", "Printf"]
git-tree-sha1 = "6a3d80f31ff87bc94ab22a7b8ec2f263f9a6a583"
uuid = "0e44f5e4-bd66-52a0-8798-143a42290a1d"
version = "3.3.0"

    [deps.Hwloc.extensions]
    HwlocTrees = "AbstractTrees"

    [deps.Hwloc.weakdeps]
    AbstractTrees = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"

[[deps.Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f93a9ce66cd89c9ba7a4695a47fd93b4c6bc59fa"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.12.0+0"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "a007feb38b422fbdab534406aeca1b86823cb4d6"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "c47892541d03e5dc63467f8964c9f2b415dfe718"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.46"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Latexify]]
deps = ["Format", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "cd10d2cc78d34c0e2a3a36420ab607b611debfbb"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.7"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.6.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.7.2+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "39240b5f66956acfa462d7fe12efe08e26d6d70d"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "3.2.2"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OrderedCollections]]
git-tree-sha1 = "cc4054e898b852042d7b503313f7ad03de99c3dd"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "44f6c1f38f77cafef9450ff93946c53bd9ca16ff"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PlutoHooks]]
deps = ["InteractiveUtils", "Markdown", "UUIDs"]
git-tree-sha1 = "072cdf20c9b0507fdd977d7d246d90030609674b"
uuid = "0ff47ea0-7a50-410d-8455-4348d5de0774"
version = "0.0.5"

[[deps.PlutoLinks]]
deps = ["FileWatching", "InteractiveUtils", "Markdown", "PlutoHooks", "Revise", "UUIDs"]
git-tree-sha1 = "8f5fa7056e6dcfb23ac5211de38e6c03f6367794"
uuid = "0ff47ea0-7a50-410d-8455-4348d5de0420"
version = "0.1.6"

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "LaTeXStrings", "Latexify", "Markdown", "PlutoLinks", "PlutoUI", "Random"]
git-tree-sha1 = "5d9ab1a4faf25a62bb9d07ef0003396ac258ef1c"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.2.15"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eba4810d5e6a01f612b948c9fa94f905b49087b0"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.60"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.Revise]]
deps = ["CodeTracking", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "4e58145c98094ab2405b8fca034e21bde6c06c1c"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.7.5"

    [deps.Revise.extensions]
    DistributedExt = "Distributed"

    [deps.Revise.weakdeps]
    Distributed = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

[[deps.URIs]]
git-tree-sha1 = "cbbebadbcc76c5ca1cc4b4f3b0614b3e603b5000"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╠═07565449-7cf6-47f2-b8f7-5a1bb2cd56ce
# ╟─df284ffd-14eb-41eb-a4b8-94f4d7cee298
# ╟─6044b1cf-97b2-428c-8d2c-d3cf078599f3
# ╟─4af02ca9-0b62-463e-ab58-7eea703ed638
# ╟─97ee45b8-77a7-48b8-96ef-ad38b68cfe9e
# ╟─1fccadd6-498f-4d10-8740-81f4e2114e03
# ╠═6327d081-fabd-4b9d-9627-01f18a537409
# ╠═5c4c21e4-1a90-11f0-2f05-47d877772576
# ╠═0b1b3a0d-ee2a-4a97-98b7-e6a40da9465e
# ╟─c8c5bf61-c6ca-495f-82f1-fbf84d29be57
# ╟─d0d64acb-2eb5-4bbe-aac0-05a2ef1bd97a
# ╟─971b0fc4-cf03-44e6-a515-fdb74a36003f
# ╟─2cc61da7-f7b2-46fa-85c8-ed5cdd3e412a
# ╟─b21b17f7-bc3e-4286-ad0b-3004e1bb4d78
# ╟─38b99eb2-a6dc-4872-ab86-8f21cb4c7f59
# ╟─a10ab271-4a58-47d3-90d6-8d48745ce712
# ╟─33d2c72d-f6f1-4805-b3a6-1c6c6e79caa3
# ╟─1b20ca8f-81a4-4f28-8c9e-02fd3c3b986a
# ╟─b4a9d35e-eeb2-41a4-9159-0e9b78d51ef6
# ╟─5cdd4e72-835f-4123-91d0-a5da8bf8f365
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
