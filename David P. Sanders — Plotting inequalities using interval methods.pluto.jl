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

# ╔═╡ 9223061d-c2ad-4d6b-b17d-85a424d050e6
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add([
        Pkg.PackageSpec(name="Plots", version="1"),
        Pkg.PackageSpec(name="ReversePropagation", version="0.1"),
        Pkg.PackageSpec(name="IntervalArithmetic", rev="5751634"), # branch dps/config
        Pkg.PackageSpec(name="Symbolics", version="0.1"),
        Pkg.PackageSpec(name="PlutoUI", version="0.7"),
        Pkg.PackageSpec(name="LaTeXStrings", version="1"),
        Pkg.PackageSpec(name="Pluto", rev="13a17f5"),
	])
    using Plots, ReversePropagation, IntervalArithmetic, Symbolics, PlutoUI, LaTeXStrings, Pluto
	IntervalArithmetic.configure!(directed_rounding=:fast, powers=:fast)
end

# ╔═╡ 3b38e24d-01dd-4eaa-9a57-186cbec7181f
using Symbolics: operation, value, arguments, toexpr

# ╔═╡ be75fc1c-393b-46c3-9a8a-605c028d5901
md"""
## Plotting inequalities using interval methods

### Author: [David P. Sanders](https://github.com/dpsanders)
"""

# ╔═╡ d63edc38-df0c-422a-8937-0819f1f7f040
md"""
Using [interval arithmetic](https://juliaintervals.github.io/) we can produce  plots of equations and inequalities that are guaranteed to be correct.

This notebook previews a work-in-progress rewrite of the [`IntervalConstraintProgramming.jl`](https://github.com/JuliaIntervals/IntervalConstraintProgramming.jl) package, using symbolic manipulation from the excellent [`Symbolics.jl`](https://github.com/JuliaSymbolics/Symbolics.jl) package.

To learn more about the theory behind the methods, please check out [these video presentations](https://juliaintervals.github.io/pages/explanations/videos/#calculating_with_sets_interval_methods_in_julia) with associated notebooks, as well as the references linked below.
"""

# ╔═╡ 4a4eb65a-8eb2-47f9-b4de-dc31bf0d6b6f
md"""
### Give it a try!
"""

# ╔═╡ f9920438-dc18-41e8-8286-d00e715f3789
md"""
Write an **equality** (`=`) or **inequality** (`≤` or `≥`) in the box below, involving the variables `x` and `y`. You may also use the parameters `a`, `b`, `c` and `d`. Try using functions like `exp`, `sin`, `cos` and `log`!
"""

# ╔═╡ 2b4a16c9-dc1e-474e-8ef3-3ad0f8849392
md"""
You can change the size of the input box. The box will go from $-h$ to $+h$ in the $x$ and $y$ directions:
"""

# ╔═╡ 409d5444-b8ae-4741-b9a5-5a6b5c0797c2
md"""
Move the `m` slider to control the fineness, $δ$, of the mesh in the plot. Avoid making it too small for complicated expressions, though!
"""

# ╔═╡ c414fd82-2c25-410e-a2b4-186af74a7794
md"""
h = $(@bind h Slider(0.1:0.1:10, default=5, show_value=true))
"""

# ╔═╡ 4622075d-cd78-412a-a995-ef1a71bba537
begin
	X = IntervalBox(-h..h, 2)
	
	md"The box $X$ = $(X)"
end

# ╔═╡ e82f9d4e-d2c2-4d79-a5d2-d42aa7de6478
md"""
Use an example from the dropdown, or edit this notebook to write your own!
"""

# ╔═╡ bc9709dc-8f97-4588-b071-ea806ba1dcbd
md"""
``a`` = $(@bind a Slider(-5:0.01:5, show_value=true, default=-0.5)) 
$(html"&nbsp;&nbsp;&nbsp;&nbsp;")
``b`` = $(@bind b Slider(-5:0.01:5, show_value=true, default=2))


``c`` = $(@bind c Slider(-5:0.01:5, show_value=true, default=2))
$(html"&nbsp;&nbsp;&nbsp;&nbsp;")
``d`` = $(@bind d Slider(-5:0.01:5, show_value=true, default=3))

"""

# ╔═╡ 76fa1f07-9546-4f89-ab15-f31306b2f30c
md"""
``m`` = $(@bind m Slider(-3:0.01:1, show_value=true, default=-1))
$(html"&nbsp;&nbsp;&nbsp;&nbsp;")
show boxes $(@bind show_boxes CheckBox(default=true)) 
$(html"&nbsp;&nbsp;&nbsp;&nbsp;")
show legend $(@bind show_legend CheckBox()) 

"""

# ╔═╡ b57cf5f7-ca6f-47f9-ba9b-108a36c041c5
begin
	δ = 10.0^m
	
	md"δ = $10^m$ = $(round(δ, digits=4))"
end

# ╔═╡ d4626e5c-9fdf-4ace-80c9-99f09abfe104
md"""
The symbolic expression is shown above the graph, after substituting in the numerical values of the parameters.
"""

# ╔═╡ 7d778956-2029-419b-a33f-2e70fd29450f
md"""
### Some code
"""

# ╔═╡ dcc23cff-79b5-4808-bc14-69b72b89a755
md"""
Here's the code to generate the plot; it's explained below.
"""

# ╔═╡ 6e46b81d-3cb8-47a4-9948-2f70696e6ab8
examples = [
	"a * x + y ≤ b",

	"a * x^2 + b * (y - c)^2 > d", 

	"a * x^3 + b * y^2 < c",

	"a + b*x*y + c*x^2 < d",

	"y^2 - a * x^2 ≥ b",
	
	"sin(x - b*y^2) < a",

	"y ≤ x * sin(a / (x-b))",

	"sin(x^2 + y^2) < cos(x * y)",

	"cos((b * y)^2) - sin(a * x) < 0.1",

	"(y - 5) * cos(4 * sqrt( (x-4)^2 + y^2 )) > x * sin(2 * sqrt( x^2 +y^2 ))",

	"x * cos(y) * cos(x*y) + y * cos(x) * cos(x*y) + x*y * cos(x) * cos(y) < 0.1"
	]

# ╔═╡ 0c1f44e2-f1b3-403e-9358-341fb1833bc7
md"""
### Select an expression...

$(@bind dropdown Select([s => s for s in examples], default="a + b*x*y + c*x^2 < d"))
"""

# ╔═╡ 08a43bcb-ad7d-4013-949b-a124392a9536
#= md"""
### ... and modify it here, or write your own!:

$(@bind s TextField( (50, 3), default="a + b*x*y + c*x^2 < d") )
""" =#
s = dropdown;

# ╔═╡ a3c0c064-506b-43ce-afd4-4e4ee897c034
md"""
## Constraints in the $x$--$y$ plane
"""

# ╔═╡ d585f87e-63d6-487c-a7dc-4c2dca15ca4d
md"""
How does this work? The technology mixes symbolic expressions, interval arithmetic and interval constraint propagation. It also works well in 3D, and in principle in any number of dimensions, although here we'll focus on 2D.
"""

# ╔═╡ 8d0e9542-8231-4af9-855b-5ea72c097ee9
md"""
Since we're working in 2D, let's make two symbolic variables $x$ and $y$:
"""

# ╔═╡ b0a03acd-3906-44c9-9614-c6c32459f2b6
vars = begin
	x = y = nothing # to make pluto understand
	
	@variables x y
end

# ╔═╡ 90d3eade-19fa-4e87-9e7b-8b3dce8bbd3f
md"""
We can now make expressions using these variables, for example the following inequality representing a **constraint**:
"""

# ╔═╡ 4c2577d3-15d9-4f7b-96b6-6dd23a013b92
ex = x^2 + y^2 ≤ 1

# ╔═╡ f12ad635-9dd5-4c7b-8168-806733657e83
begin
	md"""
	This defines a **constraint set** (or **feasible set**) $S$ in the plane, consisting of those $(x, y)$ pairs satisfying the constraint condition.
	"""
	
	md"""
	
	Interval constraint propagation is a technique that takes in a rectangular box $X$ and tries to reduce, or **contract** the box, by eliminating pieces of the box that it can prove, using interval arithmetic, do not lie inside the box.
	
	A **separator** returns three boxes: 
	
	- a boundary subbox: the intersection of `inner` and `outer`, which are pieces wherre we cannot decide whether they lie inside or outside $S$
	- an `inner` subbox: pieces lying *outside* $S$ may have been removed
	- an `outer` subbox: pieces lying *inside* $S$ may have been removed. 
	
	The algorithm used to do the contraction is the **forward--backward contractor**, also called HC4Revise, as implemented in [`ReversePropagation.jl`](https://github.com/dpsanders/ReversePropagation.jl), which also uses `Symbolics.jl`.
	
	"""
end

# ╔═╡ ba529560-fe47-435b-a459-082681571f62
md"""
### Example of a separator
"""

# ╔═╡ e652e1cd-2beb-4f82-a7ec-335fdc742077
md"""
Let's make a separator from the above expression:
"""

# ╔═╡ a72b53b3-2d3b-4ce6-9962-f564e8962e0e
md"""
The expression has been changed a little into a more canonical form:
"""

# ╔═╡ 6b4d0744-293b-411a-8b3d-9a73bcaab2bb
md"""
and the constraint has become an interval:
"""

# ╔═╡ b8b5829e-1545-41cb-b1e5-772c3ed5c038
md"""
Let's make an interval box in 2D:
"""

# ╔═╡ ccd556b2-2a7f-496b-bee9-cc30132dc2dd
X2 = (0.6..1.1) × (-0.1..0.4)

# ╔═╡ 7abb2e85-8b52-4474-8b40-584e3a481ad6
md"""
and apply the separator to it:
"""

# ╔═╡ 038cae8a-bf79-434d-a805-dde8a0ee0509
md"""
We see that the original box has indeed been split into three pieces. The left and right pieces are guaranteed to be entirely contained in $S$, and entirely outside $S$, respectively. For clarity we have only drawn the boundary of $S$ in this picture.
"""

# ╔═╡ 847c6fdc-0a48-48f1-8965-9facabf8c2c6
md"""
## Paving space
"""

# ╔═╡ ce74d395-b1db-427e-b7e6-faa3ab326e78
md"""
We can now repeatedly bisect space to exhaustively check each subbox, in order to find **inner** and **outer** approximations of the set $S$ defined by the constraint expression, called **pavings**. We need to specify a minimum size ϵ for the boxes.

The `pave` function returns two vectors of boxes: those which are inside, and those which are unknown (on or near the boundary of $S$).

Move the slider to refine the paving -- but be careful with small values of ϵ, which can take a long time to finish running!
"""

# ╔═╡ 7744c2da-ef13-4e1d-ad82-045b1280f773
md"""
n = $(@bind n Slider(-2:0.1:0, default=1, show_value=true))
"""

# ╔═╡ 74e4354d-cabd-4fc1-b8e3-eb19b7f71bcd
ϵ = 10.0^n

# ╔═╡ 9bbb6f23-c8f4-4bed-b56b-8b0fb0522acb
md"""
## References
"""

# ╔═╡ f58bd7ca-bb23-4e9e-b33f-dbb178c16083
md"""
- *Applied Interval Analysis*, Luc Jaulin, Michel Kieffer, Olivier Didrit, Eric Walter (2001)
- Introduction to the Algebra of Separators with Application to Path Planning, Luc Jaulin and Benoît Desrochers, *Engineering Applications of Artificial Intelligence* **33**, 141–-147 (2014). <https://www.sciencedirect.com/science/article/abs/pii/S0952197614000864>
- Reliable two-dimensional graphing methods for mathematical formulae with two free variables, Jeff Tupper, SIGGRAPH '01: Proceedings of the 28th annual conference on Computer graphics and interactive techniques, 77--86. <https://doi.org/10.1145/383259.383267>
"""

# ╔═╡ f44e0400-ac76-4717-af4f-4eda130dbe7a
md"""
## Appendix: The Code
"""

# ╔═╡ 978b2396-3183-4cbb-aa55-ed76687ea215
md"""
### Contractor
"""

# ╔═╡ 1fde9cd0-c0a3-4d4c-822c-278f671d3e44
begin
	struct Contractor{V, E, CC}
	    vars::V
	    ex::E
	    contractor::CC
	end
	
	Contractor(ex, vars) = Contractor(vars, ex, forward_backward_contractor(ex, vars))
	
	(CC::Contractor)(X, constraint=interval(0.0)) = IntervalBox(CC.contractor(X, constraint)[1])
	
	Contractor
end

# ╔═╡ 83fa8da1-bbb3-4f91-a5cc-c81834749c58


# ╔═╡ 808319fe-be49-4278-b9c6-fc1bbf2c7954
md"""
### Separator
"""

# ╔═╡ 5126ba06-bee9-4ae8-9358-35045fcd0fe0
make_function(ex, vars) = eval(build_function(ex, vars))

# ╔═╡ 242fe373-aa92-4fcc-8347-1a0172c3a70d
md"""
### Pave
"""

# ╔═╡ 5688a092-3a57-4ca9-91a5-4c25549602b0
function pave(X, C::Contractor, ϵ=0.1)
    working = [X]
    paving = typeof(X)[]

    while !isempty(working)
        X = pop!(working)
		
		if isempty(X)
            continue
        end

        X = C(X, 0..0)

		if isempty(X)
            continue
        end

        if diam(X) < ϵ
            push!(paving, X)
            continue 
        end

        push!(working, bisect(X)...)

    end

    return paving
end

# ╔═╡ b3e538a2-06ce-4ee4-a413-c0c6b36ec797
plot_options = Dict(:ratio=>1, :leg=>false, :alpha=>0.5, :size=>(500, 300), :lw=>0.3)

# ╔═╡ 72dd723a-a664-41a7-8361-3a51aeaa31ae
md"""
### Parse expressions
"""

# ╔═╡ 7008fa4d-cfdb-4429-b5e6-07d5af2db270
function analyse(ex)
	ex2 = value(ex)
	
	op = operation(ex2)
	lhs, rhs = arguments(ex2)
	
	if op ∈ (≤, <)
		constraint = interval(-∞, 0)
		Num(lhs - rhs), constraint
		
	elseif op ∈ (≥, >)
		constraint = interval(0, +∞)
		Num(lhs - rhs), constraint
		
	elseif op == (==)
		constraint = interval(0, 0)
		Num(lhs - rhs), constraint
	
	else
		return ex, interval(0, 0)   # implicit 0
	end
		
end

# ╔═╡ 063766c7-aff6-4fbe-a7be-759c1ea02e88
begin
	struct Separator{V,E,C,F,R}
		vars::V
		ex::E
		constraint::C
		f::F
		contractor::R
	end
	
	function Separator(orig_expr, vars)
		ex, constraint = analyse(orig_expr)
		
		return Separator(vars, ex, constraint, make_function(ex, vars), Contractor(ex, vars))
	end
	
	function (SS::Separator)(X)
		boundary = SS.contractor(X)  # contract with respect to 0, which is always the boundary

		lb = IntervalBox(inf.(X))
		ub = IntervalBox(sup.(X))
		
		inner = boundary   
		outer = boundary

		if SS.f(lb) ⊆ SS.constraint
			inner = inner ∪ lb
		else
			outer = outer ∪ lb
		end
		
		if SS.f(ub) ⊆ SS.constraint
			inner = inner ∪ ub
		else
			outer = outer ∪ ub
		end
		

		return boundary, inner, outer 
	end
end

# ╔═╡ e2c7e05d-814f-4e44-9b39-df4d4e8b2cee
S2 = Separator(ex, vars)

# ╔═╡ 1684fec3-aa5a-45c5-92b3-9b397cb44ba7
S2.ex

# ╔═╡ 8bc765fc-9b70-43c1-97ef-a4fa9ca3e42b
S2.constraint

# ╔═╡ 53ddc2d8-dbba-4efc-a78c-c038f198b3a9
boundary, inner, outer = S2(X2)

# ╔═╡ 0454b5b4-dd75-473c-9fe0-cb89b67853ba
begin
	contour(-1:0.1:1, -1:0.1:1, (x, y) -> x^2 + y^2, levels=[1]; plot_options..., size=(600, 400), lw=2)
	
	plot!(inner, label="inner", leg=:outertopright)
	plot!(outer, label="outer")
	plot!(boundary, label="boundary")

end

# ╔═╡ d462cc10-3b0f-4ceb-9b6e-bb84fcf3437f
function pave(X, S::Separator, ϵ=0.1)
    working = [X]
	inner_paving = typeof(X)[]
    boundary_paving = typeof(X)[]

    while !isempty(working)
	
        X = pop!(working)
		
		
		
		if isempty(X)
            continue
        end
		
		if any(any.(isnan, X))  # hack to check empty
			continue
		end
		
		# @show X


        boundary, inner, outer = S(X)

		if outer != X
			# index = findfirst(outer .!= X)
			
			diff = setdiff(X, outer)  
			# replace setdiff with finding the *unique* direction that shrank
			
			if !isempty(diff)

				append!(inner_paving, diff)
				
			end
		end


        if diam(boundary) < ϵ
            push!(boundary_paving, boundary)
            continue 
        end
		
		push!(working, bisect(boundary)...)

    end

    return inner_paving, boundary_paving
end

# ╔═╡ fafefa1c-8867-4125-ba5d-98564fc83b88
inner_paving, boundary_paving = pave(IntervalBox(-9..10, 2), S2, ϵ);

# ╔═╡ c6b9b6fc-fb25-4cb7-bcc4-f041a652f451
begin
	plot(inner_paving; plot_options..., xlims=(-2, 2), ylims=(-2, 2), lw=0.5, label="inside")
	plot!(boundary_paving; plot_options..., lw=0.5, label="boundary", leg=:outertopright)
end

# ╔═╡ 1bf7f2bd-537d-46fc-9689-25d99b39100b


# ╔═╡ 05ed1e0e-074e-4c7d-9763-48523c90d830
"Use Pluto to get the variables referenced in an expression. Don't try this at home kids"
get_references_hacky(s) = let
	result = Pluto.ReactiveNode(s)
	result.references
end

# ╔═╡ fa3a3229-d4ac-4582-adec-f8891ecac06f
const legal_refs = [:a, :b, :c, :d, :x, :y, :+, :-, :*, :/, :<, :≤, :≥, :>, :sin, :cos, :expr, :log, :log10, :^, :sqrt]

# ╔═╡ bd2c3858-2123-485f-8dbd-9ba8f6a47a42
begin
	a, b, c, d, x, y  # dummy variables to re-evaluate when these values change
	
	s2 = s
	
	# allow single "=":
	if contains(s2, "=") && !contains(s2, "==") && !contains(s2, "<=") && !contains(s2, ">=")
		s2 = replace(s2, "=" => "==")
	end
	
	if get_references_hacky(s2) ⊆ legal_refs
		expr = eval(Meta.parse(s2))
	end
end

# ╔═╡ e9d94091-0984-4b7a-9cca-5e52c0c22e02
S = Separator(expr, vars);

# ╔═╡ 76c8ff72-4123-4ef4-993e-db0bef7f3610
inner_p, boundary_p = pave(X, S, δ);

# ╔═╡ f537faa6-a1e7-4056-a4e9-a89fbf808650
begin
	lw = show_boxes ? 0.5 : 0.0
	leg = show_legend ? :outertopright : false
	
	plot(inner_p; plot_options..., xlims=(-h, h), ylims=(-h, h), lw=lw, label="inside")
	plot!(boundary_p; plot_options..., lw=lw, label="boundary", leg=leg, alpha=0.8)
end

# ╔═╡ b6712eb8-554c-4aa9-aad1-14118fa308ff
#= md"""
$([Markdown.Code("julia", e) for e in examples])
""" =#

# ╔═╡ 89349420-cefe-4ca1-ac65-30ffbbbda8a0
# Markdown.MD(Markdown.Code("julia", join(examples, "\n\n")))

# ╔═╡ Cell order:
# ╠═9223061d-c2ad-4d6b-b17d-85a424d050e6
# ╟─be75fc1c-393b-46c3-9a8a-605c028d5901
# ╟─d63edc38-df0c-422a-8937-0819f1f7f040
# ╟─4a4eb65a-8eb2-47f9-b4de-dc31bf0d6b6f
# ╟─f9920438-dc18-41e8-8286-d00e715f3789
# ╟─2b4a16c9-dc1e-474e-8ef3-3ad0f8849392
# ╟─409d5444-b8ae-4741-b9a5-5a6b5c0797c2
# ╟─c414fd82-2c25-410e-a2b4-186af74a7794
# ╟─4622075d-cd78-412a-a995-ef1a71bba537
# ╟─e82f9d4e-d2c2-4d79-a5d2-d42aa7de6478
# ╟─0c1f44e2-f1b3-403e-9358-341fb1833bc7
# ╟─08a43bcb-ad7d-4013-949b-a124392a9536
# ╟─bc9709dc-8f97-4588-b071-ea806ba1dcbd
# ╟─76fa1f07-9546-4f89-ab15-f31306b2f30c
# ╟─b57cf5f7-ca6f-47f9-ba9b-108a36c041c5
# ╟─bd2c3858-2123-485f-8dbd-9ba8f6a47a42
# ╟─f537faa6-a1e7-4056-a4e9-a89fbf808650
# ╟─d4626e5c-9fdf-4ace-80c9-99f09abfe104
# ╟─7d778956-2029-419b-a33f-2e70fd29450f
# ╟─dcc23cff-79b5-4808-bc14-69b72b89a755
# ╠═e9d94091-0984-4b7a-9cca-5e52c0c22e02
# ╠═76c8ff72-4123-4ef4-993e-db0bef7f3610
# ╟─6e46b81d-3cb8-47a4-9948-2f70696e6ab8
# ╟─a3c0c064-506b-43ce-afd4-4e4ee897c034
# ╟─d585f87e-63d6-487c-a7dc-4c2dca15ca4d
# ╟─8d0e9542-8231-4af9-855b-5ea72c097ee9
# ╠═b0a03acd-3906-44c9-9614-c6c32459f2b6
# ╟─90d3eade-19fa-4e87-9e7b-8b3dce8bbd3f
# ╠═4c2577d3-15d9-4f7b-96b6-6dd23a013b92
# ╟─f12ad635-9dd5-4c7b-8168-806733657e83
# ╟─ba529560-fe47-435b-a459-082681571f62
# ╟─e652e1cd-2beb-4f82-a7ec-335fdc742077
# ╠═e2c7e05d-814f-4e44-9b39-df4d4e8b2cee
# ╟─a72b53b3-2d3b-4ce6-9962-f564e8962e0e
# ╠═1684fec3-aa5a-45c5-92b3-9b397cb44ba7
# ╟─6b4d0744-293b-411a-8b3d-9a73bcaab2bb
# ╠═8bc765fc-9b70-43c1-97ef-a4fa9ca3e42b
# ╟─b8b5829e-1545-41cb-b1e5-772c3ed5c038
# ╠═ccd556b2-2a7f-496b-bee9-cc30132dc2dd
# ╟─7abb2e85-8b52-4474-8b40-584e3a481ad6
# ╠═53ddc2d8-dbba-4efc-a78c-c038f198b3a9
# ╟─0454b5b4-dd75-473c-9fe0-cb89b67853ba
# ╟─038cae8a-bf79-434d-a805-dde8a0ee0509
# ╟─847c6fdc-0a48-48f1-8965-9facabf8c2c6
# ╟─ce74d395-b1db-427e-b7e6-faa3ab326e78
# ╟─7744c2da-ef13-4e1d-ad82-045b1280f773
# ╠═74e4354d-cabd-4fc1-b8e3-eb19b7f71bcd
# ╠═fafefa1c-8867-4125-ba5d-98564fc83b88
# ╠═c6b9b6fc-fb25-4cb7-bcc4-f041a652f451
# ╟─9bbb6f23-c8f4-4bed-b56b-8b0fb0522acb
# ╟─f58bd7ca-bb23-4e9e-b33f-dbb178c16083
# ╟─f44e0400-ac76-4717-af4f-4eda130dbe7a
# ╟─978b2396-3183-4cbb-aa55-ed76687ea215
# ╠═1fde9cd0-c0a3-4d4c-822c-278f671d3e44
# ╠═83fa8da1-bbb3-4f91-a5cc-c81834749c58
# ╟─808319fe-be49-4278-b9c6-fc1bbf2c7954
# ╠═5126ba06-bee9-4ae8-9358-35045fcd0fe0
# ╠═063766c7-aff6-4fbe-a7be-759c1ea02e88
# ╟─242fe373-aa92-4fcc-8347-1a0172c3a70d
# ╠═5688a092-3a57-4ca9-91a5-4c25549602b0
# ╠═d462cc10-3b0f-4ceb-9b6e-bb84fcf3437f
# ╠═b3e538a2-06ce-4ee4-a413-c0c6b36ec797
# ╟─72dd723a-a664-41a7-8361-3a51aeaa31ae
# ╠═3b38e24d-01dd-4eaa-9a57-186cbec7181f
# ╠═7008fa4d-cfdb-4429-b5e6-07d5af2db270
# ╠═1bf7f2bd-537d-46fc-9689-25d99b39100b
# ╟─05ed1e0e-074e-4c7d-9763-48523c90d830
# ╟─fa3a3229-d4ac-4582-adec-f8891ecac06f
# ╠═b6712eb8-554c-4aa9-aad1-14118fa308ff
# ╠═89349420-cefe-4ca1-ac65-30ffbbbda8a0
