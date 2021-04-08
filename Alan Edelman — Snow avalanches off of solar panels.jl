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

# ╔═╡ 6569e216-8a4d-11eb-19dd-cd16ae1e18d4
using Plots, PlutoUI

# ╔═╡ 81369001-f2d3-441c-b28e-0650312a2d62
md"""
I couldn't quite find anything online that indicated how far snow can fall from a roof with solar panels, so I made this little demo based on freshman physics
using the usual physics assumptions.  Would be great if the predictions could be experimentally verified. (Prof. Alan Edelman, MIT, 2021)
"""

# ╔═╡ a1d87592-8a51-11eb-3d9b-5bc0cfc2388e
md"""
# Snow avalanches off of solar panels
"""

# ╔═╡ b1aa300e-8a52-11eb-0e7c-35ae3dfcd7cb
html"""
<div style="position: relative; right: 0; top: 0; z-index: 300;"><iframe src="https://www.youtube.com/embed/Fh-rCnO6jvc?start=7" width=400 height=250  frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe></div>
"""

# ╔═╡ 1ab20db6-8a54-11eb-015b-bdb3c0e77fa2
md"""
###  Car Park, NY Suffolk County
"""

# ╔═╡ 041e7e2a-8a54-11eb-0225-a34742d2f35d
html"""
<img src="https://cdn.newsday.com/polopoly_fs/1.9795529.1421001422!/httpImage/image.JPG_gen/derivatives/landscape_1280/image.JPG">
"""

# ╔═╡ f37a06aa-8a4b-11eb-3ace-b51f66d33a50
function howfar(d=16,h=30,θ=45)
# height(ft) of roof above the roof base 
# angle(degrees) of roof with horizontal (Note: tan θ = pitch  )
# height(ft) of the roof base above the ground

g =  32.1741 # ft/s^2 gravitational constant
v₁ = √(2g*d) # speed (ft/s) at roof base
vₓ =  v₁ * cosd(θ)       # horizontal speed at roof base
vᵥ =  v₁ * sind(θ)       # vertical speed at roof base
t = (√(2g*h +vᵥ^2)-vᵥ)/g # time from roof base to ground (solve for t, h=vᵥt + gt²/2)
r = vₓ*t                 # distance in front of house
return r, t, vₓ, vᵥ
end

# ╔═╡ 0ab2932c-8a57-11eb-2391-8d2dbee3d78b
howfartime(d=15,h=30,θ=45) = howfar(d,h,θ)[1]

# ╔═╡ be66ff40-8a55-11eb-287e-4da0523312b9
md"""
portico below roof $(@bind b Slider(1:100, show_value=true, default=6))

h $(@bind h  Slider(15:50, show_value=true, default=19))

d $(@bind d  Slider(1:100, show_value=true, default=11))

θ $(@bind θ  Slider(1:.1:90, show_value=true, default=35))


"""

# ╔═╡ cdd8512c-8a55-11eb-2e8f-abf87a0a153e
begin
	#physics
	r, t, vₓ, vᵥ  = howfar(d,h,θ)
	g = 32.1741 # gravitational constant in ft/s²

	plot()
	plot!( [0, 0],[0,h],c=:blue,lw=5)   # side of house
	
	#roof
	plot!( [0, d*cotd(θ)],[h, h+d],c=:black,lw=5)
	plot!( [d*cotd(θ), 2d*cotd(θ)], [h+d,h], c=:black,lw=5)
	plot!( [0, d*cotd(θ)],[h+d, h+d],ls=:dash,c=:black)
	plot!( [0, 0],[h, h+d],ls=:dash,c=:black)
	annotate!(-.7,h+d-.5,text("h+d=$(h+d)'",:right))
	annotate!(-.7,h+.4,text("h=$(h)'",:blue,:right))
	annotate!(2.5,h+.5,text("θ=$(θ)°", font(6),:left,rotation=30))
	
	#window
	plot!(Shape( [ (5,h-10),(5,h),(15,h),(15,h-10),(15,h-10)]),c=:white)
	plot!( [10, 10],[h-10,h],c=:black)
	plot!( [5, 15],[h-5,h-5],c=:black)
	plot!([0,4.5],[h,h],c=:gray)
	
	

	
	# ground
	plot!( [-r,0],[0,0],c=:green,lw=10) # ground
	annotate!( -r*.5,.5, text("$(round(r,digits=1))'",:green,:bottom))
	
	# trajectory
		
	time = t.*(0:.05:1)
	
	x = -vₓ.*time
	y = h .- vᵥ.*time - g.*time.^2 ./2
	scatter!(x,y)
	annotate!( x[end÷2],y[end÷2]+5,text("Avalanche!",:teal,:right,rotation=50))

	# portico

	ts = (-vᵥ+√(2*g*b+vᵥ^2))/g
	xs = -vₓ.*ts
	ys = h .- vᵥ.*ts - g.*ts.^2 ./2
	plot!([xs,0],[ys,ys],c=:red,lw=5)
	plot!([0,0],[0,ys],c=:red,lw=5)
	
	if b<h
	  annotate!(xs*.6,ys-.5,text("$(round(-xs,digits=1))'",:red,:top))
	  annotate!(-.3,ys/2, text(" $(round(ys,digits=1))'",:left,:red))	
	  annotate!(-.3,(h+ys)/2, text(" $(round(h-ys,digits=1))'",:left,:blue))
	end
	
	title!("Snow Avalanche from Solar Panels")
	plot!(ratio=1,xlims=(-r*1.3,2d*cotd(θ)),ylims=(0,h+d+2),legend=false)
end


# ╔═╡ Cell order:
# ╠═6569e216-8a4d-11eb-19dd-cd16ae1e18d4
# ╟─81369001-f2d3-441c-b28e-0650312a2d62
# ╟─a1d87592-8a51-11eb-3d9b-5bc0cfc2388e
# ╟─b1aa300e-8a52-11eb-0e7c-35ae3dfcd7cb
# ╟─1ab20db6-8a54-11eb-015b-bdb3c0e77fa2
# ╟─041e7e2a-8a54-11eb-0225-a34742d2f35d
# ╠═f37a06aa-8a4b-11eb-3ace-b51f66d33a50
# ╠═0ab2932c-8a57-11eb-2391-8d2dbee3d78b
# ╟─be66ff40-8a55-11eb-287e-4da0523312b9
# ╠═cdd8512c-8a55-11eb-2e8f-abf87a0a153e
