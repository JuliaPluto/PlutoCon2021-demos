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

# ╔═╡ 530c7a0e-0429-460d-a9a1-db5e2d636252
md"
# The backstage of reactivity
by Nick aka [malyvsen](https://github.com/malyvsen/)
"

# ╔═╡ 2d911204-8b5b-4149-9ad0-23452b617c64
md"
Hey there 👋 In this notebook, I'll try to convince you that *you could have made Pluto yourself*!

This notebook is part of [PlutoCon 2021](https://plutojl.org/plutocon2021).
It's best served together with [my presentation](https://youtu.be/JY-wmGyz9tw) 🎥
"

# ╔═╡ 2f3b04cb-fde6-4c38-92bb-96d7bde76162
md"
## Expression objects
If you write a colon `:` in front of some code, you get an *expression object* representing the syntax tree.
"

# ╔═╡ 05c94274-b55f-4f43-a044-cfb62993c445
:(toucan = 2 + can)

# ╔═╡ 47e88a71-519e-43c8-990a-0036285c0203
md"This object has a `.head` and `.args`, which represent a node in the syntax tree and its children. In this case, `.head` is the assignment operator `=` and the children are the left-hand side (the variable being assigned to) and the right-hand side (the value being assigned)."

# ╔═╡ 4d85e81c-3126-42ca-8d26-1f9175d8e290
:(toucan = 2 + can).head

# ╔═╡ f3b2970c-8bf5-4678-a45e-186ea2da589d
:(toucan = 2 + can).args

# ╔═╡ c7876964-42d4-454e-8ebe-dcf2355fbe87
md"The `:toucan` you're seeing here is a *symbol object* - it represents a variable name and can easily be turned into a string:"

# ╔═╡ f5d80aaa-9535-4ebf-b629-89576b192309
string(:toucan)

# ╔═╡ bebe01be-5600-4cc1-8c74-853f578aa58b
md"Also, check this out: `args[2]` is an expression object in itself!"

# ╔═╡ 15c2a633-fe96-4211-a39c-75e0db37f6fb
:(toucan = 2 + can).args[2]

# ╔═╡ 756ebbc3-d7a9-4364-ab41-4bcf4cf7e803
md"Now for a little it of Julia magic: `2 + can` is a function call to the function `+`:"

# ╔═╡ e2d5b08a-516e-4c16-a313-53916f6aea37
:(2 + can).head

# ╔═╡ 0eef54ca-8213-4c16-9138-4e0b071f2d64
:(2 + can).args

# ╔═╡ d9a04c8b-9a24-47b7-92e5-f1cc9aae6760
md"`.args[1]` is the function being called, and the rest of `.args` is its arguments. So `+` is secretly a function!"

# ╔═╡ 74204a6c-71e3-45ca-8ef4-fe6a223b7823
+(3, 4)

# ╔═╡ 2b8b9222-e29a-43e0-9033-a3744156f560
md"One last thing about expression objects - you can easily make them out of strings like so:"

# ╔═╡ b51b68f9-4569-4ebd-a1ae-8640623598f8
Meta.parse("toucan = 2 + can")

# ╔═╡ 43e74e84-218d-4774-9a7d-a9748265c60b
md"
## What variables does a cell use?
Let's write a function, `references`, which tells us exactly that!
"

# ╔═╡ 6904d2ee-eda2-4c0c-a909-6ead4dc99f83
function references(expression::Expr)
	if expression.head == :(=)
		references(expression.args[2])
	else
		union(references.(expression.args)...)
	end
end

# ╔═╡ bde6bfbc-7d11-43a6-91b4-b642181a31c2
references(symbol::Symbol) = Set([symbol])

# ╔═╡ 1539ad42-1700-42f1-98eb-373ca14bd3d8
references(value) = Set{Symbol}()

# ╔═╡ 8bf57412-98ed-4455-9279-9bf93f9e92b8
references(:(toucan = 2 + can))

# ╔═╡ 97dcb803-e85e-4590-94a5-da9d95b9be3e
md"## What variables does a cell assign to?"

# ╔═╡ faa762ec-b583-4658-8ee6-b94fef2a06c4
function assignments(expression::Expr)
	if expression.head == :(=)
		Set([expression.args[1]])
	else
		Set{Symbol}()
	end
end

# ╔═╡ ff83d63d-ba21-4ec3-8815-e4cdda4c73e2
assignments(:(can = 3))

# ╔═╡ 0a7990c1-f2e6-4412-827a-dfd450f630cd
md"
## When does one cell depend on another?
We'll write a function called `depends_on` which tells us whether cell `a` depends on cell `b`, i.e. whether `b` needs to be ran before `a`.

It's pretty easy! Try to figure it out before you proceed 🧙🏼
Here's how our function should behave:
"

# ╔═╡ 8607afd7-e53d-4df5-ab54-b0db1c061a5b
md"Tell me how it's done! $(@bind spoiler_time html\"<input type=checkbox>\")"

# ╔═╡ 5f9668e1-5b3f-4945-99fb-b1a0c6cc3279
if spoiler_time
	md"All we need to do is check if any of the variables referenced in cell `a` are assigned to in cell `b`."
else
	md"🛑 Don't peek!"
end

# ╔═╡ 688ab913-0269-4325-b0dd-69228ed8d801
function depends_on(a::String, b::String)
	any(
		assignment in references(Meta.parse(a))
		for assignment in assignments(Meta.parse(b))
	)
end

# ╔═╡ 019e7322-76af-429f-b082-1f4fd20ff3ee
depends_on("toucan = 2 + can", "can = 3")

# ╔═╡ 946d25e6-3e33-4b6c-a97e-a1f2068f2ae4
depends_on("toucan = 2 + can", "cat = 3")

# ╔═╡ 581c4a19-c9c1-41ee-9342-55669c72b32e
md"
## In what order should we run cells?
Julia's `sort` function can help here - it takes a \"less than\" argument, `lt`, which should be a function that returns `true` if its first argument should come before its second argument, and `false` otherwise.
"

# ╔═╡ 3723fdb5-5bf0-4494-b392-bf2ec993b66e
run_order(cells) = sort(cells, lt=!depends_on)

# ╔═╡ 287746c0-6052-4e5e-9778-302c81a4922b
run_order(["toucan = 2 + can", "can = 3", "cat = toucan"])

# ╔═╡ eddea92b-594d-4476-ae9c-6407d7c6b684
md"
## Actually running cells
Let's use Julia's `Core.eval` to run cells in the correct order.

The first argument to `Core.eval` is the module to evaluate the expression in - we'll just use `Main`. The second argument is an expression object.
"

# ╔═╡ 99db1525-9159-490e-9851-bce8bddb63a2
function run_cell!(cell::String)
	Core.eval(Main, Meta.parse(cell))
end

# ╔═╡ f475e4eb-d24d-4a50-81dd-6ad4aada7b98
run_cell!("❓ = 3")

# ╔═╡ fa741699-db8e-4f4a-bfe9-7ff1e12476ce
Main.❓

# ╔═╡ 9c0ea3c4-5008-4e37-a7ae-61b2e818fdfa
md"We're almost there! The cells below are *quite meta*, so Pluto might have trouble updating them - please help it 😇"

# ╔═╡ 64d6f615-6e82-4bcd-97ec-7fe41e9a4acf
function run_cells!(cells)
	run_cell!.(run_order(cells))
end

# ╔═╡ 413f948a-6920-4e6d-9c81-258e108671aa
run_cells!(["toucan = 2 + can", "can = 4"])

# ╔═╡ 74926ccb-7c49-4929-a13a-68bbf3f24a43
Main.can

# ╔═╡ ec2abfd2-1cba-4c41-95c1-ef29e3fafa4e
Main.toucan

# ╔═╡ 202aa645-091a-4d1f-a57d-7dc82ca36bb7
md"Bam, we did it! I hope Pluto is still magic 🪄 after you got a sneak peek behind the curtain. *Adieu!*"

# ╔═╡ Cell order:
# ╟─530c7a0e-0429-460d-a9a1-db5e2d636252
# ╟─2d911204-8b5b-4149-9ad0-23452b617c64
# ╟─2f3b04cb-fde6-4c38-92bb-96d7bde76162
# ╠═05c94274-b55f-4f43-a044-cfb62993c445
# ╟─47e88a71-519e-43c8-990a-0036285c0203
# ╠═4d85e81c-3126-42ca-8d26-1f9175d8e290
# ╠═f3b2970c-8bf5-4678-a45e-186ea2da589d
# ╟─c7876964-42d4-454e-8ebe-dcf2355fbe87
# ╠═f5d80aaa-9535-4ebf-b629-89576b192309
# ╟─bebe01be-5600-4cc1-8c74-853f578aa58b
# ╠═15c2a633-fe96-4211-a39c-75e0db37f6fb
# ╟─756ebbc3-d7a9-4364-ab41-4bcf4cf7e803
# ╠═e2d5b08a-516e-4c16-a313-53916f6aea37
# ╠═0eef54ca-8213-4c16-9138-4e0b071f2d64
# ╟─d9a04c8b-9a24-47b7-92e5-f1cc9aae6760
# ╠═74204a6c-71e3-45ca-8ef4-fe6a223b7823
# ╟─2b8b9222-e29a-43e0-9033-a3744156f560
# ╠═b51b68f9-4569-4ebd-a1ae-8640623598f8
# ╟─43e74e84-218d-4774-9a7d-a9748265c60b
# ╠═8bf57412-98ed-4455-9279-9bf93f9e92b8
# ╠═6904d2ee-eda2-4c0c-a909-6ead4dc99f83
# ╠═bde6bfbc-7d11-43a6-91b4-b642181a31c2
# ╠═1539ad42-1700-42f1-98eb-373ca14bd3d8
# ╟─97dcb803-e85e-4590-94a5-da9d95b9be3e
# ╠═ff83d63d-ba21-4ec3-8815-e4cdda4c73e2
# ╠═faa762ec-b583-4658-8ee6-b94fef2a06c4
# ╟─0a7990c1-f2e6-4412-827a-dfd450f630cd
# ╠═019e7322-76af-429f-b082-1f4fd20ff3ee
# ╠═946d25e6-3e33-4b6c-a97e-a1f2068f2ae4
# ╟─8607afd7-e53d-4df5-ab54-b0db1c061a5b
# ╟─5f9668e1-5b3f-4945-99fb-b1a0c6cc3279
# ╠═688ab913-0269-4325-b0dd-69228ed8d801
# ╟─581c4a19-c9c1-41ee-9342-55669c72b32e
# ╠═3723fdb5-5bf0-4494-b392-bf2ec993b66e
# ╠═287746c0-6052-4e5e-9778-302c81a4922b
# ╟─eddea92b-594d-4476-ae9c-6407d7c6b684
# ╠═99db1525-9159-490e-9851-bce8bddb63a2
# ╠═f475e4eb-d24d-4a50-81dd-6ad4aada7b98
# ╠═fa741699-db8e-4f4a-bfe9-7ff1e12476ce
# ╟─9c0ea3c4-5008-4e37-a7ae-61b2e818fdfa
# ╠═64d6f615-6e82-4bcd-97ec-7fe41e9a4acf
# ╠═413f948a-6920-4e6d-9c81-258e108671aa
# ╠═74926ccb-7c49-4929-a13a-68bbf3f24a43
# ╠═ec2abfd2-1cba-4c41-95c1-ef29e3fafa4e
# ╟─202aa645-091a-4d1f-a57d-7dc82ca36bb7
