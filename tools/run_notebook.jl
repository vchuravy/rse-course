if !isdir("pluto-deployment-environment") || length(ARGS) != 1
    error("""
    Run me from the root of the repository directory, using:

    julia tools/run_notebook.jl <notebook.jl>
    
    Where <notebook.jl> is the path to the notebook you want to run.
    """)
end

import Pkg
Pkg.activate("./pluto-deployment-environment")
Pkg.instantiate()


import Pluto

notebook_path = get(ARGS, 1, nothing)
if notebook_path === nothing
    println(stderr, "Usage: julia run_notebook.jl <notebook.jl>")
    exit(1)
end

notebook_path = abspath(notebook_path)
println("Running notebook: $notebook_path")

session = Pluto.ServerSession()
nb = Pluto.load_notebook(Pluto.tamepath(notebook_path))

Pluto.update_save_run!(session, nb, nb.cells; run_async=false, prerender_text=true)

errors = [(c.cell_id, c.output.body) for c in nb.cells if c.errored]

if isempty(errors)
    println("✓ Notebook ran successfully with no errors.")
else
    println("✗ $(length(errors)) cell(s) had errors:\n")
    for (id, body) in errors
        println("  Cell $id:")
        println("    ", body)
        println()
    end
    exit(1)
end
