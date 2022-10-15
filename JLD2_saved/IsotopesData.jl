module IsotopesData
using DataFrames, Unitful, JLD2, Measurements

d = @__DIR__
jld2_isot_meas = joinpath(d, "isotopes_data_measvals.jld2")

@load jld2_isot_meas isotopes

export isotopes

end
