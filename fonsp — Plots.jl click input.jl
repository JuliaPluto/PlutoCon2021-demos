### A Pluto.jl notebook ###
# v0.12.10

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

# ╔═╡ e9eacfd0-20fd-11eb-0d0f-97a6fe34a16f
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add([
			Pkg.PackageSpec(name="Plots", version="1.6-1"),
			])
	using Plots
end

# ╔═╡ 4e360478-20fe-11eb-3f6d-9111d385b33d
md"""
# Plots.jl click input

Click somewhere on this graph:
"""

# ╔═╡ 58349090-20fe-11eb-2344-a9895f29ce31
function linepoint(click_coordinate)
	p = plot(1:10)
	scatter!(p, click_coordinate[1:1], click_coordinate[2:2])
end

# ╔═╡ 607d58da-20ff-11eb-2a49-218d6307d7f2
md"""
---
Why is this special? Because normally, the _input_ (`@bind`) and _output_ live in two separate cells:
"""

# ╔═╡ b0084aa8-2100-11eb-18f7-8b68a3a6f85d
@bind x html"<input type=range>"

# ╔═╡ b00c1d36-2100-11eb-395c-6bb0bc0f64bf
sqrt(x)

# ╔═╡ b0190fc8-2100-11eb-073a-95ff9fa6c7c4
md"""
But in our interactive plot, the input and output are inside _the same cell_. To achieve this, we need a couple of tricks: a _click tracker wrapper_, a _self-referencing cell_ and the _`@initially` macro_. Let's talk about those one by one:

# Click tracker

TUTORIAL WORK IN PROGRESS
"""

# ╔═╡ 8b129e70-20ff-11eb-1e52-4fed0031b63e
function COOL_PLOT(q0)
	p = plot(1:10)
	scatter!(p, q0[1:1], q0[2:2])
	
	return p
end

# ╔═╡ 9e3a08ce-2101-11eb-0b21-31a5843403ca
md"""
The third step is to write a function that:
- takes a **click coordinate** (a vector `[x, y]`) as input, and 
- returns a plot.

It's up to _you_ to use this coordinate in a creative way!
"""

# ╔═╡ 15e0dc00-20ff-11eb-1a4d-71579b2970b7
md"""
## Necessary functions

You can copy these cells into your notebook by selecting them (start dragging a selection rectangle from inbetween two cells), and dragging them into another notebook. 
"""

# ╔═╡ 6a998f62-20fe-11eb-3104-5d96f4718ccb
begin
	plotclicktracker_js(id, r) = """
	const container = document.querySelector("#$(id)")
	const graph = container.firstElementChild
	
	const onclick = (e) => {
	    const svgrect = graph.getBoundingClientRect()
	    const f = [
			(e.clientX - svgrect.left) / svgrect.width, 
			(e.clientY - svgrect.top) / svgrect.height
		]
		container.value = [
			f[0] * $(r.x_scale) + $(r.x_offset),
			f[1] * $(r.y_scale) + $(r.y_offset),
		]
		container.dispatchEvent(new CustomEvent("input"), {})
	}
	
	graph.addEventListener("click", onclick)
	
	invalidation.then(() => {
	graph.removeEventListener("click", onclick)
	})
	"""
	
	plotclicktracker(p::Plots.Plot) = let
		id = String(rand(('a':'z') ∪ ('A':'Z'), 12))
		
		# we need to render the plot before its dimensions are available:
		plot_render = repr(MIME"text/html"(), p)
		
		# these are the _bounding boxes_ of our plot
		big = bbox(p.layout)
		small = plotarea(p[1])
		
		# the axis limits
		xl = xlims(p)
		yl = ylims(p)
		
		# with this information, we can form the linear transformation from 
		# screen coordinate -> plot coordinate
		
		# this is done on the JS side, to avoid one step in the Julia side
		# we send the linear coefficients:
		r = (
		x_offset = xl[1] - (xl[2] - xl[1]) * small.x0[1] / small.a[1],
		x_scale = (big.a[1] / small.a[1]) * (xl[2] - xl[1]),
		y_offset = (yl[2] - yl[1]) + (small.x0[2] / small.a[2]) * (yl[2] - yl[1]) + yl[1],
		y_scale = -(big.a[2]/ small.a[2]) * (yl[2] - yl[1])
		)
		HTML("""<div id=$(id)>$(plot_render)<script>$(plotclicktracker_js(id, r))</script></div>""")
	end
end

# ╔═╡ 2105339e-2109-11eb-05e5-43a837b52a7e
begin
	default_usage_error = :(error("Example usage:\n\n@intially [1,2] @bind x f(x)\n"))
	
	macro initially(::Any)
		default_usage_error
	end
	
	macro initially(default, bind_expr::Expr)
		if bind_expr.head != :macrocall || bind_expr.args[1] != Symbol("@bind")
			return default_usage_error
		end
		
		# warn if the first argument is a @bind
		if default isa Expr && default.head == :macrocall && default.args[1] == Symbol("@bind")
			return default_usage_error
		end
			
		esc(intially_function(default, bind_expr))
	end
	
	
	function intially_function(default, bind_expr)
		sym = bind_expr.args[3]
		@gensym setval bond

		quote
			if !@isdefined($sym)
				$sym = $default
			end

			$setval = $sym


			$bond = @bind $sym $(bind_expr.args[4])
			PlutoRunner.Bond

			if $sym isa Missing
				$sym = $setval
			end

			$bond
		end
	end
end

# ╔═╡ 5711a7d4-20fe-11eb-3058-69e4348b96e6
@initially [5,5] @bind x0 plotclicktracker(linepoint(x0))

# ╔═╡ 59eb1f44-2103-11eb-04dd-594b96f10c15
x0

# ╔═╡ 91a3614a-2102-11eb-3e5b-dd99598e57d0
md"""
You can also use [`ingredients`](https://github.com/fonsp/Pluto.jl/issues/115#issuecomment-661722426) to load this notebook into another notebook.
"""

# ╔═╡ 119f2e96-20ff-11eb-1cc1-259f842a8cd8
md"""
## Packages

(We only need Plots.jl)
"""

# ╔═╡ Cell order:
# ╟─4e360478-20fe-11eb-3f6d-9111d385b33d
# ╠═5711a7d4-20fe-11eb-3058-69e4348b96e6
# ╠═59eb1f44-2103-11eb-04dd-594b96f10c15
# ╠═58349090-20fe-11eb-2344-a9895f29ce31
# ╟─607d58da-20ff-11eb-2a49-218d6307d7f2
# ╠═b0084aa8-2100-11eb-18f7-8b68a3a6f85d
# ╠═b00c1d36-2100-11eb-395c-6bb0bc0f64bf
# ╟─b0190fc8-2100-11eb-073a-95ff9fa6c7c4
# ╠═8b129e70-20ff-11eb-1e52-4fed0031b63e
# ╟─9e3a08ce-2101-11eb-0b21-31a5843403ca
# ╟─15e0dc00-20ff-11eb-1a4d-71579b2970b7
# ╟─6a998f62-20fe-11eb-3104-5d96f4718ccb
# ╟─2105339e-2109-11eb-05e5-43a837b52a7e
# ╟─91a3614a-2102-11eb-3e5b-dd99598e57d0
# ╟─119f2e96-20ff-11eb-1cc1-259f842a8cd8
# ╠═e9eacfd0-20fd-11eb-0d0f-97a6fe34a16f
