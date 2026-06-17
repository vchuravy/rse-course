### A Pluto.jl notebook ###
# v1.0.1

#> [frontmatter]
#> order = "5.2"
#> exercise_number = "12"
#> title = "Performance Annotations"
#> tags = ["module1", "track_performance", "exercises"]
#> layout = "layout.jlhtml"
#> license = "MIT"
#> description = "Use @inbounds, @simd and @fastmath to accelerate inner loops and understand the trade-offs"
#> 
#>     [[frontmatter.author]]
#>     name = "Valentin Churavy"
#>     url = "https://vchuravy.dev"

using Markdown
using InteractiveUtils

# ╔═╡ 12010001-0012-4000-8000-000000000001
using PlutoTeachingTools, PlutoUI

# ╔═╡ 12010002-0012-4000-8000-000000000002
using BenchmarkTools

# ╔═╡ 12010003-0012-4000-8000-000000000003
ChooseDisplayMode()

# ╔═╡ 12010004-0012-4000-8000-000000000004
PlutoUI.TableOfContents(; depth=4)

# ╔═╡ 12010005-0012-4000-8000-000000000005
md"""
# Exercise: Performance Annotations

Julia provides three macros for accelerating inner loops:

| Macro | Effect | Risk |
|---|---|---|
| `@inbounds` | Disables bounds-checking on array accesses | An out-of-bounds index gives undefined behaviour instead of a `BoundsError` |
| `@simd` | Hints the compiler to auto-vectorise the loop | Loop must be a simple reduction with no cross-iteration dependencies |
| `@fastmath` | Relaxes IEEE 754 strict floating-point rules (allows fused ops, reordering, etc.) | Results may differ slightly; `Inf`/`NaN` propagation changes |

**Workflow:** always verify correctness *before* annotating, and profile first to confirm the loop is actually a hot-spot.
"""

# ╔═╡ 12010006-0012-4000-8000-000000000006
md"""
## Part 1 — Sum reduction with `@inbounds` and `@simd`

The loop below is correct but limited: because IEEE 754 requires floating-point
additions to be evaluated strictly left-to-right, the compiler cannot use vector
registers for the accumulation without explicit permission.

```julia
function mysum_naive(x)
    acc = zero(eltype(x))
    for i in eachindex(x)
        acc += x[i]
    end
    return acc
end
```

Implement `mysum_fast(x)` that adds:
1. `@inbounds` — safe when iterating with `eachindex`, removes the per-element bounds check inside the loop.
2. `@simd` — grants the compiler permission to reorder additions, enabling multi-lane vector reduction (e.g. 4 × `Float64` per cycle with AVX2).
"""

# ╔═╡ 12010007-0012-4000-8000-000000000007
function mysum_naive(x)
    acc = zero(eltype(x))
    for i in eachindex(x)
        acc += x[i]
    end
    return acc
end

# ╔═╡ 12010008-0012-4000-8000-000000000008
# TODO: Implement mysum_fast

# ╔═╡ 12010009-0012-4000-8000-000000000009
let
	if !@isdefined(mysum_fast)
		func_not_defined(:mysum_fast)
	else
		try
			x = rand(1000)
			result = mysum_fast(x)
			if !(result ≈ mysum_naive(x))
				keep_working(md"`mysum_fast(x)` returned `$(round(result, digits=6))` but expected approximately `$(round(mysum_naive(x), digits=6))`.")
			else
				correct()
			end
		catch e
			keep_working(md"Your function threw an error: `$(sprint(showerror, e))`")
		end
	end
end

# ╔═╡ 1201000a-0012-4000-8000-00000000000a
let
	n = 2^14
	x = rand(n)
	t_naive = @belapsed mysum_naive($x)
	t_fast  = @isdefined(mysum_fast) ? @belapsed(mysum_fast($x)) : NaN
	md"""
	| Implementation | Time |
	|---|---|
	| `mysum_naive` | $(round(t_naive * 1e9, digits=1)) ns |
	| `mysum_fast`  | $(round(t_fast  * 1e9, digits=1)) ns |
	| speedup | $(round(t_naive / t_fast, digits=2))× |
	"""
end

# ╔═╡ 1201000b-0012-4000-8000-00000000000b
answer_box(hint(md"""
```julia
function mysum_fast(x)
    acc = zero(eltype(x))
    @inbounds @simd for i in eachindex(x)
        acc += x[i]
    end
    return acc
end
```

Without `@simd`, strict IEEE 754 left-to-right ordering prevents the compiler from vectorising the reduction. `@simd` grants permission to reorder, so LLVM can maintain multiple partial sums across vector lanes — typically giving a 4–8× speedup on AVX2 hardware.
"""))

# ╔═╡ 1201000c-0012-4000-8000-00000000000c
md"""
## Part 2 — Dot product with `@simd` and `@fastmath`

Implement `dot_fast(x, y)` that computes the scalar dot product ``\sum_i x_i y_i`` using:
- `@inbounds` inside the loop
- `@simd` to enable vectorised reduction
- `@fastmath` on the whole function body, which allows the compiler to fuse multiply-add operations into a single `fmadd` instruction and reorder partial sums

The accumulator should be initialised with `zero(promote_type(eltype(x), eltype(y)))` so that `dot_fast` works for any numeric element type (e.g. `Float32` or `Float64`).
"""

# ╔═╡ 1201000d-0012-4000-8000-00000000000d
# TODO: Implement dot_fast

# ╔═╡ 1201000e-0012-4000-8000-00000000000e
let
	if !@isdefined(dot_fast)
		func_not_defined(:dot_fast)
	else
		try
			x = rand(1000); y = rand(1000)
			result   = dot_fast(x, y)
			expected = sum(x[i] * y[i] for i in eachindex(x, y))
			if !(result ≈ expected)
				keep_working(md"`dot_fast(x, y)` returned `$(round(result, digits=6))` but expected approximately `$(round(expected, digits=6))`.")
			else
				# Also check Float32 type preservation
				x32 = rand(Float32, 100); y32 = rand(Float32, 100)
				r32 = dot_fast(x32, y32)
				if !(r32 isa Float32)
					keep_working(md"`dot_fast` should return a `Float32` for `Float32` inputs, but got `$(typeof(r32))`.")
				else
					correct()
				end
			end
		catch e
			keep_working(md"Your function threw an error: `$(sprint(showerror, e))`")
		end
	end
end

# ╔═╡ 1201000f-0012-4000-8000-00000000000f
let
	x = rand(2^20); y = rand(2^20)
	t_base = @belapsed sum($x .* $y)
	t_fast = @isdefined(dot_fast) ? @belapsed(dot_fast($x, $y)) : NaN
	md"""
	| Implementation | Time |
	|---|---|
	| `sum(x .* y)` (allocates a temporary) | $(round(t_base * 1e6, digits=2)) µs |
	| `dot_fast(x, y)` (no allocation) | $(round(t_fast * 1e6, digits=2)) µs |
	| speedup | $(round(t_base / t_fast, digits=2))× |
	"""
end

# ╔═╡ 12010010-0012-4000-8000-000000000010
answer_box(hint(md"""
```julia
function dot_fast(x, y)
    acc = zero(promote_type(eltype(x), eltype(y)))
    @fastmath @inbounds @simd for i in eachindex(x, y)
        acc += x[i] * y[i]
    end
    return acc
end
```

`@fastmath` lets the compiler emit `fmadd` (fused multiply-add) instructions and freely reorder the partial sums in the reduction — both of which can double throughput on modern CPUs. The result is still `≈` the true dot product; the error stays within a few ULPs.
"""))

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
BenchmarkTools = "~1.6"
PlutoTeachingTools = "~0.4"
PlutoUI = "~0.7"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "60157c176b9eecd8ca9bf5ce0ec9c32e98e36bf8"

[[deps.AbstractPlutoDingetjes]]
git-tree-sha1 = "6c3913f4e9bdf6ba3c08041a446fb1332716cbc2"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BenchmarkTools]]
deps = ["Compat", "JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "7fecfb1123b8d0232218e2da0c213004ff15358d"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.6.3"

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
git-tree-sha1 = "94ba93778373a53bfd5a0caaf7d809c445292ff4"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.2"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "32a4e09c5f29402573d673901778a0e03b0807b9"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.6"

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

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

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
"""

# ╔═╡ Cell order:
# ╠═12010001-0012-4000-8000-000000000001
# ╠═12010002-0012-4000-8000-000000000002
# ╟─12010003-0012-4000-8000-000000000003
# ╟─12010004-0012-4000-8000-000000000004
# ╟─12010005-0012-4000-8000-000000000005
# ╟─12010006-0012-4000-8000-000000000006
# ╠═12010007-0012-4000-8000-000000000007
# ╠═12010008-0012-4000-8000-000000000008
# ╟─12010009-0012-4000-8000-000000000009
# ╟─1201000a-0012-4000-8000-00000000000a
# ╟─1201000b-0012-4000-8000-00000000000b
# ╟─1201000c-0012-4000-8000-00000000000c
# ╠═1201000d-0012-4000-8000-00000000000d
# ╟─1201000e-0012-4000-8000-00000000000e
# ╟─1201000f-0012-4000-8000-00000000000f
# ╟─12010010-0012-4000-8000-000000000010
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
