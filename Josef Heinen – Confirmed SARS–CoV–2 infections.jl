### A Pluto.jl notebook ###
# v0.14.1

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ e2d1cb38-2698-11eb-2e59-632faa201d6f
begin
    using DelimitedFiles
	using PlutoUI

	ENV["GRDISPLAY"] = "pluto" # see note above
    using GR
	
    GR.js.init_pluto() # see note above
end

# ╔═╡ b2107723-4ff8-4d0f-84b2-4051f8ff48f5
md"""
## Plotting confirmed SARS–CoV–2 infections
### Author: [Josef Heinen](https://github.com/jheinen)

#### Required packages: PlutoUI, GR

You may have to comment out the Pluto part, if you are running the script on a remote web server. If you are running the script in a local notebook server, you will be able to pan/zoom the plot and display information when hovering over the data points.
"""

# ╔═╡ 49d120ea-2699-11eb-203d-fddbb33bb08b
begin
	url = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv"
	download(url, "covid19.csv")
end;

# ╔═╡ 4b5f800a-2699-11eb-2528-b5917c0461cf
begin
    data = readdlm("covid19.csv", ',')
    ncountries, ncols = size(data)
    ndays = ncols - 4
end;

# ╔═╡ b3307385-fc8d-4b0c-b4d9-f77a1e2a11ca
md"""
Here you can select the country you want to see.

You can select multiple countries or all countries with `Cmd`+`A`.
"""

# ╔═╡ 1c4aec86-269a-11eb-2204-098352e8267c
@bind countries MultiSelect(["Germany", "Austria", "Belgium", "Netherlands", "France", "Italy", "Spain", "US"], default=["Germany"])

# ╔═╡ 75ad9770-2699-11eb-0db7-5948da39d6e1
begin
	cummulated = Dict()
	for i in 1:ncountries
		country = data[i,2]
		if country in countries
			if !haskey(cummulated, country) cummulated[country] = zeros(ndays) end
			cummulated[country] .+= collect(data[i,5:end])
		end
	end
end

# ╔═╡ 86c70334-2699-11eb-1b52-cfa50b314e2b
begin
	day = collect(Float64, 1:ndays);
	confirmed = hcat([cummulated[country] for country in countries]...)
end;

# ╔═╡ 918f640a-2699-11eb-02d8-998ed76c614a
plot(day, confirmed, xlim=(0, ndays+1), ylim=(10, 20_000_000), ylog=true,
     title="Confirmed SARS–CoV–2 infections", xlabel="Day", ylabel="Confirmed",
     labels=countries, location=4)

# ╔═╡ Cell order:
# ╠═b2107723-4ff8-4d0f-84b2-4051f8ff48f5
# ╠═e2d1cb38-2698-11eb-2e59-632faa201d6f
# ╠═49d120ea-2699-11eb-203d-fddbb33bb08b
# ╠═4b5f800a-2699-11eb-2528-b5917c0461cf
# ╠═75ad9770-2699-11eb-0db7-5948da39d6e1
# ╠═86c70334-2699-11eb-1b52-cfa50b314e2b
# ╠═b3307385-fc8d-4b0c-b4d9-f77a1e2a11ca
# ╠═1c4aec86-269a-11eb-2204-098352e8267c
# ╠═918f640a-2699-11eb-02d8-998ed76c614a
