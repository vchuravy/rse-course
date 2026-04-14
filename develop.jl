import Pkg
Pkg.activate("./pluto-deployment-environment")
Pkg.instantiate()

import PlutoPages

PlutoPages.develop(".")
