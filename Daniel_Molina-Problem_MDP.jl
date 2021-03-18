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

# ╔═╡ 525a77d8-7ccb-11eb-07f3-bb1cc4b9d4a6
begin
	  using Plots
	  gr()
	  using Random
	  Random.seed!(42343)
	  using PlutoUI: NumberField, Button, CheckBox, Slider
	  using Distances
	  using DataFrames: DataFrame, rename!
	  using StatsBase: mean
end


# ╔═╡ 98c68364-87e4-11eb-0b5c-f39df8a7bafb
md"""
# Demo for the PlutoCon 201
## Author: Daniel Molina Cabrera
## Talk: Teaching Computer Sciences and Metaheuristics Algorithms using Pluto
"""

# ╔═╡ d409036c-7ccb-11eb-2f1c-ef355626c4f3
md"""
# Maximize Diversity Problem (MDP)

In this problem we have a set of data *n* and the target is to choose *m* of them (n < m) to maximize the distance between the selected.
In other words, it is wanted ``M \subset N`` that maximize ``\displaystyle \sum_{i \in N} \sum_{j \in N} D_{ij}``.
"""

# ╔═╡ c25233ea-7db2-11eb-2e18-e314b308f5a0
function showvalues(values)
	str = join(string.(values), ", ")
	return string("{", str, "}")
end

# ╔═╡ 1c9fabca-7ccd-11eb-086e-8b033697039f
md"""
## Initial Set

Then, from the following data:
"""

# ╔═╡ 25c072be-7ccd-11eb-06bf-87a610a9b61d
function scene(points; title="", colors=:blue, markersize=5)
	Plots.scatter(points[:,1], points[:,2], color=colors, legend=false, axis=false, grid=false, ticks=false, title=title, hover=1:size(points, 1), markersize=markersize)
end

# ╔═╡ b720c7f6-7ccd-11eb-2322-ef87a5dca4a0
begin
	tam = @bind n NumberField(3:40, default=10)
    button  = @bind nuevo Button("Nuevo conjunto")
	md"n:  $tam  $button"
end

# ╔═╡ baae04d0-7cd5-11eb-16e5-a53365c4294e
begin
	button
	problem = rand(n, 2)
	# problem = problem[sortperm(problem[:,1]),:]
	# sort!(problem, dims=2)
	scene(problem)
end

# ╔═╡ 73701676-7cd5-11eb-3643-930177ea6366
md"""
## Distance of the problem

We are not going to work with the points, we are going to work using  the distances between them.
"""

# ╔═╡ 97b9e874-7cd5-11eb-0e42-378e68cfd22c
begin
	dists = pairwise(Euclidean(), problem, dims=1)
	df = DataFrame(dists)
	rename!(df, string.(1:n))
end

# ╔═╡ 7bbce1ac-7cdc-11eb-189a-07e6e7026b7c
md"""
## Problem: We choose the m value and the distance measure
"""

# ╔═╡ d76b3cbe-7cd0-11eb-2870-c30481233d45
begin
	min_value = min(3, n)
	max_value = min(8, n)
	html = @bind m NumberField(min_value:max_value)
	md"m value: $html"
end

# ╔═╡ d8e1f3b0-7cdc-11eb-3119-09f90cb48a68
function metrica(solucion, dists=dists)
	distancias = Float64[]
	for i in 1:m
		for j in (i+1):m
			push!(distancias, dists[solucion[i],solucion[j]])
		end
	end
	
	return sum(distancias)
end

# ╔═╡ e973b5f4-7ccf-11eb-07e9-79ee89d458f4
md"""
## Solution for that problem

A random solution could be create easily choosing randomly m variable without repetition.
"""

# ╔═╡ 776ad346-7cd1-11eb-01fd-4300a85eb631
@bind nuevasol Button("New random solution")

# ╔═╡ 4a0daf90-7cd1-11eb-1fa5-a5e0f60e860b
begin
	local sol_str
	nuevasol
	solucion = sort(shuffle(1:n)[1:m])
	sol_str = join(string.(solucion), ", ")
	md"random solution: **{$(sol_str)}**"
end

# ╔═╡ b174ece0-7cd2-11eb-0b89-41604cdd9d52
md"""
The interpretation of the solution will be:
"""

# ╔═╡ bba210be-7cd2-11eb-0440-1b471e2c8a2d
function plot_sol(solucion)
	global m
	points = hcat([problem[i,:] for i in solucion]...)'
	dist = 0.0
	lines = Array{Tuple{Int,Int}}[]
	tam = 0
	title = ""
	
	if size(solucion, 1) == m
		fitness = metrica(solucion)
 		title = "Solution Fitness: $fitness"
 	end
	
	p = scene(problem, title=title)
 	scatter!(points[:,1], points[:,2], color=:red)
	min_m = min(m, size(points, 1))
	
 	for i in 1:n
 		for j in (i+1):min_m
 			plot!(points[[i,j],1], points[[i,j],2], color=:red, linewidth=2, arrow=false, style=:dash)	
 		end
 	end
	
 	p
# 	scatter!(points, color=:red, legend=false)
end

# ╔═╡ 93377306-7cdc-11eb-0c45-4982f8a45c77
md"""
In which the selected instances are in red, and the connexions with dashed lines. The fitness is obtained with the measure function.
"""

# ╔═╡ 678019c8-7cf9-11eb-07d9-5be88346cc3c
plot_sol(solucion)

# ╔═╡ f6b075b4-7cdd-11eb-1029-53dff62c68e7
md"""
## Local Search algorithm

The local search starts from an initial solution, and it is continuously improved. It can be described as:

1. Initial current solution is a random solution S.
2. If it has not yet finished (less than 100_000 evaluations or local optimum) continue steps 3-7.
3. Choose randomly a position i from S.
4. It create a new solution, in which the value of position i is changed by a new value j, where ``j \in \{N-solucion[i]\}``.
5. Compare the new solution S' with the previous one.
6. If S' fitness is worse than the S fitness, go to step 2.
7. If it is better ``S \leftarrow S'`` and go to step 2.
"""

# ╔═╡ fd64874c-7cdd-11eb-154d-8998a75f101a
function BL(original; maxevals=1000, callback=nothing)
	current = copy(original)
	current_fit = metrica(current)
	newsol = similar(current)
	
	for _ in 1:maxevals
		newsol .= current
		i = rand(1:m)
		j = rand(setdiff(1:n, current))
		newsol[i] = j
		fit = metrica(newsol)
		
		if fit > current_fit
			current .= newsol
			current_fit = fit
		end
		
		if callback != nothing
				callback(current)
		end

	end
	
	return current, current_fit
end

# ╔═╡ 10162afa-7ce1-11eb-20f3-cf7ce3a08761
begin
	html_maxevals = @bind maxevals NumberField(1:2000, default=100)
md"We apply the LS during $html_maxevals iterations"
end

# ╔═╡ 6b57428e-7ce2-11eb-22aa-b79e0005e16f
begin
	best, best_fit = BL(solucion, maxevals=maxevals)
	best_sol = join(string.(best), ", ")
	total = maxevals
	md"""
	The best found solution is **\{$(best_sol)\}** with fitness: **$(round(best_fit,digits=3))**
	"""
end

# ╔═╡ e897cee0-7ce3-11eb-19c7-a7aa0cea3c2b
plot_sol(best)

# ╔═╡ 2fad8aea-7ce4-11eb-36d5-23ef4daee43c
md"""
## We can see dynamically how it improves
"""

# ╔═╡ 38fef93c-7ce4-11eb-3269-4fbf1a3e498e
begin 
	html_slider = @bind slider Slider(1:100)
	md"Iteration: $html_slider"
end

# ╔═╡ 6629ee92-7ce4-11eb-362a-5b0052246896
begin
	best_dyn, best_fit_dyn = BL(solucion, maxevals=slider)
	plot_sol(best_dyn)
end

# ╔═╡ c17add8c-7d94-11eb-0a71-c9b04e4cc107
function showdf(table)
	table |>  DataFrame
end

# ╔═╡ 510521fc-7d99-11eb-3765-394921866646
function plot_greedy(current, newpos)
	p = plot_sol(current)
	m = length(current)
	mydists = zeros(m)
	
	for (i,value) in enumerate(current)
		mydists[i]  = dists[value,newpos]
	end
	
	bestpos = argmin(mydists)

	points = hcat([problem[i,:] for i in vcat(current, newpos)]...)'
	
	for i  in 1:size(points, 1)
		if i == bestpos
			style = :dash
		else
			style = :dot
		end
		
		plot!(points[[i,end],1], points[[i,end],2], color=:orange, linewidth=2, arrow=false, style=style)
	end
	
	title!(p, "Min distance with $(newpos): $(mydists[bestpos])")
	return p
end

# ╔═╡ f9522c12-7d92-11eb-0ee7-d9b64022c9d5
md"""
## Greedy Algorithm

This algorithm tackle the previous problem. It is a variant of classic algorithm because we cannot create clusters due to the fact that we only know the distances between instances, so we cannot create intermediate positions.
"""

# ╔═╡ 4d81e9dc-7d93-11eb-1298-bb7af5e8a42f
md"""
#### Algorithm

1. Define ``Sel=\emptyset``, y ``S``={todos los elementos}.
2. Calculate for each element *i* i its accumulated distance ``\displaystyle d_i = \sum_{j \in S}D_{ij}``
"""

# ╔═╡ 98248848-7d94-11eb-0fa5-85157d0b5781
accumulated_distance = rename!(sum(dists, dims=2) |> showdf, ["Distance"])

# ╔═╡ a424c946-7d94-11eb-3faf-ed146b509985
md"""
3. Set to ``Sel`` the element ``sol_1`` which maximize ``d_i``, ``S=\{S-sol_i\}``.
"""

# ╔═╡ d86299a8-7da4-11eb-2956-4be178d21a70
@bind inicia_greedy Button("Reset Greedy")

# ╔═╡ aa48b0e4-7d94-11eb-3a3a-29267936dd62
begin
	inicia_greedy
	local best
	best = argmax(sum(dists, dims=1))
	Sel = [best[2]]
	others = setdiff(1:n, Sel) |> collect
	first = true
	tam_others = n-1
	md"Sel: **$(showvalues(Sel))**"
end

# ╔═╡ dd307522-7d95-11eb-0b0b-f1218e06c86e
md"""
4. for each element c from S, to calculate the minimum distance to each element of Set ``\forall C \in S, dist(C, Sel)=min(D_{Csol}), \forall sol \in Sel``
"""

# ╔═╡ 72a19b7e-7d99-11eb-21b6-ef4028870601
@bind candidate_greedy Slider(1:size(others, 1))

# ╔═╡ d6f6a4c0-7da3-11eb-3e96-1bbcd1392e31
if candidate_greedy <= size(others, 1)
	plot_greedy(Sel, others[candidate_greedy])
else
	plot_greedy(Sel, others[end])
end

# ╔═╡ 76e48cb8-7da4-11eb-1012-d1dc6f71cf38
md"""
5. Choose the element c' with maximum dist(C, Sel).
"""

# ╔═╡ 9c2da05e-7da4-11eb-328f-191f38231c6e
function select_best(Sel, others)
	m = size(Sel, 1)
	mydists = zeros(m)
	distances = [minimum(dists[Sel,other]) for other in others]
	return argmax(distances)
end

# ╔═╡ 5aff27c2-7da6-11eb-1593-1341c2500fe9
begin
	local  html_g
	html_g = @bind doit CheckBox(default=false)
	md"Next step: $html_g"
end

# ╔═╡ 46407cac-7db5-11eb-11fe-b551c616dea1
begin
	if !doit
		best_next = select_best(Sel, others)
		md"Next better: **$(others[best_next])**"
	end
end

# ╔═╡ fdf5ab24-80bf-11eb-132e-9d58cee9be1f
begin
	local best
	
	if doit && size(Sel, 1) < m
		best = select_best(Sel, others)
		push!(Sel, others[best])
		deleteat!(others, best)
	end
	md"Sel: **$(showvalues(Sel))**, Others: **$(showvalues(others))**"
end

# ╔═╡ Cell order:
# ╟─525a77d8-7ccb-11eb-07f3-bb1cc4b9d4a6
# ╟─98c68364-87e4-11eb-0b5c-f39df8a7bafb
# ╟─d409036c-7ccb-11eb-2f1c-ef355626c4f3
# ╟─c25233ea-7db2-11eb-2e18-e314b308f5a0
# ╟─1c9fabca-7ccd-11eb-086e-8b033697039f
# ╟─25c072be-7ccd-11eb-06bf-87a610a9b61d
# ╟─b720c7f6-7ccd-11eb-2322-ef87a5dca4a0
# ╟─baae04d0-7cd5-11eb-16e5-a53365c4294e
# ╟─73701676-7cd5-11eb-3643-930177ea6366
# ╟─97b9e874-7cd5-11eb-0e42-378e68cfd22c
# ╟─7bbce1ac-7cdc-11eb-189a-07e6e7026b7c
# ╟─d76b3cbe-7cd0-11eb-2870-c30481233d45
# ╠═d8e1f3b0-7cdc-11eb-3119-09f90cb48a68
# ╟─e973b5f4-7ccf-11eb-07e9-79ee89d458f4
# ╟─776ad346-7cd1-11eb-01fd-4300a85eb631
# ╟─4a0daf90-7cd1-11eb-1fa5-a5e0f60e860b
# ╟─b174ece0-7cd2-11eb-0b89-41604cdd9d52
# ╟─bba210be-7cd2-11eb-0440-1b471e2c8a2d
# ╟─93377306-7cdc-11eb-0c45-4982f8a45c77
# ╟─678019c8-7cf9-11eb-07d9-5be88346cc3c
# ╟─f6b075b4-7cdd-11eb-1029-53dff62c68e7
# ╟─fd64874c-7cdd-11eb-154d-8998a75f101a
# ╟─10162afa-7ce1-11eb-20f3-cf7ce3a08761
# ╟─6b57428e-7ce2-11eb-22aa-b79e0005e16f
# ╟─e897cee0-7ce3-11eb-19c7-a7aa0cea3c2b
# ╟─2fad8aea-7ce4-11eb-36d5-23ef4daee43c
# ╟─38fef93c-7ce4-11eb-3269-4fbf1a3e498e
# ╟─6629ee92-7ce4-11eb-362a-5b0052246896
# ╟─c17add8c-7d94-11eb-0a71-c9b04e4cc107
# ╟─510521fc-7d99-11eb-3765-394921866646
# ╟─f9522c12-7d92-11eb-0ee7-d9b64022c9d5
# ╟─4d81e9dc-7d93-11eb-1298-bb7af5e8a42f
# ╟─98248848-7d94-11eb-0fa5-85157d0b5781
# ╟─a424c946-7d94-11eb-3faf-ed146b509985
# ╟─d86299a8-7da4-11eb-2956-4be178d21a70
# ╟─aa48b0e4-7d94-11eb-3a3a-29267936dd62
# ╟─dd307522-7d95-11eb-0b0b-f1218e06c86e
# ╟─72a19b7e-7d99-11eb-21b6-ef4028870601
# ╟─d6f6a4c0-7da3-11eb-3e96-1bbcd1392e31
# ╟─76e48cb8-7da4-11eb-1012-d1dc6f71cf38
# ╟─9c2da05e-7da4-11eb-328f-191f38231c6e
# ╟─5aff27c2-7da6-11eb-1593-1341c2500fe9
# ╟─46407cac-7db5-11eb-11fe-b551c616dea1
# ╟─fdf5ab24-80bf-11eb-132e-9d58cee9be1f
