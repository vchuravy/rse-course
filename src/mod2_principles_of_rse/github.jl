### A Pluto.jl notebook ###
# v0.20.6

#> [frontmatter]
#> chapter = "2"
#> section = "1"
#> order = "5"
#> title = "Software development with Github"
#> date = "2025-05-14"
#> tags = ["module2", "track_principles"]
#> layout = "layout.jlhtml"
#> 
#>     [[frontmatter.author]]
#>     name = "Valentin Churavy"
#>     url = "https://vchuravy.dev"

using Markdown
using InteractiveUtils

# ╔═╡ 5c4c21e4-1a90-11f0-2f05-47d877772576
using PlutoUI

# ╔═╡ 5f6deede-7e22-4ebf-ae1a-14d584595f17
html"<button onclick='present()'>Toggle presentation mode</button>"

# ╔═╡ aa46fef4-0c92-4947-ac64-f06ee31cb43f
PlutoUI.TableOfContents(; depth=4)

# ╔═╡ 0be73b29-7780-4be0-bf07-9b62c99fc4b4
md"""
# Github
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
    The [GitBook](https://git-scm.com/book/en/v2) is a usefull resource.
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
#### Working with branches `git checkout`
"""

# ╔═╡ 3271fcee-884b-4610-a93f-94954e6a4022
md"""
- `git add -p`
- `git rebase`
- `git checkout`
"""

# ╔═╡ 134822f5-8d9f-4a39-ad7b-1350d57d12dd


# ╔═╡ f25b352a-52b1-424d-8d4a-da210cbd442f
md"""
## Julia & Github
"""

# ╔═╡ a88718a1-ba41-40ef-b09f-fc53ed70893d
md"""
- https://github.com/JuliaCI/PkgTemplates.jl
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

- MIT vs GPL

"""

# ╔═╡ 24203379-cc7b-451a-b52b-02f0075563f5
md"""
### `Project.toml`
```toml
name = "MyPackage"
uuid = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
authors = ["Author <autor@somehost.de>"]
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

- Test.jl
- Purpose of testing
- Challenges:
	- randomness

Other helpful package:
- [TestItems.jl](https://www.julia-vscode.org/docs/stable/userguide/testitems/)

#### `runtests.jl`
```
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
"""

# ╔═╡ 0dbbf025-b5db-4be7-a720-162beadc5d20
md"""
### Benchmarking
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
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PlutoUI = "~0.7.62"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.11.4"
manifest_format = "2.0"
project_hash = "8ee5d63d41e3e4bb137628ac5343048da171f71e"

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
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"
version = "1.11.0"

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

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

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

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"
version = "1.11.0"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.6+0"

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

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "44f6c1f38f77cafef9450ff93946c53bd9ca16ff"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "Random", "SHA", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.11.0"

    [deps.Pkg.extensions]
    REPLExt = "REPL"

    [deps.Pkg.weakdeps]
    REPL = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "d3de2694b52a01ce61a036f18ea9c0f61c4a9230"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.62"

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

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"
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
# ╟─5f6deede-7e22-4ebf-ae1a-14d584595f17
# ╟─5c4c21e4-1a90-11f0-2f05-47d877772576
# ╟─aa46fef4-0c92-4947-ac64-f06ee31cb43f
# ╟─0be73b29-7780-4be0-bf07-9b62c99fc4b4
# ╟─ecaaf7eb-f748-4ab8-99e8-63c436f2045b
# ╟─c6a2d68f-b8c0-4d77-82a8-265a287336f2
# ╟─1c908c9e-f287-4f35-85a8-0089b1104838
# ╟─d5a72daf-b1dc-4e42-8d01-73a358b48a36
# ╟─4d9710dd-ebd8-4a60-a2d6-b43ce9b6a990
# ╟─d87edbd4-e75c-4a97-9a10-c581a698e923
# ╟─a0626ce0-5969-475c-ab18-5dcf6bb36732
# ╟─2c682f34-0164-4840-a52f-fe06f17a2456
# ╟─15e93a07-c0a9-4fd6-b84c-4055ec79e78a
# ╟─53366fdd-1558-4b07-98f4-6a898004b923
# ╟─31cae475-1cba-466a-a87c-cc4dfd03d552
# ╟─e112373c-24fd-4e0d-8766-a5cfb1747f78
# ╟─6756ace4-eab3-47e7-9fdf-abcfb37029e5
# ╠═c4053d4f-fadf-4b87-8f2d-ca4c2166c46d
# ╠═3271fcee-884b-4610-a93f-94954e6a4022
# ╠═134822f5-8d9f-4a39-ad7b-1350d57d12dd
# ╟─f25b352a-52b1-424d-8d4a-da210cbd442f
# ╟─a88718a1-ba41-40ef-b09f-fc53ed70893d
# ╟─14ee3dcc-9070-49f4-a562-0f8ba918d87f
# ╟─c14d85f3-9d4d-4ec6-a15b-4918a5761312
# ╟─24203379-cc7b-451a-b52b-02f0075563f5
# ╟─b115a56b-600a-4032-a42b-6ff5172b7417
# ╟─10b96a54-9d02-4fbf-ba69-d8c27304c48a
# ╟─3712e9a2-eeea-444f-9741-4576f3b7d49a
# ╟─0dbbf025-b5db-4be7-a720-162beadc5d20
# ╟─86658337-5837-4a19-86b3-76459ed38785
# ╟─6824a0fc-77a6-4c9e-8244-c71682d103e2
# ╟─1856800c-346b-42af-bb58-3947a01d9a85
# ╟─a4e3be29-8553-410e-9842-96aba6d9e127
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
