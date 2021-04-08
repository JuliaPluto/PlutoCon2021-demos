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

# ╔═╡ e74815d8-1bb4-48bd-9000-8d72fab406d3
begin
    import Pkg
    Pkg.activate(mktempdir())

    Pkg.add([
        Pkg.PackageSpec(name="Plots"),
        Pkg.PackageSpec(name="PlutoUI"),
		Pkg.PackageSpec(name="ImageMagick"),
		Pkg.PackageSpec(name="Images"),
    ])

    using Plots
    using PlutoUI
	using Images
end

# ╔═╡ fecdd4d9-2085-4d17-a6b1-85a35b1e70de
md"""
# Colour filters

By Luka van der Plas

In this notebook, we will do some simple colour filters on images. Essentially, we write a function that takes a colour and transforms it a bit. When you apply it to a whole image, you change the colours of the image!

We'll keep things pretty simple here. This notebook is not really a useful photo editing tool: I intended it more as a fun concept that you can build on.

We start by loading an image to work with.
"""

# ╔═╡ ca75f874-f845-11ea-1d22-9352f0e872bb
download("https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Giant_Pandas_having_a_snack.jpg/1280px-Giant_Pandas_having_a_snack.jpg",
	"pandas.jpg")

# ╔═╡ e6a44cf8-f845-11ea-0918-6585b79b2981
pandas = load("pandas.jpg")

# ╔═╡ eff44dc8-08be-417e-b560-a5e337ae21f4
md"""
Cute!
"""

# ╔═╡ 54eca61b-b42e-459b-be37-7660aa19ec71
md"""
## Sliders sliders sliders

Okay, here we go. We have some sliders to alter the red, blue and green channels of the image. Play around with them and see how it affects the picture!
"""

# ╔═╡ 6e59eb98-f90a-11ea-0540-2b03b30c5bd1
let
	function color_slider()
		Slider(-0.2 : 0.01 : 0.2, default = 0.0 )
	end
	
	md"""
	**Red**:

	Contrast: $(@bind red_contrast color_slider()) 

	Intensity: $(@bind red_intensity color_slider())

	**Green**:

	Contrast: $(@bind green_contrast color_slider()) 

	Intensity: $(@bind green_intensity color_slider())

	**Blue**:

	Contrast: $(@bind blue_contrast color_slider()) 

	Intensity: $(@bind blue_intensity color_slider())
	"""
end

# ╔═╡ 574e26b3-e8f5-4003-acbe-da965b27ada1
md"""
So what are these sliders doing? Here is a plot of what's happening.
"""

# ╔═╡ 7888e433-d548-430c-b68d-55c160700d81
md"""
Each pixel has a red, green, and blue value. Based on the slider value, we calculate a new value for the pixel.
"""

# ╔═╡ bf65c40a-e373-447b-8481-edc7c6922425
md"""
## Behind the screens

So how does this work? For each channel (red, green, or blue) we have a slider for *contrast* and *intensity*. Based on those values, we want to define a transformation for that channel. A transformation function will take the original value and return the new value (based on the slider). 

So `color_curve` takes those slider values, and outputs the corresponding function.
"""

# ╔═╡ fe39ca62-f90a-11ea-3c73-1deb0d6bf9f3
function color_curve(contrast, intensity)
	function new_value(x)
		x += contrast * sin((x - 0.5) * 2π)
		x += intensity * cos((x - 0.5) * π) 
		
		max(0, min(x, 1))
	end
end

# ╔═╡ 0313d6b6-7d1c-499b-ab1d-3a4022f962fe
md"We get a function for the red, green and blue values."

# ╔═╡ 37d21840-f84a-11ea-1fdc-43a5227edf08
begin
	reds = color_curve(red_contrast, red_intensity)
	greens = color_curve(green_contrast, green_intensity)
	blues = color_curve(blue_contrast, blue_intensity)
end ;

# ╔═╡ 71de5cb3-c3f8-4057-b482-a3705c3bcd64
md"""
Now, we want to use color transformations on the entire image.

To apply these to a single pixel, we apply the red transformation to the red value of the pixel, the green transformation to the green value, and the blue transformation to the blue value. We put those together to get the new function.

Then we broadcast that operation on the image to apply it to each pixel.
"""

# ╔═╡ 7b72bd6e-f84a-11ea-3c86-d52011d43cde
function apply_curve(img, red_curve, green_curve, blue_curve)
	function apply_curve(color)
		RGB(red_curve(color.r), green_curve(color.g), blue_curve(color.b))
	end
	
	apply_curve.(img)
end

# ╔═╡ cfc1d17e-f84a-11ea-3782-b9fd15025fe6
apply_curve(pandas, reds, greens, blues)

# ╔═╡ a79ce946-2485-458f-a11a-c0f7ea10020d
md"""
Lastly, we define the plot.
"""

# ╔═╡ f6bccafe-f848-11ea-3736-4b6449fbfa0e
function plot_curves(red_curve, green_curve, blue_curve)
	plot(legend = false, 
		xlims = (0,1),
		xlabel = "original value", 
		ylabel = "new value"
	)
	plot!(red_curve, linecolor = :red)
	plot!(green_curve, linecolor = :green)
	plot!(blue_curve, linecolor = :blue)

end

# ╔═╡ 59a8caae-f84a-11ea-32fd-2520b9a8b57f
plot_curves(reds, greens, blues)

# ╔═╡ Cell order:
# ╟─fecdd4d9-2085-4d17-a6b1-85a35b1e70de
# ╠═ca75f874-f845-11ea-1d22-9352f0e872bb
# ╠═e6a44cf8-f845-11ea-0918-6585b79b2981
# ╟─eff44dc8-08be-417e-b560-a5e337ae21f4
# ╟─54eca61b-b42e-459b-be37-7660aa19ec71
# ╟─6e59eb98-f90a-11ea-0540-2b03b30c5bd1
# ╠═cfc1d17e-f84a-11ea-3782-b9fd15025fe6
# ╟─574e26b3-e8f5-4003-acbe-da965b27ada1
# ╠═59a8caae-f84a-11ea-32fd-2520b9a8b57f
# ╟─7888e433-d548-430c-b68d-55c160700d81
# ╟─bf65c40a-e373-447b-8481-edc7c6922425
# ╠═fe39ca62-f90a-11ea-3c73-1deb0d6bf9f3
# ╟─0313d6b6-7d1c-499b-ab1d-3a4022f962fe
# ╠═37d21840-f84a-11ea-1fdc-43a5227edf08
# ╟─71de5cb3-c3f8-4057-b482-a3705c3bcd64
# ╠═7b72bd6e-f84a-11ea-3c86-d52011d43cde
# ╟─a79ce946-2485-458f-a11a-c0f7ea10020d
# ╠═f6bccafe-f848-11ea-3736-4b6449fbfa0e
# ╠═e74815d8-1bb4-48bd-9000-8d72fab406d3
