using FileIO, JLD2, DataFrames, CSV, Unitful, PeriodicTable, Measurements

Unitful.register(@__MODULE__)

################
#
# Utility functions to parse INDC tables
#
################

function parse_spin(str::AbstractString)
    rm = match(r"\(?(\d+)\/?(\d*)\)?([+-])", str)
    if rm==nothing
        return missing, missing
    end
    nom = parse(Int, rm.captures[1])
    denom = rm.captures[2]=="" ? 1 : parse(Int, rm.captures[2])
    parity = parse(Int, rm.captures[3]*"1")
    return nom//denom, parity
end

function parse_value_with_error(str::AbstractString)
    rm = match(r"\(?([+-]?)\)?(\d+)\.(\d+)\((\d+)", str)
    if rm==nothing
        return missing, missing
    end
    val = parse(Float64, rm.captures[1]*rm.captures[2]*"."*rm.captures[3])
    dval = parse(Int, rm.captures[4])/10^(length(rm.captures[3]))
    return val, dval
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
			hl = missing
		elseif hl_raw==""
			hl = missing
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
		hl = missing
		hlu = missing
	end
	if length(str)>=88
		hlu_raw = str[82:88] |> strip
		if hlu_raw==""
			hlu = missing
		elseif hlu_raw[1]=='T'
			hlu = missing
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
		hlu = missing
	end
    #### parsing abundance
    if length(str)>122
        abundance_raw = split(str[120:end])|>first|>x->split(x,";")|>first
        if length(abundance_raw)>3 && abundance_raw[1:3]=="IS="
            abundance = parse(Float64, abundance_raw[4:end])
        else
            abundance = 0.0
        end
    else
        abundance = 0.0
    end
    #### parsing radioactivity
    if !ismissing(hl) && hl==Inf*u"s"
        is_radioactive=false
    else
        is_radioactive=true
    end
    #### parsing mass and atomic numbers
    mass_number = parse(Int, str[1:3])
    atomic_number = parse(Int, str[5:7])
    #### parsing spin
    if length(str)>94
        spin, parity = parse_spin(str[89:94])
    else
        spin,parity=missing,missing
    end
    return (nuclide=nuclide, atomic_number=atomic_number, mass_number=mass_number, is_radioactive=is_radioactive, half_life=hl, half_life_uncertainty=hlu, abundance=abundance, spin=spin, parity=parity)
end

function parse_nubase(filename::AbstractString)
	io = open(filename, "r")
	rows = [parse_line_nubase(line) for line in readlines(io) if (line[1]!='#')&&(line[1]!='-')]
	close(io)
	return DataFrame(rows)
end


################
#
# Utilities to combine the value and error into a single measurement.
# Utilities to add fancy superscripts.
# Utility to strip units for saving to CSV.
#
################

measmiss(v, err) = (v ± err)
measmiss(v::Missing, err) = missing
measmiss(v::Missing, err::Missing) = missing
measmiss(v, err::Missing) = isinf(v) ? (v ± zero(v)) : (v ± unit(v)*NaN)

const superscripts = Dict(
    '0' => '⁰',
    '1' => '¹',
    '2' => '²',
    '3' => '³',
    '4' => '⁴',
    '5' => '⁵',
    '6' => '⁶',
    '7' => '⁷',
    '8' => '⁸',
    '9' => '⁹',
)

function superstring(x)
    s = string(x)
    carr = [superscripts[c] for c in s]
    return join(carr, "")
end
isot_symbol(symbol, mass_number) = string(superstring(mass_number), symbol)

strip_data(x) = x
strip_data(x::Number) = ustrip(x)

# function to get the header of the dataframe with units
get_header(df) = .*(names(df), get_df_unit_strs(df))
get_df_unit_strs(df) = eltype.(eachcol(df)) .|> get_unit_str
get_unit_str(x) = ""
get_unit_str(x::Type{<:Quantity}) = " ["*string(unit(x))*"]"
get_unit_str(x::Type{Union{Missing,T}}) where {T} = get_unit_str(T)

################
#
# Parsing and loading the files
#
################

# radioactivity, half-life and abundance data
rad_data = parse_nubase("nubase_3.mas20.txt")

# spin and gyromagnetic ratio
spings = load("magn_mom_recomm.csv") |> DataFrame |>
            df -> transform!(df, [Symbol("n.n+n.z"), :symbol]=>ByRow((x,y)->string(x,y))=>:nuclide,
                            :spin=>ByRow(x->parse_spin(x))=>[:spin, :parity],
                            Symbol("magnetic dipole [nm]")=>ByRow(x->parse_value_with_error(x))=>[:dm, :dmerror]
                           ) |>
            df -> filter!(Symbol("energy [keV]")=>x->(x=="0"), df) |> # we are interested in ground states of nuclei
            df -> select!(df, :nuclide=>ByRow(x->(x=="1NN" ? "1n" : x))=>:nuclide,
                            :z=>:atomic_number,
                            Symbol("n.n+n.z")=>:mass_number,
                            :spin, :parity,
                            [:spin, :dm]=>ByRow((spin,val)->val/(ismissing(spin) ? 1//1 : spin))=>:gfactor,
                            [:spin, :dmerror]=>ByRow((spin,val)->val/(ismissing(spin) ? 1//1 : spin))=>:gfactor_uncertainty)

# electric quadrupole moment
elqms = load("elec_mom_recomm.csv") |> DataFrame |>
            df -> transform!(df, [Symbol("n.n+n.z"), :symbol]=>ByRow((x,y)->string(x,y))=>:nuclide,
                             Symbol("electric quadrupole [b]")=>ByRow(x->parse_value_with_error(x).*1u"b")=>[:quadrupole_moment, :quadrupole_moment_uncertainty]) |>
            df -> filter!(Symbol("energy [keV]")=>x->(x=="0"), df) |>
            df -> select!(df, :nuclide=>ByRow(x->(x=="1NN" ? "1n" : x))=>:nuclide, :quadrupole_moment, :quadrupole_moment_uncertainty)

# masses
masses0 = DataFrame(nuclide="1n", mass=1.00866491588u"u", mass_uncertainty=49e-11u"u")
masses = vcat(masses0, load("IUPAC-atomic-masses.csv") |> DataFrame |> df -> filter!("Year/link" => str->occursin("2020", str), df) |>
      df -> select!(df, :nuclide, :mass=>ByRow(x->x*1u"u")=>:mass, :uncertainty=>ByRow(x->parse(Float64, x)*1u"u")=>:mass_uncertainty)
     )

# Merging the DataFrames together is the tricky part.
# Isotopes with spin 0 have neither magnetic dipolar nor electric quadrupolar moment, so they don't appear in INDC tables.
# Isotopes with spin 1/2 have a magnetic dipolar moment but no electric quadrupolar moment.
# As a result, this isotopes do not appear in the table of recommended electric quadrupolar moments (elqms).
magnetic_data = leftjoin(spings, elqms; on = :nuclide, validate = (true, true))
nonmagnetic_data = innerjoin(masses, rad_data; on = :nuclide, validate = (true, true))
isotopes=leftjoin(nonmagnetic_data, magnetic_data; on=[:nuclide,:atomic_number,:mass_number,:spin,:parity], validate=(true,true), matchmissing=:equal)
filter!(:spin=>x->!ismissing(x), isotopes)
filter(:spin=>x->x==0, isotopes; view=true)[:, [:gfactor,:gfactor_uncertainty,:quadrupole_moment,:quadrupole_moment_uncertainty]] .= [0.0 0.0 0.0u"b" 0.0u"b"]
filter(:spin=>x->x==1//2, isotopes; view=true)[:, [:quadrupole_moment,:quadrupole_moment_uncertainty]] .= [0.0u"b" 0.0u"b"]

function get_name_symbol(nuclide::AbstractString, mass_number::Int)
    rm = match(r"\d+(\w+)", nuclide)
    symbol = Symbol(rm.captures[1])
    name = symbol==:n ? "neutron" : elements[symbol].name
    isymbol = isot_symbol(symbol, mass_number)
    return name,symbol,isymbol
end
select!(isotopes,
        [:nuclide, :mass_number]=>ByRow((x,y)->get_name_symbol(x,y))=>[:name, :symbol, :isot_symbol],
        :atomic_number,
        :mass_number,
        :abundance,
        :mass,
        :mass_uncertainty,
        :spin,
        :parity,
        :is_radioactive,
        :half_life,
        :half_life_uncertainty,
        :gfactor,
        :gfactor_uncertainty,
        :quadrupole_moment,
        :quadrupole_moment_uncertainty
       )

sort!(isotopes, [:atomic_number, :mass_number])

# saving to csv
isotopes_csv = isotopes .|> strip_data
transform!(isotopes_csv, :spin=>ByRow(x->float(x))=>:spin)
CSV.write("isotopes_data.csv", isotopes_csv; header = get_header(isotopes))


select!(isotopes,
        :name, :symbol, :isot_symbol, :atomic_number, :mass_number, :abundance,
        [:mass, :mass_uncertainty]=>ByRow((x,y)->measmiss(x,y))=>:mass,
        :spin, :parity, :is_radioactive,
        [:half_life, :half_life_uncertainty]=>ByRow((x,y)->measmiss(x,y))=>:half_life,
        [:gfactor, :gfactor_uncertainty]=>ByRow((x,y)->measmiss(x,y))=>:gfactor,
        [:quadrupole_moment, :quadrupole_moment_uncertainty]=>ByRow((x,y)->measmiss(x,y))=>:quadrupole_moment
       )
jldsave("isotopes_data.jld2"; isotopes)
