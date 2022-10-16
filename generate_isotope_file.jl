using DataFrames, Measurements, Unitful, FileIO, JLD2

isotopes = load("isotopes_data.jld2", "isotopes")
colnames = names(isotopes)

quantity_repr(x) = repr(x)
function quantity_repr(x::Quantity)
	n,u = repr(x)|>split
	return n*"*"*u
end
function quantity_repr(x::Quantity{<:Measurement})
    x_split = repr(x)|>split
    return "("*join(x_split[1:end-1], " ")*") * "*x_split[end]
end

open("isotopes_data.jl", "w") do io

	println(io, "_isotopes_data = [")
	for istp in eachrow(isotopes)
		println(io, "    Isotope(;")
        for (i,field) in enumerate(istp[1:end-1])
            println(io, "        ", colnames[i], " = ", quantity_repr(field),',')
		end
        println(io, "        ", colnames[end], " = ", quantity_repr(istp[end]))
		println(io, "    ),")
	end
	println(io, "]")
end


