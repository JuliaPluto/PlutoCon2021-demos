### A Pluto.jl notebook ###
# v0.14.0

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

# ╔═╡ f42dbad0-9287-11eb-2f3f-cd16aaf26cc9
begin
    import Pkg
    Pkg.activate(mktempdir())
	
    Pkg.add([
        Pkg.PackageSpec(name="Plots", version="1"),
        Pkg.PackageSpec(name="PlutoUI", version="0.7"),
		Pkg.PackageSpec(name="DataFrames", version="0.21.8"),
		Pkg.PackageSpec(name="StatsPlots", version="0.14.5"),
    ])
	
    using Plots, PlutoUI, DataFrames, Dates, StatsPlots
end

# ╔═╡ 3005dbee-9288-11eb-3082-df0ca63d53ac
md"""

![PlutoCon2021](https://github.com/AmitXShukla/AmitXShukla.github.io/raw/master/blogs/PlutoCon/header.png)

"""

# ╔═╡ 90500ec0-928a-11eb-28bc-6b3fc2a55fcd
# enable a floating Table of Contents
TableOfContents(aside=true)

# ╔═╡ 933a8480-928a-11eb-3072-939719abf473
md"""
# Introduction

This Pluto notebook, is meant for ERP consultants, IT Developers, Finance, Supply chain, HR & CRM managers, executive leaders or anyone curious to implement data science concepts in ERP space. 

	Author: Amit Shukla
	Publish Date: Apr 02, 2021
	https://github.com/AmitXShukla
"""

# ╔═╡ 5ef65d32-92fc-11eb-2a87-cf8ff9ad6426
md"""
# About ERP Systems, General Ledger & Supply chain

A typical ERP system consists of many modules based on business domain, functions and operations.
GL is core of Finance and Supply chain domains and Buy to Pay, Order to Cash deal with different aspects of business operations in an Organization.
Many organization, use ERPs in different ways and may chose to implement all or some of the modules.

You can find examples of module specific business operations/processes diagram here.
- [General Ledger process flow](https://github.com/AmitXShukla/AmitXShukla.github.io/raw/master/blogs/PlutoCon/gl.png)
- [Account Payable process flow](https://github.com/AmitXShukla/AmitXShukla.github.io/raw/master/blogs/PlutoCon/ap.png)
- [Tax Analytics](https://github.com/AmitXShukla/AmitXShukla.github.io/raw/master/blogs/PlutoCon/tax.png)
- [Sample GL ERD - Entity Relaton Diagram](https://github.com/AmitXShukla/AmitXShukla.github.io/raw/master/blogs/PlutoCon/gl_erd.png)

A typical ERP modules list looks like below diagram.

"""


# ╔═╡ 8223d700-92a8-11eb-1504-814c1e4b2911
md"""

![PlutoCon2021](https://github.com/AmitXShukla/AmitXShukla.github.io/raw/master/blogs/PlutoCon/ERP_modules.png)

"""

# ╔═╡ 84e30b80-92ff-11eb-2344-2fa561929056
md"""
# Current Solutions
Big Organizations have been using big ERP systems like **SAP, Oracle, PeopleSoft, Coupa, Workday** etc. systems over few decades now and 
Recent popularity of softwares like **Quickbooks, NetSuite, Tally** in medium, small organizations are proof that ERP are the way to manage any business successfully.

Finance analysts, supply chain managers heavily rely on using Business Intelligence tools like **Microsoft Excel, Microsoft Power BI, Tableau, Oracle Analytics, Google Analytics, IBM Cognos, Business Objects** etc. 

These BI tools provide a self-service reporting for analytics and often are used for managing daily ad-hoc reporting and anlysis.

"""

# ╔═╡ 90e8d340-9301-11eb-1eac-391a3f4d92f9
md"""
# Problem Statement

*"Read, Write and Understand"* data are three aspects of any ERP system.
While big and small ERPs master "write aspect" of ERP, there is lot needs to be done on "read & understand" data.

I would rather not waste your time talking about how one BI Tools compare with Pluto  or others, 

instead, in this notebook,
I will show some sample reports I built in Pluto last year for Pandemic reporting, and then let Analysts decide, if They would have rather used Traditional BI reportings tools to build these reports.

Point is, How easily, Pluto can create real time ad-hoc, *Reactive* dashboard analytics to support critical business operations.

"""

# ╔═╡ 64e46740-9302-11eb-0401-5b8ba684cc55
md"""
# understanding Finance, Supply chain data

A typical Finance statement look like this.
[click here](https://s2.q4cdn.com/470004039/files/doc_financials/2020/q4/FY20_Q4_Consolidated_Financial_Statements.pdf)

below are sample data sets,

Accounts, Dept (or Cost Center), Location, and Finance Ledger may look like

## Accounts Dimension
"""

# ╔═╡ 70af8b40-285f-4711-909c-32295d70225b
begin
	# create dummy data
	accounts = DataFrame(AS_OF_DATE=Date("1900-01-01", dateformat"y-m-d"), 
							ID = 11000:1000:45000,
							CLASSIFICATION=repeat([
	"OPERATING_EXPENSES","NON-OPERATING_EXPENSES", "ASSETS","LIABILITIES","NET_WORTH","STATISTICS","REVENUE"
	], inner=5),
							CATEGORY=[
	"Travel","Payroll","non-Payroll","Allowance","Cash",
	"Facility","Supply","Services","Investment","Misc.",
	"Depreciation","Gain","Service","Retired","Fault.",
	"Receipt","Accrual","Return","Credit","ROI",
	"Cash","Funds","Invest","Transfer","Roll-over",
	"FTE","Members","Non_Members","Temp","Contractors",
	"Sales","Merchant","Service","Consulting","Subscriptions"
	],
							STATUS="A",
							DESCR=repeat([
	"operating expenses","non-operating expenses","assets","liability","net-worth","stats","revenue"
	], inner=5),
							ACCOUNT_TYPE=repeat([
	"E","E","A","L","N","S","R"
				],inner=5));
	accounts[collect(1:5:35),:]
end

# ╔═╡ ff47dbbc-5340-4fa0-98bb-451e474c3b9f
accounts_size = size(accounts)

# ╔═╡ cfbd59b6-032b-4e35-b8cb-4ac1aaa17975
md"""
## Department Dimension
"""

# ╔═╡ 083eca79-c563-408d-b36b-afc9ccdd0698
begin
	# create dummy data
	dept = DataFrame(AS_OF_DATE=Date("2000-01-01", dateformat"y-m-d"), 
							ID = 1100:100:1500,
							CLASSIFICATION=[
	"SALES","HR", "IT","BUSINESS","OTHERS"
	],
							CATEGORY=[
	"sales","human_resource","IT_Staff","business","others"
	],
							STATUS="A",
							DESCR=[
	"Sales & Marketing","Human Resource","Infomration Technology","Business leaders","other temp"
	],
							DEPT_TYPE=[
	"S","H","I","B","O"]);
	dept[collect(1:5),:]
end

# ╔═╡ 038b0d45-4579-4ab3-a255-14b0ef3410c7
dept_size = size(dept)

# ╔═╡ efe901a0-32a0-4d2a-a69d-d74d77a13932
md"""
## Location Dimension
"""

# ╔═╡ db0437c3-115f-4ca7-8f83-0b7c5d2cec77
begin
	# create dummy data
	location = DataFrame(AS_OF_DATE=Date("2000-01-01", dateformat"y-m-d"), 
							ID = 11:1:22,
							CLASSIFICATION=repeat([
	"Region A","Region B", "Region C"], inner=4),
							CATEGORY=repeat([
	"Region A","Region B", "Region C"], inner=4),
							STATUS="A",
							DESCR=[
"Boston","New York","Philadelphia","Cleveland","Richmond",
"Atlanta","Chicago","St. Louis","Minneapolis","Kansas City",
"Dallas","San Francisco"],
							LOCA_TYPE="Physical");
	location[:,:]
end

# ╔═╡ a806795e-8832-49ce-b5dd-199a3d6fb34d
location_size = size(location)

# ╔═╡ 735b4965-ac21-4c98-b22b-623ff6583346
md"""
## Dimesions visuals
"""

# ╔═╡ d1a0c9fd-788b-46c9-8968-8b067af85386
begin
	p1 = plot((combine(groupby(accounts, :CLASSIFICATION), nrow)).nrow,(combine(groupby(accounts, :CLASSIFICATION), nrow)).CLASSIFICATION, seriestype=scatter, label = "# of accounts by classification", xlabel = "# of accounts", ylabel="Class", xlims = (0, 5.5))
	p2 = plot((combine(groupby(dept, :CLASSIFICATION), nrow)).nrow,(combine(groupby(dept, :CLASSIFICATION), nrow)).CLASSIFICATION, seriestype=scatter, label = "# of dept by classification", xlabel = "# of depts", ylabel="Class", xlims = (0, 2))
	p3 = plot((combine(groupby(accounts, :CLASSIFICATION), nrow)).nrow,(combine(groupby(location, :CLASSIFICATION), nrow)).CLASSIFICATION, seriestype=scatter, label = "# of locations by classification", xlabel = "# of locations", ylabel="Class", xlims = (1, 6.5))
plot(p1, p2, p3, layout = (3, 1), legend = false)
end

# ╔═╡ d7fdb537-2d74-407c-a62b-5caaea9f85c4
md"""
# Using Pluto for Finance & SCM analytics
"""

# ╔═╡ 0b928414-0480-48c7-b1e0-2998e56d82cb
md"""
## Finance Ledger 

below is sample Finance Ledger Data
"""

# ╔═╡ f9627390-4af5-4b38-86ad-caf5d87eaae2
begin
	ledger = DataFrame(
		LEDGER = String[], FISCAL_YEAR = Int[], PERIOD = Int[], ORGID = String[],
		OPER_UNIT = String[], ACCOUNT = Int[], DEPT = Int[], LOCATION = Int[], 	
		POSTED_TOTAL = Float64[]
	);
	# create 2020 Period 1-12 Actuals Ledger 
	l = "Actuals";
	fy = 2020;
	for p = 1:12
		for i = 1:10^5
		push!(ledger, (l, fy, p, "ABC Inc.", rand(location.CATEGORY),
			rand(accounts.ID), rand(dept.ID), rand(location.ID), rand()*10^8))
		end
	end
	# create 2021 Period 1-4 Actuals Ledger 
	l = "Actuals";
	fy = 2021;
	for p = 1:4
		for i = 1:10^5
		push!(ledger, (l, fy, p, "ABC Inc.", rand(location.CATEGORY),
			rand(accounts.ID), rand(dept.ID), rand(location.ID), rand()*10^8))
		end
	end
	# create 2021 Period 1-4 Budget Ledger 
	l = "Budget";
	fy = 2021;
	for p = 1:12
		for i = 1:10^5
		push!(ledger, (l, fy, p, "ABC Inc.", rand(location.CATEGORY),
			rand(accounts.ID), rand(dept.ID), rand(location.ID), rand()*10^8))
		end
	end
	ledger[:,:]
end

# ╔═╡ 5519e7cc-e225-4922-a2bf-43233bf61194
ledger_size = size(ledger)

# ╔═╡ 7d852828-b451-46c7-a387-c17d5830d004
md"""
## GL BalanceSheet, IncomeStatement & CashFlow
"""

# ╔═╡ 7b3fd42d-fb57-4617-81b7-1e2f46f61bb1
begin
# rename dimensions columns for innerjoin
df_accounts = rename(accounts, :ID => :ACCOUNTS_ID, :CLASSIFICATION => :ACCOUNTS_CLASSIFICATION, :CATEGORY => :ACCOUNTS_CATEGORY, :DESCR => :ACCOUNTS_DESCR);
df_dept = rename(dept, :ID => :DEPT_ID, :CLASSIFICATION => :DEPT_CLASSIFICATION, :CATEGORY => :DEPT_CATEGORY, :DESCR => :DEPT_DESCR);
df_location = rename(location, :ID => :LOCATION_ID, :CLASSIFICATION => :LOCATION_CLASSIFICATION, :CATEGORY => :LOCATION_CATEGORY, :DESCR => :LOCATION_DESCR);
df_dimensions_size = ("df_dimensions_size", size(df_accounts),size(df_dept),size(df_location))
end

# ╔═╡ 1e1e554c-16ae-4015-80c2-5e1e4467ff52
begin
	# join ledger with dimensions, create Qtr -Period column
	# there must be a smarter way of doing this,
	# below code must be refactored, it's for demo purpose only
	# not using memory efficiently
	function periodToQtr(x)
	if x ∈ 1:3
		return 1
	elseif x ∈ 4:6
		return 2
	elseif x ∈ 7:9
		return 3
	else return 4
	end
	end
	df_ledger = innerjoin(
		innerjoin(
			innerjoin(ledger, df_accounts, on = [:ACCOUNT => :ACCOUNTS_ID], makeunique=true),
			df_dept, on = [:DEPT => :DEPT_ID], makeunique=true), df_location,
	on = [:LOCATION => :LOCATION_ID], makeunique=true);
	transform!(df_ledger, :PERIOD => ByRow(periodToQtr) => :QTR)
	("df_ledger_size", size(df_ledger))
end

# ╔═╡ 0948024b-032e-4fd5-9658-2fd54ac2afe7
md"""
## Balance Sheet
"""

# ╔═╡ 0c864763-d6ca-497b-bdd4-beeda515f052
@bind ld Select(["Actuals", "Budget"])

# ╔═╡ 6c9e948f-69fa-444f-8ca9-ad250a6aebee
@bind rg Select(["Region A", "Region B", "Region C"])

# ╔═╡ f36d01e6-f934-40b7-b3a7-ab550498e072
@bind yr Slider(2020:1:2021, default=2020, show_value=true)

# ╔═╡ 9502cbd8-9e8f-4960-9ed1-0fe93f730d93
@bind qtr Slider(1:1:4, default=1, show_value=true)

# ╔═╡ f375290d-0192-4f67-8431-60be59e552f3
begin
	function numToCurrency(x)
		return string("USD ",round(x/10^6; digits = 2), "m")
	end
	gdf = groupby(df_ledger, [:LEDGER, :FISCAL_YEAR, :QTR, :OPER_UNIT, :ACCOUNTS_CLASSIFICATION, :DEPT_CLASSIFICATION, 
			# :LOCATION_CLASSIFICATION,
			:LOCATION_DESCR]);
	gdf_plot = combine(gdf, :POSTED_TOTAL => sum => :TOTAL);

	select(gdf_plot[(
				(gdf_plot.FISCAL_YEAR .== yr)
				.&
				(gdf_plot.QTR .== qtr)
				.&
				(gdf_plot.LEDGER .== ld)
				.&
				(gdf_plot.OPER_UNIT .== rg)
				),:], 
		:FISCAL_YEAR => :FY,
		:QTR => :Qtr,
		:OPER_UNIT => :Org,
		:ACCOUNTS_CLASSIFICATION => :Accounts,
		:DEPT_CLASSIFICATION => :Dept,
		# :LOCATION_CLASSIFICATION => :Region,
		:LOCATION_DESCR => :Loc,
		:TOTAL => ByRow(numToCurrency) => :TOTAL)
end

# ╔═╡ 9e118707-6854-49bb-a41c-925726834796
md"""
## Income Statement
"""

# ╔═╡ 6349c272-ef08-4f83-9cd6-2acbd3bfc8ab
	select(gdf_plot[(
				(gdf_plot.FISCAL_YEAR .== yr)
				.&
				(gdf_plot.QTR .== qtr)
				.&
				(gdf_plot.LEDGER .== ld)
				.&
				(gdf_plot.OPER_UNIT .== rg)
				.&
				(in.(gdf_plot.ACCOUNTS_CLASSIFICATION, Ref(["ASSETS", "LIABILITIES", "REVENUE","NET_WORTH"])))
				),:], 
		:FISCAL_YEAR => :FY,
		:QTR => :Qtr,
		:OPER_UNIT => :Org,
		:ACCOUNTS_CLASSIFICATION => :Accounts,
		# :DEPT_CLASSIFICATION => :Dept,
		# :LOCATION_CLASSIFICATION => :Region,
		# :LOCATION_DESCR => :Loc,
		:TOTAL => ByRow(numToCurrency) => :TOTAL)

# ╔═╡ f6890d42-636d-40f6-bffa-518ef016f0d9
md"""
## Cash Flow Statement
"""

# ╔═╡ bd6e6148-4317-4856-a612-a8a9ce24b4e9
	select(gdf_plot[(
				(gdf_plot.FISCAL_YEAR .== yr)
				.&
				(gdf_plot.QTR .== qtr)
				.&
				(gdf_plot.LEDGER .== ld)
				.&
				(gdf_plot.OPER_UNIT .== rg)
				.&
				(in.(gdf_plot.ACCOUNTS_CLASSIFICATION, Ref(["NON-OPERATING_EXPENSES","OPERATING_EXPENSES"	])))
				),:], 
		:FISCAL_YEAR => :FY,
		:QTR => :Qtr,
		:OPER_UNIT => :Org,
		:ACCOUNTS_CLASSIFICATION => :Accounts,
		# :DEPT_CLASSIFICATION => :Dept,
		# :LOCATION_CLASSIFICATION => :Region,
		# :LOCATION_DESCR => :Loc,
		:TOTAL => ByRow(numToCurrency) => :TOTAL)

# ╔═╡ 5f0d4b1b-09e7-4913-91e3-28d3c2b9dbe1
md"""
## Ledger Visual
"""

# ╔═╡ 4e16f723-6c84-49c9-ad64-8f7b81bcc568
@bind ld_p Select(["Actuals", "Budget"])

# ╔═╡ c57d4b85-f157-43e7-85b6-d10af1c9cc9c
@bind yr_p Slider(2020:1:2021, default=2021, show_value=true)

# ╔═╡ 97d23b1b-927a-471c-9e0c-9eafead92167
@bind rg_p Select(["Region A", "Region B", "Region C"])

# ╔═╡ a431b45c-209d-4b31-ab03-e762958b095d
@bind ldescr Select(unique(location.DESCR))

# ╔═╡ 95302cab-0f88-4b93-88b8-47ce4af894fb
@bind adescr Select(unique(accounts.CLASSIFICATION))

# ╔═╡ 7d9b6029-e502-4065-9fa2-ef8f4da39021
@bind ddescr Select(unique(dept.CLASSIFICATION))

# ╔═╡ 90408ebd-ce89-48eb-ba66-5e56db44b8a2
begin
	plot_data = gdf_plot[(
		(gdf_plot.FISCAL_YEAR .== yr_p)
		.&
		(gdf_plot.LEDGER .== ld_p)
		.&
		(gdf_plot.OPER_UNIT .== rg_p)
		.&
		(gdf_plot.LOCATION_DESCR .== ldescr)
		.&
		(gdf_plot.DEPT_CLASSIFICATION .== ddescr)
		.&
		(gdf_plot.ACCOUNTS_CLASSIFICATION .== adescr))
		, :];
	# @df plot_data scatter(:QTR, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", label="$ld_p Total by $yr_p for $rg_p")
	@df plot_data plot(:QTR, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", 
		label=[
			"$ld_p by $yr_p for $rg_p $ldescr $adescr $ddescr"
			],
		lw=3)
end

# ╔═╡ 90049f35-f30b-4101-a8cf-1bd17f217998
md"""
## Actuals vs Budget comparison
"""

# ╔═╡ 9c220649-67e7-4adc-b1b6-be2feabe2313
begin
	plot_data_a = gdf_plot[(
		(gdf_plot.FISCAL_YEAR .== yr_p)
		.&
		(gdf_plot.LEDGER .== "Actuals")
		.&
		(gdf_plot.OPER_UNIT .== rg_p)
		.&
		(gdf_plot.LOCATION_DESCR .== ldescr)
		.&
		(gdf_plot.DEPT_CLASSIFICATION .== ddescr)
		.&
		(gdf_plot.ACCOUNTS_CLASSIFICATION .== adescr))
		, :];
	# @df plot_data scatter(:QTR, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", label="$ld_p Total by $yr_p for $rg_p")
	plot_data_b = gdf_plot[(
		(gdf_plot.FISCAL_YEAR .== yr_p)
		.&
		(gdf_plot.LEDGER .== "Budget")
		.&
		(gdf_plot.OPER_UNIT .== rg_p)
		.&
		(gdf_plot.LOCATION_DESCR .== ldescr)
		.&
		(gdf_plot.DEPT_CLASSIFICATION .== ddescr)
		.&
		(gdf_plot.ACCOUNTS_CLASSIFICATION .== adescr))
		, :];
	# @df plot_data scatter(:QTR, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", label="$ld_p Total by $yr_p for $rg_p")
	@df plot_data_a plot(:QTR, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", 
		label=[
			"Actuals by $yr_p for $rg_p $ldescr $adescr $ddescr"
			],
		lw=3)
	@df plot_data_b plot!(:QTR, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", 
		label=[
			"Budget by $yr_p for $rg_p $ldescr $adescr $ddescr"
			],
		lw=3)
end

# ╔═╡ bea7c89e-78ca-4a68-8487-f10f91ee6449
md"""
raw data in table format
"""

# ╔═╡ 3f6f4feb-3425-4f89-814d-4ebb7334d6c6
plot_data

# ╔═╡ b370f5c2-c6cc-4f2c-9d68-98a0dab6db3b
begin
	# plot_data = gdf_plot[(
	# 	(gdf_plot.FISCAL_YEAR .== yr_p)
	# 	.&
	# 	(gdf_plot.LEDGER .== ld_p)
	# 	.&
	# 	(gdf_plot.OPER_UNIT .== rg_p)
	# 	.&
	# 	(gdf_plot.LOCATION_DESCR .== ldescr)
	# 	.&
	# 	(gdf_plot.DEPT_CLASSIFICATION .== ddescr)
	# 	.&
	# 	(gdf_plot.ACCOUNTS_CLASSIFICATION .== adescr))
	# 	, :];
	# @df plot_data scatter(:QTR, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", label="$ld_p Total by $yr_p for $rg_p")
	# @df gdf_plot plot(:QTR, :ACCOUNTS_CLASSIFICATION, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", 
	# 	label=[
	# 		"$ld_p by $yr_p for $rg_p $ldescr $adescr $ddescr"
	# 		],
	# 	lw=3)
	@df gdf_plot scatter(:QTR, :ACCOUNTS_CLASSIFICATION, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", 
		label=[
			"$ld_p by $yr_p for $rg_p $ldescr for $ddescr"
			],
		lw=3)
end

# ╔═╡ 9313e997-cead-48e0-aac9-784708c4221c
begin
	# plot_data = gdf_plot[(
	# 	(gdf_plot.FISCAL_YEAR .== yr_p)
	# 	.&
	# 	(gdf_plot.LEDGER .== ld_p)
	# 	.&
	# 	(gdf_plot.OPER_UNIT .== rg_p)
	# 	.&
	# 	(gdf_plot.LOCATION_DESCR .== ldescr)
	# 	.&
	# 	(gdf_plot.DEPT_CLASSIFICATION .== ddescr)
	# 	.&
	# 	(gdf_plot.ACCOUNTS_CLASSIFICATION .== adescr))
	# 	, :];
	# @df plot_data scatter(:QTR, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", label="$ld_p Total by $yr_p for $rg_p")
	# @df gdf_plot plot(:QTR, :ACCOUNTS_CLASSIFICATION, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", 
	# 	label=[
	# 		"$ld_p by $yr_p for $rg_p $ldescr $adescr $ddescr"
	# 		],
	# 	lw=3)
	@df gdf_plot scatter(:QTR, :DEPT_CLASSIFICATION, :TOTAL/10^8, title = "Finance Ledger Data", xlabel="Quarter", ylabel="Total (in USD million)", 
		label=[
			"$ld_p by $yr_p for $rg_p $ldescr for $adescr"
			],
		lw=3)
end

# ╔═╡ 5bd9fabf-52c6-4d5b-a871-74791237f5f4
md"""
## what-if, would, could, should
	Region A is merged with Region B
	Employee resume work from office, how much Travel amounts % will increase.
	% of Office supply expenses given to Employee as home office setup

	would Region A, Cash Flow Investment have returned 7% ROI
	would Region B received Government/investor funding

	could have increased IT operating expenses by 5%
	could have reduced HR temp staff
	
	should have paid vendor invoiced on time to recive rebate
	should have applied loan to increase production
	should have retired a particular Asset
"""

# ╔═╡ 60ce8d4c-433d-4ce0-918b-7b8512749fb3
md"""
## Real-time TimeSeries, StatsModel predictions

	Predict Operating and non-operating expense for year
	Predict Actuals to Budget variance and FORECAST
	using SARIMA model to predict "Region A" NET-WORTH

"""

# ╔═╡ c93c46dc-1b18-43fc-babe-d8bc81c38d5c
md"""
# Supply chain Dashboard - live inventory

	below is an example dashboard (image) built in Pluto
	This dashboard uses OnlineStats.jl for "real-time" udpates

![Supply Chain Dashboard](https://github.com/AmitXShukla/AmitXShukla.github.io/raw/master/blogs/PlutoCon/scm.png)

"""

# ╔═╡ 54d6e2f5-7c62-4af1-b6e5-f313e16e2cb6
md"""
# Feature Requests

Pluto as an Enterprise Reproting tool.

Pluto provides a cohesive real-time, reactive data wrangling, tranformation, reporting & analytics framework for big data /ERP data sets.

	Cloud/on-Premise Server deployment
	PIN - live KPI Reports like TOC (Floating fluid content)
	Integarete pluto with BI tools like Microsoft Power BI, Tableau etc.
	Drill-through, Drill-down functionalities
	linking variables for easy navigation

"""

# ╔═╡ 1af26a9b-9936-447e-93b0-ed044e0eee96
md"""
## contact information
	contact: amit@elishconsulting.com
	https://github.com/AmitXShukla

"""

# ╔═╡ Cell order:
# ╟─3005dbee-9288-11eb-3082-df0ca63d53ac
# ╟─f42dbad0-9287-11eb-2f3f-cd16aaf26cc9
# ╟─90500ec0-928a-11eb-28bc-6b3fc2a55fcd
# ╟─933a8480-928a-11eb-3072-939719abf473
# ╟─5ef65d32-92fc-11eb-2a87-cf8ff9ad6426
# ╟─8223d700-92a8-11eb-1504-814c1e4b2911
# ╟─84e30b80-92ff-11eb-2344-2fa561929056
# ╟─90e8d340-9301-11eb-1eac-391a3f4d92f9
# ╟─64e46740-9302-11eb-0401-5b8ba684cc55
# ╟─70af8b40-285f-4711-909c-32295d70225b
# ╟─ff47dbbc-5340-4fa0-98bb-451e474c3b9f
# ╟─cfbd59b6-032b-4e35-b8cb-4ac1aaa17975
# ╟─083eca79-c563-408d-b36b-afc9ccdd0698
# ╟─038b0d45-4579-4ab3-a255-14b0ef3410c7
# ╟─efe901a0-32a0-4d2a-a69d-d74d77a13932
# ╟─db0437c3-115f-4ca7-8f83-0b7c5d2cec77
# ╟─a806795e-8832-49ce-b5dd-199a3d6fb34d
# ╟─735b4965-ac21-4c98-b22b-623ff6583346
# ╟─d1a0c9fd-788b-46c9-8968-8b067af85386
# ╟─d7fdb537-2d74-407c-a62b-5caaea9f85c4
# ╟─0b928414-0480-48c7-b1e0-2998e56d82cb
# ╟─f9627390-4af5-4b38-86ad-caf5d87eaae2
# ╟─5519e7cc-e225-4922-a2bf-43233bf61194
# ╟─7d852828-b451-46c7-a387-c17d5830d004
# ╟─7b3fd42d-fb57-4617-81b7-1e2f46f61bb1
# ╟─1e1e554c-16ae-4015-80c2-5e1e4467ff52
# ╟─0948024b-032e-4fd5-9658-2fd54ac2afe7
# ╟─0c864763-d6ca-497b-bdd4-beeda515f052
# ╟─6c9e948f-69fa-444f-8ca9-ad250a6aebee
# ╟─f36d01e6-f934-40b7-b3a7-ab550498e072
# ╟─9502cbd8-9e8f-4960-9ed1-0fe93f730d93
# ╟─f375290d-0192-4f67-8431-60be59e552f3
# ╟─9e118707-6854-49bb-a41c-925726834796
# ╟─6349c272-ef08-4f83-9cd6-2acbd3bfc8ab
# ╟─f6890d42-636d-40f6-bffa-518ef016f0d9
# ╟─bd6e6148-4317-4856-a612-a8a9ce24b4e9
# ╟─5f0d4b1b-09e7-4913-91e3-28d3c2b9dbe1
# ╟─4e16f723-6c84-49c9-ad64-8f7b81bcc568
# ╟─c57d4b85-f157-43e7-85b6-d10af1c9cc9c
# ╟─97d23b1b-927a-471c-9e0c-9eafead92167
# ╟─a431b45c-209d-4b31-ab03-e762958b095d
# ╟─95302cab-0f88-4b93-88b8-47ce4af894fb
# ╟─7d9b6029-e502-4065-9fa2-ef8f4da39021
# ╟─90408ebd-ce89-48eb-ba66-5e56db44b8a2
# ╟─90049f35-f30b-4101-a8cf-1bd17f217998
# ╟─9c220649-67e7-4adc-b1b6-be2feabe2313
# ╟─bea7c89e-78ca-4a68-8487-f10f91ee6449
# ╟─3f6f4feb-3425-4f89-814d-4ebb7334d6c6
# ╟─b370f5c2-c6cc-4f2c-9d68-98a0dab6db3b
# ╟─9313e997-cead-48e0-aac9-784708c4221c
# ╟─5bd9fabf-52c6-4d5b-a871-74791237f5f4
# ╟─60ce8d4c-433d-4ce0-918b-7b8512749fb3
# ╟─c93c46dc-1b18-43fc-babe-d8bc81c38d5c
# ╟─54d6e2f5-7c62-4af1-b6e5-f313e16e2cb6
# ╟─1af26a9b-9936-447e-93b0-ed044e0eee96
