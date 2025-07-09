### A Pluto.jl notebook ###
# v0.20.13

#> [frontmatter]
#> chapter = "5"
#> section = "1"
#> order = "14"
#> title = "Compilers"
#> date = "2025-07-08"
#> tags = ["module5", "track_performance"]
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

# ╔═╡ f1db15d4-9f18-11ee-029a-e51fbd66cfea
begin
	using PlutoUI
	using PlutoTeachingTools
	using ShortCodes
end

# ╔═╡ 2d617f49-8dd4-45be-8e59-b80bc87afa93
using JuliaSyntax

# ╔═╡ b416ea3c-92d0-46b0-bbc0-99b7dfabe328
using IRViz

# ╔═╡ 2324f04a-f7a8-4fa5-85ca-034bdb1b0f03
using BenchmarkTools

# ╔═╡ c3488041-e25e-46f4-95ee-a7aceebbaf38
using Unitful

# ╔═╡ 0d928ac8-0c54-47df-9194-da6f0bf88fb5
begin
	using LLVM
	using LLVM.Interop
end

# ╔═╡ 2f03b26e-08e1-4be8-81e3-1d97e9c46e97
html"<button onclick='present()'>Toggle presentation mode</button>"

# ╔═╡ 21735a54-7dd0-4a7a-9368-7495e318e307
PlutoUI.TableOfContents(; depth=4)

# ╔═╡ e1f06315-633b-42d0-94c7-98ad6ec15259
begin
		# using JET
	# using AllocCheck
end

# ╔═╡ d92b6c00-b1b3-4d23-b8b9-b57e5fd3ffe5
md"""
# Compilation
"""

# ╔═╡ 3dc0b5ff-2322-46eb-84a1-4074024ee8b6
md"""
1. Parsing
2. Linearization
3. Abstract-interpretation based type-inference
4. High-level optimizations
5. LLVM based optimizations
6. Emission of native code
"""

# ╔═╡ da596e21-9b9b-4a39-92ba-67aa4eefa88a
func = """
function example(X)
	acc = zero(eltype(X))
	for x in X
		acc += x
	end
	return acc
end
""";

# ╔═╡ f9f1207a-e65a-4325-a0d4-948a4e2b4320
md"""
## Parsing
"""

# ╔═╡ 53371620-eb8f-46bb-870f-d8eb20e46489
md"""
!!! note
    Parsing turns **text** into expressions.
"""

# ╔═╡ d8c0c48e-e950-4ce5-a15e-a6644e7f4c16
expr = Meta.parse(func)

# ╔═╡ 65f24ef9-d62d-43d4-879a-145b1301f58d
 parsestmt(SyntaxNode, func)

# ╔═╡ b09c9059-6f28-470c-a63b-d1857323a451
parsestmt(Expr, func)

# ╔═╡ e9f9cb37-d778-4e30-9f3b-8b7392a1eade
md"""
!!! note
    To go from **Expr** to usable function we need to resolve symbols in a namespace and add the function to the system. `eval` will do that for us.
"""

# ╔═╡ 35e3b7a9-5393-4e1c-ab29-1f3603a4e5b7
example = eval(expr)

# ╔═╡ 30ceb52d-e96e-47aa-a993-fd9e5ac79d00
example(ones(10))

# ╔═╡ 70fd2d56-817c-43c1-975a-c7b0161e86a7
md"""
## Linearization
"""

# ╔═╡ 89d20363-b871-4ce2-95d1-a80a70a0419f
md"""
!!! note
    `Expr` form an abstract-syntax-tree (AST). Julia macros are functions from `Expr` to `Expr`. To simplify things later we want to linearize that tree. In Julia we call this lowering.
"""

# ╔═╡ 9a7ee25e-2c3c-4b10-a4c6-be7196c83538
CL = code_lowered(example, (Array{Float64},)) |> only

# ╔═╡ 944fc32c-569f-4792-8976-ef5095db8e4c
md"""
!!! note
    Lowered code is in single-static-assignment (SSA) form with memory.
    `%8  = %7 === nothing` is a SSA statement, and `@_3` are variables (e.g. memory).
"""

# ╔═╡ 02812c13-f1cd-44dc-aec2-b64dd4e808fa
md"""
!!! note
    The lowered code forms a control-flow-graph CFG, with a set of basic blocks.
"""

# ╔═╡ 109df061-0abe-4d2a-b083-c653066aaf05
viz(CL)

# ╔═╡ c6a01a34-161f-4da5-b359-775b064f96cf
md"""
!!! note 
    Control-flow is implemented using `goto %n` and `goto %n if not %c` statements.
    Julia's IR uses implicit fallthrough, so a basic-block ending in a `goto %n if not %c` statement has a second implicit successor in the subsequent basic block.
"""

# ╔═╡ 653049e7-f1ca-45b1-92c1-5a7fe9e381fa
md"""
## Abstract-interpretation based type-inference
"""

# ╔═╡ c8428a0c-6765-4a59-a0a7-1f426f052d4b
md"""
As soon as we have an AST we could have written an interpreter. Perhaps we would use the lowered form to make our lifes easier. 
"""

# ╔═╡ 04e4c1f6-f6c7-4b29-97f2-9de06ee4d71b
import Core.Compiler as CC

# ╔═╡ baa49d7b-62c3-4fee-8981-e89408806561
function interpret_naively(CL, args)
	code = CL.code
	slots = Vector{Any}(undef, length(CL.slotnames))
	stmts = Vector{Any}(undef, length(code)) # SSA

	# copy args into vars
	for (name, value) in args
		id = findfirst(==(name), CL.slotnames)
		slots[id] = value
	end

	resolve(val::CC.SSAValue) = stmts[val.id]
	resolve(val::CC.SlotNumber) = slots[val.id]
		
	function local_eval(stmt)
		if stmt isa GlobalRef
			return eval(stmt)
		elseif stmt isa CC.SSAValue || stmt isa CC.SlotNumber
			return resolve(stmt)
		elseif stmt isa Expr
			head = stmt.head
			if head == :call
				resolve_args = map(local_eval, stmt.args)
				f = first(resolve_args)
				f_args = resolve_args[2:end]
				if f isa Core.IntrinsicFunction || f isa Core.Builtin || 
				   f === Base.iterate
					return f(f_args...)
				end
				argtypes = ntuple(i->Core.Typeof(f_args[i]), length(f_args))
				CL_f = code_lowered(f, argtypes) |> only
				f_args′ = collect(zip(CL_f.slotnames[2:end], f_args))
				try
					return interpret_naively(CL_f, f_args′)
				catch exc
					@error "Interpretation failed" exception=exc f f_args
					return f(f_args...)
				end
			elseif head == :(=)
				@show stmt
				error("= in rhs expression")
			else
				@show stmt
				error("Unknown expression")
			end
		else
			return stmt
		end
	end
	
	# interpreter
	pc = 1
	while true
		stmt = code[pc]
		if stmt isa GlobalRef || stmt isa CC.SSAValue || stmt isa CC.SlotNumber
			stmts[pc] = local_eval(stmt)
		elseif stmt isa Expr
			head = stmt.head
			if head == :(=)
				lhs = stmt.args[1]
				rhs = stmt.args[2]
				@assert lhs isa CC.SlotNumber
				val = local_eval(rhs)
				slots[lhs.id] = val
				stmts[pc] = val
			else
				stmts[pc] = local_eval(stmt)
			end
		elseif stmt isa CC.GotoIfNot
			cond = local_eval(stmt.cond)
			if !cond
				pc = stmt.dest
			else
				pc += 1
			end
			continue
		elseif stmt isa CC.GotoNode
			pc = stmt.label
			continue
		elseif stmt isa CC.ReturnNode
			return local_eval(stmt.val)
		else
			error("Unknown stmt")
		end
		pc += 1
	end
end

# ╔═╡ ae37bb88-8bae-434f-b2fd-2ad1a31e9c06
interpret_naively(CL, (:X => ones(3),))

# ╔═╡ d58bb116-c069-453d-9866-abd63cfa86d8
md"""
Our interpreter isn't all that fast, but it mostly works! Of course if you want to support all of Julia life becomes a bit more complicated. Here I am skipping things like foreign function calls, and I fall-back onto the native execution scheme if I have no other options.
"""

# ╔═╡ 84f30340-ce40-4e63-8f70-7b57868a8919
md"""
!!! note
    To accelerate execution we would need to cache lookups and perhaps perform optimizations such as inlining. We need to carefully consider under which assumptions we may do so!
"""

# ╔═╡ c482bc24-f1d2-46c7-8538-48c90d7e4394
md"""
### What makes a programming language dynamic?

1. Dynamic typing vs static typing
2. Open world vs closed world
3. Dynamic structs vs dynamic
"""

# ╔═╡ 1dd808d9-84d8-4de3-85ea-73febfee62df
md"""
### Dynamic typing vs static typing

The **common** argument: JavaScript vs TypeScript -- reminds one a bit of Vim vs Emacs, or spaces vs tabs.

- [Laurence Tratt: A modest attempt to help prevent unnecessary static dynamic typing debates](https://tratt.net/laurie/blog/2010/a_modest_attempt_to_help_prevent_unnecessary_static_dynamic_typing_debates.html)
- [Laurence Tratt: Dynamically Typed Languages](https://tratt.net/laurie/research/pubs/papers/tratt__dynamically_typed_languages.pdf)

> a dynamically typed language is one that does not check or enforce type-safety at compile-time.

But is there all that is to it?
"""

# ╔═╡ 09939df5-6b00-4d55-9ddb-d87a25264a8e
md"""
### Some terminology

- Types: A type (or in Object-Oriented programming a class) defines a set of values 
```julia
abstract type Fruit end
struct Apples <: Fruit end
abtract type StoneFruit end
struct Peaches <: StoneFruit end
```

- Compile-time: Work done before the user's program
- Run time: Work done during the execution of the program
"""

# ╔═╡ bdf87ca9-ed6c-4d66-9b1c-b9db83453a4d
md"""
### Static typying

In statically typed languages a variable can only be assigned a type once.

Explicitly (Java):
```java
int i = 3;
String s = "4";
int x = i + s;
```

Implicitly (Haskell):

```haskell
let
  i = 3
  s = "4"
in
  i + s
```

!!! note
    This allows us to perform type-checking before executing a program.
    Type errors occur at compile-time.
"""

# ╔═╡ f3d799cf-9bc5-4fa1-b2ad-79473a8d17af
md"""
### Dynamic typying

In a dynamically typed language type-checks are deferred until runtime. 
"""

# ╔═╡ a056c2d2-961e-4b8f-98af-b24f2bfb660e
function f()
	i = 3
	s = "4"
	i + s
end

# ╔═╡ 83a4d259-2842-4e1d-af29-70ecf0de2e19
md"""
!!! note
    We can still write analyzers that perform these checks ahead of execution.
"""

# ╔═╡ 983f57a5-a391-4e68-b891-755cb0e569fe
md"""
Dynamic typing also means that functions can return differently typed values depending on program execution.

In Julia we denotate those as `Union{Int, Float64}`
"""

# ╔═╡ d77dbe9f-87d3-463e-b45b-c7f947b39f3b
g() = rand() ? 1 : 1.0

# ╔═╡ 08d8db52-11b3-4281-b20f-23c038f5d9b3
md"""
### Strong vs weakly typed
Yet another delination is strong vs weakly typed. As an example `C` is a statically typed language, but values are weakly typed.

```c
void f(void* p) {
	int *ints = (int*)p;
    float *floats (float*)p;
    ints[0] + floats[1];
}
```
"""

# ╔═╡ 13d86040-eb93-422e-a522-570fb794353f
md"""
### Open world vs closed world

Many dynamic programing languages have the notion of `eval`.
`Eval` allows one to add code at runtime. Julia is "define by running"
code get's added incrementaly by running code.

!!! note
    Read-Eval-Print-Line (REPL) is a powerful tool, as are use-cases like notebooks.

Open-world semantics means code can be added or change at runtime.

Closed-world semantics mean that the program is fixed before running.
"""

# ╔═╡ 75300e9f-8218-4267-ad8d-99b5a59fa104
md"""
### Interpretation vs Compilation

!!! question
    Is Python interpreted
"""

# ╔═╡ 6dc58b58-f921-4870-a079-3bbdfb69576d
    let
	    content = md"""!!! answer
	Compiled to Bytecode: then interpreted (and there are full Python compiler)
    """
	    HTML("<details>$(html(content))</details>")
    end

# ╔═╡ 7113b4d0-4155-4f68-9189-9a08c23cd385
md"""
!!! question
    Is C compiled?
"""

# ╔═╡ 952bb1db-e62e-4a2a-a5c3-6ad982f51461
    let
	    content = md"""
!!! answer
	Yes, but there are also C interpreters such as Cling.
"""
	    HTML("<details>$(html(content))</details>")
    end

# ╔═╡ 4656cd6b-4c61-49a1-b9c0-5107f8c5dfef
md"""
!!! note
    Interpretations vs Compilation is an implementation choice not part of the language semantics.
"""

# ╔═╡ ce93b6cc-9a05-42b6-be00-b617c36bab1a
md"""
### The curse of leaky abstractions

In Python I can create a class and later modify the fields of an object of said class.

```python
>>> class MyClass:
...   x = 5
... 
>>> c = MyClass()
>>> c.x
5
>>> c.y = 3
>>> c.y
3
>>> c = MyClass()
>>> c.y
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
AttributeError: 'MyClass' object has no attribute 'y'
```
"""

# ╔═╡ 3a853565-a349-4102-9f85-f13c662a704c
md"""

Similarily in Ruby:

```ruby
class A
end

a = A.new
a.age = 20 # Raises undefined method `age='

# Inject attribute accessors into instance of A
class << a
  attr_accessor :age
end

a.age = 20 # Succeeds
a.age # Returns 20

b = A.new
b.age # Raises undefined method, as expected, since we only modified one instance of A
```
"""

# ╔═╡ 4b16cfc8-e77b-4044-a1c1-5fea5828fb4c
md"""
!!! note
    In both Python and Ruby fields are dynamically typed.
"""

# ╔═╡ ca937820-3cb9-4009-93db-0627fe430ab2
md"""
While Julia has inheritance, only abstract types can be inherited from.
Concrete types are final.

```julia
struct A
   age::Int
   data # Untyped field
end
```

Types can also be parametric.

!!! important
    Since concrete types are final we can take advantage of this information, 
    without having to rely on guard checks.
"""

# ╔═╡ 0301eb8a-9363-49fc-8a96-5d4c5b353cf3
md"""
### So how do we make dynamic programs run fast: 

**Julia: Avoiding runtime uncertainty**
- Sophisticated type system
- Type inference
- Multiple dispatch
- Specialization
- JIT compilation


> Julia: Dynamism and Performance Reconciled by Design (doi:10.1145/3276490)
"""

# ╔═╡ 205495c4-4060-48ed-b498-3bd6746c86fa
md"""
### Type inference

In Julia, type inference is the process of propagating type information from arguments. This utilizes **Abstract Interpretation** as a technique.

- Iteration until fixed-point is reach / Convergence
- Types form a lattice:
  - Bottom: `Union{}`
  - Top: `Any`
- Imprecise answers are permisible: E.g. `Any` is always correct
- Care must be taken for *recursive* functions and *loops*
- Requires heuristics to prevent it from running forever

!!! note
    Type inference allows us to aggressivly de-virtualize calls.
"""

# ╔═╡ 7ce026fd-c884-41d4-89b4-7e5e7139fdc6
function mysum(X)
	acc = 0
    for x in X
       acc += x
    end
    return acc
end

# ╔═╡ 0d53d881-4599-41dd-9d0e-2adf39230be5
md"""
The analysis for `mysum` begins with a specific signature type.

`Tuple{::typeof(mysum), Vector{Float64}}`

```julia
function mysum(X::Vector{Float64})
	acc = 0
    for x in X
       acc += x
    end
    return acc
end
```
"""

# ╔═╡ 7a535689-29d0-4c97-88f7-d09b438d2270

md"""
Examining line 1 we can state that `acc::Int64` due to it being set to a constant.

```julia
function mysum(X::Vector{Float64}) 
	acc = 0::Int # State: {X::Vector{Float64}, acc::Int}
    for x in X
       acc += x
    end
    return acc
end
```
"""

# ╔═╡ 5890e3d7-bad6-4260-9584-d7694ce3659e
md"""
Let's for the moment assume that we can deduce `x in X` to imply that `x::Float64`

```julia
function mysum(X::Vector{Float64}) 
	acc = 0::Int
    for x::Float64 in X # State: {X::Vector{Float64}, acc::Int, x::Float64}
       acc += x
    end
    return acc
end
```
"""

# ╔═╡ b63d195b-a73f-4c72-9dc3-6e7cb216f153
md"""
`acc += x` is syntax sugar for `acc = acc + x`

Julia has a user-extendable promotion scheme for arithmetic ops:

`Base.promote_op(+, Int64, Float64) =` $(Base.promote_op(+, Int64, Float64))

```julia
function mysum(X::Vector{Float64}) 
	acc = 0::Int # State: {X::Vector{Float64}, acc::Int}
    for x::Float64 in X
       acc::Float64 = acc::Int + x::Float64
       # State: {X::Vector{Float64}, acc::Float64, x::Float64}
    end
    return acc
end
```

"""

# ╔═╡ 89af78f4-c51c-4fc1-a0a9-9279d6728f57
md"""
If `length(X) == 0` the for-loop might never be executed. So after the loop we have to unify the abstract interpretation state before the loop with after the loop iteration.

- State Before: `{X::Vector{Float64}, acc::Int64}`
- State After: `{X::Vector{Float64}, acc::Float64}`
- Unification: `{X::Vector{Float64}, acc::Union{Int64, Float64}}`

We haven't yet reached a fix-point. So we re-enter the loop with our new state.

```julia
function mysum(X::Vector{Float64}) 
	acc = 0::Int
    for x::Float64 in X # {X::Vector{...}, acc::Union{Int64, Float64}, x::Float64}
       acc::Union{Float64} = acc::Union{Int64, Float64} + x::Float64
	   # State: {X::Vector{Float64}, acc::Float64, x::Float64}
    end
    return acc
end
```

"""

# ╔═╡ 101a3517-828b-445e-9939-550b6e6829c8
md"""
- State Before: `{X::Vector{Float64}, acc::Union{Int64, Float64}}`
- State After: `{X::Vector{Float64}, acc::Float64}`
- Unification: `{X::Vector{Float64}, acc::Union{Int64, Float64}}`

Fixed point is reached and we can conclude that after the loop `acc::Union{Int64, Float64}` and thus `mysum(X::Vector{Float64})::Union{Int, Float64}`

We can use Julia's introspection tools to automatically query the system:

- `@code_lowered`
- `@code_typed optimize=false`
"""

# ╔═╡ b435bf1f-13ee-46ca-8c45-58680f286028
@code_lowered mysum(rand(3))

# ╔═╡ 95cb7031-67ae-4243-a07a-c2338ca9bd6e
@code_typed optimize=false mysum(rand(3))

# ╔═╡ c4fd2716-a18a-49af-a317-44c677e40bbe
md"""
### What information did we use?

Julia has `eval`. So what happens if someone changes the definition of say `+` while the code is running?

Julia uses the so called "world-age" system to track the validity of method definitions and method compilations.
"""

# ╔═╡ e0a38f99-3c73-44e0-b4c2-9a9d694eae7e
TwoColumn(md"""
Julia 0.3
```julia-repl
julia> f() =  1
julia> g() = f()
julia> g()
1

julia> f() = 2
julia> g()
1

```
""", md"""
Julia 1.0
```julia-repl
julia> f() =  1
julia> g() = f()
julia> g()
1

julia> f() = 2
julia> g()
2
```
""")

# ╔═╡ 7b9eb8e9-943e-4a31-b0ec-1847e70fda6f
md"""

> World age in Julia: optimizing method dispatch in the presence of eval (doi:10.1145/3428275)

"""

# ╔═╡ aa22d898-b106-4812-b0b8-75f5908ee204
md"""
## Optimizations

- Optimizations are unobservable program transformations
  - Except when they fail

Julia (as many other modern programming languages) uses a multi-stage optimization pipeline.

High-level optimizations:
- Constant propagation
  - Concrete evaluation
- Effect analysis
- Inlining
- Dead code elimination (DCE)
- Scalar replacement of aggregates (SROA)
- (Future) Interprocedural Escape Analyis
- (Future) Alias analysis
- (Future) Loop based optimizations such as loop invariant code motion (LICM)
"""

# ╔═╡ fe94ed49-90cb-44ca-8308-60b76fe9ce93
begin
	IR, rt = only(Base.code_ircode(mysum, (Vector{Float64},), optimize_until="compact 1"))
	IR
end

# ╔═╡ 94757fc2-8858-499c-8d26-24844a89fc00
Core.Compiler.ssa_inlining_pass!(
	Core.Compiler.copy(IR),
	Core.Compiler.InliningState(Core.Compiler.NativeInterpreter()), false)

# ╔═╡ e7772c4c-a41e-4ea0-88b4-1482ae155b4a
md"""
Or simply
"""

# ╔═╡ eb2e8913-657a-4c48-93f1-d4b68cf1a990
@code_typed mysum(rand(4))

# ╔═╡ 8bd2c9a8-7c12-4a10-b28a-ca6c4cf86619
md"""
## LLVM based code generation

- LLVM is a widely used compiler framework
- Common set of "middle-end" optimizations based on LLVM IR
- Specific backend optimizations
- Frontends like Julia generate LLVM intermediate representation (IR)
"""

# ╔═╡ e7bae422-7ca6-4cfb-9278-7840a7be647f
@code_llvm optimize=false debuginfo=:none mysum(rand(30))

# ╔═╡ 0516e98c-0a78-43b2-9aec-9d6698032a6e
md"""
Optimizations include:
- Simplifications (Control flow graph (CFG) / Instructions)
- Julia specific passes
  - allocation optimizations (ellision / heap to stack / ...)
- Loop optimization
  - LICM
  - Vectorization
  - Unrolling/Peeling
  - Loop Unswitch

We also perform **legalization**. Turning the LLVM full or Julia specific concepts into a legal representation.

!!! note
    Each successive lowering simplifies the program and throws information away.
    This opens the question: When to perform what optimization.

"""

# ╔═╡ 371d7e91-eb88-4220-ad38-0bc74f55c806
md"""
## Interpretation vs JIT vs JAOT vs AOT

There are many flavours of executing programs.
- Interpreters
  - Byte code interpreters
- Compilation
  - Ahead of Time (AOT)
  - Just in Time (JIT)
    - Tracing JIT
  - Just Ahead of Time (JAOT) / Just in the nick of Time

JIT compilers are commonly used for Java or JavaScript, they are often tiered and responsive.

As an example Java may compile your program first with the `C1` compiler tuned for latency, then later if it detects your function has executed many times it will use the `C2` compiler. In JavaScript it will assome the most common type and de-optimize upon uncommon types.
"""

# ╔═╡ e3862e23-8942-4c1e-98b0-e4f14b0be8de
md"""
Currently Julia compiles every function before it's first execution.

!!! note
    This initial latency or time-to-first-X, is why sometimes folks say:
    "Julia is fast the second time"

Over the years more and more attention has been payed on amortizing this compilation cost by performing caching. Native code caching for Julia 1.9 had a drastic impact on how "snappy" the language feels.
"""

# ╔═╡ 7e8b6d19-3a9b-41f4-8bfa-3cadc7e69334
YouTube("jFhL8EVrz7s", 10, 5)

# ╔═╡ 55b87adc-2bac-45ae-b8e2-f318502782f4
md"""
## How to make it correct?

In order to execute dynamic programs fast we need to obtain information/make assumptions. It is crucial that the information remains correct.

!!! info
    The language semantics are dynamic, optimizations and static analysis doesn't change that.

So we need to track the validity of the information. Python compilers and other JITs often use **guard checks** whereas Julia thanks to final concrete types can use **world-ages** to convert open-world semantics to closed-world semantics.

Julia also uses edges to limit the invalidation effect. Methods and compile results have a pair of world-ages (first-valid and last-valid).

!!! important
    On disk caches must be carefully validated as well.
"""

# ╔═╡ 6b5e0098-631d-4a5d-9333-a2ab7c6e95f8
md"""
## So why bother?

- The usability improvement of dynamic programming language is not to undervalue
  - Python, JavaScript and co are very popular for accessibility reasons
- Dynamic Programming Languages often have a higher level of abstractions
  - When I work on hard science, I don't want to worry about memory lifetimes
- Dynamic programming languages can be fast
  - The presenence of a JIT allows for value specializationn
  - We can start dynamic and regain information at call-boundaries

!!! note
    Julia is a fast, high-level dynamic programming language.
    It's not magic, but rather clever language design.

"""

# ╔═╡ 3c86bb43-8e17-46b2-8b5d-edad10a1a659
md"""
# Going fast nowhere
"""

# ╔═╡ 9f29f87e-bfe3-49a3-9377-53bf67e067b6
@bind N Slider(1:9)

# ╔═╡ 6d9677c6-a158-4c42-9923-98b02f047cb5
data = rand(10^N);

# ╔═╡ b1dc82b5-1044-43fa-8028-1a2127c2022a
function sum(X::Vector{Float64})
    acc = 0::Int64
    for x in X
        (acc += x)::Float64
    end
    acc::Union{Int64, Float64}
end
    

# ╔═╡ d6978e15-36fd-466f-94fe-d367642302a3
@benchmark sum($data)

# ╔═╡ a125fcfc-3859-4a7d-b8fb-68fbe3add529
md"""
## Figuring out what is happening
The stages of the compiler

- `@code_lowered`
- `@code_typed` & `@code_warntype`
- `@code_llvm`
- `@code_native`

Where is a function defined `@which` & `@edit`
"""

# ╔═╡ 77bab67c-0d15-4821-8e8c-e02670da3736
@code_lowered sum(data)

# ╔═╡ c105ab86-cadc-4c7c-932c-c4be9e9939ea
md"""
## A simple example: counting
"""

# ╔═╡ c172f2c0-af21-4284-9158-627241078a41
function f(N)
    acc = 0
    for i in 1:N
        acc += 1
    end
    return acc
end

# ╔═╡ 47e78f05-9751-43d8-8b75-a5603031c4a9
f()

# ╔═╡ 23a7ea45-b772-472b-b763-e923bcce7a0f
@code_typed f()

# ╔═╡ 3b0e1117-3ef4-4418-9fc6-af4ed9d93f33
K = 100_000_000

# ╔═╡ 53c55d04-0783-496f-bbf7-5fadd3c73c5b
result = @benchmark f($K)

# ╔═╡ 8cf7becb-17a7-4eba-8a31-620463f7e819
begin
	t = time(minimum(result)) * u"ns" # in ns
	pFreq = round(typeof(1u"PHz"), K/t)
end;

# ╔═╡ 6f115a34-53fe-4307-a9e3-c682dedf1ede
md"""

So we are doing **$(K/1_000_000)** million additions in **$t**...

That would mean our processor operates at **$pFreq**

We wish...

Let's do a basic check, 10x bigger input.
"""

# ╔═╡ fd6eaedc-3565-48a6-afc1-12eb9219c5bd
@benchmark f($(Ref(10*K))[])

# ╔═╡ 6162ec42-6004-4677-aa89-aa3be386c79a
md"""
Let's explore what code we are **actually** running.

Using Julia's reflection macros we can see all of the stages of code-generation.
"""

# ╔═╡ a8b0673f-1df1-41b3-8863-6b2a0b316201
@code_lowered f(K)

# ╔═╡ be75072e-60b6-49f9-bb12-b5290d78ff84
@code_typed optimize=false f(K)

# ╔═╡ a9ec9994-5e06-4c55-a0b4-fb425447aa12
@code_typed optimize=true f(K)

# ╔═╡ f4f638ef-a490-4c16-a2b1-a67c13368b8b
with_terminal() do
	@code_llvm optimize=false f(K)
end

# ╔═╡ 4752da81-340a-4af4-af80-1d2e448d18da
with_terminal() do
	@code_llvm optimize=true f(K)
end

# ╔═╡ b66a4a6f-7790-4329-8c3f-0a9372e57ef9
with_terminal() do
	@code_native f(K)
end

# ╔═╡ 84dfeb58-6223-4152-ba0c-fda3fb54f206
md"""
### Conclusion
LLVM realised that our loop:
```julia
for i in 1:N
  acc += 1
end
```

Just ended up being $acc = 1 * N$
"""

# ╔═╡ 19086a1f-e9f9-4ed5-b917-1c38cd8c7693
md"""
## Can we actually measure the speed of our original code?
"""

# ╔═╡ 4902e862-2d00-44a7-bcca-9694fd3a63ff
"""
    clobber()

Force the compiler to flush pending writes to global memory.
Acts as an effective read/write barrier.
"""
@inline clobber() = @asmcall("", "~{memory}", true) 

# ╔═╡ 9564cb71-5cb1-44c8-8885-83b00496aa7b
"""
    escape(val)

The `escape` function can be used to prevent a value or
expression from being optimized away by the compiler. This function is
intended to add little to no overhead.
See: https://youtu.be/nXaxk27zwlk?t=2441
"""
@inline escape(val::T) where T = @asmcall("", "X,~{memory}", true, Nothing, Tuple{T}, val)

# ╔═╡ 2c7e66b1-d916-468f-8da7-90b51c6febea
function k(::Type{T}, N) where T
    acc = zero(T)
    for i in 1:N
        acc += one(T)
        clobber()
    end
    return acc
end

# ╔═╡ 3a08a729-92b4-4c0b-90d1-93c8599c5f6b
with_terminal() do
	@code_llvm debuginfo=:none k(Int64, 10)
end

# ╔═╡ a5ab9729-1cdb-446b-83e3-3131b54f23be
with_terminal() do
	@code_native debuginfo=:none k(Int64, 10)
end

# ╔═╡ bea7ce92-7559-4ad6-a759-7bcf0e4c429e
function m(::Type{T}, N) where T
    acc = zero(T)
    for i in 1:N
        acc += one(T)
        escape(acc)
    end
    return acc
end

# ╔═╡ 7f54c6ec-6cdd-4b5f-b872-0c225e283bb0
with_terminal() do
	@code_llvm debuginfo=:none m(Int64, 10)
end

# ╔═╡ 4a7fd2de-3cb0-4b1d-aeb6-b2b4c99144a4
result2 = @benchmark m(Int64, $K)

# ╔═╡ e61a9667-fe5c-4052-a99b-324f34f74a95
@benchmark m(Int64, $(K*10))

# ╔═╡ 68de661f-8d99-4d82-a069-c174f687eb78
begin
	t2 = time(minimum(result2)) * u"ns" # in ns
	pFreq2 = round(typeof(1u"MHz"), K/t2)
end;

# ╔═╡ 92850708-6e15-4ba6-bdbd-db7a41d2690a
md"""
Frequency estimation: $pFreq2 ~ $(round(typeof(1u"GHz"), pFreq2))

Note: Benchmarking is hard, careful evalutaion of what you are trying to benchmark.

- If we were just interesting in how fast f(N) was we would have been fine with our first measurement
- But we were interested in the speed of addition as a proxy of perfromance
- Integer math on a computer is associative, Floating-Point math is not.
"""

# ╔═╡ 061223e6-15b4-412b-aafe-c06a02719f92
md"""
# SIMD
"""

# ╔═╡ 6df4986b-8b68-4c8f-bd14-78b679b2eff3
TODO()

# ╔═╡ 52d63c8d-6737-4512-a69b-124f1e8c9cd3
md"""
# LICM
"""

# ╔═╡ 99cb0490-4015-4c63-b288-a2905f950585


# ╔═╡ 8f573fba-fa84-4adc-a6cc-d1fd83c9f1ce


# ╔═╡ 9ead45ad-187b-4b28-b959-c5667be53a30


# ╔═╡ 803f5ec5-85e6-44ef-a56d-e9e40b04f1ac


# ╔═╡ cd1fd248-de09-420c-8920-146fd2a7f0c2


# ╔═╡ 2fe0a097-acfe-421c-8230-dd67bb9d3855


# ╔═╡ 5d9a734e-8282-44ce-9b07-75c89abafc94


# ╔═╡ 808fc3bd-5ea2-414e-aec3-180e03f366ca


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
IRViz = "fe03f759-463e-4126-a68f-1df7fb7a8375"
JuliaSyntax = "70703baa-626e-46a2-a12c-08ffd08c73b4"
LLVM = "929cbde3-209d-540e-8aea-75f648917ca0"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
ShortCodes = "f62ebe17-55c5-4640-972f-b59c0dd11ccf"
Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d"

[compat]
BenchmarkTools = "~1.6.0"
IRViz = "~1.0.0"
JuliaSyntax = "~1.0.2"
LLVM = "~9.4.2"
PlutoTeachingTools = "~0.4.1"
PlutoUI = "~0.7.68"
ShortCodes = "~0.3.6"
Unitful = "~1.23.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "a90c40be4afba7614b65c990ffe16b2735b2ffda"

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

[[deps.BenchmarkTools]]
deps = ["Compat", "JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "e38fbc49a620f5d0b660d7f543db1009fe0f8336"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.6.0"

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "962834c22b66e32aa10f7611c08c8ca4e20749a9"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.8"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

    [deps.ColorTypes.weakdeps]
    StyledStrings = "f489334b-da3d-4c2e-b8f0-e476e12c162b"

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

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "d9d26935a0bcffc87d2613ce14c527c99fc543fd"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.5.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.ExceptionUnwrapping]]
deps = ["Test"]
git-tree-sha1 = "d36f682e590a83d63d1c7dbd287573764682d12a"
uuid = "460bff9d-24e4-43bc-9d9f-a8973cb893f4"
version = "0.1.11"

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

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "ed5e9c58612c4e081aecdb6e1a479e18462e041e"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.10.17"

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

[[deps.IRViz]]
deps = ["Kroki"]
git-tree-sha1 = "fb9307c3ebe6b9e39df4cc26b7218d4ee4f0961d"
uuid = "fe03f759-463e-4126-a68f-1df7fb7a8375"
version = "1.0.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"
version = "1.11.0"

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

[[deps.JuliaSyntax]]
git-tree-sha1 = "0d4b3dab95018bcf3925204475693d9f09dc45b8"
uuid = "70703baa-626e-46a2-a12c-08ffd08c73b4"
version = "1.0.2"

[[deps.Kroki]]
deps = ["Base64", "CodecZlib", "DocStringExtensions", "HTTP", "JSON", "Markdown", "Reexport"]
git-tree-sha1 = "a3235f9ff60923658084df500cdbc0442ced3274"
uuid = "b3565e16-c1f2-4fe9-b4ab-221c88942068"
version = "0.2.0"

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

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"
version = "1.11.0"

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

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f02b56007b064fbfddb4c9cd60161b6dd0f40df3"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.1.0"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.Memoize]]
deps = ["MacroTools"]
git-tree-sha1 = "2b1dfcba103de714d31c033b5dacc2e4a12c7caa"
uuid = "c03570c3-d221-55d1-a50c-7939bbd78826"
version = "0.4.4"

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

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "f1a7e086c677df53e064e0fdd2c9d0b0833e3f6e"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.5.0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "87510f7292a2b21aeff97912b0898f9553cc5c2c"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.1+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "Latexify", "Markdown", "PlutoUI"]
git-tree-sha1 = "537c439831c0f8d37265efe850ee5c0d9c7efbe4"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.4.1"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "ec9e63bd098c50e4ad28e7cb95ca7a4860603298"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.68"

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

[[deps.ShortCodes]]
deps = ["Base64", "CodecZlib", "Downloads", "JSON3", "Memoize", "URIs", "UUIDs"]
git-tree-sha1 = "5844ee60d9fd30a891d48bab77ac9e16791a0a57"
uuid = "f62ebe17-55c5-4640-972f-b59c0dd11ccf"
version = "0.3.6"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "f305871d2f381d21527c770d4788c06c097c9bc1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.2.0"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
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

[[deps.StructTypes]]
deps = ["Dates", "UUIDs"]
git-tree-sha1 = "159331b30e94d7b11379037feeb9b690950cace8"
uuid = "856f2bd8-1eba-4b0a-8007-ebc267875bd4"
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

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

[[deps.Tricks]]
git-tree-sha1 = "6cae795a5a9313bbb4f60683f7263318fc7d1505"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.10"

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

[[deps.Unitful]]
deps = ["Dates", "LinearAlgebra", "Random"]
git-tree-sha1 = "d2282232f8a4d71f79e85dc4dd45e5b12a6297fb"
uuid = "1986cc42-f94f-5a68-af5c-568840ba703d"
version = "1.23.1"

    [deps.Unitful.extensions]
    ConstructionBaseUnitfulExt = "ConstructionBase"
    ForwardDiffExt = "ForwardDiff"
    InverseFunctionsUnitfulExt = "InverseFunctions"
    PrintfExt = "Printf"

    [deps.Unitful.weakdeps]
    ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
    ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"
    Printf = "de0858da-6303-5e67-8744-51eddeeeb8d7"

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
# ╟─2f03b26e-08e1-4be8-81e3-1d97e9c46e97
# ╠═21735a54-7dd0-4a7a-9368-7495e318e307
# ╟─f1db15d4-9f18-11ee-029a-e51fbd66cfea
# ╠═e1f06315-633b-42d0-94c7-98ad6ec15259
# ╟─d92b6c00-b1b3-4d23-b8b9-b57e5fd3ffe5
# ╟─3dc0b5ff-2322-46eb-84a1-4074024ee8b6
# ╠═da596e21-9b9b-4a39-92ba-67aa4eefa88a
# ╟─f9f1207a-e65a-4325-a0d4-948a4e2b4320
# ╟─53371620-eb8f-46bb-870f-d8eb20e46489
# ╠═d8c0c48e-e950-4ce5-a15e-a6644e7f4c16
# ╠═2d617f49-8dd4-45be-8e59-b80bc87afa93
# ╠═65f24ef9-d62d-43d4-879a-145b1301f58d
# ╠═b09c9059-6f28-470c-a63b-d1857323a451
# ╟─e9f9cb37-d778-4e30-9f3b-8b7392a1eade
# ╠═35e3b7a9-5393-4e1c-ab29-1f3603a4e5b7
# ╠═30ceb52d-e96e-47aa-a993-fd9e5ac79d00
# ╟─70fd2d56-817c-43c1-975a-c7b0161e86a7
# ╟─89d20363-b871-4ce2-95d1-a80a70a0419f
# ╠═9a7ee25e-2c3c-4b10-a4c6-be7196c83538
# ╟─944fc32c-569f-4792-8976-ef5095db8e4c
# ╟─02812c13-f1cd-44dc-aec2-b64dd4e808fa
# ╠═b416ea3c-92d0-46b0-bbc0-99b7dfabe328
# ╠═109df061-0abe-4d2a-b083-c653066aaf05
# ╟─c6a01a34-161f-4da5-b359-775b064f96cf
# ╟─653049e7-f1ca-45b1-92c1-5a7fe9e381fa
# ╟─c8428a0c-6765-4a59-a0a7-1f426f052d4b
# ╠═04e4c1f6-f6c7-4b29-97f2-9de06ee4d71b
# ╠═baa49d7b-62c3-4fee-8981-e89408806561
# ╠═ae37bb88-8bae-434f-b2fd-2ad1a31e9c06
# ╟─d58bb116-c069-453d-9866-abd63cfa86d8
# ╟─84f30340-ce40-4e63-8f70-7b57868a8919
# ╟─c482bc24-f1d2-46c7-8538-48c90d7e4394
# ╟─1dd808d9-84d8-4de3-85ea-73febfee62df
# ╟─09939df5-6b00-4d55-9ddb-d87a25264a8e
# ╟─bdf87ca9-ed6c-4d66-9b1c-b9db83453a4d
# ╟─f3d799cf-9bc5-4fa1-b2ad-79473a8d17af
# ╠═a056c2d2-961e-4b8f-98af-b24f2bfb660e
# ╠═47e78f05-9751-43d8-8b75-a5603031c4a9
# ╟─83a4d259-2842-4e1d-af29-70ecf0de2e19
# ╠═23a7ea45-b772-472b-b763-e923bcce7a0f
# ╟─983f57a5-a391-4e68-b891-755cb0e569fe
# ╠═d77dbe9f-87d3-463e-b45b-c7f947b39f3b
# ╟─08d8db52-11b3-4281-b20f-23c038f5d9b3
# ╟─13d86040-eb93-422e-a522-570fb794353f
# ╟─75300e9f-8218-4267-ad8d-99b5a59fa104
# ╟─6dc58b58-f921-4870-a079-3bbdfb69576d
# ╟─7113b4d0-4155-4f68-9189-9a08c23cd385
# ╟─952bb1db-e62e-4a2a-a5c3-6ad982f51461
# ╟─4656cd6b-4c61-49a1-b9c0-5107f8c5dfef
# ╟─ce93b6cc-9a05-42b6-be00-b617c36bab1a
# ╟─3a853565-a349-4102-9f85-f13c662a704c
# ╟─4b16cfc8-e77b-4044-a1c1-5fea5828fb4c
# ╟─ca937820-3cb9-4009-93db-0627fe430ab2
# ╟─0301eb8a-9363-49fc-8a96-5d4c5b353cf3
# ╟─205495c4-4060-48ed-b498-3bd6746c86fa
# ╠═7ce026fd-c884-41d4-89b4-7e5e7139fdc6
# ╟─0d53d881-4599-41dd-9d0e-2adf39230be5
# ╟─7a535689-29d0-4c97-88f7-d09b438d2270
# ╟─5890e3d7-bad6-4260-9584-d7694ce3659e
# ╟─b63d195b-a73f-4c72-9dc3-6e7cb216f153
# ╟─89af78f4-c51c-4fc1-a0a9-9279d6728f57
# ╟─101a3517-828b-445e-9939-550b6e6829c8
# ╠═b435bf1f-13ee-46ca-8c45-58680f286028
# ╠═95cb7031-67ae-4243-a07a-c2338ca9bd6e
# ╟─c4fd2716-a18a-49af-a317-44c677e40bbe
# ╟─e0a38f99-3c73-44e0-b4c2-9a9d694eae7e
# ╟─7b9eb8e9-943e-4a31-b0ec-1847e70fda6f
# ╟─aa22d898-b106-4812-b0b8-75f5908ee204
# ╠═fe94ed49-90cb-44ca-8308-60b76fe9ce93
# ╠═94757fc2-8858-499c-8d26-24844a89fc00
# ╟─e7772c4c-a41e-4ea0-88b4-1482ae155b4a
# ╠═eb2e8913-657a-4c48-93f1-d4b68cf1a990
# ╟─8bd2c9a8-7c12-4a10-b28a-ca6c4cf86619
# ╠═e7bae422-7ca6-4cfb-9278-7840a7be647f
# ╟─0516e98c-0a78-43b2-9aec-9d6698032a6e
# ╟─371d7e91-eb88-4220-ad38-0bc74f55c806
# ╟─e3862e23-8942-4c1e-98b0-e4f14b0be8de
# ╠═7e8b6d19-3a9b-41f4-8bfa-3cadc7e69334
# ╟─55b87adc-2bac-45ae-b8e2-f318502782f4
# ╟─6b5e0098-631d-4a5d-9333-a2ab7c6e95f8
# ╟─3c86bb43-8e17-46b2-8b5d-edad10a1a659
# ╠═2324f04a-f7a8-4fa5-85ca-034bdb1b0f03
# ╠═9f29f87e-bfe3-49a3-9377-53bf67e067b6
# ╠═6d9677c6-a158-4c42-9923-98b02f047cb5
# ╠═b1dc82b5-1044-43fa-8028-1a2127c2022a
# ╠═d6978e15-36fd-466f-94fe-d367642302a3
# ╟─a125fcfc-3859-4a7d-b8fb-68fbe3add529
# ╠═77bab67c-0d15-4821-8e8c-e02670da3736
# ╠═c3488041-e25e-46f4-95ee-a7aceebbaf38
# ╟─c105ab86-cadc-4c7c-932c-c4be9e9939ea
# ╠═c172f2c0-af21-4284-9158-627241078a41
# ╠═3b0e1117-3ef4-4418-9fc6-af4ed9d93f33
# ╠═53c55d04-0783-496f-bbf7-5fadd3c73c5b
# ╠═8cf7becb-17a7-4eba-8a31-620463f7e819
# ╟─6f115a34-53fe-4307-a9e3-c682dedf1ede
# ╠═fd6eaedc-3565-48a6-afc1-12eb9219c5bd
# ╠═6162ec42-6004-4677-aa89-aa3be386c79a
# ╠═a8b0673f-1df1-41b3-8863-6b2a0b316201
# ╠═be75072e-60b6-49f9-bb12-b5290d78ff84
# ╠═a9ec9994-5e06-4c55-a0b4-fb425447aa12
# ╠═f4f638ef-a490-4c16-a2b1-a67c13368b8b
# ╠═4752da81-340a-4af4-af80-1d2e448d18da
# ╠═b66a4a6f-7790-4329-8c3f-0a9372e57ef9
# ╟─84dfeb58-6223-4152-ba0c-fda3fb54f206
# ╟─19086a1f-e9f9-4ed5-b917-1c38cd8c7693
# ╠═0d928ac8-0c54-47df-9194-da6f0bf88fb5
# ╟─4902e862-2d00-44a7-bcca-9694fd3a63ff
# ╟─9564cb71-5cb1-44c8-8885-83b00496aa7b
# ╠═2c7e66b1-d916-468f-8da7-90b51c6febea
# ╠═3a08a729-92b4-4c0b-90d1-93c8599c5f6b
# ╠═a5ab9729-1cdb-446b-83e3-3131b54f23be
# ╠═bea7ce92-7559-4ad6-a759-7bcf0e4c429e
# ╠═7f54c6ec-6cdd-4b5f-b872-0c225e283bb0
# ╠═4a7fd2de-3cb0-4b1d-aeb6-b2b4c99144a4
# ╠═e61a9667-fe5c-4052-a99b-324f34f74a95
# ╠═68de661f-8d99-4d82-a069-c174f687eb78
# ╟─92850708-6e15-4ba6-bdbd-db7a41d2690a
# ╠═061223e6-15b4-412b-aafe-c06a02719f92
# ╠═6df4986b-8b68-4c8f-bd14-78b679b2eff3
# ╟─52d63c8d-6737-4512-a69b-124f1e8c9cd3
# ╠═99cb0490-4015-4c63-b288-a2905f950585
# ╟─8f573fba-fa84-4adc-a6cc-d1fd83c9f1ce
# ╠═9ead45ad-187b-4b28-b959-c5667be53a30
# ╟─803f5ec5-85e6-44ef-a56d-e9e40b04f1ac
# ╠═cd1fd248-de09-420c-8920-146fd2a7f0c2
# ╠═2fe0a097-acfe-421c-8230-dd67bb9d3855
# ╠═5d9a734e-8282-44ce-9b07-75c89abafc94
# ╠═808fc3bd-5ea2-414e-aec3-180e03f366ca
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
