### A Pluto.jl notebook ###
# v0.20.24

#> [frontmatter]
#> order = "2.1"
#> exercise_number = "1"
#> title = "Functions and Unicode"
#> tags = ["module1", "track_principles", "exercises"]
#> layout = "layout.jlhtml"
#> description = "Practice writing Julia functions and using Unicode identifiers"
#> 
#>     [[frontmatter.author]]
#>     name = "Valentin Churavy"
#>     url = "https://vchuravy.dev"

using Markdown
using InteractiveUtils

# ╔═╡ a1b2c3d4-1a90-11f0-2f05-47d877772576
using PlutoTeachingTools, PlutoUI

# ╔═╡ c3d4e5f6-1a90-11f0-2f05-47d877772576
PlutoUI.TableOfContents(; depth=4)

# ╔═╡ d4e5f6a7-1a90-11f0-2f05-47d877772576
md"""
# Exercise: Functions and Unicode

Julia supports full Unicode in identifiers, making it easy to write mathematics that reads like a textbook.
"""

# ╔═╡ e5f6a7b8-1a90-11f0-2f05-47d877772576
md"""
## Part 1 — Circle area

Write a function `circle_area(r)` that returns the area of a circle with radius `r`.

- Use the built-in constant `π` (type `\pi` then press Tab to get the Unicode symbol).
- Do **not** hard-code an approximation like `3.14159`.
"""

# ╔═╡ f6a7b8c9-1a90-11f0-2f05-47d877772576
# Write circle_area here

# ╔═╡ a7b8c9d0-1a90-11f0-2f05-47d877772576
let
	if !@isdefined(circle_area)
		func_not_defined(:circle_area)
	elseif !(circle_area(1.0) ≈ π)
		keep_working(md"`circle_area(1.0)` should equal `π`.")
	elseif !(circle_area(2.0) ≈ 4π)
		keep_working(md"`circle_area(2.0)` should equal `4π`.")
	else
		correct()
	end
end

# ╔═╡ b8c9d0e1-1a90-11f0-2f05-47d877772576
answer_box(hint(md"""
```julia
circle_area(r) = π * r^2
```
"""))

# ╔═╡ c9d0e1f2-1a90-11f0-2f05-47d877772576
md"""
## Part 2 — Quadratic formula

Write a function `quadratic(a, b, c)` that returns **both** roots of $ax^2 + bx + c = 0$ as a tuple, using the quadratic formula:

$$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$

Use `√` (type `\sqrt` then Tab) or `sqrt` for the square root.

Check: `quadratic(1, -3, 2)` should return the roots `2.0` and `1.0` (in either order).
"""

# ╔═╡ d0e1f2a3-1a90-11f0-2f05-47d877772576
# Write quadratic here

# ╔═╡ e1f2a3b4-1a90-11f0-2f05-47d877772576
let
	if !@isdefined(quadratic)
		func_not_defined(:quadratic)
	else
		r1, r2 = quadratic(1, -3, 2)
		expected = Set([1.0, 2.0])
		if !(Set([r1, r2]) == expected)
			keep_working(md"`quadratic(1, -3, 2)` should return the roots `1.0` and `2.0`.")
		else
			correct()
		end
	end
end

# ╔═╡ f2a3b4c5-1a90-11f0-2f05-47d877772576
answer_box(hint(md"""
```julia
function quadratic(a, b, c)
    disc = √(b^2 - 4a*c)
    (-b + disc) / (2a), (-b - disc) / (2a)
end
```
"""))

# ╔═╡ a3b4c5d6-1a90-11f0-2f05-47d877772576
md"""
## Part 3 — Unicode variable names

Rewrite the snippet below so that the variable names use proper Greek letters
(`α`, `β`, `γ` via `\alpha`, `\beta`, `\gamma` + Tab).

Then define a function `linear_combo(α, β)` that returns `α * β + α^2`.

```julia
alpha = 0.5
beta  = 1.5
gamma = alpha * beta + alpha^2
```
"""

# ╔═╡ b4c5d6e7-1a90-11f0-2f05-47d877772576
# Write linear_combo here (and optionally the α, β, γ variables)

# ╔═╡ c5d6e7f8-1a90-11f0-2f05-47d877772576
let
	if !@isdefined(linear_combo)
		func_not_defined(:linear_combo)
	elseif !(linear_combo(0.5, 1.5) ≈ 0.5 * 1.5 + 0.5^2)
		keep_working(md"`linear_combo(0.5, 1.5)` should equal `0.5 * 1.5 + 0.5^2 = 1.0`.")
	else
		correct()
	end
end

# ╔═╡ d6e7f8a9-1a90-11f0-2f05-47d877772576
answer_box(hint(md"""
```julia
α = 0.5
β = 1.5
γ = α * β + α^2

linear_combo(α, β) = α * β + α^2
linear_combo(0.5, 1.5)   # 1.0
```
"""))

# ╔═╡ fe462959-e84f-4ba4-823a-5b5140fa8416
md"""
## Part 3 — Playing darts to estimate Pi

You and some friends are playing darts. You all are very bad at darts. Each throw is guaranteed to hit the square board depicted below, but otherwise each throw will land in a completely random position within the square. To entertain yourself during this pathetic display, you decide to use this as an opportunity to estimate the irrational number $(π)

Because each throw falls randomly within the square, you realize that the probability of a dart landing within the circle is given by the ratio of the circle’s area to the square’s area:

```math
P_{circle} = \frac{Area_{circle}}{Area_{square}} = \frac{\pi r^2}{(2r)^2}
```

Furthermore, we can interpret $P_{circle}$ as being approximated by the fraction of darts thrown that land in the circle. Thus, we find:

```math
\frac{N_{circle}}{N_{total}} \approx \frac{\pi r^2}{(2r)^2} = \frac{\pi}{4}
```

where $N_{total}$ is the total number of darts thrown, and is $N_{circle}$ the number of darts that land within the circle. Thus simply by keeping tally of where the darts land, you can begin to estimate the value of π!

"""

# ╔═╡ a40dcfdd-c0a9-4a44-9e1f-f73af9e610a5
md"""
Write code that simulates the dart throwing and tallying process. For simplicity, you can assume that the board is centered at  $(0,0)$, and that $r=1$ (the radius of the circle). Use `rand` to randomly generate the positions on the board where the darts land. Do this for $N$ darts in total. For each dart thrown determine whether or not it landed within the circle, and update your estimate of π according to the formula: $N_{circle}/N_{total} = \pi/4$

Keep in mind that each dart can land in $(x∈[-1,1], y∈[-1,1])$ and that a dart that lands $(x,y)$at falls within the circle if

$\sqrt{x^2 +y^2} < 1$
"""

# ╔═╡ aee71697-601d-46ea-8e7a-03978707c8db
# write a estimate_pi(N) function here

# ╔═╡ 71283db4-aec9-4c3a-b04f-653dd771ff29
let
	if !@isdefined(estimate_pi)
		func_not_defined(:estimate_pi)
	elseif !(round(estimate_pi(100_000),digits=1) == round(π,digits=1))
		keep_working(md"`estimate_pi(100_000)` should equal `round(π,digits=1)`.")
	elseif !(round(estimate_pi(100_000_000),digits=2) == round(π,digits=2))
		keep_working(md"`estimate_pi(100_000_000)` should equal `round(π,digits=2)`.")
	else
		correct()
	end
end

# ╔═╡ 8b37efdb-b4cd-4fbc-9f33-62bee67da371
round(π,digits=4)

# ╔═╡ ead7abcd-192d-4c61-93ce-0872bc16c05f
answer_box(hint(md"""
```julia
function estimate_pi(N=10_000)
	total = 0
	circle = 0

	for _ in 1:N
		x = 2 * rand() - 1
		y = 2 * rand() - 1
		if sqrt(x^2 + y^2) < 1
			circle += 1
		end
		total += 1
	end
	4*circle/total
end
```
"""))

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PlutoTeachingTools = "~0.4"
PlutoUI = "~0.7"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "298d939e2def5605c9bbf33e4a51404869962d9d"

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
# ╠═a1b2c3d4-1a90-11f0-2f05-47d877772576
# ╟─c3d4e5f6-1a90-11f0-2f05-47d877772576
# ╟─d4e5f6a7-1a90-11f0-2f05-47d877772576
# ╟─e5f6a7b8-1a90-11f0-2f05-47d877772576
# ╠═f6a7b8c9-1a90-11f0-2f05-47d877772576
# ╟─a7b8c9d0-1a90-11f0-2f05-47d877772576
# ╟─b8c9d0e1-1a90-11f0-2f05-47d877772576
# ╟─c9d0e1f2-1a90-11f0-2f05-47d877772576
# ╠═d0e1f2a3-1a90-11f0-2f05-47d877772576
# ╟─e1f2a3b4-1a90-11f0-2f05-47d877772576
# ╟─f2a3b4c5-1a90-11f0-2f05-47d877772576
# ╟─a3b4c5d6-1a90-11f0-2f05-47d877772576
# ╠═b4c5d6e7-1a90-11f0-2f05-47d877772576
# ╟─c5d6e7f8-1a90-11f0-2f05-47d877772576
# ╟─d6e7f8a9-1a90-11f0-2f05-47d877772576
# ╟─fe462959-e84f-4ba4-823a-5b5140fa8416
# ╟─a40dcfdd-c0a9-4a44-9e1f-f73af9e610a5
# ╠═aee71697-601d-46ea-8e7a-03978707c8db
# ╟─71283db4-aec9-4c3a-b04f-653dd771ff29
# ╠═8b37efdb-b4cd-4fbc-9f33-62bee67da371
# ╟─ead7abcd-192d-4c61-93ce-0872bc16c05f
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
