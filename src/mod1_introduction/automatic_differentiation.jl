### A Pluto.jl notebook ###
# v1.0.1

#> [frontmatter]
#> chapter = "1"
#> section = "4"
#> order = "4"
#> title = "Automatic Differentiation"
#> date = "2026-05-06"
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

# ╔═╡ 3a267f1f-1936-4cab-81cc-d42d59169d26
ChooseDisplayMode()

# ╔═╡ 5c4c21e4-1a90-11f0-2f05-47d877772576
begin
	using CairoMakie
	set_theme!(theme_latexfonts();
			   fontsize = 16,
			   Lines = (linewidth = 2,),
			   markersize = 16)
end

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

# ╔═╡ 280d83db-080d-4b22-8fc0-a175c8690b4a
f(x) = x^2 - 5 * sin(x) - 10 # you can change this function!

# ╔═╡ 38b821ed-91a9-414e-9575-eb43e8068956
@bind x̂ Slider(-5:0.2:5, default=-1.5, show_value=true)

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

# ╔═╡ 779370fe-7513-4f4e-8517-d3328337ac42
md"""
## Partial derivatives

For a multi-variable function like `f(x, y)` we define $\frac{\partial}{\partial x}f$ as the rate of change in the $x$ direction, and likewise $\frac{\partial}{\partial y}f$ as the rate of change in the $y$ direction.
"""

# ╔═╡ 866b8869-47ec-4040-a7ef-a0831370b277
f2(x, y) = x^2 - y^3 - 5 * sin(x) + 5 * cos(y * x) - 20 # you can change this function!

# ╔═╡ cf7662c3-6ad6-4cc8-b73b-42b1bb738f37
@bind x̂₁ Slider(-5:0.2:5, default=-1.5, show_value=true)

# ╔═╡ 47da91d3-8a69-4aa5-a49f-55f9c4f585f9
@bind ŷ₁ Slider(-5:0.2:5, default=-1.5, show_value=true)

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

	lines!(ax3, ys, f_y′; label=L"Derivative $f_y′(y)$")

    # Plot 1st order Taylor series approximation
    taylor_approx(x, y) = f2(x̂₁, ŷ₁) + f_x′(x̂₁)*(x-x̂₁) + f_y′(ŷ₁)*(y-ŷ₁) 
    surface!(ax4, xs, ys, taylor_approx; label=L"Taylor approx. around $\tilde{x},\tilde{y}$")

	fig
end

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

# ╔═╡ ecf84d2e-46f6-4dd1-a5de-a5f65b1d281f
function m(x, a, b, c, d)
	return sin(a*x)*b + cos(c*x)*d
end

# ╔═╡ 7a5bccfa-fce1-4bd8-8531-048ecb1c6a21
xs = 0.0:0.01:2π

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

# ╔═╡ 74c8acf3-0c7b-4555-a795-0c712546d5b4
question_box(
md"""
Given an "observed" evaluation of `m` can we "learn" the values of `a`, `b`, `c`, `d`?
"""
)

# ╔═╡ e86b88d2-baa7-4d41-9539-fb298ba5c123
ys = m.(xs, 0.3, -1.2, 0.5, 0.7)

# ╔═╡ b2cdecef-d2d5-4514-a6cd-d3d453ed9099
lines(xs, ys)

# ╔═╡ 608b15d4-9ab3-405d-b574-167788f0c842
md"""
We could try some random values!
"""

# ╔═╡ 834f9474-8f11-4bda-818e-ed3dd505f444
coeffs_guess = rand(-2.0:0.1:2.0, 4)

# ╔═╡ f73540da-cf91-4463-9adf-b0e5b98e7b79
ys_guess = m.(xs, coeffs_guess...)

# ╔═╡ 3950039e-5d9d-4a00-b511-3f0a583d8309
md"""
We need to define a "loss" a function that measures how far away we are from our solution. The Mean-Squared-Error is a common choice.
"""

# ╔═╡ 14db561f-54c3-41d4-8078-531facb65038
# Mean squared error
function mse(ŷ, y)
	sum((ŷ .- y).^2) / length(y)
end

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

# ╔═╡ a7f02fa7-8dac-424e-92d9-cc0f8ed85b93
md"""
So how do we improve our guess systematically?
"""

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

# ╔═╡ eea941bf-0be0-4002-a07e-4ee5d95645dd
nextfloat(1.0) - 1.0

# ╔═╡ a037e8aa-1b41-4146-814f-af3c6ff38be4
eps(1.0)

# ╔═╡ 5acc8ada-625a-4a8b-a790-a2b57a4ed189
eps(1.0f0)

# ╔═╡ 492d49ba-94aa-4c30-894b-4e59ed98402a
(nextfloat(1.234e5) - 1.234e5)

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

# ╔═╡ 424db547-b82b-45ae-a8ac-044de1ed6a0c
using DoubleFloats

# ╔═╡ 400c2d07-00f1-404f-b360-572671c467b5
@bind f_diff Select([
	sin => "f(x) = sin(x)",
	cos => "f(x) = cos(x)",
	exp => "f(x) = exp(x)",
	(x -> sin(100 * x)) => "f(x) = sin(100 x)",
	(x -> sin(x / 100)) => "f(x) = sin(x / 100)",
])

# ╔═╡ 799fd006-6e40-47cd-98c6-62222e8c74eb
@bind FloatType Select([Float32, Float64, Double64]; default = Float64)

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

# ╔═╡ 3150ee27-4907-4a83-9969-b1ed75bf6378
md"""
Next, we use the central difference

$$\frac{f(x + h) - f(x - h)}{2 h} \approx f'(x).$$
"""

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


# ╔═╡ 89d5bd8a-a9e4-4a1a-9e71-206db516a50f
md"""
## Forward-mode AD for scalars

There is a well-know proverb

> Differentiation is mechanics, integration is art

Luckily, we are just interested in differentiation for now. Thus, all we need to do
is to implement the basic rules of calculus like the product rule and the chain rule.
Before doing that, let's consider an example.
"""

# ╔═╡ 7122f82d-32b8-46c3-9299-6f7e31b7fd55
g(x) = log(x^2 + exp(sin(x)))

# ╔═╡ ac9403df-12f2-436f-bfbd-553e9de1ab2e
md"""We can compute the derivative by hand using the chain rule."""

# ╔═╡ bc07318f-abb3-4791-9044-3609c05aebb3
g′(x) = 1 / (x^2 + exp(sin(x))) * (2 * x + exp(sin(x)) * cos(x))

# ╔═╡ 611ecf77-940d-4c1f-92e3-4249c2d720ef
md"We can think of the function as a kind of *computational graph* obtained by dividing it into steps."

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

# ╔═╡ 5e99b4d7-5c7a-473a-aace-6e0ea16ec1bf
md"To compute the derivative, we have to apply the chain rule multiple times."

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

# ╔═╡ 44cc65e6-f622-4601-8f4f-c31b89ce00fe
(g(1.0), g′(1.0))

# ╔═╡ 68d42e2d-10cd-474d-a8c8-681f13bb027c
let x = 1.0, h = sqrt(eps())
	(g(x + h) - g(x)) / h
end

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

# ╔═╡ ae46c18f-3e2e-4f92-8a96-ed786215b51f
Dual(1, 2) - Dual(2.0, 3)

# ╔═╡ ce102254-9c7b-48b4-aee2-3acc16bb31ba
Base.:*(x::Dual, y::Dual) = Dual(x.value * y.value,
								 x.value * y.deriv + x.deriv * y.value)

# ╔═╡ 05629dd9-7777-46c8-9851-5b39ce2829df
Dual(1, 2) * Dual(2.0, 3)

# ╔═╡ 4006fed7-9a7d-4eee-bb75-ed7b5472d6d1
Base.:/(x::Dual, y::Dual) = Dual(x.value / y.value,
								 (x.deriv * y.value - x.value * y.deriv) / y.value^2)

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

# ╔═╡ aabbccdd-1111-4000-8000-000000000001
warning_box(md"""
**Type-generic allocations**

The promote rules propagate `Dual` numbers through arithmetic — but only if every array you allocate can *hold* them. A common pitfall is `zeros(n)` or `zeros(Float64, m, n)`, which always creates a `Float64` array that rejects `Dual` values when you try to store `x` into it:

```julia
function bad(x)
    A = zeros(2, 2)   # always Matrix{Float64}
    A[1,1] = x        # MethodError: cannot convert Dual → Float64
    A
end
```

Write `zeros(typeof(x), m, n)` instead so the element type follows the input:

```julia
function good(x)
    A = zeros(typeof(x), 2, 2)
    A[1,1] = x
    A
end
```

You will encounter this pitfall directly in **Exercise 10, Part 2**.
""")

# ╔═╡ 67f88aac-14e4-423c-9a7b-35275a01a309
md"Next, we need to implement the well-know derivatives of special functions."

# ╔═╡ 10553f26-b660-4889-b0a7-71d68dbc105c
Base.sin(x::Dual) = Dual(sin(x.value), cos(x.value) * x.deriv)

# ╔═╡ 42af19cc-c2b9-4736-9d07-8376c8b6cf09
sin(Dual(π, 1.0))

# ╔═╡ 81a8a7b4-47dc-4e20-a26f-adf6f36d12d9
Base.cos(x::Dual) = Dual(cos(x.value), -sin(x.value) * x.deriv)

# ╔═╡ 89be32ff-786e-4794-9aa7-9246dc488a8c
cos(Dual(π, 1.0))

# ╔═╡ 65dd6dd4-db1d-4e6d-b29c-9dd759567af5
Base.log(x::Dual) = Dual(log(x.value), x.deriv / x.value)

# ╔═╡ a42cc7a3-5e79-4cc9-afce-38e1db38d485
log(Dual(1.0, 1))

# ╔═╡ 34d68aa2-42de-480c-8e1b-ce7dfdd1e538
Base.exp(x::Dual) = Dual(exp(x.value), exp(x.value) * x.deriv)

# ╔═╡ 027dcf07-5dbf-4bfe-bab3-9e8ad3279e3a
exp(Dual(1.0, 1))

# ╔═╡ d0ebe0d0-c370-4a9d-ace8-1146da614fda
Base.abs(x::Dual) = Dual(abs(x.value), sign(x.value) * x.deriv)

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

# ╔═╡ 708757e8-f115-42d4-a100-9a132d91cd0f
using BenchmarkTools

# ╔═╡ 1fdcaee7-3f27-4d97-bace-1a022babaff9
@benchmark g_graph_derivative($(Ref(1.0))[])

# ╔═╡ 9faa9a57-4e7e-4145-a0d5-921f7809721d
@benchmark g(Dual($(Ref(1.0))[], 1.0))

# ╔═╡ 7317e24b-4461-4a6e-b580-94efd6cb12d4
md"Now, we have a versatile tool to compute derivatives of functions depending on a single variable."

# ╔═╡ 552d2403-41a8-4f56-938a-61e6ced75d85
derivative(f, x::Real) = f(Dual(x, one(x))).deriv

# ╔═╡ de74c171-b9e2-4a7e-9550-124508e0dfaa
derivative(g, 1.0)

# ╔═╡ ff552723-12ba-4b9f-92ab-d5ade47b8203
derivative(x -> 3 * x^2 + 4 * x + 5, 2)

# ╔═╡ 2e0c073d-0ad9-4e31-b791-27ac747a8f40
derivative(3) do x
	sin(x) * log(x)
end

# ╔═╡ 69e2683a-caf4-48b0-a71a-b73f24bdab83
md"We can also get the derivative as a function itself."

# ╔═╡ 6f903e30-2c85-4ae1-a4cc-591934f1e012
derivative(f) = x -> derivative(f, x)

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

# ╔═╡ aabbccdd-1111-4000-8000-000000000010
using ForwardDiff

# ╔═╡ aabbccdd-1111-4000-8000-000000000011
md"""
## From hand-rolled to ForwardDiff.jl

Our custom `derivative(f, x)` works for scalar functions. For production code,
use **ForwardDiff.jl** which provides:

| Function                       | Input      | Returns           |
|--------------------------------|------------|-------------------|
| `ForwardDiff.derivative(f, x)` | scalar `x` | scalar `f′(x)`    |
| `ForwardDiff.gradient(f, x)`   | vector `x` | vector `∇f(x)`    |

The key distinction: `gradient` differentiates a *scalar-valued* function w.r.t.
a **vector** argument and returns a vector of partial derivatives.
"""

# ╔═╡ aabbccdd-1111-4000-8000-000000000012
# Our hand-rolled derivative vs ForwardDiff.derivative — same result
(derivative(g, 1.0), ForwardDiff.derivative(g, 1.0))

# ╔═╡ aabbccdd-1111-4000-8000-000000000013
# ForwardDiff.gradient: differentiate w.r.t. a *vector* of parameters
let
	loss(c) = mse(ys, m.(xs, c...))
	ForwardDiff.gradient(loss, [coeffs_guess...])
end

# ╔═╡ aabbccdd-1111-4000-8000-000000000014
tip(md"""
Compare the result above to our manual `dm(mse, ys, xs, coeffs_guess)` — they
should match! But `ForwardDiff.gradient` handles all the one-hot seeding
internally and is heavily optimised.

You will use `ForwardDiff.gradient` directly in **Exercises 9 and 11**.
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
dm(mse, ys, xs, [coeffs_guess...])

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

# ╔═╡ aabbccdd-1111-4000-8000-000000000020
tip(md"""
**Coming up in Exercise 9: `Optim.jl`**

Instead of writing a gradient-descent loop by hand, you can use `Optim.jl`:

```julia
using Optim

f(c) = mse(ys, m.(xs, c...))   # objective: Vector → scalar

function g!(dc, c)              # in-place gradient: writes ∇f into dc
    dc .= ForwardDiff.gradient(f, c)
end

sol = optimize(f, g!, c₀)      # c₀ is the initial guess
Optim.minimizer(sol)            # optimal parameters
```

The `g!(dc, c)` convention means Optim passes you a pre-allocated vector `dc`
and expects you to *fill it* with the gradient — it avoids allocations on every
iteration.
""")

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
DoubleFloats = "497a8b3b-efae-58df-a0af-a86822472b78"
ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
BenchmarkTools = "~1.8.0"
CairoMakie = "~0.15.11"
DoubleFloats = "~1.9.1"
ForwardDiff = "~1.4.1"
PlutoTeachingTools = "~0.4.7"
PlutoUI = "~0.7.83"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "5c7db5a46c6bfd18cfcf712b993a1f8889dcb1ee"

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
git-tree-sha1 = "6c3913f4e9bdf6ba3c08041a446fb1332716cbc2"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.4.0"

[[deps.AbstractTrees]]
git-tree-sha1 = "2d9c9a55f9c93e8887ad391fbae72f8ef55e1177"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.4.5"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "7715e5b2b186c4d9b664d299d2c9e48b9a778c88"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.6.1"
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
deps = ["PrecompileTools", "TranscodingStreams"]
git-tree-sha1 = "94eab0b3ccdcac361188cc661daf69d4433c1818"
uuid = "67c07d97-cdcb-5c2c-af73-a7f9c32a568b"
version = "1.2.0"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "01b8ccb13d68535d73d2b0c23e39bd23155fb712"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.1.0"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "4126b08903b777c88edf1754288144a0492c05ad"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.8"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"
version = "1.11.0"

[[deps.BaseDirs]]
git-tree-sha1 = "bca794632b8a9bbe159d56bf9e31c422671b35e0"
uuid = "18cc8868-cbac-4acf-b575-c8ff214dc66f"
version = "1.3.2"

[[deps.BenchmarkTools]]
deps = ["Compat", "JSON", "Logging", "PrecompileTools", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "9670d3febc2b6da60a0ae57846ba74670290653f"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.8.0"

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
git-tree-sha1 = "1a063740329b7ee9ec602505c41cccb8500b637d"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.15.11"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "1fa950ebc3e37eccd51c6a8fe1f92f7d86263522"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.7+0"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "12177ad6b3cad7fd50c8b3825ce24a99ad61c18f"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.26.1"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.CodecZstd]]
deps = ["TranscodingStreams", "Zstd_jll"]
git-tree-sha1 = "da54a6cd93c54950c15adf1d336cfd7d71f51a56"
uuid = "6b39b394-51ab-5f42-8807-6242bab2b4c2"
version = "0.8.7"

[[deps.ColorBrewer]]
deps = ["Colors", "JSON"]
git-tree-sha1 = "07da79661b919001e6863b81fc572497daa58349"
uuid = "a2cac450-b92f-5266-8821-25eda20663c8"
version = "0.4.2"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "b0fd3f56fa442f81e0a47815c92245acfaaa4e34"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.31.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "8b3b6f87ce8f65a2b4f857528fd8d70086cd72b1"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.11.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "37ea44092930b1811e666c3bc38065d7d87fcc74"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.13.1"

[[deps.CommonSubexpressions]]
deps = ["MacroTools"]
git-tree-sha1 = "cda2cfaebb4be89c9084adaca7dd7333369715c5"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.1"

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

[[deps.ComputePipeline]]
deps = ["Observables", "Preferences"]
git-tree-sha1 = "7bc84b769c1d384315e7b5c4ac03a6c303e6cf35"
uuid = "95dc2771-c249-4cd0-9c9f-1f3b4330693c"
version = "0.1.8"

[[deps.ConstructionBase]]
git-tree-sha1 = "b4b092499347b18a015186eae3042f72267106cb"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.6.0"
weakdeps = ["IntervalSets", "LinearAlgebra", "StaticArrays"]

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

[[deps.Contour]]
git-tree-sha1 = "439e35b0b36e2e5881738abc8857bd92ad6ff9a8"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.3"

[[deps.CoreMath]]
deps = ["CoreMath_jll"]
git-tree-sha1 = "8c0480f92b1b1796239156a1b9b1bfb1b39499b4"
uuid = "b7a15901-be09-4a0e-87d2-2e66b0e09b5a"
version = "0.1.0"

[[deps.CoreMath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a692a4c1dc59a4b8bc0b6403876eb3250fde2bc3"
uuid = "a38c48d9-6df1-5ac9-9223-b6ada3b5572b"
version = "0.1.0+0"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataStructures]]
deps = ["OrderedCollections"]
git-tree-sha1 = "6fb53a69613a0b2b68a0d12671717d307ab8b24e"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.19.5"

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
git-tree-sha1 = "c55f5a9fd67bdbc8e089b5a3111fe4292986a8e8"
uuid = "927a84f5-c5f4-47a5-9785-b46e178433df"
version = "1.6.6"

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

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.Distributions]]
deps = ["AliasTables", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "96f76dcd6cc75cf8eb49109123868499d413f526"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.126"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"
    DistributionsTestExt = "Test"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
    Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.DoubleFloats]]
deps = ["GenericLinearAlgebra", "LinearAlgebra", "Printf", "Quadmath", "Random", "SpecialFunctions"]
git-tree-sha1 = "341267a7b8db517bef61e704a46f02f2672b3a15"
uuid = "497a8b3b-efae-58df-a0af-a86822472b78"
version = "1.9.1"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.7.0"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.EnumX]]
git-tree-sha1 = "c49898e8438c828577f04b92fc9368c388ac783c"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.7"

[[deps.ExactPredicates]]
deps = ["IntervalArithmetic", "Random", "StaticArrays"]
git-tree-sha1 = "83231673ea4d3d6008ac74dc5079e77ab2209d8f"
uuid = "429591f6-91af-11e9-00e2-59fbe8cec110"
version = "2.2.9"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c307cd83373868391f3ac30b41530bc5d5d05d08"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.8.1+0"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libva_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "cac41ca6b2d399adfc95e51240566f8a60a80806"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "8.1.0+0"

[[deps.FFTA]]
deps = ["AbstractFFTs", "DocStringExtensions", "LinearAlgebra", "MuladdMacro", "Primes", "Random", "Reexport"]
git-tree-sha1 = "65e55303b72f4a567a51b174dd2c47496efeb95a"
uuid = "b86e33f2-c0db-4aa1-a6e0-ab43e668529e"
version = "0.3.1"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "8e9c059d6857607253e837730dbf780b6b151acd"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.19.0"

    [deps.FileIO.extensions]
    HTTPExt = "HTTP"

    [deps.FileIO.weakdeps]
    HTTP = "cd3eb016-35fb-5094-929b-558a96fad6f3"

[[deps.FilePaths]]
deps = ["FilePathsBase", "MacroTools", "Reexport"]
git-tree-sha1 = "a1b2fbfe98503f15b665ed45b3d149e5d8895e4c"
uuid = "8fc22ac5-c921-52a6-82fd-178b2807b824"
version = "0.9.0"

    [deps.FilePaths.extensions]
    FilePathsGlobExt = "Glob"
    FilePathsURIParserExt = "URIParser"
    FilePathsURIsExt = "URIs"

    [deps.FilePaths.weakdeps]
    Glob = "c27321d9-0574-5035-807b-f59d2c89b15c"
    URIParser = "30578b45-9adc-5946-b283-645ec420af67"
    URIs = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"

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
git-tree-sha1 = "2f979084d1e13948a3352cf64a25df6bd3b4dca3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.16.0"
weakdeps = ["PDMats", "SparseArrays", "StaticArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStaticArraysExt = "StaticArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FixedPointNumbers]]
deps = ["Random", "Statistics"]
git-tree-sha1 = "59af96b98217c6ef4ae0dfe065ac7c20831d1a84"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.6"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "f85dac9a96a01087df6e3a749840015a0ca3817d"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.17.1+0"

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "2c5d0b0e12088cde2cf84afb2784415b1ea3dfee"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "1.4.1"
weakdeps = ["StaticArrays"]

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

[[deps.FreeType]]
deps = ["CEnum", "FreeType2_jll"]
git-tree-sha1 = "907369da0f8e80728ab49c1c7e09327bf0d6d999"
uuid = "b38be410-82b0-50bf-ab77-7b57e271db43"
version = "4.1.1"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "70329abc09b886fd2c5d94ad2d9527639c421e3e"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.14.3+1"

[[deps.FreeTypeAbstraction]]
deps = ["BaseDirs", "ColorVectorSpace", "Colors", "FreeType", "GeometryBasics", "Mmap"]
git-tree-sha1 = "4ebb930ef4a43817991ba35db6317a05e59abd11"
uuid = "663a7486-cb36-511b-a19d-713bb74d65c9"
version = "0.10.8"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "7a214fdac5ed5f59a22c2d9a885a16da1c74bbc7"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.17+0"

[[deps.GenericLinearAlgebra]]
deps = ["LinearAlgebra", "Printf", "Random", "libblastrampoline_jll"]
git-tree-sha1 = "6a0335feebe8e2b61242f2b4ec165c1b70b83f8a"
uuid = "14197337-ba66-59df-a3e3-ca00e7dcff7a"
version = "0.4.0"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "LinearAlgebra", "PrecompileTools", "Random", "StaticArrays"]
git-tree-sha1 = "364685f5ffde25deb1bbcfd5bb278a5c6b7a9b37"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.5.11"

    [deps.GeometryBasics.extensions]
    ExtentsExt = "Extents"
    GeometryBasicsGeoInterfaceExt = "GeoInterface"
    IntervalSetsExt = "IntervalSets"

    [deps.GeometryBasics.weakdeps]
    Extents = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
    GeoInterface = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"

[[deps.GettextRuntime_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll"]
git-tree-sha1 = "45288942190db7c5f760f59c04495064eedf9340"
uuid = "b0724c58-0f36-5564-988d-3bb0596ebc4a"
version = "0.22.4+0"

[[deps.Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Zlib_jll"]
git-tree-sha1 = "38044a04637976140074d0b0621c1edf0eb531fd"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.1+0"

[[deps.Giflib_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6570366d757b50fabae9f4315ad74d2e40c0560a"
uuid = "59f7168a-df46-5410-90c8-f2779963d0ec"
version = "5.2.3+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "GettextRuntime_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "24f6def62397474a297bfcec22384101609142ed"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.86.3+0"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "a641238db938fff9b2f60d08ed9030387daf428c"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.3"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "69ffb934a5c5b7e086a0b4fee3427db2556fba6e"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.16+0"

[[deps.GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Observables"]
git-tree-sha1 = "93d5c27c8de51687a2c70ec0716e6e76f298416f"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.11.2"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "f923f9a774fcf3f5cb761bfa43aeadd689714813"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.5.1+0"

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
git-tree-sha1 = "d1a86724f81bcd184a38fd284ce183ec067d71a0"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "1.0.0"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "0ee181ec08df7d7c911901ea38baf16f755114dc"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "1.0.0"

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
git-tree-sha1 = "dcc8d0cd653e55213df9b75ebc6fe4a8d3254c65"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.2.2+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "d1b1b796e47d94588b3757fe84fbf65a5ec4a80d"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.5"

[[deps.IntegerMathUtils]]
git-tree-sha1 = "4c1acff2dc6b6967e7e750633c50bc3b8d83e617"
uuid = "18e54dd8-cb9d-406c-a71d-865a43cbb235"
version = "0.1.3"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "48922d06068130f87e43edef52382e6a94305ae6"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.16.3"
weakdeps = ["ForwardDiff", "Unitful"]

    [deps.Interpolations.extensions]
    InterpolationsForwardDiffExt = "ForwardDiff"
    InterpolationsUnitfulExt = "Unitful"

[[deps.IntervalArithmetic]]
deps = ["CRlibm", "CoreMath", "MacroTools", "OpenBLASConsistentFPCSR_jll", "Printf", "Random", "RoundingEmulator"]
git-tree-sha1 = "921d7e91687e15a2c7c269c226960491fc041832"
uuid = "d1acc4aa-44c8-5952-acd4-ba5d80a2a253"
version = "1.0.9"

    [deps.IntervalArithmetic.extensions]
    IntervalArithmeticArblibExt = "Arblib"
    IntervalArithmeticDiffRulesExt = "DiffRules"
    IntervalArithmeticForwardDiffExt = "ForwardDiff"
    IntervalArithmeticIntervalSetsExt = "IntervalSets"
    IntervalArithmeticIrrationalConstantsExt = "IrrationalConstants"
    IntervalArithmeticLinearAlgebraExt = "LinearAlgebra"
    IntervalArithmeticRecipesBaseExt = "RecipesBase"
    IntervalArithmeticSparseArraysExt = "SparseArrays"

    [deps.IntervalArithmetic.weakdeps]
    Arblib = "fb37089c-8514-4489-9461-98f9c8763369"
    DiffRules = "b552c78f-8df3-52c6-915a-8e097449b14b"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    IrrationalConstants = "92d709cd-6900-40b7-9082-c6be49f344b6"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.IntervalSets]]
git-tree-sha1 = "79d6bd28c8d9bccc2229784f1bd637689b256377"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.14"

    [deps.IntervalSets.extensions]
    IntervalSetsRandomExt = "Random"
    IntervalSetsRecipesBaseExt = "RecipesBase"
    IntervalSetsStatisticsExt = "Statistics"

    [deps.IntervalSets.weakdeps]
    Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
    RecipesBase = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.InverseFunctions]]
git-tree-sha1 = "a779299d77cd080bf77b97535acecd73e1c5e5cb"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.17"
weakdeps = ["Dates", "Test"]

    [deps.InverseFunctions.extensions]
    InverseFunctionsDatesExt = "Dates"
    InverseFunctionsTestExt = "Test"

[[deps.IrrationalConstants]]
git-tree-sha1 = "b2d91fe939cae05960e760110b328288867b5758"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.6"

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

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "9496de8fb52c224a2e3f9ff403947674517317d9"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.6"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c0c9b76f3520863909825cbecdef58cd63de705a"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.5+0"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTA", "Interpolations", "StatsBase"]
git-tree-sha1 = "9eda8292dd3268b3b7ec9df21bbfac24e177ec52"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.12"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "059aabebaa7c82ccb853dd4a0ee9d17796f7e1bc"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.3+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "17b94ecafcfa45e8360a4fc9ca6b583b049e4e37"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "4.1.0+0"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "eb62a3deb62fc6d8822c0c4bef73e4412419c5d8"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "18.1.8+0"

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

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

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

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c8da7e6a91781c41a863611c7e966098d783c57a"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.4.7+0"

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
git-tree-sha1 = "cc3ad4faf30015a3e8094c9b5b7f19e85bdf2386"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.42.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "f04133fe05eff1667d2054c53d59f9122383fe05"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.7.2+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d620582b1f0cbe2c72dd1d5bd195a9ce73370ab1"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.42.0+0"

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

[[deps.Makie]]
deps = ["Animations", "Base64", "CRC32c", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "ComputePipeline", "Contour", "Dates", "DelaunayTriangulation", "Distributions", "DocStringExtensions", "Downloads", "FFMPEG_jll", "FileIO", "FilePaths", "FixedPointNumbers", "Format", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageBase", "ImageIO", "InteractiveUtils", "Interpolations", "IntervalSets", "InverseFunctions", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MacroTools", "Markdown", "MathTeXEngine", "Observables", "OffsetArrays", "PNGFiles", "Packing", "Pkg", "PlotUtils", "PolygonOps", "PrecompileTools", "Printf", "REPL", "Random", "RelocatableFolders", "Scratch", "ShaderAbstractions", "SignedDistanceFields", "SparseArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "TriplotBase", "UnicodeFun", "Unitful"]
git-tree-sha1 = "1cdb9a8ca42229d1ff880ce85e9b31ef2291bce3"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.24.11"

    [deps.Makie.extensions]
    MakieDynamicQuantitiesExt = "DynamicQuantities"

    [deps.Makie.weakdeps]
    DynamicQuantities = "06fc5a27-2a28-4c7c-a15d-362465fb6821"

[[deps.MappedArrays]]
git-tree-sha1 = "0ee4497a4e80dbd29c058fcee6493f5219556f40"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.3"

[[deps.Markdown]]
deps = ["Base64", "JuliaSyntaxHighlighting", "StyledStrings"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MathTeXEngine]]
deps = ["AbstractTrees", "Automa", "DataStructures", "FreeTypeAbstraction", "GeometryBasics", "LaTeXStrings", "REPL", "RelocatableFolders", "UnicodeFun"]
git-tree-sha1 = "aa1078778be5a8e5259ff04fbc3d258b3e78d464"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.6.9"

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
version = "2025.11.4"

[[deps.MuladdMacro]]
git-tree-sha1 = "cac9cc5499c25554cba55cd3c30543cff5ca4fab"
uuid = "46d2c3a1-f734-5fdb-9937-b9b9aeba4221"
version = "0.2.4"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "dbd2e8cd2c1c27f0b584f6661b4309609c5a685e"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.4"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "d92b107dbb887293622df7697a2223f9f8176fcd"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.3.0"

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
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b6aa4566bb7ae78498a5e68943863fa8b5231b59"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.6+0"

[[deps.OpenBLASConsistentFPCSR_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "3287ec88df50429a934ebc6cf14606215e27b987"
uuid = "6cdc7f73-28fd-5e50-80fb-958a8875b1af"
version = "0.3.33+0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.29+0"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "97db9e07fe2091882c765380ef58ec553074e9c7"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.3"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "4a33fd64a77949468187339d8b10c44a422082f1"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.4.12+0"

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

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e2bb57a313a74b8104064b7efd01406c0a50d2ff"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.6.1+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "94ba93778373a53bfd5a0caaf7d809c445292ff4"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.2"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.44.0+1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "e4cff168707d441cd6bf3ff7e4832bdf34278e4a"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.37"
weakdeps = ["StatsBase"]

    [deps.PDMats.extensions]
    StatsBaseExt = "StatsBase"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "32b657a0d57c310a1a172bfc8c8cf68c5e674323"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.4.5"

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
git-tree-sha1 = "58e5ed5e386e156bd93e86b305ebd21ac63d2d04"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.57.1+0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "32a4e09c5f29402573d673901778a0e03b0807b9"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.6"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "e4a6721aa89e62e5d4217c0b21bd714263779dda"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.46.4+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.12.1"
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
git-tree-sha1 = "26ca162858917496748aad52bb5d3be4d26a228a"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.4"

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

[[deps.PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

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

[[deps.Primes]]
deps = ["IntegerMathUtils"]
git-tree-sha1 = "25cdd1d20cd005b52fc12cb6be3f75faaf59bb9b"
uuid = "27ebfcd6-29c5-5fa9-bf4b-fb8fc14df3ae"
version = "0.5.7"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
version = "1.11.0"

[[deps.Profile]]
deps = ["StyledStrings"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"
version = "1.11.0"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "fbb92c6c56b34e1a2c4c36058f68f332bec840e7"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.11.0"

[[deps.PtrArrays]]
git-tree-sha1 = "4fbbafbc6251b883f4d2705356f3641f3652a7fe"
uuid = "43287f4e-b6f4-7ad1-bb20-aadabca52c3d"
version = "1.4.0"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "472daaa816895cb7aee81658d4e7aec901fa1106"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.2"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "5e8e8b0ab68215d7a2b14b9921a946fee794749e"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.11.3"

    [deps.QuadGK.extensions]
    QuadGKEnzymeExt = "Enzyme"

    [deps.QuadGK.weakdeps]
    Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"

[[deps.Quadmath]]
deps = ["Compat", "Printf", "Random"]
git-tree-sha1 = "79cd6923b7e5fdb4130cdb0f6c0038d7f65a9717"
uuid = "be4d8f0f-7fa4-5f49-b795-2f01399ab2dd"
version = "1.0.1"
weakdeps = ["SpecialFunctions"]

    [deps.Quadmath.extensions]
    QuadmathSpecialFunctionsExt = ["SpecialFunctions"]

[[deps.REPL]]
deps = ["InteractiveUtils", "JuliaSyntaxHighlighting", "Markdown", "Sockets", "StyledStrings", "Unicode"]
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

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "5b3d50eb374cea306873b371d3f8d3915a018f0b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.9.0"

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
git-tree-sha1 = "e24dc23107d426a096d3eae6c165b921e74c18e4"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.7.2"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "9b81b8393e50b7d4e6d0a9f14e192294d3b7c109"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.3.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
version = "1.11.0"

[[deps.ShaderAbstractions]]
deps = ["ColorTypes", "FixedPointNumbers", "GeometryBasics", "LinearAlgebra", "Observables", "StaticArrays"]
git-tree-sha1 = "818554664a2e01fc3784becb2eb3a82326a604b6"
uuid = "65257c39-d410-5151-9873-9b3e5be5013e"
version = "0.5.0"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"
version = "1.11.0"

[[deps.SignedDistanceFields]]
deps = ["Statistics"]
git-tree-sha1 = "3949ad92e1c9d2ff0cd4a1317d5ecbba682f4b92"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.1"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "7ddb0b49c109481b046972c0e4ab02b2127d6a75"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.6"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "0494aed9501e7fb65daba895fb7fd57cc38bc743"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.5"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "64d974c2e6fdf07f8155b5b2ca2ffa9069b608d9"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.2"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.12.0"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "6547cbdd8ce32efba0d21c5a40fa96d1a3548f9f"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.8.0"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.StableRNGs]]
deps = ["Random"]
git-tree-sha1 = "4f96c596b8c8258cc7d3b19797854d368f243ddc"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.4"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "be1cf4eb0ac528d96f5115b4ed80c26a8d8ae621"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.2"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "246a8bb2e6667f832eea063c3a56aef96429a3db"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.18"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

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

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "178ed29fd5b2a2cfc3bd31c13375ae925623ff36"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.8.0"

[[deps.StatsBase]]
deps = ["AliasTables", "DataAPI", "DataStructures", "IrrationalConstants", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "e4d7a1a0edc20af42689ea6f4f3587a2175d50ee"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.12"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "91f091a8716a6bb38417a6e6f274602a19aaa685"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.5.2"
weakdeps = ["ChainRulesCore", "InverseFunctions"]

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

[[deps.StructArrays]]
deps = ["ConstructionBase", "DataAPI", "Tables"]
git-tree-sha1 = "ad8002667372439f2e3611cfd14097e03fa4bccd"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.7.3"

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

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.8.3+2"

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
deps = ["CodecZstd", "ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "PrecompileTools", "ProgressMeter", "SIMD", "UUIDs"]
git-tree-sha1 = "9ca5f1f2d42f80df4b8c9f6ab5a64f438bbd9976"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.11.9"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "311349fd1c93a31f783f977a71e8b062a57d4101"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.13"

[[deps.TriplotBase]]
git-tree-sha1 = "4d4ed7f294cda19382ff7de4c137d24d16adc89b"
uuid = "981d1d27-644d-49a2-9326-4793e63143c3"
version = "0.1.0"

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

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "57e1b2c9de4bd6f40ecb9de4ac1797b81970d008"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.28.0"
weakdeps = ["ConstructionBase", "ForwardDiff", "InverseFunctions", "LaTeXStrings", "Latexify", "NaNMath", "Printf"]

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    ForwardDiffExt = "ForwardDiff"
    InverseFunctionsUnitfulExt = "InverseFunctions"
    LatexifyExt = ["Latexify", "LaTeXStrings"]
    NaNMathExt = "NaNMath"
    PrintfExt = "Printf"

[[deps.WebP]]
deps = ["CEnum", "ColorTypes", "FileIO", "FixedPointNumbers", "ImageCore", "libwebp_jll"]
git-tree-sha1 = "aa1ca3c47f119fbdae8770c29820e5e6119b83f2"
uuid = "e3aaa7dc-3e4b-44e0-be63-ffb868ccd7c1"
version = "0.1.3"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "248a7031b3da79a127f14e5dc5f417e26f9f6db7"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "1.1.0"

[[deps.XZ_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "b29c22e245d092b8b4e8d3c09ad7baa586d9f573"
uuid = "ffd25f8a-64ca-5728-b0f7-c24cf3aae800"
version = "5.8.3+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "808090ede1d41644447dd5cbafced4731c56bd2f"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.13+0"

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
git-tree-sha1 = "1a4a26870bf1e5d26cd585e38038d399d7e65706"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.8+0"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "75e00946e43621e09d431d9b95818ee751e6b2ef"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "6.0.2+0"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "7ed9347888fac59a618302ee38216dd0379c480d"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.12+0"

[[deps.Xorg_libpciaccess_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "58972370b81423fc546c56a60ed1a009450177c3"
uuid = "a65dc6b1-eb27-53a1-bb3e-dea574b5389e"
version = "0.19.0+0"

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
version = "1.3.1+2"

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
git-tree-sha1 = "850b06095ee71f0135d644ffd8a52850699581ed"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.13.3+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "125eedcb0a4a0bba65b657251ce1d27c8714e9d6"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.17.4+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.15.0+0"

[[deps.libdrm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libpciaccess_jll"]
git-tree-sha1 = "63aac0bcb0b582e11bad965cef4a689905456c03"
uuid = "8e53e030-5e6c-5a89-a30b-be5b7263a166"
version = "2.4.125+1"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "646634dd19587a56ee2f1199563ec056c5f228df"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.4+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e51150d5ab85cee6fc36726850f0e627ad2e4aba"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.58+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "libpng_jll"]
git-tree-sha1 = "c1733e347283df07689d71d61e14be986e49e47a"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.10.5+0"

[[deps.libva_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll", "Xorg_libXext_jll", "Xorg_libXfixes_jll", "libdrm_jll"]
git-tree-sha1 = "7dbf96baae3310fe2fa0df0ccbb3c6288d5816c9"
uuid = "9a156e7d-b971-5f62-b2c9-67348b8fb97c"
version = "2.23.0+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll"]
git-tree-sha1 = "11e1772e7f3cc987e9d3de991dd4f6b2602663a5"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.8+0"

[[deps.libwebp_jll]]
deps = ["Artifacts", "Giflib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libglvnd_jll", "Libtiff_jll", "libpng_jll"]
git-tree-sha1 = "4e4282c4d846e11dce56d74fa8040130b7a95cb3"
uuid = "c5f90fcd-3b7e-5836-afba-fc50a0988cb2"
version = "1.6.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.64.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.7.0+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "14cc7083fc6dff3cc44f2bc435ee96d06ed79aa7"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "10164.0.1+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e7b67590c14d487e734dcb925924c5dc43ec85f3"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "4.1.0+0"
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
# ╟─aabbccdd-1111-4000-8000-000000000001
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
# ╠═aabbccdd-1111-4000-8000-000000000010
# ╟─aabbccdd-1111-4000-8000-000000000011
# ╠═aabbccdd-1111-4000-8000-000000000012
# ╠═aabbccdd-1111-4000-8000-000000000013
# ╟─aabbccdd-1111-4000-8000-000000000014
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
# ╟─aabbccdd-1111-4000-8000-000000000020
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
