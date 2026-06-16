### A Pluto.jl notebook ###
# v0.20.24

#> [frontmatter]
#> chapter = "3"
#> section = "1"
#> order = "8"
#> title = "Shared-memory parallelism"
#> date = "2026-05-27"
#> tags = ["module3", "track_parallel"]
#> layout = "layout.jlhtml"
#> 
#>     [[frontmatter.author]]
#>     name = "Valentin Churavy"
#>     url = "https://vchuravy.dev"

using Markdown
using InteractiveUtils

# ╔═╡ 7d055f08-3d46-11f0-135f-7d7e6e2ec362
begin
	using PlutoUI, PlutoTeachingTools
	using PlutoUI: Slider
	PlutoUI.TableOfContents(; depth=4)
end

# ╔═╡ b14fd513-13ab-4a35-bc96-5022537c10a7
ChooseDisplayMode()

# ╔═╡ 58545cef-b247-40e5-846d-dd81b5e1a473
md"""
# Shared-Memory parallelism

This notebook uses **$(Threads.nthreads()) threads**
"""

# ╔═╡ 531b63de-6e7c-4600-9237-7266389cdc87
with_terminal() do
	Sys.cpu_summary()
end

# ╔═╡ db6c8c04-c343-4b64-9d8a-0037cfccf0d6
using Hwloc

# ╔═╡ bf5b4b0b-9bda-4aed-b917-babcbe63ef85
with_terminal() do
	topology_info()
end

# ╔═╡ 833ec918-2852-4fd1-9a36-4b034cd6279a
md"""
## CPU-architecture
"""

# ╔═╡ 6ce49967-effb-421e-9171-3f1db78c065b
md"""
In [Introduction to Parallelism](/../mod1_introduction/parallelism/) we briefly touched on computer architecture.

One of the more peculiar issues are so called Hyperthreads (HT) . Hyperthread is the Intel brand name for Simultaneous multithreading (SMT).

SMT-**N** provides **N** logical CPU-cores per physical CPU core. Some platforms may even make **N** configurable. On Intel and AMD systems **N**=2, but systems with higher **N** are available.

The core idea is that memory accesses are slow and superscalar CPUs can have many instructions **in-flight** at once. 

The CPU architecture exposes a limited amount of resources (registers) that can be used, but the actual implementation in hardware may have an abundance of resources.
This can be used to execute operations that can be *speculatively* executed or we can execute multiple threads on the same physical core.

!!! note
    For our purposes the distinction can be mostly ignored, but we should not expect perfect scaling when exceeding the number of physical cores.
"""

# ╔═╡ d44b1725-7ff2-4707-9ca8-4b41394e429d
using ThreadPinning

# ╔═╡ 313a34bf-6893-4648-9cb8-4c68d3472d51
with_terminal() do
	threadinfo()
end

# ╔═╡ dc53ba40-1c1f-4925-b18b-a0ddeee9f7bc
md"""
## Julia tasks

In Julia concurrent and parallel programming is done through **tasks**. Tasks are independent and communication units of computation. They execute **always** concurrently, but not always parallel.


!!! info "Further reading"
    - https://docs.julialang.org/en/v1/manual/asynchronous-programming/
    - https://proceedings.juliacon.org/papers/10.21105/jcon.00054
"""

# ╔═╡ 60a94c32-81b6-4983-b14c-b1afd29561b6
import Base.Threads: @sync, @spawn

# ╔═╡ e5f5aa82-2152-4d4e-aad1-a03bedb36158
function fib(x)
	if x <= 1
		return 1
	else
		b = @spawn fib(x-2)
		a = fib(x-1)
		return a+(fetch(b)::Int)
	end
end

# ╔═╡ 379511ed-1ee4-4007-ab92-ed65a7e3397a
fib(5)

# ╔═╡ e474e858-5f7d-4b2e-8a01-366d298d1f9b
md"""
!!! note
    A core principle at play is the notion of divide-and-conquer. Can I split a problem into smaller sub-problems? Often, in parallel computing we split problems until a **grain-size** is reached for which we execute a base-case. 

	Today's exercise "Parallel sorting" is an example of divide-and-conquer
"""

# ╔═╡ aef33f15-71b5-4c00-81af-c73178a2c96e
md"""
!!! question

    The Fibonacci function above is just an example to demonstrate basic ideas
    of parallel programming. How would you implement it if you were interested
    in getting the result as fast as possible?
"""

# ╔═╡ 8f11b736-cc8f-4672-9b3a-343ddbff7c9f
md"""
### Channels
"""

# ╔═╡ c96021c9-db62-4bbc-8841-c2cfd9f0bcd4
md"""
As mentioned Julia tasks are **communicating**, communication can happen with dedicated programming concepts like `Channel`, or directly through memory shared with another tasks.

Channels are first-in-first-out queues that can either be buffered (e.g. contain a reservoir for a number of elements), or un-buffered/blocking. 

Julia's channels support `put!`, `take!`
"""

# ╔═╡ ad83880f-8e1d-4ad6-8d9f-5e2951749cd6
let ch = Channel{Int}(Inf) # buffered
	@sync begin
		for i in 1:10
			@spawn put!(ch, rand(Int))
		end
	end
	close(ch) # Otherwise collect will wait for more data
	collect(ch)
end


# ╔═╡ cca0c4ab-1f5d-49ff-900a-dadc6fd85326
md"""
## Race-conditions

`Channel` is a concurrent data-structure and ensure that it safe to use with multiple tasks. When we use our own data-structures we have to make sure that we make them safe if necessary, otherwise we will observe data-races.
"""

# ╔═╡ d9a04988-61c0-41b7-ad0b-f0f49ea97bf6
mutable struct BrokenCounter
	x::Int
end

# ╔═╡ 974edb00-3713-4f6f-8092-79e0506b97b5
let a = BrokenCounter(0)
	N = 10
	K = 100_000
	@sync for i in 1:N
		@spawn for i in 1:K
			a.x += 1
			GC.safepoint()
		end
	end
	a.x, N*K, a.x/(N*K)
end

# ╔═╡ 0359e389-00c4-4e6a-8511-1aa2d9561afa
md"""
!!! note
    We launch `N` tasks each performing `K` updates to our counter. We expect `N*K` updates, but we only observe a fraction of them.

    ```julia
    a.x += 1
    # Can be written as
    a.x = a.x + 1 
    ```

    But in the time between reading and writing `a.x`, there might have been another update. This is a classical race condition.
"""

# ╔═╡ 11e3046d-7ab9-4cb8-8ed4-db6c76ec6bd0
md"""
### Atomics & Locks

One way this can be fixed is to use atomics. Atomics allow to express the `read-and-increment` operation as one operation.

!!! info "Further reading"
    - https://marabos.nl/atomics/
    - https://redixhumayun.github.io/systems/2024/01/03/atomics-and-concurrency.html
"""

# ╔═╡ e114281e-a348-4a33-a465-8ee55ad04608
mutable struct AtomicCounter
	@atomic x::Int
end

# ╔═╡ 0a201007-73ac-4bb8-b02f-25b6f7e23525
let a = AtomicCounter(0)
	N = 10
	K = 100_000
	@sync for i in 1:N
		@spawn for i in 1:K
			@atomic a.x += 1
			GC.safepoint()
		end
	end
	a.x, N*K, a.x/(N*K)
end

# ╔═╡ 746a6ca4-f197-4f1c-a6be-ba0a509367e2
let a = AtomicCounter(0)
	a.x = 10
end

# ╔═╡ 41e5929e-644d-43a5-b3a6-f83674b70003
let a = AtomicCounter(0)
	@atomic :sequentially_consistent a.x = 1+2
end

# ╔═╡ be920575-85ac-4ec4-bf37-ac94f279d6ba
md"""
We can also fix this using a lock.

!!! note
    `Lockable` was added in Julia 1.11.
"""

# ╔═╡ c801dc71-f50e-441e-ae4c-41eba64ab00b
let a = Base.Lockable(BrokenCounter(0), Base.ReentrantLock())
	N = 10
	K = 100_000
	@sync for i in 1:N
		@spawn for i in 1:K
			@lock(a, a[].x += 1)
			GC.safepoint()
		end
	end
	@lock a begin
		a[].x, N*K, a[].x/(N*K)
	end
end

# ╔═╡ ecbfdffe-40cb-4f2d-95da-d5a1363cc99e
md"""
Atomics are limited to things that are "small" (For fields Julia might put a lock variable next to the field, if the value is "big"). And locks are an easier way to provide access to things that should be exclusive access, but are more expensive than atomics.
"""

# ╔═╡ 6268a1ea-d366-4f0e-8b5a-6e590b38d222
md"""
### Atomics on Arrays

Not yet part of the base language. Use the package `Atomix`.
"""

# ╔═╡ 000c5382-3d4c-403a-a5b1-59b6c096f3f4
using Atomix: Atomix, @atomic, @atomicswap, @atomicreplace

# ╔═╡ 961add94-0e5a-4163-bb8d-8a2868623fea
let A = ones(Int, 3)
	Atomix.@atomic A[1] += 1;  # fetch-and-increment
	A
end

# ╔═╡ e64b3064-9730-460d-be79-6fc572ceefd4
md"""
## Parallel-loops
"""

# ╔═╡ 782abc8b-0d43-4c1d-95dd-6d5c7c089408
import Base.Threads: @threads, nthreads, threadid

# ╔═╡ 77a0131c-d031-41d2-a9ff-bb305311e3f4
let 
	a = zeros(Int, nthreads()*2)
	@threads for i in 1:length(a)
	    a[i] = threadid()
	end
	a
end

# ╔═╡ 0d7db4d6-15e8-419c-9ca2-7182df628b2e
md"""
!!! note
    `threadid` is a implementation detail, and should not be used as part of algorithms. Tasks migrate across threads, so it is not a stable observation.
"""

# ╔═╡ 42aabb33-ffb1-479e-a050-436646c4bae7
md"""
#### Schedulers

Julia has different schedulers for parallel for-loops
- `:dynamic` (the default). Chunks the iteration-space.
- `:greedy`: One-task-per-thread, good for unequal workloads. Iteration-space is interpreted as a channel.
- `:static`: One-task-per-thread, equal division of iteration-space. Can not be nested.
"""

# ╔═╡ e3003125-f4cb-48c2-99c7-0eb736ea0e44
md"""
## Parallel primitives
"""

# ╔═╡ 6954d632-9e8d-42aa-893f-bc90160b8648
using OhMyThreads

# ╔═╡ 7463e19b-6685-4d6c-a8f9-89250b046528
md"""
While `@threads` is on the surface an acceptable interface, it is often cumbersome to implement reductions. There are several libraries that provide high-level parallel primitives based on higher-order functions (functions that take other functions).

- `map(f, A)`
- `reduce(+, A)`
- `mapreduce(f, +, A)`

`OhMyThreads.jl` provides:

- `tmap`
- `treduce`
- `tmapreduce`
- `tforeach`

!!! note
    It is a bit unfortunate that `map` & co are implicitly parallel on the GPU, but not on the CPU. Fixing this as been a long-standing ToDo. 
"""

# ╔═╡ de3c1416-acc7-4bf3-ad74-e0cc49b50f31
let 
	a = zeros(Int, nthreads()*2)
	tforeach(1:length(a)) do i
	    a[i] = threadid()
	end
	a
end

# ╔═╡ 2a982390-e075-4d2b-bcc2-38051bdfb1ea
md"""
## False-sharing

Based on the [OhMyThreads.jl docs](https://juliafolds2.github.io/OhMyThreads.jl/stable/literate/falsesharing/falsesharing/).
"""

# ╔═╡ c82e1c97-11c6-4227-966b-aa12d7e9efda
using BenchmarkTools

# ╔═╡ 31f6929c-baca-4cae-ad52-da4283e01d13
data = rand(1_000_000 * nthreads());

# ╔═╡ 24aa1f62-df36-4798-97e6-7a164e4e843d
md"""
**Baseline sequential sum:**
"""

# ╔═╡ beb1ee27-6e43-4fb7-9541-d03f482a18c7
function simple_sum(data)
	acc = zero(eltype(data))
	for i in eachindex(data)
		acc += data[i]
	end
	acc
end

# ╔═╡ c4f63461-d8fd-44f2-b4a7-f131900e342c
@benchmark sum($data)

# ╔═╡ c8ad6195-c142-44a1-81a3-009f700555dd
@benchmark simple_sum($data)

# ╔═╡ 0d8fbd27-1f16-4d58-a6af-8731ff8638f3
question_box(md"""
Note that our simple sum is slower than Julia's sum! Why might that be the case?
""")

# ╔═╡ fcd1a759-c595-43a4-a278-9c1a8d817477
md"""
**Naive parallel implementation:**

We allocate space for the intermediate results.
"""

# ╔═╡ cd5a1da3-8b77-4763-a3a8-52abd0174728
function parallel_sum_falsesharing(data; nchunks = nthreads())
    psums = zeros(eltype(data), nchunks)
    @sync for (c, idcs) in enumerate(OhMyThreads.index_chunks(data; n = nchunks))
        @spawn begin
            for i in idcs
                psums[c] += data[i]
            end
        end
    end
    return sum(psums)
end

# ╔═╡ 1af636ab-f2ec-4c96-9282-d612bf513bd0
 sum(data) ≈ parallel_sum_falsesharing(data)

# ╔═╡ 261c0f75-00b7-411f-929f-2c5a7290a2e1
@benchmark parallel_sum_falsesharing($data)

# ╔═╡ b4e7a32a-6930-466c-a7f2-eb33c37405ab
md"""
**Oof** our parallel code is slower than our serial code! The core issue is that we directly update the values in memory and this causes the CPU to bounce the cache lines from core to core!
"""

# ╔═╡ 9392c90b-73f2-4894-85f3-a63d0570c6d1
md"""
**Padding to cache line size**

One way of solving this is to over-allocate memory and pad each sum such that it is occurring on different cache lines.

[`std::hardware_destructive_interference_size`](https://en.cppreference.com/w/cpp/thread/hardware_destructive_interference_size.html)
"""

# ╔═╡ 80faa7e3-3947-42c1-b21e-190d1b907b43
const CACHE_LINE_SIZE = 64

# ╔═╡ dc549c99-9f26-44dd-b3d0-67c8f3ac901a
function parallel_sum_padded(data; nchunks = nthreads())
	# pad each entry
	stride = CACHE_LINE_SIZE ÷ sizeof(eltype(data))
    psums = zeros(eltype(data), nchunks * stride)
    @sync for (c, idcs) in enumerate(OhMyThreads.index_chunks(data; n = nchunks))
        @spawn begin
			c_idx = (c-1) * stride + 1
            for i in idcs
                psums[c_idx] += data[i]
            end
        end
    end
    return sum(psums)
end

# ╔═╡ e65fe2bc-bd28-4b31-85d4-d9b7ac4715ed
@benchmark parallel_sum_padded($data)

# ╔═╡ bc78c1b4-31a5-42ec-a76e-e14e6152bb59
md"""
!!! note
    To make our implementation faster, we should first think about how we could make our `simple_sum` implementation faster.
"""

# ╔═╡ a394580b-ae6b-4b4c-a3a2-86d6c0892726
md"""
**Task-local parallel summation**

Another way of solving this is to do a local reduction first!
"""

# ╔═╡ 10175638-9211-43b9-b764-623171c194a0
function parallel_sum_tasklocal(data; nchunks = nthreads())
    psums = zeros(eltype(data), nchunks)
    @sync for (c, idcs) in enumerate(OhMyThreads.index_chunks(data; n = nchunks))
        @spawn begin
            local s = zero(eltype(data))
            for i in idcs
                s += data[i]
            end
            psums[c] = s
        end
    end
    return sum(psums)
end

# ╔═╡ 4461e2e6-4e43-4a32-8572-bd1a9ae0121e
@benchmark parallel_sum_tasklocal($data)

# ╔═╡ 8b02babb-0594-4497-b217-99c5434c31df
md"""
**Reuse efficient local implementation:**
"""

# ╔═╡ a9219e30-049f-4b71-9d87-1a0e80416d44
function parallel_sum_map(data; nchunks = nthreads())
    psums = zeros(eltype(data), nchunks)
    @sync for (c, idcs) in enumerate(OhMyThreads.index_chunks(data; n = nchunks))
        @spawn begin
            psums[c] = sum(view(data, idcs))
        end
    end
    return sum(psums)
end

# ╔═╡ 0d1f56da-f39f-45f8-a26e-ae6a7e14a972
@benchmark parallel_sum_map($data)

# ╔═╡ 9dcb1863-c2a8-400d-bbf9-72df6cf288f4
md"""
Of course we can just use `OhMyThreads.treduce`!
"""

# ╔═╡ d09703dd-35cc-41f6-9e50-f75d1fd10cd2
@benchmark treduce($+, $data; ntasks = $nthreads())

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Atomix = "a9b6321e-bd34-4604-b9c9-b65b8de01458"
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
Hwloc = "0e44f5e4-bd66-52a0-8798-143a42290a1d"
OhMyThreads = "67456a42-1dca-4109-a031-0a68de7e3ad5"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
ThreadPinning = "811555cd-349b-4f26-b7bc-1f208b848042"

[compat]
Atomix = "~1.1.3"
BenchmarkTools = "~1.8.0"
Hwloc = "~3.3.0"
OhMyThreads = "~0.8.6"
PlutoTeachingTools = "~0.4.7"
PlutoUI = "~0.7.83"
ThreadPinning = "~1.1.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "a605a1d5b0f20eb3c6caebccf91ee7fb9c1e5803"

[[deps.AbstractPlutoDingetjes]]
git-tree-sha1 = "6c3913f4e9bdf6ba3c08041a446fb1332716cbc2"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.4.0"

[[deps.Accessors]]
deps = ["CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "MacroTools"]
git-tree-sha1 = "2eeb2c9bef11013efc6f8f97f32ee59b146b09fb"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.44"

    [deps.Accessors.extensions]
    AxisKeysExt = "AxisKeys"
    IntervalSetsExt = "IntervalSets"
    LinearAlgebraExt = "LinearAlgebra"
    StaticArraysExt = "StaticArrays"
    StructArraysExt = "StructArrays"
    TestExt = "Test"
    UnitfulExt = "Unitful"

    [deps.Accessors.weakdeps]
    AxisKeys = "94b1ba4f-4ee9-5380-92f1-94cde586c3c5"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
    Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Atomix]]
deps = ["UnsafeAtomics"]
git-tree-sha1 = "b8651b2eb5796a386b0398a20b519a6a6150f75c"
uuid = "a9b6321e-bd34-4604-b9c9-b65b8de01458"
version = "1.1.3"

    [deps.Atomix.extensions]
    AtomixCUDAExt = "CUDA"
    AtomixMetalExt = "Metal"
    AtomixOpenCLExt = "OpenCL"
    AtomixoneAPIExt = "oneAPI"

    [deps.Atomix.weakdeps]
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    Metal = "dde4c033-4e86-420c-a63e-0dd931031962"
    OpenCL = "08131aa3-fb12-5dee-8b74-c09406e224a2"
    oneAPI = "8f75cd03-7ff8-4ecb-9b8f-daf728133b1b"

[[deps.BangBang]]
deps = ["Accessors", "ConstructionBase", "InitialValues", "LinearAlgebra"]
git-tree-sha1 = "cceb62468025be98d42a5dc581b163c20896b040"
uuid = "198e06fe-97b7-11e9-32a5-e1d131e6ad66"
version = "0.4.9"

    [deps.BangBang.extensions]
    BangBangChainRulesCoreExt = "ChainRulesCore"
    BangBangDataFramesExt = "DataFrames"
    BangBangStaticArraysExt = "StaticArrays"
    BangBangStructArraysExt = "StructArrays"
    BangBangTablesExt = "Tables"
    BangBangTypedTablesExt = "TypedTables"

    [deps.BangBang.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
    TypedTables = "9d95f2ec-7b3d-5a63-8d20-e2491e220bb9"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BenchmarkTools]]
deps = ["Compat", "JSON", "Logging", "PrecompileTools", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "9670d3febc2b6da60a0ae57846ba74670290653f"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.8.0"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.ChunkSplitters]]
git-tree-sha1 = "1c52c8e2673edc030191177ff1aee42d25149acb"
uuid = "ae650224-84b6-46f8-82ea-d812ca08434e"
version = "3.2.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "9d8a54ce4b17aa5bdce0ea5c34bc5e7c340d16ad"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.18.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.CompositionsBase]]
git-tree-sha1 = "802bb88cd69dfd1509f6670416bd4434015693ad"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.2"
weakdeps = ["InverseFunctions"]

    [deps.CompositionsBase.extensions]
    CompositionsBaseInverseFunctionsExt = "InverseFunctions"

[[deps.ConstructionBase]]
git-tree-sha1 = "b4b092499347b18a015186eae3042f72267106cb"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.6.0"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FixedPointNumbers]]
deps = ["Random", "Statistics"]
git-tree-sha1 = "59af96b98217c6ef4ae0dfe065ac7c20831d1a84"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.6"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Zlib_jll"]
git-tree-sha1 = "38044a04637976140074d0b0621c1edf0eb531fd"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.1+0"

[[deps.HashArrayMappedTries]]
git-tree-sha1 = "2eaa69a7cab70a52b9687c8bf950a5a93ec895ae"
uuid = "076d061b-32b6-4027-95e0-9a2c6f6d7e74"
version = "0.2.0"

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
deps = ["Artifacts", "JLLWrappers", "Libdl", "XML2_jll", "Xorg_libpciaccess_jll"]
git-tree-sha1 = "baaaebd42ed9ee1bd9173cfd56910e55a8622ee1"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.13.0+1"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "d1a86724f81bcd184a38fd284ce183ec067d71a0"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "1.0.0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

[[deps.InitialValues]]
git-tree-sha1 = "4da0f88e9a39111c2fa3add390ab15f3a44f3ca3"
uuid = "22cec73e-a1b8-11e9-2c92-598750a2cf9c"
version = "0.3.1"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.InverseFunctions]]
git-tree-sha1 = "a779299d77cd080bf77b97535acecd73e1c5e5cb"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.17"
weakdeps = ["Dates", "Test"]

    [deps.InverseFunctions.extensions]
    InverseFunctionsDatesExt = "Dates"
    InverseFunctionsTestExt = "Test"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7204148362dafe5fe6a273f855b8ccbe4df8173e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.8.0"

[[deps.JSON]]
deps = ["Dates", "Logging", "Parsers", "PrecompileTools", "StructUtils", "UUIDs", "Unicode"]
git-tree-sha1 = "c89d196f5ffb64bfbf80985b699ea913b0d2c211"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "1.6.1"

    [deps.JSON.extensions]
    JSONArrowExt = ["ArrowTypes"]

    [deps.JSON.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c0c9b76f3520863909825cbecdef58cd63de705a"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.5+0"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "dda21b8cbd6a6c40d9d02a73230f9d70fed6918c"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.4.0"

[[deps.Latexify]]
deps = ["Format", "Ghostscript_jll", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Requires"]
git-tree-sha1 = "44f93c47f9cd6c7e431f2f2091fcba8f01cd7e8f"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.10"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    SparseArraysExt = "SparseArrays"
    SymEngineExt = "SymEngine"
    TectonicExt = "tectonic_jll"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"
    tectonic_jll = "d7dd28d6-a5e6-559c-9131-7eb760cdacc5"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.15.0+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "OpenSSL_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.3+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2025.11.4"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OhMyThreads]]
deps = ["BangBang", "ChunkSplitters", "ScopedValues", "StableTasks", "TaskLocalValues"]
git-tree-sha1 = "9a07c25c438110500d871fd5309649ec6791ef57"
uuid = "67456a42-1dca-4109-a031-0a68de7e3ad5"
version = "0.8.6"

    [deps.OhMyThreads.extensions]
    MarkdownExt = "Markdown"
    ProgressMeterExt = "ProgressMeter"

    [deps.OhMyThreads.weakdeps]
    Markdown = "d6f4376e-aef5-505a-96c1-9c027394607a"
    ProgressMeter = "92933f4c-e287-5a05-a399-4b506db050ca"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.4+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "94ba93778373a53bfd5a0caaf7d809c445292ff4"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.2"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "468dbe2b510c876dc091b2c74ed52c7c34f48b9b"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.5"

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "Latexify", "Markdown", "PlutoUI"]
git-tree-sha1 = "90b41ced6bacd8c01bd05da8aed35c5458891749"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.4.7"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "e189d0623e7ce9c37389bac17e80aac3b0302e75"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.83"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "edbeefc7a4889f528644251bdb5fc9ab5348bc2c"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.3.4"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "8b770b60760d4451834fe79dd483e318eee709c4"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Profile]]
deps = ["StyledStrings"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"
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

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.ScopedValues]]
deps = ["HashArrayMappedTries", "Logging"]
git-tree-sha1 = "67a144433c4ce877ee6d1ada69a124d6b1ecf7be"
uuid = "7e506255-f358-4e82-b7e4-beb19740aa63"
version = "1.6.2"

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

[[deps.StructUtils]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "82bee338d650aa515f31866c460cb7e3bcef90b8"
uuid = "ec057cc2-7a8d-4b58-b3b3-92acb9f63b42"
version = "2.8.2"

    [deps.StructUtils.extensions]
    StructUtilsMeasurementsExt = ["Measurements"]
    StructUtilsStaticArraysCoreExt = ["StaticArraysCore"]
    StructUtilsTablesExt = ["Tables"]

    [deps.StructUtils.weakdeps]
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SysInfo]]
deps = ["Dates", "DelimitedFiles", "Hwloc", "PrecompileTools", "Random", "Serialization"]
git-tree-sha1 = "dbe0126f74fba2f6e378b81271a6e9538cf490ef"
uuid = "90a7ee08-a23f-48b9-9006-0e0e2a9e4608"
version = "0.3.1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TaskLocalValues]]
git-tree-sha1 = "67e469338d9ce74fc578f7db1736a74d93a49eb8"
uuid = "ed4db957-447d-4319-bfb6-7fa9ae7ecf34"
version = "0.1.3"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.ThreadPinning]]
deps = ["DelimitedFiles", "Libdl", "LinearAlgebra", "PrecompileTools", "Preferences", "Random", "StableTasks", "SysInfo", "ThreadPinningCore"]
git-tree-sha1 = "d125980124c8a02da76d03590b4cae9f3d5df077"
uuid = "811555cd-349b-4f26-b7bc-1f208b848042"
version = "1.1.1"

    [deps.ThreadPinning.extensions]
    DistributedExt = "Distributed"
    MPIExt = "MPI"

    [deps.ThreadPinning.weakdeps]
    Distributed = "8ba89e20-285c-5b6f-9357-94700520ee1b"
    MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"

[[deps.ThreadPinningCore]]
deps = ["LinearAlgebra", "PrecompileTools", "StableTasks"]
git-tree-sha1 = "bb3c6f3b5600fbff028c43348365681b34d06499"
uuid = "6f48bc29-05ce-4cc8-baad-4adcba581a18"
version = "0.4.5"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"
version = "1.11.0"

[[deps.UnsafeAtomics]]
git-tree-sha1 = "0f30765c32d66d58e41f4cb5624d4fc8a82ec13b"
uuid = "013be700-e6cd-48c3-b4a1-df204f14c38f"
version = "0.3.1"

    [deps.UnsafeAtomics.extensions]
    UnsafeAtomicsLLVM = ["LLVM"]

    [deps.UnsafeAtomics.weakdeps]
    LLVM = "929cbde3-209d-540e-8aea-75f648917ca0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "80d3930c6347cfce7ccf96bd3bafdf079d9c0390"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.9+0"

[[deps.Xorg_libpciaccess_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "58972370b81423fc546c56a60ed1a009450177c3"
uuid = "a65dc6b1-eb27-53a1-bb3e-dea574b5389e"
version = "0.19.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.3.1+2"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.64.0+1"
"""

# ╔═╡ Cell order:
# ╠═7d055f08-3d46-11f0-135f-7d7e6e2ec362
# ╠═b14fd513-13ab-4a35-bc96-5022537c10a7
# ╟─58545cef-b247-40e5-846d-dd81b5e1a473
# ╠═531b63de-6e7c-4600-9237-7266389cdc87
# ╠═db6c8c04-c343-4b64-9d8a-0037cfccf0d6
# ╠═bf5b4b0b-9bda-4aed-b917-babcbe63ef85
# ╟─833ec918-2852-4fd1-9a36-4b034cd6279a
# ╟─6ce49967-effb-421e-9171-3f1db78c065b
# ╠═d44b1725-7ff2-4707-9ca8-4b41394e429d
# ╠═313a34bf-6893-4648-9cb8-4c68d3472d51
# ╟─dc53ba40-1c1f-4925-b18b-a0ddeee9f7bc
# ╠═60a94c32-81b6-4983-b14c-b1afd29561b6
# ╠═e5f5aa82-2152-4d4e-aad1-a03bedb36158
# ╠═379511ed-1ee4-4007-ab92-ed65a7e3397a
# ╟─e474e858-5f7d-4b2e-8a01-366d298d1f9b
# ╟─aef33f15-71b5-4c00-81af-c73178a2c96e
# ╟─8f11b736-cc8f-4672-9b3a-343ddbff7c9f
# ╟─c96021c9-db62-4bbc-8841-c2cfd9f0bcd4
# ╠═ad83880f-8e1d-4ad6-8d9f-5e2951749cd6
# ╟─cca0c4ab-1f5d-49ff-900a-dadc6fd85326
# ╠═d9a04988-61c0-41b7-ad0b-f0f49ea97bf6
# ╠═974edb00-3713-4f6f-8092-79e0506b97b5
# ╟─0359e389-00c4-4e6a-8511-1aa2d9561afa
# ╟─11e3046d-7ab9-4cb8-8ed4-db6c76ec6bd0
# ╠═e114281e-a348-4a33-a465-8ee55ad04608
# ╠═0a201007-73ac-4bb8-b02f-25b6f7e23525
# ╠═746a6ca4-f197-4f1c-a6be-ba0a509367e2
# ╠═41e5929e-644d-43a5-b3a6-f83674b70003
# ╟─be920575-85ac-4ec4-bf37-ac94f279d6ba
# ╠═c801dc71-f50e-441e-ae4c-41eba64ab00b
# ╟─ecbfdffe-40cb-4f2d-95da-d5a1363cc99e
# ╟─6268a1ea-d366-4f0e-8b5a-6e590b38d222
# ╠═000c5382-3d4c-403a-a5b1-59b6c096f3f4
# ╠═961add94-0e5a-4163-bb8d-8a2868623fea
# ╟─e64b3064-9730-460d-be79-6fc572ceefd4
# ╠═782abc8b-0d43-4c1d-95dd-6d5c7c089408
# ╠═77a0131c-d031-41d2-a9ff-bb305311e3f4
# ╟─0d7db4d6-15e8-419c-9ca2-7182df628b2e
# ╟─42aabb33-ffb1-479e-a050-436646c4bae7
# ╟─e3003125-f4cb-48c2-99c7-0eb736ea0e44
# ╠═6954d632-9e8d-42aa-893f-bc90160b8648
# ╟─7463e19b-6685-4d6c-a8f9-89250b046528
# ╠═de3c1416-acc7-4bf3-ad74-e0cc49b50f31
# ╟─2a982390-e075-4d2b-bcc2-38051bdfb1ea
# ╠═c82e1c97-11c6-4227-966b-aa12d7e9efda
# ╠═31f6929c-baca-4cae-ad52-da4283e01d13
# ╟─24aa1f62-df36-4798-97e6-7a164e4e843d
# ╠═beb1ee27-6e43-4fb7-9541-d03f482a18c7
# ╠═c4f63461-d8fd-44f2-b4a7-f131900e342c
# ╠═c8ad6195-c142-44a1-81a3-009f700555dd
# ╟─0d8fbd27-1f16-4d58-a6af-8731ff8638f3
# ╟─fcd1a759-c595-43a4-a278-9c1a8d817477
# ╠═cd5a1da3-8b77-4763-a3a8-52abd0174728
# ╠═1af636ab-f2ec-4c96-9282-d612bf513bd0
# ╠═261c0f75-00b7-411f-929f-2c5a7290a2e1
# ╟─b4e7a32a-6930-466c-a7f2-eb33c37405ab
# ╟─9392c90b-73f2-4894-85f3-a63d0570c6d1
# ╠═80faa7e3-3947-42c1-b21e-190d1b907b43
# ╠═dc549c99-9f26-44dd-b3d0-67c8f3ac901a
# ╠═e65fe2bc-bd28-4b31-85d4-d9b7ac4715ed
# ╟─bc78c1b4-31a5-42ec-a76e-e14e6152bb59
# ╟─a394580b-ae6b-4b4c-a3a2-86d6c0892726
# ╠═10175638-9211-43b9-b764-623171c194a0
# ╠═4461e2e6-4e43-4a32-8572-bd1a9ae0121e
# ╟─8b02babb-0594-4497-b217-99c5434c31df
# ╠═a9219e30-049f-4b71-9d87-1a0e80416d44
# ╠═0d1f56da-f39f-45f8-a26e-ae6a7e14a972
# ╟─9dcb1863-c2a8-400d-bbf9-72df6cf288f4
# ╠═d09703dd-35cc-41f6-9e50-f75d1fd10cd2
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
