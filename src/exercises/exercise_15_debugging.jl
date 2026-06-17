### A Pluto.jl notebook ###
# v1.0.1

#> [frontmatter]
#> order = "7.1"
#> exercise_number = "15"
#> title = "Debugging"
#> tags = ["module2", "track_principles", "exercises"]
#> license = "MIT"
#> layout = "layout.jlhtml"
#> description = "sample exercise"
#> 
#>     [[frontmatter.author]]
#>     name = "Valentin Churavy"
#>     image = "https://avatars.githubusercontent.com/u/145258?v=4"
#>     url = "https://vchuravy.dev"

using Markdown
using InteractiveUtils

# ╔═╡ 4102ceaf-db99-4ae0-a026-1d4488e43d1f
import ForwardDiff

# ╔═╡ 21b8975a-f775-4002-a2ca-bca4b87c23ce
using PlutoTeachingTools

# ╔═╡ b95b424b-0c7b-4c82-b8d0-48610d6865d6
md"""
# Exercise: Debugging directional derivatives
"""

# ╔═╡ 3dc9b338-3b9e-11f0-3f74-d92fbbc6004c
function jvp(F, u, v, ϵ = sqrt(eps()))
    (F(u + ϵ .* v) - F(u)) ./ ϵ
end

# ╔═╡ 8c0e2d22-1fc2-4405-a44e-24a4c188acaf
function jacobian(F, u)
	w = F(u)
	v = similar(u)
	J = similar(u, length(u), length(w))
	for i in length(u)
		v[i] = 1
		J[:, i] = jvp(F, u, v)
	end
	J
end

# ╔═╡ e0adc011-382f-428a-8dc8-1841de97ebec
F1(x) = [x[1]^4 - 3; exp(x[2]) - 2]

# ╔═╡ d0842474-69d9-4a41-b33b-ef235be025ab
jacobian(F1, [1.0, 2.0])

# ╔═╡ e940f8a3-906f-4838-af85-b11e63cf2966
let
	J = jacobian(F1, [1.0, 2.0])
	ref_J = ForwardDiff.jacobian(F1, [1.0, 2.0])
	if J ≈ ref_J
		correct()
	elseif !(J[1,1] ≈ 4.0 && J[2,2] ≈ exp(2.0))
		keep_working(md"The answer is not quite right! Check your diagonal entries")
	elseif J[1,2] != 0.0
		keep_working(md"The answer is not quite right! Think back to one-hot vectors")
	else
		keep_working()
	end
end

# ╔═╡ 00227690-e4ff-4e7a-bd5d-b8e08947c659
F2(x) = [x[1]^4 - 3; exp(x[2]) - 2; log(x[1]) - x[2]^2]

# ╔═╡ dc76859a-9cb6-441f-b208-55e20f3bfa43
jacobian(F2, [1.0, 2.0])

# ╔═╡ 872c0fb2-d393-451d-ad96-1543612457f5
let
	success = false
	try
		J = jacobian(F2, [1.0, 2.0])
		success = true
	catch
	end
	if !success
		keep_working(md"Your function is erroring!")
	else
		ref_J = ForwardDiff.jacobian(F2, [1.0, 2.0])
		if J ≈ ref_J
			correct()
		elseif !(J[1,1] ≈ 4.0 && J[2,2] ≈ exp(2.0))
			keep_working(md"The answer is not quite right! Check your diagonal entries")
		elseif !(J[3,1] ≈ 1.0 && J[3,2] ≈ -4.0)
			keep_working(md"The new entries don't match my expectation.")
		elseif J[1,2] != 0.0
			keep_working(md"The answer is not quite right! Think back to one-hot vectors")
		else
			keep_working()
		end
	end
end

# ╔═╡ c2a4ab20-4ec3-48ab-b7ab-d476f80e7e59
md"""
# Exercise: Linked-List
"""

# ╔═╡ 2fce6d2c-5bf1-4d97-91a8-e4c0ce4b9220
mutable struct LinkedList{T}
	const value::T
	next::Union{Nothing, LinkedList{T}}
	LinkedList(value::T) where T = new{T}(value, nothing)
end

# ╔═╡ 3618e283-73d0-4567-97c6-1eaad9749d32
function collect(ll::LinkedList)
	values = [ll.value]
	while ll.next !== nothing
		push!(values, ll.next.value)
	end
	values
end

# ╔═╡ 60ef9516-c98d-48d3-a5de-2ff0739ea488
ll = LinkedList(1.0)

# ╔═╡ 558e6ce3-b44d-4d72-8cd4-875119366aab
collect(ll)

# ╔═╡ 3621e247-a3bc-42fa-b20a-dcaca71bbf42
md"""
Let's write a function that appends values!
"""

# ╔═╡ 9f5483ce-dbd0-42bf-876c-73d1e43fd682
function append!(ll::LinkedList, value)
	# Find tail
	while ll.next !== nothing
		ll = ll.next
	end
	ll.next = LinkedList(value)
end

# ╔═╡ 4214ceed-9dce-49f1-92d7-408239217117
let
	ll = LinkedList(1.0)
	append!(ll, 2.0)

	# TODO: collect(ll) hangs!
	ll
end

# ╔═╡ 7f5f0cc9-464e-44c0-91a0-70733f2865a2
"""
    insert!(ll, after, value)

Insert a value after another
"""
function insert!(ll::LinkedList, after, value)
	while ll !== nothing
		if ll.value == after
			ll.next = LinkedList(value)
			break
		else
			ll = ll.next
		end
	end	
end

# ╔═╡ 0b050f7e-929c-4cbd-9c66-084bb0d698f9
function delete!(ll::LinkedList, value)
	while ll !== nothing
		if ll.value == value
			ll.next = nothing
			break
		else
			ll = ll.next
		end
	end	
end

# ╔═╡ 2e59c299-8bd2-4a4f-94b0-add48528dfdc
let
	ll = LinkedList(1.0)
	append!(ll, 3.0)
	insert!(ll, 1.0, 2.0)

	# OOPS where did 3.0 go?
	ll
end

# ╔═╡ 61c7a7d7-86b8-46dc-a17a-fd4d5a7e2466
let
	ll = LinkedList(1.0)
	append!(ll, 2.0)
	append!(ll, 3.0)

	delete!(ll, 2.0)

	# OOPS where did 3.0 go, and why is 2.0 still here?
	ll
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"

[compat]
ForwardDiff = "~1.4.1"
PlutoTeachingTools = "~0.4.7"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "cdde2c650986a680050541f71334830b076c385f"

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

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.CommonSubexpressions]]
deps = ["MacroTools"]
git-tree-sha1 = "cda2cfaebb4be89c9084adaca7dd7333369715c5"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.1"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "79a2aca180a85c690c58a020d47b426954b590f8"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.16.0"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

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

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "2c5d0b0e12088cde2cf84afb2784415b1ea3dfee"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "1.4.1"

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

    [deps.ForwardDiff.weakdeps]
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

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

[[deps.IrrationalConstants]]
git-tree-sha1 = "b2d91fe939cae05960e760110b328288867b5758"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.6"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7204148362dafe5fe6a273f855b8ccbe4df8173e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.8.0"

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

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "bba2d9aa057d8f126415de240573e86a8f39d2a1"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "1.0.1"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

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

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "dbd2e8cd2c1c27f0b584f6661b4309609c5a685e"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.4"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.7+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.4+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "94ba93778373a53bfd5a0caaf7d809c445292ff4"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.2"

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

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "6547cbdd8ce32efba0d21c5a40fa96d1a3548f9f"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.8.0"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6ab403037779dae8c514bad259f32a447262455a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.4"

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
# ╟─4102ceaf-db99-4ae0-a026-1d4488e43d1f
# ╟─21b8975a-f775-4002-a2ca-bca4b87c23ce
# ╟─b95b424b-0c7b-4c82-b8d0-48610d6865d6
# ╠═3dc9b338-3b9e-11f0-3f74-d92fbbc6004c
# ╠═8c0e2d22-1fc2-4405-a44e-24a4c188acaf
# ╠═e0adc011-382f-428a-8dc8-1841de97ebec
# ╠═d0842474-69d9-4a41-b33b-ef235be025ab
# ╟─e940f8a3-906f-4838-af85-b11e63cf2966
# ╠═00227690-e4ff-4e7a-bd5d-b8e08947c659
# ╠═dc76859a-9cb6-441f-b208-55e20f3bfa43
# ╟─872c0fb2-d393-451d-ad96-1543612457f5
# ╟─c2a4ab20-4ec3-48ab-b7ab-d476f80e7e59
# ╠═2fce6d2c-5bf1-4d97-91a8-e4c0ce4b9220
# ╠═3618e283-73d0-4567-97c6-1eaad9749d32
# ╠═60ef9516-c98d-48d3-a5de-2ff0739ea488
# ╠═558e6ce3-b44d-4d72-8cd4-875119366aab
# ╟─3621e247-a3bc-42fa-b20a-dcaca71bbf42
# ╠═9f5483ce-dbd0-42bf-876c-73d1e43fd682
# ╠═4214ceed-9dce-49f1-92d7-408239217117
# ╠═7f5f0cc9-464e-44c0-91a0-70733f2865a2
# ╠═0b050f7e-929c-4cbd-9c66-084bb0d698f9
# ╠═2e59c299-8bd2-4a4f-94b0-add48528dfdc
# ╠═61c7a7d7-86b8-46dc-a17a-fd4d5a7e2466
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
