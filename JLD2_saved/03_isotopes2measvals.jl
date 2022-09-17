using DataFrames, Unitful, JLD2, Measurements

d = @__DIR__
jld2_isots_sym = joinpath(d, "isotopes_data_sym.jld2")
jld2_isot_meas = joinpath(d, "isotopes_data_measvals.jld2")

name_uncert(nm) = "$(nm)_uncertainty"

function getmeasnames(df)
    ns = names(df)
    return mns = [n for n in ns if (name_uncert(n) in ns)]
end

measmiss(v, err) = measurement(v, err)
measmiss(v::Missing, err) = missing
measmiss(v::Missing, err::Missing) = missing
# as some half-life data miss an estimation of uncertainty, and measurement(::Float64, Missing) is not defined
measmiss(v, err::Missing) = v

"combine value and it's uncertainty into a measurement value"
function combine2meas!(df, nm)
    sym = Symbol(nm)
    sym_unc = Symbol(name_uncert(nm))
    transform!(df, AsTable([sym, sym_unc]) =>  ByRow(x -> measmiss(x[sym], x[sym_unc])) => sym)
    select!(df, Not(sym_unc))
end

function combine2measall!(df)
    mns = getmeasnames(df)
    for n in mns
        combine2meas!(df, n)
    end
    return df
end

@load jld2_isots_sym isotopes
combine2measall!(isotopes)
@save jld2_isot_meas isotopes
