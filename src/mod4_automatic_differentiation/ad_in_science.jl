### A Pluto.jl notebook ###
# v0.20.13

#> [frontmatter]
#> chapter = "4"
#> section = "2"
#> order = "12"
#> title = "Examples of Automatic Differentiation in Scientific Computing"
#> date = "2025-07-02"
#> tags = ["module4", "track_ad"]
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

# ╔═╡ e46cb298-35b9-4764-a867-795bbc5a0943
begin
	using PlutoUI, PlutoTeachingTools
	using PlutoUI: Slider
	PlutoUI.TableOfContents(; depth=4)
end

# ╔═╡ 6a1c41ab-76df-4e0f-bdf9-1e71506ba45d
begin
	using CairoMakie
	set_theme!(theme_latexfonts();
			   fontsize = 16,
			   Lines = (linewidth = 2,),
			   markersize = 16)
end


# ╔═╡ 5ae4d0c3-c5da-4b90-8fab-2cd4a2f0b44a
begin
	using Enzyme
	using Enzyme: Reverse
	import ForwardDiff
end

# ╔═╡ 2b0564a9-422d-4ba6-b867-4a902b8f844c
using Symbolics

# ╔═╡ 51a63a0a-a11b-4f53-a197-9dffabf6ad0c
using ShortCodes

# ╔═╡ 82b7a36d-d9cf-4050-bdb5-1db892ff853e
using SparseArrays

# ╔═╡ d34ccc86-bd36-4afd-9e30-2489a2b88779
using LinearAlgebra

# ╔═╡ 9ef768ba-c5a1-481a-add0-340f0bef982f
using Krylov

# ╔═╡ 8d6aa174-ed55-4fa9-bc8e-efd1abbb8404
using SparseConnectivityTracer

# ╔═╡ dbf6bdad-31eb-4414-ba7b-62dfc41ce940
begin
	using SparseMatrixColorings
	import Images
end

# ╔═╡ feb264fa-e282-40e8-ac69-eb4763945966
md"""
Motivation:

In science and engineering we often need to solve *systems of equations*.

If the equations are *linear* then linear algebra tells us a general method to solve them; these are now routinely applied to solve systems of millions of linear equations.

If the equations are *nonlinear* then things are less obvious. The main solution methods we know work by... reducing the nonlinear equations to a sequence of linear equations! They do this by *approximating* the function by a linear function and solving that to get a better solution, then repeating this operation as many times as necessary to get a *sequence* of increasingly better solutions. This is an example of an **iterative algorithm**.

A well-known and elegant method, which can be used in many different contexts, is the **Newton method**. It does, however, have the disadvantage that it requires derivatives of the function. This can be overcome using **automatic differentiation** techniques.
"""

# ╔═╡ c78a2897-7015-46d9-bfc0-9a31c3814050
md"""
## The Newton method in 1D
based of https://featured.plutojl.org/computational-thinking/newton.html
"""

# ╔═╡ 9f020c74-ce3b-4d6d-987f-40495cde0a61
md"""
We would like to solve equations like $f(x) = g(x)$. 
We rewrite that by moving all the terms to one side of the equation so that we can write $h(x) = 0$, with $h(x) := f(x) - g(x)$.

A point $x^*$ such that $h(x^*) = 0$ is called a **root** or **zero** of $h$.

The Newton method finds zeros, and hence solves the original equation.
"""

# ╔═╡ b537e53f-ebf8-4f22-adb4-77006c0f58d8
md"""
The idea of the Newton method is to *follow the direction in which the function is pointing*! We do this by building a **tangent line** at the current position and following that instead, until it hits the $x$-axis.

Let's look at that visually first:
"""

# ╔═╡ 84031796-be2e-4870-bb7e-e6c49134e329
md"""
n = $(@bind n2 Slider(0:10, show_value=true, default=1))
"""

# ╔═╡ ce8b7f71-fc5e-412f-8a28-eb865bd98e03
md"""
x₀ = $(@bind x02 Slider(-10:10, show_value=true, default=6))
"""

# ╔═╡ cbe34351-4ae5-440a-b2ae-dcd01757cede
md"""
n = $(@bind n Slider(0:10, show_value=true, default=1))
"""

# ╔═╡ 38880563-84ea-4b7a-84ac-0e4c6edf9b56
md"""
x₀ = $(@bind x0 Slider(-10:10, show_value=true, default=6))
"""

# ╔═╡ fd5fae86-30c1-469d-84a4-2f37c2895be8
straight(x0, y0, x, m) = y0 + m * (x - x0)

# ╔═╡ 53f32ad8-cbbd-447a-93f4-b39ac3cbb97e
function standard_Newton(f, n, x_range, x0, ymin=-10, ymax=10)
    
    f′ = x -> ForwardDiff.derivative(f, x)

	fig = Figure(size=(400, 300))
	ax = Axis(fig[1,1])
	ylims!(ax, ymin, ymax)
	
	lines!(ax, x_range, f)

	hlines
	hlines!(ax, 0.0, color=:magenta, linestyle=:dash) # lw=3)
	scatter!(ax, x0, 0, color=:green)
	annotation!(ax, x0, -5, text=L"x_0")
	
	for i in 1:n
		lines!(ax, [x0, x0], [0, f(x0)], color=:gray, alpha=0.5)
		scatter!(ax, x0, f(x0), color=:red)
		
		m = f′(x0)

		lines!(ax, x_range, [straight(x0, f(x0), x, m) for x in x_range], color=:blue, alpha=0.5, linestyle=:dash)
			  # lw=2)

		x1 = x0 - f(x0) / m

		scatter!(ax, x1, 0, color = :green)#, ann=(x1, -5, L"x_%$i", 10))
		annotation!(ax, x1, -5, text=L"x_%$i")
		
		x0 = x1

	end
	fig
end

# ╔═╡ e56c9cab-5908-4838-aba7-09623577d164
let
	f(x) = x^2 - 2

	standard_Newton(f, n2, -1:0.01:10, x02, -10, 70)
end

# ╔═╡ 852f5bd4-1661-4893-ab4d-93dd9bc96172
let
	f(x) = 0.2x^3 - 4x + 1
	
	standard_Newton(f, n, -10:0.01:10, x0, -10, 70)
end

# ╔═╡ 8f771594-fdf4-4343-9da9-5193b1d79432
md"""
### Mathematics of the Newton method
"""

# ╔═╡ 5e2c6a2a-beb5-4fd3-b686-f5b8b365548b
md"""
We can convert the idea of "following the tangent line" into equations as follows.
(You can also do so by just looking at the geometry in 1D, but that does not help in 2D.)
"""

# ╔═╡ 66508521-3e17-4707-8159-b1ff7a8e2549
md"""
Suppose we have a guess $x_0$ for the root and we want to find a (hopefully) better guess $x_1$.

Let's set $x_1 = x_0 + \delta$, where $x_1$ and $\delta$ are still unknown.

We want $x_1$ to be a root, so
"""

# ╔═╡ 82ee211e-db21-4f88-8eec-a78fa402ce84
md"""
$$f(x_1) = f(x_0 + \delta) \simeq 0$$
"""

# ╔═╡ b36665f2-fdee-40fd-b814-980fa19a71ae
md"""
If we are already "quite close" to the root then $\delta$ should be small, so we can approximate $f$ using the tangent line:

$$f(x_0) + \delta \, f'(x_0) \simeq 0$$

and hence

$$\delta \simeq \frac{-f(x_0)}{f'(x_0)}$$

so that

$$x_1 = x_0 - \frac{f(x_0)}{f'(x_0)}$$

Now we can repeat so that 

$$x_2 = x_1 - \frac{f(x_1)}{f'(x_1)}$$

and in general

$$x_{n+1} = x_n - \frac{f(x_n)}{f'(x_n)}.$$


This is the Newton method in 1D.
"""

# ╔═╡ a247217c-cf59-4ec1-bbc4-706b1204ee8b
function newton1D(f, x0)
	f′(x) = ForwardDiff.derivative(f, x)
	
	sequence = [x0]
	
	x = x0
	
	for i in 1:10
		x -= f(x) / f′(x)
	end
	
	return x
end

# ╔═╡ 5c313ce8-dbae-4c82-b1b0-dafa3ea78f6d
newton1D(x -> x^2 - 2, 37.0)

# ╔═╡ 14b8e99b-fd2b-418f-b657-18c47c9c1cc1
sqrt(2)

# ╔═╡ 8af45e55-e782-479d-b063-6afa3543bcfb
md"""
### Extending Netwon to 2D

$$T: \mathbb{R}^2 \to \mathbb{R}^2$$
"""

# ╔═╡ 233a7f9e-a27c-4fa0-8d04-a749bbf6f48b
md"""
We want to find the inverse $T^{-1}(y)$, i.e. to solve the equation $T(x) = y$ for $x$.

We use the same idea as in 1D, but now in 2D:
"""

# ╔═╡ 3ab03b6f-1791-46a5-80d9-fc043e2e08c6
md"""
$$T(x_0 + \delta) \simeq 0$$

$$T(x_0) + J \cdot \delta \simeq 0,$$

where $J := DT_{x_0}$ is the Jacobian matrix of $T$ at $x_0$, i.e. the best linear approximation of $T$ near to $x_0$.
"""

# ╔═╡ 6954e48d-0673-4f47-aec0-c4ddb1270219
md"""
Hence $\delta$ is the solution of the system of linear equations
"""

# ╔═╡ fd6d557e-3c42-49aa-9fce-256c69ae0b9f
md"""
$$J \cdot \delta = -T(x_0)$$

Then we again construct the new approximation $x_1$ as $x_1 := x_0 + \delta$.
"""

# ╔═╡ 90bf3931-e67f-40db-9474-ab5f2ba68c22
function newton2D_step(T, x)
	
	J = ForwardDiff.jacobian(T, x)
	
	δ = J \ T(x)   # J^(-1) * T(x)
	
	return x - δ
end

# ╔═╡ dc707823-9fac-470e-9ea4-ed5b38a07bb4
"Find ``x`` such that ``T(x) = 0``"
function newton2D(T, x0, n=10)
	
	x = x0

	for i in 1:n
		x = newton2D_step(T, x)
	end
	
	return x
end

# ╔═╡ 0387e199-253f-4dc9-81fb-adfed2dbd0c3
md"""
Remember that Newton is designed to look for *roots*, i.e. places where $T(x) = 0$.
We want $T(x) = y$, so we need another layer:
"""

# ╔═╡ 3e28b98b-eed1-4e45-814c-9d82e6655fb0
begin
	"Looks for ``x`` such that ``f(x) = y``, i.e. ``f(x) - y = 0``"
	function inverse(f, y, x0=[0, 0])
		return newton2D(x -> f(x) - y, x0)
	end
	inverse(f) = y -> inverse(f, y)
end

# ╔═╡ 02ee5f29-97dd-4dae-a733-7d9d8bec171e
T(α) = ((x, y),) -> [x + α*y^2, y + α*x^2]

# ╔═╡ 9c07e655-1cfb-46a9-af8c-25e07cbf3f86
md"""
α = $(@bind α Slider(0.0:0.01:1.0, show_value=true))
"""

# ╔═╡ 13037903-cd23-4da7-b8cd-dbb6771aa050
T(α)( [0.3, 0.4] )

# ╔═╡ 34e0c0bc-4877-4a02-8210-c53f8d64def4
( T(α) ∘ inverse(T(α)) )( [0.3, 0.4] ) # Essentially I*v

# ╔═╡ 9b581c58-b184-4d06-a9a7-08ebef24cdb0
md"""
## Jacobian

$f: \mathbb{R}^n\rightarrow\mathbb{R}^m$

```math
J = \begin{bmatrix}
  \frac{\partial f_1}{\partial x_1} & 
    \cdots & 
    \frac{\partial f_1}{\partial x_n} \\[1ex] % <-- 1ex more space between rows of matrix
   \vdots & 
    \ddots & 
    \vdots \\[1ex]
  \frac{\partial f_m}{\partial x_1} & 
    \cdots & 
    \frac{\partial f_m}{\partial x_n}
\end{bmatrix}
```
"""

# ╔═╡ 27d74eac-700f-4325-9869-0c6f43463c8b
md"""
Let's take a function `F` from $\mathbb{R}^2\rightarrow\mathbb{R}^3$ as a concrete example.
"""

# ╔═╡ 0b554dea-3ad2-414a-a7a7-c9e694002b76
function F(X) 
	[
		X[1]^4 - 3;
     	exp(X[2]) - 2; 
	 	log(X[1]) - X[2]^2
	]
end

# ╔═╡ dc46096e-28bc-49c2-ae57-670f72521b36
md"""
#### Manual derivation / Symbolics
"""

# ╔═╡ 5232357a-2d86-45e9-8591-7c4a379db12a
begin
	@variables X[2]
	ex_F = F(X)
	ex_J = Symbolics.jacobian(ex_F, X; scalarize=false)
end

# ╔═╡ 200b7150-d062-497c-a0c0-ea12856d16a8
md"""
!!! note
    Above we have the general form of the Jacobian of `F`, but more often than not we care about the Jacobian of `F` at a point `x`.
"""

# ╔═╡ f0514e8e-b97a-496f-ad9f-87300ed5c52d
substitute.(ex_J, X=>[1.0, 1.0])

# ╔═╡ 5cd872fe-71cc-46a8-88df-829c4de9c939
function F2(X) 
	[
		X[1]^4 - 3;
     	X[2] <= 0 ? X[2] : exp(X[2]) - 2; 
	 	log(X[1]) - X[2]^2
	]
end

# ╔═╡ 77c85b86-c0cc-443c-8aa2-58f0abac3214
md"""
!!! note
    When we have functions with control-flow that depend on an input, the symbolic approach fails.
"""

# ╔═╡ 36c84cde-b7c2-43a5-bb0e-8fae0552f8e2
begin
	ex_F2 = F2(X)
	ex_J2 = Symbolics.jacobian(ex_F2, X; scalarize=false)
end

# ╔═╡ 45c0c3f2-de06-4161-85fd-b8adaac56a75
md"""
#### Using ForwardDiff
"""

# ╔═╡ c5ba102c-b475-47c9-bd68-fb66473f96e0
ForwardDiff.jacobian(F, [1.0, 1.0])

# ╔═╡ 0aff3351-9e5f-4e67-80c7-487569b1263c
ForwardDiff.jacobian(F2, [1.0, 1.0])

# ╔═╡ a5698629-68b8-4b68-b8e5-d636c4062589
md"""
!!! note
    Automatic differentiation always evaluates things at a point, we can ask for the Jacobian of a function with input dependent control-flow.
"""

# ╔═╡ 13a29b0c-0aa9-4884-9ceb-f17067ab5cd8
ForwardDiff.jacobian(F, [1.0, -1.0])

# ╔═╡ 148dc2b8-b478-45b8-8599-3f3b908040dd
ForwardDiff.jacobian(F2, [1.0, -1.0])

# ╔═╡ ab0067f3-bfae-4f42-ba39-9e1bfdedf1f7
md"""
#### Using Enzyme
"""

# ╔═╡ e27f6b76-aebf-4319-b9b6-f92ea7f48347
Enzyme.jacobian(Forward, F, [1.0, 1.0]) |> only

# ╔═╡ 5fbe74c0-230d-4365-8282-2799b672494f
Enzyme.jacobian(Reverse, F, [1.0, 1.0]) |> only

# ╔═╡ 2b1c4518-82ee-400b-923c-038679bf655f
md"""
!!! note
    Both Jacobian are equivalent, but the object computed by Reverse mode is the transpose.
"""

# ╔═╡ ee746ffa-54c9-4a89-adeb-89c9b7c9833e
let
	J = Enzyme.jacobian(Reverse, F, [1.0, 1.0]) |> only
	v = [1.0, 0.0]
	J*v
end

# ╔═╡ 11af8ae0-df28-438f-b8a7-2e235dcdef10
md"""
### Mutation
"""

# ╔═╡ 8a897616-cd77-45af-a541-13a76e9eb8e7
begin
	function G!(Y, X)
		Y[1] = X[1]^4 - 3
     	Y[2] = exp(X[2]) - 2
	 	Y[3] = log(X[1]) - X[2]^2
	end
	function G(X)
		Y = similar(X, 3)
		G!(Y, X)
		Y
	end
end

# ╔═╡ cc515126-9e3d-48a8-b5d4-b29bb507aa4b
ForwardDiff.jacobian(G, [1.0, 1.0])

# ╔═╡ d1de4440-df3e-4475-b058-dd3cd56e536b
ForwardDiff.jacobian!(zeros(3, 2), G!, zeros(3), [1.0, 1.0])

# ╔═╡ 765975a1-7a8b-46b8-b11a-e2bc2b35b5f0
J = Enzyme.jacobian(Reverse, G, [1.0, 1.0]) |> only

# ╔═╡ 57087fe7-9eb1-4c9b-acb0-c6f3639bcf2c
md"""
### Jacobian vector product
"""

# ╔═╡ 5e4d567b-3a53-44dc-ac3e-bfb792509d21
md"""
The Jacobian-vector product or directional derivative is a powerful primitive.

We implicitly perform a $Jv$ operation at the point $u$. With Enzyme this is a direct application of `autodiff` in Forward mode.
"""

# ╔═╡ 19ea9417-208f-4f2c-8351-39d787ec33c9
function JVP(f::F, u, v, ϵ=NaN) where F
	return only(Enzyme.autodiff(Forward,
		  f,
		  Duplicated,
		  Duplicated(u, v)))
end

# ╔═╡ 1450b827-bc0d-452f-9c5c-493a510395a4
md"""
#### Approximation

In many texts you will find the directional derivatives approximated using a finite-difference operation.
"""

# ╔═╡ 8576cbbd-4fe7-414e-b5a8-3c8d5ee11655
md"""
#### First-order finite difference 

$\frac{F(u + \epsilon \cdot v) - F(u)}{\epsilon}$
"""

# ╔═╡ bf1ec46d-35ac-4c67-b18c-67ddbbf85c13
# First-order Taylor series
function JVP_Finite_Diff_1st(F, u, v, ϵ = sqrt(eps()))
    (F(u + ϵ .* v) - F(u)) ./ ϵ
end

# ╔═╡ a6e1f10e-0072-4ce5-b8b9-80e46cc9cd9f
md"""
#### Second-order finite difference
$\frac{F(u + \epsilon \cdot v) - F(u - \epsilon \cdot v)}{2\epsilon}$
"""

# ╔═╡ cfba8fa5-9a7f-46a5-9f19-e909f268f502
# Second-order Taylor series / Central finite difference
function JVP_Finite_Diff_2nd(F, u, v, ϵ = cbrt(eps()/2))
    (F(u + ϵ .* v) - F(u - ϵ .* v)) ./ 2ϵ
end

# ╔═╡ 858b0569-b45b-4584-88c3-7f003f1f6ad3
md"""
#### Choosing $ϵ$

!!! warn
    A core challenge is to choose the right $ϵ$ for the problem at hand.

##### Common
- For 1st order: $ϵ = \sqrt{\epsilon_{mach}}$
- For 2nd order: $ϵ = \sqrt[3]{\epsilon_{mach}/2}$

##### Input dependent
- For 1st order: $ϵ = \frac{\sqrt{(1 + ||u||)\epsilon_{mach}}}{||v||}$ 
  after $(DOI("10.1016/j.jcp.2003.08.010"))
- For 2nd order: $ϵ = \frac{\sqrt{(1 + ||u||)}}{||v||} \sqrt[3]{\epsilon_{mach}}$ 
  after $(DOI("10.1016/j.cam.2011.09.003"))
"""

# ╔═╡ 5120e1b4-6ae1-4074-812e-ff34d9bad60e
JVP_Finite_Diff_1st(F, [1.0 1.0], [1.0 0.0])

# ╔═╡ d4ae507b-8ebd-4ff9-aa28-7ec2692c09b6
JVP_Finite_Diff_2nd(F, [1.0 1.0], [1.0 0.0])

# ╔═╡ ccfb8431-ef72-46b7-9e40-6005ea5f06be
md"""
#### Example Truncated Weierstrass
"""

# ╔═╡ 6d788dbe-b589-45ac-9e1c-56b42164c1c2
md"""
Truncated Weierstrass

$f(x) = \sum_{k=0}^{N}(a^k cos(b^k\pi x))$
$f'(x) = - \sum_{k=0}^{N}(a^k b^k \pi sin(b^k\pi x))$

With $a \in (0,1)$ and $1<=ab$
"""

# ╔═╡ aff4afb2-6b42-4765-9100-3f142be71698
f(x, a=0.3, b=3.0; N=10) = sum(a^k * cos(b^k * π * x) for k in 0:N)

# ╔═╡ 1cbfbf39-f916-4082-8a52-7a711739504f
f′(x, a=0.3, b=3.0; N=10) = - sum(a^k * b^k * π * sin(b^k * π * x) for k in 0:N)

# ╔═╡ 14979edc-2c15-4bab-8890-6eaf97a225da
let
	xs = LinRange(-1.0, 1.0, 10000)
	fig = Figure(size=(800, 800))
	lines(fig[1, 1], xs, (x)->f(x, N=3), 
		axis=(;title="Function N=3", ylabel=L"$f(x)$", xlabel = L"$x$"))
	lines(fig[2, 1], xs, (x)->f(x, N=10),
		axis=(;title="Function N=10", ylabel=L"$f(x)$", xlabel = L"$x$"))
	lines(fig[1, 2],  xs, (x)->f′(x, N=3),
		axis=(;title="Derivative N=3", ylabel=L"$f'(x)$", xlabel = L"$x$"))
	lines(fig[2, 2],  xs, (x)->f′(x, N=10),
		axis=(;title="Derivative N=10", ylabel=L"$f'(x)$", xlabel = L"$x$"))

	fig
end

# ╔═╡ abeb91fd-545c-4b1e-ad83-499155df9bf6
function rel_error(f, f′, x, method, ϵ)
	y′ = f′(x)
	y = method(f, x, one(x), ϵ)
	max(eps()/4, abs((y′-y)/y′)) # Avoid error =0 to cause issues in log plot
end

# ╔═╡ 3c01bfdb-b44a-42e4-9438-04a00e457a20
let
	ϵs = [10.0^-x for x in 30:-0.1:0]
	#ϵs = BigFloat.([10.0^-x for x in 30:-0.1:0])
	x = 0.2
	fig = Figure(size=(800, 800))
	ax = Axis(fig[1,1], xscale=log10, yscale=log10, title="Relative error N=3", ylabel="Relative error", xlabel="Difference step size")
	ylims!(ax, 1e-20, 10e1)
	
	lines!(ax, ϵs, ϵ->rel_error((x)->f(x, N=3), (x)->f′(x, N=3), x, JVP_Finite_Diff_1st, ϵ), label="FFD/1st order")
	lines!(ax, ϵs, ϵ->rel_error((x)->f(x, N=3), (x)->f′(x, N=3), x, JVP_Finite_Diff_2nd, ϵ), label="CFD/2nd order")
	lines!(ax, ϵs, ϵ->rel_error((x)->f(x, N=3), (x)->f′(x, N=3), x, JVP, ϵ), label="AD")
	
	vlines!(ax, [sqrt(eps())], label=L"$\sqrt(\epsilon_{mach})$", color="red",ymin=-1)
	vlines!(ax, [cbrt(eps()/2)], label=L"$\cbrt(\epsilon_{mach}/2)$", color="orange",ymin=-1)
	axislegend(ax, position = :lt)

	ax = Axis(fig[2,1], xscale=log10, yscale=log10, title="Relative error N=10", ylabel = "Relative error", xlabel="Difference step size")
	ylims!(ax, 1e-20, 10e1)
	
	lines!(ax, ϵs, ϵ->rel_error((x)->f(x, N=10), (x)->f′(x, N=10), x, JVP_Finite_Diff_1st, ϵ), label="FFD/1st order")
	lines!(ax, ϵs, ϵ->rel_error((x)->f(x, N=10), (x)->f′(x, N=10), x, JVP_Finite_Diff_2nd, ϵ), label="CFD/2nd order")
	lines!(ax, ϵs, ϵ->rel_error((x)->f(x, N=10), (x)->f′(x, N=10), x, JVP, ϵ), label="AD")
	
	vlines!(ax, [sqrt(eps())], label=L"$\sqrt(\epsilon_{mach})$", color="red", ymin=-1)
	vlines!(ax, [cbrt(eps()/2)], label=L"$\cbrt(\epsilon_{mach}/2)$", color="orange", ymin=-1)
	axislegend(ax, position = :lt)

	
	fig
end

# ╔═╡ 4d2c3b3e-f080-4c85-b269-cf9a44039df7
md"""
### Extracting a Jacobian
"""

# ╔═╡ beebeee4-9ace-48cb-a199-054db91b0821
ex_F

# ╔═╡ fc94e961-7ef5-4063-afb3-831bdc244fb4
question_box(md"""
			 Are the zeros here real structural zeros, or are they computational zero?
			 """)

# ╔═╡ 23601c7e-7bba-4d0f-a735-d9cf68df0d19
ex_J

# ╔═╡ c17a28bd-5be0-4f0c-9e7e-0d5c96778c86
md"""
#### Inadmissability
"""

# ╔═╡ 13bf6c3a-1f3b-40d7-a7a0-d1e26fb9d613
md"""
!!! note
    Why is there a NaN?
"""

# ╔═╡ 438475e4-84ed-47fc-a32b-28e85894880f
ex_F

# ╔═╡ f0557ad5-b3cf-4211-83b6-60341350f609
md"""
```
Base.log(x::Dual) = Dual(log(x.value), x.deriv / x.value)
Base.:-(x::Dual, y::Dual) = Dual(x.value - y.value,
								 x.deriv - y.deriv)
```
"""

# ╔═╡ 0b2a206c-1719-481d-8a72-b6ceb4a9ae5e
0.0/0.0 # derivative of log(x=0.0)

# ╔═╡ e6deffa6-b4ce-4e8a-8c38-02e8a8b728d3
0.0/0.0 - 2.0

# ╔═╡ ccd67810-f1ae-49c5-b11a-201a0ad8f812
md"""
!!! note
    Finite differences can struggle with "inadmisable" values. Recall the definition of `F`. We calculate $log(X_1)$ If $X_1=0$ then the 2nd order method will go a little bit to the left and right of zero. `log(0-eps())` is not defined.
"""

# ╔═╡ 24a7c06d-8dd1-4016-a809-8816b7fa24e5
ex_F

# ╔═╡ 50c9b1ac-22de-41c6-a15b-8743f01c41d3
md"""
```
log(0-eps())
```
"""

# ╔═╡ 49ed86ea-8219-4bdd-a8aa-b656ffa24309
md"""
#### Using Enzyme (generalized)

$w = J*v$

```
autodiff(Forward, G!, Duplicated(out, w), Duplicated(in, v))
```

$w = v*J$


```
autodiff(Reverse, G!, Duplicated(out, copy(v)), Duplicated(in, w))
```

!!! note
    Recall from last week that Enzyme zeros the shadow-inputs. 
    Necessitating the `copy(v)`
"""

# ╔═╡ 0a623f3a-9fda-4590-aebb-ca56283dda41
md"""
!!! warn
    That's clearly wrong!
"""

# ╔═╡ 775255f7-f322-4ee5-9e2f-48abf91ecf15
let
	out = zeros(3)
	w = zeros(2)
	autodiff(Reverse, G!, Duplicated(out, [0.0,0.0,0.0]), Duplicated([1.0, 1.0], w))
	w
end

# ╔═╡ 1258de24-fd40-4a67-b7c0-426dd610e008
md"""
Uhm... All the seeds are zero... So why do we have a gradient!?
"""

# ╔═╡ 13cf456c-3960-4101-a273-823c211660fb
typeof(G!(zeros(3), [1.0, 1.0]))

# ╔═╡ 7548dfdc-a715-49ee-91d6-b11184759fee
md"""
Due to historic reasons Enzyme inferes function with floating point return as "active return" and provides an implicit seed of 1.0.
"""

# ╔═╡ c18ece26-e2f0-401b-a717-160a14c21d07
let
	out = zeros(3)
	w = zeros(2)
	autodiff(Reverse, G!, Const,
			 Duplicated(out, [0.0,0.0,0.0]), Duplicated([1.0, 1.0], w))
	w
end

# ╔═╡ e8d5c77b-3045-4d6e-bf2e-a1f6971828f3
md"""
Sanity restored...
"""

# ╔═╡ 458dd94e-8bf5-4a91-b56a-e11f40997000
md"""
## Jacobian Operator

Given a problem `F(u) = 0` we say that `F(u)` calculates the *residual*.
We want to have an operator `J(F, u)` that represents the Jacobian of `F` at `u`.
"""

# ╔═╡ 5a8f68ab-31a9-4f2f-a9e7-aa7b34a2055d
struct JacobianOperator{F, A}
    f::F # F!(out, in)
    out::A
    in::A
    function JacobianOperator(f::F, out, in) where {F}
        return new{F, typeof(in)}(f, out, in)
    end
end

# ╔═╡ 01955dbb-3a65-4829-b4c1-ac9f51b152db
begin
	Base.size(J::JacobianOperator) = (length(J.out), length(J.in))
	Base.eltype(J::JacobianOperator) = eltype(J.in)
end

# ╔═╡ 7555281f-f08c-43f3-89ea-4e33fbc715cf
function assemble_jacobian(F, u, JVP)
	N = length(u)
	v = zero(u)
	out = JVP(F, u, v)
	M = length(out)
	J = SparseMatrixCSC{eltype(u), Int}(undef, M, N)
	for j in 1:N
		v .= 0
		v[j] = 1
		out = JVP(F, u, v)
		for i in 1:M
			if out[i] != 0
				J[i, j] = out[i]
			end
		end
	end
	J
end

# ╔═╡ f086d449-9910-42ec-9cf8-22061b71554a
assemble_jacobian(F, [1.0 1.0], JVP)

# ╔═╡ 1bc022af-5cac-4126-bb57-32ee79ff3a03
assemble_jacobian(F, [1.0 1.0], JVP_Finite_Diff_1st)

# ╔═╡ c4c3a3e8-163c-4755-af61-e8f228aeedd6
assemble_jacobian(F, [1.0 1.0], JVP_Finite_Diff_2nd)

# ╔═╡ 2f5021bc-6ff8-499f-b4c7-9c10a9f6fad4
assemble_jacobian(F, [1.0 0.0], JVP)

# ╔═╡ a3a637e0-d70d-478e-92c1-9a2f1b55c208
assemble_jacobian(F, [1.0 0.0], JVP_Finite_Diff_1st)

# ╔═╡ b7f89c19-9ee9-4bdb-9cef-fa8d565e47e5
assemble_jacobian(F, [1.0 0.0], JVP_Finite_Diff_2nd)

# ╔═╡ a26d68f5-3a5a-4aa5-9923-3846d0291885
assemble_jacobian(F, [0.0 1.0], JVP)

# ╔═╡ d5443976-5370-483f-9d80-c9e99bbcc81c
assemble_jacobian(F, [0.0 1.0], JVP_Finite_Diff_1st)

# ╔═╡ a43b052e-feab-49a6-9097-2eb70513953a
assemble_jacobian(F, [0.0 1.0], JVP_Finite_Diff_2nd)

# ╔═╡ 7a838d91-ae25-484e-bbd6-ba7bee55d1d4
begin
	LinearAlgebra.adjoint(J::JacobianOperator) = Adjoint(J)
	LinearAlgebra.transpose(J::JacobianOperator) = Transpose(J)
end

# ╔═╡ d61dbc33-6d1a-48ba-9489-693bb3700ae3
let
	J = Enzyme.jacobian(Reverse, F, [1.0, 1.0]) |> only
	v = [1.0, 0.0, 0.0]
	transpose(J) * v # vJ
end

# ╔═╡ b12a5cad-5f60-4473-9c64-7731e3d3e1ed
begin
	v = [1.0, 0.0, 0.0]
	transpose(J)*v
end

# ╔═╡ cc0ca242-e5f9-4812-bd3b-d6a1ab6cbfc7
let
	out = zeros(3)
	w = zeros(2)
	autodiff(Reverse, G!, Duplicated(out, copy(v)), Duplicated([1.0, 1.0], w))
	w
end

# ╔═╡ 0cf8867b-2ff6-4f6c-8504-7cf877b28f31
let
	out = zeros(3)
	w = zeros(2)
	autodiff(Reverse, G!, Const,
			 Duplicated(out, copy(v)), Duplicated([1.0, 1.0], w))
	w
end

# ╔═╡ 4624b3e8-be3b-4e27-92a4-9b071987e8e1
function maybe_duplicated(f, df)
    if !Enzyme.Compiler.guaranteed_const(typeof(f))
        return DuplicatedNoNeed(f, df)
    else
        return Const(f)
    end
end

# ╔═╡ 824fb368-5f80-4643-9872-8fc8044d900f
function LinearAlgebra.mul!(out, J::JacobianOperator, v)
    autodiff(
        Forward,
        maybe_duplicated(J.f, Enzyme.make_zero(J.f)), Const,
        Duplicated(J.out, out),
        Duplicated(J.in, v)
    )
    return nothing
end

# ╔═╡ d25383f8-86f2-45b2-b2a6-cfe29efa7f7e
function LinearAlgebra.mul!(out, J′::Union{Adjoint{<:Any, <:JacobianOperator}, Transpose{<:Any, <:JacobianOperator}}, v)
    J = parent(J′)
    # If out is non-zero we get spurious gradients
    out .= 0
    autodiff(
        Reverse,
        maybe_duplicated(J.f, Enzyme.make_zero(J.f)), 
		Const,
		# Enzyme zeros input derivatives and that confuses the solvers.
        Duplicated(J.out, copy(v)),
        Duplicated(J.in, out)
    )
    return nothing
end

# ╔═╡ d4657f7f-f992-4196-b6f9-da9b20e2bd2e
function Base.collect(JOp::JacobianOperator)
    N, M = size(JOp)
    v = zeros(eltype(JOp), M)
    out = zeros(eltype(JOp), N)
    J = SparseMatrixCSC{eltype(v), Int}(undef, size(JOp)...)
    for j in 1:M
        out .= 0.0
        v .= 0.0
        v[j] = 1.0
        mul!(out, JOp, v)
        for i in 1:N
            if out[i] != 0
                J[i, j] = out[i]
            end
        end
    end
    return J
end

# ╔═╡ 899e4ead-decb-4cc9-a855-3bad4b01cc8c
JOp = JacobianOperator(G!, zeros(3), [1.0, 1.0])

# ╔═╡ 43eb2a0b-7acc-4ab6-83b4-2dbb3b378983
let
	w = zeros(3)
	mul!(w, JOp, [1.0, 0.0])
	w
end

# ╔═╡ e97858d0-b394-4c85-8de0-71b6b61e49e9
let
	w = zeros(2)
	mul!(w, transpose(JOp), [1.0, 0.0, 0.0])
	w
end

# ╔═╡ c4ddb84b-9439-4e68-8230-4758e2272e88
md"""
## Newton-Krylov
$F(u) = 0$
$J(F, u) \times x = -F(u)$

Problems of the form $F(u) = 0$ can be solved with a Newton method, this particular helpful for finding an iterative solution of nonlinear equations.

We can use a Krylov solver "gmres" to solve the linear system $Ax=-b$ without "materializing" $A$. This is called a matrix-free method.
"""

# ╔═╡ bcf5e168-ff76-436e-84ba-fd73226a9232
begin
	function G2!(y, x)
	    y[1] = x[1]^2 + x[2]^2 - 2
		y[2] = exp(x[1] - 1) + x[2]^2 - 2
	end
	function G2(x)
		y = similar(x)
		G2!(y, x)
		return y
	end
end

# ╔═╡ dcb6f8c4-bfae-4646-ae98-05eedc193167
let
	xs = LinRange(-3, 4, 1000)
	ys = LinRange(-5, 5, 1000)
	
	levels = [0.1, 0.25, 0.5:2:10..., 10.0:10:200..., 200:100:4000...]
	
	fig, ax = contour(xs, ys, (x, y) -> norm(G2([x, y])); levels)
	fig
end

# ╔═╡ bb581fc3-57c4-4e27-90ab-56a8a88367f6
function newton_krylov!(F!, u;
						tol_rel = 1.0e-6,
        				tol_abs = 1.0e-12,
						max_niter = 50,
						callback = x->nothing)

	res = similar(u)
	F!(res, u)
	n_res = norm(res)
	callback(u)

	tol = tol_rel * n_res + tol_abs
	iter = 0
	
	while n_res > tol && iter <= max_niter
		# Ax = -b
		J = JacobianOperator(F!, res, u)
		x, stats = gmres(J, -res)

		# Take a step in the newton direction
		u .+= x

		F!(res, u)
		n_res = norm(res)
		callback(u)
		if isinf(n_res) || isnan(n_res)
			error("Solver blew up")
		end
		iter += 1
	end
	return u, (; solved = n_res <= tol, iter)
end

# ╔═╡ 7531960a-9a51-4950-abdc-112bea3e791e
trace_1 = let x₀ = [2.0, 0.5]
    xs = Vector{Tuple{Float64, Float64}}(undef, 0)
    hist(x) = (push!(xs, (x[1], x[2])); nothing)
    _ = newton_krylov!(G2!, x₀, callback = hist)
	xs
end

# ╔═╡ 1ce82922-2664-4a08-a47f-5e353e3701cf
trace_2 = let x₀ = [2.5, 3.0]
    xs = Vector{Tuple{Float64, Float64}}(undef, 0)
    hist(x) = (push!(xs, (x[1], x[2])); nothing)
    newton_krylov!(G2!, x₀, callback = hist)
    xs
end

# ╔═╡ 353fa149-a0ff-4923-a3f0-e115ecdfdf2d
G2([trace_2[end]...])

# ╔═╡ 3722f5d6-011c-4318-b512-36380269eebb
let
	xs = LinRange(-3, 4, 1000)
	ys = LinRange(-5, 5, 1000)
	
	levels = [0.1, 0.25, 0.5:2:10..., 10.0:10:200..., 200:100:4000...]
	
	fig, ax = contour(xs, ys, (x, y) -> norm(G2([x, y])); levels)
	lines!(ax, trace_1)
	lines!(ax, trace_2)
	fig
end

# ╔═╡ 6ec186a8-114b-4f51-9a28-0135e8dc04ac
md"""
## Coloring
"""

# ╔═╡ 4b7edccf-f98f-47c8-87b0-83e4258166b8
md"""
Matrix-free methods are powerful especially for systems that are:
1. Large
2. Unkown structure of the Jacobian

But special care is needed to make sure that the number of Jacobian-Vector product evaluations is low. In particular for Netwon-Krylov one has to use inexact Newton-Krylov with an Eisenstatt-Walker condition.

Matrix coloring is an alternative to reduce the cost of calculating the Jacobian at each iteration.
"""

# ╔═╡ 3b766814-0397-45f2-b59e-3b3659eb8859
md"""
!!! note
	Adrian Hill and Guillaume Dalle have done some great work on this in the Julia AD landscape.

1. https://iclr-blogposts.github.io/2025/blog/sparse-autodiff/
2. https://arxiv.org/abs/2501.17737

!!! warn
    Remember the issues we had earlier with "structural sparsisty" and "input dependent computation". These issues are particularly perniscous for automatic sparsity detection.
"""

# ╔═╡ 88f3172f-d031-485d-a49d-0cb19d21ff37
jacobian_sparsity(F, [1.0, 1.0], TracerSparsityDetector())

# ╔═╡ 77923aa6-939b-400e-8e04-fcd3753f4cbc
jacobian_sparsity(F, [1.0, 0.0], TracerSparsityDetector())

# ╔═╡ 45e43630-09a5-4d1e-b7d7-cd72eca3d146
jacobian_sparsity(F, [1.0, 0.0], TracerLocalSparsityDetector())

# ╔═╡ d8797760-0090-42f5-b297-c119a2ac1727
jacobian_sparsity(x->x[1]*x[2], [1.0, 0.0], TracerLocalSparsityDetector())

# ╔═╡ 425ee2c7-82b2-4560-b538-1d5b768fd4cd
jacobian_sparsity(x->x[1]*x[2], [0.0, 1.0], TracerLocalSparsityDetector())

# ╔═╡ 4306dd2d-d831-4358-ad2e-c77ba1be101e
jacobian_sparsity(x->x[1]*x[2], [1.0, 1.0], TracerLocalSparsityDetector())

# ╔═╡ 50f0d2b8-c26c-495f-a606-88df639557bd
jacobian_sparsity(x->x[1]*x[2], [0.0, 0.0], TracerSparsityDetector())

# ╔═╡ fe9db70c-82ad-4fdf-91b7-8280f902fd72
jacobian_sparsity(F2, [1.0, 1.0], TracerSparsityDetector())

# ╔═╡ 23807f7b-a02b-485d-87cc-d7a9dfd4c684
jacobian_sparsity(F2, [1.0, 1.0], TracerLocalSparsityDetector())

# ╔═╡ 53a9d262-a1e9-491e-8e0d-aa1543593b76
md"""
Recall the diffuse example from the beginning of term.
"""

# ╔═╡ 3166db0b-dcc9-47ad-a4a4-312c83a514d5
function heat_1D!(du, u, (a, Δx), t)
    N = length(u)

    # Enforce the boundary condition
    u[1] = 0
	u[end] = 0
    du[1] = 0
    du[end] = 0

    # Only compute within
    for i in 2:(N - 1)
        du[i] = a * (u[i + 1] - 2u[i] + u[i - 1]) / Δx^2
    end
    return
end

# ╔═╡ 3c38d5c8-ebc4-45fb-ad85-bf8590c1805c
function heat_1D(u)
	du = similar(u)
	heat_1D!(du, u, (0.01, 0.01), 0.01)
	return du
end

# ╔═╡ e497a596-e1b5-4eec-9bba-ee4a4fb6f441
md"""
What is it's Jacobian?
"""

# ╔═╡ 7b36b0fb-754c-4f75-883d-4efe57a674dd
ForwardDiff.jacobian(heat_1D, ones(12))

# ╔═╡ 96f27ecd-982e-4377-87db-999492a12707
assemble_jacobian(heat_1D, ones(12), JVP)

# ╔═╡ 77fd49cb-8d56-4688-8df3-7e19e70da303
J_heat_1D_sparsity = jacobian_sparsity(heat_1D, ones(12), TracerSparsityDetector())

# ╔═╡ 5d13b13b-f7e9-4475-9a0d-6a8e13101770
result = coloring(J_heat_1D_sparsity, ColoringProblem(), GreedyColoringAlgorithm());

# ╔═╡ 28d6817b-3184-4673-ad93-3e1de2cf809a
SparseMatrixColorings.show_colors(result)[1]

# ╔═╡ 3084f697-3602-484b-b59d-90f830045538
ncolors(result)

# ╔═╡ 761d220d-d926-456a-a23f-85aaa5989ad2
column_colors(result)

# ╔═╡ 4486037a-3d30-4219-9c81-1659dbee4e0c
function assemble_jacobian_with_colors(F, u, JVP)
	sparsity = jacobian_sparsity(F, u, TracerSparsityDetector())
	result = coloring(sparsity, ColoringProblem(), GreedyColoringAlgorithm());
	
	N = length(u)
	v = zero(u)
	out = JVP(F, u, v)
	M = length(out)
	J = Matrix{eltype(u)}(undef, M, ncolors(result))
	for c in 1:ncolors(result)
		v .= 0
		for j in 1:N
			if c == column_colors(result)[j]
				v[j] = 1
			end
		end
		J[:,c] = JVP(F, u, v)
	end
	decompress(J, result)
end

# ╔═╡ 7fef1e26-3ebc-4da1-ba96-ce85e5c1bce0
assemble_jacobian_with_colors(heat_1D, ones(12), JVP)

# ╔═╡ 73eca3e1-e3bb-4e38-af4e-9a6d1d65472c
md"""
!!! note
	Instead of doing `length(u)` JVPs, we are only doing `ncolors`. As long as the structure of our Jacobian is stable we can reuse the color information to extract it efficiently.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
Krylov = "ba0b0d4f-ebba-5204-a429-3ac8c609bfb7"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
ShortCodes = "f62ebe17-55c5-4640-972f-b59c0dd11ccf"
SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
SparseConnectivityTracer = "9f842d2f-2579-4b1d-911e-f412cf18a3f5"
SparseMatrixColorings = "0a514795-09f3-496d-8182-132a7b665d35"
Symbolics = "0c5d862f-8b57-4792-8d23-62f2024744c7"

[compat]
CairoMakie = "~0.15.0"
Enzyme = "~0.13.51"
ForwardDiff = "~1.0.1"
Images = "~0.26.2"
Krylov = "~0.10.1"
PlutoTeachingTools = "~0.4.1"
PlutoUI = "~0.7.65"
ShortCodes = "~0.3.6"
SparseConnectivityTracer = "~0.6.21"
SparseMatrixColorings = "~0.4.21"
Symbolics = "~6.43.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "80530fc998d31145103ec5586f34522a50666435"

[[deps.ADTypes]]
git-tree-sha1 = "be7ae030256b8ef14a441726c4c37766b90b93a3"
uuid = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
version = "1.15.0"
weakdeps = ["ChainRulesCore", "ConstructionBase", "EnzymeCore"]

    [deps.ADTypes.extensions]
    ADTypesChainRulesCoreExt = "ChainRulesCore"
    ADTypesConstructionBaseExt = "ConstructionBase"
    ADTypesEnzymeCoreExt = "EnzymeCore"

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

[[deps.Accessors]]
deps = ["CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "MacroTools"]
git-tree-sha1 = "3b86719127f50670efe356bc11073d84b4ed7a5d"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.42"

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

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "d57bd3762d308bded22c3b82d033bff85f6195c6"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.4.0"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra"]
git-tree-sha1 = "9606d7832795cbef89e06a550475be300364a8aa"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.19.0"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceCUDSSExt = "CUDSS"
    ArrayInterfaceChainRulesCoreExt = "ChainRulesCore"
    ArrayInterfaceChainRulesExt = "ChainRules"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceReverseDiffExt = "ReverseDiff"
    ArrayInterfaceSparseArraysExt = "SparseArrays"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    CUDSS = "45b445bb-4962-46a0-9369-b4df9d0f772e"
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

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

[[deps.BaseDirs]]
git-tree-sha1 = "03fea4a4efe25d2069c2d5685155005fc251c0a1"
uuid = "18cc8868-cbac-4acf-b575-c8ff214dc66f"
version = "1.3.0"

[[deps.Bijections]]
git-tree-sha1 = "a2d308fcd4c2fb90e943cf9cd2fbfa9c32b69733"
uuid = "e2ed5e7c-b2de-5872-ae92-c73ca462fb04"
version = "0.2.2"

[[deps.BitTwiddlingConvenienceFunctions]]
deps = ["Static"]
git-tree-sha1 = "f21cfd4950cb9f0587d5067e69405ad2acd27b87"
uuid = "62783981-4cbd-42fc-bca8-16325de8dc4b"
version = "0.1.6"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1b96ea4a01afe0ea4090c5c8039690672dd13f2e"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.9+0"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CPUSummary]]
deps = ["CpuId", "IfElse", "PrecompileTools", "Static"]
git-tree-sha1 = "5a97e67919535d6841172016c9530fd69494e5ec"
uuid = "2a0fbf3d-bb9c-48f3-b0a9-814d99fd7ab9"
version = "0.2.6"

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
git-tree-sha1 = "d9b76aa0798df8d010c564fc68a7bf4f2c660c21"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.15.2"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "fde3bf89aead2e723284a8ff9cdf5b551ed700e8"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.5+0"

[[deps.CatIndices]]
deps = ["CustomUnitRanges", "OffsetArrays"]
git-tree-sha1 = "a0f80a09780eed9b1d106a1bf62041c2efc995bc"
uuid = "aafaddc9-749c-510e-ac4f-586e18779b91"
version = "0.2.2"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "06ee8d1aa558d2833aa799f6f0b31b30cada405f"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.25.2"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.CloseOpenIntervals]]
deps = ["Static", "StaticArrayInterface"]
git-tree-sha1 = "05ba0d07cd4fd8b7a39541e31a7b0254704ea581"
uuid = "fb6a15b2-703c-40df-9091-08a04967cfa9"
version = "0.1.13"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "Random", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "3e22db924e2945282e70c33b75d4dde8bfa44c94"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.15.8"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "962834c22b66e32aa10f7611c08c8ca4e20749a9"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.8"

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

[[deps.Combinatorics]]
git-tree-sha1 = "8010b6bb3388abe68d95743dcbea77650bb2eddf"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.3"

[[deps.CommonSolve]]
git-tree-sha1 = "0eee5eb66b1cf62cd6ad1b460238e60e4b09400c"
uuid = "38540f10-b2f7-11e9-35d8-d573e4eb0ff2"
version = "0.2.4"

[[deps.CommonSubexpressions]]
deps = ["MacroTools"]
git-tree-sha1 = "cda2cfaebb4be89c9084adaca7dd7333369715c5"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.1"

[[deps.CommonWorldInvalidations]]
git-tree-sha1 = "ae52d1c52048455e85a387fbee9be553ec2b68d0"
uuid = "f70d9fcc-98c5-4d4a-abd7-e4cdeebd8ca8"
version = "1.0.0"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "3a3dfb30697e96a440e4149c8c51bf32f818c0f3"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.17.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.CompositeTypes]]
git-tree-sha1 = "bce26c3dab336582805503bed209faab1c279768"
uuid = "b152e2b5-7a66-4b01-a709-34e65c35f657"
version = "0.1.4"

[[deps.CompositionsBase]]
git-tree-sha1 = "802bb88cd69dfd1509f6670416bd4434015693ad"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.2"
weakdeps = ["InverseFunctions"]

    [deps.CompositionsBase.extensions]
    CompositionsBaseInverseFunctionsExt = "InverseFunctions"

[[deps.ComputationalResources]]
git-tree-sha1 = "52cb3ec90e8a8bea0e62e275ba577ad0f74821f7"
uuid = "ed09eef8-17a6-5b46-8889-db040fac31e3"
version = "0.3.2"

[[deps.ComputePipeline]]
deps = ["Observables", "Preferences"]
git-tree-sha1 = "09570704174dbe7d72ee5dcca604b985b6f384e6"
uuid = "95dc2771-c249-4cd0-9c9f-1f3b4330693c"
version = "0.1.1"

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

[[deps.CoordinateTransformations]]
deps = ["LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "a692f5e257d332de1e554e4566a4e5a8a72de2b2"
uuid = "150eb455-5306-5404-9cee-2592286d6298"
version = "0.6.4"

[[deps.CpuId]]
deps = ["Markdown"]
git-tree-sha1 = "fcbb72b032692610bfbdb15018ac16a36cf2e406"
uuid = "adafc99b-e345-5852-983c-f28acb93d879"
version = "0.3.1"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.CustomUnitRanges]]
git-tree-sha1 = "1a3f97f907e6dd8983b744d2642651bb162a3f7a"
uuid = "dc8bdbbb-1ca9-579f-8c36-e416f6a65cce"
version = "1.0.2"

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

[[deps.Distances]]
deps = ["LinearAlgebra", "Statistics", "StatsAPI"]
git-tree-sha1 = "c7e3a542b999843086e2f29dac96a618c105be1d"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.12"
weakdeps = ["ChainRulesCore", "SparseArrays"]

    [deps.Distances.extensions]
    DistancesChainRulesCoreExt = "ChainRulesCore"
    DistancesSparseArraysExt = "SparseArrays"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.Distributions]]
deps = ["AliasTables", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns"]
git-tree-sha1 = "3e6d038b77f22791b8e3472b7c633acea1ecac06"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.120"

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

[[deps.DomainSets]]
deps = ["CompositeTypes", "IntervalSets", "LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "a0c11553b6c58bfc0283d8279dd3798150b77ac5"
uuid = "5b8099bc-c8ec-5219-889f-1d9e522a28bf"
version = "0.7.12"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DynamicPolynomials]]
deps = ["Future", "LinearAlgebra", "MultivariatePolynomials", "MutableArithmetics", "Reexport", "Test"]
git-tree-sha1 = "98c4bb95af37e5d980129261fdd6dab0392c6607"
uuid = "7c1d4256-1411-5781-91ec-d7bc3513ac07"
version = "0.6.2"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.EnumX]]
git-tree-sha1 = "bddad79635af6aec424f53ed8aad5d7555dc6f00"
uuid = "4e289a0a-7415-4d19-859d-a7e5c4648b56"
version = "1.0.5"

[[deps.Enzyme]]
deps = ["CEnum", "EnzymeCore", "Enzyme_jll", "GPUCompiler", "InteractiveUtils", "LLVM", "Libdl", "LinearAlgebra", "ObjectFile", "PrecompileTools", "Preferences", "Printf", "Random", "SparseArrays"]
git-tree-sha1 = "d58fef755b0bde0e4dace520d875b386f82b9ab1"
uuid = "7da242da-08ed-463a-9acd-ee780be4f1d9"
version = "0.13.54"

    [deps.Enzyme.extensions]
    EnzymeBFloat16sExt = "BFloat16s"
    EnzymeChainRulesCoreExt = "ChainRulesCore"
    EnzymeGPUArraysCoreExt = "GPUArraysCore"
    EnzymeLogExpFunctionsExt = "LogExpFunctions"
    EnzymeSpecialFunctionsExt = "SpecialFunctions"
    EnzymeStaticArraysExt = "StaticArrays"

    [deps.Enzyme.weakdeps]
    BFloat16s = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    LogExpFunctions = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.EnzymeCore]]
git-tree-sha1 = "8272a687bca7b5c601c0c24fc0c71bff10aafdfd"
uuid = "f151be2c-9106-41f4-ab19-57ee4f262869"
version = "0.8.12"
weakdeps = ["Adapt"]

    [deps.EnzymeCore.extensions]
    AdaptExt = "Adapt"

[[deps.Enzyme_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "97e0a9a3fa1c51ebd94dd076dd847c037b79fd79"
uuid = "7cc45869-7501-5eee-bdea-0790c847d4ef"
version = "0.0.183+0"

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

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.ExproniconLite]]
git-tree-sha1 = "c13f0b150373771b0fdc1713c97860f8df12e6c2"
uuid = "55351af7-c7e9-48d6-89ff-24e801d99491"
version = "0.10.14"

[[deps.Extents]]
git-tree-sha1 = "b309b36a9e02fe7be71270dd8c0fd873625332b4"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.6"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "8cc47f299902e13f90405ddb5bf87e5d474c0d38"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "6.1.2+0"

[[deps.FFTViews]]
deps = ["CustomUnitRanges", "FFTW"]
git-tree-sha1 = "cbdf14d1e8c7c8aacbe8b19862e0179fd08321c2"
uuid = "4f61f5a4-77b1-5117-aa51-3ab5ef4ef0cd"
version = "0.3.2"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "797762812ed063b9b94f6cc7742bc8883bb5e69e"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.9.0"

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

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "910febccb28d493032495b7009dce7d7f7aee554"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "1.0.1"
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
git-tree-sha1 = "2c5512e11c791d1baed2049c5652441b28fc6a31"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.4+0"

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

[[deps.FunctionWrappers]]
git-tree-sha1 = "d62485945ce5ae9c0c48f124a84998d755bae00e"
uuid = "069b7b12-0de2-55c6-9aab-29f3d0a68a2e"
version = "1.1.3"

[[deps.FunctionWrappersWrappers]]
deps = ["FunctionWrappers"]
git-tree-sha1 = "b104d487b34566608f8b4e1c39fb0b10aa279ff8"
uuid = "77dc65aa-8811-40c2-897b-53d922fa7daf"
version = "0.1.3"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"
version = "1.11.0"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "83cf05ab16a73219e5f6bd1bdfa9848fa24ac627"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.2.0"

[[deps.GPUCompiler]]
deps = ["ExprTools", "InteractiveUtils", "LLVM", "Libdl", "Logging", "PrecompileTools", "Preferences", "Scratch", "Serialization", "TOML", "Tracy", "UUIDs"]
git-tree-sha1 = "71a747c7c0137222dceb799b5643440e8eb6bfce"
uuid = "61eb1bfa-7361-4325-ad38-22787b887f55"
version = "1.6.0"

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
git-tree-sha1 = "2670cf32dcf0229c9893b895a9afe725edb23545"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.5.9"

[[deps.GettextRuntime_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll"]
git-tree-sha1 = "45288942190db7c5f760f59c04495064eedf9340"
uuid = "b0724c58-0f36-5564-988d-3bb0596ebc4a"
version = "0.22.4+0"

[[deps.Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "43ba3d3c82c18d88471cfd2924931658838c9d8f"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.0+4"

[[deps.Giflib_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6570366d757b50fabae9f4315ad74d2e40c0560a"
uuid = "59f7168a-df46-5410-90c8-f2779963d0ec"
version = "5.2.3+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "GettextRuntime_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "35fbd0cefb04a516104b8e183ce0df11b70a3f1a"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.84.3+0"

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

[[deps.Graphs]]
deps = ["ArnoldiMethod", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "c5abfa0ae0aaee162a3fbb053c13ecda39be545b"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.13.0"

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
git-tree-sha1 = "f923f9a774fcf3f5cb761bfa43aeadd689714813"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.5.1+0"

[[deps.HashArrayMappedTries]]
git-tree-sha1 = "2eaa69a7cab70a52b9687c8bf950a5a93ec895ae"
uuid = "076d061b-32b6-4027-95e0-9a2c6f6d7e74"
version = "0.2.0"

[[deps.HistogramThresholding]]
deps = ["ImageBase", "LinearAlgebra", "MappedArrays"]
git-tree-sha1 = "7194dfbb2f8d945abdaf68fa9480a965d6661e69"
uuid = "2c695a8d-9458-5d45-9878-1b8a99cf7853"
version = "0.3.1"

[[deps.HostCPUFeatures]]
deps = ["BitTwiddlingConvenienceFunctions", "IfElse", "Libdl", "Static"]
git-tree-sha1 = "8e070b599339d622e9a081d17230d74a5c473293"
uuid = "3e5b6fbb-0976-4d2c-9146-d79de83f2fb0"
version = "0.1.17"

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

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

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

[[deps.ImageBinarization]]
deps = ["HistogramThresholding", "ImageCore", "LinearAlgebra", "Polynomials", "Reexport", "Statistics"]
git-tree-sha1 = "33485b4e40d1df46c806498c73ea32dc17475c59"
uuid = "cbc4b850-ae4b-5111-9e64-df94c024a13d"
version = "0.3.1"

[[deps.ImageContrastAdjustment]]
deps = ["ImageBase", "ImageCore", "ImageTransformations", "Parameters"]
git-tree-sha1 = "eb3d4365a10e3f3ecb3b115e9d12db131d28a386"
uuid = "f332f351-ec65-5f6a-b3d1-319c6670881a"
version = "0.3.12"

[[deps.ImageCore]]
deps = ["ColorVectorSpace", "Colors", "FixedPointNumbers", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "PrecompileTools", "Reexport"]
git-tree-sha1 = "8c193230235bbcee22c8066b0374f63b5683c2d3"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.10.5"

[[deps.ImageCorners]]
deps = ["ImageCore", "ImageFiltering", "PrecompileTools", "StaticArrays", "StatsBase"]
git-tree-sha1 = "24c52de051293745a9bad7d73497708954562b79"
uuid = "89d5987c-236e-4e32-acd0-25bd6bd87b70"
version = "0.1.3"

[[deps.ImageDistances]]
deps = ["Distances", "ImageCore", "ImageMorphology", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "08b0e6354b21ef5dd5e49026028e41831401aca8"
uuid = "51556ac3-7006-55f5-8cb3-34580c88182d"
version = "0.2.17"

[[deps.ImageFiltering]]
deps = ["CatIndices", "ComputationalResources", "DataStructures", "FFTViews", "FFTW", "ImageBase", "ImageCore", "LinearAlgebra", "OffsetArrays", "PrecompileTools", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "TiledIteration"]
git-tree-sha1 = "eea3a5095c0c5f143e62773164ab11f67e43c4bb"
uuid = "6a3955dd-da59-5b1f-98d4-e7296123deb5"
version = "0.7.10"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs", "WebP"]
git-tree-sha1 = "696144904b76e1ca433b886b4e7edd067d76cbf7"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.9"

[[deps.ImageMagick]]
deps = ["FileIO", "ImageCore", "ImageMagick_jll", "InteractiveUtils"]
git-tree-sha1 = "8e64ab2f0da7b928c8ae889c514a52741debc1c2"
uuid = "6218d12a-5da1-5696-b52f-db25d2ecc6d1"
version = "1.4.2"

[[deps.ImageMagick_jll]]
deps = ["Artifacts", "Ghostscript_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "OpenJpeg_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "afde851466407a99d48829051c36ac80749d8d7c"
uuid = "c73af94c-d91f-53ed-93a7-00f77d67a9d7"
version = "7.1.1048+0"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "2a81c3897be6fbcde0802a0ebe6796d0562f63ec"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.10"

[[deps.ImageMorphology]]
deps = ["DataStructures", "ImageCore", "LinearAlgebra", "LoopVectorization", "OffsetArrays", "Requires", "TiledIteration"]
git-tree-sha1 = "cffa21df12f00ca1a365eb8ed107614b40e8c6da"
uuid = "787d08f9-d448-5407-9aad-5290dd7ab264"
version = "0.4.6"

[[deps.ImageQualityIndexes]]
deps = ["ImageContrastAdjustment", "ImageCore", "ImageDistances", "ImageFiltering", "LazyModules", "OffsetArrays", "PrecompileTools", "Statistics"]
git-tree-sha1 = "783b70725ed326340adf225be4889906c96b8fd1"
uuid = "2996bd0c-7a13-11e9-2da2-2f5ce47296a9"
version = "0.3.7"

[[deps.ImageSegmentation]]
deps = ["Clustering", "DataStructures", "Distances", "Graphs", "ImageCore", "ImageFiltering", "ImageMorphology", "LinearAlgebra", "MetaGraphs", "RegionTrees", "SimpleWeightedGraphs", "StaticArrays", "Statistics"]
git-tree-sha1 = "7196039573b6f312864547eb7a74360d6c0ab8e6"
uuid = "80713f31-8817-5129-9cf8-209ff8fb23e1"
version = "1.9.0"

[[deps.ImageShow]]
deps = ["Base64", "ColorSchemes", "FileIO", "ImageBase", "ImageCore", "OffsetArrays", "StackViews"]
git-tree-sha1 = "3b5344bcdbdc11ad58f3b1956709b5b9345355de"
uuid = "4e3cecfd-b093-5904-9786-8bbb286a6a31"
version = "0.3.8"

[[deps.ImageTransformations]]
deps = ["AxisAlgorithms", "CoordinateTransformations", "ImageBase", "ImageCore", "Interpolations", "OffsetArrays", "Rotations", "StaticArrays"]
git-tree-sha1 = "dfde81fafbe5d6516fb864dc79362c5c6b973c82"
uuid = "02fcd773-0e25-5acc-982a-7f6622650795"
version = "0.10.2"

[[deps.Images]]
deps = ["Base64", "FileIO", "Graphics", "ImageAxes", "ImageBase", "ImageBinarization", "ImageContrastAdjustment", "ImageCore", "ImageCorners", "ImageDistances", "ImageFiltering", "ImageIO", "ImageMagick", "ImageMetadata", "ImageMorphology", "ImageQualityIndexes", "ImageSegmentation", "ImageShow", "ImageTransformations", "IndirectArrays", "IntegralArrays", "Random", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "StatsBase", "TiledIteration"]
git-tree-sha1 = "a49b96fd4a8d1a9a718dfd9cde34c154fc84fcd5"
uuid = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
version = "0.26.2"

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

[[deps.IntegerMathUtils]]
git-tree-sha1 = "b8ffb903da9f7b8cf695a8bead8e01814aa24b30"
uuid = "18e54dd8-cb9d-406c-a71d-865a43cbb235"
version = "0.1.2"

[[deps.IntegralArrays]]
deps = ["ColorTypes", "FixedPointNumbers", "IntervalSets"]
git-tree-sha1 = "b842cbff3f44804a84fda409745cc8f04c029a20"
uuid = "1d092043-8f09-5a30-832f-7509e371ab51"
version = "0.1.6"

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
git-tree-sha1 = "79342df41c3c24664e5bf29395cfdf2f2a599412"
uuid = "d1acc4aa-44c8-5952-acd4-ba5d80a2a253"
version = "0.22.36"

    [deps.IntervalArithmetic.extensions]
    IntervalArithmeticArblibExt = "Arblib"
    IntervalArithmeticDiffRulesExt = "DiffRules"
    IntervalArithmeticForwardDiffExt = "ForwardDiff"
    IntervalArithmeticIntervalSetsExt = "IntervalSets"
    IntervalArithmeticLinearAlgebraExt = "LinearAlgebra"
    IntervalArithmeticRecipesBaseExt = "RecipesBase"
    IntervalArithmeticSparseArraysExt = "SparseArrays"

    [deps.IntervalArithmetic.weakdeps]
    Arblib = "fb37089c-8514-4489-9461-98f9c8763369"
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

[[deps.JLD2]]
deps = ["FileIO", "MacroTools", "Mmap", "OrderedCollections", "PrecompileTools", "ScopedValues", "TranscodingStreams"]
git-tree-sha1 = "d97791feefda45729613fafeccc4fbef3f539151"
uuid = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
version = "0.5.15"
weakdeps = ["UnPack"]

    [deps.JLD2.extensions]
    UnPackExt = "UnPack"

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

[[deps.JSON3]]
deps = ["Dates", "Mmap", "Parsers", "PrecompileTools", "StructTypes", "UUIDs"]
git-tree-sha1 = "411eccfe8aba0814ffa0fdf4860913ed09c34975"
uuid = "0f8b85d8-7281-11e9-16c2-39a750bddbf1"
version = "1.14.3"

    [deps.JSON3.extensions]
    JSON3ArrowExt = ["ArrowTypes"]

    [deps.JSON3.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.Jieko]]
deps = ["ExproniconLite"]
git-tree-sha1 = "2f05ed29618da60c06a87e9c033982d4f71d0b6c"
uuid = "ae98c720-c025-4a4a-838c-29b094483192"
version = "0.2.1"

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

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "7d703202e65efa1369de1279c162b915e245eed1"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.9"

[[deps.Krylov]]
deps = ["LinearAlgebra", "Printf", "SparseArrays"]
git-tree-sha1 = "b94257a1a8737099ca40bc7271a8b374033473ed"
uuid = "ba0b0d4f-ebba-5204-a429-3ac8c609bfb7"
version = "0.10.1"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "170b660facf5df5de098d866564877e119141cbd"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.2+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "Preferences", "Printf", "Unicode"]
git-tree-sha1 = "9c7c721cfd800d87d48c745d8bfb65144f0a91df"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "9.4.2"

    [deps.LLVM.extensions]
    BFloat16sExt = "BFloat16s"

    [deps.LLVM.weakdeps]
    BFloat16s = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"

[[deps.LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "2ea068aac1e7f0337d381b0eae3110581e3f3216"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.37+2"

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
git-tree-sha1 = "4f34eaabe49ecb3fb0d58d6015e32fd31a733199"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.16.8"

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

[[deps.LayoutPointers]]
deps = ["ArrayInterface", "LinearAlgebra", "ManualMemory", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "a9eaadb366f5493a5654e843864c13d8b107548c"
uuid = "10f19ff3-798f-405d-979b-55457f8fc047"
version = "0.1.17"

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

[[deps.LibTracyClient_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d2bc4e1034b2d43076b50f0e34ea094c2cb0a717"
uuid = "ad6e5548-8b26-5c9f-8ef3-ef0ad883f3a5"
version = "0.9.1+6"

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
git-tree-sha1 = "a31572773ac1b745e0343fe5e2c8ddda7a37e997"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.41.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "XZ_jll", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "2da088d113af58221c52828a80378e16be7d037a"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.5.1+1"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "321ccef73a96ba828cd51f2ab5b9f917fa73945a"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.41.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
version = "1.11.0"

[[deps.LittleCMS_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll"]
git-tree-sha1 = "fa7fd067dca76cadd880f1ca937b4f387975a9f5"
uuid = "d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"
version = "2.16.0+0"

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

[[deps.LoopVectorization]]
deps = ["ArrayInterface", "CPUSummary", "CloseOpenIntervals", "DocStringExtensions", "HostCPUFeatures", "IfElse", "LayoutPointers", "LinearAlgebra", "OffsetArrays", "PolyesterWeave", "PrecompileTools", "SIMDTypes", "SLEEFPirates", "Static", "StaticArrayInterface", "ThreadingUtilities", "UnPack", "VectorizationBase"]
git-tree-sha1 = "e5afce7eaf5b5ca0d444bcb4dc4fd78c54cbbac0"
uuid = "bdcacae8-1622-11e9-2a5c-532679323890"
version = "0.12.172"
weakdeps = ["ChainRulesCore", "ForwardDiff", "SpecialFunctions"]

    [deps.LoopVectorization.extensions]
    ForwardDiffExt = ["ChainRulesCore", "ForwardDiff"]
    SpecialFunctionsExt = "SpecialFunctions"

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
deps = ["Animations", "Base64", "CRC32c", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "ComputePipeline", "Contour", "Dates", "DelaunayTriangulation", "Distributions", "DocStringExtensions", "Downloads", "FFMPEG_jll", "FileIO", "FilePaths", "FixedPointNumbers", "Format", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageBase", "ImageIO", "InteractiveUtils", "Interpolations", "IntervalSets", "InverseFunctions", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MacroTools", "Markdown", "MathTeXEngine", "Observables", "OffsetArrays", "PNGFiles", "Packing", "Pkg", "PlotUtils", "PolygonOps", "PrecompileTools", "Printf", "REPL", "Random", "RelocatableFolders", "Scratch", "ShaderAbstractions", "Showoff", "SignedDistanceFields", "SparseArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "TriplotBase", "UnicodeFun", "Unitful"]
git-tree-sha1 = "2928d52e1737965fd63c23fdef49cb51577068c4"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.24.2"

[[deps.ManualMemory]]
git-tree-sha1 = "bcaef4fc7a0cfe2cba636d84cda54b5e4e4ca3cd"
uuid = "d125e4d3-2237-4719-b19c-fa641b8a4667"
version = "0.1.8"

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
git-tree-sha1 = "6e64d2321257cc52f47e193407d0659ea1b2b431"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.6.5"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Memoize]]
deps = ["MacroTools"]
git-tree-sha1 = "2b1dfcba103de714d31c033b5dacc2e4a12c7caa"
uuid = "c03570c3-d221-55d1-a50c-7939bbd78826"
version = "0.4.4"

[[deps.MetaGraphs]]
deps = ["Graphs", "JLD2", "Random"]
git-tree-sha1 = "e9650bea7f91c3397eb9ae6377343963a22bf5b8"
uuid = "626554b9-1ddb-594c-aa3c-2596fe9399a5"
version = "0.8.0"

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

[[deps.Moshi]]
deps = ["ExproniconLite", "Jieko"]
git-tree-sha1 = "d5198869af7a8aec7354dc8559ae71aba77a625a"
uuid = "2e0e35c7-a2e4-4343-998d-7ef72827ed2d"
version = "0.3.6"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.12.12"

[[deps.MultivariatePolynomials]]
deps = ["ChainRulesCore", "DataStructures", "LinearAlgebra", "MutableArithmetics"]
git-tree-sha1 = "fade91fe9bee7b142d332fc6ab3f0deea29f637b"
uuid = "102ac46a-7ee4-5c85-9060-abc95bfdeaa3"
version = "0.5.9"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "491bdcdc943fcbc4c005900d7463c9f216aabf4c"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.6.4"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "9b8215b1ee9e78a293f99797cd31375471b2bcae"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.1.3"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "8a3271d8309285f4db73b4f662b1b290c715e85e"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.21"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore", "ImageMetadata"]
git-tree-sha1 = "d92b107dbb887293622df7697a2223f9f8176fcd"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.1.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.ObjectFile]]
deps = ["Reexport", "StructIO"]
git-tree-sha1 = "09b1fe6ff16e6587fa240c165347474322e77cf1"
uuid = "d8793406-e978-5875-9003-1fc021f44a92"
version = "0.4.4"

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

[[deps.OpenJpeg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libtiff_jll", "LittleCMS_jll", "libpng_jll"]
git-tree-sha1 = "7dc7028a10d1408e9103c0a77da19fdedce4de6c"
uuid = "643b3616-a352-519d-856d-80112ee9badc"
version = "2.5.4+0"

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
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+1"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "f07c06228a1c670ae4c87d1276b92c7c597fdda0"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.35"

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
git-tree-sha1 = "275a9a6d85dc86c24d03d1837a0010226a96f540"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.56.3+0"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

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

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "Latexify", "Markdown", "PlutoUI"]
git-tree-sha1 = "537c439831c0f8d37265efe850ee5c0d9c7efbe4"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.4.1"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "2b2127e64c1221b8204afe4eb71662b641f33b82"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.66"

[[deps.PolyesterWeave]]
deps = ["BitTwiddlingConvenienceFunctions", "CPUSummary", "IfElse", "Static", "ThreadingUtilities"]
git-tree-sha1 = "645bed98cd47f72f67316fd42fc47dee771aefcd"
uuid = "1d0040c9-8b98-4ee7-8388-3f51789ca0ad"
version = "0.2.2"

[[deps.PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

[[deps.Polynomials]]
deps = ["LinearAlgebra", "OrderedCollections", "RecipesBase", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "972089912ba299fba87671b025cd0da74f5f54f7"
uuid = "f27b6e38-b328-58d1-80ce-0feddd5e7a45"
version = "4.1.0"
weakdeps = ["ChainRulesCore", "FFTW", "Makie", "MutableArithmetics"]

    [deps.Polynomials.extensions]
    PolynomialsChainRulesCoreExt = "ChainRulesCore"
    PolynomialsFFTWExt = "FFTW"
    PolynomialsMakieExt = "Makie"
    PolynomialsMutableArithmeticsExt = "MutableArithmetics"

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

[[deps.Primes]]
deps = ["IntegerMathUtils"]
git-tree-sha1 = "25cdd1d20cd005b52fc12cb6be3f75faaf59bb9b"
uuid = "27ebfcd6-29c5-5fa9-bf4b-fb8fc14df3ae"
version = "0.5.7"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"
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
weakdeps = ["Enzyme"]

    [deps.QuadGK.extensions]
    QuadGKEnzymeExt = "Enzyme"

[[deps.Quaternions]]
deps = ["LinearAlgebra", "Random", "RealDot"]
git-tree-sha1 = "994cc27cdacca10e68feb291673ec3a76aa2fae9"
uuid = "94ee1d12-ae83-5a48-8b1c-48b8ff168ae0"
version = "0.7.6"

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

[[deps.RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecursiveArrayTools]]
deps = ["Adapt", "ArrayInterface", "DocStringExtensions", "GPUArraysCore", "IteratorInterfaceExtensions", "LinearAlgebra", "RecipesBase", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface", "Tables"]
git-tree-sha1 = "2e154f7d7e38db1af0a14ec751aba33360c3bef9"
uuid = "731186ca-8d62-57ce-b412-fbd966d074cd"
version = "3.33.0"

    [deps.RecursiveArrayTools.extensions]
    RecursiveArrayToolsFastBroadcastExt = "FastBroadcast"
    RecursiveArrayToolsForwardDiffExt = "ForwardDiff"
    RecursiveArrayToolsMeasurementsExt = "Measurements"
    RecursiveArrayToolsMonteCarloMeasurementsExt = "MonteCarloMeasurements"
    RecursiveArrayToolsReverseDiffExt = ["ReverseDiff", "Zygote"]
    RecursiveArrayToolsSparseArraysExt = ["SparseArrays"]
    RecursiveArrayToolsStructArraysExt = "StructArrays"
    RecursiveArrayToolsTrackerExt = "Tracker"
    RecursiveArrayToolsZygoteExt = "Zygote"

    [deps.RecursiveArrayTools.weakdeps]
    FastBroadcast = "7034ab61-46d4-4ed7-9d0f-46aef9175898"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7"
    MonteCarloMeasurements = "0987c9cc-fe09-11e8-30f0-b96dd679fdca"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StructArrays = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RegionTrees]]
deps = ["IterTools", "LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "4618ed0da7a251c7f92e869ae1a19c74a7d2a7f9"
uuid = "dee08c22-ab7f-5625-9660-a9af2021b33f"
version = "0.3.2"

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
git-tree-sha1 = "852bd0f55565a9e973fcfee83a84413270224dc4"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.8.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "58cdd8fb2201a6267e1db87ff148dd6c1dbd8ad8"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.5.1+0"

[[deps.Rotations]]
deps = ["LinearAlgebra", "Quaternions", "Random", "StaticArrays"]
git-tree-sha1 = "5680a9276685d392c87407df00d57c9924d9f11e"
uuid = "6038ab10-8711-5258-84ad-4b1120ba62dc"
version = "1.7.1"
weakdeps = ["RecipesBase"]

    [deps.Rotations.extensions]
    RotationsRecipesBaseExt = "RecipesBase"

[[deps.RoundingEmulator]]
git-tree-sha1 = "40b9edad2e5287e05bd413a38f61a8ff55b9557b"
uuid = "5eaf0fd0-dfba-4ccb-bf02-d820a40db705"
version = "0.2.1"

[[deps.RuntimeGeneratedFunctions]]
deps = ["ExprTools", "SHA", "Serialization"]
git-tree-sha1 = "86a8a8b783481e1ea6b9c91dd949cb32191f8ab4"
uuid = "7e49a35a-f44a-4d26-94aa-eba1b4ca6b47"
version = "0.5.15"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
deps = ["PrecompileTools"]
git-tree-sha1 = "fea870727142270bdf7624ad675901a1ee3b4c87"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.7.1"

[[deps.SIMDTypes]]
git-tree-sha1 = "330289636fb8107c5f32088d2741e9fd7a061a5c"
uuid = "94e857df-77ce-4151-89e5-788b33177be4"
version = "0.1.0"

[[deps.SLEEFPirates]]
deps = ["IfElse", "Static", "VectorizationBase"]
git-tree-sha1 = "456f610ca2fbd1c14f5fcf31c6bfadc55e7d66e0"
uuid = "476501e8-09a2-5ece-8869-fb82de89a1fa"
version = "0.6.43"

[[deps.SciMLBase]]
deps = ["ADTypes", "Accessors", "Adapt", "ArrayInterface", "CommonSolve", "ConstructionBase", "Distributed", "DocStringExtensions", "EnumX", "FunctionWrappersWrappers", "IteratorInterfaceExtensions", "LinearAlgebra", "Logging", "Markdown", "Moshi", "PrecompileTools", "Preferences", "Printf", "RecipesBase", "RecursiveArrayTools", "Reexport", "RuntimeGeneratedFunctions", "SciMLOperators", "SciMLStructures", "StaticArraysCore", "Statistics", "SymbolicIndexingInterface"]
git-tree-sha1 = "31587e20cdea9fba3a689033313e658dfc9aae78"
uuid = "0bca4576-84f4-4d90-8ffe-ffa030f20462"
version = "2.102.1"

    [deps.SciMLBase.extensions]
    SciMLBaseChainRulesCoreExt = "ChainRulesCore"
    SciMLBaseMLStyleExt = "MLStyle"
    SciMLBaseMakieExt = "Makie"
    SciMLBasePartialFunctionsExt = "PartialFunctions"
    SciMLBasePyCallExt = "PyCall"
    SciMLBasePythonCallExt = "PythonCall"
    SciMLBaseRCallExt = "RCall"
    SciMLBaseZygoteExt = ["Zygote", "ChainRulesCore"]

    [deps.SciMLBase.weakdeps]
    ChainRules = "082447d4-558c-5d27-93f4-14fc19e9eca2"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    MLStyle = "d8e11817-5142-5d16-987a-aa16d5891078"
    Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
    PartialFunctions = "570af359-4316-4cb7-8c74-252c00c2016b"
    PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
    PythonCall = "6099a3de-0909-46bc-b1f4-468b9a2dfc0d"
    RCall = "6f49c342-dc21-5d91-9882-a32aef131414"
    Zygote = "e88e6eb3-aa80-5325-afca-941959d7151f"

[[deps.SciMLOperators]]
deps = ["Accessors", "ArrayInterface", "DocStringExtensions", "LinearAlgebra", "MacroTools"]
git-tree-sha1 = "3249fe77f322fe539e935ecb388c8290cd38a3fc"
uuid = "c0aeaf25-5076-4817-a8d5-81caf7dfa961"
version = "1.3.1"
weakdeps = ["SparseArrays", "StaticArraysCore"]

    [deps.SciMLOperators.extensions]
    SciMLOperatorsSparseArraysExt = "SparseArrays"
    SciMLOperatorsStaticArraysCoreExt = "StaticArraysCore"

[[deps.SciMLStructures]]
deps = ["ArrayInterface"]
git-tree-sha1 = "566c4ed301ccb2a44cbd5a27da5f885e0ed1d5df"
uuid = "53ae85a6-f571-4167-b2af-e1d143709226"
version = "1.7.0"

[[deps.ScopedValues]]
deps = ["HashArrayMappedTries", "Logging"]
git-tree-sha1 = "1147f140b4c8ddab224c94efa9569fc23d63ab44"
uuid = "7e506255-f358-4e82-b7e4-beb19740aa63"
version = "1.3.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "9b81b8393e50b7d4e6d0a9f14e192294d3b7c109"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.3.0"

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

[[deps.ShortCodes]]
deps = ["Base64", "CodecZlib", "Downloads", "JSON3", "Memoize", "URIs", "UUIDs"]
git-tree-sha1 = "5844ee60d9fd30a891d48bab77ac9e16791a0a57"
uuid = "f62ebe17-55c5-4640-972f-b59c0dd11ccf"
version = "0.3.6"

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

[[deps.SimpleWeightedGraphs]]
deps = ["Graphs", "LinearAlgebra", "Markdown", "SparseArrays"]
git-tree-sha1 = "3e5f165e58b18204aed03158664c4982d691f454"
uuid = "47aef6b3-ad0c-573a-a1e2-d07658019622"
version = "1.5.0"

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
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.11.0"

[[deps.SparseConnectivityTracer]]
deps = ["ADTypes", "DocStringExtensions", "FillArrays", "LinearAlgebra", "Random", "SparseArrays"]
git-tree-sha1 = "182990067a09adf950274f97f38f68c76f81d2d0"
uuid = "9f842d2f-2579-4b1d-911e-f412cf18a3f5"
version = "0.6.21"

    [deps.SparseConnectivityTracer.extensions]
    SparseConnectivityTracerDataInterpolationsExt = "DataInterpolations"
    SparseConnectivityTracerLogExpFunctionsExt = "LogExpFunctions"
    SparseConnectivityTracerNNlibExt = "NNlib"
    SparseConnectivityTracerNaNMathExt = "NaNMath"
    SparseConnectivityTracerSpecialFunctionsExt = "SpecialFunctions"

    [deps.SparseConnectivityTracer.weakdeps]
    DataInterpolations = "82cc6244-b520-54b8-b5a6-8a565e85f1d0"
    LogExpFunctions = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
    NNlib = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
    NaNMath = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"

[[deps.SparseMatrixColorings]]
deps = ["ADTypes", "DocStringExtensions", "LinearAlgebra", "PrecompileTools", "Random", "SparseArrays"]
git-tree-sha1 = "9de43e0b9b976f1019bf7a879a686c4514520078"
uuid = "0a514795-09f3-496d-8182-132a7b665d35"
version = "0.4.21"

    [deps.SparseMatrixColorings.extensions]
    SparseMatrixColoringsCUDAExt = "CUDA"
    SparseMatrixColoringsCliqueTreesExt = "CliqueTrees"
    SparseMatrixColoringsColorsExt = "Colors"

    [deps.SparseMatrixColorings.weakdeps]
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    CliqueTrees = "60701a23-6482-424a-84db-faee86b9b1f8"
    Colors = "5ae59095-9a9b-59fe-a467-6f913c188581"

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
git-tree-sha1 = "95af145932c2ed859b63329952ce8d633719f091"
uuid = "860ef19b-820b-49d6-a774-d7a799459cd3"
version = "1.0.3"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "be1cf4eb0ac528d96f5115b4ed80c26a8d8ae621"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.2"

[[deps.Static]]
deps = ["CommonWorldInvalidations", "IfElse", "PrecompileTools"]
git-tree-sha1 = "f737d444cb0ad07e61b3c1bef8eb91203c321eff"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "1.2.0"

[[deps.StaticArrayInterface]]
deps = ["ArrayInterface", "Compat", "IfElse", "LinearAlgebra", "PrecompileTools", "Static"]
git-tree-sha1 = "96381d50f1ce85f2663584c8e886a6ca97e60554"
uuid = "0d7ed370-da01-4f52-bd93-41d350b8b718"
version = "1.8.0"
weakdeps = ["OffsetArrays", "StaticArrays"]

    [deps.StaticArrayInterface.extensions]
    StaticArrayInterfaceOffsetArraysExt = "OffsetArrays"
    StaticArrayInterfaceStaticArraysExt = "StaticArrays"

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
git-tree-sha1 = "9d72a13a3f4dd3795a195ac5a44d7d6ff5f552ff"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.1"

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

[[deps.StringManipulation]]
deps = ["PrecompileTools"]
git-tree-sha1 = "725421ae8e530ec29bcbdddbe91ff8053421d023"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.4.1"

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

[[deps.StructIO]]
git-tree-sha1 = "c581be48ae1cbf83e899b14c07a807e1787512cc"
uuid = "53d494c1-5632-5724-8f4c-31dff12d585f"
version = "0.3.1"

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "159331b30e94d7b11379037feeb9b690950cace8"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
version = "1.11.0"

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

[[deps.SymbolicIndexingInterface]]
deps = ["Accessors", "ArrayInterface", "PrettyTables", "RuntimeGeneratedFunctions", "StaticArraysCore"]
git-tree-sha1 = "658f6d01bfe68d6bf47915bf5d868228138c7d71"
uuid = "2efcf032-c050-4f8e-a9bb-153293bab1f5"
version = "0.3.41"

[[deps.SymbolicLimits]]
deps = ["SymbolicUtils"]
git-tree-sha1 = "fabf4650afe966a2ba646cabd924c3fd43577fc3"
uuid = "19f23fe9-fdab-4a78-91af-e7b7767979c3"
version = "0.2.2"

[[deps.SymbolicUtils]]
deps = ["AbstractTrees", "ArrayInterface", "Bijections", "ChainRulesCore", "Combinatorics", "ConstructionBase", "DataStructures", "DocStringExtensions", "DynamicPolynomials", "ExproniconLite", "LinearAlgebra", "MultivariatePolynomials", "NaNMath", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArrays", "SymbolicIndexingInterface", "TaskLocalValues", "TermInterface", "TimerOutputs", "Unityper", "WeakValueDicts"]
git-tree-sha1 = "fa63e8f55e99aee528951ba26544403b09645979"
uuid = "d1185830-fcd6-423d-90d6-eec64667417b"
version = "3.29.0"

    [deps.SymbolicUtils.extensions]
    SymbolicUtilsLabelledArraysExt = "LabelledArrays"
    SymbolicUtilsReverseDiffExt = "ReverseDiff"

    [deps.SymbolicUtils.weakdeps]
    LabelledArrays = "2ee39098-c373-598a-b85f-a56591580800"
    ReverseDiff = "37e2e3b7-166d-5795-8a7a-e32c996b4267"

[[deps.Symbolics]]
deps = ["ADTypes", "ArrayInterface", "Bijections", "CommonWorldInvalidations", "ConstructionBase", "DataStructures", "DiffRules", "Distributions", "DocStringExtensions", "DomainSets", "DynamicPolynomials", "LaTeXStrings", "Latexify", "Libdl", "LinearAlgebra", "LogExpFunctions", "MacroTools", "Markdown", "NaNMath", "OffsetArrays", "PrecompileTools", "Primes", "RecipesBase", "Reexport", "RuntimeGeneratedFunctions", "SciMLBase", "Setfield", "SparseArrays", "SpecialFunctions", "StaticArraysCore", "SymbolicIndexingInterface", "SymbolicLimits", "SymbolicUtils", "TermInterface"]
git-tree-sha1 = "df665535546bb07078ee42e0972527b5d6bd3f69"
uuid = "0c5d862f-8b57-4792-8d23-62f2024744c7"
version = "6.43.0"

    [deps.Symbolics.extensions]
    SymbolicsForwardDiffExt = "ForwardDiff"
    SymbolicsGroebnerExt = "Groebner"
    SymbolicsLuxExt = "Lux"
    SymbolicsNemoExt = "Nemo"
    SymbolicsPreallocationToolsExt = ["PreallocationTools", "ForwardDiff"]
    SymbolicsSymPyExt = "SymPy"

    [deps.Symbolics.weakdeps]
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    Groebner = "0b43b601-686d-58a3-8a1c-6623616c7cd4"
    Lux = "b2108857-7c20-44ae-9111-449ecde12c47"
    Nemo = "2edaba10-b0f1-5616-af89-8c11ac63239a"
    PreallocationTools = "d236fae5-4411-538c-8e31-a6e3d9e00b46"
    SymPy = "24249f21-da20-56a4-8eb1-6a02cf4ae2e6"

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

[[deps.TaskLocalValues]]
git-tree-sha1 = "d155450e6dff2a8bc2fcb81dcb194bd98b0aeb46"
uuid = "ed4db957-447d-4319-bfb6-7fa9ae7ecf34"
version = "0.1.2"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.TermInterface]]
git-tree-sha1 = "d673e0aca9e46a2f63720201f55cc7b3e7169b16"
uuid = "8ea1fca8-c5ef-4a55-8b96-4e9afe9c9a3c"
version = "2.0.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.ThreadingUtilities]]
deps = ["ManualMemory"]
git-tree-sha1 = "d969183d3d244b6c33796b5ed01ab97328f2db85"
uuid = "8290d209-cae3-49c0-8002-c8c24d57dab5"
version = "0.5.5"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "PrecompileTools", "ProgressMeter", "SIMD", "UUIDs"]
git-tree-sha1 = "02aca429c9885d1109e58f400c333521c13d48a0"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.11.4"

[[deps.TiledIteration]]
deps = ["OffsetArrays", "StaticArrayInterface"]
git-tree-sha1 = "1176cc31e867217b06928e2f140c90bd1bc88283"
uuid = "06e1c1a7-607b-532d-9fad-de7d9aa2abac"
version = "0.5.0"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "3748bd928e68c7c346b52125cf41fff0de6937d0"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.29"

    [deps.TimerOutputs.extensions]
    FlameGraphsExt = "FlameGraphs"

    [deps.TimerOutputs.weakdeps]
    FlameGraphs = "08572546-2f56-4bcf-ba4e-bab62c3a3f89"

[[deps.Tracy]]
deps = ["ExprTools", "LibTracyClient_jll", "Libdl"]
git-tree-sha1 = "91dbaee0f50faa4357f7e9fc69442c7b6364dfe5"
uuid = "e689c965-62c8-4b79-b2c5-8359227902fd"
version = "0.1.5"

    [deps.Tracy.extensions]
    TracyProfilerExt = "TracyProfiler_jll"

    [deps.Tracy.weakdeps]
    TracyProfiler_jll = "0c351ed6-8a68-550e-8b79-de6f926da83c"

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
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"
version = "1.11.0"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

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
git-tree-sha1 = "d2282232f8a4d71f79e85dc4dd45e5b12a6297fb"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.23.1"
weakdeps = ["ConstructionBase", "ForwardDiff", "InverseFunctions", "Printf"]

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    ForwardDiffExt = "ForwardDiff"
    InverseFunctionsUnitfulExt = "InverseFunctions"
    PrintfExt = "Printf"

[[deps.Unityper]]
deps = ["ConstructionBase"]
git-tree-sha1 = "25008b734a03736c41e2a7dc314ecb95bd6bbdb0"
uuid = "a7c27f48-0311-42f6-a7f8-2c11e75eb415"
version = "0.1.6"

[[deps.VectorizationBase]]
deps = ["ArrayInterface", "CPUSummary", "HostCPUFeatures", "IfElse", "LayoutPointers", "Libdl", "LinearAlgebra", "SIMDTypes", "Static", "StaticArrayInterface"]
git-tree-sha1 = "4ab62a49f1d8d9548a1c8d1a75e5f55cf196f64e"
uuid = "3d5dd08c-fd9d-11e8-17fa-ed2836048c2f"
version = "0.21.71"

[[deps.WeakValueDicts]]
git-tree-sha1 = "98528c2610a5479f091d470967a25becfd83edd0"
uuid = "897b6980-f191-5a31-bcb0-bf3c4585e0c1"
version = "0.1.0"

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
git-tree-sha1 = "cd155272a3738da6db765745b89e466fa64d0830"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.49+0"

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
git-tree-sha1 = "ccbb625a89ec6195856a50aa2b668a5c08712c94"
uuid = "c5f90fcd-3b7e-5836-afba-fc50a0988cb2"
version = "1.4.0+0"

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
# ╠═e46cb298-35b9-4764-a867-795bbc5a0943
# ╠═6a1c41ab-76df-4e0f-bdf9-1e71506ba45d
# ╠═5ae4d0c3-c5da-4b90-8fab-2cd4a2f0b44a
# ╟─feb264fa-e282-40e8-ac69-eb4763945966
# ╟─c78a2897-7015-46d9-bfc0-9a31c3814050
# ╟─9f020c74-ce3b-4d6d-987f-40495cde0a61
# ╟─b537e53f-ebf8-4f22-adb4-77006c0f58d8
# ╟─84031796-be2e-4870-bb7e-e6c49134e329
# ╟─ce8b7f71-fc5e-412f-8a28-eb865bd98e03
# ╟─e56c9cab-5908-4838-aba7-09623577d164
# ╟─cbe34351-4ae5-440a-b2ae-dcd01757cede
# ╟─38880563-84ea-4b7a-84ac-0e4c6edf9b56
# ╟─852f5bd4-1661-4893-ab4d-93dd9bc96172
# ╟─fd5fae86-30c1-469d-84a4-2f37c2895be8
# ╟─53f32ad8-cbbd-447a-93f4-b39ac3cbb97e
# ╟─8f771594-fdf4-4343-9da9-5193b1d79432
# ╟─5e2c6a2a-beb5-4fd3-b686-f5b8b365548b
# ╟─66508521-3e17-4707-8159-b1ff7a8e2549
# ╟─82ee211e-db21-4f88-8eec-a78fa402ce84
# ╟─b36665f2-fdee-40fd-b814-980fa19a71ae
# ╠═a247217c-cf59-4ec1-bbc4-706b1204ee8b
# ╠═5c313ce8-dbae-4c82-b1b0-dafa3ea78f6d
# ╠═14b8e99b-fd2b-418f-b657-18c47c9c1cc1
# ╟─8af45e55-e782-479d-b063-6afa3543bcfb
# ╟─233a7f9e-a27c-4fa0-8d04-a749bbf6f48b
# ╟─3ab03b6f-1791-46a5-80d9-fc043e2e08c6
# ╟─6954e48d-0673-4f47-aec0-c4ddb1270219
# ╟─fd6d557e-3c42-49aa-9fce-256c69ae0b9f
# ╠═90bf3931-e67f-40db-9474-ab5f2ba68c22
# ╠═dc707823-9fac-470e-9ea4-ed5b38a07bb4
# ╟─0387e199-253f-4dc9-81fb-adfed2dbd0c3
# ╠═3e28b98b-eed1-4e45-814c-9d82e6655fb0
# ╠═02ee5f29-97dd-4dae-a733-7d9d8bec171e
# ╟─9c07e655-1cfb-46a9-af8c-25e07cbf3f86
# ╠═13037903-cd23-4da7-b8cd-dbb6771aa050
# ╠═34e0c0bc-4877-4a02-8210-c53f8d64def4
# ╟─9b581c58-b184-4d06-a9a7-08ebef24cdb0
# ╟─27d74eac-700f-4325-9869-0c6f43463c8b
# ╠═0b554dea-3ad2-414a-a7a7-c9e694002b76
# ╟─dc46096e-28bc-49c2-ae57-670f72521b36
# ╠═2b0564a9-422d-4ba6-b867-4a902b8f844c
# ╠═5232357a-2d86-45e9-8591-7c4a379db12a
# ╟─200b7150-d062-497c-a0c0-ea12856d16a8
# ╠═f0514e8e-b97a-496f-ad9f-87300ed5c52d
# ╠═5cd872fe-71cc-46a8-88df-829c4de9c939
# ╟─77c85b86-c0cc-443c-8aa2-58f0abac3214
# ╠═36c84cde-b7c2-43a5-bb0e-8fae0552f8e2
# ╟─45c0c3f2-de06-4161-85fd-b8adaac56a75
# ╠═c5ba102c-b475-47c9-bd68-fb66473f96e0
# ╠═0aff3351-9e5f-4e67-80c7-487569b1263c
# ╟─a5698629-68b8-4b68-b8e5-d636c4062589
# ╠═13a29b0c-0aa9-4884-9ceb-f17067ab5cd8
# ╠═148dc2b8-b478-45b8-8599-3f3b908040dd
# ╟─ab0067f3-bfae-4f42-ba39-9e1bfdedf1f7
# ╠═e27f6b76-aebf-4319-b9b6-f92ea7f48347
# ╠═5fbe74c0-230d-4365-8282-2799b672494f
# ╟─2b1c4518-82ee-400b-923c-038679bf655f
# ╠═ee746ffa-54c9-4a89-adeb-89c9b7c9833e
# ╠═d61dbc33-6d1a-48ba-9489-693bb3700ae3
# ╟─11af8ae0-df28-438f-b8a7-2e235dcdef10
# ╠═8a897616-cd77-45af-a541-13a76e9eb8e7
# ╠═cc515126-9e3d-48a8-b5d4-b29bb507aa4b
# ╠═d1de4440-df3e-4475-b058-dd3cd56e536b
# ╠═765975a1-7a8b-46b8-b11a-e2bc2b35b5f0
# ╟─57087fe7-9eb1-4c9b-acb0-c6f3639bcf2c
# ╟─5e4d567b-3a53-44dc-ac3e-bfb792509d21
# ╠═19ea9417-208f-4f2c-8351-39d787ec33c9
# ╟─1450b827-bc0d-452f-9c5c-493a510395a4
# ╟─8576cbbd-4fe7-414e-b5a8-3c8d5ee11655
# ╠═bf1ec46d-35ac-4c67-b18c-67ddbbf85c13
# ╟─a6e1f10e-0072-4ce5-b8b9-80e46cc9cd9f
# ╠═cfba8fa5-9a7f-46a5-9f19-e909f268f502
# ╠═51a63a0a-a11b-4f53-a197-9dffabf6ad0c
# ╟─858b0569-b45b-4584-88c3-7f003f1f6ad3
# ╠═5120e1b4-6ae1-4074-812e-ff34d9bad60e
# ╠═d4ae507b-8ebd-4ff9-aa28-7ec2692c09b6
# ╟─ccfb8431-ef72-46b7-9e40-6005ea5f06be
# ╟─6d788dbe-b589-45ac-9e1c-56b42164c1c2
# ╠═aff4afb2-6b42-4765-9100-3f142be71698
# ╠═1cbfbf39-f916-4082-8a52-7a711739504f
# ╟─14979edc-2c15-4bab-8890-6eaf97a225da
# ╠═abeb91fd-545c-4b1e-ad83-499155df9bf6
# ╟─3c01bfdb-b44a-42e4-9438-04a00e457a20
# ╟─4d2c3b3e-f080-4c85-b269-cf9a44039df7
# ╠═82b7a36d-d9cf-4050-bdb5-1db892ff853e
# ╠═7555281f-f08c-43f3-89ea-4e33fbc715cf
# ╠═beebeee4-9ace-48cb-a199-054db91b0821
# ╠═f086d449-9910-42ec-9cf8-22061b71554a
# ╠═1bc022af-5cac-4126-bb57-32ee79ff3a03
# ╠═c4c3a3e8-163c-4755-af61-e8f228aeedd6
# ╟─fc94e961-7ef5-4063-afb3-831bdc244fb4
# ╠═23601c7e-7bba-4d0f-a735-d9cf68df0d19
# ╠═2f5021bc-6ff8-499f-b4c7-9c10a9f6fad4
# ╠═a3a637e0-d70d-478e-92c1-9a2f1b55c208
# ╠═b7f89c19-9ee9-4bdb-9cef-fa8d565e47e5
# ╟─c17a28bd-5be0-4f0c-9e7e-0d5c96778c86
# ╠═a26d68f5-3a5a-4aa5-9923-3846d0291885
# ╟─13bf6c3a-1f3b-40d7-a7a0-d1e26fb9d613
# ╠═438475e4-84ed-47fc-a32b-28e85894880f
# ╟─f0557ad5-b3cf-4211-83b6-60341350f609
# ╠═0b2a206c-1719-481d-8a72-b6ceb4a9ae5e
# ╠═e6deffa6-b4ce-4e8a-8c38-02e8a8b728d3
# ╠═d5443976-5370-483f-9d80-c9e99bbcc81c
# ╠═a43b052e-feab-49a6-9097-2eb70513953a
# ╟─ccd67810-f1ae-49c5-b11a-201a0ad8f812
# ╠═24a7c06d-8dd1-4016-a809-8816b7fa24e5
# ╟─50c9b1ac-22de-41c6-a15b-8743f01c41d3
# ╟─49ed86ea-8219-4bdd-a8aa-b656ffa24309
# ╠═b12a5cad-5f60-4473-9c64-7731e3d3e1ed
# ╠═cc0ca242-e5f9-4812-bd3b-d6a1ab6cbfc7
# ╟─0a623f3a-9fda-4590-aebb-ca56283dda41
# ╠═775255f7-f322-4ee5-9e2f-48abf91ecf15
# ╟─1258de24-fd40-4a67-b7c0-426dd610e008
# ╠═13cf456c-3960-4101-a273-823c211660fb
# ╟─7548dfdc-a715-49ee-91d6-b11184759fee
# ╠═c18ece26-e2f0-401b-a717-160a14c21d07
# ╠═0cf8867b-2ff6-4f6c-8504-7cf877b28f31
# ╟─e8d5c77b-3045-4d6e-bf2e-a1f6971828f3
# ╟─458dd94e-8bf5-4a91-b56a-e11f40997000
# ╠═d34ccc86-bd36-4afd-9e30-2489a2b88779
# ╠═5a8f68ab-31a9-4f2f-a9e7-aa7b34a2055d
# ╠═01955dbb-3a65-4829-b4c1-ac9f51b152db
# ╠═7a838d91-ae25-484e-bbd6-ba7bee55d1d4
# ╠═4624b3e8-be3b-4e27-92a4-9b071987e8e1
# ╠═824fb368-5f80-4643-9872-8fc8044d900f
# ╠═d25383f8-86f2-45b2-b2a6-cfe29efa7f7e
# ╠═d4657f7f-f992-4196-b6f9-da9b20e2bd2e
# ╠═899e4ead-decb-4cc9-a855-3bad4b01cc8c
# ╠═43eb2a0b-7acc-4ab6-83b4-2dbb3b378983
# ╠═e97858d0-b394-4c85-8de0-71b6b61e49e9
# ╟─c4ddb84b-9439-4e68-8230-4758e2272e88
# ╠═9ef768ba-c5a1-481a-add0-340f0bef982f
# ╠═bcf5e168-ff76-436e-84ba-fd73226a9232
# ╠═dcb6f8c4-bfae-4646-ae98-05eedc193167
# ╠═bb581fc3-57c4-4e27-90ab-56a8a88367f6
# ╠═7531960a-9a51-4950-abdc-112bea3e791e
# ╠═1ce82922-2664-4a08-a47f-5e353e3701cf
# ╠═353fa149-a0ff-4923-a3f0-e115ecdfdf2d
# ╠═3722f5d6-011c-4318-b512-36380269eebb
# ╟─6ec186a8-114b-4f51-9a28-0135e8dc04ac
# ╟─4b7edccf-f98f-47c8-87b0-83e4258166b8
# ╟─3b766814-0397-45f2-b59e-3b3659eb8859
# ╠═8d6aa174-ed55-4fa9-bc8e-efd1abbb8404
# ╠═88f3172f-d031-485d-a49d-0cb19d21ff37
# ╠═77923aa6-939b-400e-8e04-fcd3753f4cbc
# ╠═45e43630-09a5-4d1e-b7d7-cd72eca3d146
# ╠═d8797760-0090-42f5-b297-c119a2ac1727
# ╠═425ee2c7-82b2-4560-b538-1d5b768fd4cd
# ╠═4306dd2d-d831-4358-ad2e-c77ba1be101e
# ╠═50f0d2b8-c26c-495f-a606-88df639557bd
# ╠═fe9db70c-82ad-4fdf-91b7-8280f902fd72
# ╠═23807f7b-a02b-485d-87cc-d7a9dfd4c684
# ╟─53a9d262-a1e9-491e-8e0d-aa1543593b76
# ╠═3166db0b-dcc9-47ad-a4a4-312c83a514d5
# ╠═3c38d5c8-ebc4-45fb-ad85-bf8590c1805c
# ╟─e497a596-e1b5-4eec-9bba-ee4a4fb6f441
# ╠═7b36b0fb-754c-4f75-883d-4efe57a674dd
# ╠═96f27ecd-982e-4377-87db-999492a12707
# ╠═77fd49cb-8d56-4688-8df3-7e19e70da303
# ╠═dbf6bdad-31eb-4414-ba7b-62dfc41ce940
# ╠═5d13b13b-f7e9-4475-9a0d-6a8e13101770
# ╠═28d6817b-3184-4673-ad93-3e1de2cf809a
# ╠═3084f697-3602-484b-b59d-90f830045538
# ╠═761d220d-d926-456a-a23f-85aaa5989ad2
# ╠═4486037a-3d30-4219-9c81-1659dbee4e0c
# ╠═7fef1e26-3ebc-4da1-ba96-ce85e5c1bce0
# ╟─73eca3e1-e3bb-4e38-af4e-9a6d1d65472c
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
