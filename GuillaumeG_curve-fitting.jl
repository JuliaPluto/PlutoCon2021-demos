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

# ╔═╡ 393b2f5e-6556-11eb-2119-cf7309ee7392
begin
    import Pkg
    # Activate a clean environment.
    Pkg.activate(mktempdir())
	# Install required packages.
    Pkg.add([
			Pkg.PackageSpec(name="Chain"),
			Pkg.PackageSpec(name="CSV"),
			Pkg.PackageSpec(name="DataFrames"),
			Pkg.PackageSpec(name="HTTP"),
			Pkg.PackageSpec(name="LsqFit"),
			Pkg.PackageSpec(name="Measurements"),
        	Pkg.PackageSpec(name="Plots"),
        	Pkg.PackageSpec(name="PlutoUI"),
			Pkg.PackageSpec(name="Statistics"),
			Pkg.PackageSpec(name="URIs")
			])

	# Load required packages.
    using Chain
	using CSV
	using DataFrames
	using HTTP
	using LsqFit
	using Measurements
	using Plots
	using PlutoUI
	using Statistics
	using URIs
end

# ╔═╡ 412eedac-658a-11eb-2326-93e5bf3d1a2c
md"""
# Fitting of equilibrium binding data

This notebook plots an equilibrium binding dataset (with error bars, for datasets containing replicates) and performs non-linear curve fitting of a model to the data.

The following reference explains very well the theory of equilibrium binding experiments, as well as many important practical considerations:

> Jarmoskaite I, AlSadhan I, Vaidyanathan PP & Herschlag D (2020) How to measure and evaluate binding affinities. *eLife* **9**: e57264 <https://doi.org/10.7554/eLife.57264>

Example datasets are from the following publication:

> Gaullier G, Roberts G, Muthurajan UM, Bowerman S, Rudolph J, Mahadevan J, Jha A, Rae PS & Luger K (2020) Bridging of nucleosome-proximal DNA double-strand breaks by PARP2 enhances its interaction with HPF1. *PLOS ONE* **15**: e0240932 <https://doi.org/10.1371/journal.pone.0240932>

The original files are freely available from <https://doi.org/10.5281/zenodo.3519435> (CC-BY 4.0). They are also available reformatted for compatibility with this notebook in this repository: <https://github.com/Guillawme/julia-curve-fitting/tree/main/datasets>

"""

# ╔═╡ 270cc0cc-660f-11eb-241e-b75746a39cc7
md"""
## Load data

The data file must be in CSV format. The first row is assumed to contain column names. The first column is assumed to be the $X$ values, all other columns are assumed to be replicate $Y$ values that will be averaged (fitting will be done against the mean values, weighted by their standard deviations). In addition, there must not be any row with an $X = 0$ value (this would result in an error when attempting to plot with a logarithmic scale). I always perform two measurements at $X = 0$, and I always sort rows by descending $X$ values, so this notebook automatically skips the last two rows of the CSV file; adjust accordingly if you don't measure at $X = 0$ and want to keep all rows (see section [Data processing](#1884912a-6aeb-11eb-2b4a-d14d4a321dc5) below). The data does *not* need to be scaled such that $Y$ takes values between $0$ and $1$: the binding models can account for arbitrary minimum and maximum $Y$ values (see section [Model functions](#663a4cae-658a-11eb-382f-cf256c08c9d1) below). Scaling data will hide differences in signal change between datasets, while these differences may tell you something about the system under study, so scaling should never be done "blindly"; always look at the raw data.

Indicate below which data files to process:

- if the path given is not absolute, it is assumed to be relative to the notebook file (wherever the notebook is located)
- a list of files can be provided with one file path per line and separated by commas
- files can be located by local path or URL, but each type of location should be in the dedicated list
"""

# ╔═╡ a2c02fcf-9402-4938-bc3d-819b45a66afa
dataURLs = [
	"https://raw.githubusercontent.com/Guillawme/julia-curve-fitting/main/datasets/dataset_003.csv",
	"https://raw.githubusercontent.com/Guillawme/julia-curve-fitting/main/datasets/dataset_005.csv"
]

# ╔═╡ 14baf100-660f-11eb-1380-ebf4a860eed8
dataFiles = [
	#"datasets/dataset_003.csv",
	#"datasets/dataset_005.csv"
]

# ╔═╡ 2ce72e97-0133-4f15-bf1d-7fd04ccf3102
md"""
**Number of rows to ignore at the end of files:** $(@bind footerRows PlutoUI.NumberField(0:30, default = 2))
"""

# ╔═╡ 214acce6-6ae8-11eb-3abf-492e50140317
md"""
Your data should appear below shortly, check that it looks normal. In addition to the columns present in your CSV file, you should see three columns named `mean`, `std` and `measurement` (these values will be used for fitting and plotting).
"""

# ╔═╡ d5b0e2a1-865c-489c-9d0d-c4ae043828fb
# By defaults, use file names and URLs to identify datasets.
datasetNames = vcat(dataURLs, dataFiles)
# But one can also use custom names.
#datasetNames = ["Monday", "Tuesday", "Wednesday", "Thursday"]

# ╔═╡ 5c5e0392-658a-11eb-35be-3d940d4504cb
md"""
## Visualizations

Your data and fit should appear below shortly. Take a good look at the [data and fit](#3dd72c58-6b2c-11eb-210f-0b547bf38ebe), make sure you check the [residuals](#4f4000b4-6b2c-11eb-015f-d76a0adda0a0). Once you're happy with it, check the [numerical results](#be17b97e-663a-11eb-2158-a381c19ece3f).
"""

# ╔═╡ 3dd72c58-6b2c-11eb-210f-0b547bf38ebe
md"""
### Data and fit

Select binding model:
"""

# ╔═╡ 3da83f72-6a11-11eb-1a74-49b66eb39c96
@bind chosenModel PlutoUI.Radio(
	[
		"Hill" => :Hill,
		"Hyperbolic" => :Hyperbolic,
		"Quadratic" => :Quadratic
	],
	default = "Hill"
)

# ╔═╡ d15cba72-6aeb-11eb-2c80-65702b48e859
md"""
Show fit line with initial parameters?
$@bind showInitialFit PlutoUI.CheckBox(default = false)
"""

# ╔═╡ 01b59d8a-6637-11eb-0da0-8d3e314e23af
md"""
For the quadratic model, indicate receptor concentration (the receptor is the binding partner kept at constant, low concentration across the titration series).
Parameter $R_0 =$
$@bind R0 PlutoUI.Slider(0.01:0.1:500.0, default = 5.0, show_value = true)
"""

# ╔═╡ 4f4000b4-6b2c-11eb-015f-d76a0adda0a0
md"""
### Residuals
"""

# ╔═╡ c50cf18c-6b11-11eb-07d3-0b8e332ec5bc
md"""
The fit residuals should follow a random normal distribution around $0$. If they show a systematic trend, it means the fit systematically deviates from your data, and therefore the model you chose might not be justified (but be careful when considering alternative models: introducing more free parameters will likely get the fit line closer to the data points and yield a lower [sum of squared residuals](#124c4f94-6b99-11eb-2921-d7c2cd00b893), but this is not helpful if these additional parameters don't contribute to explaining the physical phenomenon being modeled). Another possibility is a problem with your data. The most common problems are:

- the data does not cover the proper concentration range
- the concentration of receptor is too high relative to the $K_D$

In either case, your best option is to design a new experiment and collect new data.
"""

# ╔═╡ 5a36fc3f-ce74-42c8-8284-19321e0d687f
md"""
#### Scatter plot
"""

# ╔═╡ 5392d99b-70f9-48cd-90b4-58cba5fc9681
md"""
#### Histogram
"""

# ╔═╡ be17b97e-663a-11eb-2158-a381c19ece3f
md"""
## Numerical results

### Model parameters
"""

# ╔═╡ 124c4f94-6b99-11eb-2921-d7c2cd00b893
md"""
### Sum of squared residuals
"""

# ╔═╡ 7e7a9dc4-6ae8-11eb-128d-83544f01b78b
md"""
## Code

The code doing the actual work is in this section. Do not edit unless you know what you are doing.
"""

# ╔═╡ 512e3028-6ae9-11eb-31b4-1bc9fc66b322
md"### Necessary packages and notebook setup"

# ╔═╡ abc03f64-6a11-11eb-0319-ed7cea455cb5
PlutoUI.TableOfContents()

# ╔═╡ 1884912a-6aeb-11eb-2b4a-d14d4a321dc5
md"### Data processing"

# ╔═╡ 4f4b580d-507c-4ad0-b1d5-5967c8ed829e
md"""
The `commonProcessing()` function computes the mean and standard deviation of replicates, defines measurements as mean ± std, and returns a DataFrame containing all the data. It is used by all methods of the following `processData()` function, which handle various inputs (path to a local file, URL to a remote file, loaded CSV file, loaded DataFrame).
"""

# ╔═╡ 5eb607c7-172b-4a6c-a815-acbc195108f0
function commonProcessing(data::DataFrame)
	df = @chain data begin
		# Rename column 1, so we can always call it by the
		# same name regardless of its name in the input file.
		rename(1 => :concentration)
		@aside cols = ncol(_)
		transform(
			# Calculate mean and stddev of replicates
			# (all columns in input except first one).
			AsTable(2:cols) => ByRow(mean) => :mean,
			AsTable(2:cols) => ByRow(std) => :std
		)
		transform(
			# Mean and stddev together define a measurement
			# (this is only for plotting; fitting uses the two
			# original columns separately).
			[:mean, :std] => ByRow(measurement) => :measurement
		)
	end
	return df
end

# ╔═╡ 992c86a2-6b13-11eb-1e00-95bdff2736d0
md"""
The `processData()` function loads one data file, computes the mean and standard deviation of replicates, defines measurements as mean ± std, and returns a DataFrame containing all the data.
"""

# ╔═╡ 1fe4d112-6a11-11eb-37a6-bf95fbe032b1
function processData(dataFile::String)
	df = @chain dataFile begin
		CSV.File(footerskip=footerRows)
		DataFrame()
		commonProcessing()
	end
	return df
end

# ╔═╡ 5cc812af-4f8e-444b-9652-fb063cc6be06
md"""
This functions should also work if passed an URL to a remote file:
"""

# ╔═╡ 7c2af794-a0ed-4827-bc8e-1f15ad205eca
function processData(dataFile::URI)
	df = @chain dataFile begin
		HTTP.get(_).body
		CSV.File(footerskip=footerRows)
		DataFrame()
		commonProcessing()
	end
	return df
end

# ╔═╡ a08d1b29-fa5e-4312-977c-39b050de4516
md"""
This functions should also work if passed an already loaded CSV file:
"""

# ╔═╡ 0181a0b1-ec6c-4325-8b3a-851a3fe33846
function processData(dataFile::CSV.File)
	df = @chain dataFile begin
		DataFrame()
		commonProcessing()
	end
	return df
end

# ╔═╡ 247c2416-6c67-11eb-01df-8dac01cdbf8f
md"""
This functions should also work if passed an already loaded data frame (for example, if the user wants to load data and pre-process it in a different way before averaging replicates):
"""

# ╔═╡ 36ebe112-6c66-11eb-11f0-7fdb946865e4
function processData(data::DataFrame)
	return commonProcessing(data)
end

# ╔═╡ d904fd76-6af1-11eb-2352-837e03072137
begin
	allData = vcat(URI.(dataURLs), dataFiles)
	dfs = [ processData(df) for df in allData ]
end

# ╔═╡ 0e8af3be-7ae7-4ec2-8d7a-670878cd52ee
md"""
We will need to keep track of dataset names. You can edit them here if you want to use something more meaningful than the file name or URL; changes will propagate to plot legends. This list **must** contain the same number of elements as you have datasets: **$(length(allData))** in this case.
"""

# ╔═╡ 8e105fae-6aec-11eb-1471-83aebb776241
md"### Plotting"

# ╔═╡ 97c5020c-6aec-11eb-024b-513b1e603d98
md"The `initMainPlot()` function initializes a plot, the `plotOneDataset()` function plots one dataset (call it repeatedly to plot more datasets on the same axes)."

# ╔═╡ caf4a4a2-6aec-11eb-2765-49d67afa47dd
function initMainPlot()
	plot(
		xlabel = "Concentration",
		ylabel = "Signal",
		xscale = :log10,
		legend = :topleft
	)
end

# ╔═╡ fc194672-6aed-11eb-0a06-2d967ec094b1
md"The `initResidualPlot()` function initializes a plot, the `plotOneResiduals!()` function plots the fit residuals from one dataset (call it repeatedly to plot more datasets on the same axes)."

# ╔═╡ 14db987c-6aee-11eb-06cf-a11987b98f1e
function initResidualPlot()
	plot(
		xlabel = "Concentration",
		ylabel = "Fit residual",
		xscale = :log10,
		legend = :topleft
	)
	hline!([0], label = nothing, color = :red)
end

# ╔═╡ 7f83b838-6a11-11eb-3652-bdff24f3473e
function plotOneResiduals!(plt, df, fit, filePath)
	title = split(filePath, "/")[end]
	scatter!(
		plt,
		df.concentration,
		fit.resid,
		label = "$title: $chosenModel fit residual"
	)
end

# ╔═╡ 9020fa5d-7408-4161-a52f-df37b3c2e6f5
md"The `initResidualHistogram()` function initializes a histogram, the `plotOneResidualsHistogram!()` function plots a histogram of the fit residuals from one dataset (call it repeatedly to plot more datasets on the same axes)."

# ╔═╡ 3184d209-1cc9-40ed-a9ec-9f094c5c94b5
function initResidualHistogram()
	histogram(
		xlabel = "Fit residual",
		ylabel = "Count",
		legend = :topleft
	)
	vline!([0], label = nothing, color = :red)
end

# ╔═╡ b38cd229-64e2-4ca4-a78b-8881ec166b09
function plotOneResidualsHistogram!(plt, df, fit, filePath)
	title = split(filePath, "/")[end]
	histogram!(
		plt,
		fit.resid,
		bins = length(fit.resid),
		label = "$title: $chosenModel fit residual"
	)
end

# ╔═╡ 663a4cae-658a-11eb-382f-cf256c08c9d1
md"### Model functions"

# ╔═╡ 594e7534-6aeb-11eb-1254-3b92b71877ed
md"#### Model selection"

# ╔═╡ 32dce844-6aee-11eb-3cf2-3ba420d311d3
md"""
This dictionary maps radio button options (in section [Visualizations](#5c5e0392-658a-11eb-35be-3d940d4504cb) above) to their corresponding model function:
"""

# ╔═╡ a1f56b0a-6aeb-11eb-0a44-556fad58f368
md"""
The remaining cells in this section are only meant to check that the model selection buttons work. This first cell should return the name of the selected binding model (corresponding to the active radio button in section [Visualizations](#5c5e0392-658a-11eb-35be-3d940d4504cb) above):
"""

# ╔═╡ 5be2e5d2-6a11-11eb-1421-492f5af16f9c
chosenModel

# ╔═╡ 58617378-6aee-11eb-23e8-c13d89b4c57f
md"""
This other cell should return the model function corresponding to the selected binding model (the active radio button in section [Visualizations](#5c5e0392-658a-11eb-35be-3d940d4504cb) above):
"""

# ╔═╡ 88d941e6-658a-11eb-08a2-0f021e5ae3a4
md"""
#### Hill model

This is the [Hill equation](https://en.wikipedia.org/wiki/Hill_equation_(biochemistry)):

$S = S_{min} + (S_{max} - S_{min}) \times \frac{L^h}{{K_D}^h + L^h}$

In which $S$ is the measured signal ($Y$ value) at a given value of ligand concentration $L$ ($X$ value), $S_{min}$ and $S_{max}$ are the minimum and maximum values the observed signal can take, respectively, $K_D$ is the equilibrium dissociation constant and $h$ is the Hill coefficient."""

# ╔═╡ e9fc3d44-6559-11eb-2da7-314e8fc76ee9
@. hill(conc, p) = p[1] + (p[2] - p[1]) * conc^p[4] / (p[3]^p[4] + conc^p[4])

# ╔═╡ 9d1f24cc-6a0f-11eb-3b16-35f89aff5d4a
md"""
#### Hyperbolic model

The hyperbolic equation is a special case of the Hill equation, in which $h = 1$:
"""

# ╔═╡ 78e664d0-6618-11eb-135b-5574bb05ddef
@. hyperbolic(conc, p) = p[1] + (p[2] - p[1]) * conc / (p[3] + conc)

# ╔═╡ b0b17206-6a0f-11eb-2f5e-5fc8fa06cd36
md"""
#### Quadratic model

Unlike the Hill and hyperbolic models, the quadratic model does not make the approximation that the concentration of free ligand at equilibrium is equal to the total ligand concentration:

$S = S_{min} + (S_{max} - S_{min}) \times \frac{(K_{D} + R_{tot} + L_{tot}) - \sqrt{(- K_{D} - R_{tot} - L_{tot})^2 - 4 \times R_{tot} \times L_{tot}}}{2 \times R_{tot}}$

Symbols have the same meaning as in the previous equations, except here $L_{tot}$ is the total concentration of ligand, not the concentration of free ligand at equilibrium. $R_{tot}$ is the total concentration of receptor.

In principle, $R_{tot}$ could be left as a free parameter to be determined by the fitting procedure, but in general it is known accurately enough from the experimental set up, and one should replicate the same experiment with different concentrations of receptor to check its effect on the results. $R_{tot}$ should be set in the experiment to be smaller than $K_D$, ideally, or at least of the same order of magnitude than $K_D$. It might take a couple experiments to obtain an estimate of $K_D$ before one can determine an adequately small concentration of receptor at which to perform a definite experiment.
"""

# ╔═╡ 5694f1da-6636-11eb-0fed-9fee5c48b114
@. quadratic(conc, p) = p[1] + (p[2] - p[1]) * ( (p[3] + R0 + conc) - sqrt((-(p[3] + R0 + conc)) ^ 2 - 4 * R0 * conc) ) / (2 * R0)

# ╔═╡ 605f06ae-6a11-11eb-0b2f-eb81f6526829
bindingModels = Dict(
	"Hill" => hill,
	"Hyperbolic" => hyperbolic,
	"Quadratic" => quadratic
)

# ╔═╡ 7c03fcbe-6a11-11eb-1b7b-cbad863156a6
function plotOneDataset!(plt, df, fit, filePath, showInitial = false, initialValues = nothing)
	title = split(filePath, "/")[end]
	scatter!(
		plt,
		df.concentration,
		df.measurement,
		label = "$title: data"
	)
	if showInitial
		plot!(
			plt,
			df.concentration,
			bindingModels[chosenModel](df.concentration, initialValues),
			label = "$title: $chosenModel fit (initial)",
			color = :grey
		)
		plot!(
			plt,
			df.concentration,
			bindingModels[chosenModel](df.concentration, fit.param),
			label = "$title: $chosenModel fit (converged)",
			color = :red
		)
	else
		plot!(
			plt,
			df.concentration,
			bindingModels[chosenModel](df.concentration, fit.param),
			label = "$title: $chosenModel fit",
			color = :red
		)
	end
end

# ╔═╡ 6668c49a-6a11-11eb-2abf-5feecaee8972
bindingModels[chosenModel]

# ╔═╡ 0f960a8a-6a0f-11eb-04e2-b543192f6354
md"### Parameters and their initial values"

# ╔═╡ 2eb890a4-658c-11eb-1fc4-af645d74109d
md"""
The `findInitialValues()` function takes the measured data and returns an array containing initial values for the model parameters (in this order): $S_{min}$, $S_{max}$, $K_D$ and $h$ (for the Hill model only, so the function needs to know which model was selected).

Initial values for $S_{min}$ and $S_{max}$ are simply taken as the minimal and maximal values found in the data. The initial estimate for $K_D$ is the concentration of the data point that has a signal closest to halfway between $S_{min}$ and $S_{max}$ (if the experiment was properly designed, this is a reasonable estimate and close enough to the true value for the fit to converge). The initial estimate of $h$ is $1.0$, meaning we assume no cooperativity.
"""

# ╔═╡ ca2d2f12-6a1a-11eb-13ca-1f93df2b8e4a
function findInitialValues(df, model)
	halfSignal = minimum(df.mean) + (maximum(df.mean) - minimum(df.mean)) / 2
	if model == "Hill"
		params = [
			minimum(df.mean),
			maximum(df.mean),
			df.concentration[findmin(abs.(halfSignal .- df.mean))[2]],
			1.0
		]
	else
		params = [
			minimum(df.mean),
			maximum(df.mean),
			df.concentration[findmin(abs.(halfSignal .- df.mean))[2]]
		]
	end
end

# ╔═╡ 9be41e32-6af0-11eb-0904-d1cf3c288cab
md"Determine initial values of the selected model's parameters from the currently loaded datasets:"

# ╔═╡ 67b538f6-6a1b-11eb-3004-2d89c2f941e8
initialParams = [ findInitialValues(df, chosenModel) for df in dfs ]

# ╔═╡ 213e8ffa-6a0f-11eb-357e-638146193c5d
md"### Fitting"

# ╔═╡ babcb896-6af0-11eb-194a-15922bc2df83
md"Perform fit of the selected model to the measurements' mean values using initial values for the model parameters determined previously. If the dataset contains replicates, the fit will be weighted by the measurements' standard deviations."

# ╔═╡ 47426056-6af2-11eb-17f8-6d27d35003ca
begin
	fits = Vector{LsqFit.LsqFitResult}(undef, length(allData))
	for (df, initialValues, i) in zip(dfs, initialParams, 1:length(allData))
		if ncol(df) > 5
			# If the dataset has more than 5 columns, it means it has
			# replicate Y values, so we weight the fit by their stddev.
			fits[i] = curve_fit(bindingModels[chosenModel],
						df.concentration,
						df.mean,
						df.std,
						initialValues)
		else
			# If the dataset has only 5 columns, it means it doesn't have
			# replicate Y values, so there are no stddev we can use as weights.
			fits[i] = curve_fit(bindingModels[chosenModel],
						df.concentration,
						df.mean,
						initialValues)
		end
	end
	fits
end

# ╔═╡ 264bf9ec-6af5-11eb-1ffd-79fb3466f596
begin
	dataPlot = initMainPlot()
	for (df, fit, title, initialVals) in zip(dfs, fits, datasetNames, initialParams)
		plotOneDataset!(dataPlot, df, fit, title, showInitialFit, initialVals)
	end
	dataPlot
end

# ╔═╡ a951b5dc-6af7-11eb-2401-5d11a14e3067
begin
	residualPlot = initResidualPlot()
	for (df, fit, title) in zip(dfs, fits, datasetNames)
		plotOneResiduals!(residualPlot, df, fit, title)
	end
	residualPlot
end

# ╔═╡ 7625d41a-dab1-4b10-947c-3667c03f85aa
begin
	residualHistogram = initResidualHistogram()
	for (df, fit, title) in zip(dfs, fits, datasetNames)
		plotOneResidualsHistogram!(residualHistogram, df, fit, title)
	end
	residualHistogram
end

# ╔═╡ 2109f516-6b99-11eb-05a0-99b9ecfd0f9d
PlutoUI.with_terminal() do
	println("Dataset\t\t\t\tSum of squared residuals")
	for (dataset, fit) in zip(datasetNames, fits)
		println(
			split(dataset, "/")[end],
			"\t\t",
			round(sum(fit.resid.^2), digits = 2)
		)
	end
end

# ╔═╡ 799680d0-6af1-11eb-321d-b7758a40f931
md"Degrees of freedom:"

# ╔═╡ 1f0384de-659b-11eb-043e-5b86fcdd36e6
dof.(fits)

# ╔═╡ 54501a10-6b9c-11eb-29de-77afc3772fb7
md"Best fit parameters:"

# ╔═╡ 5ed3ab64-6b9c-11eb-149e-43a1ef12ac7d
coef.(fits)

# ╔═╡ 8643b03c-6af1-11eb-0aa7-67acee28d2c0
md"Standard errors of best-fit parameters:"

# ╔═╡ a74998b4-659c-11eb-354d-09ff62710b87
paramsStdErrors = stderror.(fits)

# ╔═╡ 090347fc-6b8e-11eb-0e17-9d9d45749c0b
PlutoUI.with_terminal() do
	if length(initialParams[1]) == 3
		# No Hill coefficient to report.
		println("Dataset\t\t\t\tKd\t\t\t\tSmin\t\t\tSmax")
		for (dataset, fit, stderr) in zip(datasetNames, fits, paramsStdErrors)
			println(
				split(dataset, "/")[end],
				"\t\t",
				round(fit.param[3], digits = 1),
				" ± ",
				round(stderr[3], digits = 1),
				"\t\t",
				round(fit.param[1], digits = 1),
				" ± ",
				round(stderr[1], digits = 1),
				"\t\t",
				round(fit.param[2], digits = 1),
				" ± ",
				round(stderr[2], digits = 1)
			)
		end
	elseif length(initialParams[1]) == 4
		# There is a Hill coefficient to report.
		println("Dataset\t\t\t\tKd\t\t\t\tSmin\t\t\tSmax\t\t\th")
		for (dataset, fit, stderr) in zip(datasetNames, fits, paramsStdErrors)
			println(
				split(dataset, "/")[end],
				"\t\t",
				round(fit.param[3], digits = 1),
				" ± ",
				round(stderr[3], digits = 1),
				"\t\t",
				round(fit.param[1], digits = 1),
				" ± ",
				round(stderr[1], digits = 1),
				"\t\t",
				round(fit.param[2], digits = 1),
				" ± ",
				round(stderr[2], digits = 1),
				"\t\t",
				round(fit.param[4], digits = 1),
				" ± ",
				round(stderr[4], digits = 1),
			)
		end
	else
		# Other number of values in the parameters array make no sense.
		println("Error.")
	end
end

# ╔═╡ Cell order:
# ╟─412eedac-658a-11eb-2326-93e5bf3d1a2c
# ╟─270cc0cc-660f-11eb-241e-b75746a39cc7
# ╠═a2c02fcf-9402-4938-bc3d-819b45a66afa
# ╠═14baf100-660f-11eb-1380-ebf4a860eed8
# ╟─2ce72e97-0133-4f15-bf1d-7fd04ccf3102
# ╟─214acce6-6ae8-11eb-3abf-492e50140317
# ╟─d904fd76-6af1-11eb-2352-837e03072137
# ╟─0e8af3be-7ae7-4ec2-8d7a-670878cd52ee
# ╠═d5b0e2a1-865c-489c-9d0d-c4ae043828fb
# ╟─5c5e0392-658a-11eb-35be-3d940d4504cb
# ╟─3dd72c58-6b2c-11eb-210f-0b547bf38ebe
# ╟─3da83f72-6a11-11eb-1a74-49b66eb39c96
# ╟─d15cba72-6aeb-11eb-2c80-65702b48e859
# ╟─01b59d8a-6637-11eb-0da0-8d3e314e23af
# ╟─264bf9ec-6af5-11eb-1ffd-79fb3466f596
# ╟─4f4000b4-6b2c-11eb-015f-d76a0adda0a0
# ╟─c50cf18c-6b11-11eb-07d3-0b8e332ec5bc
# ╟─5a36fc3f-ce74-42c8-8284-19321e0d687f
# ╟─a951b5dc-6af7-11eb-2401-5d11a14e3067
# ╟─5392d99b-70f9-48cd-90b4-58cba5fc9681
# ╟─7625d41a-dab1-4b10-947c-3667c03f85aa
# ╟─be17b97e-663a-11eb-2158-a381c19ece3f
# ╟─090347fc-6b8e-11eb-0e17-9d9d45749c0b
# ╟─124c4f94-6b99-11eb-2921-d7c2cd00b893
# ╟─2109f516-6b99-11eb-05a0-99b9ecfd0f9d
# ╟─7e7a9dc4-6ae8-11eb-128d-83544f01b78b
# ╟─512e3028-6ae9-11eb-31b4-1bc9fc66b322
# ╠═393b2f5e-6556-11eb-2119-cf7309ee7392
# ╠═abc03f64-6a11-11eb-0319-ed7cea455cb5
# ╟─1884912a-6aeb-11eb-2b4a-d14d4a321dc5
# ╟─4f4b580d-507c-4ad0-b1d5-5967c8ed829e
# ╠═5eb607c7-172b-4a6c-a815-acbc195108f0
# ╟─992c86a2-6b13-11eb-1e00-95bdff2736d0
# ╠═1fe4d112-6a11-11eb-37a6-bf95fbe032b1
# ╟─5cc812af-4f8e-444b-9652-fb063cc6be06
# ╠═7c2af794-a0ed-4827-bc8e-1f15ad205eca
# ╟─a08d1b29-fa5e-4312-977c-39b050de4516
# ╠═0181a0b1-ec6c-4325-8b3a-851a3fe33846
# ╟─247c2416-6c67-11eb-01df-8dac01cdbf8f
# ╠═36ebe112-6c66-11eb-11f0-7fdb946865e4
# ╟─8e105fae-6aec-11eb-1471-83aebb776241
# ╟─97c5020c-6aec-11eb-024b-513b1e603d98
# ╠═caf4a4a2-6aec-11eb-2765-49d67afa47dd
# ╠═7c03fcbe-6a11-11eb-1b7b-cbad863156a6
# ╟─fc194672-6aed-11eb-0a06-2d967ec094b1
# ╠═14db987c-6aee-11eb-06cf-a11987b98f1e
# ╠═7f83b838-6a11-11eb-3652-bdff24f3473e
# ╟─9020fa5d-7408-4161-a52f-df37b3c2e6f5
# ╠═3184d209-1cc9-40ed-a9ec-9f094c5c94b5
# ╠═b38cd229-64e2-4ca4-a78b-8881ec166b09
# ╟─663a4cae-658a-11eb-382f-cf256c08c9d1
# ╟─594e7534-6aeb-11eb-1254-3b92b71877ed
# ╟─32dce844-6aee-11eb-3cf2-3ba420d311d3
# ╠═605f06ae-6a11-11eb-0b2f-eb81f6526829
# ╟─a1f56b0a-6aeb-11eb-0a44-556fad58f368
# ╠═5be2e5d2-6a11-11eb-1421-492f5af16f9c
# ╟─58617378-6aee-11eb-23e8-c13d89b4c57f
# ╠═6668c49a-6a11-11eb-2abf-5feecaee8972
# ╟─88d941e6-658a-11eb-08a2-0f021e5ae3a4
# ╠═e9fc3d44-6559-11eb-2da7-314e8fc76ee9
# ╟─9d1f24cc-6a0f-11eb-3b16-35f89aff5d4a
# ╠═78e664d0-6618-11eb-135b-5574bb05ddef
# ╟─b0b17206-6a0f-11eb-2f5e-5fc8fa06cd36
# ╠═5694f1da-6636-11eb-0fed-9fee5c48b114
# ╟─0f960a8a-6a0f-11eb-04e2-b543192f6354
# ╟─2eb890a4-658c-11eb-1fc4-af645d74109d
# ╠═ca2d2f12-6a1a-11eb-13ca-1f93df2b8e4a
# ╟─9be41e32-6af0-11eb-0904-d1cf3c288cab
# ╠═67b538f6-6a1b-11eb-3004-2d89c2f941e8
# ╟─213e8ffa-6a0f-11eb-357e-638146193c5d
# ╟─babcb896-6af0-11eb-194a-15922bc2df83
# ╠═47426056-6af2-11eb-17f8-6d27d35003ca
# ╟─799680d0-6af1-11eb-321d-b7758a40f931
# ╠═1f0384de-659b-11eb-043e-5b86fcdd36e6
# ╟─54501a10-6b9c-11eb-29de-77afc3772fb7
# ╠═5ed3ab64-6b9c-11eb-149e-43a1ef12ac7d
# ╟─8643b03c-6af1-11eb-0aa7-67acee28d2c0
# ╠═a74998b4-659c-11eb-354d-09ff62710b87
