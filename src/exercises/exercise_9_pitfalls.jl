### A Pluto.jl notebook ###
# v0.20.24

#> [frontmatter]
#> order = "4.2"
#> exercise_number = "9"
#> title = "Pitfalls of AD"
#> tags = ["module1", "track_ad", "exercises"]
#> layout = "layout.jlhtml"
#> license = "MIT"
#> description = "Understand and fix common pitfalls in automatic differentiation: type constraints, mixing of types, and perturbation confusion"
#> 
#>     [[frontmatter.author]]
#>     name = "Valentin Churavy"
#>     url = "https://vchuravy.dev"

using Markdown
using InteractiveUtils

# ╔═╡ ff258bfc-41e2-433e-95f9-1cb6988400d6
begin
	using PlutoTeachingTools, PlutoUI
	using PlutoUI: Slider
	PlutoUI.TableOfContents(; depth=4)
end

# ╔═╡ aabbccdd-0001-4000-8000-000000000007
using LinearAlgebra

# ╔═╡ 6bd9908e-944d-47d4-ad61-1ed79cdc5ac8
using HypertextLiteral

# ╔═╡ 8577787d-d72d-4d92-8c69-9e516a85b779
ChooseDisplayMode()

# ╔═╡ 03524177-1749-4697-9927-d1ddb2ce3785
import ForwardDiff

# ╔═╡ 4d5fa063-73c5-4fb4-9d9a-b153502524df
import Enzyme

# ╔═╡ e5b72189-9a74-4b5c-8d19-b2f5d94726cd
function expected_failure(f)
	try
		f()
		Markdown.MD(Markdown.Admonition("warning", "Expected failure", [
			Markdown.Paragraph(["The code was expected to fail, but it evaluated successfully."])
		]))
	catch e
		str = sprint() do io
			showerror(IOContext(io, :color=>true), e)
		end
		@htl """
		<div>
		<jlerror>
		<div class="error-header">
		<secret-h1>Expected error message</secret-h1>
		</div>
		<header style='overflow: auto;'>
		$(embed_display(Text(str)))
		</header>
		</jlerror>
		</div>
		"""
	end
end

# ╔═╡ aabbccdd-0001-4000-8000-000000000002
md"""
# Exercise: Pitfalls of AD

Automatic differentiation is powerful, but it can fail in subtle ways.
In this exercise you will identify and fix three common pitfalls.
"""

# ╔═╡ b51f9f48-9579-4297-aeaa-9acd54b8e286
md"""
## Part 1 — Type constraints
"""

# ╔═╡ 801f8f21-75e8-40c0-b6b0-952ee712dbe3
f(x::Float64) = x^2

# ╔═╡ 1f2c95c5-d087-4677-aa5f-776758e941b4
expected_failure() do
	ForwardDiff.derivative(f, 2.0)
end

# ╔═╡ c0086e6f-41db-4cac-9c42-c308f618c6b4
md"""
!!! note
	ForwardDiff fails but Enzyme (cell below) succeeds.
"""

# ╔═╡ 421d866d-498a-43b0-91fb-5634d463e9e5
question_box(
md"""
Implement `f_fixed` without a type constraint so that `ForwardDiff.derivative(f_fixed, 2.0)` also returns `4.0`.
"""
)

# ╔═╡ 645f0281-3737-4b2c-8b6b-8b19fbdd27ba
# TODO: Implement f_fixed

# ╔═╡ aabbccdd-0001-4000-8000-000000000003
let
	if !@isdefined(f_fixed)
		func_not_defined(:f_fixed)
	else
		try
			result = ForwardDiff.derivative(f_fixed, 2.0)
			if result ≈ 4.0
				correct()
			else
				keep_working(md"`f_fixed'(2.0)` should be `4.0`, got $(result).")
			end
		catch e
			keep_working(md"Your `f_fixed` still causes an error with ForwardDiff.")
		end
	end
end

# ╔═╡ 1996d8c5-8368-4abc-bc2f-d08a03436916
answer_box(hint(
md"""
```julia
f_fixed(x) = x^2
```
"""
))

# ╔═╡ 59d9fc50-57e0-42f5-a40f-ed5e6f41875c
tip(md"""
**ForwardDiff** works by *operator overloading*: it wraps the input in a
`Dual{Float64}` type and relies on Julia's dispatch to propagate derivatives.
A `::Float64` annotation rejects the `Dual` number — hence the error.

**Enzyme** works at the *compiler IR level*: it differentiates the compiled
machine code directly, so source-level type annotations are irrelevant to how
derivatives are propagated.
""")

# ╔═╡ 889539ca-33a4-44d5-90a7-07b92b4f8a68
md"""
## Part 2 — Mixing of types
"""

# ╔═╡ 264b5f27-9172-423a-8b2b-3c60a26361e5
function g(x)
	A = zeros(2, 2)
	A[1,1] = x
	A[2,2] = x
	det(A)
end

# ╔═╡ 615645f1-2eda-4a5e-a8ee-8c60dcb026e2
expected_failure() do
	ForwardDiff.derivative(g, 2.0)
end

# ╔═╡ 6b4df449-c6d0-4e42-bec6-cf8aebe5c9e8
md"""
!!! note
	ForwardDiff fails but Enzyme (cell below) succeeds.
"""

# ╔═╡ d52b9598-37ed-4823-8624-654c7aa69637
question_box(
md"""
Implement `g_fixed` using `zeros(typeof(x), 2, 2)` so that `ForwardDiff.derivative(g_fixed, 2.0)` also returns `4.0`.
"""
)

# ╔═╡ aabbccdd-0001-4000-8000-000000000004
# TODO: Implement g_fixed

# ╔═╡ aabbccdd-0001-4000-8000-000000000005
let
	if !@isdefined(g_fixed)
		func_not_defined(:g_fixed)
	else
		try
			result = ForwardDiff.derivative(g_fixed, 2.0)
			if result ≈ 4.0
				correct()
			else
				keep_working(md"`g_fixed'(2.0)` should be `4.0`, got $(result).")
			end
		catch e
			keep_working(md"Your `g_fixed` still causes an error with ForwardDiff.")
		end
	end
end

# ╔═╡ 75529643-9088-4f04-bd4e-689000d5d6d6
answer_box(hint(
md"""
```julia
function g_fixed(x)
	A = zeros(typeof(x), 2, 2)
	A[1,1] = x
	A[2,2] = x
	det(A)
end
```
"""
))

# ╔═╡ a6d5ccd4-06da-45bf-a210-dcec8d3191e5
md"""
## Part 3 -- Higher-order derivatives

A somewhat natural question is: **How would we obtain higher-order derivatives**.

Interstingly we can define higher order derivatives as a recursive application of AD.
"""

# ╔═╡ d5ca1e3b-0f42-4438-b4cc-2a3d839b1bff
md"""
### Simple AD system

Recall our small AD system from the lecture.
"""

# ╔═╡ 19b85a74-8ccb-4086-9fa7-386e28b15bf0
begin
	struct Dual{T<:Number} <: Number
		value::T
		deriv::T
	end
	Dual(x::Real, y::Real) = Dual{promote_type(typeof(x), typeof(y))}(promote(x, y)...)
	
	Base.convert(::Type{Dual{T}}, x::Real) where {T <: Real} = Dual(x, zero(T))
	Base.promote_rule(::Type{Dual{T}}, ::Type{<:Real}) where {T <: Real} = Dual{T}

	Base.:+(x::Dual, y::Dual) = Dual(x.value + y.value,
								 x.deriv + y.deriv)
	Base.:-(x::Dual, y::Dual) = Dual(x.value - y.value,
								 x.deriv - y.deriv)
	Base.:*(x::Dual, y::Dual) = Dual(x.value * y.value,
								 x.value * y.deriv + x.deriv * y.value)
	Base.:/(x::Dual, y::Dual) = Dual(x.value / y.value,
								 (x.deriv * y.value - x.value * y.deriv) / y.value^2)

	Base.sin(x::Dual) = Dual(sin(x.value), cos(x.value) * x.deriv)
	Base.cos(x::Dual) = Dual(cos(x.value), -sin(x.value) * x.deriv)
	Base.log(x::Dual) = Dual(log(x.value), x.deriv / x.value)
	Base.exp(x::Dual) = Dual(exp(x.value), exp(x.value) * x.deriv)

	# NEW!
	Base.one(x::Dual) = Dual(one(x.value), zero(x.deriv))
	Base.:-(x::Dual) = Dual(-x.value, -x.deriv)
end

# ╔═╡ 5dfa6e38-7382-4632-9ead-27ee56e25592
function derivative_enzyme(f, x) 
	Enzyme.autodiff(Enzyme.Forward, f, Enzyme.Duplicated(x, one(x))) |> only
end

# ╔═╡ a03c51b6-2601-4b6b-bfc4-0530c036ac11
derivative_enzyme(f, 2.0)

# ╔═╡ aabbccdd-0001-4000-8000-000000000006
derivative_enzyme(g, 2.0)

# ╔═╡ ed90483f-5800-40db-b140-635464513422
function nth_derivative_forwarddiff(f::F, x, ::Val{N}) where {F, N}
   if N == 0
	  return f(x)
   else
	  return ForwardDiff.derivative(y->nth_derivative_forwarddiff(f, y, Val(N-1)), x)
   end
end

# ╔═╡ 4ddea8b8-e647-46d3-95b2-b38a010b2504
nth_derivative_forwarddiff(sin, 1.0, Val(1)) == cos(1.0)

# ╔═╡ 0ffba4a9-68f4-4ac0-8908-df98c2daef99
nth_derivative_forwarddiff(sin, 1.0, Val(2)) == -sin(1.0)

# ╔═╡ 6ff9d6fc-d0d9-478f-baeb-c65a261c0dc4
nth_derivative_forwarddiff(sin, 1.0, Val(3)) == -cos(1.0)

# ╔═╡ ca80b204-687f-48c7-88b9-06cc465a4a9b
nth_derivative_forwarddiff(sin, 1.0, Val(4)) == sin(1.0)

# ╔═╡ 62357e53-6ccc-4d86-92da-3ae090a93e5a
begin
	derivative(f, x) = f(Dual(x, one(x))).deriv
	derivative(f) = x -> derivative(f, x)
end

# ╔═╡ 3953860b-4b83-4119-a48d-e29807ed1aa0
function nth_derivative(f::F, x, ::Val{N}) where {F, N}
   if N == 0
	  return f(x)
   else
	  return derivative(y->nth_derivative(f, y, Val(N-1)), x)
   end
end

# ╔═╡ c8323091-d200-4398-83be-586f8782a6c4
nth_derivative(sin, 1.0, Val(0)) == sin(1.0)

# ╔═╡ 2f3356d8-015a-4eec-9fa5-b4bc3bd959cf
nth_derivative(sin, 1.0, Val(1)) == cos(1.0)

# ╔═╡ 5163902d-15eb-4ab4-b1f9-1859ba4bdc39
nth_derivative(sin, 1.0, Val(2)) == -sin(1.0)

# ╔═╡ e99b55ce-c119-4c87-ba64-bc6bedaf9f06
nth_derivative(sin, 1.0, Val(3)) == -cos(1.0)

# ╔═╡ 02e23b87-4925-44d4-be34-79f664af0e11
md"""
### Exercise: Derivation
"""

# ╔═╡ 6e165fd6-860b-4429-b027-8b4724d2cb0b
md"""
Thinking about this in the language of dual numbers.

$D(f, x) := f(x+ϵ).deriv$
"""

# ╔═╡ 946f486a-0592-4ac2-a96f-1075ac8b1f5c
md"""
We can evaluate $D$ symbolically using **substitution**: replace $x$ with $x+\epsilon$, apply the function, then read off the dual part.

**Example:** 

```julia
D(x -> x^2, 3)
((3 + ϵ)^2).deriv
(9 + 6ϵ + ϵ^2).deriv # Remember ϵ^2=0
6
```
"""

# ╔═╡ 5e06a920-1c84-4c6b-aa7f-a7ca83b71314
question_box(md"""
Using the definitions 
			 
$D(f, x) = f(x+\epsilon).\text{deriv}$		 
$\sin(a + b\epsilon) = \sin(a) + \cos(a)\,b\epsilon$
$\cos(a + b\epsilon) = \cos(a) - \sin(a)\,b\epsilon$
			 
Evaluate step by step:
			 
$D(\sin, x)$
$D(\cos, x)$ 
$D(x \mapsto D(\sin, x), x)$
""")

# ╔═╡ 16ae48ca-5668-4004-9a43-560caa06e1b0
md"""
```julia
D(sin, x)
# TODO
```
"""

# ╔═╡ c383cc6c-7504-4f1b-a289-c108c4ba2961
answer_box(hint(
md"""
```julia
D(sin, x)
(sin(x+ϵ)).deriv # Apply rule
(sin(x) + cos(x)ϵ).deriv
cos(x)
```
"""))

# ╔═╡ 8e8c51c9-386c-45b2-a27d-eec9d9e79d49
md"""
```julia
D(cos, x)
# TODO
```
"""

# ╔═╡ 20a29484-258d-4a6b-bd3d-45cc6c2fc50b
answer_box(hint(
md"""
```julia
D(cos, x)
(cos(x+ϵ)).deriv # Apply rule
(cos(x) - sin(x)ϵ).deriv
-sin(x)
```
"""))

# ╔═╡ 075bd65a-1a22-4470-8baf-61a1eab93df3
md"""
```julia
D(x->D(sin, x), x)
# TODO
```
"""

# ╔═╡ 23ce13cd-efbb-4838-aedc-9a6c0d7a3b7b
answer_box(hint(
md"""
```julia
D(x->D(sin, x), x) # substitute
D(sin,x+ϵ).deriv
(sin((x+ϵ) + ϵ).deriv).deriv # apply rule for sin
((sin(x+ϵ) + cos(x+ϵ)ϵ).deriv).deriv # apply rule for sin
((sin(x) + cos(x)ϵ + cos(x+ϵ)ϵ).deriv).deriv # apply rule for cos
((sin(x) + cos(x)ϵ + cos(x)ϵ - sin(x)ϵ^2).deriv).deriv # apply .deriv
(2cos(x) - sin(x)ϵ).deriv # apply .deriv
-sin(x)
```
"""))

# ╔═╡ 5bc374e1-e362-4fc7-bb4e-5149d8ee6f23
md"""
### Exercise: Perturbation confusion
"""

# ╔═╡ df8cb515-3430-43f5-818e-74de0c4a5a0d
md"""
If we have derivatives on different "levels" interact with each other we have to be careful.

$\frac{d}{dx} (x * \frac{d}{dy}(x+y))$

or 
```
f(x, y) = D(x -> x * D(y -> x + y, y), x) 
```
"""

# ╔═╡ 0b3c1f28-8689-4577-bac2-460f79a80919
md"""
Manually differentiating:

$\frac{d}{dx} (x * \frac{d}{dy}(x+y))$
$\frac{d}{dy}(x+y) = 1$
$\frac{d}{dx} (x * 1) = 1$

"""

# ╔═╡ dfbedc8c-6ace-4aad-9cda-a9bfa6d5f280
md"""
!!! warning
	Yet when we use our `derivative` function, we get a wrong answer of $2$.
"""

# ╔═╡ e2214dbf-5c13-4bb6-bc74-af3d07a59188
let D = derivative
	D(x -> x * D(y -> x + y, 3.), 5.)
end

# ╔═╡ bdc627b0-b990-4b89-89f9-d8897d6d6291
md"""
ForwardDiff.jl and Enzyme.jl get this right
"""

# ╔═╡ 27982180-7a49-4ecc-9af3-54af80643538
let D = ForwardDiff.derivative
	D(x -> x * D(y -> x + y, 3.), 5.)
end

# ╔═╡ 7a7fc131-5a2a-489e-acab-49ef863e2828
let D = derivative_enzyme
	D(x -> x * D(y -> x + y, 3.0), 5.0)
end

# ╔═╡ 4fb03f1a-fbd5-4230-ac8f-8a47d742a09a
question_box(md"""
Evaluate the expression below step-by-step through substitution.
Start by substituting $x$ with $5+\epsilon$.

$$D(x \mapsto x \cdot D(y \mapsto x + y,\; 3),\; 5)$$

Why does the result differ from the correct answer of $1$?
""")

# ╔═╡ 6a10fd08-8151-4f98-b9f7-4ba8ba328bec
md"""
```julia
D(x -> x   * D(y ->   x   + y, 3 ), 5   ) # substitute x with 5+ϵ
# TODO
```
"""

# ╔═╡ b497fd1a-22bc-48d6-bec9-997dcc5c1eb4
answer_box(hint(md"""
```julia
D(x -> x   * D(y ->   x   + y, 3 ), 5   )       # substitute x with 5+ϵ
 (   (5+ϵ) * D(y -> (5+ϵ) + y, 3 )      ).deriv # substitute y with 3+ϵ
 (   (5+ϵ) *  (     (5+ϵ) + (3+ϵ)).deriv).deriv # apply rule for +
 (   (5+ϵ) *  (         (8+2ϵ)   ).deriv).deriv # simplify
 (   (5+ϵ) *              2             ).deriv # extract inner deriv
 (      (10+2ϵ)                         ).deriv # apply rule for *
           2                                    # extract outer deriv
```

The inner $D$ sees $x$ as $5+\epsilon$ (not just $5$), so
$D(y \mapsto (5+\epsilon)+y,\;3) = ((5+\epsilon)+(3+\epsilon)).\text{deriv} = 2$
instead of $1$. The outer and inner $\epsilon$ tags interact — this is **perturbation confusion**.
"""))

# ╔═╡ 5991ca4a-e1d3-4ef8-9809-6c00c0b694e2
md"""
We see an interaction between the inner and the outer derivative.
"""

# ╔═╡ 4af2dc42-6398-40f7-ab2f-9b19aa11d06e
md"""
We fix this by introducing tagged $\epsilon$

$\epsilon_1^2=0$
$\epsilon_2^2=0$
$\epsilon_1 \neq \epsilon_2 \neq \epsilon_1\epsilon_2 \neq 0$

But better just to use ForwardDiff or Enymze.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Enzyme = "~0.13.140"
ForwardDiff = "~1.3.3"
HypertextLiteral = "~1.0.0"
PlutoTeachingTools = "~0.4.7"
PlutoUI = "~0.7.80"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "5ed64085a581fb7979fbcd7cd0cfe88f09f6f26a"

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
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.Enzyme]]
deps = ["CEnum", "EnzymeCore", "Enzyme_jll", "GPUCompiler", "InteractiveUtils", "LLVM", "Libdl", "LinearAlgebra", "ObjectFile", "PrecompileTools", "Preferences", "Printf", "Random", "SparseArrays"]
git-tree-sha1 = "78704dd8d84c93a7f2ac5af0bbb95d26763ec9b9"
uuid = "7da242da-08ed-463a-9acd-ee780be4f1d9"
version = "0.13.140"

    [deps.Enzyme.extensions]
    EnzymeBFloat16sExt = "BFloat16s"
    EnzymeChainRulesCoreExt = "ChainRulesCore"
    EnzymeGPUArraysCoreExt = "GPUArraysCore"
    EnzymeLogExpFunctionsExt = "LogExpFunctions"
    EnzymeSpecialFunctionsExt = "SpecialFunctions"
    EnzymeStaticArraysExt = "StaticArrays"

    [deps.Enzyme.weakdeps]
    ADTypes = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
    BFloat16s = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    LogExpFunctions = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.EnzymeCore]]
git-tree-sha1 = "c6ee69ee502060982d12dbaaf3d8fcb4e835a0d1"
uuid = "f151be2c-9106-41f4-ab19-57ee4f262869"
version = "0.8.20"

    [deps.EnzymeCore.extensions]
    AdaptExt = "Adapt"
    EnzymeCoreChainRulesCoreExt = "ChainRulesCore"

    [deps.EnzymeCore.weakdeps]
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.Enzyme_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "d3ad8f5eca369ac8803ff7db660028d47debc75d"
uuid = "7cc45869-7501-5eee-bdea-0790c847d4ef"
version = "0.0.258+0"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

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

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "cddeab6487248a39dae1a960fff0ac17b2a28888"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "1.3.3"

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

    [deps.ForwardDiff.weakdeps]
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.GPUCompiler]]
deps = ["ExprTools", "InteractiveUtils", "LLVM", "Libdl", "Logging", "PrecompileTools", "Preferences", "Scratch", "Serialization", "TOML", "Tracy", "UUIDs"]
git-tree-sha1 = "fedfe5e7db7035271c3f58359007f971da1dde87"
uuid = "61eb1bfa-7361-4325-ad38-22787b887f55"
version = "1.9.1"

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

[[deps.LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "PrecompileTools", "Preferences", "Printf", "Unicode"]
git-tree-sha1 = "85592339c4363f40863f0b61f9cba80b885070c3"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "9.7.1"

    [deps.LLVM.extensions]
    BFloat16sExt = "BFloat16s"

    [deps.LLVM.weakdeps]
    BFloat16s = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"

[[deps.LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "f1d1adfff151fd02b4062d1af82df02052dc4a0c"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.42+0"

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

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"
version = "1.11.0"

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

[[deps.LibTracyClient_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d4e20500d210247322901841d4eafc7a0c52642d"
uuid = "ad6e5548-8b26-5c9f-8ef3-ef0ad883f3a5"
version = "0.13.1+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"
version = "1.11.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.12.0"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "13ca9e2586b89836fd20cccf56e57e2b9ae7f38f"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.29"

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
git-tree-sha1 = "9b8215b1ee9e78a293f99797cd31375471b2bcae"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.3"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

[[deps.ObjectFile]]
deps = ["Reexport", "StructIO"]
git-tree-sha1 = "22faba70c22d2f03e60fbc61da99c4ebfc3eb9ba"
uuid = "d8793406-e978-5875-9003-1fc021f44a92"
version = "0.5.0"

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

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "07a921781cab75691315adc645096ed5e370cb77"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.3.3"

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

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "9b81b8393e50b7d4e6d0a9f14e192294d3b7c109"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.3.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.12.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "2700b235561b0335d5bef7097a111dc513b8655e"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.7.2"

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
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StructIO]]
git-tree-sha1 = "c581be48ae1cbf83e899b14c07a807e1787512cc"
uuid = "53d494c1-5632-5724-8f4c-31dff12d585f"
version = "0.3.1"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.8.3+2"

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

[[deps.Tracy]]
deps = ["ExprTools", "LibTracyClient_jll", "Libdl"]
git-tree-sha1 = "73e3ff50fd3990874c59fef0f35d10644a1487bc"
uuid = "e689c965-62c8-4b79-b2c5-8359227902fd"
version = "0.1.6"

    [deps.Tracy.extensions]
    TracyProfilerExt = "TracyProfiler_jll"

    [deps.Tracy.weakdeps]
    TracyProfiler_jll = "0c351ed6-8a68-550e-8b79-de6f926da83c"

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
# ╟─ff258bfc-41e2-433e-95f9-1cb6988400d6
# ╠═8577787d-d72d-4d92-8c69-9e516a85b779
# ╠═03524177-1749-4697-9927-d1ddb2ce3785
# ╠═aabbccdd-0001-4000-8000-000000000007
# ╠═4d5fa063-73c5-4fb4-9d9a-b153502524df
# ╟─6bd9908e-944d-47d4-ad61-1ed79cdc5ac8
# ╟─e5b72189-9a74-4b5c-8d19-b2f5d94726cd
# ╠═5dfa6e38-7382-4632-9ead-27ee56e25592
# ╟─aabbccdd-0001-4000-8000-000000000002
# ╟─b51f9f48-9579-4297-aeaa-9acd54b8e286
# ╠═801f8f21-75e8-40c0-b6b0-952ee712dbe3
# ╠═1f2c95c5-d087-4677-aa5f-776758e941b4
# ╟─c0086e6f-41db-4cac-9c42-c308f618c6b4
# ╠═a03c51b6-2601-4b6b-bfc4-0530c036ac11
# ╟─421d866d-498a-43b0-91fb-5634d463e9e5
# ╠═645f0281-3737-4b2c-8b6b-8b19fbdd27ba
# ╟─aabbccdd-0001-4000-8000-000000000003
# ╟─1996d8c5-8368-4abc-bc2f-d08a03436916
# ╟─59d9fc50-57e0-42f5-a40f-ed5e6f41875c
# ╟─889539ca-33a4-44d5-90a7-07b92b4f8a68
# ╠═264b5f27-9172-423a-8b2b-3c60a26361e5
# ╠═615645f1-2eda-4a5e-a8ee-8c60dcb026e2
# ╟─6b4df449-c6d0-4e42-bec6-cf8aebe5c9e8
# ╠═aabbccdd-0001-4000-8000-000000000006
# ╟─d52b9598-37ed-4823-8624-654c7aa69637
# ╠═aabbccdd-0001-4000-8000-000000000004
# ╟─aabbccdd-0001-4000-8000-000000000005
# ╟─75529643-9088-4f04-bd4e-689000d5d6d6
# ╟─a6d5ccd4-06da-45bf-a210-dcec8d3191e5
# ╠═ed90483f-5800-40db-b140-635464513422
# ╠═4ddea8b8-e647-46d3-95b2-b38a010b2504
# ╠═0ffba4a9-68f4-4ac0-8908-df98c2daef99
# ╠═6ff9d6fc-d0d9-478f-baeb-c65a261c0dc4
# ╠═ca80b204-687f-48c7-88b9-06cc465a4a9b
# ╟─d5ca1e3b-0f42-4438-b4cc-2a3d839b1bff
# ╠═19b85a74-8ccb-4086-9fa7-386e28b15bf0
# ╠═62357e53-6ccc-4d86-92da-3ae090a93e5a
# ╠═3953860b-4b83-4119-a48d-e29807ed1aa0
# ╠═c8323091-d200-4398-83be-586f8782a6c4
# ╠═2f3356d8-015a-4eec-9fa5-b4bc3bd959cf
# ╠═5163902d-15eb-4ab4-b1f9-1859ba4bdc39
# ╠═e99b55ce-c119-4c87-ba64-bc6bedaf9f06
# ╟─02e23b87-4925-44d4-be34-79f664af0e11
# ╟─6e165fd6-860b-4429-b027-8b4724d2cb0b
# ╟─946f486a-0592-4ac2-a96f-1075ac8b1f5c
# ╟─5e06a920-1c84-4c6b-aa7f-a7ca83b71314
# ╠═16ae48ca-5668-4004-9a43-560caa06e1b0
# ╟─c383cc6c-7504-4f1b-a289-c108c4ba2961
# ╠═8e8c51c9-386c-45b2-a27d-eec9d9e79d49
# ╟─20a29484-258d-4a6b-bd3d-45cc6c2fc50b
# ╟─075bd65a-1a22-4470-8baf-61a1eab93df3
# ╟─23ce13cd-efbb-4838-aedc-9a6c0d7a3b7b
# ╟─5bc374e1-e362-4fc7-bb4e-5149d8ee6f23
# ╟─df8cb515-3430-43f5-818e-74de0c4a5a0d
# ╟─0b3c1f28-8689-4577-bac2-460f79a80919
# ╟─dfbedc8c-6ace-4aad-9cda-a9bfa6d5f280
# ╠═e2214dbf-5c13-4bb6-bc74-af3d07a59188
# ╟─bdc627b0-b990-4b89-89f9-d8897d6d6291
# ╠═27982180-7a49-4ecc-9af3-54af80643538
# ╠═7a7fc131-5a2a-489e-acab-49ef863e2828
# ╟─4fb03f1a-fbd5-4230-ac8f-8a47d742a09a
# ╟─6a10fd08-8151-4f98-b9f7-4ba8ba328bec
# ╟─b497fd1a-22bc-48d6-bec9-997dcc5c1eb4
# ╟─5991ca4a-e1d3-4ef8-9809-6c00c0b694e2
# ╟─4af2dc42-6398-40f7-ab2f-9b19aa11d06e
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
