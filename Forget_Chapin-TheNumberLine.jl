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

# ╔═╡ f07c3450-ef32-11ea-3f5f-2b0fc747ff80
begin
	using TheNumberLine, PlutoUI, Luxor; "✓"
end

# ╔═╡ 62e67a9c-ef25-11ea-3589-6f377d7aa788
md"""
Type value and select `add`

` Type value : ` $(@bind b html"<input type=text>")

` ` $(@bind c html"<input type=button value='add'>")
$(@bind d html"<input type=button value='start over'>")

_For example, `8`, `-9`, or `+2` should be valid choices. You can also `start over` if it looks like something went wrong._
"""

# ╔═╡ dcddc9f9-36aa-44ce-b2c5-284af9928680
#The Number Line is a common teaching tool in e.g. K-12 math classes accross the U.S.
#
#Details of the implementation are found in the following code cells and in the github code repository
#
#https://github.com/gaelforget/TheNumberLine.jl

md"""↩ click here for additional information
"""

# ╔═╡ 78c0fd44-f052-11ea-0264-4378e02814af
begin
	#1. In the code cell at the top where values are entered, you can use 
	# a list of a slider instead. Try replacing the _...@bind b htm..._ line with:
	#
	#`Select value of x from the list : `
	#` ` $(@bind b Select(["4","3","2","1","0","-1","-2","-3","-4"],default="0"))
	#
	#or
	#
	#`Choose value of x using slider : `
	#` ` $(@bind b aSlider(-10:10; default=0))
	
	#2. To restrict the number line to Integer inputs try changing the `TestType` below.
	#	
	TestType=Number; NumberLineType=Float64; "Number LineType = $(NumberLineType)"
	#TestType=Int; NumberLineType=Int; "NumberLineType = $(NumberLineType)"
	
	#3. In the `random turtle` exercise we take a series of consecutive steps on the 
	# number line. Each step is either `-1` (1 step left) or `+1` (1 step right) 
	# based on a coin flip. We do this N times in a row (10 times for example) and
	# observe our final value at the end (green arrow).
	#
	# All you need to do is copy the following line to a new code cell and run it
	#
	# NumberLinePlot(rand((-1,1),10))
	#
	# The activity is ~ do this a bunch of times and discuss how results can vary
	
	md"""↩ click here for exercise material
	"""
end

# ╔═╡ 7c1434b2-ef25-11ea-0967-d756ec262715
bb = try
	isa(b,String) ? b1=eval(Meta.parse(b)) : b1=deepcopy(b)
	!isa(b1,TestType) ? b2=parse(NumberLineType,b1) : b2=b1
	b2
  catch
    NaN
end; "✓"

# ╔═╡ 46c870e8-ef2a-11ea-3552-afbc18d117ee
begin
	d
	ii=[0.0]
	jj=[]
end; "✓"

# ╔═╡ 4be4ef1e-ef27-11ea-34f7-cd86ba1c36e2
begin
	c
	d
	length(jj)>0 ? push!(ii,jj[end]) : nothing
	kk=findall((!isnan).(ii))
	smry=NumberLineExpression(ii[kk])
	NumberLinePlot(ii[kk])
end

# ╔═╡ 33165978-f050-11ea-33f0-4971b031ee8b
smry

# ╔═╡ c0e46264-ef30-11ea-0b51-adc95104e22f
push!(jj,bb); "✓"

# ╔═╡ Cell order:
# ╟─62e67a9c-ef25-11ea-3589-6f377d7aa788
# ╟─33165978-f050-11ea-33f0-4971b031ee8b
# ╟─4be4ef1e-ef27-11ea-34f7-cd86ba1c36e2
# ╟─dcddc9f9-36aa-44ce-b2c5-284af9928680
# ╟─78c0fd44-f052-11ea-0264-4378e02814af
# ╟─f07c3450-ef32-11ea-3f5f-2b0fc747ff80
# ╟─7c1434b2-ef25-11ea-0967-d756ec262715
# ╟─46c870e8-ef2a-11ea-3552-afbc18d117ee
# ╟─c0e46264-ef30-11ea-0b51-adc95104e22f
