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

# ╔═╡ 214b7040-5424-11eb-20a0-3316520c333e
begin
	import Pkg
	Pkg.activate(mktempdir())
	# Pkg.add("Revise")
	# using Revise
	
	Pkg.add(["DataFrames", "CSV", "TableIO", "Curves", "PlutoUI", "Plots", "ZipFile",  "ShiftedArrays", "Statistics", "Distributions", "CurrencyAmounts"])
	
	using DataFrames, CSV, TableIO, Curves, Dates, PlutoUI, Plots, ShiftedArrays, Statistics, Distributions
	plotly()
	
	using CurrencyAmounts
	const EUR = Currency(:EUR)
	const USD = Currency(:USD)
	const DKK = Currency(:DKK)
	const SEK = Currency(:SEK)
	const NOK = Currency(:NOK)
	
	Pkg.add(Pkg.PackageSpec(url="https://github.com/lungben/MarketRiskPrototype.git"))
	using MarketRiskPrototype
end

# ╔═╡ ac41d630-54e2-11eb-3dde-f374a3e297c7
md"""
# Price Time Series and Historical Simulation VaR
"""

# ╔═╡ 527c6812-51d9-11eb-312a-4f9a773af0e1
md"""
## Trade Definitions
"""

# ╔═╡ 9ee3b9c3-466c-479f-9beb-0098fad79e0f
md"""
For this example, a portfolio of cash-settled FX Forwards is used. 

Cash-settled FX Forwards are rather simple products because they only have a single cashflow at maturity $T$:

\begin{equation}
CF(T) = Notional \cdot \left( FX_{contractual}(T) - FX(T) \right)
\end{equation}

Thus, the present value at $t < T$ is:
\begin{equation}
PV(t) = Notional \cdot \left( FX_{contractual}(T) - FX(t, T) \right) \cdot df(t, T)
\end{equation}

Where $FX(t, T)$ is the FX forward rate and $df(t, T)$ the discount factor from $t$ to $T$.
"""

# ╔═╡ b8665350-51e0-11eb-13f6-d902368ec2ab
all_trades = [
	# parameters: 1. notional, 2. settlement currency, 3. contractual FX rate,
	# 4. time to maturity (T-t)
	FXForward(100000.0EUR, USD, 1.2USD/EUR, t"3M"),
	FXForward(100000.0USD, EUR, 0.9EUR/USD, t"3M"),
	FXForward(100000.0USD, SEK, 9.5SEK/USD, t"6M"),
	FXForward(-100000.0USD, SEK, 8.5SEK/USD, t"1Y"),
	FXForward(100000.0USD, EUR, 0.95EUR/USD, t"2M"),
]

# ╔═╡ 99be0f5d-c52e-4d79-9b3d-ea23028f515b
md"""
For simplicity, this portfolio contains only one product type, but this approach may be generalized to any portfolio.
"""

# ╔═╡ bb8a57c0-54e2-11eb-05dd-cb81329ee0c0
md"""
## Price Time Series
"""

# ╔═╡ 44035cbd-ced1-4b85-85ef-8b3c4ece03fa
md"""
This is the time dependence of the present value (in EUR) for the single trades and the total portfolio.
"""

# ╔═╡ 3244b430-54d6-11eb-14bc-1357fda1020c
md"""
## Market Risk
"""

# ╔═╡ 09459651-740c-4dae-8fde-86cc8b2359c2
md"""
The Value-at-Risk $VaR_n^c$ is defined as the maximum loss a portfolio does not exceed in a given time horizon $n$ with the confidence level $c$.

E.g. $VaR^{99\%}_{5d} = 1,000,000 EUR$ means that the present value of the portfolio decreases in 5 business days by a value of less than 1 million EUR in $99\%$ of the cases.

VaR is one of the most commonly used measures for market risk in financial industry.
"""

# ╔═╡ 8ade16f0-54d5-11eb-3fe9-d334f1578236
md"""
VaR Confidence Level $c$:
"""

# ╔═╡ 66ab6d50-54d5-11eb-152a-299a27e573f6
@bind confidence_level Slider(0.9:0.001:0.999, default=0.99, show_value=true)

# ╔═╡ a0218290-54d5-11eb-3e54-abf6eb6fb8fd
md"""
VaR Time Horizon $n$ (in business days):
"""

# ╔═╡ a8cf57a2-54d5-11eb-2679-8f44e902d5d7
@bind time_horizon NumberField(1:20, default=1)

# ╔═╡ 37e98c9b-9c83-4559-b6c7-caf30b2ecc7d
md"""
There are different methods for the calculation of VaR. 

In this notebook, we are using the (classical) *historical simulation* method, where past returns of each risk factor are applied on the current value of the risk factor to generate sceanario P&Ls (= Profit & Loss, PV difference between $t$ and $t+n$).

The main parameter for a historical simulation is the *Lookback Period* $L$, this is the time period before the current date included for the historical scenarios.
"""

# ╔═╡ dd6a98d0-54d5-11eb-2151-59ab4f323fa0
md"""
Lookback Period $L$ (in business days):
"""

# ╔═╡ f010eb60-54d5-11eb-0652-db1e8c3bc560
@bind lookback_period NumberField(1:1000, default=250)

# ╔═╡ 1095cf15-475e-443d-b685-939509de6c4d
md"""
The VaR results for a specific calculation date:
"""

# ╔═╡ ac367dd0-54dd-11eb-3124-7961cef8a5c3
md"""
Calculation Date:
"""

# ╔═╡ f1c406b0-54e2-11eb-1522-bf45d8cfae34
md"""
## VaR Time Series
"""

# ╔═╡ 27cfe650-de9a-4a77-bee9-f92e6eaa7363
md"""
In order to assess the validity of the risk model, it is not sufficient to look at the VaR numbers for a specific date. Instead, the VaR numbers for a longer period are calculated and compared to the realized P&Ls, the so-called $backtesting$.

The most fundamental backtest is for the number of outliers - for a VaR with confidence level $C$ it is expected that the fraction of days where the loss exceeds VaR is $1-c$.

In oder to assess the statistical significance of the observed number of outliers, a $\chi^2$ hypothesis test, the so-called *Kupiec POF* test, is used. 

From regulatory side (Basel-regulation), a traffic light is defined based on the probability to reject a correct risk model: 

🟡 for level 2 error probability $<5\%$ (corresponding to $\chi^2$ probability of $≥ 0.95$),

🔴 for level 2 error probability $< 0.01\%$ (corresponding to $\chi^2$ probability of $≥ 0.9999$).

"""

# ╔═╡ e1e2eea0-54e2-11eb-070d-4d2716c886b9
md"""
Calculate VaR Time Series?

(Note: it takes ca. 30s on my machine and is updated on any VaR parameter change)
"""

# ╔═╡ d786581e-54e2-11eb-0a84-bdaae4eb3409
@bind calc_var_ts CheckBox(default=true)

# ╔═╡ c359b3b0-54e2-11eb-0fef-8541745a702e
md"""
# Appendix
"""

# ╔═╡ a0cab060-6c7a-11eb-1192-23f77501a715
TableOfContents()

# ╔═╡ a9411200-5421-11eb-3658-437fa0003eea
md"""
## Calculation of time series
"""

# ╔═╡ 0375db60-54c8-11eb-11f2-9769a197f903
md"""
## Market Risk Calculation
"""

# ╔═╡ fd746600-54e5-11eb-0452-433159afbabb
const chi2 = Chisq(1)

# ╔═╡ fd763abe-54e5-11eb-0416-8157f4358dca
function kupiec_prob(outliers, points, confidence_level; one_sided=true)
	p0 = outliers/points
	p = 1-confidence_level
	one_sided && (p0 < p) && return 0.0
	lf = -2*log(
		(p^outliers * (1-p)^(points-outliers))
		/
		(p0^outliers * (1-p0)^(points-outliers)))
	return cdf(chi2, lf)
end

# ╔═╡ fd78d2d0-54e5-11eb-2e68-7d8813b97d19
function get_tl(prob)
	prob < 0.95 && return :green
	prob < 0.9999 && return :yellow
	return :red
end

# ╔═╡ d622400e-51c8-11eb-0bad-4f37eafc03ef
md"""
## Import Market Data
"""

# ╔═╡ 3b057770-51d5-11eb-1ece-17f68ab97550
md"""
### FX Forward Data
"""

# ╔═╡ 2745e320-51c9-11eb-026c-936376a7fe5d
market_data_raw = let
	df = DataFrame(read_table(joinpath(dirname(pathof(MarketRiskPrototype)), "../sample_data/cleansed_data.zip")); copycols=false)
	df[!, :base_currency] = Symbol.(SubString.(df.name, Ref(1:3)))
	df[!, :quote_currency] = Symbol.(SubString.(df.name, Ref(4:6)))
	df[!, :tenor] = Tenor.(df[!, :tenor])
	select(df, [:date, :name, :base_currency, :quote_currency, :tenor, :mid_value])
end

# ╔═╡ e98cd9c0-51d8-11eb-0f47-49fa2b88120d
fx_ccys_per_calculation_days = combine(groupby(market_data_raw, :date), :name => length ∘ unique)

# ╔═╡ 2a02ed00-51d9-11eb-11f2-b1dd74df62ae
fx_days = view(fx_ccys_per_calculation_days.date, fx_ccys_per_calculation_days.name_length_unique .== 8)[:,1]

# ╔═╡ 0b235180-51d5-11eb-2feb-4dd6e60bc4e7
md"""
### Discount Curves
"""

# ╔═╡ 4877d970-51d5-11eb-0f68-ed0fc71dcd9c
discount_data_raw = let
	df = DataFrame(read_table(joinpath(dirname(pathof(MarketRiskPrototype)), "../sample_data/discount_factors_interpolated.zip")); copycols=false)
	df[!, :base_currency] = Symbol.(df.currency)
	df[!, :tenor] = get_tenor.(df[!, :MATURITY_OFFSET])
	rename!(df, Dict(:Date => :date, :VALUE => :mid_value))
	select(df, [:date, :base_currency, :tenor, :mid_value])
end

# ╔═╡ 0781d5e0-51d7-11eb-347d-057f0a4b2c1f
discount_ccys_per_calculation_days = combine(groupby(discount_data_raw, :date), :base_currency => length ∘ unique)

# ╔═╡ fcdef21e-51d7-11eb-0538-497cf87774a9
discount_days = view(discount_ccys_per_calculation_days.date, discount_ccys_per_calculation_days.base_currency_length_unique .== 5)[:,1]

# ╔═╡ dee4a630-51d6-11eb-0439-d1ca6e4acbaa
md"""
#### Data Container
"""

# ╔═╡ 500ae850-51d8-11eb-290d-6dc13c5004a2
analysis_days = fx_days ∩ discount_days # only include days with complete data

# ╔═╡ 60f86520-51c9-11eb-24b0-e12201f8c25b
fx_forward_data = let
	fx_forward_data = FXForwardTimeSeries[]
	for ((base_ccy, quote_ccy), curve_data) in pairs(groupby(market_data_raw, [:base_currency, :quote_currency]))
		dates = Date[]
		curves = Curve[]
		for ((dt, ), curve_per_date) in pairs(groupby(curve_data, :date))
			if dt ∉ analysis_days
				continue
			end
			curve = Curve(curve_per_date.tenor, curve_per_date.mid_value .* Currency(quote_ccy) ./ Currency(base_ccy))
			push!(dates, dt)
			push!(curves, curve)
		end
		fx_forward_time_series = FXForwardTimeSeries(Currency(base_ccy), Currency(quote_ccy), dates, curves)
		push!(fx_forward_data, fx_forward_time_series)
	end
	fx_forward_data
end

# ╔═╡ c829d240-51d5-11eb-0e07-3f5da254bf16
discount_data = let
	discount_data = DiscountTimeSeries[]
	for ((base_ccy, ), curve_data) in pairs(groupby(discount_data_raw, :base_currency))
		dates = Date[]
		curves = Curve[]
		for ((dt, ), curve_per_date) in pairs(groupby(curve_data, :date))
			if dt ∉ analysis_days
				continue
			end
			curve = Curve(curve_per_date.tenor, curve_per_date.mid_value; logy=true)
			push!(dates, dt)
			push!(curves, curve)
		end
		discount_time_series = DiscountTimeSeries(Currency(base_ccy), dates, curves)
		push!(discount_data, discount_time_series)
	end
	discount_data
end

# ╔═╡ e3623f10-51d6-11eb-335f-ef3d47c9897d
market_data_container = FXForwardMarketDataContainer(fx_forward_data, discount_data)

# ╔═╡ 90d7f930-541d-11eb-3e14-e750c274e6b2
spot_rates = get_spot_rates(market_data_container)

# ╔═╡ 7a0e8c30-51e0-11eb-2ce3-85387782af72
all_prices = price_time_series.(all_trades, market_data_container)

# ╔═╡ 5e936750-541f-11eb-05a7-07ceb0979255
all_prices_EUR = [convert.(EUR, x, Ref(values(spot_rates))) for x in all_prices]

# ╔═╡ 4694c8b0-54e2-11eb-2079-5fe8c1e73977
sum_prices = sum(all_prices_EUR)

# ╔═╡ 4703e0a0-51e1-11eb-225c-ebddbe0e887c
begin
	all_prices_without_ccy = [getproperty.(x, :amount) for x ∈ all_prices_EUR]
	plt = plot(analysis_days, all_prices_without_ccy, label=reshape(["trade $i" for i in 1:length(all_trades)], 1, length(all_trades)), ylabel="EUR")
	plot!(plt, analysis_days, getproperty.(sum_prices, :amount), label="total")
	plt
end

# ╔═╡ d6bb2370-54e3-11eb-04c4-3b82ec981bb6
backtesting_pls = sum_prices[time_horizon+1:end] .- lag(sum_prices, time_horizon)[time_horizon+1:end]

# ╔═╡ 1fad78a0-54dd-11eb-088f-c5f3cdb5adc0
scenarios = create_historical_scenarios(market_data_container)

# ╔═╡ 626744e0-54de-11eb-0fa4-e7986b0ae98c
scenario_pls = calculate_scenario_pls.(all_trades, scenarios)

# ╔═╡ 51c23a30-54d6-11eb-1895-b14d3e404c57
market_risk_days = analysis_days[lookback_period+time_horizon+1:end]

# ╔═╡ 36239c10-54d6-11eb-220a-31ecf19a578a
@bind valuation_date Select(string.(market_risk_days), default=string(last(market_risk_days)))

# ╔═╡ c46e4a40-54dd-11eb-2f11-11f08927507e
component_vars = value_at_risk.(all_trades, market_data_container, Date(valuation_date);
	quantile_value=confidence_level, time_horizon=time_horizon, lookback=lookback_period)

# ╔═╡ f2e7ea12-54de-11eb-14af-7fe117d7b403
total_var = value_at_risk(all_trades, market_data_container, spot_rates, Date(valuation_date);
	quantile_value=confidence_level, time_horizon=time_horizon, lookback=lookback_period)

# ╔═╡ f71654b0-54e2-11eb-2a54-85bce080ff76
if calc_var_ts
	var_time_series = fetch.([Threads.@spawn value_at_risk(all_trades, market_data_container, spot_rates, dt; quantile_value=confidence_level, time_horizon=time_horizon, lookback=lookback_period) 
		for dt in market_risk_days])
else
	var_time_series = nothing
end

# ╔═╡ b4579480-54e3-11eb-344f-ed787fa284a7
if var_time_series !== nothing
	plt_var = plot(market_risk_days, getproperty.(var_time_series, :amount), label="VaR")
	plot!(plt_var, analysis_days[time_horizon+1:end], getproperty.(backtesting_pls, :amount), label="Backtesting P&L")
end

# ╔═╡ 456764e0-54e5-11eb-0ce5-bb40c103bb79
if var_time_series !== nothing
	nr_obs = length(market_risk_days)
	backtesting_aligned = backtesting_pls[end-nr_obs+1:end]
	is_outlier = -backtesting_aligned .> var_time_series
	nr_outlier = count(is_outlier)
	kupiec_val = kupiec_prob(nr_outlier, nr_obs, confidence_level; one_sided=true)
	kupiec_tl = get_tl(kupiec_val)
	kupiec_tl_unicode = kupiec_tl == :green ? "🟢" : kupiec_tl == :yellow ? "🟡" : "🔴"
end

# ╔═╡ 5d159982-54e6-11eb-0523-b73e0fc52b41
if calc_var_ts
	md"""
	Number of backtesting data points: $nr_obs
	
	Number of backtesting outliers: $nr_outlier
	
	Kupiec POF test probability: $kupiec_val
	
	Kupiec POF Traffic Light 🚦: $kupiec_tl_unicode
	"""
end

# ╔═╡ cbe7d790-51c8-11eb-1178-f5f8b9c59122
md"""
## Environment Setup
"""

# ╔═╡ Cell order:
# ╟─ac41d630-54e2-11eb-3dde-f374a3e297c7
# ╟─527c6812-51d9-11eb-312a-4f9a773af0e1
# ╟─9ee3b9c3-466c-479f-9beb-0098fad79e0f
# ╠═b8665350-51e0-11eb-13f6-d902368ec2ab
# ╟─99be0f5d-c52e-4d79-9b3d-ea23028f515b
# ╟─bb8a57c0-54e2-11eb-05dd-cb81329ee0c0
# ╟─44035cbd-ced1-4b85-85ef-8b3c4ece03fa
# ╟─4703e0a0-51e1-11eb-225c-ebddbe0e887c
# ╟─3244b430-54d6-11eb-14bc-1357fda1020c
# ╟─09459651-740c-4dae-8fde-86cc8b2359c2
# ╟─8ade16f0-54d5-11eb-3fe9-d334f1578236
# ╟─66ab6d50-54d5-11eb-152a-299a27e573f6
# ╟─a0218290-54d5-11eb-3e54-abf6eb6fb8fd
# ╟─a8cf57a2-54d5-11eb-2679-8f44e902d5d7
# ╟─37e98c9b-9c83-4559-b6c7-caf30b2ecc7d
# ╟─dd6a98d0-54d5-11eb-2151-59ab4f323fa0
# ╟─f010eb60-54d5-11eb-0652-db1e8c3bc560
# ╟─1095cf15-475e-443d-b685-939509de6c4d
# ╟─ac367dd0-54dd-11eb-3124-7961cef8a5c3
# ╟─36239c10-54d6-11eb-220a-31ecf19a578a
# ╟─c46e4a40-54dd-11eb-2f11-11f08927507e
# ╟─f2e7ea12-54de-11eb-14af-7fe117d7b403
# ╟─f1c406b0-54e2-11eb-1522-bf45d8cfae34
# ╟─27cfe650-de9a-4a77-bee9-f92e6eaa7363
# ╟─e1e2eea0-54e2-11eb-070d-4d2716c886b9
# ╟─d786581e-54e2-11eb-0a84-bdaae4eb3409
# ╟─b4579480-54e3-11eb-344f-ed787fa284a7
# ╟─5d159982-54e6-11eb-0523-b73e0fc52b41
# ╟─c359b3b0-54e2-11eb-0fef-8541745a702e
# ╠═a0cab060-6c7a-11eb-1192-23f77501a715
# ╟─a9411200-5421-11eb-3658-437fa0003eea
# ╠═90d7f930-541d-11eb-3e14-e750c274e6b2
# ╠═7a0e8c30-51e0-11eb-2ce3-85387782af72
# ╠═5e936750-541f-11eb-05a7-07ceb0979255
# ╠═4694c8b0-54e2-11eb-2079-5fe8c1e73977
# ╟─0375db60-54c8-11eb-11f2-9769a197f903
# ╠═1fad78a0-54dd-11eb-088f-c5f3cdb5adc0
# ╠═626744e0-54de-11eb-0fa4-e7986b0ae98c
# ╠═d6bb2370-54e3-11eb-04c4-3b82ec981bb6
# ╠═f71654b0-54e2-11eb-2a54-85bce080ff76
# ╠═fd746600-54e5-11eb-0452-433159afbabb
# ╠═fd763abe-54e5-11eb-0416-8157f4358dca
# ╠═fd78d2d0-54e5-11eb-2e68-7d8813b97d19
# ╠═456764e0-54e5-11eb-0ce5-bb40c103bb79
# ╟─d622400e-51c8-11eb-0bad-4f37eafc03ef
# ╟─3b057770-51d5-11eb-1ece-17f68ab97550
# ╠═2745e320-51c9-11eb-026c-936376a7fe5d
# ╠═e98cd9c0-51d8-11eb-0f47-49fa2b88120d
# ╠═2a02ed00-51d9-11eb-11f2-b1dd74df62ae
# ╠═60f86520-51c9-11eb-24b0-e12201f8c25b
# ╟─0b235180-51d5-11eb-2feb-4dd6e60bc4e7
# ╠═4877d970-51d5-11eb-0f68-ed0fc71dcd9c
# ╠═0781d5e0-51d7-11eb-347d-057f0a4b2c1f
# ╠═fcdef21e-51d7-11eb-0538-497cf87774a9
# ╠═c829d240-51d5-11eb-0e07-3f5da254bf16
# ╟─dee4a630-51d6-11eb-0439-d1ca6e4acbaa
# ╠═500ae850-51d8-11eb-290d-6dc13c5004a2
# ╠═e3623f10-51d6-11eb-335f-ef3d47c9897d
# ╠═51c23a30-54d6-11eb-1895-b14d3e404c57
# ╟─cbe7d790-51c8-11eb-1178-f5f8b9c59122
# ╠═214b7040-5424-11eb-20a0-3316520c333e
