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

# ╔═╡ 3674a622-823b-11eb-3991-d5771010237b
using Pkg; Pkg.status()

# ╔═╡ c456b902-7959-11eb-03ba-dd14a2cd5758
begin
	using Revise, PlutoUI, CoordinateTransformations, StaticArrays, Rotations, Viznet, Compose
	# left right layout
	function leftright(a, b; width=600)
		HTML("""
<style>
table.nohover tr:hover td {
   background-color: white !important;
}</style>
			
<table width=$(width)px class="nohover" style="border:none">
<tr>
	<td>$(html(a))</td>
	<td>$(html(b))</td>
</tr></table>
""")
	end
	
	# up down layout
	function updown(a, b; width=nothing)
		HTML("""<table class="nohover" style="border:none" $(width === nothing ? "" : "width=$(width)px")>
<tr>
	<td>$(html(a))</td>
</tr>
<tr>
	<td>$(html(b))</td>
</tr></table>
""")
	end
	
	function highlight(str)
		HTML("""<span style="background-color:yellow">$(str)</span>""")
	end
end;

# ╔═╡ 5bb40ad6-7b33-11eb-0b31-63d5e47fa0e7
using TropicalNumbers,  		# tropical number type
		LightGraphs,			# graph operations
		Random,
    	SimpleTensorNetworks  	# tensor network contraction

# ╔═╡ 94b870d2-8235-11eb-33e7-35bf5132efd6
using Profile

# ╔═╡ 121b4926-7aba-11eb-30e1-7b8edd4f0166
html"""<h1>Tropical tensor networks for solving spin glasses</h1>
<p><big>Jinguo Liu</big></p>
"""

# ╔═╡ 92065f9d-422e-455f-bff2-f442ccd6043a
md"""
1. What is a tropical tensor network,
2. How to use a tropical tensor network to find the spin glass ground state,
3. How to use a tropical tensor network to count the spin glass ground state degeneracy,
"""

# ╔═╡ 9273e259-a25a-46a4-b0f8-62f37f62c263
html"""<button onclick="present()">present</button>"""

# ╔═╡ 2c3f2fd6-93ea-4fd7-9664-cffd10db16b4
html"""
<script>
document.body.style.cursor = "pointer";
</script>
"""

# ╔═╡ 400de6cf-3ffe-4bec-844d-775c490a0665
md"""
## Spinglass problem
"""

# ╔═╡ fd0f0167-8040-4f47-91ba-a11ff54ec88f
md"You invited 8 friends for dinner. However, some of your friends do not like each other (connected red lines)."

# ╔═╡ 883171ba-470b-4cff-832f-6c409a6de616
let
	tb = textstyle(:default, fontsize(10))
	tb2 = textstyle(:default, fontsize(5))
	xs = map(x->(x[1]-0.05, x[2]), [(0.1, 0.2), (0.1, 0.8), (0.35, 0.8), (0.35, 0.2), (0.6, 0.2), (0.85, 0.2), (0.6, 0.8), (0.85, 0.8)])
	animals = ["🐄", "🐬", "🐫", "🐧", "🐠", "🐢", "🐘", "🐒", "🐍"]
	edges = [((1,2), true), ((2,3), false), ((3,4), true), ((4,5), false), ((5,6), true), ((6,7), true), ((7,8), true), ((1,3), false), ((5,8), true)]
	eb1 = bondstyle(:default, stroke("red"))
	eb2 = bondstyle(:default, stroke("blue"))
	nb = nodestyle(:default, fill("white"), r=0.05)
	Compose.set_default_graphic_size(14cm, 6cm)
	canvas() do
		for i=1:length(xs)
			tb >> (xs[i], animals[i])
		end
		for ((i,j), c) in edges
			#(c ? eb1 : eb2) >> (xs[i], xs[j])
			eb1 >> (xs[i], xs[j])
		end
		for i=1:length(xs)
			nb >> (xs[i], animals[i])
		end
		#eb1 >> ((0.85, 0.4), (0.95, 0.4))
		#eb2 >> ((0.85, 0.6), (0.95, 0.6))
		#tb2 >> ((0.9, 0.45), "like")
		#tb2 >> ((0.9, 0.65), "dislike")
	end
end

# ╔═╡ 1c0136d1-89a2-456c-bd1c-9988a35f161f
md"You need to fit your friends into two tables, so that people hate each other are not on the same table."

# ╔═╡ 7bdf517e-79ff-11eb-38a3-49c02d94d943
md"## The Song Shan Lake Spring School (SSSS) Challenge"

# ╔═╡ 89d737b3-e72e-4d87-9ade-466a84491ac8
md"In 2019, Lei Wang, Pan Zhang, Roger and me released a challenge in the Song Shan Lake Spring School, the one gives the largest number of solutions to the challenge quiz can take a macbook home ([@LinuxDaFaHao](https://github.com/LinuxDaFaHao)). Students submitted many [solutions to the problem](https://github.com/QuantumBFS/SSSS/blob/master/Challenge.md). The second part of the quiz is"

# ╔═╡ a843152e-93e6-11eb-365f-2bd3ff0cf096
md"""
θ = $(@bind θ2 Slider(0.0:0.01:π; default=0.5))

ϕ = $(@bind ϕ2 Slider(0.0:0.01:2π; default=0.3))
"""

# ╔═╡ 88e14ef2-7af1-11eb-23d6-b34b1eff8f87
md"""
In the $(highlight("Buckyball")) structure as shown in the figure, we attach an ising spin ``s_i=\pm 1`` on each vertex. The neighboring spins interact with an $(highlight("anti-ferromagnetic")) coupling of unit strength. Count the $(highlight("degeneracy")) of configurations that minimizes the energy
```math
E(\{s_1,s_2,\ldots,s_n\}) = \sum_{i,j \in edges}s_i s_j
```
"""

# ╔═╡ 3221a326-7a17-11eb-0fe6-f75798a411b9
md"""# It is can be represented as the tensor network contraction
"""

# ╔═╡ e383103e-c956-4884-9c59-3e171b5bc11d
md"""**A tensor networ contraction is a $(highlight("generalization of matrix multiplication")), it is widely used in physics.**"""

# ╔═╡ 3208fd8a-7a17-11eb-35ce-4d6b141c1aff
md"
```math
Y[i,j] := \sum_k A[i,k] \times B[k,j]
```
"

# ╔═╡ 32116a92-7a17-11eb-228f-0713510d0348
let
	Compose.set_default_graphic_size(15cm, 10/3*cm)
	sq = nodestyle(:square; r=0.08)
	eb = bondstyle(:line)
	tb = textstyle(:default, fontsize(25px))
	tb2 = textstyle(:default, fontsize(40px), fill("white"))
	y0 = 0.15
	x = (0.3, y0)
	y = (0.7, y0)
	img = canvas() do
		sq >> x
		sq >> y
		eb >> (x, y)
		eb >> (x, (0.0, y0))
		eb >> (x, (1.0, y0))
		tb >> ((0.1, y0+0.05), "i")
		tb >> ((0.9, y0+0.05), "j")
		tb >> ((0.5, y0+0.05), "k")
		tb2 >> (x, "A")
		tb2 >> (y, "B")
	end
	Compose.compose(context(0.38, 0.0, 1/1.5^2, 2.0), img)
end


# ╔═╡ 1af9b822-4239-4ac7-bc64-801a3461d9e1
md"""

* matrices -> tensors
* two arguments -> multiple arguments

```math
Y[n] := \sum_{i,j,k,l,m} A[i,l] \times B[i,j] \times C[j,k,n] \times D[k,l,m] \times E[m]
```
"""

# ╔═╡ 32277c3a-7a17-11eb-3763-af68dbb81465
let
	Compose.set_default_graphic_size(14cm, 7cm)
	sq = nodestyle(:square; r=0.07)
	wb = nodestyle(:square, fill("white"); r=0.04)
	eb = bondstyle(:line)
	tb = textstyle(:default, fontsize(25px))
	tb2 = textstyle(:default, fontsize(30px), fill("white"))
	x0 = 0.15
	x1 = 0.65
	y0 = 0.35
	y1 = 0.8
	x3 = 0.9
	y3 = 0.1
	a = (x0, y0)
	b = (x0, y1)
	c = (x1, y1)
	d = (x1, y0)
	e = (x3, y3)
	img = canvas() do
		for (loc, label) in [(a, "A"), (b, "B"), (c, "C"), (d, "D"), (e, "E")]
			sq >> loc
			tb2 >> (loc, label)
		end
		for (edge, label) in [((a, b), "i"), ((b, c), "j"), ((c, d), "k"), ((a, d), "l"), ((d,e), "m"), ((c, (0.9, 0.55)), "n")]
			eb >> edge
			wb >> ((edge[1] .+ edge[2]) ./ 2)
			tb >> ((edge[1] .+ edge[2]) ./ 2, label)
		end
	end
	Compose.compose(context(.38, 0, .5, 1), img)
end

# ╔═╡ 2c294933-1425-4e80-84f8-80fe73b2b03a
md"enumerate over internal degree of freedoms, sum over the product of elements."

# ╔═╡ a7363a47-83b6-458a-95dc-448f32d4ef4f
md"A Tropical tensor network is a tensor network with elements having **Tropical algebra**"

# ╔═╡ d0b54b76-7852-11eb-2398-0911380fa090
md"""

```math
\begin{align}
&a ⊕ b = \max(a, b)\\
&a ⊙ b = a + b
\end{align}
```
"""

# ╔═╡ 211911da-7a18-11eb-12d4-65b0dec4b8dc
md"
```math
\begin{align}
\cancel{Y[n] := \sum_{i,j,k,l,m} A[i,l] \times B[i,j] \times C[j,k,n] \times D[k,l,m] \times E[m]}\\

Y[n] := \max_{i,j,k,l,m} (A[i,l] + B[i,j] + C[j,k,n] + D[k,l,m] + E[m])
\end{align}
```
"

# ╔═╡ 31b975b8-690d-41a0-b1a4-dcbf16a23517
md"""
The spinglass wants to get maximum over the sum.
```math
-E_G = \max_{\{s_1,s_2,\ldots,s_n\}}\left(-\sum_{ij \in edges}J_{ij}s_i s_j\right)
```
"""

# ╔═╡ cc43da91-bd5d-4277-8876-69653e14486f
md"# Wrap up"

# ╔═╡ c92e5039-097b-4b95-96d7-b4d470c0ab21
md"""
* The tensor network is a generalization of matrix multiplication,
* A tropical tensor network is a tensor network with tropical numbers inside,
* Tropical numbers are numbers with Tropical algebra that `* → +` and `+ → max`
* Solving spin glass ground state can be mapped to the evaluation of a tropical tensor network.
"""

# ╔═╡ 5f6cfe59-4d59-4ee6-a32c-712e2a67faa5
md"""
## Let's get our hands dirty!
"""

# ╔═╡ 5d956bd2-8472-47dc-909a-7930612e66de
md"##### Tropical algebra"

# ╔═╡ af13e090-7852-11eb-21ae-8b94f25f1a4f
Tropical(2.0) * Tropical(3.0)

# ╔═╡ d770f232-7864-11eb-0e9a-81528e359d39
Tropical(5.0) + Tropical(3.0)

# ╔═╡ 7a88b8f0-6f22-4992-931b-54e7f50742f0
zero(TropicalF64)

# ╔═╡ 8767709c-478d-4fe5-ad6b-a280b9443460
one(TropicalF64)

# ╔═╡ 7b618d71-2b56-42ba-9c3a-5840f4f0d481
md"##### Mapping a spin glass to a Tropical tensor network"

# ╔═╡ b52ead96-7a2a-11eb-334f-e5e5ff5867e3
let
	B = md"""
```math
T_{e_{i,j}} = \begin{bmatrix}-J_{ij} & J_{ij} \\J_{ij} & -J_{ij}\end{bmatrix}
```
"""
	A = md"""
```math
(T_{v_i})_{s_i s_i' s_i''} = \begin{cases}
 0, & s_i = s_i' =s_i'''\\
 -\infty, &otherwise
\end{cases}
```
"""
	leftright(updown(html"<p align='center'>vertex tensor</p>", A), updown(html"<p align='center'>edge tensor</p>", B))
end

# ╔═╡ 064c14b0-73db-4bcf-9b64-a0e34c642f97
md"The contraction gives you the maximum negative energy"

# ╔═╡ 16c2b86c-db2d-4408-a6ae-e698fdd495c7
md"""
```math
\begin{align}
&\max_{\{s_1,s_2\ldots s_n\}} \sum_{i\in vertices}(T_{v})_{s_is_i s_i} + \sum_{ij\in edges}(T_{e_{ij}})_{s_is_j}\\
=&\max_{\{s_1,s_2,\ldots,s_n\}}\left(-\sum_{ij \in edges}J_{ij}s_i s_j\right)
\end{align}
```
"""

# ╔═╡ 624f57db-7f07-4281-a547-d229b9a8413a
function ising_bondtensor(::Type{T}, J) where T
	e = T(J)
	e_ = T(-J)
	[e e_; e_ e]
end

# ╔═╡ 8692573b-ae74-4f24-8bc3-57c7b85a7034
ising_bondtensor(TropicalF64, 2.0)

# ╔═╡ b975680f-0b78-4178-861f-5da6d10327e4
function ising_vertextensor(::Type{T}, n::Int) where T
	res = zeros(T, fill(2, n)...)
	res[1] = one(T)
	res[end] = one(T)
	return res
end

# ╔═╡ e0939f0e-d9f5-4ec6-937d-66367fb40fb6
ising_vertextensor(TropicalF64, 3)

# ╔═╡ 695e405c-786d-11eb-0a6e-bb776d9626ad
md"
# Towards solving the challenge
"

# ╔═╡ 1bb36c52-a171-4993-ac86-2250e1e87a01
md"It corresponds to the following four processes of concatenating and comparing configrations on graphs (or tensor networks)."

# ╔═╡ 43101224-7ac5-11eb-104c-0323cf1813c5
md"The zero and one elements are defined as"

# ╔═╡ 792df1aa-7a23-11eb-2991-196336246c43
zero(CountingTropical{Float64})

# ╔═╡ 8388305c-7a23-11eb-1588-79c3c6ce9db9
one(CountingTropical{Float64})

# ╔═╡ 5a5d4de6-7895-11eb-15c6-bda7a4342002
# returns atom locations
function fullerene()
	φ = (1+√5)/2
	res = NTuple{3,Float64}[]
	for (x, y, z) in ((0.0, 1.0, 3φ), (1.0, 2 + φ, 2φ), (φ, 2.0, 2φ + 1.0))
		for (α, β, γ) in ((x,y,z), (y,z,x), (z,x,y))
			for loc in ((α,β,γ), (α,β,-γ), (α,-β,γ), (α,-β,-γ), (-α,β,γ), (-α,β,-γ), (-α,-β,γ), (-α,-β,-γ))
				if loc ∉ res
					push!(res, loc)
				end
			end
		end
	end
	return res
end;

# ╔═╡ 9b1dc21a-7896-11eb-21f6-bfe9b4dc9ccf
let
	tb = textstyle(:default)
	Compose.set_default_graphic_size(12cm, 8cm)
	cam_position = SVector(0.0, 0.0, 0.5)
	rot = RotY(θ2)*RotX(ϕ2)
	cam_transform = PerspectiveMap() ∘ inv(AffineMap(rot, rot*cam_position))
	Nx = Ny = Nz = 4
	nb = nodestyle(:circle; r=0.01)
	eb = bondstyle(:default; r=0.01)
	x(i,j,k) = cam_transform(SVector(i,j,k) .* 0.03).data
	fl = fullerene()
	fig = canvas() do
		for (i,j,k) in fl
			nb >> x(i,j,k)
			for (i2,j2,k2) in fl
				(i2-i)^2+(j2-j)^2+(k2-k)^2 < 5.0 && eb >> (x(i,j,k), x(i2,j2,k2))
			end
		end
		tb >> ((0.5, 0.0), "60 vertices\n90 edges")
	end
	img = Compose.compose(context(0.4,0.5, 1.0, 1.5), fig)
	img
end

# ╔═╡ acbdbfa8-97bc-4194-81b9-4a203e7f8919
let
	tb = textstyle(:default)
	mb = textstyle(:math)
	Compose.set_default_graphic_size(14cm, 8cm)
	cam_position = SVector(0.0, 0.0, 0.5)
	rot = RotY(θ2)*RotX(ϕ2)
	cam_transform = PerspectiveMap() ∘ inv(AffineMap(rot, rot*cam_position))
	Nx = Ny = Nz = 4
	nb1 = nodestyle(:circle; r=0.01)
	nb2 = nodestyle(:square; r=0.01)
	eb = bondstyle(:default; r=0.01)
	x(i,j,k) = cam_transform(SVector(i,j,k) .* 0.03).data
	fl = fullerene()
	fig = canvas() do
		for (i,j,k) in fl
			nb1 >> x(i,j,k)
			for (i2,j2,k2) in fl
				if (i2-i)^2+(j2-j)^2+(k2-k)^2 < 5.0 && (i<=i2 && (i,j,k) != (i2,j2,k2))
					eb >> (x(i,j,k), x(i2,j2,k2))
					nb2 >> x((i+i2)/2,(j+j2)/2,(k+k2)/2)
				end
			end
		end
		nb1 >> (0.4,-0.1)
		eb >> ((0.35,-0.1), (0.45, -0.1))
		nb2 >> (0.4,0.0)
		eb >> ((0.35,-0.0), (0.45, -0.0))
		tb >> ((0.54, 0.0), "edge tensor")
		tb >> ((0.55, -0.1), "vertex tensor")
	end
	img = Compose.compose(context(0.3,0.5, 1.2/1.4, 1.5), fig)
	img
end

# ╔═╡ b6560404-7b2d-11eb-21d7-a1e55609ebf7
# the positions of fullerene atoms
c60_xy = fullerene();

# ╔═╡ 6f649efc-7b2d-11eb-1e80-53d84ef98c13
# find edges: vertex pairs with square distance smaller than 5.
c60_edges = [(i=>j) for (i,(i2,j2,k2)) in enumerate(c60_xy), (j,(i1,j1,k1)) in enumerate(c60_xy) if i<j && (i2-i1)^2+(j2-j1)^2+(k2-k1)^2 < 5.0];

# ╔═╡ 20125640-79fd-11eb-1715-1d071cc6cf6c
md"The resulting tensor network contains 90 edge tensors and 60 vertex tensors."

# ╔═╡ 29e59f11-7540-4616-a00a-6719f861ad19
function build_tensornetwork(; vertices, vertex_arrays, edges, edge_arrays)
	TensorNetwork([
	# vertex tensors
	[LabeledTensor(vertex_arrays[i], [(j, v==e[1]) for (j, e) in enumerate(edges) if v ∈ e]) for (i, v) in enumerate(vertices)]...,
	# bond tensors
	[LabeledTensor(edge_arrays[j], [(j, true), (j, false)]) for j=1:length(edges)]...
])
end

# ╔═╡ c26b5bb6-7984-11eb-18fe-2b6a524f5c85
c60_tnet = let
	T = CountingTropical{Float64}
	build_tensornetwork(
		vertices=1:60,
		vertex_arrays = [ising_vertextensor(T, 3) for j=1:length(c60_xy)],
		edges = c60_edges,
		edge_arrays = [ising_bondtensor(T, -1.0) for i = 1:length(c60_edges)]
	)
end;

# ╔═╡ 698a6dd0-7a0e-11eb-2766-1f0baa1317d2
md"Then we find a proper contraction order by greedy search"

# ╔═╡ 020cfb20-8228-11eb-2ee9-6de0fc7700b1
md"Seed for greedy search = $(@bind seed Slider(1:10000; show_value=true, default=42))"

# ╔═╡ ae92d828-7984-11eb-31c8-8b3f9a071c24
tcs, scs, c60_trees = (Random.seed!(seed); trees_greedy(c60_tnet; strategy="min_reduce"));

# ╔═╡ 2b899624-798c-11eb-20c4-fd5523f7abff
md"The resulting contraction order produces time complexity = $(round(log2sumexp2(tcs); sigdigits=4)), space complexity = $(round(maximum(scs); sigdigits=4))"

# ╔═╡ 01e40898-c1c8-481a-b149-9b1bebb00043
md"""
Tropical algebra does the degeneracy counting
```math
\begin{align}
(n_1, c_1) \odot (n_2,c_2) &= (n_1 + n_2, c_1\cdot c_2)\\
    (n_1, c_1)\oplus (n_2, c_2) &= \begin{cases}
 (n_1\oplus n_2, \, c_1 + c_2 ) & \text{if $n_1 = n_2$} \\
 (n_1\oplus n_2,\, c_1 ) & \text{if $n_1>n_2$} \\
 (n_1\oplus n_2,\, c_2 )& \text{if $n_1 < n_2$}
 \end{cases}.
\end{align}
```
"""

# ╔═╡ ade34905-5a61-4f71-b347-e02fab120b5d
let
	Compose.set_default_graphic_size(15cm, 10cm)
	a = 0.1
	b = 0.05
	nodes = [(-a, -b), (a, -b), (a, b), (-a, b)]
	nb = Compose.compose(context(), polygon(nodes), stroke("black"), fill("white"))
	tb = textstyle(:default)
	tt = Compose.compose(context(), text(0.0, 0.0, ""))
	x_title = 0.1
	canvas() do
		for (y_1, op, title) in zip(
				[0.2, 0.4, 0.6, 0.8],
				["⊙", "⊕", "⊕", "⊕"],
				[
				("concatenate best configurations of two subgraphs", "value = n₁\ndegeneracy = c₁", "value = n₂\ndegeneracy = c₂", "value = n₁ + n₂\ndegeneracy = c₁ * c₂"),
				("compare two configurations: case n₁ == n₂", "value = n\ndegeneracy = c₁", "value = n\ndegeneracy = c₂", "value = n\ndegeneracy = c₁ + c₂"),
				("compare two configurations: case n₁ > n₂", "value = n₁\ndegeneracy = c₁", "value = n₂\ndegeneracy = c₂", "value = n₁ \ndegeneracy = c₁"),
				("compare two configurations: case n₁ < n₂", "value = n₁\ndegeneracy = c₁", "value = n₂\ndegeneracy = c₂", "value = n₂\ndegeneracy = c₂")
				]
			)
			x = (0.2, y_1)
			y = (0.5, y_1)
			z = (0.8, y_1)
			nb >> x
			nb >> y
			nb >> z
			tt >> ((x_title, y_1-0.08), title[1])
			tb >> (x, title[2])
			tb >> (y, title[3])
			tb >> ((x .+ y) ./ 2, op)
			tb >> ((z .+ y) ./ 2, "=")
			tb >> (z, title[4])
		end
	end
end

# ╔═╡ 8522456a-823c-11eb-3cc1-fb720f1cc470
SimpleTensorNetworks.contract(c60_tnet, c60_trees[]).array[]

# ╔═╡ 1c4b19d2-7b30-11eb-007b-ab03052b22d2
md"If you see a 16000 in the counting field, congratuations! The greedy contraction order can be visualized by dragging the slider (if you run it on your local host)"

# ╔═╡ 58e38656-7b2e-11eb-3c70-25a919f9926a
md"contraction step = $(@bind nstep_c60 Slider(0:length(c60_tnet); show_value=true, default=60))"

# ╔═╡ 12740186-7b2f-11eb-35e4-01e6f9ffbb4d
c60_contraction_masks = let
	function contraction_mask(tnet, tree)
		contraction_mask!(tnet, tree, [zeros(Bool, length(tnet))])
	end
	function contraction_mask!(tnet, tree, results)
		if tree isa Integer
			res = copy(results[end])
			@assert res[tree] == false
			res[tree] = true
			push!(results, res)
		else
			contraction_mask!(tnet, tree.left, results)
			contraction_mask!(tnet, tree.right, results)
		end
		return results
	end
	contraction_mask(c60_tnet, c60_trees[])
end;

# ╔═╡ c1c74e70-7b2c-11eb-2f26-21f54ad00fb2
let
	θ2 = 0.5
	ϕ2 = 0.8
	mask = c60_contraction_masks[nstep_c60+1]
	Compose.set_default_graphic_size(12cm, 12cm)
	cam_position = SVector(0.0, 0.0, 0.5)
	rot = RotY(θ2)*RotX(ϕ2)
	cam_transform = PerspectiveMap() ∘ inv(AffineMap(rot, rot*cam_position))
	Nx = Ny = Nz = 4
	tb = textstyle(:default)
	nb1 = nodestyle(:circle, fill("red"); r=0.01)
	nb2 = nodestyle(:circle, fill("white"), stroke("black"); r=0.01)
	eb = bondstyle(:default; r=0.01)
	x(i,j,k) = cam_transform(SVector(i,j,k) .* 0.03).data
	
	fig = canvas() do
		for (s, (i,j,k)) in enumerate(c60_xy)
			(mask[s] ? nb1 : nb2) >> x(i,j,k)
		end
		for (i, j) in c60_edges
			eb >> (x(c60_xy[i]...), x(c60_xy[j]...))
		end
		nb1 >> (-0.1, 0.45)
		tb >> ((-0.0, 0.45), "contracted")
		nb2 >> (-0.1, 0.50)
		tb >> ((-0.0, 0.50), "remaining")
	end
	Compose.compose(context(0.5,0.35, 1.0, 1.0), fig)
end

# ╔═╡ 4c137484-7b30-11eb-2fb1-190d8beebbc3
md"""Since the complexity of tensor contraction is exponential to the number of legs involved, *"what is the optimal contraction order"* becomes one of the most important issues in tensor network contraction. The greedy algorithm we used here is efficient but not optimal. Finding the optimal contraction order itself is NP-hard.
"""

# ╔═╡ e302bd1c-7ab5-11eb-03f6-69dcbb817354
md"## Resources

* Papers and notebooks
    * [Phys. Rev. Lett. 126, 090506 (2021)](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.126.090506), Jin-Guo Liu, Lei Wang, and Pan Zhang
    * [notebook](https://giggleliu.github.io/notebooks/tropical/tropicaltensornetwork.html)
* Learn Tensor networks
    * [Tensor network website](https://tensornetwork.org/)
    * How to find a good tensor contraction order?
        * [Contracting Arbitrary Tensor Networks: General Approximate Algorithm and Applications in Graphical Models and Quantum Circuit Simulations](https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.125.060503)


* How to compute tropical matrix multiplication efficiently?
    * [TropicalGEMM](https://github.com/TensorBFS/TropicalGEMM.jl),
"

# ╔═╡ 442bcb3c-7940-11eb-18e5-d3158b74b1dc
html"""
<p>Learn more about spin glasses and other hard problems</p>
<table style="border:none">
<tr>
	<td rowspan=4>
	<img src="https://images-na.ssl-images-amazon.com/images/I/51QttTd6JLL._SX351_BO1,204,203,200_.jpg" width=200px/>
	</td>
	<td rowspan=1 align="center">
	<big>The Nature of Computation</big><br><br>
	By <strong>Cristopher Moore</strong>
	</td>
</tr>
<tr>
	<td align="center">
	<strong>Section 5</strong>
	<br><br>Who is the hardest one of All?
	<br>NP-Completeness
	</td>
</tr>
<tr>
	<td align="center">
	<strong>Section 13</strong>
	<br><br>Counting, sampling and statistical physics
	</td>
</tr>
</table>
"""

# ╔═╡ Cell order:
# ╟─c456b902-7959-11eb-03ba-dd14a2cd5758
# ╟─121b4926-7aba-11eb-30e1-7b8edd4f0166
# ╟─92065f9d-422e-455f-bff2-f442ccd6043a
# ╟─9273e259-a25a-46a4-b0f8-62f37f62c263
# ╟─2c3f2fd6-93ea-4fd7-9664-cffd10db16b4
# ╟─400de6cf-3ffe-4bec-844d-775c490a0665
# ╟─fd0f0167-8040-4f47-91ba-a11ff54ec88f
# ╟─883171ba-470b-4cff-832f-6c409a6de616
# ╟─1c0136d1-89a2-456c-bd1c-9988a35f161f
# ╟─7bdf517e-79ff-11eb-38a3-49c02d94d943
# ╟─89d737b3-e72e-4d87-9ade-466a84491ac8
# ╟─a843152e-93e6-11eb-365f-2bd3ff0cf096
# ╟─9b1dc21a-7896-11eb-21f6-bfe9b4dc9ccf
# ╟─88e14ef2-7af1-11eb-23d6-b34b1eff8f87
# ╟─3221a326-7a17-11eb-0fe6-f75798a411b9
# ╟─e383103e-c956-4884-9c59-3e171b5bc11d
# ╟─3208fd8a-7a17-11eb-35ce-4d6b141c1aff
# ╟─32116a92-7a17-11eb-228f-0713510d0348
# ╟─1af9b822-4239-4ac7-bc64-801a3461d9e1
# ╟─32277c3a-7a17-11eb-3763-af68dbb81465
# ╟─2c294933-1425-4e80-84f8-80fe73b2b03a
# ╟─a7363a47-83b6-458a-95dc-448f32d4ef4f
# ╟─d0b54b76-7852-11eb-2398-0911380fa090
# ╟─211911da-7a18-11eb-12d4-65b0dec4b8dc
# ╟─31b975b8-690d-41a0-b1a4-dcbf16a23517
# ╟─cc43da91-bd5d-4277-8876-69653e14486f
# ╟─c92e5039-097b-4b95-96d7-b4d470c0ab21
# ╟─5f6cfe59-4d59-4ee6-a32c-712e2a67faa5
# ╠═5bb40ad6-7b33-11eb-0b31-63d5e47fa0e7
# ╟─5d956bd2-8472-47dc-909a-7930612e66de
# ╠═af13e090-7852-11eb-21ae-8b94f25f1a4f
# ╠═d770f232-7864-11eb-0e9a-81528e359d39
# ╠═7a88b8f0-6f22-4992-931b-54e7f50742f0
# ╠═8767709c-478d-4fe5-ad6b-a280b9443460
# ╟─7b618d71-2b56-42ba-9c3a-5840f4f0d481
# ╟─acbdbfa8-97bc-4194-81b9-4a203e7f8919
# ╟─b52ead96-7a2a-11eb-334f-e5e5ff5867e3
# ╟─064c14b0-73db-4bcf-9b64-a0e34c642f97
# ╟─16c2b86c-db2d-4408-a6ae-e698fdd495c7
# ╠═624f57db-7f07-4281-a547-d229b9a8413a
# ╠═8692573b-ae74-4f24-8bc3-57c7b85a7034
# ╠═b975680f-0b78-4178-861f-5da6d10327e4
# ╠═e0939f0e-d9f5-4ec6-937d-66367fb40fb6
# ╟─695e405c-786d-11eb-0a6e-bb776d9626ad
# ╟─1bb36c52-a171-4993-ac86-2250e1e87a01
# ╟─43101224-7ac5-11eb-104c-0323cf1813c5
# ╠═792df1aa-7a23-11eb-2991-196336246c43
# ╠═8388305c-7a23-11eb-1588-79c3c6ce9db9
# ╠═5a5d4de6-7895-11eb-15c6-bda7a4342002
# ╠═b6560404-7b2d-11eb-21d7-a1e55609ebf7
# ╠═6f649efc-7b2d-11eb-1e80-53d84ef98c13
# ╟─20125640-79fd-11eb-1715-1d071cc6cf6c
# ╠═29e59f11-7540-4616-a00a-6719f861ad19
# ╠═c26b5bb6-7984-11eb-18fe-2b6a524f5c85
# ╟─698a6dd0-7a0e-11eb-2766-1f0baa1317d2
# ╟─020cfb20-8228-11eb-2ee9-6de0fc7700b1
# ╠═ae92d828-7984-11eb-31c8-8b3f9a071c24
# ╟─2b899624-798c-11eb-20c4-fd5523f7abff
# ╠═3674a622-823b-11eb-3991-d5771010237b
# ╠═94b870d2-8235-11eb-33e7-35bf5132efd6
# ╟─01e40898-c1c8-481a-b149-9b1bebb00043
# ╟─ade34905-5a61-4f71-b347-e02fab120b5d
# ╠═8522456a-823c-11eb-3cc1-fb720f1cc470
# ╟─1c4b19d2-7b30-11eb-007b-ab03052b22d2
# ╟─58e38656-7b2e-11eb-3c70-25a919f9926a
# ╟─12740186-7b2f-11eb-35e4-01e6f9ffbb4d
# ╟─c1c74e70-7b2c-11eb-2f26-21f54ad00fb2
# ╟─4c137484-7b30-11eb-2fb1-190d8beebbc3
# ╟─e302bd1c-7ab5-11eb-03f6-69dcbb817354
# ╟─442bcb3c-7940-11eb-18e5-d3158b74b1dc
