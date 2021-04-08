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

# ╔═╡ 24bd1072-7fa4-4656-a485-c81991d3f1d9
using PlutoUI

# ╔═╡ 571613a1-6b4b-496d-9a68-aac3f6a83a4b
using HypertextLiteral, JSON

# ╔═╡ 97914842-76d2-11eb-0c48-a7eedca870fb
md"""
# Using _JavaScript_ inside Pluto

You have already seen that Pluto is designed to be _interactive_. You can make fantastic explorable documents using just the basic inputs provided by PlutoUI, together with the diff
"""

# ╔═╡ 168e13f7-2ff2-4207-be56-e57755041d36
md"""
https://javascript.info/
"""

# ╔═╡ d70a3a02-ef3a-450f-bf5a-4a0d7f6262e2
TableOfContents()

# ╔═╡ 5c5d2489-e48b-432f-94f8-b15333134e24
md"""
# Essentials

## Custom `@bind` output
"""

# ╔═╡ 75e1a973-7ef0-4ac5-b3e2-5edb63577927
md"""
**You can use JavaScript to write input widgets.** The `input` event can be triggered on any object using

```javascript
obj.value = ...
obj.dispatchEvent(new CustomEvent("input"))
```

For example, here is a button widget that will send the number of times it has been clicked as the value:


For better readability, you can view the script from the cell below with syntax highlighting: $(@bind show_cc_with_highlighting html"<input type=checkbox >")

"""

# ╔═╡ bfe6d760-3141-4e37-a136-d1277bd22380
if show_cc_with_highlighting === true
	md"""
	
```htmlmixed
ClickCounter(text="Click") = @htl(""\"
<div>
<button>$(text)</button>

<script>

// Select elements relative to `currentScript`
var div = currentScript.parentElement
var button = div.querySelector("button")

// we wrapped the button in a `div` to hide its default behaviour from Pluto

var count = 0

button.addEventListener("click", (e) => {
	count += 1
	
	// we dispatch the input event on the div, not the button, because 
	// Pluto's `@bind` mechanism listens for events on the **first element** in the
	// HTML output. In our case, that's the div.
	
	div.value = count
	div.dispatchEvent(new CustomEvent("input"))
	e.stopPropagation()
})

// Set the initial value
div.value = count

</script>
</div>
""\")
```
	"""
end

# ╔═╡ e8d8a60e-489b-467a-b49c-1fa844807751
ClickCounter(text="Click") = @htl("""
<div>
<button>$(text)</button>

<script>

// Select elements relative to `currentScript`
var div = currentScript.parentElement
var button = div.querySelector("button")

// we wrapped the button in a `div` to hide its default behaviour from Pluto

var count = 0

button.addEventListener("click", (e) => {
	count += 1
	
	// we dispatch the input event on the div, not the button, because 
	// Pluto's `@bind` mechanism listens for events on the **first element** in the
	// HTML output. In our case, that's the div.
	
	div.value = count
	div.dispatchEvent(new CustomEvent("input"))
	e.stopPropagation()
})

// Set the initial value
div.value = count

</script>
</div>
""")

# ╔═╡ 9346d8e2-9ba0-4475-a21f-11bdd018bc60
@bind num_clicks ClickCounter()

# ╔═╡ 7822fdb7-bee6-40cc-a089-56bb32d77fe6
num_clicks

# ╔═╡ 701de4b8-42d3-46a3-a399-d7761dccd83d
md"""
As an exercise to get familiar with these techniques, you can try the following:
- 👉 Add a "reset to zero" button to the widget above.
- 👉 Make the bound value an array that increases size when you click, instead of a single number.
- 👉 Create a "two sliders" widget: combine two sliders (`<input type=range>`) into a single widget, where the bound value is the two-element array with both values.
- 👉 Create a "click to send" widget: combine a text input and a button, and only send the contents of the text field when the button is clicked, not on every keystroke.

Questions? Ask them on our [GitHub Discussions](https://github.com/fonsp/Pluto.jl/discussions)!
"""

# ╔═╡ 88120468-a43d-4d58-ac04-9cc7c86ca179
md"""
## Debugging

The HTML, CSS and JavaScript that you write run in the browser, so you should use the [browser's built-in developer tools](https://developer.mozilla.org/en-US/docs/Learn/Common_questions/What_are_browser_developer_tools) to debug your code. 
"""

# ╔═╡ ea4b2da1-4c83-4a1f-8fc3-c71a120e58e1
html"""

<script>

console.info("Can you find this message in the console?")

</script>

"""

# ╔═╡ 08bdeaff-5bfb-49ab-b4cc-3a3446c63edc
@htl("""
	<style>
	.cool-class {
		font-size: 1.3rem;
		color: purple;
		background: lightBlue;
		padding: 1rem;
		border-radius: 1rem;
	}
	
	
	</style>
	
	<div class="cool-class">Can you find out which CSS class this is?</div>
	""")

# ╔═╡ 9b6b5da9-8372-4ebf-9c66-ae9fcfc45d47
md"""
## Selecting elements

When writing the javascript code for a widget, it is common to **select elements inside the widgets** to manipulate them. In the number-of-clicks example above, we selected the `<div>` and `<button>` elements in our code, to trigger the input event, and attach event listeners, respectively.

There are a numbers of ways to do this, and the recommended strategy is to **create a wrapper `<div>`, and use `currentScript.parentElement` to select it**.

### `currentScript`

When Pluto runs the code inside `<script>` tags, it assigns a reference to that script element to a variable called `currentScript`. You can then use properties like `previousElementSibling` or `parentElement` to "navigate to other elements".

Let's look at the "wrapper div strategy" again.

```htmlmixed
@htl("\""

<!-- the wrapper div -->
<div>

	<button id="first">Hello</button>
	<button id="second">Julians!</button>
	
	<script>
		var wrapper_div = currentScript.parentElement
		// we can now use querySelector to select anything we want
		var first_button = wrapper_dir.querySelector("button#first")

		console.log(first_button)
	</script>
</div>
"\"")
```
"""

# ╔═╡ f18b98f7-1e0f-4273-896f-8a667d15605b
md"""
#### Why not just select on `document.body`?

In the example above, it would have been easier to just select the button directly, using:
```javascript
// ⛔ do no use:
var first_button = document.body.querySelector("button#first")
```

However, this becomes a problem when **combining using the widget multiple times in the same notebook**, since all selectors will point to the first instance. 

Similarly, try not to search relative to the `<pluto-cell>` or `<pluto-output>` element, because users might want to combine multiple instances of the widget in a single cell.
"""

# ╔═╡ 4a3398be-ee86-45f3-ac8b-f627a38c00b8
md"""
## Interpolation

Julia has a nice feature: _string interpolation_:
"""

# ╔═╡ 2d5fd611-284b-4428-b6a5-8909203990b9
who = "🌍"

# ╔═╡ 82de4674-9ecc-46c4-8a57-0b4453c579c3
"Hello $(who)!"

# ╔═╡ 70a415be-881a-4c01-9f8c-635b8b89e1ad
md"""
With some (frustrating) exceptions, you can also interpolate into Markdown literals:
"""

# ╔═╡ 730a692f-2bf2-4d5b-86da-6ab861e8b8ac
md"""
Hello $(who)!
"""

# ╔═╡ a45fdec4-2d4b-429b-b809-4c256b57fffe
md"""
**However**, you cannot interpolate into an `html"` string:
"""

# ╔═╡ c68ebd7b-5fb6-4527-ac34-33f9730e4587
html"""
<p>Hello $(who)!</p>
"""

# ╔═╡ 8c03139f-a94b-40cc-859f-0d86f1c72143
md"""

😢 For this feature, we highly recommend the new package [HypertextLiteral.jl](https://github.com/MechanicalRabbit/HypertextLiteral.jl), which has an `@htl` macro that supports interpolation:


### Interpolating into HTML -- HypertextLiteral.jl
"""

# ╔═╡ d8dcb044-0ac8-46d1-a043-1073bb6d1ff1
@htl("""
	<p> Hello $(who)!</p>
	""")

# ╔═╡ e7d3db79-8253-4cbd-9832-5afb7dff0abf
cool_features = [
	md"Interpolate any **HTML-showable object**, such as plots and images, or another `@htl` literal."
	md"Interpolated lists are expanded _(like in this cell!)_."
	"Easy syntax for CSS"
	]

# ╔═╡ bf592202-a9a4-4e9b-8433-fed55e3aa3bc
@htl("""
	<p>It has a bunch of very cool features! Including:</p>
	<ul>$([
		@htl(
			"<li>$(item)</li>"
		)
		for item in cool_features
	])</ul>
	""")

# ╔═╡ 5ac5b984-8c02-4b8d-a342-d0f05f7909ec
md"""
#### Why not just `HTML(...)`?

You might be thinking, why don't we just use the `HTML` function, together with string interpolation? The main problem is correctly handling HTML _escaping rules_. For example:
"""

# ╔═╡ ef28eb8d-ec98-43e5-9012-3338c3b84f1b
currencies = "euros&pounds"

# ╔═╡ ba5ea204-cea5-40cd-bbad-86f45d2ed80d
HTML("""
<h5> We accept $(currencies)!</h5>
"""),

@htl("""
<h5> We accept $(currencies)!</h5>
""")

# ╔═╡ 7afbf8ef-e91c-45b9-bf22-24201cbb4828
md"""
### Interpolating into JS -- JSON.jl

Using HypertextLiteral.jl, we can interpolate objects into HTML output, great! Next, we want to **interpolate data into scripts**. The easiest way to do so is to use `JSON.jl`, in combination with string interpolation:
"""

# ╔═╡ 00d97588-d591-4dad-9f7d-223c237deefd
@bind fantastic_x Slider(0:400)

# ╔═╡ 01ce31a9-6856-4ee7-8bce-7ce635167457
my_data = [
	(name="Cool", coordinate=[100, 100]),
	(name="Awesome", coordinate=[200, 100]),
	(name="Fantastic!", coordinate=[fantastic_x, 150]),
]

# ╔═╡ 21f57310-9ceb-423c-a9ce-5beb1060a5a3
@htl("""
	<script src="https://cdn.jsdelivr.net/npm/d3@6.2.0/dist/d3.min.js"></script>

	<script>

	// interpolate the data 🐸
	const data = $(JSON.json(my_data))

	const svg = DOM.svg(600,200)
	const s = d3.select(svg)

	s.selectAll("text")
		.data(data)
		.join("text")
		.attr("x", d => d.coordinate[0])
		.attr("y", d => d.coordinate[1])
		.text(d => d.name)

	return svg
	</script>
""")

# ╔═╡ d83d57e2-4787-4b8d-8669-64ed73d79e73
md"""
## Script loading

To use external javascript dependencies, you can load them from a CDN, such as:
- [jsdelivr.com](https://www.jsdelivr.com/)
- [skypack.dev](https://www.skypack.dev/)

Just like when writing a browser app, there are two ways to import JS dependencies: a `<script>` tag, and the more modern ES6 import.

### Loading method 1: ES6 imports

we recommend that you use an [**ES6 import**](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules) if the library supports it.


##### Awkward note about syntax

Normally, you can import libraries inside JS using the import syntax:
```javascript
import confetti from 'https://cdn.skypack.dev/canvas-confetti'
import { html, render, useEffect } from "https://cdn.jsdelivr.net/npm/htm@3.0.4/preact/standalone.mjs"
```

In Pluto, this is [currently not yet supported](https://github.com/fonsp/Pluto.jl/issues/992), and you need to use a different syntax as workaround:
```javascript
const { default: confetti } = await import("https://cdn.skypack.dev/canvas-confetti@1")
const { html, render, useEffect } = await import( "https://cdn.jsdelivr.net/npm/htm@3.0.4/preact/standalone.mjs")
```
"""

# ╔═╡ 27e4604c-5954-44b7-a348-1650dbc6d8a9


# ╔═╡ 077c95cf-2a1b-459f-830e-c29c11a2c5cc
md"""

### Loading method 2: script tag

`<script src="...">` tags with a `src` attribute set, like this tag to import the d3.js library:

```css
<script src="https://cdn.jsdelivr.net/npm/d3@6.2.0/dist/d3.min.js"></script>
```

will work as expected. The execution of other script tags within the same cell is delayed until a `src` script finished loading, and Pluto will make sure that every source file is only loaded once.
"""

# ╔═╡ 8388a833-d535-4cbd-a27b-de323cea60e8
md"""
# Advanced
"""

# ╔═╡ 4cf27df3-6a69-402e-a71c-26538b2a52e7
md"""
## Script output
"""

# ╔═╡ a9815586-1532-4fa1-bf79-905ff9de4e92
cool_thing() = html"""



"""

# ╔═╡ 5721ad33-a51a-4a91-adb2-0915ea0efa13
md"""
### Example: 
"""

# ╔═╡ a33c7d7a-8071-448e-abd6-4e38b5444a3a
md"""
## Stateful output with `this`

"""

# ╔═╡ 91f3dab8-5521-44a0-9890-8d988a994076
trigger = "edit me!"

# ╔═╡ dcaae662-4a4f-4dd3-8763-89ea9eab7d43
let
	trigger
	
	html"""
	<script id="something">

	if(this == null) {
		return html`<blockquote>I am running for the first time!</blockqoute>`
	} else {
		return html`<blockquote><b>I was triggered by reactivity!</b></blockqoute>`
	}


	</script>
	"""
end

# ╔═╡ e77cfefc-429d-49db-8135-f4604f6a9f0b
md"""
### Example: d3.js transitions

Type the coordinates of the circles here! 
"""

# ╔═╡ 2d5689f5-1d63-4b8b-a103-da35933ad26e
@bind positions TextField(default="100, 300")

# ╔═╡ 6dd221d1-7fd8-446e-aced-950512ea34bc
dot_positions = try
	parse.([Int], split(replace(positions, ',' => ' ')))
catch e
	[100, 300]
end

# ╔═╡ 0a9d6e2d-3a41-4cd5-9a4e-a9b76ed89fa9
# dot_positions = [100, 300] # edit me!

# ╔═╡ 0962d456-1a76-4b0d-85ff-c9e7dc66621d
md"""
Notice that, even though the cell below re-runs, we **smoothly transition** between states. We use `this` to maintain the d3 transition states inbetween reactive runs.
"""

# ╔═╡ bf9b36e8-14c5-477b-a54b-35ba8e415c77
@htl("""
<script src="https://cdn.jsdelivr.net/npm/d3@6.2.0/dist/d3.min.js"></script>

<script id="hello">

const positions = $(JSON.json(dot_positions))
	
const svg = this == null ? DOM.svg(600,200) : this
const s = this == null ? d3.select(svg) : this.s

s.selectAll("circle")
	.data(positions)
	.join("circle")
    .transition()
    .duration(300)
	.attr("cx", d => d)
	.attr("cy", 100)
	.attr("r", 10)
	.attr("fill", "gray")


const output = svg
output.s = s
return output
</script>

""")

# ╔═╡ 53512329-523b-4b45-b222-1b982f49d5db


# ╔═╡ 91e9a6dc-b970-4c83-b2b9-dfaff706c28c
script(s) = HTML("""
	<script id="something">
	$s
	</script>
	""")

# ╔═╡ Cell order:
# ╟─97914842-76d2-11eb-0c48-a7eedca870fb
# ╠═168e13f7-2ff2-4207-be56-e57755041d36
# ╠═24bd1072-7fa4-4656-a485-c81991d3f1d9
# ╟─d70a3a02-ef3a-450f-bf5a-4a0d7f6262e2
# ╟─5c5d2489-e48b-432f-94f8-b15333134e24
# ╟─75e1a973-7ef0-4ac5-b3e2-5edb63577927
# ╟─bfe6d760-3141-4e37-a136-d1277bd22380
# ╠═e8d8a60e-489b-467a-b49c-1fa844807751
# ╠═9346d8e2-9ba0-4475-a21f-11bdd018bc60
# ╠═7822fdb7-bee6-40cc-a089-56bb32d77fe6
# ╟─701de4b8-42d3-46a3-a399-d7761dccd83d
# ╟─88120468-a43d-4d58-ac04-9cc7c86ca179
# ╠═ea4b2da1-4c83-4a1f-8fc3-c71a120e58e1
# ╟─08bdeaff-5bfb-49ab-b4cc-3a3446c63edc
# ╟─9b6b5da9-8372-4ebf-9c66-ae9fcfc45d47
# ╟─f18b98f7-1e0f-4273-896f-8a667d15605b
# ╟─4a3398be-ee86-45f3-ac8b-f627a38c00b8
# ╠═2d5fd611-284b-4428-b6a5-8909203990b9
# ╠═82de4674-9ecc-46c4-8a57-0b4453c579c3
# ╟─70a415be-881a-4c01-9f8c-635b8b89e1ad
# ╠═730a692f-2bf2-4d5b-86da-6ab861e8b8ac
# ╟─a45fdec4-2d4b-429b-b809-4c256b57fffe
# ╠═c68ebd7b-5fb6-4527-ac34-33f9730e4587
# ╟─8c03139f-a94b-40cc-859f-0d86f1c72143
# ╠═d8dcb044-0ac8-46d1-a043-1073bb6d1ff1
# ╠═bf592202-a9a4-4e9b-8433-fed55e3aa3bc
# ╟─e7d3db79-8253-4cbd-9832-5afb7dff0abf
# ╟─5ac5b984-8c02-4b8d-a342-d0f05f7909ec
# ╠═ef28eb8d-ec98-43e5-9012-3338c3b84f1b
# ╠═ba5ea204-cea5-40cd-bbad-86f45d2ed80d
# ╟─7afbf8ef-e91c-45b9-bf22-24201cbb4828
# ╠═01ce31a9-6856-4ee7-8bce-7ce635167457
# ╠═00d97588-d591-4dad-9f7d-223c237deefd
# ╠═21f57310-9ceb-423c-a9ce-5beb1060a5a3
# ╟─d83d57e2-4787-4b8d-8669-64ed73d79e73
# ╠═27e4604c-5954-44b7-a348-1650dbc6d8a9
# ╟─077c95cf-2a1b-459f-830e-c29c11a2c5cc
# ╟─8388a833-d535-4cbd-a27b-de323cea60e8
# ╠═4cf27df3-6a69-402e-a71c-26538b2a52e7
# ╠═a9815586-1532-4fa1-bf79-905ff9de4e92
# ╠═5721ad33-a51a-4a91-adb2-0915ea0efa13
# ╠═a33c7d7a-8071-448e-abd6-4e38b5444a3a
# ╠═91f3dab8-5521-44a0-9890-8d988a994076
# ╠═dcaae662-4a4f-4dd3-8763-89ea9eab7d43
# ╟─e77cfefc-429d-49db-8135-f4604f6a9f0b
# ╠═2d5689f5-1d63-4b8b-a103-da35933ad26e
# ╠═6dd221d1-7fd8-446e-aced-950512ea34bc
# ╠═0a9d6e2d-3a41-4cd5-9a4e-a9b76ed89fa9
# ╟─0962d456-1a76-4b0d-85ff-c9e7dc66621d
# ╠═bf9b36e8-14c5-477b-a54b-35ba8e415c77
# ╠═53512329-523b-4b45-b222-1b982f49d5db
# ╠═91e9a6dc-b970-4c83-b2b9-dfaff706c28c
# ╠═571613a1-6b4b-496d-9a68-aac3f6a83a4b
