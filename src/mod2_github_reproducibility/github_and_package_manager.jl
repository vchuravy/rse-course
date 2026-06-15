### A Pluto.jl notebook ###
# v0.20.24

#> [frontmatter]
#> chapter = "2"
#> section = "1"
#> order = "5"
#> title = "Github & Package Manager"
#> date = "2026-05-14"
#> tags = ["module2", "track_principles"]
#> layout = "layout.jlhtml"
#> 
#>     [[frontmatter.author]]
#>     name = "Valentin Churavy"
#>     url = "https://vchuravy.dev"

using Markdown
using InteractiveUtils

# ╔═╡ 0adedfb9-edfc-424d-8bcb-8bb9c6555d92
using PlutoUI, PlutoTeachingTools

# ╔═╡ d4b60dfe-0067-47ec-8608-9a34e088aeae
using Kroki

# ╔═╡ 03335a53-18de-47f8-87b0-d0c742e52f72
ChooseDisplayMode()

# ╔═╡ 41dcefbb-8b3d-41a0-ab14-ad6ec52294a1
TableOfContents()

# ╔═╡ aabb0001-0001-4000-8000-000000000001
md"""
# Reproducibility

Two questions:

1. Does my code **execute** on another computer
    - Can someone else do it without my intervention
2. Do we calculate the same results?
"""

# ╔═╡ b9ab169a-451f-4d45-8e98-2965e4284153
md"""
Should be easy right?

```sh
git clone https://github.com/vchuravy/FancyProject
cd FancyProject
julia run_script.jl
```

What can go wrong? 
- What version of Julia did I use?
- What Julia packages did I use?
- Which version of those Julia packages did I use?
    - Which version of all the transitive dependencies did I use?
"""

# ╔═╡ 4f012dd5-372c-4f16-9ca1-b15de79c446f
md"""
!!! note
    And what is this `git`?
"""

# ╔═╡ 87b6ebd8-2c07-4750-aeba-8ce237403689
md"""
## How does Julia know which package can be loaded.

[`LOAD_PATH`](https://docs.julialang.org/en/v1/base/constants/#Base.LOAD_PATH) describes the stacked environment. When doing an `import`/`using` (called a require operation) we search the stack for a matching package.

In the REPL:

```julia-repl
julia> Base.LOAD_PATH
3-element Vector{String}:
 "@"
 "@v#.#"
 "@stdlib"
```

##### References:
- [Code loading](https://docs.julialang.org/en/v1/manual/code-loading/#code-loading)
"""

# ╔═╡ d2bf5326-3c40-4cb4-9f4d-fde6136b85a0
Base.LOAD_PATH

# ╔═╡ 4087f982-1854-4d30-8ae0-50bbfd1fbf29
Base.load_path()

# ╔═╡ 7431db21-4a9b-47f3-9ff6-26eeb544b975
@doc Base.LOAD_PATH

# ╔═╡ 1a331491-56b9-4906-acce-07c95f150809
md"""
### Active project

The `@` entry in the `LOAD_PATH` corresponds to the active project:

```sh
julia --project=.
```

or 

```sh
JULIA_PROJECT="." julia
```

You can query the current active project with `Base.active_project()` and switch the active project with `Base.set_active_project()`

!!! warning
    When you switch projects inside a Julia session, you are combining "partial state". You might have loaded incompatible package versions!

!!! note
    In many older docs you will see `Pkg.activate` instead of `Base.set_active_project` which was only added in Julia 1.8.
"""

# ╔═╡ e70cbf6f-488f-4d5c-a097-7e36bd445f67
md"""
## Julia's package manager: Pkg.jl
"""

# ╔═╡ 41ee91a9-fc53-4658-a1c8-8501b05abf33
Base.active_project()

# ╔═╡ 515ced98-05a3-4a3f-99a6-988f38a10ebb
md"""
!!! note
    In Pluto the package-manager is tightly integrated. This leads to reproducible note-books. Open a Pluto notebook in an editor! What do you see? 
"""

# ╔═╡ 59560685-e835-4bb7-aece-e85432aaac5f
md"""
Two modes of interaction:

1. In the repl use `]` to switch
2. `import Pkg; Pkg.add(...)`

Read:
- [Getting started with Pkg.jl](https://pkgdocs.julialang.org/v1/getting-started/)
- [Managing packages](https://pkgdocs.julialang.org/v1/managing-packages/)
"""

# ╔═╡ 8b2a9fd1-b832-4bae-a53d-745edc238fd1
md"""
### Project.toml

A `Project.toml` describes the dependenencies of a project or a package

```toml
name = "App"
uuid = "8f986787-14fe-4607-ba5d-fbff2944afa9"

[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"

[compat]
BenchmarkTools = "1.6"
julia = "1.10"
```

A package is a project with a name and a UUID.

```toml
name = "App"
uuid = "8f986787-14fe-4607-ba5d-fbff2944afa9"
```

The `[deps]` section maps names to `UUID`

```toml
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
```

The `[compat]` section restricts the version of dependencies

```toml
[compat]
BenchmarkTools = "1.6"
julia = "1.10"
```

!!! note
    There is a special entry for Julia.
"""

# ╔═╡ fec70833-4bd5-4663-a17f-3f568cb0a414
md"""
### Manifest.toml

The Manifest is an auto-generated **record** of all the transitive dependencies.

!!! note
    Exact reproducibility is only gurantueed when using the same Julia version and the same `Manifest.toml`

```toml
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
manifest_format = "2.0"
project_hash = "cb14032aabe4b0376e6dcb58a497b54adc5b92d1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
version = "1.11.0"

...
```
"""

# ╔═╡ 73ae8c08-dbbf-4b0a-9795-4a3eb9bba11b
md"""
!!! note
    The `Manifest.toml` is version dependent! Note the recorded Julia version.
    Since Julia 1.11, we have access the Julia version specific manifests.

    - `Manifest.toml`: Fallback and only option for 1.10
    - `Manifest-v1.11.toml`: Will be preferentiably read by 1.11 and ignored by all else.
"""

# ╔═╡ 4c2d481d-61f9-4506-9789-3c4633f81253
md"""
### Compatibility

```toml
[compat]
BenchmarkTools = "1.6"
julia = "1.10"
```

Julia uses [semantic versioning](https://semver.org/) `vX.Y.Z`. `X` is the major version, `Y` is the minor version, `Z` is the patch version, with an exception for leading zeros. 

1. MAJOR version when you make incompatible API changes
2. MINOR version when you add functionality in a backward compatible manner
3. PATCH version when you make backward compatible bug fixes

When you write a version specifier `1.2.3` it is assumed to be compatible with `[1.2.3 - 2.0.0)` where `)` is a non-inclusive upper-bound.

Julia has two specifiers:

1. **Caret specifier**: `^1.2.3` (the default and equivalent to `1.2.3`)
2. **Tilde specifier**: `~1.2.3`

Julia also supports sets of multiple version specifiers

```
[compat]
Example = "1.2, 2"
```

Will result in `[1.2.0, 3.0.0)`.

#### Leading zeros `0.0.x` and `0.x.y`

The first non-zero version acts as a major version.

```
[compat]
Example = "0.2.1"
```

Will result in `[0.2.1, 0.3.0)`.

#### Caret specifier

A caret (`^`) specifier allows upgrade that would be compatible according to semantic versioning.

```
[compat]
PkgA = "^1.2.3" # [1.2.3, 2.0.0)
PkgB = "^1.2"   # [1.2.0, 2.0.0)
PkgC = "^1"     # [1.0.0, 2.0.0)
```

#### Tilde specifier

A tilde specifier provides more limited upgrade possibilities. When specifying major, minor and patch versions, or when specifying major and minor versions, only the patch version is allowed to change. If you only specify a major version, then both minor and patch versions are allowed to be upgraded (`~1` is thus equivalent to `^1`). For example:

```
[compat]
PkgA = "~1.2.3" # [1.2.3, 1.3.0)
PkgB = "~1.2"   # [1.2.0, 1.3.0)
PkgC = "~1"     # [1.0.0, 2.0.0)
```

#### Other specifier

You can also express **equality** and **inequality**, as well as ranges.

See [Compatibility](https://pkgdocs.julialang.org/v1/compatibility/) for more information.
"""

# ╔═╡ 2af11cad-cc8b-4409-a1fd-7bcc2c729c17
md"""
## Workflow
"""

# ╔═╡ e2663784-2c02-419c-9965-2989631fd307
md"""
1. Clone repository
2. Check if the repository has a `Project.toml`
    - If not, yell at the author
    - Check the `[deps]` section, is there an entry for every dependency?
3. Check the project for a `Manifest.toml`
```sh
head -n 3 Manifest.toml
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.5"
```
4. Instantiate the manifest `julia +1.11 --project=. -e "import Pkg; Pkg.instantiate()"`


!!! note
    Instantiate will not resolve the environment again, it will just install all the dependencies listed in the `Manifest.toml`. Make sure to match the version.
"""



# ╔═╡ 0be73b29-7780-4be0-bf07-9b62c99fc4b4
md"""
# Git & Github
"""

# ╔═╡ ecaaf7eb-f748-4ab8-99e8-63c436f2045b
md"""
## What is Git?

[Git](https://git-scm.com/) is a **d**istributed-**v**ersion-**c**ontrol-system.

1. Version-Control-System
    - Keeps track of "state" of a repository.
    - Keeps a history of previous changes
2. Distributed
    - Local-first
    - Many different "views" on the state of the project
    - Explicit synchronization
"""

# ╔═╡ c6a2d68f-b8c0-4d77-82a8-265a287336f2
md"""
!!! note 
    The [GitBook](https://git-scm.com/book/en/v2) is a useful resource.
"""

# ╔═╡ 1c908c9e-f287-4f35-85a8-0089b1104838
md"""
### Git concepts

- **Repository**: A top-level folder tracked by git. 
- **Checkout**: The current local state of the working directory.
- **Commit**: A set of changes.
- **Hash**/**SHA**: The hash of a commit (includes the history/parents).
- **Tag**: A named commit.
- **Branch**: A named "state" currently pointing at a commit.
"""

# ╔═╡ d5a72daf-b1dc-4e42-8d01-73a358b48a36
md"""
### Git commands
"""

# ╔═╡ 4d9710dd-ebd8-4a60-a2d6-b43ce9b6a990
md"""
#### `git init`

```sh
> mkdir MyPackage.jl
> cd MyPackage.jl
> git init
Initialized empty Git repository in /tmp/MyPackage.jl/.git/
```

Creates the `.git` folder and initializes a git repository.

!!! note
    `git` will walk up the directory tree until it finds a `.git` folder. 
"""

# ╔═╡ a375415a-b89c-4155-bf34-cd66c37407af
mermaid"""
gitGraph
"""

# ╔═╡ d87edbd4-e75c-4a97-9a10-c581a698e923
md"""
#### `git status`

```sh
> git status 
On branch main

No commits yet

nothing to commit (create/copy files and use "git add" to track)
```
"""

# ╔═╡ a0626ce0-5969-475c-ab18-5dcf6bb36732
md"""
#### `git add`
"""

# ╔═╡ 2c682f34-0164-4840-a52f-fe06f17a2456
md"""
```sh
> echo "# MyPackage" > README.md
> git status
On branch main

No commits yet

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	README.md

nothing added to commit but untracked files present (use "git add" to track)
```
"""

# ╔═╡ 15e93a07-c0a9-4fd6-b84c-4055ec79e78a
md"""
```sh
> git add README.md
> git status
On branch main

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
	new file:   README.md
```
"""

# ╔═╡ 53366fdd-1558-4b07-98f4-6a898004b923
md"""
Git has three simultaneous "states"

- The state of the current commit
- The state of the working directory: **untracked**
- The "staged" state: "Changes to be committed"
"""

# ╔═╡ 278d924c-b4f6-4802-98da-a67797b3d426
md"""
!!! note
	`git add -p` is an **extremely** useful variant that let's you see what changes you are staging.
"""

# ╔═╡ 31cae475-1cba-466a-a87c-cc4dfd03d552
md"""
#### `git commit`

Git commit creates a new commit.

```sh
> git commit -m "initial commit"
[main (root-commit) d3af9e2] initial commit
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
```

```sh
> git status
On branch main
nothing to commit, working tree clean
```
"""

# ╔═╡ 177d84b7-8d25-4978-822e-cf07091b1f63
mermaid"""
gitGraph
  commit
"""

# ╔═╡ e112373c-24fd-4e0d-8766-a5cfb1747f78
md"""
#### `git log`
```sh
> git log
commit d3af9e273c4b1d42fca6093f63a9560a3b2cf767 (HEAD -> main)
Author: Valentin Churavy <...>
Date:   Tue May 13 18:28:24 2025 +0200

    initial commit
```
"""

# ╔═╡ 6756ace4-eab3-47e7-9fdf-abcfb37029e5
md"""
!!! note
    If you need to remove a file from Git, you can use the `git rm` command.
    Note, that this only removes the file from the current commit, but it's previous content is always available in the history.
"""

# ╔═╡ c4053d4f-fadf-4b87-8f2d-ca4c2166c46d
md"""
#### Working with branches
"""

# ╔═╡ 9f48c2dd-f445-4efd-91f2-35d0bbcae765
md"""
##### `git branch`
```sh
> git branch
* main
```

```sh
> git branch -v
* main 504d898 initial commit
```
"""

# ╔═╡ f5973d0a-043d-4cdc-ba79-15e9a3eb3046
md"""
You can use `git branch` to create a new branch
```sh
> git branch develop
```

```sh
> git branch -v
* develop 504d898 initial commit
* main 504d898 initial commit
```
"""

# ╔═╡ 363ebe92-ea01-43f9-9150-a01609a6cfca
md"""

Deleting a branch.

```sh
> git branch -D develop
```
"""

# ╔═╡ 8e402dae-e10a-4736-bdd8-e2844f79d859
mermaid"""
gitGraph
  commit
"""

# ╔═╡ f6e64181-479b-47b3-99d2-405ed2b9be15
md"""
##### `git switch`

`git switch` switches branches!

```sh
> git switch develop
```

!!! note
    You will sometimes see me use `git checkout` instead, which is an older form.
    [Learn more!](https://refine.dev/blog/git-switch-and-git-checkout/#using-git-switch-vs-git-checkout)
"""

# ╔═╡ 1e1a58b4-98a9-4b27-be11-b67fc329a6a6
md"""
With `-c` git switch creates a new branch.

```sh
> git switch -c feature
```

"""

# ╔═╡ 05ad0829-84ed-494f-80bb-c1da1991a238
md"""
##### `git merge`

Given a state that looks like this, we may want to add changes from `feature` back to `main`.
"""

# ╔═╡ 54fac0b7-e3d0-4bb2-a9cb-34a4ec629422
mermaid"""
gitGraph
  commit
  branch feature
  commit
  commit
"""

# ╔═╡ 7515ed27-d5c6-45c1-8793-12e5db294983
md"""
```sh
> git switch main
> git merge feature
```
"""

# ╔═╡ 1bae1dbb-c428-406e-ad22-be4255c47fdc
mermaid"""
gitGraph
  commit
  branch feature
  commit
  commit
  checkout main
  merge feature
"""

# ╔═╡ 80e832d7-ede2-4e13-86fd-f92429a53011
md"""
Due to the nature of Git, work may have happen on `main`
"""

# ╔═╡ 3cd28b53-281c-4934-a399-eb75f64cf5a6
mermaid"""
gitGraph
  commit
  branch feature
  commit
  commit
  checkout main
  commit
"""

# ╔═╡ 6f021238-0d2f-4821-b407-a230dc7814bc
md"""
```sh
> git switch feature
> git merge main
```
"""

# ╔═╡ 7efce24a-c294-4c26-8297-76cd0fb12081
mermaid"""
gitGraph
  commit
  branch feature
  commit
  commit
  checkout main
  commit
  checkout feature
  merge main
"""

# ╔═╡ 02c596c5-080f-4c5a-98c9-cd13b32df5c3
md"""
##### `git rebase`

Instead of merging a branch we may want to `rebase`. Rebase is particularly useful when working with feature branches and it's variant `git rebase -i` allows you to cleanup your messy state.
"""

# ╔═╡ 70fd6057-1f46-414f-b0b8-0928fde77341
mermaid"""
gitGraph
  commit id: "A"
  branch feature
  commit id: "B"
  commit id: "C"
  checkout main
  commit id: "D"
"""

# ╔═╡ ecc31d48-35ca-4e89-986f-cc2f191b26b9
md"""
```sh
> git switch feature
> git rebase main
```
"""

# ╔═╡ 3d6871e7-bb7a-4276-8180-b5f388a73cc9
mermaid"""
gitGraph
  commit id: "A"
  commit id: "D"
  branch feature
  commit id: "B"
  commit id: "C"
"""

# ╔═╡ 168d9204-4aa3-4c3a-8c62-7dd4af5dba15
md"""
#### `git stash`

A more advanced utility command is `git stash`.

It "saves" the current state of your working directory

"""

# ╔═╡ 8fcfbb4a-940c-44bd-9528-d7d18ff27cbb
md"""
```sh
> echo "Hey" > README.md
> git status
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
```
"""

# ╔═╡ e907d4a0-e904-41eb-be39-b6ef8a1679d4
md"""
```sh
> git diff
diff --git a/README.md b/README.md
index f266118..a72832b 100644
--- a/README.md
+++ b/README.md
@@ -1 +1 @@
-# MyPackage
+Hey
```
"""

# ╔═╡ 25de521d-2f56-4e5b-ae87-b8f7312796d3
md"""
```sh
> git stash
Saved working directory and index state WIP on main: 504d898 initial commit
> git status
On branch main
nothing to commit, working tree clean
```
"""

# ╔═╡ cea48abe-5d02-4e3b-8781-3eae51545481
md"""
```sh
> git stash list
stash@{0}: WIP on main: 504d898 initial commit
> git stash pop
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   README.md

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{0} (a6287e30602f575adba45fa10ee48ee48e0326fc)
> git stash list
```
"""

# ╔═╡ b970dc0b-9991-4849-a6d9-099e19471946
md"""
!!! note
    `git stash` only works for current dirty files. Use `git stash -s` for all files.
"""

# ╔═╡ ffdc7bb5-9cec-42b5-9819-78ca7beabf6c
md"""
#### Working with remotes

A remote is a Git repository "somewhere" else. Most often this means it's hosted on Github or another Git forge like Gitlab.
"""

# ╔═╡ 14e24118-fa8b-4d50-9e23-0f3901a7a1be
md"""
The core commands are

- `git fetch` & `git pull` to synchronize the state of a repository
- `git push` to publish the state of our local repository
"""

# ╔═╡ 29ccbb9d-edef-4101-99c6-15c417a41d1f
md"""
Checking with `git remote` we can see that we currently don't have a remote setup
"""

# ╔═╡ 8cb9853d-3bc1-4e78-bc2b-3a2aa4f328cb
md"""
```sh
> git remote
```
"""

# ╔═╡ 3955fc29-e3c3-49a1-b4dd-1864111eabe4
md"""
## Github
"""

# ╔═╡ 30f74532-20f9-4f80-bdfd-01cbcd3e68ff
md"""
Going to [https://github.com/new](https://github.com/new) allows use setup a new repository.

Doing that without ticking any of the boxes, presents us with two options.
"""

# ╔═╡ 627af63b-d863-495c-b2ee-e101746c49e5
md"""

**…or create a new repository on the command line**
```
echo "# MyPackage.jl" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/vchuravy/MyPackage.jl.git
git push -u origin main
```

**…or push an existing repository from the command line**
```
git remote add origin https://github.com/vchuravy/MyPackage.jl.git
git branch -M main
git push -u origin main
```
"""

# ╔═╡ c86e608a-1a6e-4fbd-9584-e1d3de905f1c
md"""
Since we already have a local repository setup we choose the second option.

!!! note
    To authenticate to Github there are two different ways.
    1. Passwords
    2. SSH-Keys
"""

# ╔═╡ 82cbab70-a328-4bd2-b084-b292ed3a85aa
md"""
!!! note
    The [Github CLI](https://cli.github.com/) simplifies some of these operations.
"""

# ╔═╡ b0b37d43-8001-405a-8f67-73e94c8d41b5
md"""
```sh
> git remote add origin git@github.com:vchuravy/MyPackage.jl.git
> git branch -M main
> git push -u origin main
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Writing objects: 100% (3/3), 229 bytes | 229.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To github.com:vchuravy/MyPackage.jl.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```
"""

# ╔═╡ 88b670c9-6ba2-4c92-8abb-dc33bc3d4191
md"""
```sh
> git remote -v
origin	git@github.com:vchuravy/MyPackage.jl.git (fetch)
origin	git@github.com:vchuravy/MyPackage.jl.git (push)
```
"""

# ╔═╡ d93f3b6f-a727-4c5c-9069-c9f171ae94fe
md"""
### What to do on a merge conflict!?

When working with other people each local repository may diverge from the common root. So sometimes you may run into merge conflicts.
"""

# ╔═╡ b3b3d443-ea18-456a-aabf-23c2b2f854db
md"""
When a  merge conflict occurs you will see something like:

```
<<<<<<< HEAD
this is some content to mess with
content to append
=======
totally different content to merge later
>>>>>>> new_branch_to_merge_later
```

You need to choose which side of the merge you want, and maybe you need to combine them! I recommend VS Code for this.
"""

# ╔═╡ f25b352a-52b1-424d-8d4a-da210cbd442f
md"""
# Julia & Github
"""

# ╔═╡ a88718a1-ba41-40ef-b09f-fc53ed70893d
md"""
!!! note
	Below we will walk through the manual setup of a Julia reposirtory,
	but you may want to use [`PkgTemplates.jl`](https://github.com/JuliaCI/PkgTemplates.jl) to simplify the initial setup.
"""

# ╔═╡ 14ee3dcc-9070-49f4-a562-0f8ba918d87f
md"""
## Structure of a Julia Github repository

```shell
.github/workflows/
src/
  MyPackage.jl
test/
  Project.toml
  runtests.jl
docs/
  src/
  Project.toml
  make.jl
benchmark/
  Project.toml
  benchmarks.jl
Project.toml
README.md
LICENSE.md
.gitignore
```
"""

# ╔═╡ c14d85f3-9d4d-4ec6-a15b-4918a5761312
md"""
### Licensing

There are many licenses to choose from. In short a license protects you and others and allows you to use other people code without being sued later...

[Chose A License](https://choosealicense.com/)

The Julia community at large prefers the [MIT license](https://choosealicense.com/licenses/mit/).

When contributing to someone elses project check the license!

The most important thing is that it is something like an [OSI Approved License](https://opensource.org/licenses) and not something made up.
"""

# ╔═╡ 24203379-cc7b-451a-b52b-02f0075563f5
md"""
### `Project.toml`
```toml
name = "MyPackage"
uuid = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
authors = ["Author <author@somehost.de>"]
version = "0.1.0"

[deps]
Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"

[compat]
Enzyme = "0.13.41"
```
"""

# ╔═╡ b115a56b-600a-4032-a42b-6ff5172b7417
md"""
```
] generate MyPackage
```
"""

# ╔═╡ 10b96a54-9d02-4fbf-ba69-d8c27304c48a
md"""
### Testing: `test/`

A foundational best practice for research software development is testing.
Testing can both be

1. Unit-tests: Small scale test of functionality
2. End-to-end tests: Testing that a task functions

Julia has the [`Test.jl`](https://docs.julialang.org/en/v1/stdlib/Test/) package that helps to write unit tests.

Other helpful package:
- [ParallelTestRunner.jl](https://github.com/JuliaTesting/ParallelTestRunner.jl)

#### `runtests.jl`
```julia
using Test
using MyPackage

@testset "Group of Tests" begin
	@test my_fun() == 1
	@test_broken my_other_fun() == 2 
end
```

#### `Project.toml`

```toml
[deps]
MyPackage = "..."
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[sources]
MyPackage = {path = ".."}
```


"""

# ╔═╡ 3712e9a2-eeea-444f-9741-4576f3b7d49a
md"""
### Documentation

The package [`Documenter.jl`](https://documenter.juliadocs.org/) turns doc-strings and manual written docs into an webpage.

#### Doc-strings
"""

# ╔═╡ 3a2b059a-15c0-40e3-8f62-b1b2acc6d676
"""
    toss_coin(p=0.5)::Bool

Toss a coin to your witcher.

### Arguments
- `p`: The propability that the coin comes up head.
"""
function toss_coin(p=0.5)
	rand() < p
end

# ╔═╡ 1944a721-3b5d-402c-b78f-0449af1c787f
md"""
!!! note
	The [Documenter Guide](https://documenter.juliadocs.org/stable/man/guide/) has a full setup.
"""

# ╔═╡ 0dbbf025-b5db-4be7-a720-162beadc5d20
md"""
### Benchmarking

- Using [`BenchmarkTools.jl`](https://github.com/JuliaCI/BenchmarkTools.jl) we can write and define benchmark suites.
- Using [`PkgBenchmark.jl`](https://github.com/JuliaCI/PkgBenchmark.jl) or [`AirSpeedVelocity.jl`](https://github.com/MilesCranmer/AirspeedVelocity.jl) we can run those benchmarks.
- For CI [`AirSpeedVelocity.jl`](https://github.com/MilesCranmer/AirspeedVelocity.jl) or [`github-action-benchmark`](https://github.com/benchmark-action/github-action-benchmark) may be options. Send me feedback!
"""

# ╔═╡ b4b3fbc4-1a9e-4977-8b5b-f9c8f9b3c6b8
md"""
```
benchmark/
  Project.toml
  benchmarks.jl
  runbenchmarks.jl
```
"""

# ╔═╡ 763c41b5-c9f8-42e1-a3a1-992006dde0ee
md"""
##### Project.toml
```toml
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
MyPackage = "..."

[sources]
MyPackage = {path = ".."}
```
"""

# ╔═╡ 519e251d-27f3-440f-a69e-bbb5dff1c7f1
md"""
##### `benchmarks.jl`
```julia
using BenchmarkTools
using TowerOfEnzyme

const SUITE = BenchmarkGroup()

SUITE["basics"] = BenchmarkGroup()

SUITE["basics"]["overhead"] = @benchmarkable nth_derivative(sin, 1.0, Val(0))
```
"""

# ╔═╡ 73a38c14-8865-4be2-860c-46018e534289
md"""
##### `runbenchmarks.jl`
```julia
# For CI

using BenchmarkTools

include("benchmarks.jl")

tune!(SUITE)
results = run(SUITE, verbose = true)

BenchmarkTools.save("output.json", median(results))
```
"""

# ╔═╡ 86658337-5837-4a19-86b3-76459ed38785
md"""
### Continous integration

- Matrix
- Triggers
- Secrets
"""

# ╔═╡ 6824a0fc-77a6-4c9e-8244-c71682d103e2
md"""
#### Example `.github/workflows/CI.yml`

```yml
name: Run tests

on:
  push:
    branches:
      - main
  pull_request:

# needed to allow julia-actions/cache to delete old caches that it has created
permissions:
  actions: write
  contents: read

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        julia-version: ['lts', '1', 'pre']
        julia-arch: [x64]
        os: [ubuntu-latest, windows-latest, macOS-latest]

    steps:
      - uses: actions/checkout@v4
      - uses: julia-actions/setup-julia@v2
        with:
          version: ${{ matrix.julia-version }}
          arch: ${{ matrix.julia-arch }}
      - uses: julia-actions/cache@v2
        id: julia-cache
      - uses: julia-actions/julia-buildpkg@v1
      - uses: julia-actions/julia-runtest@v1
      - name: Save Julia depot cache on cancel or failure
        id: julia-cache-save
        if: cancelled() || failure()
        uses: actions/cache/save@v4
        with: 
          path: |
            ${{ steps.julia-cache.outputs.cache-paths }}
          key: ${{ steps.julia-cache.outputs.cache-key }}
```

"""

# ╔═╡ 1856800c-346b-42af-bb58-3947a01d9a85
md"""
#### Example: `.github/workflows/Documenter.yml`
"""

# ╔═╡ 574b9572-df2f-4c8f-ab14-80b4ecf5c70a
md"""
!!! note
    Read the manual on setting up Documenter with [`GitHub Actions`](https://documenter.juliadocs.org/stable/man/hosting/#GitHub-Actions) in particular you will need to setup a secret.
"""

# ╔═╡ 692700d1-e71d-4246-8c5b-0554408cae88
md"""
```yml
name: Documentation

on:
  push:
    branches:
      - main
    tags: '*'
  pull_request:

jobs:
  build:
    # These permissions are needed to:
    # - Deploy the documentation: https://documenter.juliadocs.org/stable/man/hosting/#Permissions
    # - Delete old caches: https://github.com/julia-actions/cache#usage
    permissions:
      actions: write
      contents: write
      pull-requests: read
      statuses: write
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: julia-actions/setup-julia@v2
        with:
          version: '1'
      - uses: julia-actions/cache@v2
      - name: Install dependencies
        shell: julia --color=yes --project=docs {0}
        run: |
          using Pkg
          Pkg.develop(PackageSpec(path=pwd()))
          Pkg.instantiate()
      - name: Build and deploy
        run: julia --color=yes --project=docs docs/make.jl
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} # If authenticating with GitHub Actions token
          DOCUMENTER_KEY: ${{ secrets.DOCUMENTER_KEY }} # If authenticating with SSH deploy key
```
"""

# ╔═╡ a4e3be29-8553-410e-9842-96aba6d9e127
md"""
#### Example: `.github/workflows/TagBot.yml`

https://github.com/JuliaRegistries/TagBot

```yml
name: TagBot
on:
  issue_comment:
    types:
      - created
  workflow_dispatch:
jobs:
  TagBot:
    if: github.event_name == 'workflow_dispatch' || github.actor == 'JuliaTagBot'
    runs-on: ubuntu-latest
    steps:
      - uses: JuliaRegistries/TagBot@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          ssh: ${{ secrets.DOCUMENTER_KEY }}
```
"""


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Kroki = "b3565e16-c1f2-4fe9-b4ab-221c88942068"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
Kroki = "~1.0.1"
PlutoTeachingTools = "~0.4.7"
PlutoUI = "~0.7.81"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.12.6"
manifest_format = "2.0"
project_hash = "f5c38e16ea3b587209ea8917f49a5d36a559d507"

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

[[deps.BitFlags]]
git-tree-sha1 = "0691e34b3bb8be9307330f88d1a3c3f25466c24d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.9"

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
weakdeps = ["StyledStrings"]

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.3.0+1"

[[deps.ConcurrentUtilities]]
deps = ["Serialization", "Sockets"]
git-tree-sha1 = "21d088c496ea22914fe80906eb5bce65755e5ec8"
uuid = "f0e56b4a-5159-44fe-b623-3e5288b988bb"
version = "2.5.1"

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
version = "1.7.0"

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

[[deps.Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Zlib_jll"]
git-tree-sha1 = "38044a04637976140074d0b0621c1edf0eb531fd"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.1+0"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "ConcurrentUtilities", "Dates", "ExceptionUnwrapping", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "PrecompileTools", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "51059d23c8bb67911a2e6fd5130229113735fc7e"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.11.0"

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
git-tree-sha1 = "7204148362dafe5fe6a273f855b8ccbe4df8173e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.8.0"

[[deps.JSON]]
deps = ["Dates", "Logging", "Parsers", "PrecompileTools", "StructUtils", "UUIDs", "Unicode"]
git-tree-sha1 = "f76f7560267b840e492180f9899b472f30b88450"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "1.6.0"

    [deps.JSON.extensions]
    JSONArrowExt = ["ArrowTypes"]

    [deps.JSON.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c0c9b76f3520863909825cbecdef58cd63de705a"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.1.5+0"

[[deps.JuliaSyntaxHighlighting]]
deps = ["StyledStrings"]
uuid = "ac6e5ff7-fb65-4e79-a425-ec3bc9c03011"
version = "1.12.0"

[[deps.Kroki]]
deps = ["Base64", "CodecZlib", "DocStringExtensions", "HTTP", "JSON", "Markdown", "Reexport"]
git-tree-sha1 = "c2eeb52dd957eb8b9c2c2c3a8ea2a1f084062548"
uuid = "b3565e16-c1f2-4fe9-b4ab-221c88942068"
version = "1.0.1"

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

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"
version = "1.11.0"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "f00544d95982ea270145636c181ceda21c4e2575"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.2.0"

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

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "8785729fa736197687541f7053f6d8ab7fc44f92"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.10"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "ff69a2b1330bcb730b9ac1ab7dd680176f5896b8"
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.1010+0"

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

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "NetworkOptions", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "1d1aaa7d449b58415f97d2839c318b70ffb525a0"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.6.1"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "3.5.4+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "05868e21324cede2207c6f0f466b4bfef6d5e7ee"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.8.1"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "5d5e0a78e971354b1c7bff0655d11fdc1b0e12c8"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.4"

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "Latexify", "Markdown", "PlutoUI"]
git-tree-sha1 = "90b41ced6bacd8c01bd05da8aed35c5458891749"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.4.7"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "79436d2d6f29a5d5b4e4749043a3f190d55631a3"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.81"

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

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
version = "1.11.0"

[[deps.TranscodingStreams]]
git-tree-sha1 = "0c45878dcfdcfa8480052b6ab162cdd138781742"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.3"

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
# ╠═0adedfb9-edfc-424d-8bcb-8bb9c6555d92
# ╟─03335a53-18de-47f8-87b0-d0c742e52f72
# ╠═41dcefbb-8b3d-41a0-ab14-ad6ec52294a1
# ╟─aabb0001-0001-4000-8000-000000000001
# ╟─b9ab169a-451f-4d45-8e98-2965e4284153
# ╟─4f012dd5-372c-4f16-9ca1-b15de79c446f
# ╟─87b6ebd8-2c07-4750-aeba-8ce237403689
# ╠═d2bf5326-3c40-4cb4-9f4d-fde6136b85a0
# ╠═4087f982-1854-4d30-8ae0-50bbfd1fbf29
# ╠═7431db21-4a9b-47f3-9ff6-26eeb544b975
# ╟─1a331491-56b9-4906-acce-07c95f150809
# ╟─e70cbf6f-488f-4d5c-a097-7e36bd445f67
# ╠═41ee91a9-fc53-4658-a1c8-8501b05abf33
# ╟─515ced98-05a3-4a3f-99a6-988f38a10ebb
# ╟─59560685-e835-4bb7-aece-e85432aaac5f
# ╟─8b2a9fd1-b832-4bae-a53d-745edc238fd1
# ╟─fec70833-4bd5-4663-a17f-3f568cb0a414
# ╟─73ae8c08-dbbf-4b0a-9795-4a3eb9bba11b
# ╟─4c2d481d-61f9-4506-9789-3c4633f81253
# ╟─2af11cad-cc8b-4409-a1fd-7bcc2c729c17
# ╟─e2663784-2c02-419c-9965-2989631fd307
# ╟─0be73b29-7780-4be0-bf07-9b62c99fc4b4
# ╠═d4b60dfe-0067-47ec-8608-9a34e088aeae
# ╟─ecaaf7eb-f748-4ab8-99e8-63c436f2045b
# ╟─c6a2d68f-b8c0-4d77-82a8-265a287336f2
# ╟─1c908c9e-f287-4f35-85a8-0089b1104838
# ╟─d5a72daf-b1dc-4e42-8d01-73a358b48a36
# ╟─4d9710dd-ebd8-4a60-a2d6-b43ce9b6a990
# ╟─a375415a-b89c-4155-bf34-cd66c37407af
# ╟─d87edbd4-e75c-4a97-9a10-c581a698e923
# ╟─a0626ce0-5969-475c-ab18-5dcf6bb36732
# ╟─2c682f34-0164-4840-a52f-fe06f17a2456
# ╟─15e93a07-c0a9-4fd6-b84c-4055ec79e78a
# ╟─53366fdd-1558-4b07-98f4-6a898004b923
# ╟─278d924c-b4f6-4802-98da-a67797b3d426
# ╟─31cae475-1cba-466a-a87c-cc4dfd03d552
# ╟─177d84b7-8d25-4978-822e-cf07091b1f63
# ╟─e112373c-24fd-4e0d-8766-a5cfb1747f78
# ╟─6756ace4-eab3-47e7-9fdf-abcfb37029e5
# ╟─c4053d4f-fadf-4b87-8f2d-ca4c2166c46d
# ╟─9f48c2dd-f445-4efd-91f2-35d0bbcae765
# ╟─f5973d0a-043d-4cdc-ba79-15e9a3eb3046
# ╟─363ebe92-ea01-43f9-9150-a01609a6cfca
# ╟─8e402dae-e10a-4736-bdd8-e2844f79d859
# ╟─f6e64181-479b-47b3-99d2-405ed2b9be15
# ╟─1e1a58b4-98a9-4b27-be11-b67fc329a6a6
# ╟─05ad0829-84ed-494f-80bb-c1da1991a238
# ╟─54fac0b7-e3d0-4bb2-a9cb-34a4ec629422
# ╟─7515ed27-d5c6-45c1-8793-12e5db294983
# ╟─1bae1dbb-c428-406e-ad22-be4255c47fdc
# ╟─80e832d7-ede2-4e13-86fd-f92429a53011
# ╟─3cd28b53-281c-4934-a399-eb75f64cf5a6
# ╟─6f021238-0d2f-4821-b407-a230dc7814bc
# ╟─7efce24a-c294-4c26-8297-76cd0fb12081
# ╟─02c596c5-080f-4c5a-98c9-cd13b32df5c3
# ╟─70fd6057-1f46-414f-b0b8-0928fde77341
# ╟─ecc31d48-35ca-4e89-986f-cc2f191b26b9
# ╟─3d6871e7-bb7a-4276-8180-b5f388a73cc9
# ╟─168d9204-4aa3-4c3a-8c62-7dd4af5dba15
# ╟─8fcfbb4a-940c-44bd-9528-d7d18ff27cbb
# ╟─e907d4a0-e904-41eb-be39-b6ef8a1679d4
# ╟─25de521d-2f56-4e5b-ae87-b8f7312796d3
# ╟─cea48abe-5d02-4e3b-8781-3eae51545481
# ╟─b970dc0b-9991-4849-a6d9-099e19471946
# ╟─ffdc7bb5-9cec-42b5-9819-78ca7beabf6c
# ╟─14e24118-fa8b-4d50-9e23-0f3901a7a1be
# ╟─29ccbb9d-edef-4101-99c6-15c417a41d1f
# ╟─8cb9853d-3bc1-4e78-bc2b-3a2aa4f328cb
# ╟─3955fc29-e3c3-49a1-b4dd-1864111eabe4
# ╟─30f74532-20f9-4f80-bdfd-01cbcd3e68ff
# ╟─627af63b-d863-495c-b2ee-e101746c49e5
# ╟─c86e608a-1a6e-4fbd-9584-e1d3de905f1c
# ╟─82cbab70-a328-4bd2-b084-b292ed3a85aa
# ╟─b0b37d43-8001-405a-8f67-73e94c8d41b5
# ╟─88b670c9-6ba2-4c92-8abb-dc33bc3d4191
# ╟─d93f3b6f-a727-4c5c-9069-c9f171ae94fe
# ╟─b3b3d443-ea18-456a-aabf-23c2b2f854db
# ╟─f25b352a-52b1-424d-8d4a-da210cbd442f
# ╟─a88718a1-ba41-40ef-b09f-fc53ed70893d
# ╟─14ee3dcc-9070-49f4-a562-0f8ba918d87f
# ╟─c14d85f3-9d4d-4ec6-a15b-4918a5761312
# ╟─24203379-cc7b-451a-b52b-02f0075563f5
# ╟─b115a56b-600a-4032-a42b-6ff5172b7417
# ╟─10b96a54-9d02-4fbf-ba69-d8c27304c48a
# ╟─3712e9a2-eeea-444f-9741-4576f3b7d49a
# ╠═3a2b059a-15c0-40e3-8f62-b1b2acc6d676
# ╟─1944a721-3b5d-402c-b78f-0449af1c787f
# ╟─0dbbf025-b5db-4be7-a720-162beadc5d20
# ╟─b4b3fbc4-1a9e-4977-8b5b-f9c8f9b3c6b8
# ╟─763c41b5-c9f8-42e1-a3a1-992006dde0ee
# ╟─519e251d-27f3-440f-a69e-bbb5dff1c7f1
# ╟─73a38c14-8865-4be2-860c-46018e534289
# ╟─86658337-5837-4a19-86b3-76459ed38785
# ╟─6824a0fc-77a6-4c9e-8244-c71682d103e2
# ╟─1856800c-346b-42af-bb58-3947a01d9a85
# ╟─574b9572-df2f-4c8f-ab14-80b4ecf5c70a
# ╟─692700d1-e71d-4246-8c5b-0554408cae88
# ╟─a4e3be29-8553-410e-9842-96aba6d9e127
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
