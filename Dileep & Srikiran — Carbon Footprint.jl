### A Pluto.jl notebook ###
# v0.12.21

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

# ╔═╡ 3b2050da-52c1-11eb-3b89-1d5b6eb2cf40
using PlutoUI, Printf, Plots, StatsPlots;

# ╔═╡ 49f027da-5dce-11eb-3fff-0fd590112019
using DataFrames, Distributions, Random

# ╔═╡ 8ae7009a-73c4-11eb-0374-25c172bd827e
md"""
# Carbon Footprint
"""

# ╔═╡ ae828cb2-86a8-11eb-2862-6137ecb692a5
md"""By: Dileep Kishore, Srikiran Chandrasekaran """

# ╔═╡ 94e65102-73c4-11eb-3cb4-81736a39e596
md"""
>A carbon footprint is the total greenhouse gas (GHG) emissions caused by an individual, event, organization, service, or product, expressed as carbon dioxide equivalent.  
>Source: Wikipedia.

From an individual perspective, GHG may be emitted from activities such as driving a car, consuming food or even just streaming content over the internet.

In this dashboard we limit the sources of GHG emissions to:
1. Electricity usage
2. Food consumption
3. Streaming over the internet
4. Purchase of manufactured goods
5. Transportation
"""

# ╔═╡ 054ae36c-52cb-11eb-25aa-31355bbed6de
md"""## Sources of GHG emissions

Most of the data presented here was obtained from [NMF-earth](https://github.com/NMF-earth/carbon-footprint). The direct sources of the data are listed along with the source descriptions below:
"""

# ╔═╡ b4a152f0-4d4f-11eb-106b-b58e9f1495a9
import JSON, HTTP

# ╔═╡ 69f1de08-7e7f-11eb-1df1-c792e5e3ec57
md"""
First we write a function `read_json` to read `JSON` data from our [GitHub repository](https://github.com/quantumbrake/ghg-dashboard/) into a `Dict`
"""

# ╔═╡ cedb71ac-52b9-11eb-19e7-9f433ffb4f14
function read_json(
	file::String;
	repo::String = "https://raw.githubusercontent.com/quantumbrake/ghg-dashboard/main/"
	)::Dict
	file_url = repo * file
	raw_string = String(HTTP.get(file_url).body)
	data = JSON.parse(raw_string)
	return data
end

# ╔═╡ b2b598f8-4d3f-11eb-310d-7740ecc9d222
md"""
### 1. Electricity usage

The emissions involved in generating 1 Joule of energy in various countries

Unit: $\frac{kgCO_2eq}{J}$

Unit of imported data: $\frac{kgCO_2eq}{kWh}$

Conversion factor (imported data -> data): $(\frac{x}{3.6}) * 10^{-6}$

**Sources**:
- https://github.com/carbonalyser/Carbonalyser
- https://www.electricitymap.org - 28th of April 2020
"""

# ╔═╡ 0fcd983e-52b7-11eb-2c1f-13d00c8b4c43
begin
	pw_to_pj(x::Float64)::Float64 = (x / 3.6) * (10 ^ (-6))
	electricity_data_pw = read_json("data/carbon_footprint/electricity.json")
	values_pj = map(x -> pw_to_pj(x), values(electricity_data_pw))
	electricity_data = Dict(zip(keys(electricity_data_pw), values_pj))
	DataFrame(electricity_data)
end

# ╔═╡ 1fc15990-4d41-11eb-0f5f-c309cf01fdfa
md"""
### 2. Food consumption

The emissions involved in producing 1 item of various foods

Unit: $\frac{kgCO_2eq}{\textrm{item}}$

**Sources**:
- http://www.greeneatz.com/foods-carbon-footprint.html
- https://www.bilans-ges.ademe.fr
"""

# ╔═╡ 329e738a-52ba-11eb-22dd-fbfe2de89bb1
begin
	food_data = read_json("data/carbon_footprint/food.json")
	DataFrame(food_data)
end

# ╔═╡ e8574808-4d49-11eb-3515-2d66aadee9f2
md"""
### 3. Streaming over the internet

The emissions involved in streaming various content

Unit: $\frac{kgCO_2eq}{minute}$

**Standards used to calculate data size of streaming content**:
- HD / 720p : 1.21 GB (~ 2.5 hours)
- Full HD / 1080p : 7.02 GB (~ 2.5 hours)
- Ultra HD / 2160p : 35.73 Gb (~ 2.5 hours)
- MP3 song at 192 kbps : 3.8 MB (~ 2.5 mins)
"""

# ╔═╡ 83af9228-6353-11eb-0e5b-4550ac55ca4f
streaming_data = Dict(["HDVideo" => "Video HD",
			"fullHDVideo" => "Video - FullHD/1080p",
			"ultraHDVideo" => "Video - UltraHD/4K",
			"audioMP3" => "Audio - MP3"]);

# ╔═╡ fb596dc6-4d41-11eb-1dbd-6707e4fa7778
md"""
Calculating the emissions involved in moving data between the device and datacenter through the network.

Unit: $kgCO_2eq$

**Sources**:
- https://theshiftproject.org/wp-content/uploads/2019/03/Lean-ICT-Report_The-Shift-Project_2019.pdf
- https://github.com/carbonalyser/
- https://www.carbonbrief.org/factcheck-what-is-the-carbon-footprint-of-streaming-video-on-netflix
"""

# ╔═╡ 227d45a0-4d45-11eb-0cca-af99bc390097
function kwatts_to_joules(x::Float64)::Float64
		x * 3.6 * (10 ^ 6);
end

# ╔═╡ d4764dc0-7e81-11eb-29da-adbfa04c613b
md"""
We create a function to calculate the GHG emissions involved in transmitting `dataweight` (in bits) amount of data for a `duration` (in seconds) in a country with emission intensity equal to `electricity_intensity` (in $kgCO_2eq.J^{-1}$). As suggested by the units of this quantity, emission intensity is simply the amount of $CO_2$ in kilograms per emitted per Joule of energy produced.
"""

# ╔═╡ cfd60bf8-4d43-11eb-00b7-bd162061b954
function internet_carbonimpact(
		duration::Float64,
		data_weight::Float64,
		electricity_intensity::Float64
	)::Float64
	factor = Dict(
		"datacenter" => kwatts_to_joules(0.007 * (10 ^ (-9))) / 8,
		"network" => kwatts_to_joules(0.058 * (10 ^ (-9))) / 8,
		"device" => kwatts_to_joules(0.055 / (60 * 60))
	)
	ghg_datacenter = data_weight * get(factor, "datacenter", 0.0) * electricity_data["world"]
	ghg_network = data_weight * get(factor, "network", 0.0) * electricity_data["world"]
	ghg_device = duration * get(factor, "device", 0.0) * electricity_intensity
	total = ghg_datacenter + ghg_network + ghg_device
	return total
end

# ╔═╡ c25bfd94-7f7e-11eb-32ff-6fb869cd3b43
md"""
Next, we create a function to calculate carbon emissions created while streaming a particular type of content (`stream_type`) for `duration` (in seconds) in a country with emission intensity equal to `electricity_intensity` (in $kgCO_2eq.J^{-1}$)
"""

# ╔═╡ 5e3ae372-4d4a-11eb-3e76-e7b1545f3759
function streaming_carbonimpact(
		stream_type::String,
		duration::Float64,
		electricity_intensity::Float64
	)::Float64
	# assuming movie duration = 2h 22m, and file size as given above.
	# factor is a dictionary mapping kind of data to bits/s.
	factor = Dict(
		"HDVideo" => (1.21 * (10 ^ 9) * 8) / ((2 * 60 + 22) * 60),
		"fullHDVideo" => (7.02* (10 ^ 9) * 8) / ((2 * 60 + 22) * 60),
		"ultraHDVideo" => (35.73 * (10 ^ 9) * 8) / ((2 * 60 + 22) * 60),
		"audioMP3" => (3.8 * (10 ^ 6) * 8) / 154
	)
	data_weight = get(factor, stream_type, 0.0)
	total_carbonimpact = internet_carbonimpact(
		duration,
		data_weight,
		electricity_intensity
	)
	return total_carbonimpact
end

# ╔═╡ cccb00f0-4d46-11eb-027b-ab6e07ce3ce5
md"""
### 4. Purchase of manufactured goods

The emissions involved in producing 1 item of various products

Unit: $\frac{kgCO_2eq}{item}$

**Sources Clothing**:
- https://www.ademe.fr/sites/default/files/assets/documents/poids_carbone-biens-equipement-201809-rapport.pdf

**Sources Tech**:
- https://www.apple.com/lae/environment/pdf/products/iphone/iPhone_11_Pro_PER_sept2019.pdf
- https://www.apple.com/lae/environment/pdf/products/ipad/iPad_PER_sept2019.pdf
- https://www.apple.com/lae/environment/pdf/products/desktops/21.5-inch_iMac_with_Retina4KDisplay_PER_Mar2019.pdf
- https://www.apple.com/lae/environment/pdf/products/notebooks/13-inch_MacBookPro_PER_June2019.pdf
- https://www.bilans-ges.ademe.fr/fr/basecarbone/donnees-consulter/liste-element?recherche=T%C3%A9l%C3%A9vision

**Sources Transport**:
-   https://www.lowcvp.org.uk/assets/workingdocuments/MC-P-11-15a%20Lifecycle%20emissions%20report.pdf
"""

# ╔═╡ 42eb4b3e-52ba-11eb-2178-11e1d2a887af
begin
	purchase_data = read_json("data/carbon_footprint/purchase.json")
	DataFrame(purchase_data)
end

# ╔═╡ cd98af32-4d4b-11eb-2ffb-edbe9a3c069b
md"""
### 5. Transportation

The emissions per meter travelled in various vehicles

Unit: $\frac{kgCO_2eq}{m}$

**Sources**:
- https://static.ducky.eco/calculator_documentation.pdf
"""

# ╔═╡ 04b51758-52b7-11eb-10f9-f5be66cf0dec
begin
	transport_data = read_json("data/carbon_footprint/transport.json")
	DataFrame(transport_data)
end

# ╔═╡ 66d55490-7f7c-11eb-2d2d-77f9b4f7b184
md"""---"""

# ╔═╡ 0442fbb8-52c0-11eb-06ea-01e68e330d5d
md"""
## Carbon footprint Dashboard
"""

# ╔═╡ 52ee864c-8445-11eb-15b0-47a0f97b6fec
plotly()

# ╔═╡ 5fbcb6e6-52ca-11eb-3e8c-1bb7495dc15d
md"""### Check your emissions here

You can use this section to compute the total emissions from various activities. Note that this is emissions from all these activities, and not normalized on a per day basis for instance."""

# ╔═╡ 1b612ec2-52c1-11eb-22aa-3b406bd64623
md"""
#### Electricity:

Electricty location
$(@bind electricity_select Select([k => k for (k, v) in electricity_data]))

Electricity amount (in kWh)
$(@bind electricity_amount Slider(1:1000, default=10, show_value=true))

#### Food:

Food type
$(@bind food_select Select([k => k for (k, v) in food_data]))

Food amount (in grams)
$(@bind food_amount Slider(5:500, default=10, show_value=true))


#### Streaming:

Streaming type
$(@bind streaming_select Select(["HDVideo" => "Video HD",
			"fullHDVideo" => "Video - FullHD/1080p",
			"ultraHDVideo" => "Video - UltraHD/4K",
			"audioMP3" => "Audio - MP3"]))

Duration (in minutes)
$(@bind streaming_amount Slider(10:600, default=60, show_value=true))

#### Purchases:

Recent purchases
$(@bind purchase_select MultiSelect([k => k for (k, v) in purchase_data]))

#### Transport:

Transport type
$(@bind transport_select Select([k => k for (k, v) in transport_data]))

Transport distance (in km)
$(@bind transport_distance Slider(1:1000, default=10, show_value=true))
"""

# ╔═╡ f5225d7a-5846-11eb-1497-c5d439899e6b
function emission_calculator(
		transport_select::String,
		transport_distance::Integer,
		food_select::String,
		food_amount::Integer,
		streaming_select::String,
		streaming_amount::Integer,
		electricity_select::String,
		electricity_amount::Integer,
		purchase_select::Array,
)::Dict
	transport_emissions = transport_data[transport_select] * transport_distance * 1000
	food_emissions = food_data[food_select] * food_amount / 1000
	streaming_emissions = streaming_carbonimpact(streaming_select,streaming_amount * 60.0,electricity_data["world"])
	electricity_emissions = electricity_data_pw[electricity_select] * electricity_amount
	if isempty(purchase_select)
		purchase_emissions = 0.0
	else
		purchase_emissions = sum([purchase_data[purchase] for purchase in purchase_select])
	end
	total_emissions = (transport_emissions + food_emissions + streaming_emissions + electricity_emissions + purchase_emissions)
	data = Dict(
		"transport" => transport_emissions,
		"food" => food_emissions,
		"streaming" => streaming_emissions,
		"electricity" => electricity_emissions,
		"purchase" => purchase_emissions,
		"total" => total_emissions,
		)
	return data
end

# ╔═╡ 8aa42c6e-6354-11eb-3c43-cb16327595c2
function emission_calculator(
		transport_select::Array{String,1},
		transport_distance::Array{Int64,1},
		food_select::Array{String,1},
		food_amount::Array{Int64,1},
		streaming_select::Array{String,1},
		streaming_amount::Array{Int64,1},
		electricity_select::String,
		electricity_amount::Int64,
		purchase_select::Array{String, 1},
		purchase_amount::Array{Int64, 1},
)::Dict
	transport_emissions = 0
	for (i, j) in zip(transport_select, transport_distance)
		transport_emissions += transport_data[i] * j * 1000
	end
	food_emissions = 0
	for (i, j) in zip(food_select, food_amount)
		food_emissions += food_data[i] * j / 1000
	end
	streaming_emissions = 0
	for (i, j) in zip(streaming_select, streaming_amount)
		streaming_emissions += streaming_carbonimpact(i, j * 60.0,electricity_data["world"])
	end
	electricity_emissions = electricity_data_pw[electricity_select] * electricity_amount
	purchase_emissions = 0.0
	for (i, j) in zip(purchase_select, purchase_amount)
		purchase_emissions += purchase_data[i] * j
	end
	total_emissions = (transport_emissions + food_emissions + streaming_emissions + electricity_emissions + purchase_emissions)
	data = Dict(
		"transport" => transport_emissions,
		"food" => food_emissions,
		"streaming" => streaming_emissions,
		"electricity" => electricity_emissions,
		"purchase" => purchase_emissions,
		"total" => total_emissions,
		)
	return data
end

# ╔═╡ 9388aa8a-52c9-11eb-0dd8-3184bcfb93b2
begin
	emissions_data = emission_calculator(
			transport_select,
			transport_distance,
			food_select,
			food_amount,
			streaming_select,
			streaming_amount,
			electricity_select,
			electricity_amount,
			purchase_select,
	)
	transport_emissions = emissions_data["transport"]
	food_emissions =  emissions_data["food"]
	streaming_emissions =  emissions_data["streaming"]
	electricity_emissions =  emissions_data["electricity"]
	purchase_emissions = emissions_data["purchase"]
	total_emissions = emissions_data["total"]
	"Emissions calculation code"
end

# ╔═╡ 2b0d264c-7f7f-11eb-2bf6-1119de8bbe96
begin
	x = ["Electricity", "Food", "Streaming", "Purchases", "Transport"]
	y = [electricity_emissions, food_emissions, streaming_emissions, purchase_emissions, transport_emissions]
	pie(x, y, title="Emissions breakdown (Total = $(@sprintf("%.2f", total_emissions)) kgCO2eq)", legend=:right)
end

# ╔═╡ 0a38c120-52c6-11eb-2ec5-e7780b3e11ec
md"""
### Your carbon footprint:

| Emission source | kgCO2eq |
| --- | --- |
| Electricity | $(@sprintf("%.3f", electricity_emissions)) |
| Food | $(@sprintf("%.3f", food_emissions)) |
| Streaming | $(@sprintf("%.3f", streaming_emissions)) |
| Purchase | $(@sprintf("%.3f", purchase_emissions)) |
| Transport | $(@sprintf("%.3f", transport_emissions))  |
| **Total emissions** | **$(@sprintf("%.3f", total_emissions))** |

"""

# ╔═╡ ec388b4a-52ca-11eb-097d-6760de18dd0e
md"""---"""

# ╔═╡ 34baf426-7f7f-11eb-0cf0-bb0d1a7c28fd
md"""
## Carbon footprint simulations for different lifestyles
"""

# ╔═╡ 672fef94-6351-11eb-0af1-652d5992e129
Random.seed!(1234);

# ╔═╡ 18787dee-8446-11eb-2b9d-9967d7fe6d5c
md"""
We create a "Person" `struct` that stores information about a lifestyle. This can be used to simulate the daily behavior of a person following this lifestyle and understand emissions due to:
1. Vehicles owned and their usage distribution
2. Food consumed and their amount
3. Content streamed and their amount
4. Country of residence
5. Commonly purchased products and their purchase rates

>NOTE:
>We assume that the distributions for each emission type are applicable to all objects or items of that type.
>Eg: If `foods` are "tofu" and "beans" and the provided `food_consumption` distribution is $\mathcal{N}(150, 50)$, we assume that each food item follows that distribution.
"""

# ╔═╡ 49571046-68c2-11eb-071e-2709f8e40e48
struct Person
	vehicles::Array{String,1}
	transport_distribution::ContinuousUnivariateDistribution
	foods::Array{String,1}
	food_consumption::ContinuousUnivariateDistribution
	streams::Array{String,1}
	streaming_distribution::ContinuousUnivariateDistribution
	country::String
	electricity_usage::ContinuousUnivariateDistribution
	purchases::Array{String,1}
	purchase_rate::DiscreteUnivariateDistribution
end

# ╔═╡ e0ad3a7e-8447-11eb-2df2-3d52fffaab6b
md"""
We create functions to calculate the daily and yearly emissions of a `Person`:
"""

# ╔═╡ 2c63765e-68c3-11eb-317c-d1603846ca9c
function daily_emissions(person::Person)::Dict
	transport_distances = floor.(
		Int,
		rand(
			person.transport_distribution,
			length(person.vehicles)
		)
	)
	food_amounts = floor.(
		Int,
		rand(
			person.food_consumption,
			length(person.foods)
		)
	)
	stream_amounts = floor.(
		Int,
		rand(
			person.streaming_distribution,
			length(person.streams)
		)
	)
	electricity_amounts = floor.(
		Int,
		rand(
			person.electricity_usage,
		)
	)
	purchase_amounts = floor.(
		Int,
		rand(
			person.purchase_rate,
			length(person.purchases)
		)
	)
	result = emission_calculator(
	person.vehicles,
	transport_distances,
	person.foods,
	food_amounts,
	person.streams,
	stream_amounts,
	person.country,
	electricity_amounts,
	person.purchases,
	purchase_amounts,
	)
	return result
end

# ╔═╡ 7bb8f0e4-8448-11eb-2bd5-e9f94078860e
function yearly_emissions(person::Person)::DataFrame
	df = DataFrame(daily_emissions(person))
	for i in range(2, stop=365)
		push!(df, daily_emissions(person))
	end
	return df
end

# ╔═╡ 04badb38-8448-11eb-2750-fde9b58547e4
md"""
### Case Study: Switching from a meat rich diet to a vegan diet

Let us consider the case where a person following a meat rich diet considers switching to a vegan diet and the impact it would have on their carbon footprint
"""

# ╔═╡ 5114761e-84d0-11eb-094e-fde0d465d19e
md"""
We create a `Person` who eats a diet rich in meat and animal derived products (`person_meat`) and a `Person` who follows a vegan diet (`person_vegan`). The only differences between these two is in the food items they eat (consumption quantities are the same).

Each `Person`:
1. Owns a car and drives on an average of 50 km per day
2. Watches ultraHDVideo for an average of 240 mins a day
3. Lives in the USA and uses an average of 30 kWh of electrcity per day
4. Buys jeans, shirts and shoes at the rate of 1 per 100 days

Additionally:
- The `person_meat` eats an average of 120g of pork, chicken, milk, eggs and rice everyday
- The `person_vegan` eats an average of 120g of fruit, tofu, beans, vegetables and rice everyday

>Note that it is possible to create more accurate and sophisticated distributions, but for the purposes of this case study we have decided to limit it to simple foods and distributions.
"""

# ╔═╡ f9d0182e-8450-11eb-3f42-3df1cf54cf96
person_meat = Person(
	["car"],
	truncated(Normal(50, 5), 0, 1000),
	["pork", "chicken", "milk", "eggs", "rice"],
	truncated(Normal(120, 20), 0, 500),
	["ultraHDVideo"],
	truncated(Normal(240, 50), 0, 600),  # 240 mins is US average
	"usa",
	truncated(Normal(30, 5), 0, 200),  # 30 kwh is US average
	["jeans", "shirt", "shoes"],
	Poisson(0.01)
)

# ╔═╡ 521ebdb6-68c5-11eb-3bb2-8926b33ec780
person_vegan = Person(
	["car"],
	truncated(Normal(50, 5), 0, 1000),
	["fruit", "tofu", "beans", "vegetables", "rice"],
	truncated(Normal(120, 20), 0, 500),
	["ultraHDVideo"],
	truncated(Normal(240, 50), 0, 600),  # 240 mins is US average
	"usa",
	truncated(Normal(30, 5), 0, 200),  # 30 kwh is US average
	["jeans", "shirt", "shoes"],
	Poisson(0.01)
)

# ╔═╡ 081ee4fc-84f4-11eb-3bad-a1e680d897b3
md"""
The daily emissions of `person_meat` for a year:
"""

# ╔═╡ 2af54294-8451-11eb-29b9-dd400f6ceb74
emissions_meat = yearly_emissions(person_meat)

# ╔═╡ f0ecfbb6-84f3-11eb-0b02-27ffea69c7ca
md"""
The daily emissions of `person_vegan` for a year:
"""

# ╔═╡ 751bb036-844e-11eb-035b-6d62fe25bfce
emissions_vegan = yearly_emissions(person_vegan)

# ╔═╡ b185179e-8451-11eb-1877-593c6b4be750
begin
	emissions_vegan_long = stack(emissions_vegan, [:electricity, :food, :purchase, :streaming, :transport]);
	emissions_meat_long = stack(emissions_meat, [:electricity, :food, :purchase, :streaming, :transport]);
end;

# ╔═╡ 4d7c796a-84f4-11eb-19cf-dfd729ac8b98
md"""
A plot of the distributions of daily emissions of each `Person` in each category is shown below. Only the distribution of emissions from food consumption are distinctly different (as per the design of the case study)
"""

# ╔═╡ 5b1d34d4-8451-11eb-15b5-1d45b1b3cb01
begin
	@df emissions_vegan_long violin(:variable, :value, side=:left, label="vegan diet", linewidth=0, title="Distribution of carbon emissions", ylabel="kgCO2eq")
	@df emissions_meat_long violin!(:variable, :value, side=:right, label="meat diet", linewidth=0)
end

# ╔═╡ 2245ae6e-84f5-11eb-0bc9-61f05b3d6935
md"""
We then plot only the distribution of daily emissions from food consumption of both `person_vegan` and `person_meat`.

The means are $\approx$ $(@sprintf("%.3f", mean(emissions_meat[!, :food]) - mean(emissions_vegan[!, :food]))) kgCO2eq apart (with the meat diet having higher emissions) and we observe that the choice of foods allowed for the meat diet in this case study offer for a wider range of emissions compared to the vegan diet.
"""

# ╔═╡ b7a631d2-8454-11eb-3ff7-5b02d14ce2b9
begin
	@df emissions_vegan density(:food, fill=(0, .5, :green), label="vegan diet (food)", xlabel="kgCO2eq", ylabel="Density", title="Density plot of daily emissions due to food", legend=:right)
	@df emissions_meat density!(:food, fill=(0, .5, :red), label="meat diet (food)")
end

# ╔═╡ e6423e30-84f6-11eb-0c07-cdae8e894eb0
md"""
Does this shift in the distribution of emissions due to food consumption affect the overall carbon emissions in any significant way?

To answer this question we plot the distribution of total emissions (shown below) and observe that there is indeed a shift in the daily total emission by $\approx$ $(@sprintf("%.3f", mean(emissions_meat[!, :total]) - mean(emissions_vegan[!, :total]))) kgCO2eq, which means that the vegan diet has reduced daily emissions by $(@sprintf("%.2f", (1 - (mean(emissions_vegan[!, :total]) / mean(emissions_meat[!, :total]))) * 100 ))%
"""

# ╔═╡ c760edd0-8452-11eb-318b-9de3fd9409ae
begin
	@df emissions_vegan density(:total, fill=(0, .5, :green), label="vegan diet (total)", xlabel="kgCO2eq", ylabel="Density", title="Density plot of the daily total emissions", legend=:right)
	@df emissions_meat density!(:total, fill=(0, .5, :red), label="meat diet (total)")
end

# ╔═╡ 3ce10e94-8455-11eb-0083-3dea8a3ebc13
md"""
Total **annual** difference in emissions would amount to $\approx$ $(@sprintf("%.2f", sum(emissions_meat[!, :total]) - sum(emissions_vegan[!, :total]))) kgCO2eq. Implying that the switching to a vegan diet would allow one to reduce their carbon footprint by a considerable amount.
"""

# ╔═╡ Cell order:
# ╟─8ae7009a-73c4-11eb-0374-25c172bd827e
# ╟─ae828cb2-86a8-11eb-2862-6137ecb692a5
# ╟─94e65102-73c4-11eb-3cb4-81736a39e596
# ╟─054ae36c-52cb-11eb-25aa-31355bbed6de
# ╠═b4a152f0-4d4f-11eb-106b-b58e9f1495a9
# ╟─69f1de08-7e7f-11eb-1df1-c792e5e3ec57
# ╠═cedb71ac-52b9-11eb-19e7-9f433ffb4f14
# ╟─b2b598f8-4d3f-11eb-310d-7740ecc9d222
# ╟─0fcd983e-52b7-11eb-2c1f-13d00c8b4c43
# ╟─1fc15990-4d41-11eb-0f5f-c309cf01fdfa
# ╟─329e738a-52ba-11eb-22dd-fbfe2de89bb1
# ╟─e8574808-4d49-11eb-3515-2d66aadee9f2
# ╟─83af9228-6353-11eb-0e5b-4550ac55ca4f
# ╟─fb596dc6-4d41-11eb-1dbd-6707e4fa7778
# ╠═227d45a0-4d45-11eb-0cca-af99bc390097
# ╟─d4764dc0-7e81-11eb-29da-adbfa04c613b
# ╠═cfd60bf8-4d43-11eb-00b7-bd162061b954
# ╟─c25bfd94-7f7e-11eb-32ff-6fb869cd3b43
# ╠═5e3ae372-4d4a-11eb-3e76-e7b1545f3759
# ╟─cccb00f0-4d46-11eb-027b-ab6e07ce3ce5
# ╟─42eb4b3e-52ba-11eb-2178-11e1d2a887af
# ╟─cd98af32-4d4b-11eb-2ffb-edbe9a3c069b
# ╟─04b51758-52b7-11eb-10f9-f5be66cf0dec
# ╟─66d55490-7f7c-11eb-2d2d-77f9b4f7b184
# ╟─0442fbb8-52c0-11eb-06ea-01e68e330d5d
# ╠═3b2050da-52c1-11eb-3b89-1d5b6eb2cf40
# ╟─52ee864c-8445-11eb-15b0-47a0f97b6fec
# ╟─5fbcb6e6-52ca-11eb-3e8c-1bb7495dc15d
# ╟─1b612ec2-52c1-11eb-22aa-3b406bd64623
# ╟─2b0d264c-7f7f-11eb-2bf6-1119de8bbe96
# ╟─0a38c120-52c6-11eb-2ec5-e7780b3e11ec
# ╟─f5225d7a-5846-11eb-1497-c5d439899e6b
# ╟─8aa42c6e-6354-11eb-3c43-cb16327595c2
# ╟─9388aa8a-52c9-11eb-0dd8-3184bcfb93b2
# ╟─ec388b4a-52ca-11eb-097d-6760de18dd0e
# ╟─34baf426-7f7f-11eb-0cf0-bb0d1a7c28fd
# ╠═49f027da-5dce-11eb-3fff-0fd590112019
# ╠═672fef94-6351-11eb-0af1-652d5992e129
# ╟─18787dee-8446-11eb-2b9d-9967d7fe6d5c
# ╠═49571046-68c2-11eb-071e-2709f8e40e48
# ╟─e0ad3a7e-8447-11eb-2df2-3d52fffaab6b
# ╟─2c63765e-68c3-11eb-317c-d1603846ca9c
# ╟─7bb8f0e4-8448-11eb-2bd5-e9f94078860e
# ╟─04badb38-8448-11eb-2750-fde9b58547e4
# ╟─5114761e-84d0-11eb-094e-fde0d465d19e
# ╠═f9d0182e-8450-11eb-3f42-3df1cf54cf96
# ╠═521ebdb6-68c5-11eb-3bb2-8926b33ec780
# ╟─081ee4fc-84f4-11eb-3bad-a1e680d897b3
# ╟─2af54294-8451-11eb-29b9-dd400f6ceb74
# ╟─f0ecfbb6-84f3-11eb-0b02-27ffea69c7ca
# ╟─751bb036-844e-11eb-035b-6d62fe25bfce
# ╟─b185179e-8451-11eb-1877-593c6b4be750
# ╟─4d7c796a-84f4-11eb-19cf-dfd729ac8b98
# ╟─5b1d34d4-8451-11eb-15b5-1d45b1b3cb01
# ╟─2245ae6e-84f5-11eb-0bc9-61f05b3d6935
# ╟─b7a631d2-8454-11eb-3ff7-5b02d14ce2b9
# ╟─e6423e30-84f6-11eb-0c07-cdae8e894eb0
# ╟─c760edd0-8452-11eb-318b-9de3fd9409ae
# ╟─3ce10e94-8455-11eb-0083-3dea8a3ebc13
