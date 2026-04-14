import Pkg
Pkg.activate("./pluto-deployment-environment")
Pkg.instantiate()

import PlutoPages

PlutoPages.generate("."; html_report_path="generation_report.html")
