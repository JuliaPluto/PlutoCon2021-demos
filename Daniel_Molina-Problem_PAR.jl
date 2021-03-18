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

# ╔═╡ 414b0dd0-7ccc-11eb-1716-e5386ac38f94
begin
	function showvalues(values)
	str = join(string.(values), ", ")
	return string("{", str, "}")
end
	using Plots
	gr()
	using Random
	Random.seed!(42343)
	using PlutoUI: NumberField, Button, Slider, CheckBox
	using Distances
	using DataFrames
	using StatsBase: mean
	using Distances: pairwise, Euclidean
end

# ╔═╡ 50b71bec-87e4-11eb-3f0a-e12518ee1041
md"""
# Demo for the PlutoCon 201
## Author: Daniel Molina Cabrera
## Talk: Teaching Computer Sciences and Metaheuristics Algorithms using Pluto
"""

# ╔═╡ 2d9ebb0a-7ceb-11eb-0ed8-f9b3ab9f1b08
md"""
# Grouping with constraints Problem

In this problem there is a dataset with *N* instances that represent numerical vectos, and it is wanted to group them in *k* clusters.

The target is select the clustering considering:

1. Fulfil as much as possible a number of constraints (several pairs of instances must be in the same clusters, they are listed in list ML, and another pairs of instances that have to be in different clusters, in list  CL).
- ``\displaystyle infeasability = \begin{array}{l} \displaystyle\sum_{i=0}^{|ML|}bool2int(hc(\overrightarrow{ML_{[i,1]}})\ne hc(\overrightarrow{ML_{[i,2]}}))\\+bool2int(hc(\overrightarrow{CL_{[i,1]}})= hc(\overrightarrow{CL_{[i,2]}}))\end{array}``

2. Reduce the intra-cluster distance:
- For each cluster *i* it is calculated its  centroid (median of the instances member of that cluster): ``\displaystyle \overrightarrow{\mu_i}=\frac{1}{c}\sum_{\overrightarrow{x_j}\in c_i} \overrightarrow{x_i}``
- The instra-cluster distance is calculate with ``\displaystyle \overline{c_i}=\frac{1}{|c_i|}\sum_{\overrightarrow{x_j}\in c_i}||\overrightarrow{x_j} -\overrightarrow{\mu_i}||_2``.
"""

# ╔═╡ 1d66778c-7cf5-11eb-1736-53a4d4b6003d
md"""
## Initial problem:

Giving several points like following:
"""

# ╔═╡ ba09d096-80c6-11eb-0e0d-358c265533fd
function scene(points; title="", colors=:white, markersize=5, share=false)
	if share
		fun_plot = Plots.scatter!
	else
		fun_plot = Plots.scatter
	end
	
	fun_plot(points[:,1], points[:,2], color=colors, legend=false, axis=false, grid=false, ticks=false, title=title, hover=1:size(points, 1), markersize=markersize, markerstrokewidth=2)
end

# ╔═╡ 3b36ba88-7cf5-11eb-160a-9bb47805303c
begin
	local tam
	tam = @bind n NumberField(3:40, default=10)
    button  = @bind nuevo Button("Nuevo conjunto")
	md"n:  $tam  $button"
end

# ╔═╡ 5b8ffd12-7cf5-11eb-36f7-f5503c0bf656
begin
	button
	data = rand(n, 2)
	dists = pairwise(Euclidean(), eachrow(data), eachrow(data))
	D = maximum(dists)
	# data = data[sortperm(data[:,1]),:]
	scene(data, markersize=5)
end

# ╔═╡ 942cd76c-7cfa-11eb-3af4-d9506c97f4cb
md"""
## Problem: number k and constraints
"""

# ╔═╡ b582d3ca-7cfb-11eb-1f60-5945b3cb6560
begin
	local html, html2, html3
	html = @bind k NumberField(2:5, default=3)
	md"k: $html"
end

# ╔═╡ 813eb76c-8207-11eb-2423-11fa68f73977
begin
	local html, html2
	html1 = @bind ML_r NumberField(2:5, default=3)
	html2 = @bind CL_r NumberField(2:5, default=1)
	md"|ML|: $html1  |CL|: $html2"
end

# ╔═╡ 82a7858c-7cf5-11eb-330d-2b95596db9ea
md"""
There are several constraints between groups
"""

# ╔═╡ 10985586-7cf8-11eb-3adc-9309220f798a
@bind nuevo_rest Button("New constraints")

# ╔═╡ 8ae8337c-7cf5-11eb-1bb8-ffa375d6620c
begin
	local N, CL_str, ML_str
	nuevo_rest
	N = size(data, 1)
	# r = max(div(N, 10), 3)
	ML = [tuple(Random.shuffle(1:N)[1:2]...) for _ in 1:ML_r]
	CL = [tuple(Random.shuffle(1:N)[1:2]...) for _ in 1:CL_r]
	ML_str = join(string.(ML), ", ")
	CL_str = join(string.(CL), ", ")
	md"""
	ML: {$(ML_str)}   

	CL: {$(CL_str)}	
	"""
end

# ╔═╡ 403f3440-7cf7-11eb-26be-f58c4c748862
md"""
We represent visually the constraints that have to be in the same cluster with a continuous line, and with a dashed line which  have to be in different clusters.
"""

# ╔═╡ 89f4a72a-7cfa-11eb-00b8-7be8b525f737
md"""
## Initial solution:

A initial solution is a partition, represented by a vector of length N, in which each position i has a value between 1 and k, the value represent the cluster assigned to the instance **i**.
"""

# ╔═╡ 6a2348d4-7cfc-11eb-2c3e-7915e39dac2b
colores = [:green, :orange, :black]

# ╔═╡ 3fac6e56-7cfe-11eb-3f4d-4729f9a8db08
@bind nuevogrouping Button("New partition")

# ╔═╡ e7eb538c-7cfb-11eb-37a3-1de8a03d808c
begin
	nuevogrouping
	grouping = rand(1:k, size(data, 1))
end

# ╔═╡ f5e96eaa-7cfc-11eb-295e-ed9b945ebb4a
md"""
We remark with different colors each clustering, indicating in the title how many constraints are violated, and the average inter-clustering distance.
"""

# ╔═╡ a794dee6-7cfd-11eb-052a-199c1421427a
function incumple(solucion)
	unfeasible = 0
	
	for ml in ML
		p1, p2 = ml
		if solucion[p1]  != solucion[p2]
			unfeasible += 1
		end
	end
	
	for cl in CL
		p1, p2 = cl
		if solucion[p1] == solucion[p2]
			unfeasible += 1
		end
	end
	
	return unfeasible
end

# ╔═╡ 4b61e0ce-7d00-11eb-276b-b995e1e7c50a
function dist_intra(cluster)
    num = size(cluster, 1)
    mean_cluster = mean(cluster, dims=1)
    dist = mean(euclidean(row, mean_cluster) for row in eachrow(cluster))
    return dist
end



# ╔═╡ ff54579a-7cfd-11eb-2a6b-13669c42deab
function distancia_intracluster(solucion)
	n = maximum(solucion)
	dists = zeros(n)
	
	for i in 1:n
            cluster = data[solucion .== i,:]
            dists[i] = dist_intra(cluster)
	end

    return mean(dists)
end

# ╔═╡ bf1ab790-7cf6-11eb-02d4-2b5bbe59689a
function plot_pac(solucion=nothing; fitness=nothing)
	
	if isnothing(solucion)
		colors = [:white]
		title = ""
	else
		colors = solucion
		title = "Violate $(incumple(solucion)) constraints and it have a distance of $(round(distancia_intracluster(solucion), digits=4))"
		
		if !isnothing(fitness)
			title = string(title, "\nFitness: $(fitness(solucion))")
		end
	end
	
	for (l1, l2) in ML[1:1]
		plot(data[[l1,l2],1], data[[l1,l2],2], color=:black, linewidth=2)
	end
	
	for (l1, l2) in ML[2:end]
		plot!(data[[l1,l2],1], data[[l1,l2],2], color=:black, linewidth=2)
	end
	
	for (l1, l2) in CL
		plot!(data[[l1,l2],1], data[[l1,l2],2], color=:black, linewidth=2, linestyle=:dash)
	end
	
	scene(data, colors=colors, title=title, markersize=5, share=true)
	Plots.current()
end

# ╔═╡ 26762448-7cf6-11eb-2bfd-d38455f6c2fd
plot_pac()

# ╔═╡ 0d0788ec-7cfd-11eb-2261-193f1d2921f5
plot_pac(grouping)

# ╔═╡ a8fbfcb6-81a2-11eb-2f5c-73fe789f193a
function plot_clusters(problems, points; solucion=nothing)
	plot_pac(solucion)
	Plots.scatter!(points[:,1], points[:,2], m = (7, :pentagon), color=1:size(points, 1), markerstrokewidth=2)
end

# ╔═╡ 51cf451a-81a2-11eb-305b-dfff76a7916d
md"""
## Greedy Algorithm

The Greedy algorithm build a solution step by  step. The process is as follow:

1. Randomly generate K clusters.
"""


# ╔═╡ 158ca3a6-81eb-11eb-01fe-1bb8fdc8d165
begin
	local html
	html = @bind Seed NumberField(1:300, default=42)
	md"Seed: $html"
end

# ╔═╡ 3a186086-81a3-11eb-1a77-913391c16c21
@bind button_cluster Button("Init Clusters")

# ╔═╡ 9516b3d0-81a2-11eb-2e63-11756fd67f26
begin
	button_cluster
	clusters = rand(k, 2)
end

# ╔═╡ a61a40de-81a2-11eb-0d71-735c2c46a3cc
plot_clusters(data, clusters)

# ╔═╡ 9213a7a6-81a2-11eb-17c8-c3ec129f603a
md"""
2. For each element it is selected the cluster closer than *violate less constraints*.
"""

# ╔═╡ f76b23ce-81a5-11eb-09f5-8101ff26598c
@bind cluster_slider Slider(1:n+1)

# ╔═╡ 41c69aa4-81a9-11eb-1682-ad92b8ae2a9a
md"clusters: $(showvalues(clusters))"

# ╔═╡ a9750f0a-81ea-11eb-1993-959d7d5603c9
md"""
3. If the centroids should be updated, recalculate it and go to step 2.
"""

# ╔═╡ 0935025a-81ec-11eb-102f-bd4d1953e61d
@bind greedy_slider Slider(1:10)

# ╔═╡ 6d94eeda-8206-11eb-2439-b329faa3938f
md"""
### The final solution obtained is:
"""

# ╔═╡ 65bf268e-81a8-11eb-1d19-715d47710cf6
function creaV(ML, CL)
	V = zeros(Int, n, n)
	for cl in CL
		V[cl[1],cl[2]] = -1
		V[cl[2],cl[1]] = -1
	end
	for ml in ML
		V[ml[1],ml[2]] = 1
		V[ml[2],ml[1]] = 1
	end
	for i in 1:n
		V[i,i] = 1
	end
	return V
end

# ╔═╡ 9f58f668-81a8-11eb-19e4-0f7236be4b22
function count_violations(sol, V, pos, value)
    count = 0

    for (i, rest) in enumerate(V)
        if rest == 0 || sol[i] == 0
            continue
        elseif rest == 1 && value != sol[i]
            count += 1
        elseif rest == -1 && value == sol[i]
            count += 1
        end
    end

    return count
end

# ╔═╡ ea5ab0a0-81dc-11eb-085b-0ddf3961af55
function plot_greedy_options(current, newpos, clusters, criteria)
	plot_clusters(data, clusters)
	is_cluster = any(all(data[newpos,:]' .== clusters, dims=2))
	sel = minimum(criteria)
	
	if !is_cluster
		for (infeasibility, rank, cluster_id) in criteria
			cluster = clusters[cluster_id,:]
			arc = hcat(data[newpos,:], data[newpos,:])
			
			if sel[3] == cluster_id
				lw = 3
			else
				lw = 1
			end
			
			plot!([data[newpos,1], cluster[1]], [data[newpos,2],cluster[2]], color=cluster_id, linewidth=lw)
			# plot!(arc[:, 1], arc[:, 2], color=cluster_id)
		end
	end
	
	if is_cluster
		m = (7, :pentagon)
	else
		m = (5, :circle)
	end
	
	scatter!(data[newpos:newpos, 1], data[newpos:newpos, 2], m=m, 
			markerstrokecolor=:red, markerstrokewidth=2, color=sel[3])
		
	pos = findall(!=(0), current)
	points = data[pos,:]
	scatter!(points[:,1], points[:, 2], color=current[pos])
end

# ╔═╡ c2a0460c-81a9-11eb-1dab-53ddbd914b40
function step_greedy(rng, clusters_actual, current, data, V, top; plot=false)
	pos = randperm(rng, n)
	dists = pairwise(Euclidean(), data, clusters_actual, dims=1)
	
	if top <= n
		pos = pos[1:top]
	end
 
	for p in pos
		nearests = sortperm(dists[p, :])
		criteria = [(count_violations(current, V[p,:], p, value), rank, value) for (rank, value) in enumerate(nearests)]
		
		if (plot && top <= n && p == pos[end])
			plot_greedy_options(current, p, clusters_actual, criteria)	
		end
		selected = minimum(criteria)
		current[p] = selected[3]
	end
	
	means = Array{Float64,2}(undef, 0, 2)
	
	for i in 1:n
		values = findall(==(i), current)
		
		if !isempty(values)
			means = vcat(means, mean(data[values,:], dims=1))
		end
	end
	# Update cluster
	return current, means
end

# ╔═╡ e61b1ea8-81a5-11eb-1778-4527da489e73
begin
	function init_greedy(data, clusters, ML,  CL, cluster_slider)
	local current, V, clusters_actual, points
	clusters_actual = copy(clusters)
	current = zeros(Int,n)
	# Init V
	V = creaV(ML, CL)
	rng = MersenneTwister(Seed)
	
	current, clusters_actual = step_greedy(rng, clusters_actual, current, data, V, cluster_slider, plot=(cluster_slider <= n))
	
	if cluster_slider > n
		plot_clusters(data, data[clusters,:])
		scatter!(data[:,1], data[:, 2], color=current)
	end
	
	Plots.current()
	end
	
	init_greedy(data, clusters, ML, CL, cluster_slider)
	# plot_clusters(data, clusters_actual, solucion=nothing)
	# changed = (oldclusters ≈ clusters_actual)
end

# ╔═╡ fee211a0-81eb-11eb-3276-07d255c468eb
begin
	function itera_greedy(data, clusters, ML,  CL, greedy_slider)
		clusters_actual = copy(clusters)
		changed = true
		current = zeros(Int,n)
		# Init V
		V = creaV(ML, CL)
		rng = MersenneTwister(Seed)
		maxitera = greedy_slider-1
		old_clusters = copy(clusters_actual)
	
		for itera in 0:maxitera
			if 	changed 
				current .= zeros(Int,n)
				current, clusters_new = step_greedy(rng, clusters_actual, current, data, V, n, plot=false)
				old_clusters .= clusters_actual
				changed = !(clusters_new ≈ clusters_actual)
				
				if maxitera > 0
					clusters_actual .= clusters_new
				end
			end
	
			if itera == maxitera
				plot_clusters(data, old_clusters)
				scatter!(data[:,1], data[:, 2], color=current)
				
				for (i, value) in enumerate(current)
					point = data[i,:]
					cluster = old_clusters[value,:]
					plot!([point[1], cluster[1]], [point[2], cluster[2]], color=value)
				end
			end
		end

		return current, Plots.current()
	end
	
	_, p = itera_greedy(data, clusters, ML, CL, greedy_slider)
	p
	# plot_clusters(data, clusters_actual, solucion=nothing)
	# changed = (oldclusters ≈ clusters_actual)
end

# ╔═╡ 40c6c284-8206-11eb-12ce-61222ac404e1
begin
	local tmp
	current, tmp = itera_greedy(data, clusters, ML, CL, greedy_slider)
	plot_pac(current)
end

# ╔═╡ 632bd1f2-7d1a-11eb-3337-af06c6d71d83
md"""
## Meta-heuristic

To be able to apply the simple meta-heuristic we need a only objective function, thus we are going to join both criteria in a only fitness function.
"""

# ╔═╡ e6c3c85a-81a0-11eb-252a-e13093de237a
md"""
The measure is defined as ``\vec{C}+(infeasability\cdot \lambda)``, as a combination of the intra-cluster distance with a ``\lambda`` penalty for each constraints that is not fullfil.
"""

# ╔═╡ f16e5974-819f-11eb-343f-173c6652cad7
md"""
The first action is to  calculate ``\lambda``, defined ass the maximum distance between two points and divided by the total of constraints: ``\displaystyle \lambda=\frac{Max( Dist_{ij})}{R}, \forall i, j \in \{1, ..., n\}``
"""

# ╔═╡ 8e4f7132-81a1-11eb-2e5a-390564c91498
begin
	R = length(ML)+length(CL)
	λ = D/R
	md"``\lambda`` value: $(round(λ, digits=3)) = $(round(D,  digits=4)) / $(R)"
end

# ╔═╡ cb39560e-81f3-11eb-050a-058f7e7c8fa8
function fitness(sol)
	distancia_intracluster(sol) + λ*incumple(sol)
end

# ╔═╡ 6da0b736-81f4-11eb-168b-3fc1c1de320b
@bind nuevasol_inicial Button("New Initial Solution")

# ╔═╡ 02ae7916-81f4-11eb-3fe8-3d1882b993f1
begin
	nuevasol_inicial
	solucion_inicial = rand(1:k, n)
plot_pac(solucion_inicial, fitness=fitness)
end

# ╔═╡ 9dfa6eea-81f4-11eb-1627-7b7e217d0535
md"""
The local search procedure is to randomly choose one position, and change its value (maintaning that for each cluster has at least one member).
"""

# ╔═╡ b6a27d54-81f7-11eb-3535-0157f063202d
@bind sliderBL Slider(1:10_000)

# ╔═╡ c28f4016-81f7-11eb-2c61-6542d9caf49e
function BL(maxitera; seed=42, callback=nothing)
	rng = MersenneTwister(seed)
	actual = copy(solucion_inicial)
	fit_actual = fitness(actual)
	newsol = similar(actual)
	itera = 1
	
	while itera < maxitera
		pos = rand(rng, 1:n)
		newvalue = rand(rng, 1:k)
		newsol .= actual
		
		while (actual[pos] == newvalue)
			newvalue = rand(rng, 1:k)
		end
		
		newsol[pos] = newvalue
		
		if length(unique(newsol)) < k
			continue
		end
		
		fit = fitness(newsol)
		itera += 1
		
		if fit < fit_actual
			actual .= newsol
			fit_actual = fit
		end
		
		if !isnothing(callback)
			callback(actual, fit_actual)
		end
	end
	
	plot_pac(actual, fitness=fitness)	
end

# ╔═╡ ded683b0-81f7-11eb-2d64-7985d498a842
begin
	conv = Float64[]
	conv_callback(actual, fit) = push!(conv, fit)
	BL(sliderBL-1, seed=42, callback=conv_callback)
end

# ╔═╡ 5ea30412-8205-11eb-1ca2-4de513b84d9c
md"""
In the following there is the convergence graphic, that show the improvement of fitness through the run of the algorithm.
"""

# ╔═╡ 9b3ae0f4-8203-11eb-39d5-c3427d6f5808
if !isempty(conv)
Plots.plot(1:length(conv), conv, legend=false, xlabel="Evaluations", ylabel="Fitness")
end

# ╔═╡ Cell order:
# ╟─414b0dd0-7ccc-11eb-1716-e5386ac38f94
# ╟─50b71bec-87e4-11eb-3f0a-e12518ee1041
# ╟─2d9ebb0a-7ceb-11eb-0ed8-f9b3ab9f1b08
# ╟─1d66778c-7cf5-11eb-1736-53a4d4b6003d
# ╟─ba09d096-80c6-11eb-0e0d-358c265533fd
# ╟─3b36ba88-7cf5-11eb-160a-9bb47805303c
# ╟─5b8ffd12-7cf5-11eb-36f7-f5503c0bf656
# ╟─942cd76c-7cfa-11eb-3af4-d9506c97f4cb
# ╟─b582d3ca-7cfb-11eb-1f60-5945b3cb6560
# ╟─813eb76c-8207-11eb-2423-11fa68f73977
# ╟─82a7858c-7cf5-11eb-330d-2b95596db9ea
# ╟─10985586-7cf8-11eb-3adc-9309220f798a
# ╟─8ae8337c-7cf5-11eb-1bb8-ffa375d6620c
# ╟─bf1ab790-7cf6-11eb-02d4-2b5bbe59689a
# ╟─403f3440-7cf7-11eb-26be-f58c4c748862
# ╟─26762448-7cf6-11eb-2bfd-d38455f6c2fd
# ╟─89f4a72a-7cfa-11eb-00b8-7be8b525f737
# ╟─6a2348d4-7cfc-11eb-2c3e-7915e39dac2b
# ╟─3fac6e56-7cfe-11eb-3f4d-4729f9a8db08
# ╟─e7eb538c-7cfb-11eb-37a3-1de8a03d808c
# ╟─f5e96eaa-7cfc-11eb-295e-ed9b945ebb4a
# ╠═0d0788ec-7cfd-11eb-2261-193f1d2921f5
# ╟─a794dee6-7cfd-11eb-052a-199c1421427a
# ╟─4b61e0ce-7d00-11eb-276b-b995e1e7c50a
# ╟─ff54579a-7cfd-11eb-2a6b-13669c42deab
# ╟─a8fbfcb6-81a2-11eb-2f5c-73fe789f193a
# ╟─51cf451a-81a2-11eb-305b-dfff76a7916d
# ╟─158ca3a6-81eb-11eb-01fe-1bb8fdc8d165
# ╟─3a186086-81a3-11eb-1a77-913391c16c21
# ╟─9516b3d0-81a2-11eb-2e63-11756fd67f26
# ╟─a61a40de-81a2-11eb-0d71-735c2c46a3cc
# ╟─9213a7a6-81a2-11eb-17c8-c3ec129f603a
# ╟─f76b23ce-81a5-11eb-09f5-8101ff26598c
# ╟─41c69aa4-81a9-11eb-1682-ad92b8ae2a9a
# ╟─e61b1ea8-81a5-11eb-1778-4527da489e73
# ╟─a9750f0a-81ea-11eb-1993-959d7d5603c9
# ╟─0935025a-81ec-11eb-102f-bd4d1953e61d
# ╟─fee211a0-81eb-11eb-3276-07d255c468eb
# ╟─6d94eeda-8206-11eb-2439-b329faa3938f
# ╟─40c6c284-8206-11eb-12ce-61222ac404e1
# ╟─65bf268e-81a8-11eb-1d19-715d47710cf6
# ╟─9f58f668-81a8-11eb-19e4-0f7236be4b22
# ╟─ea5ab0a0-81dc-11eb-085b-0ddf3961af55
# ╟─c2a0460c-81a9-11eb-1dab-53ddbd914b40
# ╟─632bd1f2-7d1a-11eb-3337-af06c6d71d83
# ╟─e6c3c85a-81a0-11eb-252a-e13093de237a
# ╟─f16e5974-819f-11eb-343f-173c6652cad7
# ╟─8e4f7132-81a1-11eb-2e5a-390564c91498
# ╟─cb39560e-81f3-11eb-050a-058f7e7c8fa8
# ╟─6da0b736-81f4-11eb-168b-3fc1c1de320b
# ╟─02ae7916-81f4-11eb-3fe8-3d1882b993f1
# ╟─9dfa6eea-81f4-11eb-1627-7b7e217d0535
# ╟─b6a27d54-81f7-11eb-3535-0157f063202d
# ╟─c28f4016-81f7-11eb-2c61-6542d9caf49e
# ╟─ded683b0-81f7-11eb-2d64-7985d498a842
# ╟─5ea30412-8205-11eb-1ca2-4de513b84d9c
# ╟─9b3ae0f4-8203-11eb-39d5-c3427d6f5808
