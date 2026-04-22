### A Pluto.jl notebook ###
# v0.20.13

#> [frontmatter]
#> chapter = "3"
#> section = "3"
#> order = "10"
#> title = "Distributed programming with MPI.jl"
#> date = "2025-06-18"
#> tags = ["module3", "track_parallel"]
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

# ╔═╡ 162c5b86-1291-4c5c-b57c-d6ec97e653a5
begin
	using PlutoUI, PlutoTeachingTools
	using PlutoUI: Slider
	PlutoUI.TableOfContents(; depth=4)
end

# ╔═╡ f2ed84b7-4f12-4c8d-bc61-596c0d33d85c
ChooseDisplayMode()

# ╔═╡ 697369b1-2b76-4942-a18d-11938ddf3565
md"""
# Distributed computing with MPI.jl
"""

# ╔═╡ 277dc532-4b7d-11f0-030e-955824d10ad2
using MPI, Serialization, Statistics, StaticArrays

# ╔═╡ 60e4af7d-3baa-477d-b63d-6c4c691a5dcc
md"""
MPI stands for "Message Passing Interface" and is one of the oldest and most successful distributed programming paradigms.

We normally start an MPI program with `mpiexec` (see exercises), but this doesn't play nicely with Pluto. Here I use a `@mpi` macro to execute a block of code as a standalone MPI.

`mpiexec` starts a number of independent processes that execute the same program.
We can use API calls like `MPI.Comm_rank` and `MPI.Comm_size` to query which rank we are. 
"""

# ╔═╡ 4231220d-3c73-45fd-a4c3-7442c4850383
md"""
The `@mpi` macro executes a block as an MPI program. 

!!! note
    Each block is isolated from another, and as such you need to setup state independently.

!!! warning
    The `@mpi` macro is purely to make MPI work in Pluto for teaching, but should be **not** used for any real uses. Furthermore, always wrap your blocks in `let` and not `begin` to not confuse Pluto.
"""

# ╔═╡ 4d52cf16-979c-42ae-a067-def1e53e66c1
np = 4

# ╔═╡ 328603b6-bf0b-4306-8762-56656bf6391f
macro mpi(np, expr)
	path, io = mktemp()
	control_io_path = path * ".ji"
	println(io, "using MPI, Serialization")
	println(io, "__mpi = begin")
	println(io, expr)
	println(io, "end")
	println(io, """
	__mpi = MPI.gather(__mpi, MPI.COMM_WORLD; root=0)
	if MPI.Comm_rank(MPI.COMM_WORLD) == 0
		Serialization.serialize("$control_io_path", __mpi)
	end
	""")
	close(io)
	quote
		let np = $(esc(np))
			path = $path
			run(`$(mpiexec()) -np $(np) $(Base.julia_cmd()) --project=$(Base.active_project()) $(path)`)
		end
		v = Serialization.deserialize($control_io_path)
		rm($control_io_path)
		all(isnothing, v) ? nothing : v
	end
end

# ╔═╡ fb31b292-e628-4cee-bd85-6f6c00b433f5
md"""
When using MPI we are going to execute N (=$np) independent copies of a program.
"""

# ╔═╡ 2352cfbf-cd9d-4481-b261-3a4d11fc6de0
@mpi np let
	MPI.Init()
	n = rand()
	println(n)
end

# ╔═╡ 88702faf-0c08-47a1-8830-72c2d8979a50
md"""
As we can see the output of the program is mangled. 

!!! note
    Most often we only print from `rank == 0`.
"""

# ╔═╡ b22c2874-a415-446e-b4c4-6ed32ce5a238
@mpi np let
	MPI.Init()
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)

	if rank == 0
		println("Comm_size: $(MPI.Comm_size(comm))")
	end
end	

# ╔═╡ 56b3e63a-57b9-448d-b937-6c7daad24758
md"""
It can also help to print in "one shot"
"""

# ╔═╡ 52265844-c86c-4d10-9478-2496d5f94c67
@mpi np let
	MPI.Init()
	comm = MPI.COMM_WORLD
	print("""
		  Hello world, I am rank $(MPI.Comm_rank(comm)) of $(MPI.Comm_size(comm))
		  """)
	MPI.Barrier(comm) # wait for all processes to reach this point.
end

# ╔═╡ fc606b6c-8861-417a-8f6d-7afc2ba646a6
md"""
### Initialization and Finalization

As you may have noticed when we start an MPI program we have to explicitly call `MPI.Init`

In other programming languages you will have to use a corresponding `MPI.Finalize`, this is not necessary in Julia since we automatically execute `MPI.Finalize` when the program shuts down.
"""

# ╔═╡ 070761aa-13d3-4f53-9a73-ac30b03cff09
md"""
## Two-sided communication
"""

# ╔═╡ 59a9d7b1-bddf-41ca-9a2e-249b8cd4ba4e
md"""
### Blocking
"""

# ╔═╡ f94762a2-ad0c-4c7b-be19-bb3b44b4859f
@mpi 2 let
	function pingpong(T, sz, iters)
		buff = zeros(T, sz)
		comm = MPI.COMM_WORLD
		rank = MPI.Comm_rank(comm)
		
		MPI.Barrier(comm)
		tic = MPI.Wtime()

		for _ in 1:iters
			if rank == 0
				MPI.Send(buff, comm; dest=1)
				MPI.Recv!(buff, comm; source=1)
			else
				MPI.Recv!(buff, comm; source=0)
				MPI.Send(buff, comm; dest=0)
			end
		end
		toc = MPI.Wtime()

		return (toc-tic)/iters
	end
	
	MPI.Init()
	pingpong(Float64, 1024, 10)
end

# ╔═╡ 5edf95fa-b068-495e-a6f1-a1a227c9a060
md"""
!!! note
    The program above is limited to two ranks!

Let's send data around in a ring
"""

# ╔═╡ ac511f20-1aae-4f9c-acdc-408f3a34e8e7
@mpi np let
	MPI.Init()
	
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)
	N    = MPI.Comm_size(comm)

	@assert N > 1

	if rank != 0 
		token = MPI.recv(comm; source=rank-1)
		print("Rank $rank received token $token.\n")
	else
		token = -1
	end
	MPI.send(token, comm; dest=mod(rank+1, N))

	# Now rank 0 can receive the token
	if rank == 0
		token = MPI.recv(comm; source=N-1)
		print("Rank $rank received token $token.\n")
	end
	token
end

# ╔═╡ 60b2789a-4d3b-412b-89ee-1e6b4dd0c872
md"""
### Non-Blocking

It is quite tricky to reason about the order of `recv` and `send` across all processes. Note how we always have to set up some `recv` then perform the matching `send`. Then flip the operations.

`Irecv!` and `Isend` are non-blocking operations, that means we can issue them and wait later for them to be completed.

!!! note "Tagging"
    Since we now can have many operations in flight at once, one might need to tag the operations.
"""

# ╔═╡ 1eb52e1b-e38c-4485-a339-3d9cce9a2318
@mpi np let
	MPI.Init()

	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)
	N    = MPI.Comm_size(comm)

	# nonblocking receive from previous rank
	recv_buf = Array{Float64}(undef, 2)
	recv_req = MPI.Irecv!(recv_buf, comm; 
						  source=mod(rank-1, N),
						  tag=0)

	# nonblock send to next rank
	send_buf = Float64[rank, rank]
	send_req = MPI.Isend(send_buf, comm; 
						  dest=mod(rank+1, N),
						  tag=0)

	# block until communication is complete
	MPI.Waitall!([recv_req, send_req])
	print("$rank: Received $recv_buf\n")
end

# ╔═╡ 60d1d794-3e0e-4f65-bbf0-41c91638b5f5
md"""
#### Ghost-cells
"""

# ╔═╡ 20b200b1-7815-42c2-9eb2-d4aea6abd979
md"""
|   1   |  2-11   |  12 |
| ---   | ---     |  --- |
|  left |  mine   |  right |
"""

# ╔═╡ 0d6f5d5e-cd3e-4caf-9a16-b5759c01a898
@mpi np let
	MPI.Init()

	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)
	N    = MPI.Comm_size(comm)

	M = 10
	data = zeros(M+2)

	# Computation phase interior
	data[2:M+1] .= rank

	# Communication phase
	begin
		# Receive into ghost cells from neighbors
		left_recv = MPI.Irecv!(view(data, 1), comm; 
					  source=mod(rank-1, N),)
		right_recv = MPI.Irecv!(view(data, M+2), comm; 
					  source=mod(rank+1, N))
		
		# Send to neighbors
		left_send = MPI.Isend(view(data, 2), comm; 
					  dest=mod(rank-1, N),)
		right_send = MPI.Isend(view(data, M+1), comm; 
					  dest=mod(rank+1, N))

		# block until communication is complete
		MPI.Waitall!([left_recv, right_recv, left_send, right_send])
	end
	print("$rank: Received $data\n")

	# Computation phase ...
end

# ╔═╡ 2f36d91a-235b-4561-bc34-976c4edee4bc
md"""
## Collective communication and synchronization
"""

# ╔═╡ 310c2add-46fb-44aa-bf2a-c85e977f61b7
md"""
MPI defines a series of "collective" operations, operations that all processes within a communicator partake in.

We have already encountered the `MPI.Barrier` operation that forces all processes to wait.
"""

# ╔═╡ 62ee1c5f-6246-4338-9a11-b937b24107ad
md"""
One possible (but inefficient way) to implement a barrier is the ring communication example from above!

```julia
if rank != 0 
	token = MPI.recv(comm; source=rank-1)
	print("Rank $rank received token $token.\n")
else
	token = -1
end
MPI.send(token, comm; dest=mod(rank+1, N))

# Now rank 0 can receive the token
if rank == 0
	token = MPI.recv(comm; source=N-1)
	print("Rank $rank received token $token.\n")
end
```
"""

# ╔═╡ b18cf7cc-80fb-4ae2-81b6-462008844acd
md"""
We set-up a chain of blocking operations and the program can only continue thereafter!
"""

# ╔═╡ 63ae5b78-855f-485d-b3dc-a0e6ea9abdaa
md"""
### Broadcast

Sends data from 1 to N
"""

# ╔═╡ 60142b52-07be-4966-80f3-78f2cdcff43c
@mpi np let
	MPI.Init()
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)

	if rank == 0
		x = rand(3)
	else
		x = zeros(3)
	end

	MPI.Bcast!(x, comm; root=0)
	
	print("$rank: Received $x\n")
end	

# ╔═╡ d1f0f3b9-33ef-41e1-be86-c2f5675794cb
@mpi np let
	MPI.Init()
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)

	function my_bcast!(data, comm; root=0)
		rank = MPI.Comm_rank(comm)
		N    = MPI.Comm_size(comm)

		if rank == root
			# send data to all other ranks
			for other in 0:(N-1)
				if other != root
					MPI.Send(data, comm; dest=other)
				end
			end
		else
			MPI.Recv!(data, comm; source=root)
		end
	end

	if rank == 0
		x = rand(3)
	else
		x = zeros(3)
	end
	
	my_bcast!(x, comm; root=0)
	
	print("$rank: Received $x\n")
end	

# ╔═╡ bcd56bc6-d34d-4d22-a685-fc95ba2e13f2
md"""
MPI implementation may choose their own more efficient implementations! 
This implementation is inefficient since it is limited by the bandwidth of the root process. 

Better would be something like a communication tree!
"""

# ╔═╡ b603cab2-1d82-418c-9932-d85b07f8446f
@bind np_bench Select([2, 4, 8, 12], default=4)

# ╔═╡ caec4ec0-7f8c-47a5-a16c-4d884dbcf0fb
avg_my_bcast = mean(x->x[1], bcast_times)

# ╔═╡ af4838a3-6827-4aef-a8de-58ecba22c1f6
avg_mpi_bcast = mean(x->x[2], bcast_times)

# ╔═╡ ac49c9b5-d0cf-4de2-b62e-939243224d12
avg_mpi_bcast / avg_my_bcast

# ╔═╡ 9529bad3-d2f9-4b46-9124-12f1dc3d01a1
bcast_times = @mpi np_bench let
	function my_bcast!(data, comm; root=0)
		rank = MPI.Comm_rank(comm)
		N    = MPI.Comm_size(comm)

		if rank == root
			# send data to all other ranks
			for other in 0:(N-1)
				if other != root
					MPI.Send(data, comm; dest=other)
				end
			end
		else
			MPI.Recv!(data, comm; source=root)
		end
	end

	function benchmark(T, sz, iters)
		comm = MPI.COMM_WORLD
		data = zeros(T, sz)
		
		my_bcast_time = 0.0
		mpi_bcast_time = 0.0

		# warmup
		my_bcast!(data, comm)
		MPI.Bcast!(data, comm)

		for _ in 1:iters
			MPI.Barrier(comm)
			my_bcast_time -= MPI.Wtime()
			
			my_bcast!(data, comm)
			
			MPI.Barrier(comm)
			my_bcast_time += MPI.Wtime()
	
			MPI.Barrier(comm)
			mpi_bcast_time -= MPI.Wtime()
			
			MPI.Bcast!(data, comm)
			
			MPI.Barrier(comm)
			mpi_bcast_time += MPI.Wtime()
		end
		my_bcast_time/iters, mpi_bcast_time/iters
	end
			
	MPI.Init()
	benchmark(Float64, 400000, 10) # magical return to Pluto value
end

# ╔═╡ 2e18fc74-333a-41a6-97ca-a83c31b6d621
md"""
### Scatter

Scatter is very similar to broadcast. 

Broadcast sends the **same** data to all processes.
Scatter sends **chunks of an array** to different processes.
"""

# ╔═╡ cc6dfbdb-1ea6-427e-9fb2-1debb70b209e
@mpi np let
	MPI.Init()
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)
	N = MPI.Comm_size(comm)

	x = zeros(Int, 3)
	data = rank == 0 ? collect(1:N*3) : nothing
	MPI.Scatter!(data, x, comm; root=0)
	
	print("$rank: Received $x\n")
end	

# ╔═╡ f0781b91-db93-4f1e-a28a-ad26b3eb6b58
md"""
### Gather

Collect data from N to 1.

!!! note
    Gather is the inverse of scatter.
"""

# ╔═╡ a27e63c7-fc43-4d62-ac5c-d233112a6b39
md"""
In MPI communication is explicit! Let's generate `np`=$np random numbers and send them all to the root rank.
"""

# ╔═╡ c17a159f-80a4-402d-9188-df64439df062
@mpi np let
	MPI.Init()
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)

	x = rand()
	
	xs = rank == 0 ? zeros(MPI.Comm_size(comm)) : nothing
	
	if rank == 0
		@show xs
	end
	
	MPI.Gather!(Ref(x), xs, comm; root=0)
	
	if rank == 0
		@show xs
	end

	x # magical return to Pluto value
end	

# ╔═╡ 718200a4-43f4-422f-8ee9-cc0c188af185
md"""
!!! note
    `Ref(x)` is a one-element container, like `[x]`
"""

# ╔═╡ 2203f302-edf1-4d4e-86d9-714dc959b97a
@mpi np let
	MPI.Init()
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)

	x = rand()
	
	xs = MPI.Gather([x], comm; root=0)
	
	if rank == 0
		@show xs
	end

	x
end	

# ╔═╡ 3b3c8663-d874-43f9-9d5f-1b51fd3a7641
@mpi np let
	MPI.Init()
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)

	x = rand()
	
	xs = MPI.gather(x, comm; root=0)
	
	if rank == 0
		@show xs
	end

	x
end	

# ╔═╡ ed45ed02-31c2-4fae-9423-ab5592944ee4
md"""
MPI.jl often has three variants of functions:

- `Gather!`: Closest to the underlying MPI implementation, expects input and output buffer.
- `Gather`: Convinience function that allocates on the receiving side, expects and input buffer.
- `gather`: Handles arbitrary Julia objects and allocates on the receiving side.
"""

# ╔═╡ d8de40e4-117a-47ef-b3b4-4b313386052b
md"""
### Reduce

`Gather` moves all values from all ranks to one **root** rank. Instead of copying values and then manually reducing them, MPI supports an `MPI.Reduce` call.
"""

# ╔═╡ 3330098d-5f3e-40d3-bd03-9a4d61d81868
md"""
Compute $\int_0^1 \frac{4}{1+x^2} dx = [4 atan(x)]_0^1$ which evaluates to π
"""

# ╔═╡ 7072e0c0-8eae-403a-b6db-1ecffd213cf9
pis = @mpi np let
	MPI.Init()	
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)

	# TODO: Support $ interpolation into `@mpi` macro
	n = 50_000_000

	s = 0.0
    for i = MPI.Comm_rank(comm) + 1 : MPI.Comm_size(comm) : n 
        x = (i - .5)/n 
        s += 4/(1 + x^2) 
    end
    mypi = s/n
    our_π = MPI.Reduce(mypi, MPI.SUM, comm; root=0)
    if rank == 0
        println("Error our_π - π: $(our_π - π)") 
    end
    mypi
end	

# ╔═╡ 1bbb299a-e363-4c7e-8d95-9fcbdb8119ab
our_π = sum(pis)

# ╔═╡ c61394cf-46bc-4681-8f04-29cb04c1cd78
@mpi np let
	MPI.Init()
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)

	sum_of_ranks = MPI.Reduce(rank, +, comm; root=0)

	if rank == 0
	    println("sum of ranks = $(sum_of_ranks)")
	end
	sum_of_ranks
end

# ╔═╡ 603fa988-f242-404c-ab62-3a73240dc9b2
md"""
!!! note
    We can also use any *Julia* function and not just the limited set of reduction operators defined by the standard.
"""

# ╔═╡ 6fc7748b-b805-480e-b3ca-93f5188a4184
md"""
### Allgather and Allreduce

`Gather` and `Reduce` are N to 1 collectives and they have sibling varieties that perform an all-to-all communication.

"""

# ╔═╡ 2aed0562-08bd-40c6-9f0e-afb91a2f9468
@mpi np let
	MPI.Init()
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)

	sum_of_ranks = MPI.Allreduce(rank, +, comm)

	if rank == 0
	    println("sum of ranks = $(sum_of_ranks)")
	end
	sum_of_ranks
end

# ╔═╡ e4d6282b-1d59-475a-9dcf-2527b3f1019a
@mpi np let
	MPI.Init()
	comm = MPI.COMM_WORLD
	rank = MPI.Comm_rank(comm)

	ranks = MPI.Allgather([rank], comm)

	ranks
end

# ╔═╡ 3e35d02c-57e7-4e00-ac44-453de4b9f4f4
md"""
## Communicators
"""

# ╔═╡ e45fff5c-98cb-40cc-b67c-2fe8364c7567
md"""
So far we have been using

```julia
comm = MPI.COMM_WORLD
```

without much explanation. `MPI.COMM_WORLD` is the default communicator and contains all available ranks! Other communicators can be used to partition our computation.

- `MPI.COMM_SELF`: Just ourselves
- `MPI.COMM_TYPE_SHARED`: All ranks on one physical node
- `MPI.COMM_NULL`: Nobody

We can split our communicator!
"""

# ╔═╡ 39ae7540-34bd-4d5e-88a3-bffee04e2bdb
@mpi np let
	MPI.Init()
	world_rank = MPI.Comm_rank(MPI.COMM_WORLD)
	comm = MPI.Comm_split(
		MPI.COMM_WORLD, iseven(world_rank), world_rank)
	
	rank = MPI.Comm_rank(comm)

	print("World rank: $world_rank, Split rank: $rank\n")
end

# ╔═╡ 6d0c3123-c119-4524-9d4a-9c3a8452bd8b
md"""
!!! note
    `Comm_split` is probably the easiest way of splitting a communicator, but modern MPI uses MPI_Groups which are a bit more flexible.
"""

# ╔═╡ fb55a9a5-3236-4d45-9048-d6e6907d5e33
@mpi np let
	MPI.Init()
	world_rank = MPI.Comm_rank(MPI.COMM_WORLD)
	world_group = MPI.Comm_group(MPI.COMM_WORLD)

	odd_ranks = convert.(Int32, collect(1:2:MPI.Comm_size(MPI.COMM_WORLD)))
	odd_group = MPI.Group_incl(world_group, odd_ranks)
	even_group = MPI.Group_difference(world_group, odd_group)

	group = iseven(world_rank) ? even_group : odd_group
	comm = MPI.Comm_create_group(MPI.COMM_WORLD, group, #=tag=# 0) # non-collective only ranks in group must participate
	
	rank = MPI.Comm_rank(comm)

	print("World rank: $world_rank, Split rank: $rank\n")
end

# ╔═╡ 09e31cdd-dea2-43f0-80b3-dda182531e8d
md"""
We can also duplicate communicators! This can be important if you want to hand-off a communicator to a library (maybe one implemented in C/Fortran) and you are unable to negotiate a common tag scheme. Otherwise we might respond to messages meant for the library and not us!


"""

# ╔═╡ 731d0b9b-9d2d-41e8-a063-2e987262ce59
@mpi np let
	MPI.Init()
	world_rank = MPI.Comm_rank(MPI.COMM_WORLD)


	comm = MPI.Comm_dup(MPI.COMM_WORLD)
	rank = MPI.Comm_rank(comm)
	
	print("World rank: $world_rank, Other rank: $rank\n")
end

# ╔═╡ e42ab070-5a92-477c-9ae4-9124f0e2efc4
md"""
## Other examples
"""

# ╔═╡ b849153b-fe90-40ac-b64f-42034bc803fe
md"""
### Custom ops and custom data-types
"""

# ╔═╡ 5470f099-c1e7-4aa9-871f-4fb2f72c162b
@mpi np let
	using Statistics

	# Define a custom struct
	# This contains the summary statistics (mean, variance, length) of a vector
	struct SummaryStat
		mean::Float64
		var::Float64
		n::Float64
	end
	function SummaryStat(X::AbstractArray)
		m = mean(X)
		v = varm(X,m, corrected=false)
		n = length(X)
		SummaryStat(m,v,n)
	end

	# Define a custom reduction operator
	# this computes the pooled mean, pooled variance and total length
	function pool(S1, S2)
	    n = S1.n + S2.n
	    m = (S1.mean*S1.n + S2.mean*S2.n) / n
	    v = (S1.n * (S1.var + S1.mean * (S1.mean-m)) +
	         S2.n * (S2.var + S2.mean * (S2.mean-m)))/n
	    SummaryStat(m,v,n)
	end

	MPI.Init()
	comm = MPI.COMM_WORLD
	root = 0
	
	X = randn(10,3) .* [1,3,7]'

	# Perform a scalar reduction
	summ = MPI.Reduce(SummaryStat(X), pool, comm; root)

	if MPI.Comm_rank(comm) == root
    	@show summ.var
	end

	# Perform a vector reduction:
	# the reduction operator is applied elementwise
	col_summ = MPI.Reduce(mapslices(SummaryStat,X,dims=1), pool, comm; root)
	
	if MPI.Comm_rank(comm) == root
	    col_var = map(summ -> summ.var, col_summ)
	    @show col_var
	end
	nothing
end

# ╔═╡ c6ea28ed-7f99-4ceb-be03-81c575a9da71
md"""
#### Static Vectors
"""

# ╔═╡ 312d7d34-ff91-49c8-a6e8-980e7f75012a
@mpi np let
	using StaticArrays
	
	MPI.Init()
	comm = MPI.COMM_WORLD

	x = ones(SVector{3, Float64})
	sum = MPI.Allreduce([x], +, comm)

	if MPI.Comm_rank(comm) == 0
		@show sum
	end
	nothing
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Serialization = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
MPI = "~0.20.22"
PlutoTeachingTools = "~0.4.1"
PlutoUI = "~0.7.65"
StaticArrays = "~1.9.13"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "ac0c7c1d86dee59adec1107eb2119ebe1048afe0"

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

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

    [deps.ColorTypes.weakdeps]
    StyledStrings = "f489334b-da3d-4c2e-b8f0-e476e12c162b"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"
version = "1.11.0"

[[deps.DocStringExtensions]]
git-tree-sha1 = "7442a5dfe1ebb773c29cc2962a8980f47221d76c"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.5"

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

[[deps.Format]]
git-tree-sha1 = "9c68794ef81b08086aeb32eeaf33531668d5f5fc"
uuid = "1fa38f19-a742-5d3f-a2b9-30dd87b9d5f8"
version = "1.3.7"

[[deps.Hwloc_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "92f65c4d78ce8cdbb6b68daf88889950b0a99d11"
uuid = "e33a78d0-f292-5ffc-b300-72abe9b543c8"
version = "2.12.1+0"

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

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.MPI]]
deps = ["Distributed", "DocStringExtensions", "Libdl", "MPICH_jll", "MPIPreferences", "MPItrampoline_jll", "MicrosoftMPI_jll", "OpenMPI_jll", "PkgVersion", "PrecompileTools", "Requires", "Serialization", "Sockets"]
git-tree-sha1 = "892676019c58f34e38743bc989b0eca5bce5edc5"
uuid = "da04e1cc-30fd-572f-bb4f-1f8673147195"
version = "0.20.22"

    [deps.MPI.extensions]
    AMDGPUExt = "AMDGPU"
    CUDAExt = "CUDA"

    [deps.MPI.weakdeps]
    AMDGPU = "21141c5a-9bdb-4563-92ae-f87d6854732e"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"

[[deps.MPICH_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "TOML"]
git-tree-sha1 = "d72d0ecc3f76998aac04e446547259b9ae4c265f"
uuid = "7cb0a576-ebde-5e09-9194-50597f1243b4"
version = "4.3.1+0"

[[deps.MPIPreferences]]
deps = ["Libdl", "Preferences"]
git-tree-sha1 = "c105fe467859e7f6e9a852cb15cb4301126fac07"
uuid = "3da0fdf6-3ccc-4f1b-acd9-58baa6c99267"
version = "0.1.11"

[[deps.MPItrampoline_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "TOML"]
git-tree-sha1 = "e214f2a20bdd64c04cd3e4ff62d3c9be7e969a59"
uuid = "f1f71cc9-e9ae-5b93-9b94-4fe0e1ad3748"
version = "5.5.4+0"

[[deps.MacroTools]]
git-tree-sha1 = "1e0228a030642014fe5cfe68c2c0a818f9e3f522"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.16"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

[[deps.MicrosoftMPI_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bc95bf4149bf535c09602e3acdf950d9b4376227"
uuid = "9237b28f-5490-5468-be7b-bb81f5f5e6cf"
version = "10.1.4+3"

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

[[deps.OpenMPI_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Hwloc_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "MPIPreferences", "TOML", "Zlib_jll"]
git-tree-sha1 = "ec764453819f802fc1e144bfe750c454181bd66d"
uuid = "fe0851c0-eecd-5654-98d4-656369965a5c"
version = "5.0.8+0"

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

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f9501cc0430a26bc3d156ae1b5b0c1b47af4d6da"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.3"

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "Latexify", "Markdown", "PlutoUI"]
git-tree-sha1 = "537c439831c0f8d37265efe850ee5c0d9c7efbe4"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.4.1"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "3151a0c8061cc3f887019beebf359e6c4b3daa08"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.65"

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

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"
version = "1.11.0"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "0feb6b9031bd5c51f9072393eb5ab3efd31bf9e4"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.13"

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

    [deps.StaticArrays.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

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
git-tree-sha1 = "24c1c558881564e2217dcf7840a8b2e10caeb0f9"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.0"

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
# ╠═162c5b86-1291-4c5c-b57c-d6ec97e653a5
# ╠═f2ed84b7-4f12-4c8d-bc61-596c0d33d85c
# ╟─697369b1-2b76-4942-a18d-11938ddf3565
# ╠═277dc532-4b7d-11f0-030e-955824d10ad2
# ╟─60e4af7d-3baa-477d-b63d-6c4c691a5dcc
# ╟─4231220d-3c73-45fd-a4c3-7442c4850383
# ╠═4d52cf16-979c-42ae-a067-def1e53e66c1
# ╟─328603b6-bf0b-4306-8762-56656bf6391f
# ╟─fb31b292-e628-4cee-bd85-6f6c00b433f5
# ╠═2352cfbf-cd9d-4481-b261-3a4d11fc6de0
# ╟─88702faf-0c08-47a1-8830-72c2d8979a50
# ╠═b22c2874-a415-446e-b4c4-6ed32ce5a238
# ╟─56b3e63a-57b9-448d-b937-6c7daad24758
# ╠═52265844-c86c-4d10-9478-2496d5f94c67
# ╟─fc606b6c-8861-417a-8f6d-7afc2ba646a6
# ╟─070761aa-13d3-4f53-9a73-ac30b03cff09
# ╟─59a9d7b1-bddf-41ca-9a2e-249b8cd4ba4e
# ╠═f94762a2-ad0c-4c7b-be19-bb3b44b4859f
# ╟─5edf95fa-b068-495e-a6f1-a1a227c9a060
# ╠═ac511f20-1aae-4f9c-acdc-408f3a34e8e7
# ╟─60b2789a-4d3b-412b-89ee-1e6b4dd0c872
# ╠═1eb52e1b-e38c-4485-a339-3d9cce9a2318
# ╟─60d1d794-3e0e-4f65-bbf0-41c91638b5f5
# ╟─20b200b1-7815-42c2-9eb2-d4aea6abd979
# ╠═0d6f5d5e-cd3e-4caf-9a16-b5759c01a898
# ╟─2f36d91a-235b-4561-bc34-976c4edee4bc
# ╟─310c2add-46fb-44aa-bf2a-c85e977f61b7
# ╟─62ee1c5f-6246-4338-9a11-b937b24107ad
# ╟─b18cf7cc-80fb-4ae2-81b6-462008844acd
# ╟─63ae5b78-855f-485d-b3dc-a0e6ea9abdaa
# ╠═60142b52-07be-4966-80f3-78f2cdcff43c
# ╠═d1f0f3b9-33ef-41e1-be86-c2f5675794cb
# ╟─bcd56bc6-d34d-4d22-a685-fc95ba2e13f2
# ╠═b603cab2-1d82-418c-9932-d85b07f8446f
# ╠═caec4ec0-7f8c-47a5-a16c-4d884dbcf0fb
# ╠═af4838a3-6827-4aef-a8de-58ecba22c1f6
# ╠═ac49c9b5-d0cf-4de2-b62e-939243224d12
# ╠═9529bad3-d2f9-4b46-9124-12f1dc3d01a1
# ╟─2e18fc74-333a-41a6-97ca-a83c31b6d621
# ╠═cc6dfbdb-1ea6-427e-9fb2-1debb70b209e
# ╟─f0781b91-db93-4f1e-a28a-ad26b3eb6b58
# ╟─a27e63c7-fc43-4d62-ac5c-d233112a6b39
# ╠═c17a159f-80a4-402d-9188-df64439df062
# ╟─718200a4-43f4-422f-8ee9-cc0c188af185
# ╠═2203f302-edf1-4d4e-86d9-714dc959b97a
# ╠═3b3c8663-d874-43f9-9d5f-1b51fd3a7641
# ╟─ed45ed02-31c2-4fae-9423-ab5592944ee4
# ╟─d8de40e4-117a-47ef-b3b4-4b313386052b
# ╟─3330098d-5f3e-40d3-bd03-9a4d61d81868
# ╠═7072e0c0-8eae-403a-b6db-1ecffd213cf9
# ╠═1bbb299a-e363-4c7e-8d95-9fcbdb8119ab
# ╠═c61394cf-46bc-4681-8f04-29cb04c1cd78
# ╟─603fa988-f242-404c-ab62-3a73240dc9b2
# ╟─6fc7748b-b805-480e-b3ca-93f5188a4184
# ╠═2aed0562-08bd-40c6-9f0e-afb91a2f9468
# ╠═e4d6282b-1d59-475a-9dcf-2527b3f1019a
# ╟─3e35d02c-57e7-4e00-ac44-453de4b9f4f4
# ╟─e45fff5c-98cb-40cc-b67c-2fe8364c7567
# ╠═39ae7540-34bd-4d5e-88a3-bffee04e2bdb
# ╟─6d0c3123-c119-4524-9d4a-9c3a8452bd8b
# ╠═fb55a9a5-3236-4d45-9048-d6e6907d5e33
# ╟─09e31cdd-dea2-43f0-80b3-dda182531e8d
# ╠═731d0b9b-9d2d-41e8-a063-2e987262ce59
# ╟─e42ab070-5a92-477c-9ae4-9124f0e2efc4
# ╟─b849153b-fe90-40ac-b64f-42034bc803fe
# ╠═5470f099-c1e7-4aa9-871f-4fb2f72c162b
# ╟─c6ea28ed-7f99-4ceb-be03-81c575a9da71
# ╠═312d7d34-ff91-49c8-a6e8-980e7f75012a
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
