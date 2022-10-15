using Serialization, FileIO, DataFrames, Unitful, JLD2

d = @__DIR__

ser_isots = joinpath(d, "../", "isotopes_data.jls")
jld2_isots = joinpath(d, "isotopes_data.jld2")

isotopes = deserialize(ser_isots)

@save jld2_isots isotopes
