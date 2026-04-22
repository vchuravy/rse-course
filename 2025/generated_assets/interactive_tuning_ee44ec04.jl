### A Pluto.jl notebook ###
# v0.20.13

#> [frontmatter]
#> chapter = "3"
#> section = "1"
#> order = "8.2"
#> title = "Interactive performance tuning with Julia"
#> tags = ["module3", "track_parallel", "indepth"]
#> layout = "layout.jlhtml"
#> indepth_number = "3"
#> 
#>     [[frontmatter.author]]
#>     name = "Mosè Giordano"
#>     url = "https://giordano.github.io/"

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    #! format: off
    return quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
    #! format: on
end

# ╔═╡ bbbe6c9c-f032-41b7-a976-c6fd5666adf5
TableOfContents()

# ╔═╡ 630971b1-9053-427e-8ede-41bde809befb
md"""# Interactive performance tuning with Julia

!!! note "Thread pinning"

    Remember to pin the threads of your programs! This notebook runs on a Slurm cluster and uses [`ThreadPinning.jl`](https://github.com/carstenbauer/ThreadPinning.jl) to pin the Julia process to the CPU threads allocated by Slurm by using the `SLURM_CPU_BIND_LIST` environment variable.

Part of this presentation will use material from the workshop [Julia for HPC @ UCL 2024](https://github-pages.arc.ucl.ac.uk/julia-hpc-2024/) run by **Carsten Bauer**, the course material is available at [carstenbauer/JuliaUCL24](https://github.com/carstenbauer/JuliaUCL24).
"""

# ╔═╡ a4906361-f71d-4376-8d64-a4c8fa9153fa
md"""
!!! warn
    This notebook uses and LIKWID & LinuxPerf.jl, which requires Linux!
"""

# ╔═╡ c7f41ccc-062d-4446-b121-a009334c6b64
using ThreadPinning

# ╔═╡ b2e4f4a1-e516-42d4-bd34-09ba3bdeecc9
# ThreadPinning.pinthreads(Int.(log2.(parse.(BigInt, first(split(ENV["SLURM_CPU_BIND_LIST"], ','), Threads.nthreads())))); warn=false)

# ╔═╡ 68e51081-9150-43cb-91a1-333d8c97ae37
ThreadPinning.pinthreads(:cores)

# ╔═╡ 1cf0469b-664a-4ae8-948b-044c3b11d60e
with_terminal(() -> ThreadPinning.threadinfo())

# ╔═╡ a282a68c-f485-4c61-9ba0-6867c9b445e1
using CpuId

# ╔═╡ fe999d9b-9684-4d4a-ac87-b826a476c6e1
cpuinfo()

# ╔═╡ 30cf6b5f-7043-4e08-829d-b263f332103d
Sys.CPU_NAME

# ╔═╡ cf2a3f32-36a7-4db8-b172-9535b7fc702d
md"""
## Simple linear algebra
"""

# ╔═╡ c63b5e94-dbbc-11ee-1324-796a50760998
using LIKWID

# ╔═╡ c0f6be74-fa11-48a5-b4d2-5b14b333a064
using LinuxPerf

# ╔═╡ 6eeea444-5126-4776-a2e7-f3ba76605c2d
using PlutoUI

# ╔═╡ ba59bed0-132b-4ee7-bd5c-b941108fe80e
using Chairmarks

# ╔═╡ 7c536724-845e-4156-aa44-38d6a00189a7
begin
	a = T(pi)
	x = rand(T, N);
	y = rand(T, N);
	z = zeros(T, N);
end;

# ╔═╡ 7585b514-0b16-45cf-ba03-b1f40b0c86b6
md"""T = $(@bind T Select([Float32, Float64]))"""

# ╔═╡ a74235f2-7c25-4438-b6ed-4610d94dbb48
let
	range = trunc.(Int, exp10.(0:0.2:5))
	md"N = $(@bind N Slider(range, default=10_000, show_value=true))"
end

# ╔═╡ 8d9eb2e4-4421-483f-86cf-3bc932c40061
function axpy!(z, a, x, y)
	for idx in eachindex(z, x, y)
		z[idx] = a * x[idx] + y[idx]
	end
end

# ╔═╡ 0c4e95fe-ac44-4f4e-a3b2-0abe18bc896f
@b axpy!(z, a, x, y)

# ╔═╡ d7f86859-2fcf-4b83-8330-d236ac91b168
md"""
We can use [`LIKWID.jl`](https://github.com/JuliaPerf/LIKWID.jl) to measure the number of floating point operations performed in the `axpy!` function (details below 👇).
"""

# ╔═╡ 235a7a10-d5e6-4043-9385-22547e1663a0
N_FLOPs = first(events[perf_group])["RETIRED_SSE_AVX_FLOPS_ALL"]

# ╔═╡ 05c48ee8-b8cc-46e7-9a60-2ac7b7eb7934
N_FLOPs_per_iteration = N_FLOPs / N

# ╔═╡ d8f66172-6e8d-4530-bad7-067d6e67ca3d
with_terminal(() -> @code_llvm debuginfo=:none axpy!(z, a, x, y))

# ╔═╡ 02ff11ba-a298-4198-890b-538835a71ce1
with_terminal(() -> @code_native debuginfo=:none axpy!(z, a, x, y))

# ╔═╡ e3709b95-3206-47a8-b1af-35c8ca62be26
perf_group = T==Float32 ? "FLOPS_SP" : "FLOPS_DP";

# ╔═╡ ce26cf0f-4ce5-404d-8ea1-7455b88faf6d
# ╠═╡ show_logs = false
metrics, events = @perfmon perf_group axpy!(z, a, x, y);

# ╔═╡ af1209dc-31ae-4d7d-bbf2-5c83169f27e0
first(metrics[perf_group])

# ╔═╡ 07572db9-fead-4ca6-b9e7-b51505a4c7b9
md"""We can also access Linux's [`perf`](https://perf.wiki.kernel.org/index.php/Main_Page) performance counters via [`LinuxPerf.jl`](https://github.com/JuliaPerf/LinuxPerf.jl)."""

# ╔═╡ 3cfef6b3-89e9-463d-a3c7-91a17e494625
@measure axpy!(z, a, x, y)

# ╔═╡ ad75bf75-9f16-42b6-84fe-554460a41553
perf_events = "(cache-references,cache-misses)";

# ╔═╡ 7032898c-3ff3-4f4d-bb95-c2d7c36767aa
# ╠═╡ show_logs = false
@pstats perf_events axpy!(z, a, x, y)

# ╔═╡ f9d81280-95bb-453e-8763-c0f6b1bca2a0
md"""

## Parallelising the `sum`

### ...not so fast.

"""

# ╔═╡ db795caa-707d-406c-8b2b-9f6695bfe758
data = rand(1_000_000 * Threads.nthreads());

# ╔═╡ 3393d9ab-9ceb-4bf1-90ad-1a3be2c8a880
sum(data)

# ╔═╡ f21573da-4d5b-4ce4-a2e9-9e3ef1d9712c
@b sum(data)

# ╔═╡ 9cbd0d6d-ebc3-4f15-a59e-e42e37d4af37
using Base.Threads

# ╔═╡ 8524cf32-3535-48a1-8439-a399d04eb160
using ChunkSplitters

# ╔═╡ adbd49bd-8401-4160-9f94-0cbbb6c8d1d4
function sum_threads_chunks(data; nchunks=nthreads())
    psums = zeros(eltype(data), nchunks)
    @threads for (c, idcs) in enumerate(chunks(data; n=nchunks))
        for i in idcs
            psums[c] += data[i]
        end
    end
    return sum(psums)
end

# ╔═╡ a419f94c-db6e-4773-83b2-4d72a3c4c59d
sum(data) ≈ sum_threads_chunks(data)

# ╔═╡ 8c550b58-d6e4-40e1-abc4-413a71bab8de
@b sum_threads_chunks(data)

# ╔═╡ ef905da5-ddc0-4209-a5a3-3ae6fee16e43
# ╠═╡ show_logs = false
@pstats perf_events sum(data)

# ╔═╡ b735f839-9725-4b46-a397-984d8f616241
# ╠═╡ show_logs = false
@pstats perf_events sum_threads_chunks(data)

# ╔═╡ 4d5151ee-674e-4ae7-9878-814c30108cbc
md"High cache-trashing frequency: [false sharing](https://en.wikipedia.org/wiki/False_sharing)!

![](https://d3i71xaburhd42.cloudfront.net/cb149ebdbe097867a3b307a0f8d24c5867c0aa68/19-Figure4-1.png)

### Good solution

Create a new local accumulator inside the `for` loop, and update the per-chunk accumulator at the end of the inner loop."

# ╔═╡ aa4b25ae-0cf9-406a-9c19-9794ad15f4a8
function sum_threads_chunks_local(data; nchunks=nthreads())
    psums = zeros(eltype(data), nchunks)
    @threads for (c, idcs) in enumerate(chunks(data; n=nchunks))
        local s = zero(eltype(data))
        for i in idcs
            s += data[i]
        end
        psums[c] = s
    end
    return sum(psums)
end

# ╔═╡ 1bedf88f-a587-4bcc-ac3a-0b9697ac5870
sum(data) ≈ sum_threads_chunks_local(data)

# ╔═╡ 7cfb6d26-9523-4a20-9934-b5c131e6281f
@b sum_threads_chunks_local(data)

# ╔═╡ b80e85d4-0f9a-402c-a38d-8b60feec6962
# ╠═╡ show_logs = false
@pstats perf_events sum_threads_chunks_local(data)

# ╔═╡ de094e69-ac82-4b74-9615-0750029c49ff
md"""

### Better solution

Don't do the manual accumulation, use tasks.
"""

# ╔═╡ 66ffc8ed-420c-45a4-b200-44313a813faf
function sum_map_spawn(data; nchunks=nthreads())
    ts = map(chunks(data, n=nchunks)) do idcs
        @spawn @views sum(data[idcs])
    end
    return sum(fetch.(ts))
end

# ╔═╡ 58d58747-9f86-4893-8366-843e523b555a
sum(data) ≈ sum_map_spawn(data)

# ╔═╡ 0bc93e84-39cf-4ad4-969f-6259aff876df
@b sum_map_spawn(data)

# ╔═╡ 68639105-4b7b-44ac-9244-588291e73d53
# ╠═╡ show_logs = false
@pstats perf_events sum_map_spawn(data)

# ╔═╡ b9cca1ff-8586-4396-9a1f-3d7aa2dcbde8
let
	range = trunc.(Int, exp10.(0:0.2:9))
	md"""
	large\_N = $(@bind large_N Slider(range, default=10, show_value=true))
	"""
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Chairmarks = "0ca39b1e-fe0b-4e98-acfc-b1656634c4de"
ChunkSplitters = "ae650224-84b6-46f8-82ea-d812ca08434e"
CpuId = "adafc99b-e345-5852-983c-f28acb93d879"
LIKWID = "bf22376a-e803-4184-b2ed-56326e3bff83"
LinuxPerf = "b4c46c6c-4fb0-484d-a11a-41bc3392d094"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
ThreadPinning = "811555cd-349b-4f26-b7bc-1f208b848042"

[compat]
Chairmarks = "~1.1.0"
ChunkSplitters = "~2.6.0"
CpuId = "~0.3.1"
LIKWID = "~0.4.4"
LinuxPerf = "~0.3.7"
PlutoUI = "~0.7.58"
ThreadPinning = "~0.7.22"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "a5f953475df66ccc391f96c556d66daa9effcded"

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

[[deps.Chairmarks]]
deps = ["Printf"]
git-tree-sha1 = "86530628eda93c49dc637b0e74bcb3362aa61e2f"
uuid = "0ca39b1e-fe0b-4e98-acfc-b1656634c4de"
version = "1.1.2"
weakdeps = ["Statistics"]

    [deps.Chairmarks.extensions]
    StatisticsChairmarksExt = ["Statistics"]

[[deps.ChunkSplitters]]
deps = ["TestItems"]
git-tree-sha1 = "01d5db8756afc4022b1cf267cfede13245226c72"
uuid = "ae650224-84b6-46f8-82ea-d812ca08434e"
version = "2.6.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

    [deps.ColorTypes.weakdeps]
    StyledStrings = "f489334b-da3d-4c2e-b8f0-e476e12c162b"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.CpuId]]
deps = ["Markdown"]
git-tree-sha1 = "fcbb72b032692610bfbdb15018ac16a36cf2e406"
uuid = "adafc99b-e345-5852-983c-f28acb93d879"
version = "0.3.1"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

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

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LIKWID]]
deps = ["CEnum", "Libdl", "OrderedCollections", "PrettyTables", "Unitful"]
git-tree-sha1 = "b21dcbf20aca355bd2e1039d9731dd1d879cc0d4"
uuid = "bf22376a-e803-4184-b2ed-56326e3bff83"
version = "0.4.5"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

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

[[deps.LinuxPerf]]
deps = ["PrettyTables", "Printf"]
git-tree-sha1 = "b6d76dc8f5a678aae42d8adfe94acf6a97a6d2dd"
uuid = "b4c46c6c-4fb0-484d-a11a-41bc3392d094"
version = "0.3.8"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

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
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "3151a0c8061cc3f887019beebf359e6c4b3daa08"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.65"

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

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "PrecompileTools", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "1101cd475833706e4d0e7b122218257178f48f34"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.4.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.StableTasks]]
git-tree-sha1 = "c4f6610f85cb965bee5bfafa64cbeeda55a4e0b2"
uuid = "91464d47-22a1-43fe-8b7f-2d57ee82463f"
version = "0.1.7"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "725421ae8e530ec29bcbdddbe91ff8053421d023"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.4.1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "f2c1efbc8f3a609aadf318094f8fc5204bdaf344"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TestItems]]
git-tree-sha1 = "42fd9023fef18b9b78c8343a4e2f3813ffbcefcb"
uuid = "1c621080-faea-4a02-84b6-bbd5e436b8fe"
version = "1.0.0"

[[deps.ThreadPinning]]
deps = ["DelimitedFiles", "DocStringExtensions", "Libdl", "LinearAlgebra", "PrecompileTools", "Preferences", "Random", "StableTasks"]
git-tree-sha1 = "333748c6fa62868fa039f00ba670d619776a6752"
uuid = "811555cd-349b-4f26-b7bc-1f208b848042"
version = "0.7.22"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

[[deps.URIs]]
git-tree-sha1 = "24c1c558881564e2217dcf7840a8b2e10caeb0f9"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "d2282232f8a4d71f79e85dc4dd45e5b12a6297fb"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.23.1"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    ForwardDiffExt = "ForwardDiff"
    InverseFunctionsUnitfulExt = "InverseFunctions"
    PrintfExt = "Printf"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"
    Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"

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
# ╟─bbbe6c9c-f032-41b7-a976-c6fd5666adf5
# ╟─630971b1-9053-427e-8ede-41bde809befb
# ╟─a4906361-f71d-4376-8d64-a4c8fa9153fa
# ╠═c7f41ccc-062d-4446-b121-a009334c6b64
# ╠═b2e4f4a1-e516-42d4-bd34-09ba3bdeecc9
# ╠═68e51081-9150-43cb-91a1-333d8c97ae37
# ╠═1cf0469b-664a-4ae8-948b-044c3b11d60e
# ╠═a282a68c-f485-4c61-9ba0-6867c9b445e1
# ╠═fe999d9b-9684-4d4a-ac87-b826a476c6e1
# ╠═30cf6b5f-7043-4e08-829d-b263f332103d
# ╟─cf2a3f32-36a7-4db8-b172-9535b7fc702d
# ╠═c63b5e94-dbbc-11ee-1324-796a50760998
# ╠═c0f6be74-fa11-48a5-b4d2-5b14b333a064
# ╠═6eeea444-5126-4776-a2e7-f3ba76605c2d
# ╠═ba59bed0-132b-4ee7-bd5c-b941108fe80e
# ╠═7c536724-845e-4156-aa44-38d6a00189a7
# ╟─7585b514-0b16-45cf-ba03-b1f40b0c86b6
# ╟─a74235f2-7c25-4438-b6ed-4610d94dbb48
# ╠═8d9eb2e4-4421-483f-86cf-3bc932c40061
# ╠═0c4e95fe-ac44-4f4e-a3b2-0abe18bc896f
# ╟─d7f86859-2fcf-4b83-8330-d236ac91b168
# ╠═235a7a10-d5e6-4043-9385-22547e1663a0
# ╠═05c48ee8-b8cc-46e7-9a60-2ac7b7eb7934
# ╠═d8f66172-6e8d-4530-bad7-067d6e67ca3d
# ╠═02ff11ba-a298-4198-890b-538835a71ce1
# ╠═e3709b95-3206-47a8-b1af-35c8ca62be26
# ╠═ce26cf0f-4ce5-404d-8ea1-7455b88faf6d
# ╠═af1209dc-31ae-4d7d-bbf2-5c83169f27e0
# ╟─07572db9-fead-4ca6-b9e7-b51505a4c7b9
# ╠═3cfef6b3-89e9-463d-a3c7-91a17e494625
# ╠═ad75bf75-9f16-42b6-84fe-554460a41553
# ╠═7032898c-3ff3-4f4d-bb95-c2d7c36767aa
# ╟─f9d81280-95bb-453e-8763-c0f6b1bca2a0
# ╠═db795caa-707d-406c-8b2b-9f6695bfe758
# ╠═3393d9ab-9ceb-4bf1-90ad-1a3be2c8a880
# ╠═f21573da-4d5b-4ce4-a2e9-9e3ef1d9712c
# ╠═9cbd0d6d-ebc3-4f15-a59e-e42e37d4af37
# ╠═8524cf32-3535-48a1-8439-a399d04eb160
# ╠═adbd49bd-8401-4160-9f94-0cbbb6c8d1d4
# ╠═a419f94c-db6e-4773-83b2-4d72a3c4c59d
# ╠═8c550b58-d6e4-40e1-abc4-413a71bab8de
# ╠═ef905da5-ddc0-4209-a5a3-3ae6fee16e43
# ╠═b735f839-9725-4b46-a397-984d8f616241
# ╟─4d5151ee-674e-4ae7-9878-814c30108cbc
# ╠═aa4b25ae-0cf9-406a-9c19-9794ad15f4a8
# ╠═1bedf88f-a587-4bcc-ac3a-0b9697ac5870
# ╠═7cfb6d26-9523-4a20-9934-b5c131e6281f
# ╠═b80e85d4-0f9a-402c-a38d-8b60feec6962
# ╟─de094e69-ac82-4b74-9615-0750029c49ff
# ╠═66ffc8ed-420c-45a4-b200-44313a813faf
# ╠═58d58747-9f86-4893-8366-843e523b555a
# ╠═0bc93e84-39cf-4ad4-969f-6259aff876df
# ╠═68639105-4b7b-44ac-9244-588291e73d53
# ╟─b9cca1ff-8586-4396-9a1f-3d7aa2dcbde8
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
