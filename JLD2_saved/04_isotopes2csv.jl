using DataFrames, Unitful, JLD2, CSV, Tables

d = @__DIR__
# jld2_isots = raw"src\that-and-this\isotopes_data\isotopes_data.jld2"
jld2_isots_sym = joinpath(d, "isotopes_data_sym.jld2")
CSV_isots = joinpath(d, "isotopes_data.csv")

@load jld2_isots_sym isotopes

"Strip units from unitful columns"
function df_ustrip(df)
    coltypes = describe(df, :eltype) |> Tables.rowtable
    for c in coltypes
        if nonmissingtype(c.eltype) <: Quantity
            transform!(df, c.variable => ByRow(ustrip); renamecols=false)
        end
    end
end

df_ustrip(isotopes)

CSV.write(CSV_isots, isotopes; delim='\t', missingstring="--")
