using DataFrames, Unitful, JLD2, Measurements

function subsuperchar(c, sub)
    subscripts = Dict(
        '0' => '₀',
        '1' => '₁',
        '2' => '₂',
        '3' => '₃',
        '4' => '₄',
        '5' => '₅',
        '6' => '₆',
        '7' => '₇',
        '8' => '₈',
        '9' => '₉',
    )

    superscripts = Dict(
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
    if sub
        return subscripts[c]
    else
        return superscripts[c]
    end
end

function subsuperstring(x, sub=false)
    s = string(x)
    carr = [subsuperchar(c, sub) for c in s]
    return join(carr, "")
end

isot_symb(atnom, elsym) = "$(subsuperstring(atnom))$(string(elsym))"

d = @__DIR__
jld2_isots = joinpath(d, "isotopes_data.jld2")
jld2_isots_sym = joinpath(d, "isotopes_data_sym.jld2")

@load jld2_isots isotopes

function add_isot_symb!(df)
    transform!(df, AsTable([:mass_number, :symbol]) =>  ByRow(x -> isot_symb(x[:mass_number], x[:symbol])) => :isotopic_symbol)
    l = length(names(df))
    nos = [1;2; l; collect(3:l-1)]
    select!(df, nos)
end

add_isot_symb!(isotopes)

@save jld2_isots_sym isotopes
