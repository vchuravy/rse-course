### A Pluto.jl notebook ###
# v0.20.6

#> [frontmatter]
#> chapter = "1"
#> section = "4"
#> order = "4"
#> title = "Automatic Differentiation"
#> date = "2025-04-16"
#> tags = ["module1", "track_ad"]
#> layout = "layout.jlhtml"
#> 
#>     [[frontmatter.author]]
#>     name = "Valentin Churavy"
#>     url = "https://vchuravy.dev"

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

# ╔═╡ 5eeae36d-988a-4906-ac80-4de96b1969bd
begin
	using PlutoUI, PlutoTeachingTools
	using PlutoUI: Slider
	PlutoUI.TableOfContents(; depth=4)
end

# ╔═╡ 5c4c21e4-1a90-11f0-2f05-47d877772576
begin
	using CairoMakie
	set_theme!(theme_latexfonts();
			   fontsize = 16,
			   Lines = (linewidth = 2,),
			   markersize = 16)
end

# ╔═╡ 424db547-b82b-45ae-a8ac-044de1ed6a0c
using DoubleFloats

# ╔═╡ 708757e8-f115-42d4-a100-9a132d91cd0f
using BenchmarkTools

# ╔═╡ 3a267f1f-1936-4cab-81cc-d42d59169d26
ChooseDisplayMode()

# ╔═╡ 668493d8-bf95-4561-9a3a-2e7f7a987682
md"""
# Introduction to AD

with material from Hendrick Ranocha, Adrian Hill, and Alan Edelman
"""

# ╔═╡ 0c125359-6dcf-49af-887d-e24dbd11ef48
md"""## What is a derivative?
From your calculus classes, you might recall that a function $f: \mathbb{R} \rightarrow \mathbb{R}$
is differentiable at $\tilde{x}$ if there is a number $f'(\tilde{x})$ such that

$\lim_{h \rightarrow 0} \frac{f(\tilde{x} + h) - f(\tilde{x})}{h}
= f'(\tilde{x}) \quad .$

This number $f'(\tilde{x})$ is called the derivative of $f$ at $\tilde{x}$.

Let's visualize this on a simple scalar function:
"""

# ╔═╡ 38b821ed-91a9-414e-9575-eb43e8068956
@bind x̂ Slider(-5:0.2:5, default=-1.5, show_value=true)

# ╔═╡ 779370fe-7513-4f4e-8517-d3328337ac42
md"""
## Partial derivatives

For a multi-variable function like `f(x, y)` we define $\frac{\partial}{\partial x}f$ as the rate of change in the $x$ direction, and likewise $\frac{\partial}{\partial y}f$ as the rate of change in the $y$ direction.
"""

# ╔═╡ cf7662c3-6ad6-4cc8-b73b-42b1bb738f37
@bind x̂₁ Slider(-5:0.2:5, default=-1.5, show_value=true)

# ╔═╡ 47da91d3-8a69-4aa5-a49f-55f9c4f585f9
@bind ŷ₁ Slider(-5:0.2:5, default=-1.5, show_value=true)

# ╔═╡ ddbbc711-bd5b-4d20-962b-7d103e0f31b4
md"""
## Motivating example

In many areas of science we encounter models with unkown parameters:

- Curve fitting
- Machine learning

$f(x; p) = \cdots$

We are often interested in learning these parameters given a training dataset or real-world observation.

Below we study a model that is the combination of a `sin` and `cos` function with four parameters.

"""

# ╔═╡ 74c8acf3-0c7b-4555-a795-0c712546d5b4
question_box(
md"""
Given an "observed" evaluation of `m` can we "learn" the values of `a`, `b`, `c`, `d`?
"""
)

# ╔═╡ 608b15d4-9ab3-405d-b574-167788f0c842
md"""
We could try some random values!
"""

# ╔═╡ 834f9474-8f11-4bda-818e-ed3dd505f444
coeffs_guess = rand(-2.0:0.1:2.0, 4)

# ╔═╡ 3950039e-5d9d-4a00-b511-3f0a583d8309
md"""
We need to define a "loss" a function that measures how far away we are from our solution. The Mean-Squared-Error is a common choice.
"""

# ╔═╡ a7f02fa7-8dac-424e-92d9-cc0f8ed85b93
md"""
So how do we improve our guess systematically?
"""

# ╔═╡ 5429e788-a5ed-434b-a140-379f73b5cfc5
tip(
md"""
We want to change a parameter, such that we are improving.
Randomly trying certainly would get us "somewhere"

- Monte-carlo methods
- Evolutionary algorithms

But what we are after is the "rate of change" in the error given for a parameter
(or all parameters).
"""
)

# ╔═╡ f918e5a2-d1b4-4c7d-93fa-a50dcd0d8fa5
tip(
md"""
Today we are focusing on "forward-mode" automatic differentiation. This means that we conceptualize calculating derivatives by applying an infinitesimal perturbation to an argument of a function.

As we will see for a multi-variable problem like ours this means we need to calculate the partial-derivative for each parameter "seperatly".

In machine-learning one often encounters "reverse-mode" automatic differentiation,
which conceptually applies a perturbation to the "return value" of a function.

We will revisit this in the Lecture: "Automatic Differentiation and Machine Learning"
"""
)

# ╔═╡ 63a62a52-d138-4fae-9c1f-c7dbebb94f45
md"""
## Finite differences

There are several ways to compute a function and its derivative on a computer.
If you use a computer algebra system (CAS), you can compute derivatives analytically,
e.g., using [Wolfram Alpha](https://www.wolframalpha.com).

Another option you should have seen in the introduction to numerical analysis are finite differences. Since the derivative is defined as

$$f'(x) = \lim_{h \to 0} \frac{f(x + h) - f(x)}{h},$$

it makes sense to use the forward difference

$$\frac{f(x + h) - f(x)}{h} \approx f'(x)$$

and approximate the limit by taking a small $h > 0$. However, this leads to round-off
error since we typically represent real numbers via *floating point numbers with fixed precision*.
"""

# ╔═╡ a037e8aa-1b41-4146-814f-af3c6ff38be4
eps(1.0)

# ╔═╡ 5acc8ada-625a-4a8b-a790-a2b57a4ed189
eps(1.0f0)

# ╔═╡ 4fbd8caf-04a5-46f0-8c73-a2db450bd172
eps(1.234e5)

# ╔═╡ 2d1d9e00-f022-4aa1-a64a-9331833f327d
md"""
Thus, there will be two regimes:
- if $h$ is too big, the error of the limit approximation dominates
- if $h$ is too small, the floating point error dominates

We illustrate this for different functions $f$ at $x = 1$. We use different types of floating point numbers and compute the error of the
finite difference approximation.
"""

# ╔═╡ 799fd006-6e40-47cd-98c6-62222e8c74eb
@bind FloatType Select([Float32, Float64, Double64]; default = Float64)

# ╔═╡ 3150ee27-4907-4a83-9969-b1ed75bf6378
md"""
Next, we use the central difference

$$\frac{f(x + h) - f(x - h)}{2 h} \approx f'(x).$$
"""

# ╔═╡ 89d5bd8a-a9e4-4a1a-9e71-206db516a50f
md"""
## Forward-mode AD for scalars

There is a well-know proverb

> Differentiation is mechanics, integration is art

Luckily, we are just interested in differentiation for now. Thus, all we need to do
is to implement the basic rules of calculus like the product rule and the chain rule.
Before doing that, let's consider an example.
"""

# ╔═╡ ac9403df-12f2-436f-bfbd-553e9de1ab2e
md"""We can compute the derivative by hand using the chain rule."""

# ╔═╡ 611ecf77-940d-4c1f-92e3-4249c2d720ef
md"We can think of the function as a kind of *computational graph* obtained by dividing it into steps."

# ╔═╡ 5e99b4d7-5c7a-473a-aace-6e0ea16ec1bf
md"To compute the derivative, we have to apply the chain rule multiple times."

# ╔═╡ 082e9259-8e64-4ffa-8ed7-5c9bdbad0a0c
md"""
We would like to automate this! To do so, we introduce so-called [dual numbers](https://en.wikipedia.org/wiki/Dual_number). They carry both a `value` and derivative (called `deriv`, the ε part above). Formally, a dual number can be written as

$$x + \varepsilon y, \qquad x, y \in \mathbb{R},$$

quite similar to a complex number

$$z = x + \mathrm{i} y, \qquad x, y \in \mathbb{R}.$$

However, the new basis element $\varepsilon$ satisfies

$$\varepsilon^2 = 0$$

instead of $\mathrm{i}^2 = -1$. Thus, the dual number have the algebraic structure of an *algebra* instead of a field like the complex numbers $\mathbb{C}$.

In our applications, the $\varepsilon$ part contains the derivative. Indeed, the rule $\varepsilon^2 = 0$ yields

$$(a + \varepsilon b) (c + \varepsilon d) = a c + \varepsilon (a d + b c),$$

which is just the product rule of calculus. You can code this as follows.
"""

# ╔═╡ b4214f5e-e675-46cb-89aa-1a51b49c141c
begin
	struct Dual{T <: Real} <: Number
		value::T
		deriv::T
	end
	Dual(x::Real, y::Real) = Dual(promote(x, y)...)
end

# ╔═╡ 803c58be-95da-4bba-940e-9a69a16ad6e5
md"Now, we can create such dual numbers."

# ╔═╡ 2fa6bd76-7539-4857-9829-6212689c1d3a
Dual(5, 2.0)

# ╔═╡ 8b9cd1a8-f33d-4ca2-9b4a-6f7684a52b7f
md"Next, we need to implement the required interface methods for numbers."

# ╔═╡ 98a72e2a-7c21-4a31-8c1e-21f4efa7e4ee
Base.:+(x::Dual, y::Dual) = Dual(x.value + y.value,
								 x.deriv + y.deriv)

# ╔═╡ 19c0f6ea-3128-45ce-a198-644f4be7d9f0
Dual(1, 2) + Dual(2.0, 3)

# ╔═╡ 0bd274cb-e359-4a18-ae75-bb91ae101391
Base.:-(x::Dual, y::Dual) = Dual(x.value - y.value,
								 x.deriv - y.deriv)

# ╔═╡ eea941bf-0be0-4002-a07e-4ee5d95645dd
nextfloat(1.0) - 1.0

# ╔═╡ 492d49ba-94aa-4c30-894b-4e59ed98402a
(nextfloat(1.234e5) - 1.234e5)

# ╔═╡ ae46c18f-3e2e-4f92-8a96-ed786215b51f
Dual(1, 2) - Dual(2.0, 3)

# ╔═╡ ce102254-9c7b-48b4-aee2-3acc16bb31ba
Base.:*(x::Dual, y::Dual) = Dual(x.value * y.value,
								 x.value * y.deriv + x.deriv * y.value)

# ╔═╡ 7a5bccfa-fce1-4bd8-8531-048ecb1c6a21
xs = 0.0:0.01:2π

# ╔═╡ 05629dd9-7777-46c8-9851-5b39ce2829df
Dual(1, 2) * Dual(2.0, 3)

# ╔═╡ 4006fed7-9a7d-4eee-bb75-ed7b5472d6d1
Base.:/(x::Dual, y::Dual) = Dual(x.value / y.value,
								 (x.deriv * y.value - x.value * y.deriv) / y.value^2)

# ╔═╡ 3c4079a7-a627-464a-9309-f0f5320d368b
function multi_slider(names, values)
	return PlutoUI.combine() do Child
		inputs = [
			md""" $(name): $(
				Child(name, Slider(vals; show_value=true, default=(first(vals)+last(vals))/2))
			)"""
			
			for (name, vals) in zip(names, values)
		]
		
		md"""
		$(inputs)
		"""
	end
end

# ╔═╡ 4b079423-6c68-4ea0-a51d-b2b3bbfbb0f6
@bind coeffs multi_slider(
	("a", "b", "c", "d"), 
	(-1.0:0.1:2.0,
	 -1.0:0.1:2.0,
	 -1.0:0.1:2.0,
	 -1.0:0.1:2.0,))

# ╔═╡ 14db561f-54c3-41d4-8078-531facb65038
# Mean squared error
function mse(ŷ, y)
	sum((ŷ .- y).^2) / length(y)
end

# ╔═╡ f0ed7963-e935-41cc-9820-94db0c3cd042
Dual(1, 2) / Dual(2.0, 3)

# ╔═╡ 20873272-f1a1-472d-bf05-c96e2f948f02
md"We also need to tell Julia how to convert and promote our dual numbers."

# ╔═╡ 71ec1afe-a7c7-41c8-a05b-32287658c2f5
Base.convert(::Type{Dual{T}}, x::Real) where {T <: Real} = Dual(x, zero(T))

# ╔═╡ ebd73caf-5be3-4b75-a240-031d4a3aa64b
Base.promote_rule(::Type{Dual{T}}, ::Type{<:Real}) where {T <: Real} = Dual{T}

# ╔═╡ 67182362-cf07-463f-9583-00451633bd93
Dual(1, 2) + 3.0

# ╔═╡ 67f88aac-14e4-423c-9a7b-35275a01a309
md"Next, we need to implement the well-know derivatives of special functions."

# ╔═╡ 81a8a7b4-47dc-4e20-a26f-adf6f36d12d9
Base.cos(x::Dual) = Dual(cos(x.value), -sin(x.value) * x.deriv)

# ╔═╡ 10553f26-b660-4889-b0a7-71d68dbc105c
Base.sin(x::Dual) = Dual(sin(x.value), cos(x.value) * x.deriv)

# ╔═╡ 280d83db-080d-4b22-8fc0-a175c8690b4a
f(x) = x^2 - 5 * sin(x) - 10 # you can change this function!

# ╔═╡ 866b8869-47ec-4040-a7ef-a0831370b277
f2(x, y) = x^2 - y^3 - 5 * sin(x) + 5 * cos(y * x) - 20 # you can change this function!

# ╔═╡ ecf84d2e-46f6-4dd1-a5de-a5f65b1d281f
function m(x, a, b, c, d)
	return sin(a*x)*b + cos(c*x)*d
end

# ╔═╡ e86b88d2-baa7-4d41-9539-fb298ba5c123
ys = m.(xs, 0.3, -1.2, 0.5, 0.7)

# ╔═╡ b2cdecef-d2d5-4514-a6cd-d3d453ed9099
lines(xs, ys)

# ╔═╡ f73540da-cf91-4463-9adf-b0e5b98e7b79
ys_guess = m.(xs, coeffs_guess...)

# ╔═╡ 367385c4-65b0-4a4a-aaf1-2cfcd8015b20
mse(ys, ys_guess)

# ╔═╡ b75017e8-bcfd-42fd-8870-9777c2f230e3
let
	fig = Figure()
	ax = Axis(fig[1,1], title="MSE = $(mse(ys, ys_guess))")
	lines!(ax, xs, ys)
	lines!(ax, xs, ys_guess)
	fig
end

# ╔═╡ 6a63cae0-fcd7-4258-a82f-3f752b37225c
let
	neighborhood = -0.3:0.1:0.3

	fig = Figure()
	ax = Axis(fig[1,1])
	for offset in neighborhood
		_ys = m.(xs, coeffs_guess[1]+offset, coeffs_guess[2:end]...)
		lines!(ax, xs, _ys, label="Offset a+$(offset), MSE= $(mse(ys, _ys))" )
	end
	axislegend(ax)
	fig
end

# ╔═╡ a4e57d7a-7232-4189-85ff-8a25a3cb82da
let
	fig = Figure()
	ax = Axis(fig[1,1])

	lines!(ax, xs, sin, label="sin")
	lines!(ax, xs, cos, label="cos")
	lines!(ax, xs, m.(xs, coeffs...), label = "model")

	axislegend(ax)
	fig
end

# ╔═╡ 42af19cc-c2b9-4736-9d07-8376c8b6cf09
sin(Dual(π, 1.0))

# ╔═╡ 89be32ff-786e-4794-9aa7-9246dc488a8c
cos(Dual(π, 1.0))

# ╔═╡ 65dd6dd4-db1d-4e6d-b29c-9dd759567af5
Base.log(x::Dual) = Dual(log(x.value), x.deriv / x.value)

# ╔═╡ a42cc7a3-5e79-4cc9-afce-38e1db38d485
log(Dual(1.0, 1))

# ╔═╡ 34d68aa2-42de-480c-8e1b-ce7dfdd1e538
Base.exp(x::Dual) = Dual(exp(x.value), exp(x.value) * x.deriv)

# ╔═╡ 400c2d07-00f1-404f-b360-572671c467b5
@bind f_diff Select([
	sin => "f(x) = sin(x)",
	cos => "f(x) = cos(x)",
	exp => "f(x) = exp(x)",
	(x -> sin(100 * x)) => "f(x) = sin(100 x)",
	(x -> sin(x / 100)) => "f(x) = sin(x / 100)",
])

# ╔═╡ 7122f82d-32b8-46c3-9299-6f7e31b7fd55
g(x) = log(x^2 + exp(sin(x)))

# ╔═╡ 68d42e2d-10cd-474d-a8c8-681f13bb027c
let x = 1.0, h = sqrt(eps())
	(g(x + h) - g(x)) / h
end

# ╔═╡ bc07318f-abb3-4791-9044-3609c05aebb3
g′(x) = 1 / (x^2 + exp(sin(x))) * (2 * x + exp(sin(x)) * cos(x))

# ╔═╡ 44cc65e6-f622-4601-8f4f-c31b89ce00fe
(g(1.0), g′(1.0))

# ╔═╡ 27220cbf-40ee-4e00-882c-d3a16f048cb0
function g_graph(x)
	c1 = x^2
	c2 = sin(x)
	c3 = exp(c2)
	c4 = c1 + c3
	c5 = log(c4)
	return c5
end

# ╔═╡ 2993b2be-69d1-4d35-81af-73fcd33e1465
g(1.0) ≈ g_graph(1.0)

# ╔═╡ 4e610480-f0d1-420d-a273-08ee98a5438c
function g_graph_derivative(x)
	c1 = x^2
	c1_ε = 2 * x
	
	c2 = sin(x)
	c2_ε = cos(x)
	
	c3 = exp(c2)
	c3_ε = exp(c2) * c2_ε
	
	c4 = c1 + c3
	c4_ε = c1_ε + c3_ε
	
	c5 = log(c4)
	c5_ε = c4_ε / c4
	return c5, c5_ε
end

# ╔═╡ 96c8d882-2970-4497-8638-19c7d34ab492
g_graph_derivative(1.0)

# ╔═╡ 027dcf07-5dbf-4bfe-bab3-9e8ad3279e3a
exp(Dual(1.0, 1))

# ╔═╡ d0ebe0d0-c370-4a9d-ace8-1146da614fda
Base.abs(x::Dual) = Dual(abs(x.value), sign(x.value))

# ╔═╡ 18901d86-b709-4f71-a439-237c7cb06ce9
md"Finally, we can differentiate the function `f` we started with!"

# ╔═╡ 0bb66e77-09a6-43ff-ae28-8085eb03e8d7
let
	g_dual = g(Dual(1.0, 1.0))
	(g_dual.value, g_dual.deriv) .- (g(1.0), g′(1.0))
end

# ╔═╡ 5fcf2dbf-7efe-4581-a347-0769c9638a0b
let
	g_dual = g(Dual(1.0, 1.0))
	(g_dual.value, g_dual.deriv) .- g_graph_derivative(1.0)
end

# ╔═╡ 3dd5c095-1a23-45b3-bdb2-a487b2c4004c
md"This works since the compiler basically performs the transformation `f` $\to$ `f_graph_derivative` for us. We can see this by looking at one stage of the Julia compilation process as follows."

# ╔═╡ f2d0825f-d27d-4869-bb6e-6a88eade3345
@code_typed g(Dual(1.0, 1.0))

# ╔═╡ d3018536-1f68-430f-a71d-89754b2dd620
@code_typed g_graph_derivative(1.0)

# ╔═╡ 51a97752-ac9b-441a-a654-65a82ec6057c
md"Since the compiler can see all the different steps, it can generate very efficient code."

# ╔═╡ 1fdcaee7-3f27-4d97-bace-1a022babaff9
@benchmark g_graph_derivative($(Ref(1.0))[])

# ╔═╡ 9faa9a57-4e7e-4145-a0d5-921f7809721d
@benchmark g(Dual($(Ref(1.0))[], 1.0))

# ╔═╡ 7317e24b-4461-4a6e-b580-94efd6cb12d4
md"Now, we have a versatile tool to compute derivatives of functions depending on a single variable."

# ╔═╡ 552d2403-41a8-4f56-938a-61e6ced75d85
derivative(f, x::Real) = f(Dual(x, one(x))).deriv

# ╔═╡ 69e2683a-caf4-48b0-a71a-b73f24bdab83
md"We can also get the derivative as a function itself."

# ╔═╡ 6f903e30-2c85-4ae1-a4cc-591934f1e012
derivative(f) = x -> derivative(f, x)

# ╔═╡ 9a0fe51f-b1df-46e7-8577-02d8cb4136f5
let
	fig = Figure()
	ax = Axis(fig[1,1], xlabel=L"x")

    # Plot function
    xs = range(-5, 5, 50)
	ymin, ymax = extrema(f.(xs))

	ylims!(ax, ymin-5, ymax+5)
	lines!(ax, xs, f, label=L"Function $f(x)$")

    # Obtain the function f′
    f′ = derivative(f)

    # Plot f′(x)
    lines!(ax, xs, f′; label=L"Derivative $f′(x)$")

    # # Plot 1st order Taylor series approximation
    taylor_approx(x) = f(x̂) + f′(x̂)*(x-x̂) # f(x) ≈ f(x̃) + f′(x̃)(x-x̃)
    lines!(ax, xs, taylor_approx; label=L"Taylor approx. around $\tilde{x}$")

    # # Show point of linearization
    vlines!(ax, [x̂]; color=:grey, linestyle=:dash, label=L"\tilde{x}")
	axislegend(ax, position=:ct)
	fig
end

# ╔═╡ e5193d1e-8613-4cc4-80a0-a08597c720a5
let
	fig = Figure()
	ax = Axis3(fig[1,1], xlabel=L"x", ylabel=L"y", zlabel=L"z", title="f(x,y)")
	ax4 = Axis3(fig[2,1], xlabel=L"x", ylabel=L"y", zlabel=L"z", title="Taylor approx. around x̂=$x̂₁, ŷ=$ŷ₁")

	ax2 = Axis(fig[1, 2], title="Partial deriv. in x at ŷ=$ŷ₁", xlabel=L"x")
	ax3 = Axis(fig[2, 2], title="Partial deriv. in y at x̂", xlabel=L"y")

    # Plot function
    xs = range(-5, 5, 50)
	ys = range(-5, 5, 50)
	zmin, zmax = extrema(f2.(xs, ys'))

	zlims!(ax, zmin-5, zmax+5)
	surface!(ax, xs, ys, f2)
	# lines!(ax, xs, f, label=L"Function $f(x)$")

    # Obtain the partial derivative functions f′
 	f_x′ = derivative(x->f2(x, ŷ₁))
	f_y′ = derivative(y->f2(x̂₁, y))


    # Plot partial f′(x)
    lines!(ax2, xs, f_x′; label=L"Derivative $f_x′(x)$")

	lines!(ax3, ys, f_y′; label=L"Derivative $f_x′(x)$")

    # Plot 1st order Taylor series approximation
    taylor_approx(x, y) = f2(x̂₁, ŷ₁) + f_x′(x̂₁)*(x-x̂₁) + f_y′(ŷ₁)*(y-ŷ₁) 
    surface!(ax4, xs, ys, taylor_approx; label=L"Taylor approx. around $\tilde{x},\tilde{y}$")

	fig
end

# ╔═╡ 583d4563-ac91-43f0-8cb1-2b598974edc7
let 
	fig=Figure()
	ax = Axis(fig[1,1], xlabel=L"a")

    # Plot function
    as = range(-2, 2, 100)

	f(a) = mse(ys, m.(xs, a, coeffs_guess[2:end]...))
	ymin, ymax = extrema(f.(as))

	ylims!(ax, ymin-5, ymax+5)
	lines!(ax, as, f, label=L"Function $f = mse(ys, m(x; a, b, c, d))$")

	# Obtain the function f′
    f′ = derivative(f)

    # Plot f′(x)
    lines!(ax, as, f′; label=L"Derivative $f′(a)$")

	â = coeffs_guess[1]
    # Plot 1st order Taylor series approximation
    taylor_approx(a) = f(â) + f′(â)*(a-â) # f(x) ≈ f(x̃) + f′(x̃)(x-x̃)
    lines!(ax, as, taylor_approx; label=L"Taylor approx. around $\tilde{a}$")

    # Show point of linearization
    vlines!(ax, [â]; color=:grey, linestyle=:dash, label=L"\tilde{a}")
	axislegend(ax, position=:ct)

	fig
end

# ╔═╡ 051b752d-b0aa-4e05-bfc4-5d671e17e6c8
let
	fig = Figure()
	ax = Axis(fig[1, 1]; 
			  xlabel = L"Step size $h$", 
			  ylabel = "Error of the forward differences",
			  xscale = log10, yscale = log10)
	
	f = f_diff
	x = one(FloatType)
	f′x = derivative(f, Float64(x))
	h = FloatType.(10.0 .^ range(-20, 0, length = 500))
	fd_error(h) = max(abs((f(x + h) - f(x)) / h - f′x), eps(x) / 100)
	lines!(ax, h, fd_error.(h); label = "")
	
	h_def = sqrt(eps(x))
	scatter!(ax, [h_def], [fd_error(h_def)]; color = :gray)
	text!(ax, "sqrt(eps(x))"; position=(5 * h_def, fd_error(h_def)), space = :data)
	
	fig
end

# ╔═╡ 518443a4-47d6-4009-bc1b-6272b46a168a
let
	fig = Figure()
	ax = Axis(fig[1, 1]; 
			  xlabel = L"Step size $h$", 
			  ylabel = "Error of the central differences",
			  xscale = log10, yscale = log10)
	
	f = f_diff
	x = one(FloatType)
	(f′x,) = derivative(f, Float64(x))
	h = FloatType.(10.0 .^ range(-20, 0, length = 500))
	fd_error(h) = max(abs((f(x + h) - f(x - h)) / (2 * h) - f′x), eps(x) / 100)
	lines!(ax, h, fd_error.(h); label = "")
	
	h_def = cbrt(eps(x))
	scatter!(ax, [h_def], [fd_error(h_def)]; color = :gray)
	text!(ax, "cbrt(eps(x))"; position=(5 * h_def, fd_error(h_def)), space = :data)
	
	fig
end


# ╔═╡ de74c171-b9e2-4a7e-9550-124508e0dfaa
derivative(g, 1.0)

# ╔═╡ ff552723-12ba-4b9f-92ab-d5ade47b8203
derivative(x -> 3 * x^2 + 4 * x + 5, 2)

# ╔═╡ 2e0c073d-0ad9-4e31-b791-27ac747a8f40
derivative(3) do x
	sin(x) * log(x)
end

# ╔═╡ ad924e1f-ef4c-433e-a259-120c9ef0c2d9
let dg = derivative(g)
	x = range(0.1, 10.0, length = 10)
	dg.(x) - g′.(x)
end

# ╔═╡ 12186fb3-a520-446b-aaf0-6a8e131ac508
let
	fig = Figure()
	ax = Axis(fig[1,1])

	lines!(ax, xs, f_diff, label="f")
	lines!(ax, xs, derivative(f_diff), label="f′")
	axislegend(ax)
	fig
end

# ╔═╡ 55c17860-f5d9-4fda-ad3e-b16b075af06c
tip(md"""
Julia has a robust ecosystem of automatic-differentiation tools! Do not handroll your own library like we did here, but instead use [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl) or [Enzyme.jl](https://github.com/EnzymeAD/Enzyme.jl).
""")

# ╔═╡ 74bf8e0b-5018-422d-8536-a5a03053acd0
md"""
## Popping up the stack
"""

# ╔═╡ dda152e7-a72a-4d71-b01d-c04f5b46de3a
dm_a(x, a, b, c, d) = m(x, Dual(a, one(a)), b, c, d)

# ╔═╡ 432f3155-d4ff-4a92-bf2b-a28cb055f54f
dm_b(x, a, b, c, d) = m(x, a, Dual(b, one(b)), c, d)

# ╔═╡ 747957c4-9908-42d7-a8a1-a94712019912
dm_c(x, a, b, c, d) = m(x, a, b, Dual(c, one(c)), d)

# ╔═╡ bf2c3298-ded1-40ad-8dc6-5cf6b03029db
dm_d(x, a, b, c, d) = m(x, a, b, c, Dual(d, one(d)))

# ╔═╡ 1835ca94-0c73-4dfd-bf7b-c227bf9a7375
mse(ys, dm_a.(xs, coeffs_guess...))

# ╔═╡ 5770d63e-a957-4044-b60d-4d91c6760288
mse(ys, dm_b.(xs, coeffs_guess...))

# ╔═╡ 385a9c94-d180-4e85-8255-fa8970d8153e
mse(ys, dm_c.(xs, coeffs_guess...))

# ╔═╡ 5efd9e58-8677-4b22-af70-492a2beca00a
mse(ys, dm_d.(xs, coeffs_guess...))

# ╔═╡ 8d45c6b6-b0fd-42d2-b265-d90a23b42eac
md"""
We can also write this in vector form
"""

# ╔═╡ ee7cc11a-f127-425a-89a9-dfd31cae7e3e
const one_hot_vectors = [
	[Dual(0.0, 1.0), 0.0, 0.0, 0.0],
	[0.0 ,Dual(0.0, 1.0), 0.0, 0.0],
	[0.0, 0.0, Dual(0.0, 1.0), 0.0],
	[0.0, 0.0, 0.0, Dual(0.0, 1.0)]
]

# ╔═╡ 25a37065-a181-431d-a973-b0a07701f564
dm(loss, ys, xs, coeffs) = map(v->loss(ys, m.(xs, v...)).deriv, map(v->v.+coeffs, one_hot_vectors))

# ╔═╡ 8223c585-24b7-4938-a1fb-08749e8909e0
dm(mse, xs, ys, [coeffs_guess...])

# ╔═╡ 4649dadd-75bb-4ca9-a65a-281f05dfce44
md"""
!!! note
	The need for 4 function evaluation since we have 4 function arguments.
	
"""

# ╔═╡ f9ad118c-65c2-439a-9254-9d025245aa98
begin
	learning_rate = 0.01
	steps = 1000
	plot_every = 100
end

# ╔═╡ b4dcb6d9-99a4-43da-bd3e-8af749c48290
let
	fig = Figure()
	ax = Axis(fig[1,1])
	coeffs = rand(4)
	errs = Float64[]
	for i in 1:steps
		_ys = m.(xs, coeffs...)
		err = mse(ys, _ys)
		push!(errs, err)
		if mod1(i, plot_every) == 1
			lines!(xs, _ys, label="Epoch $i")
		end
		
		dcoeffs = dm(mse, ys, xs, coeffs)
		coeffs .-= learning_rate .* dcoeffs
	end
	_ys = m.(xs, coeffs...)
	err = mse(ys, _ys)
	lines!(xs, _ys, label="Epoch $(steps+1)")

	lines!(xs, ys, label="Goal")
	
	axislegend(ax)

	ax2 = Axis(fig[2,1])
	lines!(ax2, errs)
	fig
end	

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
DoubleFloats = "497a8b3b-efae-58df-a0af-a86822472b78"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
BenchmarkTools = "~1.6.0"
CairoMakie = "~0.13.4"
DoubleFloats = "~1.4.3"
PlutoTeachingTools = "~0.3.1"
PlutoUI = "~0.7.62"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "a3c0ebcd2c65f6173530902f92b58435e7cc6029"

[[deps.AbstractFFTs]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "d92ad398961a3ed262d8bf04a1a2b8340f915fef"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.5.0"
weakdeps = ["ChainRulesCore", "Test"]

    [deps.AbstractFFTs.extensions]
    AbstractFFTsChainRulesCoreExt = "ChainRulesCore"
    AbstractFFTsTestExt = "Test"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "f7817e2e585aa6d924fd714df1e2a84be7896c60"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.3.0"
weakdeps = ["SparseArrays", "StaticArrays"]

    [deps.Adapt.extensions]
    AdaptSparseArraysExt = "SparseArrays"
    AdaptStaticArraysExt = "StaticArrays"

[[deps.AdaptivePredicates]]
git-tree-sha1 = "7e651ea8d262d2d74ce75fdf47c4d63c07dba7a6"
uuid = "35492f91-a3bd-45ad-95db-fcad7dcfedb7"
version = "1.2.0"

[[deps.AliasTables]]
deps = ["PtrArrays", "Random"]
git-tree-sha1 = "9876e1e164b144ca45e9e3198d0b689cadfed9ff"
uuid = "66dad0bd-aa9a-41b7-9441-69ab47430ed8"
version = "1.1.3"

[[deps.Animations]]
deps = ["Colors"]
git-tree-sha1 = "e092fa223bf66a3c41f9c022bd074d916dc303e7"
uuid = "27a7e980-b3e6-11e9-2bcd-0b925532e340"
version = "0.4.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.2"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

[[deps.Automa]]
deps = ["PrecompileTools", "SIMD", "TranscodingStreams"]
git-tree-sha1 = "a8f503e8e1a5f583fbef15a8440c8c7e32185df2"
uuid = "67c07d97-cdcb-5c2c-af73-a7f9c32a568b"
version = "1.1.0"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "01b8ccb13d68535d73d2b0c23e39bd23155fb712"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.1.0"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "16351be62963a67ac4083f748fdb3cca58bfd52f"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.7"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BenchmarkTools]]
deps = ["Compat", "JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "e38fbc49a620f5d0b660d7f543db1009fe0f8336"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.6.0"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CRC32c]]
uuid = "8bf52ea8-c179-5cab-976a-9e18b702a9bc"
version = "1.11.0"

[[deps.CRlibm]]
deps = ["CRlibm_jll"]
git-tree-sha1 = "66188d9d103b92b6cd705214242e27f5737a1e5e"
uuid = "96374032-68de-5a5b-8d9e-752f78720389"
version = "1.0.2"

[[deps.CRlibm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e329286945d0cfc04456972ea732551869af1cfc"
uuid = "4e9b3aee-d8a1-5a3d-ad8b-7d824db253f0"
version = "1.0.1+0"

[[deps.Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "71aa551c5c33f1a4415867fe06b7844faadb0ae9"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.1.1"

[[deps.CairoMakie]]
deps = ["CRC32c", "Cairo", "Cairo_jll", "Colors", "FileIO", "FreeType", "GeometryBasics", "LinearAlgebra", "Makie", "PrecompileTools"]
git-tree-sha1 = "c1c90ea6bba91f769a8fc3ccda802e96620eb24c"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.13.4"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "2ac646d71d0d24b44f3f8c84da8c9f4d70fb67df"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.4+0"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "1713c74e00545bfe14605d2a2be1712de8fbcb58"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.25.1"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "062c5e1a5bf6ada13db96a4ae4749a4c2234f521"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.3.9"

[[deps.ColorBrewer]]
deps = ["Colors", "JSON"]
git-tree-sha1 = "e771a63cc8b539eca78c85b0cabd9233d6c8f06f"
uuid = "a2cac450-b92f-5266-8821-25eda20663c8"
version = "0.4.1"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "403f2d8e209681fcbd9468a8514efff3ea08452e"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.29.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "64e15186f0aa277e174aa81798f7eb8598e0157e"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.ConstructionBase]]
git-tree-sha1 = "76219f1ed5771adbb096743bff43fb5fdd4c1157"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.8"
weakdeps = ["IntervalSets", "LinearAlgebra", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "4e1fe97fdaed23e9dc21d4d664bea76b65fc50a0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.22"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DelaunayTriangulation]]
deps = ["AdaptivePredicates", "EnumX", "ExactPredicates", "Random"]
git-tree-sha1 = "5620ff4ee0084a6ab7097a27ba0c19290200b037"
uuid = "927a84f5-c5f4-47a5-9785-b46e178433df"
version = "1.6.4"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.Distributions]]
deps = ["AliasTables", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "6d8b535fd38293bc54b88455465a1386f8ac1c3c"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.119"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
git-tree-sha1 = "e7b7e6f178525d17c720ab9c081e4ef04429f860"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.4"

[[deps.DoubleFloats]]
deps = ["GenericLinearAlgebra", "LinearAlgebra", "Polynomials", "Printf", "Quadmath", "Random", "Requires", "SpecialFunctions"]
git-tree-sha1 = "1ee9bc92a6b862a5ad556c52a3037249209bec1a"
uuid = "497a8b3b-efae-58df-a0af-a86822472b78"
version = "1.4.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.EnumX]]
git-tree-sha1 = "bddad79635af6aec424f53ed8aad5d7555dc6f00"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.5"

[[deps.ExactPredicates]]
deps = ["IntervalArithmetic", "Random", "StaticArrays"]
git-tree-sha1 = "b3f2ff58735b5f024c392fde763f29b057e4b025"
uuid = "429591f6-91af-11e9-00e2-59fbe8cec110"
version = "2.2.8"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d55dffd9ae73ff72f1c0482454dcf2ec6c6c4a63"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.5+0"

[[deps.Extents]]
git-tree-sha1 = "063512a13dbe9c40d999c439268539aa552d1ae6"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.5"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "8cc47f299902e13f90405ddb5bf87e5d474c0d38"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "6.1.2+0"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "7de7c78d681078f027389e067864a8d53bd7c3c9"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.8.1"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6d6219a004b8cf1e0b4dbe27a2860b8e04eba0be"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.11+0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "b66970a70db13f45b7e57fbda1736e1cf72174ea"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.17.0"

    [deps.FileIO.extensions]
    HTTPExt = "HTTP"

    [deps.FileIO.weakdeps]
    HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"

[[deps.FilePaths]]
deps = ["FilePathsBase", "MacroTools", "Reexport", "Requires"]
git-tree-sha1 = "919d9412dbf53a2e6fe74af62a73ceed0bce0629"
uuid = "8fc22ac5-c921-52a6-82fd-178b2807b824"
version = "0.8.3"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates"]
git-tree-sha1 = "3bab2c5aa25e7840a4b065805c0cdfc01f3068d2"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.24"
weakdeps = ["Mmap", "Test"]

    [deps.FilePathsBase.extensions]
    FilePathsBaseMmapExt = "Mmap"
    FilePathsBaseTestExt = "Test"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"
version = "1.11.0"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "6a70198746448456524cb442b8af316927ff3e1a"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.13.0"
weakdeps = ["PDMats", "SparseArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "301b5d5d731a0654825f1f2e906990f7141a106b"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.16.0+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.FreeType]]
deps = ["CEnum", "FreeType2_jll"]
git-tree-sha1 = "907369da0f8e80728ab49c1c7e09327bf0d6d999"
uuid = "b38be410-82b0-50bf-ab77-7b57e271db43"
version = "4.1.1"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "2c5512e11c791d1baed2049c5652441b28fc6a31"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.4+0"

[[deps.FreeTypeAbstraction]]
deps = ["ColorVectorSpace", "Colors", "FreeType", "GeometryBasics"]
git-tree-sha1 = "d52e255138ac21be31fa633200b65e4e71d26802"
uuid = "663a7486-cb36-511b-a19d-713bb74d65c9"
version = "0.10.6"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7a214fdac5ed5f59a22c2d9a885a16da1c74bbc7"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.17+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.GenericLinearAlgebra]]
deps = ["LinearAlgebra", "Printf", "Random", "libblastrampoline_jll"]
git-tree-sha1 = "ad599869948d79efd63a030c970e2c6e21fecf4a"
uuid = "14197337-ba66-59df-a3e3-ca00e7dcff7a"
version = "0.3.17"

[[deps.GeoFormatTypes]]
git-tree-sha1 = "8e233d5167e63d708d41f87597433f59a0f213fe"
uuid = "68eda718-8dee-11e9-39e7-89f7f65f511f"
version = "0.4.4"

[[deps.GeoInterface]]
deps = ["DataAPI", "Extents", "GeoFormatTypes"]
git-tree-sha1 = "294e99f19869d0b0cb71aef92f19d03649d028d5"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "1.4.1"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "Extents", "GeoInterface", "IterTools", "LinearAlgebra", "PrecompileTools", "Random", "StaticArrays"]
git-tree-sha1 = "65e3f5c519c3ec6a4c59f4c3ba21b6ff3add95b0"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.5.7"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Giflib_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6570366d757b50fabae9f4315ad74d2e40c0560a"
uuid = "59f7168a-df46-5410-90c8-f2779963d0ec"
version = "5.2.3+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "b0036b392358c80d2d2124746c2bf3d48d457938"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.82.4+0"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "a641238db938fff9b2f60d08ed9030387daf428c"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.3"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a6dbda1fd736d60cc477d99f2e7a042acfa46e8"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.15+0"

[[deps.GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Observables"]
git-tree-sha1 = "dc6bed05c15523624909b3953686c5f5ffa10adc"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.11.1"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "55c53be97790242c29031e5cd45e8ac296dadda3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.5.0+0"

[[deps.HypergeometricFunctions]]
deps = ["LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "68c173f4f449de5b438ee67ed0c9c748dc31a2ec"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.28"

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

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "e12629406c6c4442539436581041d372d69c55ba"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.12"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "eb49b82c172811fd2c86759fa0553a2221feb909"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.7"

[[deps.ImageCore]]
deps = ["ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "8c193230235bbcee22c8066b0374f63b5683c2d3"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.5"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs", "WebP"]
git-tree-sha1 = "696144904b76e1ca433b886b4e7edd067d76cbf7"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.9"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "2a81c3897be6fbcde0802a0ebe6796d0562f63ec"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.10"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0936ba688c6d201805a83da835b55c61a180db52"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.11+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl"]
git-tree-sha1 = "0f14a5456bdc6b9731a5682f439a672750a09e48"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2025.0.4+0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "88a101217d7cb38a7b481ccd50d21876e1d1b0e0"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.15.1"
weakdeps = ["Unitful"]

    [deps.Interpolations.extensions]
    InterpolationsUnitfulExt = "Unitful"

[[deps.IntervalArithmetic]]
deps = ["CRlibm", "MacroTools", "OpenBLASConsistentFPCSR_jll", "Random", "RoundingEmulator"]
git-tree-sha1 = "4e1b4155f04ffa0acf3a0d6e3d651892604666f5"
uuid = "d1acc4aa-44c8-5952-acd4-ba5d80a2a253"
version = "0.22.34"

    [deps.IntervalArithmetic.extensions]
    IntervalArithmeticDiffRulesExt = "DiffRules"
    IntervalArithmeticForwardDiffExt = "ForwardDiff"
    IntervalArithmeticIntervalSetsExt = "IntervalSets"
    IntervalArithmeticLinearAlgebraExt = "LinearAlgebra"
    IntervalArithmeticRecipesBaseExt = "RecipesBase"
    IntervalArithmeticSparseArraysExt = "SparseArrays"

    [deps.IntervalArithmetic.weakdeps]
    DiffRules = "b552c78f-8df3-52c6-915a-8e097449b14b"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.IntervalSets]]
git-tree-sha1 = "5fbb102dcb8b1a858111ae81d56682376130517d"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.11"
weakdeps = ["Random", "RecipesBase", "Statistics"]

    [deps.IntervalSets.extensions]
    IntervalSetsRandomExt = "Random"
    IntervalSetsRecipesBaseExt = "RecipesBase"
    IntervalSetsStatisticsExt = "Statistics"

[[deps.InverseFunctions]]
git-tree-sha1 = "a779299d77cd080bf77b97535acecd73e1c5e5cb"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.17"
weakdeps = ["Dates", "Test"]

    [deps.InverseFunctions.extensions]
    InverseFunctionsDatesExt = "Dates"
    InverseFunctionsTestExt = "Test"

[[deps.IrrationalConstants]]
git-tree-sha1 = "e2222959fbc6c19554dc15174c81bf7bf3aa691c"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.4"

[[deps.Isoband]]
deps = ["isoband_jll"]
git-tree-sha1 = "f9b6d97355599074dc867318950adaa6f9946137"
uuid = "f1662d9f-8043-43de-a69a-05efc1cc6ff4"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "42d5f897009e7ff2cf88db414a389e5ed1bdd023"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.10.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

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

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "9496de8fb52c224a2e3f9ff403947674517317d9"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.6"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "eac1206917768cb54957c65a615460d87b455fc1"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.1+0"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "ad08bbc177bc329888d21a94b37beb6aa919273a"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.10.2"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "7d703202e65efa1369de1279c162b915e245eed1"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.9"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "170b660facf5df5de098d866564877e119141cbd"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.2+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aaafe88dccbd957a8d82f7d05be9b69172e0cee3"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.0.1+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "eb62a3deb62fc6d8822c0c4bef73e4412419c5d8"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "18.1.8+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1c602b1127f4751facb671441ca72715cc95938a"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.3+0"

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

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"
version = "1.11.0"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

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

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "27ecae93dd25ee0909666e6835051dd684cc035e"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+2"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "d36c21b9e7c172a44a10484125024495e2625ac0"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.7.1+1"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "be484f5c92fad0bd8acfef35fe017900b0b73809"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.18.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a31572773ac1b745e0343fe5e2c8ddda7a37e997"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.41.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "4ab7581296671007fc33f07a721631b8855f4b1d"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.1+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "321ccef73a96ba828cd51f2ab5b9f917fa73945a"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.41.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

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

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "4ef1c538614e3ec30cb6383b9eb0326a5c3a9763"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "3.3.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "oneTBB_jll"]
git-tree-sha1 = "5de60bc6cb3899cd318d80d627560fae2e2d99ae"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2025.0.1+1"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Makie]]
deps = ["Animations", "Base64", "CRC32c", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "Contour", "Dates", "DelaunayTriangulation", "Distributions", "DocStringExtensions", "Downloads", "FFMPEG_jll", "FileIO", "FilePaths", "FixedPointNumbers", "Format", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageBase", "ImageIO", "InteractiveUtils", "Interpolations", "IntervalSets", "InverseFunctions", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MacroTools", "MakieCore", "Markdown", "MathTeXEngine", "Observables", "OffsetArrays", "PNGFiles", "Packing", "PlotUtils", "PolygonOps", "PrecompileTools", "Printf", "REPL", "Random", "RelocatableFolders", "Scratch", "ShaderAbstractions", "Showoff", "SignedDistanceFields", "SparseArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "TriplotBase", "UnicodeFun", "Unitful"]
git-tree-sha1 = "0318d174aa9ec593ddf6dc340b434657a8f1e068"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.22.4"

[[deps.MakieCore]]
deps = ["ColorTypes", "GeometryBasics", "IntervalSets", "Observables"]
git-tree-sha1 = "903ef1d9d326ebc4a9e6cf24f22194d8da022b50"
uuid = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
version = "0.9.2"

[[deps.MappedArrays]]
git-tree-sha1 = "2dab0221fe2b0f2cb6754eaa743cc266339f527e"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.2"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MathTeXEngine]]
deps = ["AbstractTrees", "Automa", "DataStructures", "FreeTypeAbstraction", "GeometryBasics", "LaTeXStrings", "REPL", "RelocatableFolders", "UnicodeFun"]
git-tree-sha1 = "f5a6805fb46c0285991009b526ec6fae43c6dec2"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.6.3"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"
version = "1.11.0"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "7b86a5d4d70a9f5cdf2dacb3cbe6d251d1a61dbe"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.4"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "9b8215b1ee9e78a293f99797cd31375471b2bcae"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.3"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "d92b107dbb887293622df7697a2223f9f8176fcd"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Observables]]
git-tree-sha1 = "7438a59546cf62428fc9d1bc94729146d37a7225"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.5"

[[deps.OffsetArrays]]
git-tree-sha1 = "117432e406b5c023f665fa73dc26e79ec3630151"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.17.0"
weakdeps = ["Adapt"]

    [deps.OffsetArrays.extensions]
    OffsetArraysAdaptExt = "Adapt"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLASConsistentFPCSR_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "567515ca155d0020a45b05175449b499c63e7015"
uuid = "6cdc7f73-28fd-5e50-80fb-958a8875b1af"
version = "0.3.29+0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.27+1"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "97db9e07fe2091882c765380ef58ec553074e9c7"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.3"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "8292dd5c8a38257111ada2174000a33745b06d4e"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.2.4+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.5+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "9216a80ff3682833ac4b733caa8c00390620ba5d"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.0+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1346c9208249809840c91b26703912dff463d335"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.6+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6703a85cb3781bd5909d48730a67205f3f31a575"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.3+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "cc4054e898b852042d7b503313f7ad03de99c3dd"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.0"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "0e1340b5d98971513bddaa6bbed470670cebbbfe"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.34"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "cf181f0b1e6a18dfeb0ee8acc4a9d1672499626c"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.4.4"

[[deps.Packing]]
deps = ["GeometryBasics"]
git-tree-sha1 = "bc5bf2ea3d5351edf285a06b0016788a121ce92c"
uuid = "19eb6ba3-879d-56ad-ad62-d5c202156566"
version = "0.5.1"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "0fac6313486baae819364c52b4f483450a9d793f"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.12"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3b31172c032a1def20c98dae3f2cdc9d10e3b561"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.56.1+0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "db76b1ecd5e9715f3d043cec13b2ec93ce015d53"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.44.2+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"
weakdeps = ["REPL"]

    [deps.Pkg.extensions]
    REPLExt = "REPL"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f9501cc0430a26bc3d156ae1b5b0c1b47af4d6da"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.3"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "StableRNGs", "Statistics"]
git-tree-sha1 = "3ca9a356cd2e113c420f2c13bea19f8d3fb1cb18"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.3"

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
deps = ["Downloads", "HypertextLiteral", "Latexify", "Markdown", "PlutoLinks", "PlutoUI"]
git-tree-sha1 = "8252b5de1f81dc103eb0293523ddf917695adea1"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.3.1"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "d3de2694b52a01ce61a036f18ea9c0f61c4a9230"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.62"

[[deps.PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

[[deps.Polynomials]]
deps = ["LinearAlgebra", "OrderedCollections", "RecipesBase", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "555c272d20fc80a2658587fb9bbda60067b93b7c"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "4.0.19"

    [deps.Polynomials.extensions]
    PolynomialsChainRulesCoreExt = "ChainRulesCore"
    PolynomialsFFTWExt = "FFTW"
    PolynomialsMakieCoreExt = "MakieCore"
    PolynomialsMutableArithmeticsExt = "MutableArithmetics"

    [deps.Polynomials.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    FFTW = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
    MakieCore = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
    MutableArithmetics = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"

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

[[deps.Profile]]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"
version = "1.11.0"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "13c5103482a8ed1536a54c08d0e742ae3dca2d42"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.10.4"

[[deps.PtrArrays]]
git-tree-sha1 = "1d36ef11a9aaf1e8b74dacc6a731dd1de8fd493d"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.3.0"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "8b3fc30bc0390abdce15f8822c889f669baed73d"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "9da16da70037ba9d701192e27befedefb91ec284"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.11.2"

    [deps.QuadGK.extensions]
    QuadGKEnzymeExt = "Enzyme"

    [deps.QuadGK.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"

[[deps.Quadmath]]
deps = ["Compat", "Printf", "Random", "Requires"]
git-tree-sha1 = "6bc924717c495f24de85867aa94da4de0e6cd1a1"
uuid = "be4d8f0f-7fa4-5f49-b795-2f01399ab2dd"
version = "0.5.13"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "StyledStrings", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"
version = "1.11.0"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
version = "1.11.0"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "1342a47bf3260ee108163042310d26f2be5ec90b"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.5"
weakdeps = ["FixedPointNumbers"]

    [deps.Ratios.extensions]
    RatiosFixedPointNumbersExt = "FixedPointNumbers"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "ffdaf70d81cf6ff22c2b6e733c900c3321cab864"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.1"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "62389eeff14780bfe55195b7204c0d8738436d64"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.1"

[[deps.Revise]]
deps = ["CodeTracking", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "cedc9f9013f7beabd8a9c6d2e22c0ca7c5c2a8ed"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.7.6"
weakdeps = ["Distributed"]

    [deps.Revise.extensions]
    DistributedExt = "Distributed"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "852bd0f55565a9e973fcfee83a84413270224dc4"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.8.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "58cdd8fb2201a6267e1db87ff148dd6c1dbd8ad8"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.5.1+0"

[[deps.RoundingEmulator]]
git-tree-sha1 = "40b9edad2e5287e05bd413a38f61a8ff55b9557b"
uuid = "5eaf0fd0-dfba-4ccb-bf02-d820a40db705"
version = "0.2.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
deps = ["PrecompileTools"]
git-tree-sha1 = "fea870727142270bdf7624ad675901a1ee3b4c87"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.7.1"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "c5391c6ace3bc430ca630251d02ea9687169ca68"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.2"

[[deps.ShaderAbstractions]]
deps = ["ColorTypes", "FixedPointNumbers", "GeometryBasics", "LinearAlgebra", "Observables", "StaticArrays"]
git-tree-sha1 = "818554664a2e01fc3784becb2eb3a82326a604b6"
uuid = "65257c39-d410-5151-9873-9b3e5be5013e"
version = "0.5.0"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"
version = "1.11.0"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SignedDistanceFields]]
deps = ["Random", "Statistics", "Test"]
git-tree-sha1 = "d263a08ec505853a5ff1c1ebde2070419e3f28e9"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.0"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "2da10356e31327c7096832eb9cd86307a50b1eb6"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.11.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "41852b8679f78c8d8961eeadc8f62cef861a52e3"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.5.1"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.StableRNGs]]
deps = ["Random"]
git-tree-sha1 = "83e6cce8324d49dfaf9ef059227f91ed4441a8e5"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.2"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "0feb6b9031bd5c51f9072393eb5ab3efd31bf9e4"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.13"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

[[deps.Statistics]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "ae3bb1eb3bba077cd276bc5cfc337cc65c3075c0"
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.11.1"
weakdeps = ["SparseArrays"]

    [deps.Statistics.extensions]
    SparseArraysExt = ["SparseArrays"]

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "b81c5035922cc89c2d9523afc6c54be512411466"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.5"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "8e45cecc66f3b42633b8ce14d431e8e57a3e242e"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.5.0"
weakdeps = ["ChainRulesCore", "InverseFunctions"]

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

[[deps.StructArrays]]
deps = ["ConstructionBase", "DataAPI", "Tables"]
git-tree-sha1 = "8ad2e38cbb812e29348719cc63580ec1dfeb9de4"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.7.1"

    [deps.StructArrays.extensions]
    StructArraysAdaptExt = "Adapt"
    StructArraysGPUArraysCoreExt = ["GPUArraysCore", "KernelAbstractions"]
    StructArraysLinearAlgebraExt = "LinearAlgebra"
    StructArraysSparseArraysExt = "SparseArrays"
    StructArraysStaticArraysExt = "StaticArrays"

    [deps.StructArrays.weakdeps]
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    KernelAbstractions = "63c18a36-062a-441e-b654-da1e3ab1ce7c"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.StyledStrings]]
uuid = "f489334b-da3d-4c2e-b8f0-e476e12c162b"
version = "1.11.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.7.0+0"

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
git-tree-sha1 = "598cd7c1f68d1e205689b1c2fe65a9f85846f297"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "SIMD", "UUIDs"]
git-tree-sha1 = "f21231b166166bebc73b99cea236071eb047525b"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.11.3"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

[[deps.TriplotBase]]
git-tree-sha1 = "4d4ed7f294cda19382ff7de4c137d24d16adc89b"
uuid = "981d1d27-644d-49a2-9326-4793e63143c3"
version = "0.1.0"

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

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "c0667a8e676c53d390a09dc6870b3d8d6650e2bf"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.22.0"
weakdeps = ["ConstructionBase", "InverseFunctions"]

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    InverseFunctionsUnitfulExt = "InverseFunctions"

[[deps.WebP]]
deps = ["CEnum", "ColorTypes", "FileIO", "FixedPointNumbers", "ImageCore", "libwebp_jll"]
git-tree-sha1 = "aa1ca3c47f119fbdae8770c29820e5e6119b83f2"
uuid = "e3aaa7dc-3e4b-44e0-be63-ffb868ccd7c1"
version = "0.1.3"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c1a7aa6219628fcd757dede0ca95e245c5cd9511"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "1.0.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "b8b243e47228b4a3877f1dd6aee0c5d56db7fcf4"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.6+1"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fee71455b0aaa3440dfdd54a9a36ccef829be7d4"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.8.1+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "b5899b25d17bf1889d25906fb9deed5da0c15b3b"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.12+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "aa1261ebbac3ccc8d16558ae6799524c450ed16b"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.13+0"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "52858d64353db33a56e13c341d7bf44cd0d7b309"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.6+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "a4c0ee07ad36bf8bbce1c3bb52d21fb1e0b987fb"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.7+0"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "7ed9347888fac59a618302ee38216dd0379c480d"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.12+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libXau_jll", "Xorg_libXdmcp_jll"]
git-tree-sha1 = "bfcaf7ec088eaba362093393fe11aa141fa15422"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.1+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a63799ff68005991f9d9491b6e95bd3478d783cb"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.6.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "446b23e73536f84e8037f5dce465e92275f6a308"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.7+1"

[[deps.isoband_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51b5eeb3f98367157a7a12a1fb0aa5328946c03c"
uuid = "9a68df92-36a6-505f-a73e-abb412b6bfb4"
version = "0.2.3+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "522c1df09d05a71785765d19c9524661234738e9"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.11.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e17c115d55c5fbb7e52ebedb427a0dca79d4484e"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.2+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a22cf860a7d27e4f3498a0fe0811a7957badb38"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.3+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "068dfe202b0a05b8332f1e8e6b4080684b9c7700"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.47+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "libpng_jll"]
git-tree-sha1 = "c1733e347283df07689d71d61e14be986e49e47a"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.5+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "490376214c4721cdaca654041f635213c6165cb3"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+2"

[[deps.libwebp_jll]]
deps = ["Artifacts", "Giflib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libglvnd_jll", "Libtiff_jll", "libpng_jll"]
git-tree-sha1 = "d2408cac540942921e7bd77272c32e58c33d8a77"
uuid = "c5f90fcd-3b7e-5836-afba-fc50a0988cb2"
version = "1.5.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.59.0+0"

[[deps.oneTBB_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d5a767a3bb77135a99e433afe0eb14cd7f6914c3"
uuid = "1317d2d5-d96f-522e-a858-c73665f53c3e"
version = "2022.0.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "14cc7083fc6dff3cc44f2bc435ee96d06ed79aa7"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "10164.0.1+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "dcc541bb19ed5b0ede95581fb2e41ecf179527d2"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.6.0+0"
"""

# ╔═╡ Cell order:
# ╠═5eeae36d-988a-4906-ac80-4de96b1969bd
# ╟─3a267f1f-1936-4cab-81cc-d42d59169d26
# ╠═5c4c21e4-1a90-11f0-2f05-47d877772576
# ╟─668493d8-bf95-4561-9a3a-2e7f7a987682
# ╟─0c125359-6dcf-49af-887d-e24dbd11ef48
# ╠═280d83db-080d-4b22-8fc0-a175c8690b4a
# ╟─38b821ed-91a9-414e-9575-eb43e8068956
# ╟─9a0fe51f-b1df-46e7-8577-02d8cb4136f5
# ╟─779370fe-7513-4f4e-8517-d3328337ac42
# ╠═866b8869-47ec-4040-a7ef-a0831370b277
# ╠═cf7662c3-6ad6-4cc8-b73b-42b1bb738f37
# ╠═47da91d3-8a69-4aa5-a49f-55f9c4f585f9
# ╟─e5193d1e-8613-4cc4-80a0-a08597c720a5
# ╟─ddbbc711-bd5b-4d20-962b-7d103e0f31b4
# ╠═ecf84d2e-46f6-4dd1-a5de-a5f65b1d281f
# ╠═7a5bccfa-fce1-4bd8-8531-048ecb1c6a21
# ╟─3c4079a7-a627-464a-9309-f0f5320d368b
# ╟─4b079423-6c68-4ea0-a51d-b2b3bbfbb0f6
# ╟─a4e57d7a-7232-4189-85ff-8a25a3cb82da
# ╟─74c8acf3-0c7b-4555-a795-0c712546d5b4
# ╟─e86b88d2-baa7-4d41-9539-fb298ba5c123
# ╟─b2cdecef-d2d5-4514-a6cd-d3d453ed9099
# ╟─608b15d4-9ab3-405d-b574-167788f0c842
# ╠═834f9474-8f11-4bda-818e-ed3dd505f444
# ╠═f73540da-cf91-4463-9adf-b0e5b98e7b79
# ╟─3950039e-5d9d-4a00-b511-3f0a583d8309
# ╠═14db561f-54c3-41d4-8078-531facb65038
# ╠═367385c4-65b0-4a4a-aaf1-2cfcd8015b20
# ╟─b75017e8-bcfd-42fd-8870-9777c2f230e3
# ╟─a7f02fa7-8dac-424e-92d9-cc0f8ed85b93
# ╠═6a63cae0-fcd7-4258-a82f-3f752b37225c
# ╟─5429e788-a5ed-434b-a140-379f73b5cfc5
# ╟─583d4563-ac91-43f0-8cb1-2b598974edc7
# ╟─f918e5a2-d1b4-4c7d-93fa-a50dcd0d8fa5
# ╟─63a62a52-d138-4fae-9c1f-c7dbebb94f45
# ╠═eea941bf-0be0-4002-a07e-4ee5d95645dd
# ╠═a037e8aa-1b41-4146-814f-af3c6ff38be4
# ╠═5acc8ada-625a-4a8b-a790-a2b57a4ed189
# ╠═492d49ba-94aa-4c30-894b-4e59ed98402a
# ╠═4fbd8caf-04a5-46f0-8c73-a2db450bd172
# ╟─2d1d9e00-f022-4aa1-a64a-9331833f327d
# ╠═424db547-b82b-45ae-a8ac-044de1ed6a0c
# ╟─400c2d07-00f1-404f-b360-572671c467b5
# ╟─799fd006-6e40-47cd-98c6-62222e8c74eb
# ╟─051b752d-b0aa-4e05-bfc4-5d671e17e6c8
# ╟─3150ee27-4907-4a83-9969-b1ed75bf6378
# ╟─518443a4-47d6-4009-bc1b-6272b46a168a
# ╟─89d5bd8a-a9e4-4a1a-9e71-206db516a50f
# ╠═7122f82d-32b8-46c3-9299-6f7e31b7fd55
# ╟─ac9403df-12f2-436f-bfbd-553e9de1ab2e
# ╠═bc07318f-abb3-4791-9044-3609c05aebb3
# ╟─611ecf77-940d-4c1f-92e3-4249c2d720ef
# ╠═27220cbf-40ee-4e00-882c-d3a16f048cb0
# ╠═2993b2be-69d1-4d35-81af-73fcd33e1465
# ╟─5e99b4d7-5c7a-473a-aace-6e0ea16ec1bf
# ╠═4e610480-f0d1-420d-a273-08ee98a5438c
# ╠═96c8d882-2970-4497-8638-19c7d34ab492
# ╠═44cc65e6-f622-4601-8f4f-c31b89ce00fe
# ╠═68d42e2d-10cd-474d-a8c8-681f13bb027c
# ╟─082e9259-8e64-4ffa-8ed7-5c9bdbad0a0c
# ╠═b4214f5e-e675-46cb-89aa-1a51b49c141c
# ╟─803c58be-95da-4bba-940e-9a69a16ad6e5
# ╠═2fa6bd76-7539-4857-9829-6212689c1d3a
# ╟─8b9cd1a8-f33d-4ca2-9b4a-6f7684a52b7f
# ╠═98a72e2a-7c21-4a31-8c1e-21f4efa7e4ee
# ╠═19c0f6ea-3128-45ce-a198-644f4be7d9f0
# ╠═0bd274cb-e359-4a18-ae75-bb91ae101391
# ╠═ae46c18f-3e2e-4f92-8a96-ed786215b51f
# ╠═ce102254-9c7b-48b4-aee2-3acc16bb31ba
# ╠═05629dd9-7777-46c8-9851-5b39ce2829df
# ╠═4006fed7-9a7d-4eee-bb75-ed7b5472d6d1
# ╠═f0ed7963-e935-41cc-9820-94db0c3cd042
# ╟─20873272-f1a1-472d-bf05-c96e2f948f02
# ╠═71ec1afe-a7c7-41c8-a05b-32287658c2f5
# ╠═ebd73caf-5be3-4b75-a240-031d4a3aa64b
# ╠═67182362-cf07-463f-9583-00451633bd93
# ╟─67f88aac-14e4-423c-9a7b-35275a01a309
# ╠═10553f26-b660-4889-b0a7-71d68dbc105c
# ╠═42af19cc-c2b9-4736-9d07-8376c8b6cf09
# ╠═81a8a7b4-47dc-4e20-a26f-adf6f36d12d9
# ╠═89be32ff-786e-4794-9aa7-9246dc488a8c
# ╠═65dd6dd4-db1d-4e6d-b29c-9dd759567af5
# ╠═a42cc7a3-5e79-4cc9-afce-38e1db38d485
# ╠═34d68aa2-42de-480c-8e1b-ce7dfdd1e538
# ╠═027dcf07-5dbf-4bfe-bab3-9e8ad3279e3a
# ╠═d0ebe0d0-c370-4a9d-ace8-1146da614fda
# ╟─18901d86-b709-4f71-a439-237c7cb06ce9
# ╠═0bb66e77-09a6-43ff-ae28-8085eb03e8d7
# ╠═5fcf2dbf-7efe-4581-a347-0769c9638a0b
# ╟─3dd5c095-1a23-45b3-bdb2-a487b2c4004c
# ╠═f2d0825f-d27d-4869-bb6e-6a88eade3345
# ╠═d3018536-1f68-430f-a71d-89754b2dd620
# ╟─51a97752-ac9b-441a-a654-65a82ec6057c
# ╠═708757e8-f115-42d4-a100-9a132d91cd0f
# ╠═1fdcaee7-3f27-4d97-bace-1a022babaff9
# ╠═9faa9a57-4e7e-4145-a0d5-921f7809721d
# ╟─7317e24b-4461-4a6e-b580-94efd6cb12d4
# ╠═552d2403-41a8-4f56-938a-61e6ced75d85
# ╠═de74c171-b9e2-4a7e-9550-124508e0dfaa
# ╠═ff552723-12ba-4b9f-92ab-d5ade47b8203
# ╠═2e0c073d-0ad9-4e31-b791-27ac747a8f40
# ╟─69e2683a-caf4-48b0-a71a-b73f24bdab83
# ╠═6f903e30-2c85-4ae1-a4cc-591934f1e012
# ╠═ad924e1f-ef4c-433e-a259-120c9ef0c2d9
# ╟─12186fb3-a520-446b-aaf0-6a8e131ac508
# ╟─55c17860-f5d9-4fda-ad3e-b16b075af06c
# ╟─74bf8e0b-5018-422d-8536-a5a03053acd0
# ╠═dda152e7-a72a-4d71-b01d-c04f5b46de3a
# ╠═432f3155-d4ff-4a92-bf2b-a28cb055f54f
# ╠═747957c4-9908-42d7-a8a1-a94712019912
# ╠═bf2c3298-ded1-40ad-8dc6-5cf6b03029db
# ╠═1835ca94-0c73-4dfd-bf7b-c227bf9a7375
# ╠═5770d63e-a957-4044-b60d-4d91c6760288
# ╠═385a9c94-d180-4e85-8255-fa8970d8153e
# ╠═5efd9e58-8677-4b22-af70-492a2beca00a
# ╟─8d45c6b6-b0fd-42d2-b265-d90a23b42eac
# ╠═ee7cc11a-f127-425a-89a9-dfd31cae7e3e
# ╠═25a37065-a181-431d-a973-b0a07701f564
# ╠═8223c585-24b7-4938-a1fb-08749e8909e0
# ╟─4649dadd-75bb-4ca9-a65a-281f05dfce44
# ╠═f9ad118c-65c2-439a-9254-9d025245aa98
# ╠═b4dcb6d9-99a4-43da-bd3e-8af749c48290
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
