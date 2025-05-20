### A Pluto.jl notebook ###
# v0.20.6

#> [frontmatter]
#> chapter = "2"
#> section = "2"
#> order = "6"
#> title = "Reproducibility"
#> date = "2025-05-21"
#> tags = ["module2", "track_principles"]
#> layout = "layout.jlhtml"
#> 
#>     [[frontmatter.author]]
#>     name = "Valentin Churavy"
#>     url = "https://vchuravy.dev"

using Markdown
using InteractiveUtils

# ╔═╡ 5c4c21e4-1a90-11f0-2f05-47d877772576
using PlutoUI

# ╔═╡ 5f6deede-7e22-4ebf-ae1a-14d584595f17
html"<button onclick='present()'>Toggle presentation mode</button>"

# ╔═╡ aa46fef4-0c92-4947-ac64-f06ee31cb43f
PlutoUI.TableOfContents(; depth=4)

# ╔═╡ 0be73b29-7780-4be0-bf07-9b62c99fc4b4
md"""
# Reproducibility

Two questions:

1. Does my code **execute** on another computer
    - Can someone else do it without my intervention
2. Do we calculate the same results?
"""

# ╔═╡ e70cbf6f-488f-4d5c-a097-7e36bd445f67
md"""
## Julia's package manager
"""

# ╔═╡ 5500f36a-57c6-4efb-b20e-4c766e20d2fe
md"""
!!! note
    In Pluto the package-manager is tightly integrated. This leads to reproducible note-books. Open a Pluto notebook in an editor! What do you see? 
"""

# ╔═╡ 3e29e55b-fa8c-40fd-b5c3-8d804db5967d
md"""
### Project.toml
"""

# ╔═╡ 48862074-afaa-4a7a-babe-a0fbc6965620
md"""
#### Manifest.toml
"""

# ╔═╡ 4a8e696e-f060-40d8-a8d6-5dca99a5e0b5
md"""
### Pkg.jl
"""

# ╔═╡ 73339498-d236-42ce-ad8d-58918b9fe248
md"""
### Preferences.jl
"""

# ╔═╡ 0105ef53-817b-4e29-bb96-dcc890483b27
md"""
### Binaries
"""

# ╔═╡ dcfd1a1a-e9cf-4216-ad66-48775dfe3d90
md"""
## Workflows
"""

# ╔═╡ 18cfbe65-8895-4c89-a90a-c9620efd5ab2
md"""
## Numerical reproducibility

- [What every Computer Scientist should know about Floating-Point arithmetic](https://dl.acm.org/doi/10.1145/103162.103163) 
"""

# ╔═╡ e865a795-5704-49ec-8548-195399cbae20
md"""
### Order of summing
- 
"""

# ╔═╡ cb4980f7-4285-437d-9dfd-1ee14aa10a02
md"""
### 2046 floating pointer numbers that sum to (almost) anything

Thanks to [Stefan Karpinski](https://discourse.julialang.org/t/array-ordering-and-naive-summation/1929)
"""

# ╔═╡ 017ad668-0cb6-4e12-9672-9f917a902939
(0.1 + 0.2) + 0.3

# ╔═╡ 2ab18473-2cbc-4508-8e02-3346b3f10512
 0.1 + (0.2 + 0.3)

# ╔═╡ 7fab467c-9277-4a28-a854-121bbf279fa1
md"""
The `sumsto` function always returns the same 2046 floating-point numbers but returns them in a different order based on `x`: for any 64-bit float value of `x` from 0 up to (but not including) 2^970, the naive left-to-right sum of the vector returned by `sumsto(x)` is precisely `x`:
"""

# ╔═╡ 76149ceb-e19b-415e-8c3e-8e752a0b33f7
function sumsto(x::Float64)
    0 <= x < exp2(970) || throw(ArgumentError("sum must be in [0,2^970)"))
    n, p₀ = Base.decompose(x) # integers such that `n*exp2(p₀) == x`
    [floatmax(); [exp2(p) for p in -1074:969 if iseven(n >> (p-p₀))]
    -floatmax(); [exp2(p) for p in -1074:969 if isodd(n >> (p-p₀))]]
end

# ╔═╡ beb3ac00-d5e6-4ba5-b130-34db904c0d06
foldl(+, sumsto(0.0))

# ╔═╡ 954aea7f-229d-486e-8bec-92bc323dee86
foldl(+, sumsto(eps(0.0)))

# ╔═╡ be837dec-8b71-4a13-86c3-71012f7c3382
foldl(+, sumsto(1.23))

# ╔═╡ 4813d655-706c-4ccf-91fb-19f4bc0dabaa
foldl(+, sumsto(pi+0))

# ╔═╡ b5ec5cac-3316-411c-9de6-63ebf5c2aa53
foldl(+, sumsto(6.0221409e23))

# ╔═╡ e078fa8e-6c28-4a7a-8553-077206068725
foldl(+, sumsto(9.979201547673598e291))

# ╔═╡ e499f486-0839-4430-80ea-afd2da5d8621
md"""
When adding the values from left to right, all the powers of two after `floatmax()` but before `-floatmax()` have no effect on the sum. Then `-floatmax()` cancels `floatmax()` out, bringing the sum back to zero so the remaining powers of two are added up as expected, giving the final result, `x`. There are 2044 powers of two that can be represented as 64-bit floating-point value below 2^970 since the smallest representable power of 2 is `eps(0.0) == exp2(-1074) == 5.0e-324`. So the number of values we’re summing is 1074 + 970 + 2, one for each power of two and two more for `floatmax()` and `-floatmax()`.
"""

# ╔═╡ d71b32cf-a506-4ff0-8e75-4f6064b66b5a
md"""
### Fast-math

- https://simonbyrne.github.io/notes/fastmath/
- https://llvm.org/devmtg/2024-10/slides/techtalk/Kaylor-Towards-Useful-Fast-Math.pdf
"""

# ╔═╡ 4169bd7e-f88d-46a7-8ac9-a878b0535709
function foo()
	A = 1.0f0
	C = 1.0f0

	# Find the smallest value A = 2^k  for which (A + 1 - A) != 1
	while C == 1.0f0
		A *= 2.0f0
		C = A + 1.0f0 - A
	end

	return A
end

# ╔═╡ 03050d92-c1bf-4ff8-8695-daa52cbbf9fe
foo()

# ╔═╡ 88dfd9d8-5438-492e-afdf-cdc53d60fed8
md"""
!!! warning
    Do not execute `foo_fast`! It will loop forever.
"""

# ╔═╡ e9ccfcea-c13b-4525-bb99-72ed99c360fb
function foo_fast()
	A = 1.0f0
	C = 1.0f0

	# Find the smallest value A = 2^k  for which (A + 1 - A) != 1
	@fastmath while C == 1.0f0
		A *= 2.0f0
		C = A + 1.0f0 - A
	end

	return A
end

# ╔═╡ ce5c465d-0de4-4980-a138-08d1617879bb
with_terminal() do
	@code_llvm foo_fast()
end

# ╔═╡ c158b69f-beb9-4aef-bc48-e6cdbb9a15a9
md"""
### Precision of mathematical implementations
"""

# ╔═╡ dfe25ec0-c310-4aa3-9c08-a68fe0034561


# ╔═╡ 760e6987-0631-4fcb-8355-1d81b8067680
md"""
### Implementation of Float16
"""

# ╔═╡ 49e158a5-43fb-44e3-a0fe-ff8dcecc6cab
md"""
```julia
abstract type Number end
abstract type Real <: Number end
abstract type AbstractFloat <: Real end
primitive type Float64 <: AbstractFloat 64 end
primitive type Float32 <: AbstractFloat 32 end
primitive type Float16 <: AbstractFloat 16 end
```
"""

# ╔═╡ 4a7d7c1d-2586-4be3-8da1-747a2ab52e74
methods(cbrt)

# ╔═╡ 4ce03161-6375-4ee3-91ce-6d50f5f8fefd
md"""
First attempt: Naively lowering Float16 to LLVM’s half type.


What to do on platforms with no/limited hardware support


Extended precision (thanks x87) rears it’s ugly head


Lesson: In order to implement numerical routines that are portable we must be very careful in what semantics we promise.


Solution: On targets without hardware support for `Float16`, truncate after each operation.
GCC 12 supports this as: `-fexcess-precision=16`
"""

# ╔═╡ eae704b8-97bf-4b82-a9dc-ec0453cdd37b
md"""
On x86
"""

# ╔═╡ 5a783949-59a5-4cbf-8563-dde81f3f2d80
md"""
```llvm
define half @julia_muladd(half %0, half %1, half %2) {
top:
  %3 = fmul half %0, %1
  %4 = fadd half %3, %2
  ret half %4
}
```
"""

# ╔═╡ 2762ac92-7ed2-4ad1-9ac0-5894e218404f
md"""
turns into:
"""

# ╔═╡ 0202368f-ae34-4b23-b33a-f1552d3df85c
md"""
```
define half @julia_muladd(half %0, half %1, half %2){
top:
  %3 = fpext half %0 to float
  %4 = fpext half %1 to float
  %5 = fmul float %3, %4
  %6 = fptrunc float %5 to half
  %7 = fpext half %6 to float
  %8 = fpext half %2 to float
  %9 = fadd float %7, %8
  %10 = fptrunc float %9 to half
  ret half %10
```
"""

# ╔═╡ ed224fe1-4b82-4b20-a5ba-6b0021d14628
md"""
On your machine?:
"""

# ╔═╡ 1f4619c4-5bfe-47f3-a721-6f37b3a2fc26
with_terminal() do
	code_llvm(muladd, (Float16, Float16, Float16), optimize=false)
end

# ╔═╡ cfa19d3a-1e4d-420e-8760-b0e1019d7516
with_terminal() do
	code_llvm(muladd, (Float16, Float16, Float16))
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PlutoUI = "~0.7.62"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "8ee5d63d41e3e4bb137628ac5343048da171f71e"

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

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

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

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "44f6c1f38f77cafef9450ff93946c53bd9ca16ff"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "d3de2694b52a01ce61a036f18ea9c0f61c4a9230"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.62"

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

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

    [deps.Statistics.weakdeps]
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

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
# ╟─5f6deede-7e22-4ebf-ae1a-14d584595f17
# ╟─5c4c21e4-1a90-11f0-2f05-47d877772576
# ╟─aa46fef4-0c92-4947-ac64-f06ee31cb43f
# ╟─0be73b29-7780-4be0-bf07-9b62c99fc4b4
# ╟─e70cbf6f-488f-4d5c-a097-7e36bd445f67
# ╟─5500f36a-57c6-4efb-b20e-4c766e20d2fe
# ╟─3e29e55b-fa8c-40fd-b5c3-8d804db5967d
# ╟─48862074-afaa-4a7a-babe-a0fbc6965620
# ╟─4a8e696e-f060-40d8-a8d6-5dca99a5e0b5
# ╟─73339498-d236-42ce-ad8d-58918b9fe248
# ╠═0105ef53-817b-4e29-bb96-dcc890483b27
# ╟─dcfd1a1a-e9cf-4216-ad66-48775dfe3d90
# ╠═18cfbe65-8895-4c89-a90a-c9620efd5ab2
# ╠═e865a795-5704-49ec-8548-195399cbae20
# ╟─cb4980f7-4285-437d-9dfd-1ee14aa10a02
# ╠═017ad668-0cb6-4e12-9672-9f917a902939
# ╠═2ab18473-2cbc-4508-8e02-3346b3f10512
# ╟─7fab467c-9277-4a28-a854-121bbf279fa1
# ╠═76149ceb-e19b-415e-8c3e-8e752a0b33f7
# ╠═beb3ac00-d5e6-4ba5-b130-34db904c0d06
# ╠═954aea7f-229d-486e-8bec-92bc323dee86
# ╠═be837dec-8b71-4a13-86c3-71012f7c3382
# ╠═4813d655-706c-4ccf-91fb-19f4bc0dabaa
# ╠═b5ec5cac-3316-411c-9de6-63ebf5c2aa53
# ╠═e078fa8e-6c28-4a7a-8553-077206068725
# ╟─e499f486-0839-4430-80ea-afd2da5d8621
# ╟─d71b32cf-a506-4ff0-8e75-4f6064b66b5a
# ╠═4169bd7e-f88d-46a7-8ac9-a878b0535709
# ╠═03050d92-c1bf-4ff8-8695-daa52cbbf9fe
# ╟─88dfd9d8-5438-492e-afdf-cdc53d60fed8
# ╠═e9ccfcea-c13b-4525-bb99-72ed99c360fb
# ╠═ce5c465d-0de4-4980-a138-08d1617879bb
# ╠═c158b69f-beb9-4aef-bc48-e6cdbb9a15a9
# ╠═dfe25ec0-c310-4aa3-9c08-a68fe0034561
# ╟─760e6987-0631-4fcb-8355-1d81b8067680
# ╟─49e158a5-43fb-44e3-a0fe-ff8dcecc6cab
# ╠═4a7d7c1d-2586-4be3-8da1-747a2ab52e74
# ╠═4ce03161-6375-4ee3-91ce-6d50f5f8fefd
# ╟─eae704b8-97bf-4b82-a9dc-ec0453cdd37b
# ╟─5a783949-59a5-4cbf-8563-dde81f3f2d80
# ╟─2762ac92-7ed2-4ad1-9ac0-5894e218404f
# ╟─0202368f-ae34-4b23-b33a-f1552d3df85c
# ╟─ed224fe1-4b82-4b20-a5ba-6b0021d14628
# ╠═1f4619c4-5bfe-47f3-a721-6f37b3a2fc26
# ╠═cfa19d3a-1e4d-420e-8760-b0e1019d7516
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
