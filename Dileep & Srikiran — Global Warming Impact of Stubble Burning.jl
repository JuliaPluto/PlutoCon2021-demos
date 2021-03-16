### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# ╔═╡ 81888440-4d42-11eb-1bf5-0f0108717ed6
using Markdown

# ╔═╡ ee1dacd0-52e6-11eb-3486-0bb6ee49c951
using StatsPlots

# ╔═╡ e4abc46e-52e6-11eb-19e0-19a94e1257c6
using Random, Distributions

# ╔═╡ 5cce7220-846c-11eb-0a99-7bed14a9f937
using DataFrames

# ╔═╡ 8aa500ee-52e5-11eb-034e-15d346c9433e
begin
	co2_mean = 1420 # g/kg residue
	co2_std = 240
	ch4_mean = 5.5
	ch4_std = 5.7
	n2o_mean = 0.09
	n2o_std = 0.04;
	
	ch4_co2_eq_lower = 25; ch4_co2_eq_upper = 28; #unitless
	n2o_co2_eq_lower = 265; n2o_co2_eq_upper = 298;
	
	rcr_lower = 1.4; rcr_upper = 1.8; # kg residue / kg rice
	billion_tonnes_to_million_tonnes = 10^3;
	india_annual_emission_billion_tonnes = 2.46;
	india_annual_emission_million_tonnes = india_annual_emission_billion_tonnes * billion_tonnes_to_million_tonnes;
	
	Random.seed!(123)
	n_samples = 100;
	
	co2_amt = rand(truncated(Normal(co2_mean, co2_std), 0, co2_mean * 3), n_samples); # g/kg residue
	ch4_amt = rand(truncated(Normal(ch4_mean, ch4_std), 0, ch4_mean * 3), n_samples);
	ch4_co2eq_factor = rand(Uniform(ch4_co2_eq_lower, ch4_co2_eq_upper), n_samples);
	ch4_co2eq = ch4_amt .* ch4_co2eq_factor;
	n2o_amt = rand(truncated(Normal(n2o_mean, n2o_std), 0, n2o_mean * 3), n_samples);
	n2o_co2eq_factor = rand(Uniform(n2o_co2_eq_lower, n2o_co2_eq_upper), n_samples);
	n2o_co2eq = n2o_amt .* n2o_co2eq_factor;
	
	residue_per_kg_rice = rand(Uniform(rcr_lower, rcr_upper), n_samples);
	
	co2eq = co2_amt + ch4_co2eq + n2o_co2eq # co2eq / kg residue
	co2eq_per_kg_rice = co2eq .* residue_per_kg_rice # co2eq / kg rice
	
	residue_amt = 14; # units of million tonnes
	residue_amt_3_lower = 15; residue_amt_3_upper = 22.5;
	residue_amt_3 = rand(Uniform(residue_amt_3_lower, residue_amt_3_upper), n_samples);
	residue_amt_2 = 23;
	
	total_co2 = co2_amt .* residue_amt / 1e3 # g/kg residue * million tonnes residue * 1kg/1000g = million tonnes
	total_co2eq = co2eq .* residue_amt / 1e3
	total_co2_2 = co2_amt .* residue_amt_2 / 1e3
	total_co2eq_2 = co2eq .* residue_amt_2 / 1e3
	total_co2_3 = co2_amt .* residue_amt_3 / 1e3
	total_co2eq_3 = co2eq .* residue_amt_3 / 1e3
	
	co2_df = DataFrame(Amount = vcat(total_co2, total_co2_2, total_co2_3), 
	Case = vcat(repeat([1], n_samples),
		repeat([2], n_samples), repeat([3], n_samples)),
	Quantity = repeat(["CO2 only"], n_samples * 3));
	
	total_df = DataFrame(Amount = vcat(total_co2eq, total_co2eq_2, total_co2eq_3), 
	Case = vcat(repeat([1], n_samples),
		repeat([2], n_samples), repeat([3], n_samples)),
	Quantity = repeat(["Total"], n_samples * 3));
end;

# ╔═╡ e986fbd0-4d42-11eb-3342-ff3bb8eff1ad
md"# What is the global warming impact of crop stubble burning in Northern India?

By: Srikiran Chandrasekaran, Dileep Kishore

To clear the fields of the residue from the previous rice crop and make way for the subsequent wheat crop, some farmers in Northern India burn what's left in the field. Called crop residue burning or stubble burning, this happens in the months of October and November [1]. Manually clearing the residue, or using machines built for the purpose, may cost more [10].

We were interested in understanding the global warming impact of stubble burning. It contributes to global warming in at least two ways - through the release of greenhouse gases (GHGs) and the obvious one - the heat from burning the stubble. We were interested in the former.

## How is greenhouse gas global warming potential measured?

GHGs like carbon dioxide ($CO_2$) and methane ($CH_4$) have different propensities to cause global warming. Hence global warming potential is measured in CO2eq or, $CO_2$ equivalents. That is, any contribution from say, methane, is understood as the contribution coming from an equivalent amount of $CO_2$.

For example, suppose a process releases 10g of $CO_2$ and 2g of $CH_4$. And suppose that the global warming propensity of $CH_4$ is 3 times that of $CO_2$. Then this process contributes $10 + 2 \times 3 = 16$g CO2eq.

## Which GHGs, and how much?

Before understanding the overall global warming effects, its useful to know which GHGs are released when burning crop stubble. Here we looked at carbon dioxide, methane and nitrous oxide ($N_2O$). While the latter two are addressed in the analysis by the FAO [3], $CO_2$ was not.

To understand how much of each of these gases are produced per kg of crop residue, we looked at the meta analysis by Meinrat Andreae [2] and found the following

Gas | Mean emission (g/kg residue) | Standard deviation emission (g/kg residue) | Number of samples on which esitmate is based
---|---|---|---
$CO_2$ | $(co2_mean) | $(co2_std) | 25
$CH_4$ | $(ch4_mean) | $(ch4_std) | 17
$N_2O$ | $(n2o_mean) | $(n2o_std) | 5

And we also have the CO2eq data for the two gases from the following sources

Gas | CO2eq (g $CO_2$ / g gas) | Source
---|---|---
$CH_4$ | $(ch4_co2_eq_upper) | [4]
$N_2O$ | $(n2o_co2_eq_lower) | \"
$CH_4$ | $(ch4_co2_eq_lower) | [5]
$N_2O$ | $(n2o_co2_eq_upper) | \"

### Global warming impact per kg of residue

The numbers above are sufficient to understand the global warming impact of burning 1kg of crop residue. We assumed a normal distribution for the gas amounts (since we have mean and std) and a uniform distribution for the CO2eq factors (since we have two different values).

"

# ╔═╡ d6b15000-7f83-11eb-1fca-478cddbecf54
begin
	density([log10.(co2_amt), log10.(ch4_amt), log10.(n2o_amt)], label=["Carbon Dioxide" "Methane" "Nitrous Oxide"], width=2, ylabel="Density", xlabel="Log10(GHG emission) (g/kg residue)", title="Distribution of GHG emission/kg residue burnt", fill=true, legend=:topleft, alpha=0.5)
end

# ╔═╡ f4406d20-586b-11eb-0d35-51da6f73592e
md"Since the X axis is on the log scale, we observe that $CO_2$ emission is $\approx$2 orders of magnitude greater than $CH_4$ emission, which is an order greater than $N_2O$ emission. While these are simply the amounts, the impact on global warming is better reflected by the chart below."

# ╔═╡ 55efed92-7f84-11eb-0c2e-cd38094e461d
begin
	# gr(size=(2500,3000))
	density([log10.(co2_amt), log10.(ch4_co2eq), log10.(n2o_co2eq), log10.(co2eq)], width=2, ylabel="Density", xlabel="Log10(CO2eq) (g/kg residue)", title="Distribution of GHG emission gCO2eq/kg residue burnt", legend=:topleft, fill=true, alpha=0.5, label=["Carbon Dioxide" "Methane" "Nitrous Oxide" "Total"])
end

# ╔═╡ 925ff0a0-586e-11eb-24c5-3be428cb076f
md"

So it does appear that the impact of methane and nitrous oxide is higher than surmised purely based on their amounts. However it is only a fraction of the impact of $CO_2$ alone, based on the chosen data.

### Putting these numbers in perspective

To put these numbers in perspective, we looked at the $CO_2$ output of growing rice. 

- According to a publication [7] and the subsequent analysis by Our World in Data [8], growing one kg of *rice* creates approximately 4kg $CO_2$. Note that this estimate does not talk about the residue.
- In comparison, CO2 from burning residue is : $(round(mean(co2eq) / 1000, digits=2)) $$\pm$$ $(round(std(co2eq) / 1000, digits=2)) (mean $$\pm$$ SD) kg CO2eq for one kg of *residue* (from the plot above). 
- Using a conversion factor of $(rcr_lower) - $(rcr_upper) kg residue per kg rice crop [1], we have to $(round(mean(co2eq_per_kg_rice) / 1000, digits=2)) $$\pm$$ $(round(std(co2eq_per_kg_rice) / 1000, digits=2)) kg CO2eq per kg of rice grown (mean $$\pm$$ SD), from stubble burning.

It appears that growing rice with stubble burning creates $\approx$50% more CO2 ($(round(mean(co2eq_per_kg_rice) / 1000, digits=2)) kg compared to 4kg $$CO_2$$),than growing rice without stubble burning!

## Overall impact on global warming

To understand the overall impact of stubble burning on global warming, we found estimates for the amount of agricultural residue that was burned in 2016.

Case | Amount of residue (million tonnes)/ year | Source
---|---|---
1 | $(residue_amt) | [2]
2 | $(residue_amt_2) | [3]
3 | $(residue_amt_3_lower) - $(residue_amt_3_upper) | [6]

Computing the impact of these residue amounts is simply multiplying one or more of these residue amounts with the emission per kg from the previous section. This gives

"

# ╔═╡ 745cd7d0-846f-11eb-1cab-e1ec4e7d7fad
begin
	@df co2_df violin(:Case, :Amount, group = :Quantity, side=:left, 
		label="CO2 only", xticks=[1, 2, 3], xlabel="Cases", ylabel="CO2eq (million tonnes)", title="Distribution of gCO2eq from crop residue burning")
	@df total_df violin!(:Case, :Amount, group = :Quantity, side=:right, label="Total")
end

# ╔═╡ c2cb8850-86c5-11eb-2c30-8168e9df6a5a
md"We trust the estimate of of case number 1 most, since the authors of that publication follow a first principled approach to estimate the amount of residue, and use many data sources to avoid underestimations. For example, they fill in the gaps from satellite data with surveys.

### Putting these numbers in perspective

According to Our World in Data [9], the total CO2 emission of India is $india_annual_emission_billion_tonnes billion tonnes in 2017. The CO2eq from case number 1 as a fraction of this quantity evaluates to $(round(mean(total_co2eq) / (india_annual_emission_million_tonnes) * 100, digits=2)) $$\pm$$  
$(round(std(total_co2eq) / (india_annual_emission_million_tonnes) * 100, digits=2)) % (mean $$\pm$$ SD) or almost 1%! This is a lower estimate than case 2, where we are looking at $(round(mean(total_co2eq_2) / (india_annual_emission_million_tonnes) * 100, digits=2)) % $$\pm$$ $(round(std(total_co2eq_2) / (india_annual_emission_million_tonnes) * 100, digits=2)) % (mean $$\pm$$ SD).

## Summary of findings

1. The bulk of GHG emissions from stubble burning is from the direct contribution of $CO_2$, with small contributions from nitrous oxide and methane.
1. Compared to growing rice without stubble burning, growing rice with burning of crop residue releases $\approx$50% more CO2eq of GHG.
1. Accounting for how much rice is grown with stubble burning, the GHG contribution of stubble burning was $\approx$ 1% of the total GHG emissions of India in 2017.

> Note, we are not experts in this field. So results to be interpreted with caution.

"

# ╔═╡ 701820f0-52e5-11eb-1cff-195defc1e22a
md"

## Links

[1]: <https://doi.org/10.1016/j.aeaoa.2020.100091>

[2]: <https://doi.org/10.5194/acp-19-8523-2019>

[3]: <http://www.fao.org/faostat/en/#data/GB/metadata>

[4]: <https://cdiac.ess-dive.lbl.gov/pns/current_ghg.html>

[5]: <https://climatechangeconnection.org/emissions/co2-equivalents/>

[6]: <https://doi.org/10.1038/s41598-019-52799-x>

[7]: <https://doi.org/10.1126/science.aaq0216>

[8]: <https://ourworldindata.org/environmental-impacts-of-food>

[9]: <https://ourworldindata.org/co2/country/india?country=~IND>

[10]: <https://indianexpress.com/article/india/stubble-burning-punjab-farmers-amarinder-singh-ngt-air-pollution-4897240/>"

# ╔═╡ 8685b4b0-52e5-11eb-1414-bfb2439d473c


# ╔═╡ 77ed9760-52e5-11eb-3534-d512d858bd9d


# ╔═╡ Cell order:
# ╠═81888440-4d42-11eb-1bf5-0f0108717ed6
# ╠═ee1dacd0-52e6-11eb-3486-0bb6ee49c951
# ╠═e4abc46e-52e6-11eb-19e0-19a94e1257c6
# ╠═5cce7220-846c-11eb-0a99-7bed14a9f937
# ╟─e986fbd0-4d42-11eb-3342-ff3bb8eff1ad
# ╟─8aa500ee-52e5-11eb-034e-15d346c9433e
# ╟─d6b15000-7f83-11eb-1fca-478cddbecf54
# ╟─f4406d20-586b-11eb-0d35-51da6f73592e
# ╟─55efed92-7f84-11eb-0c2e-cd38094e461d
# ╟─925ff0a0-586e-11eb-24c5-3be428cb076f
# ╟─745cd7d0-846f-11eb-1cab-e1ec4e7d7fad
# ╟─c2cb8850-86c5-11eb-2c30-8168e9df6a5a
# ╟─701820f0-52e5-11eb-1cff-195defc1e22a
# ╟─8685b4b0-52e5-11eb-1414-bfb2439d473c
# ╟─77ed9760-52e5-11eb-3534-d512d858bd9d
