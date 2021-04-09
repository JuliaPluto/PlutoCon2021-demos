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

# ╔═╡ 70b00e85-709e-4312-b2ce-4e76662d7470
begin
    import Pkg
    # activate a clean environment
    Pkg.activate(mktempdir())

    Pkg.add([
        Pkg.PackageSpec(name="Plots"),
        Pkg.PackageSpec(name="PlutoUI"),
    ])

    using Plots
    using PlutoUI
end

# ╔═╡ fd03a0f0-093c-4055-8ad5-d81434fb641c
md"""
# The 10-armed testbed: learn by implementing!

Author: [Rodrigo Chang](https://github.com/rafaelchp)

I was reading Sutton and Barto's book (2ed) on Reinforcement Learning, section 2.3, where they explain about the k-armed bandit problem and I realized that maybe it would not be so hard to implement an interactive version of figure 2.2 of the book. I share my work here to show that sometimes you can implement something as you read and that is a great way to learn and practice the concepts you are studying.

My workflow: 

- I created the module Bandits and started writing functions and trying them in next cells. 
- When I was happy with the result, I added the interactivity and plots.

Have fun!

"""

# ╔═╡ 3d72c6c0-3993-11eb-00ef-d5c730735203
# Provides functions to K-armed bandits example
module Bandits

	# Action selection algorithm
    function epsilon_greedy(Q_a, epsilon) 
        if rand() < epsilon
            action_index = rand(1:length(Q_a))
        else
            action_index = argmax(Q_a) 
        end
        action_index
    end

    function run_episode(k=10, steps=1000, epsilon=0)
        Q_star = randn(k)
        Q_a = zeros(k) # Ac
        N_a = zeros(Int, k) # number of times choosing every bandit
        rewards = zeros(steps)

        for i in 1:steps
            # select action
            a = epsilon_greedy(Q_a, epsilon)
            # get reward from bandit, ~  N(Q_star(a), 1)
            r = Q_star[a] + randn()
            N_a[a] += 1 
			# Incremental implementation
            Q_a[a] +=  (1/N_a[a]) * (r - Q_a[a])

            rewards[i] = maximum(Q_a)
        end
        
        rewards
    end

    # This runs several episodes with different bandits to measure 
    # performance of ϵ-greedy algorithm
    function run_series(episodes=2000, steps=1000, k = 10, epsilon=0)
        rewards = zeros(steps)
        for j in 1:episodes 
            rewards .+= run_episode(k, steps, epsilon)
        end
        rewards / episodes
    end


    # For optimal action selection
    function run_episode_opt(k=10, steps=1000, epsilon=0)
        Q_star = randn(k)
        Q_a = zeros(k)
        N_a = zeros(Int, k)
        opt_choice_times = 0
        opt_choice = zeros(steps)

        for i in 1:steps
            # select action
            a = epsilon_greedy(Q_a, epsilon)
            # get random reward from bandit, (distributes) ~ Normal(Q_star(a), 1)
            r = Q_star[a] + randn()
            N_a[a] += 1 
            Q_a[a] +=  (1/N_a[a]) * (r - Q_a[a])

            opt_choice_times += argmax(Q_star) == a
            opt_choice[i] = opt_choice_times / i
        end

        opt_choice 
    end

    # This runs several episodes with different bandits to measure 
    # performance of action selection of ϵ-greedy algorithm
    function run_series_choice(episodes=2000, steps=1000, k = 10, epsilon=0)
        opt_choice = zeros(steps)
        for j in 1:episodes 
            opt_choice .+= run_episode_opt(k, steps, epsilon)
        end
        opt_choice / episodes
    end

end

# ╔═╡ 25d02380-3995-11eb-370a-d3c279867efa
md"""
$ \epsilon = $ $(@bind ϵ Slider(0:0.01:1, default=0.1; show_value=true))
"""

# ╔═╡ d40dd9d8-b760-47da-abf8-633cf5dc807c
if ϵ == 0
	md"You're greedy!"
elseif ϵ > 0.2
	md"You like to explore a **lot**!"
else
	md"You like to explore a little!"
end

# ╔═╡ d3f69df2-3994-11eb-3bb2-0f343afdf320
md"""
Number of armed bandits $ k = $ $(@bind k Slider(2:20; default= 10, show_value=true))
"""

# ╔═╡ 6675960e-3993-11eb-0b7f-27011d55534e
md"""
Steps = $(@bind steps Slider(50:50:2000; default = 1000, show_value=true))
"""

# ╔═╡ c456a300-3993-11eb-0e14-577ff52d4d3b
md"""
Episodes = $(@bind episodes Slider(5:5:3000; default=2000, show_value=true))
"""

# ╔═╡ d0c8ac00-3993-11eb-08e0-b372e56d2381
begin
	# Average reward and % of time of optimal choice
	performance_e1 = Bandits.run_series(episodes, steps, k, ϵ)
	opt_choice = 100 * Bandits.run_series_choice(episodes, steps, k, ϵ)
	
	p1 = plot(1:steps, performance_e1; 
		linewidth = 2,
		label = "Average reward", 
		legend = :bottomright)
	title!("Average reward over $episodes episodes with ϵ=$ϵ")
	p2 = plot(1:steps, opt_choice; 
		linewidth = 2,
		label = "% optimal action", 
		legend = :bottomright)
	plot(p1, p2, layout = (2, 1))
end

# ╔═╡ Cell order:
# ╟─fd03a0f0-093c-4055-8ad5-d81434fb641c
# ╠═70b00e85-709e-4312-b2ce-4e76662d7470
# ╠═3d72c6c0-3993-11eb-00ef-d5c730735203
# ╟─25d02380-3995-11eb-370a-d3c279867efa
# ╟─d40dd9d8-b760-47da-abf8-633cf5dc807c
# ╟─d3f69df2-3994-11eb-3bb2-0f343afdf320
# ╟─6675960e-3993-11eb-0b7f-27011d55534e
# ╟─c456a300-3993-11eb-0e14-577ff52d4d3b
# ╠═d0c8ac00-3993-11eb-08e0-b372e56d2381
