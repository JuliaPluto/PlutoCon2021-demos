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

# ╔═╡ d0bdce5e-9486-11eb-38be-73bd0f9ccab4
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add([
			Pkg.PackageSpec(url="https://github.com/paulgb/PenPlots.jl"),
			])
	Pkg.add("PlutoUI")
	using PenPlots
	using Random
	using Base.Iterators
	using PlutoUI	
end

# ╔═╡ fde6fd72-340f-4bee-82c7-6e7924f7c72a
md"
# Pen Plotting with Pluto

A plotter is a robot that draws based on instructions you provide it.

There are basically three varieties of plotters:
- Vintage machines (like the [HP 7470A](http://www.hpmuseum.net/display_item.php?hw=73)) lovingly restored by hobbiests.
- DIY machines, often of the [polargraph](https://trmm.net/Polargraph/) variety.
- Modern pre-built desktop pen plotters, like the [AxiDraw](https://shop.evilmadscientist.com/productsmenu/846).

At a low level, plotters are controlled by a series of commands, the most important being “move to the location (x, y)”, “raise the pen”, and “lower the pen”. In addition
to these low-level commands, there are tools out there for converting various
vector graphics files into the raw commands.

In this talk, I will use a tiny library I wrote called PenPlots.jl which provides
basic data structures for representing points and paths, as well as generating an
SVG (scalable vector graphics) representation of one or more paths. Pleasingly, SVG is
supported by my plotter driver of choice, [Saxi](https://github.com/nornagon/saxi),
and is also supported directly in the browser for easy previews in Pluto.

I'll start by generating a few basic shapes to show you how `PenPlots.jl` works, and 
then I'll show how Pluto makes it easy to explore the parameter space of more 
intricate plots.
"

# ╔═╡ 63d97678-f575-428a-a198-80f51ad39fee
md"
## Some Basics

### Drawing a line

`PenPlots.jl` uses a `Point` data structure to represent an `(x, y)` coordinate on the 
plotting surface. These are _screen_ coordinates rather than _Cartesian_ coordinates,
so the origin is in the upper-left hand corner and the `y` coordinate _increases_ as 
we go down the plotting surface.

The `Path` data structure represents a path through two or more points. Its constructor takes a list of points.

Many types in `PenPlots.jl`, including `Path`, implement `Base.show` for `text/html`, so that the Pluto notebook will automatically preview them when they are the return value of a cell.
"

# ╔═╡ be70af4a-5e27-4371-b14f-e7f6b4b67b18
Path([
	Point(1, 0),
	Point(0, 1),
])

# ╔═╡ 74fcfb01-bb47-43a7-b4b3-5018580926eb
md"
### Drawing Two Lines

Multiple separate paths can be combined by putting them in a vector. In pen plotter
terms, separate paths mean that the pen plotter will draw one path, then lift the pen, move to the beginning of the next path, and then draw it.

I'm avoiding using the terms “first path” and “second path” here. That's because
even though we are using an ordered data structure (a vector), the paths will usually
be reordered to reduce drawing time. This used to be a manual step ([I 
wrote about it here](https://nb.paulbutler.org/optimizing-plots-with-tsp-solver/)), 
but recently it's become a built-in feature of the driver, as is the case with Saxi.
"

# ╔═╡ 49bf2aa5-14b6-45ff-958e-4108efa99691
[
	Path([
		Point(1, 0),
		Point(0, 1),
	]),
	Path([
		Point(-0.5, 0.),
		Point(1, 0.5),
	]),
]

# ╔═╡ 86439518-31ee-42df-8ba2-1b95995e425e
md"
### Drawing Many Lines

This technique plays really nicely with the `map` function to draw a bunch of lines.
"

# ╔═╡ 19a882eb-5819-4f71-bf8a-d3369f54f15f
map(0:40) do i
	Path([
			Point(i / 2, 0),
			Point(i, 100 - i * 2)
			])
end

# ╔═╡ 3cad3822-8d41-42b2-b99b-ef3a34bfb45f
md"
### Drawing A Circle

`map` can also be used within a `Path` to create a vector of points to visit. For
example, we can create a circle by rotating the unit vector around the origin in tiny
increments.

`frac_rotation` is a helper function to generate a rotation matrix from a fraction,
where `1.0` represents a full rotation. `PenPlots.jl` provides it along with 
`degree_rotation` and `radian_rotation`.

Rotation matrices can be multiplied by `Point`, `Path`, and `Vector{Path}`. Rotations
are always about the origin `(0, 0)`.
"

# ╔═╡ 70bf2597-4fed-45dd-b1cf-7b9d77985a01
Path(map(0:0.01:1) do i
	frac_rotation(i) * unitvec
end)

# ╔═╡ 6dda1459-f771-4b62-91b8-6292e079901b
md"
### Spiral
"

# ╔═╡ 6626b298-748c-4886-8926-c00b02c227c9
Path(map(0:0.01:30) do i
	frac_rotation(i) * unitvec * i
end)

# ╔═╡ 42a9fbe9-8a34-4b6a-ac58-efd746f01fd4
md"Step Size: $(@bind stepsize PlutoUI.Slider(0.01:0.001:1, default=0.401))"

# ╔═╡ 2ea203c3-69e2-4355-8810-f1eb72b41dc2
Path(map(0:stepsize:200) do i
	frac_rotation(i) * unitvec * i
end)

# ╔═╡ f208b8cc-9935-45ba-bd1f-c4b2a2d2be1c
md"
Step Size1: $(@bind stepsize1 PlutoUI.Slider(0.01:0.001:1, default=0.747))

Step Size2: $(@bind stepsize2 PlutoUI.Slider(0.01:0.001:1, default=0.669))

Rotation: $(@bind rotation PlutoUI.Slider(0:0.01:1))
"

# ╔═╡ 7fab0683-d27f-4fbe-af9e-4ed2d080f8f0
PenPlot(
	[Path(map(0:stepsize1:200) do i
		frac_rotation(i) * unitvec * i
	end)],
	frac_rotation(rotation) * [Path(map(0:stepsize2:200) do i
		frac_rotation(i) * unitvec * i
	end)]
)

# ╔═╡ 03fd1d18-e06c-4054-b0dd-2ec24d1d064d
md"
## Recursion

### Drawing a [Koch Curve](https://en.wikipedia.org/wiki/Koch_snowflake)
"

# ╔═╡ b602267f-bc59-4a3c-a0ac-7aa50cc8f467
function koch(i=6)
	scale = Point(1/3, 1/3)
	
	if i == 1
		[Path([Point(0, 0), Point(1, 0)])]
	else
		c = koch(i-1)
		vcat(
			scale * c,
			Point(1/3, 0) + degree_rotation(60) * (scale * c),
			Point(1/2, sqrt(3)/6) + degree_rotation(-60) * (scale * c),
			Point(2/3, 0) + scale * c,
		)
	end
end

# ╔═╡ 20013826-2660-4f05-9636-c2883117a730
koch()

# ╔═╡ 4dab6b47-2d4e-452b-a3c1-8963e79d66f9
md"### Drawing a Tree"

# ╔═╡ 8ccb784c-6f3e-456d-9f15-21eecddb5fb2
md"
Angle 1: $(@bind angle1 PlutoUI.Slider(-60:60, default=-20))

Angle 2: $(@bind angle2 PlutoUI.Slider(-60:60, default=40))
"

# ╔═╡ 5e28fe02-bbbc-447b-9fb4-412f0030e0f9
function tree(i=8)
	if i == 1
		[Path([Point(0, 0), Point(0, -1)])]
	else
		c = tree(i-1)
		vcat(
			[Path([Point(0, 0), Point(0, -1)])],
			Point(0, -1/2) + degree_rotation(angle1) * (Point(0.8, 0.8) * c),
			Point(0, -1) + degree_rotation(angle2) * (Point(0.6, 0.6) * c),
		)
	end
end

# ╔═╡ 106b111e-4734-4348-9315-8876788b3b78
tree()

# ╔═╡ 02cb3826-49a1-456a-bc9f-7e86b34adf04
md"
## Noise Spiral

Seed: $(@bind seed NumberField(1:100000))

Big Period: $(@bind big_period Slider(1:100, default=7))

Small Period: $(@bind small_period Slider(1:100, default=4))

Outer Radius: $(@bind radius Slider(1:0.1:10, default=5))
"

# ╔═╡ d55cc824-2f51-4917-961e-4651acdba78f
begin
	noise = random_vector_matrix(MersenneTwister(seed), big_period, small_period)
	
	map(0:0.004:1) do j
		r = 1 + perlin_noise(noise, Point(j*big_period, 0))
		center = radius * frac_rotation(j) * unitvec * r

		Path(map(0:0.01:1) do i
			r = 1 + perlin_noise(noise, Point(i*big_period, j*small_period))
			center + frac_rotation(i) * unitvec * r
	  end)
	end
end

# ╔═╡ Cell order:
# ╟─fde6fd72-340f-4bee-82c7-6e7924f7c72a
# ╟─63d97678-f575-428a-a198-80f51ad39fee
# ╠═be70af4a-5e27-4371-b14f-e7f6b4b67b18
# ╟─74fcfb01-bb47-43a7-b4b3-5018580926eb
# ╠═49bf2aa5-14b6-45ff-958e-4108efa99691
# ╟─86439518-31ee-42df-8ba2-1b95995e425e
# ╠═19a882eb-5819-4f71-bf8a-d3369f54f15f
# ╟─3cad3822-8d41-42b2-b99b-ef3a34bfb45f
# ╠═70bf2597-4fed-45dd-b1cf-7b9d77985a01
# ╟─6dda1459-f771-4b62-91b8-6292e079901b
# ╠═6626b298-748c-4886-8926-c00b02c227c9
# ╠═42a9fbe9-8a34-4b6a-ac58-efd746f01fd4
# ╠═2ea203c3-69e2-4355-8810-f1eb72b41dc2
# ╟─f208b8cc-9935-45ba-bd1f-c4b2a2d2be1c
# ╠═7fab0683-d27f-4fbe-af9e-4ed2d080f8f0
# ╟─03fd1d18-e06c-4054-b0dd-2ec24d1d064d
# ╠═b602267f-bc59-4a3c-a0ac-7aa50cc8f467
# ╠═20013826-2660-4f05-9636-c2883117a730
# ╟─4dab6b47-2d4e-452b-a3c1-8963e79d66f9
# ╟─8ccb784c-6f3e-456d-9f15-21eecddb5fb2
# ╠═5e28fe02-bbbc-447b-9fb4-412f0030e0f9
# ╠═106b111e-4734-4348-9315-8876788b3b78
# ╟─02cb3826-49a1-456a-bc9f-7e86b34adf04
# ╠═d55cc824-2f51-4917-961e-4651acdba78f
# ╠═d0bdce5e-9486-11eb-38be-73bd0f9ccab4
