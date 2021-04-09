### A Pluto.jl notebook ###
# v0.14.1

using Markdown
using InteractiveUtils

# ╔═╡ da13b180-97c4-11eb-257c-358495df9420
md"""
# Cell Dependencies and Execution Barriers
"""

# ╔═╡ a54f1f83-60ad-411f-aa52-bbe4116e3b8d
md"""
## Motivation
"""

# ╔═╡ 5d39d078-2a89-422c-b1e4-4ccb26b77f32
md"""
Reactivity is great!

* There is no hidden state which could introduce bugs or non-reproducible behavior - see [Joel Grus - I don't like notebooks.](https://docs.google.com/presentation/d/1n2RlMdmv1p25Xy5thJUhkKGvjtV-dkAIsUXP-AL4ffI/edit?usp=sharing)

* If you change any variable / slider / whatever, all dependent cells are automatically updated.

* ... (you probably know, because you are here!)

"""

# ╔═╡ f286571e-fab6-4cc4-bf23-000ffd4e68b5
md"""
**But why is my 10 minute-long calculation executed all over again ?!?**

* Dependencies are not always obvious (and sometimes even accidential)

* Maybe I do not want reactivity for this specific cell, because it takes too long to execute.
"""

# ╔═╡ 056613b1-fc66-439f-a333-f86c9735535d
md"""
How could we improve this?

1. Make it visible which cell depends on what  [Cell Dependencies](https://github.com/fonsp/Pluto.jl/pull/891)

2. Mark specific cells not to be updated automatically [Execution Barriers](https://github.com/fonsp/Pluto.jl/pull/985)

"""

# ╔═╡ a866c509-3c98-41a5-bc4a-1ba6c97ae0e6
md"""
## Cell Dependencies
"""

# ╔═╡ 3fde6b14-bc4d-4c38-86d7-a5d0cba738df
md"""
From Pluto V0.14.1 on, all information about cell dependencies and cell execution order is available in the frontend!

However, there no GUI implemented yet to show this - maybe you want to help?
"""

# ╔═╡ cb191d2b-5f8c-450d-a78e-65ccfe1f2e17
md"""
**Execution order of cells** - this corresponds to the order the cells are saved in the `notebook.jl` file (not the order shown in Pluto).
"""

# ╔═╡ b4d39d30-b7aa-4218-acc2-7a588cfeabba
html"""
<script>
console.log(editor_state.notebook.cell_execution_order)
</script>
"""

# ╔═╡ 4901d093-6d13-4775-8a8c-c077971d314d
md"""
**Cell dependencies**

a. upstream dependencies: variables used in a cell and where they are defined (if this is done inside the notebook)

b. downstream dependencies: variables defined in this cell and where they are used.
"""

# ╔═╡ 62e3d2c4-3363-4937-aa52-406d134be32b
html"""
<script>
console.log(editor_state.notebook.cell_dependencies)
</script>
"""

# ╔═╡ 0335c8bc-fe4e-434d-b693-b5b3c66e2a5a
md"""
### Cell Dependencies as UML Diagram
"""

# ╔═╡ e63de887-1b7b-45b0-8b8c-a2006d4608b4
"""
<div>
	graph LR
	<p id="dependencies"></p>
</div>

<script>
function short_uuid(uuid) {return uuid.substring(0,5)}
function validate(text)
{
    var isValid=false;
	var i=0;
    if(text != null && text.length>0 && text !='' )
    {
        isValid=true;
        for (i=0;i<text.length;++i)
        {
            if(text.charCodeAt(i)>=128)
            {
                isValid=false;
            }
        }

    }
    return isValid;
}

var i;
var text = "";
var uuid;
var uuid_s;
var cell;
var references;
for (i = 0; i < editor_state.notebook.cell_execution_order.length; i++) {
	uuid = editor_state.notebook.cell_execution_order[i];
	uuid_s = short_uuid(uuid) 
    cell =  editor_state.notebook.cell_dependencies[uuid];
    references = cell.downstream_cells_map;

    if (references) {
		Object.keys(references).forEach(function(ref_var) {
			Object.values(references[ref_var]).forEach(function(ref_cell) {
				if(validate(ref_var)) {
					text += uuid_s + " -- " + ref_var + " --> " + short_uuid(ref_cell) + "<br/>";
				} else {
					text += uuid_s + " --> " + short_uuid(ref_cell) + "<br/>";
				}
			})
		})
	};    
  
};

document.getElementById("dependencies").innerHTML = text;
</script>""" |> HTML

# ╔═╡ f902247e-a892-4a09-bc17-f17901d47b05
md"""
## Execution Barrier (WIP)

Note: the following only works when using Pluto with this 
[Draft Pull Request](https://github.com/fonsp/Pluto.jl/pull/985)
"""

# ╔═╡ c7a7d526-f8a0-48a8-854e-56b116c40f41
md"""
### Use Cases:

* give a method to prevent auto-update of cells which take too long to compute to keep the notebook reactive and/or save computational resources.

* step-by-step computations for educational purposes


"""

# ╔═╡ b8ec2f3c-71be-4cf9-876f-5c3116d1f03b
md"""
### Approach:

1. The execution barrier can be activated or deactivated by right-click on the run button  below the Pluto cell.

2. The cell(s) with execution barriers are not executed, as well as any other cell depending on the output (directly or indirectly) of a deactivated cell. This is graphically shown in Pluto.

3. If a barrier is deactivated, the corresponding cell and all its downstream dependencies are automatically re-executed.

4. The execution barrier information is saved inside the `notebook.jl` file for persistence. This is done in a backward compatible way - if the Pluto version does not support execution barriers, they are shown as comments in the cells.



"""

# ╔═╡ 21f710f2-8c3b-43fd-81c8-0c0ad9943236
md"""
## Demo
"""

# ╔═╡ 579f5cb3-00c8-4d9e-aea2-e0724525a493
x = 10

# ╔═╡ 2a599d22-0457-44ac-bd19-acba77322176
y = begin
	sleep(2)
	2x
end

# ╔═╡ 0ddad8dc-603a-43ab-aebf-57862643d23d
z = sqrt(y)

# ╔═╡ fa91974d-9f4c-4c65-95c2-d01f52cad465
y^2

# ╔═╡ 28772ce7-de33-41cf-9eff-b32838bf3aaf
a = 3x

# ╔═╡ f08bc1e7-4229-466f-b1ba-a5df0333eb47
z^3

# ╔═╡ 94971c75-cf66-46a6-a64d-74c1901ce0bd
u = begin
	sleep(1.5)
	4y
end

# ╔═╡ 56124d79-b192-40dc-b6ba-a7e13b0a1764
md"""
# Appendix
"""

# ╔═╡ b5de0179-a1c6-409a-bfc5-5e2ca100641e
begin
	struct UML
		code:: String
	end
	function Base.show(io::IO, ::MIME"text/html", uml::UML)
		print(io, """
		<!DOCTYPE html>
		<body>
			<div class="mermaid">
				$(uml.code)
			</div>
			<script src="https://cdn.jsdelivr.net/npm/mermaid@8.9.1/dist/mermaid.min.js"></script>
			<script>mermaid.initialize({startOnLoad:true});</script>
		</body>
		</html>
		""")
	end
end

# ╔═╡ 6581764c-2f28-49b3-803a-1008c7143cbb
UML("""graph LR
579f5 -- x --> 2a599
579f5 -- x --> 28772
2a599 -- y --> 0ddad
2a599 -- y --> fa919
2a599 -- y --> 94971
0ddad -- z --> f08bc
b5de0 -- UML --> 65817
b5de0 -- UML --> 467f8
	""")

# ╔═╡ Cell order:
# ╟─da13b180-97c4-11eb-257c-358495df9420
# ╟─a54f1f83-60ad-411f-aa52-bbe4116e3b8d
# ╟─5d39d078-2a89-422c-b1e4-4ccb26b77f32
# ╟─f286571e-fab6-4cc4-bf23-000ffd4e68b5
# ╟─056613b1-fc66-439f-a333-f86c9735535d
# ╟─a866c509-3c98-41a5-bc4a-1ba6c97ae0e6
# ╟─3fde6b14-bc4d-4c38-86d7-a5d0cba738df
# ╟─cb191d2b-5f8c-450d-a78e-65ccfe1f2e17
# ╠═b4d39d30-b7aa-4218-acc2-7a588cfeabba
# ╟─4901d093-6d13-4775-8a8c-c077971d314d
# ╠═62e3d2c4-3363-4937-aa52-406d134be32b
# ╟─0335c8bc-fe4e-434d-b693-b5b3c66e2a5a
# ╟─e63de887-1b7b-45b0-8b8c-a2006d4608b4
# ╟─6581764c-2f28-49b3-803a-1008c7143cbb
# ╟─f902247e-a892-4a09-bc17-f17901d47b05
# ╟─c7a7d526-f8a0-48a8-854e-56b116c40f41
# ╟─b8ec2f3c-71be-4cf9-876f-5c3116d1f03b
# ╟─21f710f2-8c3b-43fd-81c8-0c0ad9943236
# ╠═2a599d22-0457-44ac-bd19-acba77322176
# ╠═0ddad8dc-603a-43ab-aebf-57862643d23d
# ╠═fa91974d-9f4c-4c65-95c2-d01f52cad465
# ╠═579f5cb3-00c8-4d9e-aea2-e0724525a493
# ╠═28772ce7-de33-41cf-9eff-b32838bf3aaf
# ╠═f08bc1e7-4229-466f-b1ba-a5df0333eb47
# ╠═94971c75-cf66-46a6-a64d-74c1901ce0bd
# ╟─56124d79-b192-40dc-b6ba-a7e13b0a1764
# ╠═b5de0179-a1c6-409a-bfc5-5e2ca100641e
