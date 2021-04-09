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

# ╔═╡ 438caa30-66e8-11eb-31e9-917e458e4d33
begin
    import Pkg
    Pkg.activate(mktempdir())
    Pkg.add([
        Pkg.PackageSpec(name="Plots", version="1"),
        Pkg.PackageSpec(name="StatsBase", version="0.33"),
        Pkg.PackageSpec(name="PlutoUI", version="0.7"),
        Pkg.PackageSpec(name="HypertextLiteral", version="0.6"),
    ])
    using Plots, Random, StatsBase, PlutoUI, LinearAlgebra, SparseArrays, Markdown, InteractiveUtils, HypertextLiteral
    md"Packages"
end

# ╔═╡ f36826be-93cd-11eb-3cd4-278a16171c91
	TableOfContents(aside = true)

# ╔═╡ 24d68cf0-7ed0-11eb-004b-7b2702a5de1a
md"
# Odyssey across the ocean ⛵	
"
# CC-BY-4.0 (IMOOX, TU Graz, Institute of Theoretical and Computational Physics)
# Authors: Johanna Moser, Gerhard Dorn, Wolfgang von der Linden

# ╔═╡ b4dc3a2f-f407-4b8c-a448-4849a914be99
md"""
# About the creators

We, **Johanna Moser, Prof. Wolfgang von der Linden** and **Gerhard Dorn** created this notebook in the context of teaching **Bayesian probability theory** using story telling.

In order to make the content more approachable we invented the story of **Captain Bayes and her crew** who navigate on the ocean of uncertainty and experience a lot of adventures in probability theory. 

The course is a free massive open online course (MOOC) available on the platform [`IMOOX`](https://imoox.at/mooc/local/landingpage/course.php?shortname=bayes&lang=en)

$(Resource("https://raw.githubusercontent.com/Captain-Bayes/images/main/adventure_map.gif"))

We even have a **trailer**: 
"""

# ╔═╡ 97565f62-8129-4515-852e-2a47748dacce
html"""<div style="display: flex; justify-content: center;">
<div  notthestyle="position: relative; right: 0; top: 0; z-index: 300;">
<iframe src="https://www.youtube.com/embed/gTWU6JFHxXg" width=600 height=375  frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe></div>
</div>"""

# ╔═╡ c6f9c954-54c4-48ce-8465-fc85202b79f4
begin
	
	md"""Switch to the next 8 days 📅 by clicking the up 🔼 button: 👉 $(@bind dial NumberField(0:8; default=0))"""
	#md"""$(@bind dial ClickCounterWithReset("Dial!", "Start over!"))"""
end

# ╔═╡ 89c46920-7ed0-11eb-3c5f-574d525a9f1f
md" Here again you can see our compass 🧭! Now you can change the probabilities by increasing the number next to the directions ⬅⬆➡⬇ and thus simulate wind or currents. Let's see how this might affect our journey!
"

# ╔═╡ 66966ea0-96d4-11eb-1c5c-2b06dfd9313b
begin
	hint(text, headline=md"Law of large numbers") = Markdown.MD(Markdown.Admonition("hint", string(headline), [text]));
	
	hint(md"You might have noticed that the more days our crew is sailing, the more similar the simulation is to the theoretical values. This is called the **law of large numbers**, and it tells us, that for an infinite number of days, the results of the experiment will perfectly coincide with the theoretical distribution.")
end

# ╔═╡ 2ea667f0-6f26-11eb-02fb-1335862dc98e
md" Where do you spot turtle island?

x coordinate = $(@bind x_island NumberField(0:6, default=5))

y coordinate = $(@bind y_island NumberField(0:6, default=0))"

# ╔═╡ 4ae39013-0e68-44a2-a124-402dc1f76557
md"**Question:** But before you manipulate the compass 🧭, what do you think, how do we have to change the compass probabilities to randomly reach turtle islans 🐢 (which lies 5 days in east direction) probably sooner?

👉 Increase the weight in East direction? $(@bind answer_1 CheckBox())

👉 Decrease the weights in North and South direction? $(@bind answer_2 CheckBox()) 

👉 Set West, North and South to zero? $(@bind answer_3 CheckBox()) 

👉 Increase West to the maximum? $(@bind answer_4 CheckBox()) 

"

# ╔═╡ 4e52d0f9-c2fd-4de4-b0c8-05a6b332c9bd
md"""Click here if you want to see the analytic solution using a Markov process 👉 $(@bind plot_exact CheckBox())"""

# ╔═╡ e4bbb3f0-e6f2-44a4-aa63-3bad12d14dc0
begin
	if plot_exact  == false
md" ## An exact solution for Turtle island!🐢 (hidden)"
	else md" ## An exact solution for Turtle island!🐢"
	end
end

# ╔═╡ ad8dfe0a-1184-4831-b33b-fcc42eb6e0c4
md"""Just click in the box to show Bernoulli 

the cummulative probability distribution of first return to turtle island🐢 👉$(@bind cummulative_probability CheckBox())

and the probability for the position after one year 👉$(@bind prob_dist_one_year CheckBox())"""

# ╔═╡ 59a47ad8-ed45-4765-a8e2-28cd49ae0ab2
md"## Program code"

# ╔═╡ b34109a1-5762-46ac-b95c-5c103b1552bc
function sub2ind(siz, ix,iy)
	
	return siz[1]*(iy-1) + ix
end


# ╔═╡ bdc92620-ab48-4587-a333-1578ce8a4e17
begin
	
	
	
	q_left = 0.25
	q_right = 0.25
	q_up = 0.25
	q_down = 0.25
local N = 100
diag_up = [repeat([ones(N-1)*q_up;0],(N-1));ones(N-1)*q_up]
diag_down = [repeat([ones(N-1)*q_down;0],(N-1));ones(N-1)*q_down]
	
local C = spdiagm( 1=>diag_up, -1=>diag_down, N=> ones(N^2-N)*q_right, -N => ones(N^2-N)*q_left)

	#index of turtle island:
d = CartesianIndex(N÷2 + 5, N÷2)
	
local turtle_island = sub2ind([N,N], (N+1)÷2 + 5, (N+1)÷2)
origin = sub2ind([N,N], (N+1)÷2 , (N+1)÷2)
	# make turtle island a stop position:
	C[turtle_island, :] .= 0
	C[turtle_island, turtle_island] = 1
	
	
	# lost probability weights could be sent to a special state but this is not necessary, the border / edge is given by 1-sum(pi)
	steps = 365
	time_prob = zeros(steps,1)
	out_of_simulation = zeros(steps,1)
	
	let
		pi_vec= zeros(1,N^2)
		pi_vec[origin] = 1

		
		
		
		local C10 = C^10
		for t = 1:steps
			pi_vec = pi_vec * C

			time_prob[t] = pi_vec[turtle_island]
			out_of_simulation[t] = 1-sum(pi_vec) 
		end
		global distri_markov = reshape(pi_vec, N,N)
	end
	
	
	#=end
	
	
	pdf = diff(time_prob,dims=1)
	md"theoretical values turtle island"
	
	=#
	
	md"Theoretical values turtle island Markov Chain"
	
end

# ╔═╡ 0838840f-c652-48ec-8a7c-5f01c6aaded5
if plot_exact == true
	pdf_return = diff(time_prob; dims=1)
	days_of_pos_return = [2:steps;]
	day_max_prob_return = days_of_pos_return[pdf_return[:] .== maximum(pdf_return)][1]
	max_prob_return = maximum(pdf_return)
	
	plot((2:1:steps) , pdf_return , line = (1.2, 0, :bar), xlim = [0,30], title="Reaching turtle island", xlabel="days", ylabel="probability of first arrival", label=:none)
	
		#plot!((1:1:steps) , out_of_simulation)
	end

# ╔═╡ 979bab1b-8463-4ca0-a506-d97ed2c29871
if cummulative_probability
	plot(1:steps, time_prob, line = (1, 1.0, :path), label=:none, xlabel="t | days", ylabel="probability of first arrival after t days", title="Cummulative probability")
	
	
end

# ╔═╡ d69ab95f-bd5c-4507-b24d-f12fbde4cae8
if prob_dist_one_year
heatmap(-49:50, -49:50, permutedims(distri_markov,[2,1]), clim= (0,0.0019), c = :dense, title="probability distribution after one year")
end

# ╔═╡ 264b06d9-6fea-4260-9b42-66feca66a654
begin
	# define images
bayes = "https://raw.githubusercontent.com/Captain-Bayes/images/main/bayes_50px.gif"
	ernesto_short = "https://raw.githubusercontent.com/Captain-Bayes/images/main/Ernesto_animated.gif"
	ernesto_completed = "https://raw.githubusercontent.com/Captain-Bayes/images/main/Ernesto_completed.gif"
	bernoulli = "https://raw.githubusercontent.com/Captain-Bayes/images/main/bernoulli_100px.gif"
	turtle_island = "https://github.com/Captain-Bayes/images/blob/main/island_in_sight.gif?raw=true"
	bottle = "https://raw.githubusercontent.com/Captain-Bayes/images/main/Flaschenpost_schwimmend.gif"
	desparate_bernoulli = "https://raw.githubusercontent.com/Captain-Bayes/images/main/Bernoulli_desperate.png"
	
	bayes_large = "https://raw.githubusercontent.com/Captain-Bayes/images/main/bayes_100px.gif"
	
	md"""Images"""
	
	
	#compass = Resource("https://raw.githubusercontent.com/Captain-Bayes/images/main/Kompass_empty.png") 
end

# ╔═╡ 1aa40340-9382-11eb-1031-5fa5b0f133ee
begin
local	rng1 = MersenneTwister(32) #seperate rng so that it won't actualize again when you're further down
	dir_index = 5 .-sum(rand(rng1, 1, 8).<=cumsum([0.25, 0.25, 0.25, 0.25]), dims = 1)
local	K_start = [sum(dir_index[1:j] .== i) for i in 1:4, j in 1:8]
	pos_start = [0 0; K_start[1,:] - K_start[3,:] K_start[2,:] - K_start[4,:]]
	
	dial_index = Integer(round(dial,digits=0))
	
	md" ## Welcome 
to this random journey! Each day we choose the sailing direction randomly. Hmm, let us try to use my famous random compass for this navigation! 

Can you help me with the dial process? Just switch to the next days by clicking the up button 🔼, and see what happens!
	
$(Resource(bayes, :width => 200))"
	#Can you help me with to dial? Click the button below, and see what happens! 
	
end

# ╔═╡ 5d25f3a0-93a4-11eb-3da6-c96ae54a0d70
begin
	
	if dial_index > 0 && dial_index < 9
		
	lim_start = maximum(abs.(pos_start[:]))
	plot(
			pos_start[1:dial_index+1,1], pos_start[1:dial_index+1,2], 
			linecolor   = :green,
			linealpha = 0.2,
			linewidth = 2, aspect_ratio =:equal,
			marker = (:dot , 5, 0.2, :green),
			label=false,
			xlim =[-lim_start, lim_start],
		    ylim =[-lim_start, lim_start],
			legend = :bottom
			)
	plot!(
			[0],[0],
			marker = (:dot, 10, 1.0, :red),
			label = "initial position"
			)

	plot!(
			[pos_start[dial_index+1,1]], [pos_start[dial_index+1,2]],
			marker = (:circle, 10, 1.0, :green),
			label = "current position"
			)
	
	end
end

# ╔═╡ 38fd06d0-93cc-11eb-030e-a7888d7d7eee
begin
#dial first steps


local dir = ["E", "N", "W",  "S"]
local word = [ "east", "north", "west" ,"south"]
local url = ["https://raw.githubusercontent.com/Captain-Bayes/images/main/Kompass_east-export.gif", "https://raw.githubusercontent.com/Captain-Bayes/images/main/Kompass_north-export.gif",  "https://raw.githubusercontent.com/Captain-Bayes/images/main/Kompass_west-export.gif",  "https://raw.githubusercontent.com/Captain-Bayes/images/main/Kompass_south-export.gif"]

		
if dial_index < 8	&& dial_index > 0
	md"Well done! The compass needle landed on **$(dir[dir_index[dial_index]])**. Seems like we'll be heading **$(word[dir_index[dial_index]])wards** today! $(Resource(url[dir_index[dial_index]], :width => 200))"
elseif dial_index >= 8
		md"""
		$(Resource(ernesto_short, :width => 30))
		
		**Thank you for helping Captain Bayes dial the compass! From now on, she can handle it on her own. Scroll down further to see the whole journey of our crew. You can also change the seed to see different possible journeys!** """
	end
		
end

# ╔═╡ 9d9726dd-3456-4988-ae96-c25129092c39
md"""
That's cool! But how will we know where we'll (most likely) end up?

$(Resource(bernoulli, :width => 200))

Click here to find out! 👉 $(@bind see_distribution CheckBox())
"""

# ╔═╡ 702cce30-8047-11eb-015b-c5fb0509a38f
begin
	if see_distribution == false
	md" ## Probability distribution (hidden)"
	else
		md" ## Probability distribution"
	end
end

# ╔═╡ 299d527e-96e7-11eb-32c5-05fdf76bb79f
md"$(Resource(ernesto_completed, ))

Congrats on completing this section! You really deserve a pause! 🍍🍎🥕🥛🍵

When you're ready again, click here 👉 $(@bind see_turtle_island CheckBox())! 
"

# ╔═╡ 9579e880-8047-11eb-25cc-1710d87cbd23
begin
	if see_turtle_island  == false
md" ## Let's go to Turtle island!🐢 (hidden)"
	else md" ## Let's go to Turtle island!🐢"
	end
end


# ╔═╡ 11336f00-96e6-11eb-2434-8bac971b9849
md" $(Resource(turtle_island, :width => 700))

 **Bernoulli:** Look, there is a giant turtle over there! 


**Bayes:** This must be turtle island! I  hear they have the most delicious fresh lemonade there!


**Bernoulli:** Oh how wonderful, I really long for some fresh lemonade! Let's just go there!


**Bayes:** Wait ... we are currently  analyzing our journey with the random compass 🧭, and I don't want to stop this experiment early. And sooner or later we will reach the island for sure. Bernoulli, why don't you try to figure out how long it will take to reach that island 🐢🏝 on average?
Just perform **random walks** 🤪🌀 on your ship map and count how often we hit the island.
You could then produce a histogram showing us the statistical likelihood of reaching the island within a certain amount of time. The median of the arrival times of your simulated journeys should be an appropriate benchmark." #formulierung

# ╔═╡ f16d2de5-2473-432d-9b8e-c0482fa74031
md" $(Resource(desparate_bernoulli, :width=>100)) Oh that's sooo long 😰. But if the wind and the currents were different, we could get there a lot faster! Oh dear reader, will you tinker once again with the probabilities of our compass, so I can get my lemonade faster? Don't tell the Captain though!🤫
"


# ╔═╡ 5e7487fb-cab0-4bae-ae33-7537469d530e
md" $(Resource(bayes_large, :width=>180)) **Bernoulli, there must be a more accurate solution!**

A friend of mine - Markov - has some brilliant ideas - let's see if we can apply them.
The probabilities for the next day should depend on those of the previous. If we just multiply this vector with this transfer matrix... 
    
 >$\vec{P}^{(t+1)} = M \cdot \vec{P}^{(t)}$

Bernoulli, just have a look 😀

"

# ╔═╡ 454efd23-d99a-4d99-b348-1336dfe294a5
md"$(Resource(bernoulli, :width=>180)) Brilliant, so it seams the highest probability to reach turtle is on **the $(day_max_prob_return) day** with a **probability of $(round(max_prob_return; digits=4))**...

Puh, that's not much! Oh, I what may be the chances that I get there within a year?

Can you show me the cummulative probabilities and where we might be after one year?
"

# ╔═╡ e130ac04-e3eb-4be5-ae6c-c87eaf7064a5
begin
	days_max_first_journey = 200
	days_max = 400
	n_reps_max = 2000
	days_slider = @bind days Slider(1:1:days_max_first_journey, show_value = true, default = 100)
	days_slider_2 = @bind days_2 Slider(1:25:days_max, show_value = true, default = 100)
	seed_slider = @bind seed NumberField(1:100, default = 20)
	seed_slider_2 = @bind seed_2 NumberField(1:100, default = 20)
	
	md"define sliders"
end

# ╔═╡ 4d6c28d0-70a9-11eb-0a98-5583ef673517
md"Now you found an old log book 📘 of a previous random walk noted by Bernoulli. Just choose the number of 👉 **$(days_slider) days** to see the path of the odyssey of our crew on the ocean.

The darker a green circle 🟢 the more often it has been visited.
"


#@bind days_clock Clock(0.3, true) 

# ╔═╡ ce4ef0c2-81d1-11eb-05fe-e590b8cf2191
md" You can also examine another random walk/odyssey by taking another logbook 📕📗📙 out of the shelf in the captain's cabin. The seed  👉 $(seed_slider) is like the ID of the book"

# ╔═╡ a3a332d0-6d8d-11eb-2157-61140f731b59
md"""**Where do we end?** By repeating our odyssee again and again we can find a probability distribution about where the ship will end up after a certain number of days. The starting point will always be [0,0] and we'll mark the endpoint after each journey. See how the distribution changes depending on the number of **repetitions** 👉 $(@bind nr_reps Slider(100:100:n_reps_max, show_value = true, default = 100)) times, 

and the number of **days** 👉 $days_slider_2 days spent travelling!

Does it look similar to the spilled **ink stain** or rather a **chessboard pattern** ♟? 
Since on even and odd days we can just reach half of the possitions you can chosse the option to average two consecutive days 👉 $(@bind averaged_final CheckBox()).

You can also simulate wind or currents by changing the probabilities on the compass 🧭."""

# ╔═╡ 9d704724-4ddc-4ef2-a8f2-ce58af8f2339
md"""So if you wish you can change the seed 👉 $(seed_slider_2) and check what median arrival time ⏱ another random sample yields"""

# ╔═╡ ae845910-8109-11eb-39a8-0182f17e791e
begin
hide_everything_below =
	html"""
	<style>
	pluto-cell.hide_everything_below ~ pluto-cell {
		display: none;
	}
	</style>
	
	<script>
	const cell = currentScript.closest("pluto-cell")
	
	const setclass = () => {
		console.log("change!")
		cell.classList.toggle("hide_everything_below", true)
	}
	setclass()
	const observer = new MutationObserver(setclass)
	
	observer.observe(cell, {
		subtree: false,
		attributeFilter: ["class"],
	})
	
	invalidation.then(() => {
		observer.disconnect()
		cell.classList.toggle("hide_everything_below", false)
	})
	
	</script>
	""";
	
md"definition hide everything below"
end

# ╔═╡ 4f304620-93cb-11eb-1da6-739664f2a105
begin
	if dial < 8
			hide_everything_below
	end
end

# ╔═╡ 81cfef50-93d4-11eb-3448-975c908bd1a2
begin
if see_distribution == false
		hide_everything_below
	end
end

# ╔═╡ e527cc7e-96e5-11eb-029c-277bfb1730dc
begin
if see_turtle_island == false
	hide_everything_below
	end
end

# ╔═╡ 0446b6c1-1a7b-4ac0-b50e-6bc7e3b60c72
begin
if plot_exact == false
		hide_everything_below
	end
end

# ╔═╡ 49b1e2ad-2129-4562-911f-a81976a6bd55
html"""
	<style>
	.compasstable td {
		font-size: 30px;
		text-align: center;
	}
	
	</style>
"""

# ╔═╡ 69d1a4d0-96c6-11eb-002f-9138e617a1c2
begin
	see_distribution 
	# used to reset the compass to make it fair again, when entering the next section
	
	W1 = @bind W Scrubbable(0:1:3, default=1)
	N1 = @bind N Scrubbable(0:1:3, default=1)
	E1 = @bind E Scrubbable(0:1:3, default=1)
	S1 = @bind S Scrubbable(0:1:3, default=1)
	
	md"define tablestyle"
end

# ╔═╡ 8510bdd0-96c6-11eb-3a9a-bd311edac8f4
@htl("""
<table class="compasstable">
	
    <tbody>
        <tr>
            <td></td>
            <td style="text-align:center">	$(N1)</td>
            <td></td>
        </tr>
        <tr>
            <td>$(W1)</td>
            <td><img src="https://raw.githubusercontent.com/Captain-Bayes/images/main/Kompass_empty.png" width=200></td>
            <td>$(E1)</td>
        </tr>
        <tr>
            <td></td>
            <td style="text-align:center">	$(S1)</td>
            <td></td>
        </tr>
    </tbody>
</table>
""")

# ╔═╡ 815094e0-93ce-11eb-3878-3be919148949
begin
	angles = [0.0, pi/2, pi, 3*pi/2, 0.0]
	numbers = [E, S, N, W]
	su = sum(numbers)
	weighted = [E/su, N/su, W/su, S/su, E/su]
	plot(angles, weighted, proj=:polar, m=2, label = "weights")
	#warum so wahnsinnig langsam?
end

# ╔═╡ c3a505f0-66e8-11eb-3540-69ce34959d64
begin
	

	
#probabilities for the four directions
prob = weighted[1:4]
# create all random variables using the seed defined above
rng = MersenneTwister(seed_2)

local sample_temp = 5 .- sum(rand(rng, 1,days_max*n_reps_max) .<= cumsum(prob), dims=1)
local sample_array = reshape(sample_temp, (days_max,:))
	
# first calculation: positions of first run -> moved to first section!
# K_first_run = [sum(sample_array[1:i,1] .== j) for j ∈ 1:4, i ∈ 1:days_max]
#pos_first_run = [0 0; K_first_run[1,:] - K_first_run[3,:]  K_first_run[2,:] - K_first_run[4,:]]

# second calculation: final positions
local K = [sum(sample_array[1:days_2,i] .== j ) for j ∈ 1:4, i ∈ 1:n_reps_max]
final_pos = [K[1,:] - K[3,:]  K[2,:] - K[4,:]]

local K2 = [sum(sample_array[1:days_2-1,i] .== j ) for j ∈ 1:4, i ∈ 1:n_reps_max]
final_pos_2 = [K2[1,:] - K2[3,:]  K2[2,:] - K2[4,:]]
	
	
	
# third calculation: return to turtle island

#flip days_max and repetitions, we only take 1000 repetitions but let the walker go 10000 days (overflow)
overfl = n_reps_max

# since approx 50% of the walker return before 10000 days we will get 2*days_max repetitions
max_runs = Integer(days_max*1.5)


local x_logic = (sample_temp.==1) - (sample_temp.==3)
local y_logic = (sample_temp.==2) - (sample_temp.==4)
	
# those vectors	will be used to display histogram
reached = zeros(max_runs)
not_reached = zeros(max_runs)
let
	ind = 0
	step = 1
	for k= 1:max_runs
		
L_reach_island = findall((cumsum(x_logic[ind .+ step .* (1:overfl)]) .== x_island) .& (cumsum(y_logic[ind .+ step .* (1:overfl)]) .== y_island))
		if isempty(L_reach_island) # not reached (overflow)
			not_reached[k] = 1
			ind = ind + overfl
		else 			# reached
			reached[k] =  minimum(L_reach_island)
			ind = Integer(ind + reached[k])
		end
		# if more than 50% of walkers for some random seed do not come back we set index to zero and take only every second value to generate a new sample set (backup to prevent error)
		if ind + overfl > length(sample_temp)
			ind = 0
			step = 2
		end
		
		
	end
end
	
	days_histogram = reached
	days_histogram[reached .== 0] .= overfl
	
	md" probability distribution and turtle island walker"
end

# ╔═╡ 8aeb5aa0-93d1-11eb-1935-9b20967fb2e3
begin 
	rng2 = MersenneTwister(seed)

local sample_array = 5 .- sum(rand(rng2, 1,days_max) .<= cumsum(prob), dims=1)
	
# first calculation: positions of first run:
 K_first_run = [sum(sample_array[1:i] .== j) for j ∈ 1:4, i ∈ 1:days_max]
pos_first_run = [0 0; K_first_run[1,:] - K_first_run[3,:]  K_first_run[2,:] - K_first_run[4,:]]
	
	
	
	
	md""" Now let's compare the directions chosen by our compass with the theoretical distribution we chose. What do you notice?"""

#how to blend in law of large numbers
end

# ╔═╡ d4a2ab30-7f4a-11eb-0a76-d50b21c3217b
begin
	median_island = StatsBase.median(days_histogram)

	plot1 = histogram(days_histogram, bins = 100, label = :none, xlabel = "days", ylabel = "occurrences")
	
	
	plot!([StatsBase.median(days_histogram)],[0], marker = "red", label = string("Median =",StatsBase.median(days_histogram)), legend=:top)
# calculate median manually:
	hist_return = [sum(days_histogram .== i) for i in 1:overfl]
	
	#med = minimum(findall(cumsum(hist_return./max_runs) .>= 0.5))
	
	#einfügen: theoretische kurve?
	
	
	
	plot1
end

# ╔═╡ 6cbe3250-805d-11eb-0f34-43f4c1669537
md"$(Resource(bernoulli, :width=>180)) The simulation is finished, Captain! Here's the histogram. Taking the median as a measure of average, it looks like we'll arrive in about $(median_island) days...

"

# ╔═╡ 10b945c9-4946-49bf-9e16-62b27b3766d7
md"""If you are still not happy with the expected time to reach turtle island, you could say our simulation was just bad luck, we only use **$(max_runs) runs** and **$(overfl) days** for each run to get the average return statistic, so maybe the true value is different 🤔."""

# ╔═╡ 76380dec-000c-43d6-957f-4fb156846ff9
@htl("""
<table class="compasstable">
	
    <tbody>
        <tr>
            <td></td>
            <td style="text-align:center">	$(N1)</td>
            <td></td>
        </tr>
        <tr>
            <td>$(W1)</td>
            <td><img src="https://raw.githubusercontent.com/Captain-Bayes/images/main/Kompass_empty.png" width=200></td>
            <td>$(E1)</td>
        </tr>
        <tr>
            <td></td>
            <td style="text-align:center">	$(S1)</td>
            <td></td>
        </tr>
    </tbody>
</table>
""")

# ╔═╡ 55e65cf6-7f5c-4faa-b271-cb78761300aa
begin
#define variables

first_steps_x = [0]
first_steps_y = [0]
	
	x0 = [0,0]

	
compass_dict = Dict("N"=> 1, "E" => 2, "S" => 3, "W" => 4)
	
	
	
compass = ["E", "N", "W", "S"] #possible directions
compass_numbers = [1, 2, 3, 4]
times_compass = [0, 0, 0, 0] #counts times every direction NESW is chosen
actual_directions = [[1, 0], [0, 1], [-1, 0],  [0, -1] ]
#calculate changes to probability:
norm = N + S + E + W
n = N/norm
e = n + E/norm
s = e + S/norm
w = s + W/norm
weights = [n, E/norm, S/norm, W/norm]
	md"variables"
end

# ╔═╡ 5cea77d0-93d1-11eb-1508-aff9495e46d8
begin
	dial
if length(first_steps_x) < 7
md"""
## One journey (hidden)"""
	else
		md"""
## One journey"""
end
end

# ╔═╡ 5b711a00-6d8c-11eb-00ac-4dd20bc3dcc6
begin
	max_x_1_run = maximum(abs.(pos_first_run[1:days,1]))
	max_y_1_run = maximum(abs.(pos_first_run[1:days,2]))
	plot(
			pos_first_run[1:days,1], pos_first_run[1:days,2], linecolor   = :green,
			linealpha = 0.2,
			linewidth = 2, aspect_ratio =:equal,
			marker = (:dot , 5, 0.2, :green),
			label=false,
			xlim = [-max_x_1_run, max_x_1_run],
			ylim = [-maximum([max_x_1_run*0.6, max_y_1_run]), maximum([max_x_1_run*0.6, max_y_1_run])]
			)
	plot!(
			[x0[1]],[x0[2]],
			marker = (:dot, 10, 1.0, :red),
			label = "initial position"
			)

	plot!(
			[pos_first_run[days,1]], [pos_first_run[days,2]],
			marker = (:circle, 10, 1.0, :green),
			label = "current position"
			)
end

# ╔═╡ 29523c50-7554-11eb-25c1-1b56caf928c5
begin
plot(compass, K_first_run[:,days]/days,
		line = (1., 1., :bar), label = "simulation", title = "cardinal directions chosen")
plot!(compass, weights, line = (1.0, 0.0, :bar), bar_width = 0.02,
    marker = (:circle, 50, 1), color = [:red], label = :none, legend = :right)
	
plot!(compass, weights,
		line = (0., 0, :path),
    normalize = false,
    bins = 10,
	bar_width = 0.2,
    marker = (7, 1., :o),
    markerstrokewidth = 1,
    color = [:red],
    fill = 1.,
    orientation = :v,
	ylabel = "Relative frequency",
	xlabel = "Directions",
	label = "theory")
end

# ╔═╡ 9600df90-7f46-11eb-2d6f-953d8166854e
begin
	
	
	
	
	
	#shifts the position [0,0] to the middle of a matrix hist_data
	max_distance_1 = maximum(abs.([final_pos[1:nr_reps,1]; final_pos[1:nr_reps,2]]))	
	max_distance_2 = maximum(abs.([final_pos_2[1:nr_reps,1]; final_pos_2[1:nr_reps,2]]))
	max_distance = maximum([max_distance_1, max_distance_2])
	# initialize with a sparse matrix, plot with a full matrix - Array command
	hist_data = sparse(final_pos[1:nr_reps,2].+max_distance.+1, final_pos[1:nr_reps,1].+max_distance.+1, 	 	 ones(size(final_pos[1:nr_reps],1)), 2*max_distance + 1, 2*max_distance + 1)
	

	
	hist_data_2 = sparse(final_pos_2[1:nr_reps,2].+max_distance.+1, final_pos_2[1:nr_reps,1].+max_distance.+1, 	 	 ones(size(final_pos_2[1:nr_reps],1)), 2*max_distance + 1, 2*max_distance + 1)
	
	
	if averaged_final
	heatmap(-max_distance:1:max_distance, -max_distance:1:max_distance, Array(hist_data + hist_data_2)./2, seriestype = :bar, c=:dense, axis = :equal) 
	else
	heatmap(-max_distance:1:max_distance, -max_distance:1:max_distance, Array(hist_data), seriestype = :bar, c=:dense) 
	end
	
	L_phi  = [0:.01:2*pi;]
	radius = sqrt(days_2) * sqrt(pi)/2
	Lc_x    = radius * cos.(L_phi) .+ days_2*(weights[2] - weights[4])
	Lc_y    = radius * sin.(L_phi) .+ days_2*(weights[1] - weights[3])
	plot!(Lc_x,Lc_y, linewidth = 2, label = "measure for mean distance")
#here are different color schemes: https://docs.juliaplots.org/latest/generated/colorschemes/
	
	#heatmap(x_array, y_array, final_position, seriestype = :bar) 
	#plot!([0],[0], marker = (:dot, 10, 1.0, :red))
end

# ╔═╡ 073ac878-52dd-4112-9b42-ad08649fe927
ClickCounterWithReset(text="Click", reset_text="Reset") = HTML("""
<div>
<button>$(text)</button>&nbsp;&nbsp;&nbsp;&nbsp;
<a id="reset" href="#">$(reset_text)</a>
</div>
<script id="blabla">
// Select elements relative to `currentScript`
const div = currentScript.previousElementSibling
const button = div.querySelector("button")
const reset = div.querySelector("#reset")
// we wrapped the button in a `div` to hide its default behaviour from Pluto
let count = 0
button.addEventListener("click", (e) => {
	count += 1
	
	div.value = count
	div.dispatchEvent(new CustomEvent("input"))
	e.stopPropagation()
})
	reset.addEventListener("click", (e) => {
	count = 0
	
	div.value = count
	div.dispatchEvent(new CustomEvent("input"))
	e.stopPropagation()
	e.preventDefault()
})
// Set the initial value
div.value = count
</script>
""")

# ╔═╡ 8e804243-9123-497d-a4b2-552f04c1d9d5
begin
almost(text, headline=md"Almost there!") = Markdown.MD(Markdown.Admonition("warning", string(headline), [text]));
#brown
	
correct(text=md"Great! You got the right answer!", headline=md"Got it!") = Markdown.MD(Markdown.Admonition("correct", string(headline), [text]));
#green
	
	
keep_working(text=md"The answer is not quite right.", headline=md"Keep working on it!") = Markdown.MD(Markdown.Admonition("danger", string(headline), [text]));
#red
md"admonitions"
end

# ╔═╡ 473d0dab-ca56-4ce7-8f0e-7a8436ea5833
begin
	if answer_1
		keep_working(md"""Rethink your answer or try it out, you will see that the "ink stain" moves far to the right ➡ missing turtle island!""", md"Not really!")
	elseif answer_2
		correct( md"You surly realized that setting North and South to zero will lead to a one dimensional random walk which will highly increase the probability to reach turtle island soon 🐢", md"""Clever!""")
	elseif answer_3
		almost(md"Well, you can try it but Captain Bayes will find out, you killed all randomness. Your manipulation will directly steer the ship onto turtle island, so you definitly will reach it in 5 days, but that's no random walk anymore!.", "This is kind of cheating")
	elseif answer_4
		keep_working(md"Maybe you are like Magellan and hope to circumnavigate the globe to tackle turtle island from a direction it would not expect^^. Well played, but this definitly takes tooo long. And be careful in a pure Eucledian space setting East to zero would destroy your dream from ever drinking lemonade on turtle island beach.", md"Wrong direction!")
	end
	#almost, correct, keep_working
	
end

# ╔═╡ Cell order:
# ╟─f36826be-93cd-11eb-3cd4-278a16171c91
# ╟─24d68cf0-7ed0-11eb-004b-7b2702a5de1a
# ╟─b4dc3a2f-f407-4b8c-a448-4849a914be99
# ╟─97565f62-8129-4515-852e-2a47748dacce
# ╟─1aa40340-9382-11eb-1031-5fa5b0f133ee
# ╟─c6f9c954-54c4-48ce-8465-fc85202b79f4
# ╟─38fd06d0-93cc-11eb-030e-a7888d7d7eee
# ╟─5d25f3a0-93a4-11eb-3da6-c96ae54a0d70
# ╟─4f304620-93cb-11eb-1da6-739664f2a105
# ╟─5cea77d0-93d1-11eb-1508-aff9495e46d8
# ╟─4d6c28d0-70a9-11eb-0a98-5583ef673517
# ╟─ce4ef0c2-81d1-11eb-05fe-e590b8cf2191
# ╟─5b711a00-6d8c-11eb-00ac-4dd20bc3dcc6
# ╟─89c46920-7ed0-11eb-3c5f-574d525a9f1f
# ╟─8510bdd0-96c6-11eb-3a9a-bd311edac8f4
# ╟─815094e0-93ce-11eb-3878-3be919148949
# ╟─8aeb5aa0-93d1-11eb-1935-9b20967fb2e3
# ╟─29523c50-7554-11eb-25c1-1b56caf928c5
# ╟─66966ea0-96d4-11eb-1c5c-2b06dfd9313b
# ╟─9d9726dd-3456-4988-ae96-c25129092c39
# ╟─81cfef50-93d4-11eb-3448-975c908bd1a2
# ╟─702cce30-8047-11eb-015b-c5fb0509a38f
# ╟─a3a332d0-6d8d-11eb-2157-61140f731b59
# ╟─9600df90-7f46-11eb-2d6f-953d8166854e
# ╟─299d527e-96e7-11eb-32c5-05fdf76bb79f
# ╟─e527cc7e-96e5-11eb-029c-277bfb1730dc
# ╟─9579e880-8047-11eb-25cc-1710d87cbd23
# ╟─11336f00-96e6-11eb-2434-8bac971b9849
# ╟─2ea667f0-6f26-11eb-02fb-1335862dc98e
# ╟─6cbe3250-805d-11eb-0f34-43f4c1669537
# ╟─d4a2ab30-7f4a-11eb-0a76-d50b21c3217b
# ╟─f16d2de5-2473-432d-9b8e-c0482fa74031
# ╟─4ae39013-0e68-44a2-a124-402dc1f76557
# ╟─473d0dab-ca56-4ce7-8f0e-7a8436ea5833
# ╟─76380dec-000c-43d6-957f-4fb156846ff9
# ╟─10b945c9-4946-49bf-9e16-62b27b3766d7
# ╟─9d704724-4ddc-4ef2-a8f2-ce58af8f2339
# ╟─5e7487fb-cab0-4bae-ae33-7537469d530e
# ╟─4e52d0f9-c2fd-4de4-b0c8-05a6b332c9bd
# ╟─0446b6c1-1a7b-4ac0-b50e-6bc7e3b60c72
# ╟─e4bbb3f0-e6f2-44a4-aa63-3bad12d14dc0
# ╟─0838840f-c652-48ec-8a7c-5f01c6aaded5
# ╟─454efd23-d99a-4d99-b348-1336dfe294a5
# ╟─ad8dfe0a-1184-4831-b33b-fcc42eb6e0c4
# ╟─979bab1b-8463-4ca0-a506-d97ed2c29871
# ╟─d69ab95f-bd5c-4507-b24d-f12fbde4cae8
# ╟─59a47ad8-ed45-4765-a8e2-28cd49ae0ab2
# ╟─b34109a1-5762-46ac-b95c-5c103b1552bc
# ╟─bdc92620-ab48-4587-a333-1578ce8a4e17
# ╟─264b06d9-6fea-4260-9b42-66feca66a654
# ╟─55e65cf6-7f5c-4faa-b271-cb78761300aa
# ╟─e130ac04-e3eb-4be5-ae6c-c87eaf7064a5
# ╟─c3a505f0-66e8-11eb-3540-69ce34959d64
# ╟─438caa30-66e8-11eb-31e9-917e458e4d33
# ╟─ae845910-8109-11eb-39a8-0182f17e791e
# ╟─49b1e2ad-2129-4562-911f-a81976a6bd55
# ╟─69d1a4d0-96c6-11eb-002f-9138e617a1c2
# ╟─073ac878-52dd-4112-9b42-ad08649fe927
# ╟─8e804243-9123-497d-a4b2-552f04c1d9d5
