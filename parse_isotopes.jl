using FileIO, JLD2, DataFrames, CSV, Unitful, Serialization

Unitful.register(@__MODULE__)

################
#
# Utility functions to parse the easyspin isotope file
#
################

function parse_isotopes(filename::AbstractString)
	io = open(filename, "r")
	rows = [parse_line(line) for line in readlines(io) if line[1]!='%']
	close(io)
	return DataFrame(rows)
end

function parse_line(str::AbstractString)
	data = split(str, " "; keepempty=false)
	(atomic_number = parse(Int, data[1]),
	 mass_number = parse(Int, data[2]),
	 is_radioactive = data[3]=="*" ? true : false,
	 symbol = string(data[4]),
	 name = data[5]|>string,
	 spin = parse(Float64, data[6]),
	 gfactor = parse(Float64, data[7]),
	 abundance = parse(Float64, data[8]),
	 quadrupole_moment = parse(Float64, data[9])
	 )
end

################
#
# Utility functions to parse the Nubase2020 data for half-lives
#
################

# Nubase uses a different definition of year in comparison with Unitful.jl
@unit yra "yra" AdjustedYear 31556926Unitful.s true

# Dictionary to map names of half-lives units to Unitful units
str_to_unit = Dict("s"=>Unitful.s,
				   "m"=>Unitful.minute,
				   "h"=>Unitful.hr,
				   "d"=>Unitful.d,
				   "y"=>yra,
				   "ms"=>Unitful.ms,
				   "μs"=>Unitful.μs,
				   "us"=>Unitful.μs,
				   "ns"=>Unitful.ns,
				   "ps"=>Unitful.ps,
				   "fs"=>Unitful.fs,
				   "as"=>Unitful.as,
				   "zs"=>Unitful.zs,
				   "ys"=>Unitful.ys,
				   "ky"=>kyra,
				   "My"=>Myra,
				   "Gy"=>Gyra,
				   "Ty"=>Tyra,
				   "Py"=>Pyra,
				   "Ey"=>Eyra,
				   "Zy"=>Zyra,
				   "Yy"=>Yyra
				   )

function parse_line_nubase(str::AbstractString)
	nuclide_raw = str[12:16] |> rstrip |> string
	nuclide_postfix = str[17]
	nuclide = nuclide_postfix==' ' ? nuclide_raw : nuclide_raw*"_"*nuclide_postfix
	######
	if length(str)>=78
		hl_raw = str[70:78] |> strip
		if hl_raw=="stbl"
			hl = Inf*u"s"
		elseif hl_raw=="p-unst"
			hl = NaN*u"s"
		elseif hl_raw==""
			hl = NaN*u"s"
		else
			if (hl_raw[1]=='>')||(hl_raw[1]=='<')||(hl_raw[1]=='~')
				hl_raw = hl_raw[2:end]
			end
			if (hl_raw[end]=='#')
				hl_raw = hl_raw[1:end-1]
			end
			hl = parse(Float64, hl_raw)*str_to_unit[str[79:80]|>strip] |> q -> uconvert(Unitful.s, q)
		end
	else
		hl = NaN*u"s"
		hlu = NaN*u"s"
	end
	if length(str)>=88
		hlu_raw = str[82:88] |> strip
		if hlu_raw==""
			hlu = NaN*u"s"
		elseif hlu_raw[1]=='T'
			hlu = NaN*u"s"
		elseif (hlu_raw[1]=='>' || hlu_raw[1]=='<' || hlu_raw[1]=='~')
			hlu_n = match(r"\d+\.?\d*", hlu_raw) |> rm -> rm.match |> n -> parse(Float64, n)
			hlu_u = str_to_unit[match(r"[A-Za-z]+", hlu_raw) |> rm-> rm.match]
			hlu = hlu_n*hlu_u |> q -> uconvert(u"s", q)
		else
			if hlu_raw[end]=='#'
				hlu_raw = hlu_raw[1:end-1]
			end
			hlu = parse(Float64, hlu_raw)*str_to_unit[str[79:80]|>strip] |> q -> uconvert(Unitful.s, q)
		end
	else
		hlu = NaN*u"s"
	end
	return (nuclide=nuclide, half_life=hl, half_life_uncertainty=hlu)
end

function parse_nubase(filename::AbstractString)
	io = open(filename, "r")
	rows = [parse_line_nubase(line) for line in readlines(io) if (line[1]!='#')&&(line[1]!='-')]
	close(io)
	return DataFrame(rows)
end

################
#
# Parsing and loading the files
#
################

# half-life data
isotopes_n = parse_nubase("nubase_3.mas20.txt")

# radioactivity, abundance, spin, gyromagnetic ratio and quadrupole moment
# some of the isotopes in easyspin file have zero mass-number; I have decided to remove them
isotopes1 = parse_isotopes("isotopedata.txt") |> df -> filter(:mass_number => m->(m!=0), df) |> df -> transform(df, :, [:mass_number, :symbol] => ByRow((x,y)->string(x,y)) => :nuclide)

# masses
isotopes2 = load("IUPAC-atomic-masses.csv") |> DataFrame |> df -> filter("Year/link" => str->occursin("2020", str), df) |> df -> select!(df, Not("Year/link"))

# merging the DataFrames together
isotopes = leftjoin(leftjoin(isotopes1, isotopes2, on = :nuclide), isotopes_n, on = :nuclide, validate = (true,true))

# some of the isotopes in easyspin db are flagged as stable while the Nubase db indicates finite half-life for them
isotopes[isless.(isotopes.half_life, Inf*u"s"), :is_radioactive] .= true

select!(isotopes, :name,
		          :symbol,
				  :atomic_number,
				  :mass_number,
				  :abundance,
				  :mass=>ByRow(m->m*u"u")=>:mass,
				  :uncertainty=>ByRow(dm->parse(Float64,dm)*u"u")=>:mass_uncertainty,
				  :spin=>ByRow(s->Rational(s))=>:spin,
				  :gfactor,
				  :quadrupole_moment=>ByRow(qm->qm*u"b")=>:quadrupole_moment,
				  :is_radioactive,
				  :half_life,
				  :half_life_uncertainty)
serialize("isotopes_data.jls", isotopes)
