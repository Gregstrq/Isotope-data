# Isotope-data
The repo stores the scripts and raw data used to generate the table of isotopes for [PeriodicTable.jl](https://github.com/JuliaPhysics/PeriodicTable.jl)
- The script "parse_isotopes.jl" parses the raw data into a dataframe and saves two versions of the dataframe to the files "isotopes_data.csv" and "isotopes_data.jld2".
- The script "generate_isotope_file.jl" loads "isotopes_data.jld2" and generates the file "isotopes_data.jl" which defines the vector of Isotope-structs.
- There is a difference between ".csv" and ".jld2" versions. The ".csv" version stores quantities and uncertainties separately, and is also stripped of units. The ".jld2" version fully utilizes Julia libs and stores quantities with uncertainty as unitful measurements.

## Sources
- The data on masses is from [IUPAC-CIAAW. Atomic masses.](https://ciaaw.org/atomic-masses.htm)
- The data on half-lives and abundances is from the NUBASE2020 evaulation published in F.G. Kondev, M. Wang, W.J. Huang, S. Naimi, and G. Audi, Chin. Phys. C45, 030001 (2021). The electronic version of the table is [here](https://www-nds.iaea.org/amdc/ame2020/nubase_3.mas20.txt).
- The data on gyromagnetic ratios is from [this](https://www-nds.iaea.org/publications/indc/indc-nds-0658.pdf) report of N.J. Stone and International Nuclear Data Commitee, while the data on quadrupole moments is from [this](https://www-nds.iaea.org/publication    s/indc/indc-nds-0650.pdf) report of the same author. The electronic versions of the tables of recommended values of gyromagnetic ratios and quadrupole moments can be found [here](https://www-nds.iaea.org/nuclearmoments/).
- The data on spins and parity is pulled both from NUBASE2020 evaluation and INDC data.
- Nonmagentic isotopes have no gyromagnetic ratio and quadrupole moment. Hence, they are not present in INDC data. Isotopes with spin-1/2 have no quadrupole moment, therefore, they do not appear in the INDC data for electric quadrupole moments.
