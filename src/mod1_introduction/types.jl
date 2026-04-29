### A Pluto.jl notebook ###
# v0.20.24

#> [frontmatter]
#> chapter = "1"
#> section = "2"
#> order = "2.7"
#> title = "Types, Structs, and Mutable Structs"
#> date = "2026-04-28"
#> tags = ["module1", "track_principles", "indepth"]
#> layout = "layout.jlhtml"
#> indepth_number = "1"
#> 
#>     [[frontmatter.author]]
#>     name = "Valentin Churavy"
#>     url = "https://vchuravy.dev"

using Markdown
using InteractiveUtils

# ╔═╡ a0000001-0000-4000-8000-000000000001
using PlutoUI, PlutoTeachingTools

# ╔═╡ a0000002-0000-4000-8000-000000000002
PlutoUI.TableOfContents(; depth=4)

# ╔═╡ a0000003-0000-4000-8000-000000000003
md"""
# Types, Structs, and Mutable Structs in Julia

Julia's type system is one of its most powerful features. Understanding it unlocks
multiple dispatch, performance, and the ability to design clean, composable abstractions.

This notebook covers:
- Julia's type hierarchy
- Defining composite types with `struct` (immutable) and `mutable struct`
- Parametric (generic) types
- How types connect to multiple dispatch
"""

# ╔═╡ a0000004-0000-4000-8000-000000000004
md"""
## Julia's Type Hierarchy

Every value in Julia has a concrete type. Types are arranged in a tree rooted at `Any`.

```
Any
 ├── Number
 │    ├── Real
 │    │    ├── Integer  (abstract)
 │    │    │    ├── Int64, Int32, …  (concrete)
 │    │    └── AbstractFloat  (abstract)
 │    │         ├── Float64, Float32, …  (concrete)
 │    └── Complex
 └── AbstractString  (abstract)
      └── String  (concrete)
```

**Abstract types** organise the hierarchy but cannot be instantiated.
**Concrete types** are what values actually are.
"""

# ╔═╡ a0000005-0000-4000-8000-000000000005
typeof(42), typeof(3.14), typeof("hello")

# ╔═╡ a0000006-0000-4000-8000-000000000006
supertype(Float64), supertype(AbstractFloat), supertype(Real)

# ╔═╡ a0000007-0000-4000-8000-000000000007
isa(42, Integer), isa(42, Number), isa(42, AbstractFloat)

# ╔═╡ a0000008-0000-4000-8000-000000000008
tip(md"""
`isa(x, T)` tests whether `x` is an instance of type `T` or any of its subtypes.
The `::` operator does the same check in a type annotation or pattern-match context.
""")

# ╔═╡ a0000009-0000-4000-8000-000000000009
md"""
## Defining Custom Types with `struct`

`struct` creates an **immutable** composite type.  Once a value is constructed its
fields cannot be reassigned.
"""

# ╔═╡ a000000a-0000-4000-8000-00000000000a
begin
    struct Point
        x::Float64
        y::Float64
    end

    # Custom constructor: build a Point from polar coordinates
    function Point(r::Real, θ::Real, ::Val{:polar})
        Point(r * cos(θ), r * sin(θ))
    end
end

# ╔═╡ a000000b-0000-4000-8000-00000000000b
p = Point(3.0, 4.0)

# ╔═╡ a000000c-0000-4000-8000-00000000000c
p.x, p.y           # field access with dot notation

# ╔═╡ a000000d-0000-4000-8000-00000000000d
typeof(p)

# ╔═╡ a000000e-0000-4000-8000-00000000000e
fieldnames(Point)

# ╔═╡ a000000f-0000-4000-8000-00000000000f
md"""
A struct gets a default constructor matching its field list.
You can add your own constructors as needed.
"""

# ╔═╡ a0000011-0000-4000-8000-000000000011
Point(1.0, π/4, Val(:polar))

# ╔═╡ a0000012-0000-4000-8000-000000000012
tip(md"""
**Why immutable by default?**

- The compiler can allocate small structs on the **stack** (or inline them), avoiding heap pressure entirely.
- Immutable values are easy to reason about: passing a `Point` to a function cannot change your original.
- They are **thread-safe** with no locking needed.

Immutability is a local guarantee: a `struct` field that is itself mutable (e.g. an `Array`) can still be mutated through that field.
""")

# ╔═╡ a0000013-0000-4000-8000-000000000013
md"""
### Trying to mutate an immutable struct
"""

# ╔═╡ a0000014-0000-4000-8000-000000000014
# setfield! on an immutable struct throws an error
try
    p.x = 99.0
catch e
    e
end

# ╔═╡ a0000015-0000-4000-8000-000000000015
md"""
## Mutable Structs

When you need to update fields in-place, use `mutable struct`.
"""

# ╔═╡ a0000016-0000-4000-8000-000000000016
mutable struct Counter
    count::Int
    label::String
end

# ╔═╡ a0000017-0000-4000-8000-000000000017
c = Counter(0, "events")

# ╔═╡ a0000019-0000-4000-8000-000000000019
tip(md"""
`mutable struct` values are **heap-allocated** and accessed through a pointer, which means:

- Field updates work: `c.count += 1` ✓
- They have **identity**: two `Counter` objects with the same field values are *different* objects (unlike immutable structs, where equal values are interchangeable).
- The compiler has less freedom to optimise (cannot inline, may cause GC pressure).

**Rule of thumb:** start with `struct`. Switch to `mutable struct` only if in-place mutation is genuinely needed — e.g. accumulation, caches, or objects that model stateful resources.
""")

# ╔═╡ b000001a-0000-4000-8000-000000000001
md"""
## Callable Structs (Functors)

A struct can be made **callable** by defining a method on an instance.  This is how
Julia implements the functor pattern — an object that behaves like a function while
carrying state.
"""

# ╔═╡ b000001b-0000-4000-8000-000000000002
md"""
First, compare how closures capture state in plain functions:
"""

# ╔═╡ b0000020-0000-4000-8000-000000000007
md"""
The same idea expressed as a callable struct — all state is explicit in the fields:
"""

# ╔═╡ b0000023-0000-4000-8000-00000000000a
tip(md"""
**Why callable structs over closures?**

- The struct fields are **named and typed**.
- You can define **multiple call signatures** on the same type via dispatch.

A canonical real-world example is neural-network layers in Flux/Lux: each layer is a callable struct that holds parameters (weights) as fields.
""")

# ╔═╡ b0000024-0000-4000-8000-00000000000b
md"""
`dump` lets you inspect the internal layout of any value — useful when exploring
unfamiliar struct types:
"""

# ╔═╡ a000001a-0000-4000-8000-00000000001a
md"""
## Parametric (Generic) Types

Types can take **type parameters**, making them generic:
"""

# ╔═╡ a000001b-0000-4000-8000-00000000001b
struct Vec2{T}
    x::T
    y::T
end

# ╔═╡ a000001c-0000-4000-8000-00000000001c
Vec2(1, 2), Vec2(1.0, 2.0), Vec2(1//2, 3//4)

# ╔═╡ a000001d-0000-4000-8000-00000000001d
md"""
Julia infers `T` from the constructor arguments.  You can also constrain `T`:
"""

# ╔═╡ a000001e-0000-4000-8000-00000000001e
struct Vec2Real{T <: Real}
    x::T
    y::T
end

# ╔═╡ a000001f-0000-4000-8000-00000000001f
Vec2Real(1, 2), Vec2Real(1.0f0, 2.0f0)

# ╔═╡ a0000020-0000-4000-8000-000000000020
tip(md"""
Parametric types are **not** covariant: `Vec2{Float64}` is **not** a subtype of `Vec2{Real}`,
even though `Float64 <: Real`.

```julia
Vec2{Float64} <: Vec2{Real}   # false
Vec2{Float64} <: Vec2{<:Real} # true  (using a union bound)
```

This avoids unsound behaviour that you'd get with covariant containers (a classic pitfall in Java/C#).
""")

# ╔═╡ a0000021-0000-4000-8000-000000000021
Vec2{Float64} <: Vec2{Real}, Vec2{Float64} <: Vec2{<:Real}

# ╔═╡ a0000022-0000-4000-8000-000000000022
md"""
## Connecting Types to Multiple Dispatch

Types are the mechanism that drives Julia's multiple dispatch.
You write methods specialised on types, and Julia selects the most specific one.
"""

# ╔═╡ a0000023-0000-4000-8000-000000000023
begin
    import Base: +, show
    +(a::Point, b::Point) = Point(a.x + b.x, a.y + b.y)
    show(io::IO, p::Point) = print(io, "($(p.x), $(p.y))")
end

# ╔═╡ a0000018-0000-4000-8000-000000000018
begin
    c.count += 1
    c.count += 1
    c.count += 1
    c
end

# ╔═╡ b000001c-0000-4000-8000-000000000003
function make_adder(n)
    x -> x + n      # anonymous function closes over n
end

# ╔═╡ b000001d-0000-4000-8000-000000000004
add5 = make_adder(5)

# ╔═╡ b000001e-0000-4000-8000-000000000005
add5(10)

# ╔═╡ b000001f-0000-4000-8000-000000000006
add5 |> dump      # shows the captured field

# ╔═╡ b0000021-0000-4000-8000-000000000008
begin
    struct Adder
        n::Int
    end
    # Define call syntax: Adder(3)(10) == 13
    (a::Adder)(x) = x + a.n
end

# ╔═╡ b0000022-0000-4000-8000-000000000009
Adder(5)(10)

# ╔═╡ b0000026-0000-4000-8000-00000000000d
dump(Adder(5))

# ╔═╡ b0000025-0000-4000-8000-00000000000c
dump(1 + 2im)     # Complex is itself an immutable struct with re and re fields

# ╔═╡ a0000026-0000-4000-8000-000000000026
Point(1.0, 2.0) + Point(3.0, 4.0)

# ╔═╡ a0000027-0000-4000-8000-000000000027
md"""
Because `+` now has a method for `Point`, the entire numeric ecosystem that uses `+`
(e.g. `sum`, broadcasting, linear algebra) **just works** for `Point` values.
"""

# ╔═╡ a0000028-0000-4000-8000-000000000028
sum([Point(1.0, 0.0), Point(0.0, 1.0), Point(2.0, 3.0)])

# ╔═╡ a0000029-0000-4000-8000-000000000029
md"""
## Summary

| Feature | `struct` | `mutable struct` |
|---------|----------|-----------------|
| Field mutation | ✗ | ✓ |
| Stack / inline allocation | ✓ (small structs) | ✗ (heap only) |
| Identity semantics | value (by content) | reference (by identity) |
| Thread safety | inherently safe | requires care |
| Compiler optimisations | full | limited |

Start with `struct`. Add `mutable` only when the mutation is the point.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PlutoTeachingTools = "~0.4.7"
PlutoUI = "~0.7.80"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.4"
manifest_format = "2.0"
project_hash = "b4c18bbc242930204ae5cca25c12954846038fac"

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

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

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

[[deps.Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Zlib_jll"]
git-tree-sha1 = "38044a04637976140074d0b0621c1edf0eb531fd"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.1+0"

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

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "0533e564aae234aff59ab625543145446d8b6ec2"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.1"

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

[[deps.LibGit2]]
deps = ["LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"
version = "1.11.0"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "OpenSSL_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.9.0+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "OpenSSL_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.3+1"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

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

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2025.11.4"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.4+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.12.1"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "Latexify", "Markdown", "PlutoUI"]
git-tree-sha1 = "90b41ced6bacd8c01bd05da8aed35c5458891749"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.4.7"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "fbc875044d82c113a9dee6fc14e16cf01fd48872"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.80"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "8b770b60760d4451834fe79dd483e318eee709c4"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.2"

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

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
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

[[deps.p7zip_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.7.0+0"
"""

# ╔═╡ Cell order:
# ╠═a0000001-0000-4000-8000-000000000001
# ╟─a0000002-0000-4000-8000-000000000002
# ╟─a0000003-0000-4000-8000-000000000003
# ╟─a0000004-0000-4000-8000-000000000004
# ╠═a0000005-0000-4000-8000-000000000005
# ╠═a0000006-0000-4000-8000-000000000006
# ╠═a0000007-0000-4000-8000-000000000007
# ╟─a0000008-0000-4000-8000-000000000008
# ╟─a0000009-0000-4000-8000-000000000009
# ╠═a000000a-0000-4000-8000-00000000000a
# ╠═a000000b-0000-4000-8000-00000000000b
# ╠═a000000c-0000-4000-8000-00000000000c
# ╠═a000000d-0000-4000-8000-00000000000d
# ╠═a000000e-0000-4000-8000-00000000000e
# ╟─a000000f-0000-4000-8000-00000000000f
# ╠═a0000011-0000-4000-8000-000000000011
# ╟─a0000012-0000-4000-8000-000000000012
# ╟─a0000013-0000-4000-8000-000000000013
# ╠═a0000014-0000-4000-8000-000000000014
# ╟─a0000015-0000-4000-8000-000000000015
# ╠═a0000016-0000-4000-8000-000000000016
# ╠═a0000017-0000-4000-8000-000000000017
# ╠═a0000018-0000-4000-8000-000000000018
# ╟─a0000019-0000-4000-8000-000000000019
# ╟─b000001a-0000-4000-8000-000000000001
# ╟─b000001b-0000-4000-8000-000000000002
# ╠═b000001c-0000-4000-8000-000000000003
# ╠═b000001d-0000-4000-8000-000000000004
# ╠═b000001e-0000-4000-8000-000000000005
# ╠═b000001f-0000-4000-8000-000000000006
# ╟─b0000020-0000-4000-8000-000000000007
# ╠═b0000021-0000-4000-8000-000000000008
# ╠═b0000022-0000-4000-8000-000000000009
# ╟─b0000023-0000-4000-8000-00000000000a
# ╟─b0000024-0000-4000-8000-00000000000b
# ╠═b0000025-0000-4000-8000-00000000000c
# ╠═b0000026-0000-4000-8000-00000000000d
# ╟─a000001a-0000-4000-8000-00000000001a
# ╠═a000001b-0000-4000-8000-00000000001b
# ╠═a000001c-0000-4000-8000-00000000001c
# ╟─a000001d-0000-4000-8000-00000000001d
# ╠═a000001e-0000-4000-8000-00000000001e
# ╠═a000001f-0000-4000-8000-00000000001f
# ╟─a0000020-0000-4000-8000-000000000020
# ╠═a0000021-0000-4000-8000-000000000021
# ╟─a0000022-0000-4000-8000-000000000022
# ╠═a0000023-0000-4000-8000-000000000023
# ╠═a0000026-0000-4000-8000-000000000026
# ╟─a0000027-0000-4000-8000-000000000027
# ╠═a0000028-0000-4000-8000-000000000028
# ╟─a0000029-0000-4000-8000-000000000029
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
