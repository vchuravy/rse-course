# Load every _data/*.jl file and return a Dict keyed by filename stem.
# Include this file with Base.include(@__MODULE__, ...) from any template
# that needs the `metadata` variable.
Dict(
    splitext(basename(f))[1] => Base.include(@__MODULE__, f)
    for f in readdir(joinpath(@__DIR__, "..", "_data"); join=true) if endswith(f, ".jl")
)
