### A Pluto.jl notebook ###
# v0.14.1

using Markdown
using InteractiveUtils

# ╔═╡ 47fa40d8-963a-11eb-1666-172ae387f867
begin
    import Pkg
    Pkg.activate(mktempdir())
    Pkg.add([
        Pkg.PackageSpec(name="CommonMark", version="0.8"),
    ])
    using CommonMark
end

# ╔═╡ b12778d2-0462-40f4-913f-b4d2db404feb
md"""
# -[* Dashes, Brackets and Stars -[*

```julia
md"
### Pain Points and Potential of Markdown in Pluto

An opinionated 'lightning talk' by Jeremiah Lewis

2021-04-08
"
```

"""

# ╔═╡ 025d04f8-afa1-45a6-a681-e0e595544d63
md"""

## Pluto.jl is a great tool

### But unfortunately it's easy to end up with something that looks like:

"""

# ╔═╡ ecf26255-5550-48ae-a8ad-eecdf4437955
md"""
$(1 + 1)  $$ 1 + 1 $$
"""

# ╔═╡ 684acf40-3ac6-4a10-900e-e2606d3b1641
md"""

## 0️⃣ Truncated History of v0.x Julia

> 'Nothing else can solve my problem except Julia' era.

### Language

- High performance
- Replace two languages (e.g. Python and C++) with one new one
- Explosion of 'Julia for X' packages, from power grids to differential equations


### Community

- Community-driven language design effort **'after the emergence of data science'**
- Specialist community with lots of scientific users
- Hype 'spikes' in general data science community which would quickly diminish
"""

# ╔═╡ c58aa54f-8c8b-474f-acd0-b19dc9d7c481
md"""

## 1️⃣ Truncated History of Post v1.x Julia

> 'Why would I need to use Python' era.

### Language

- Easy to write code
- Package manager best in class (vs Python, R)
- Ecosystem mature enough to compete on 'just another data science project'

### Community

- Subject matter developers come together within ecosystems like Queryverse, JuliaData, SciML
- Increased, durable visibility in general data science community
- Lots of content generation: blog posts, high volume Discourse, active Slack, Twitter community

"""

# ╔═╡ caff927b-6b81-4009-9220-ccfdfa039fbd
md"""

##  Two Waves of Adoption, Two Target Audiences

### 1. Performance Pros
- Significant general computing experience
- Often become Julia package maintainers
- Used to language's 'quirks'
- Sold on Julia's performance advantages

### 2. Amateur Adopters
- Limited time writing Julia code
- In general, skew towards 'computing' newcomers
- Intrigued by Julia's ease of use

"""

# ╔═╡ bb4876e4-24ea-436e-827b-053b42cdd7bc
cm"""

## 👏 Pluto Converts 'Amateur Adopters' to Julia 👏

- Simply 'a better notebook'
- Introductory course material lets you 'follow along'
- Expressive syntax with an emphasis on **Markdown**!

"""

# ╔═╡ b6066ae1-c5ba-40e2-b265-4466381acc08
md"""

## In Pluto, combining text and code with markdown is as easy as ``\$(1 + 1)`` = $(1 + 1)

**...but not so fast...**

"""

# ╔═╡ 21204e04-d06f-44ed-9976-4e19f8650d78
md"""

!!! note "Danger ‼️ Here be dragons"

	 There are many longstanging 'quirks' to Julia's [Markdown support](https://github.com/JuliaLang/julia/issues?q=is%3Aissue+is%3Aopen+markdown+formatting). Let's look at one example below:

"""

# ╔═╡ 48e31668-64f9-4d57-b514-56b3328790e5
var = 1

# ╔═╡ a758f697-bc48-4ac3-980e-d8b9d38a8b79
md"""

For example, as reported [here](https://github.com/JuliaLang/julia/issues/38229), the following code:

```julia
md"$(var) value is has newline. But next inline use of $(var) works as expected"
```

Yields this output:

$(var) value is has newline. But next inline use of $(var) works as expected

"""

# ╔═╡ 67c5b2d1-fc22-4d14-acad-6a282f4e88e5
cm"""
And here:

```julia

$(1 + 1) $(1 + 1)

$(1 + 1)$(1 + 1)

 $(1 + 1) $(1 + 1)


 $(1 + 1)$(1 + 1)

```

Yields this inscruitable output:
"""

# ╔═╡ f59007c6-bc65-41ea-9566-4f60d1b52d3c
md"""

$(1 + 1) $(1 + 1)

$(1 + 1)$(1 + 1)

 $(1 + 1) $(1 + 1)


 $(1 + 1)$(1 + 1)

"""

# ╔═╡ 72d16cfd-304b-4d71-8fe6-13b6535ac750
cm"""

## Julia's Markdown challenges known since 2016...

"""

# ╔═╡ aaf1dc78-a3d0-4727-b8cf-78d71dcf6a4c
md"""

## Why has progress on Markdown stalled?

- Markdown is part of stdlib and used throughout core language for docs
- Existing features of 'dollar math' and 'dollar interpolation' relied upon by advanced users, but mean that 'intuitive' parsing is at times impossible
- Test suite is not comprehensive, changes to code can have unknown consequences


## But Julia manages to elegantly solve far more difficult issues...

## Why does Julia struggle with Markdown?

- Julia solves 'two-language problem' by creating a 'two-community' problem
- 'Pros' and 'Adopters' share a single language
- 'Pros' are familiar with (avoiding) quirks, use Julia for comparative performance advantages
- 'Adopters' demand 'ease of use', but often not (yet) in a position to contribute code towards this goal



"""

# ╔═╡ 86b2c3d1-069e-4dda-b0f2-53d64c2d88f5
cm"""

## Julia's Package Ecosystem Comes to the Rescue...

- Use [CommonMark.jl](https://github.com/MichaelHatherly/CommonMark.jl)!
- ``cm`` macro is a drop-in replacement for Julia Markdown's ``md``

```
using CommonMark


cm"
$(1 + 1) $(1 + 1)

$(1 + 1)$(1 + 1)

 $(1 + 1) $(1 + 1)


 $(1 + 1)$(1 + 1)

"
```

yields:

"""

# ╔═╡ 065a2a31-1e11-4e64-be1c-fa92168e57c6

cm"""
$(1 + 1) $(1 + 1)

$(1 + 1)$(1 + 1)

 $(1 + 1) $(1 + 1)


 $(1 + 1)$(1 + 1)


"""

# ╔═╡ f7226fe5-fe27-4dbc-b471-743129906000
md"""

## CommonMark.jl Resolves Markdown Issues

- Consistent, normed Markdown implementation
- Independent spec test suite which is used across many languages beyond Julia
- Dollar math, which is related to many issues and ambiguities is deactivated by default, instead just use `````math`` !

"""

# ╔═╡ 49f2cd4f-7f39-4530-97a9-812ffb3a492f
cm"# Conclusion..."

# ╔═╡ 2ad1275a-38b5-4945-a6a7-b4a3c775b42c
md"""

## There are some things CommonMark.jl can solve, for everything else, there's *community building*...


- Julia solves two-language problem, a technical hurdle
- This creates the 'two-communities sharing one language problem', a human one
- In order to maximize the potential of Julia's technical advances, it will be necessary to align the interests of the different Julia adopters


"""

# ╔═╡ f2e8f2ef-493a-4939-a7f4-bd96700cfeb9
cm"""

!!! note "A final warning"

	Just because Julia can enable the development of high-performance and easy-to-use applications doesn't mean it will...Markdown is sufficient proof and the oldest issue summarizing these challenges dates back four years to [2017.](https://github.com/JuliaLang/julia/issues/22076)
"""

# ╔═╡ Cell order:
# ╟─47fa40d8-963a-11eb-1666-172ae387f867
# ╟─b12778d2-0462-40f4-913f-b4d2db404feb
# ╟─025d04f8-afa1-45a6-a681-e0e595544d63
# ╠═ecf26255-5550-48ae-a8ad-eecdf4437955
# ╟─684acf40-3ac6-4a10-900e-e2606d3b1641
# ╟─c58aa54f-8c8b-474f-acd0-b19dc9d7c481
# ╟─caff927b-6b81-4009-9220-ccfdfa039fbd
# ╟─bb4876e4-24ea-436e-827b-053b42cdd7bc
# ╟─b6066ae1-c5ba-40e2-b265-4466381acc08
# ╟─21204e04-d06f-44ed-9976-4e19f8650d78
# ╠═48e31668-64f9-4d57-b514-56b3328790e5
# ╟─a758f697-bc48-4ac3-980e-d8b9d38a8b79
# ╟─67c5b2d1-fc22-4d14-acad-6a282f4e88e5
# ╟─f59007c6-bc65-41ea-9566-4f60d1b52d3c
# ╟─72d16cfd-304b-4d71-8fe6-13b6535ac750
# ╟─aaf1dc78-a3d0-4727-b8cf-78d71dcf6a4c
# ╟─86b2c3d1-069e-4dda-b0f2-53d64c2d88f5
# ╟─065a2a31-1e11-4e64-be1c-fa92168e57c6
# ╟─f7226fe5-fe27-4dbc-b471-743129906000
# ╟─49f2cd4f-7f39-4530-97a9-812ffb3a492f
# ╟─2ad1275a-38b5-4945-a6a7-b4a3c775b42c
# ╟─f2e8f2ef-493a-4939-a7f4-bd96700cfeb9
