using Serialization, DataFrames, Unitful, FileIO

isotopes = deserialize("isotopes_data.jls")

quantity_repr(x) = repr(x)
function quantity_repr(x::Quantity)
	n,u = repr(x)|>split
	return n*"*"*u
end

open("isotopes_data.jl", "w") do io
	println(io, "_isotopes_data = [")
	for istp in eachrow(isotopes)
		println(io, "    Isotope(")
		for field in istp[1:end-1]
			println(io, "        ",quantity_repr(field),',')
		end
		println(io, "        ",quantity_repr(istp[end]))
		println(io, "    ),")
	end
	println(io, "]")
end


