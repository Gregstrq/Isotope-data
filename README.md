# Isotope-data
The repo stores the scripts and raw data used to generate the table of isotopes for [PeriodicTable.jl](https://github.com/JuliaPhysics/PeriodicTable.jl)
- The script "parse_isotopes.jl" parses the raw data into a dataframe and serializes this dataframe to "isotopes_data.jls".
- The script "generate_isotope_file.jl" loads "isotopes_data.jls" and generates the file "isotopes_data.jl" which defines the vector of Isotope-structs for [PeriodicTable.jl](https://github.com/JuliaPhysics/PeriodicTable.jl).

## Sources
- The data on spins, abundances, gyromagnetic ratios and quadrupole moments is from [easyspin database](https://easyspin.org/documentation/isotopetable.html).
- The data on masses is from [IUPAC-CIAAW. Atomic masses.](https://ciaaw.org/atomic-masses.htm)
- The data on half-lives is from the NUBASE2020 evaulation published in F.G. Kondev, M. Wang, W.J. Huang, S. Naimi, and G. Audi, Chin. Phys. C45, 030001 (2021). The electronic version of the table is [here](https://www-nds.iaea.org/amdc/ame2020/nubase_3.mas20.txt).

## Disclaimer
In the end, the resulting list of the isotopes covered is very small. The problem here is easyspin database.
They reference [this](https://www-nds.iaea.org/publications/indc/indc-nds-0658.pdf) and [this](https://www-nds.iaea.org/publications/indc/indc-nds-0650.pdf) tables, which contain many more isotopes.
However, thes tables are in pdf, and I don't know how to parse them.