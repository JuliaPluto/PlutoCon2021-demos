### A Pluto.jl notebook ###
# v0.14.0

using Markdown
using InteractiveUtils

# ╔═╡ c4e34a90-77b8-11eb-108e-93d91efc7480
md"## Solving Tic Tac Toe With MiniMax Trees!"

# ╔═╡ a6e0b518-4f39-45d0-b2a3-a95cb1de7114
md"First we need to build out our minimax tree for the game"

# ╔═╡ 72fc2712-61b8-43a6-b68e-b3c5c87ed0a1
struct GameState
	turn::Int8
	tiles::Array{Int8, 2}
end

# ╔═╡ e6e3a756-6526-483d-af9e-9e53cf6d9f52
Base.:(==)(x::GameState, y::GameState) = x.turn == y.turn && all(x.tiles .== y.tiles)

# ╔═╡ b3d7a96e-f3fc-4dbd-94a9-552b21426396
Base.hash(x::GameState) = hash(x.tiles)

# ╔═╡ 82323b7f-1e92-46b0-8cff-5d85152d7d5c
md"0's are empty, 1's are player 1 (x), and 2's are player 2 (o)

Our objective is to optimize the policy of player 1"

# ╔═╡ a51583a3-0faa-4bac-a60b-e763644f674d
EMPTY = 0x00

# ╔═╡ eb2f779f-c651-4444-a34d-42681de9f3c6
PLAYER_1 = Int8(1)

# ╔═╡ f0e3fa72-9acf-4325-9173-622f93497b68
PLAYER_2 = Int8(-1)

# ╔═╡ 48828553-4846-45bf-9ab1-e576b3d16ed4
md"`next_player` will return the other player"

# ╔═╡ 2a78b1ad-63cb-4cfa-98f4-a11ab05a9022
next_player(p) = p == PLAYER_1 ? PLAYER_2 : PLAYER_1

# ╔═╡ b53af45f-2c47-44ba-9e53-acb6093f4199
md"Defines the initial state of the game tiles. In tic tac toe that's just an empty 3x3 grid"

# ╔═╡ d1efdbe8-1a18-4a1c-84fc-f80dc3b9272d
initial_tiles = fill(EMPTY, 3, 3)

# ╔═╡ 26e40b02-969c-4e87-b9f2-1357ce6b50ba
md"Take our tiles and put it into a proper `GameState` structure"

# ╔═╡ e0e9cbb2-01a8-4523-a6a9-ec7cfdb351d5
initial_state = GameState(PLAYER_1, initial_tiles)

# ╔═╡ aca2dc5f-d61c-4751-bce2-c1351f85f60e
md"To build up the minimax tree we will associate each node with a `GameState`, a winner, and a list of children. The `leaf` property is true if the node has no children (`length(children) == 0`)"

# ╔═╡ e9dd6424-1031-44fb-970c-15aa3a4a1385
struct MinimaxNode
	state::GameState
	children::Vector{MinimaxNode}
	winner::Int8
	leaf::Bool
end

# ╔═╡ 283defad-afcc-4af8-88ec-f52b6b9706a5
md"Defines a function to check whether or not a player has won the game by checking each row, column, and diagonal for the same player marker"

# ╔═╡ 5feafefc-740c-4450-838d-9e2ac47ceb32
function get_winner(state::GameState)
	# Really ugly check for game winners
	# Rows
	rows = [all(state.tiles[i, :] .== state.tiles[i, 1]) ? state.tiles[i, 1] : 0 for i ∈ 1:size(state.tiles)[1]]
	cols = [all(state.tiles[:, j] .== state.tiles[1, j]) ? state.tiles[1, j] : 0 for j ∈ 1:size(state.tiles)[2]]
	diag1 = state.tiles[1, 1] == state.tiles[2, 2] && state.tiles[1, 1] == state.tiles[3, 3] ? state.tiles[1, 1] : 0
	diag2 = state.tiles[3, 1] == state.tiles[2, 2] && state.tiles[3, 1] == state.tiles[1, 3] ? state.tiles[3, 1] : 0
	
	max_rows = max(rows..., cols..., diag1, diag2)
	min_rows = min(rows..., cols..., diag1, diag2)
	
	return max_rows > 0 ? max_rows : min_rows
end

# ╔═╡ 7b143cf1-920d-4626-a927-bf33885ae7a9
# Simple test for get_winner. Notice that the -1 player has a column down the middle and is therefore the winner
get_winner(GameState(PLAYER_1, Int8[
	1 -1 1;
	-1 -1 1;
	-1 -1 0;
]))

# ╔═╡ c4773808-c442-4195-82bc-1da5074bfd77
md"Defines a function which takes a `GameState` structure and returns a list of possible subsequent moves nonrecursively"

# ╔═╡ 31ff651f-b275-46d2-97e9-206c9926dfb8
function possible_moves(state::GameState)
	moves = []
	for i ∈ 1:length(state.tiles)
		if state.tiles[i] == EMPTY
			new_tiles = copy(state.tiles)
			new_tiles[i] = state.turn
			push!(moves, GameState(next_player(state.turn), new_tiles))
		end
	end
	
	moves
end

# ╔═╡ fa48829e-59e8-4642-8256-ca3c2d7c7595
md"""
This defines the function which will recursively build a minimax tree from a starting `state`.
"""

# ╔═╡ 258017ed-4bf0-4fdd-8239-2fc381e94d0c
function build_minimax(state::GameState)
	winner = get_winner(state)
	nodes = []
	for pm ∈ possible_moves(state)
		push!(nodes, build_minimax(pm))
	end
	
	if length(nodes) > 0 && winner == EMPTY
		return MinimaxNode(state, nodes, (state.turn == PLAYER_1 ? max : min)((x->x.winner).(nodes)...), true)
	else
		return MinimaxNode(state, [], winner, true)
	end
end

# ╔═╡ 45d2cddd-adfe-470a-89bc-56fb5d5982dc
tree = build_minimax(initial_state);

# ╔═╡ d607a5e3-78f5-4308-999f-bf49858004a7
(x->x.winner).(tree.children[1].children[4].children[4].children[2].children)

# ╔═╡ c9254d06-75b9-47dc-8d29-495c80c9215d
tree.children[1].children[2].state

# ╔═╡ 15fd5bd7-d2c4-4337-a2ad-0fc43ad2b4e0
md"#### Flattening the minimax tree
Tic Tac Toe has the nice property that if a game reaches a particular state, regardless of how that state was obtained, the minimax tree from that state will be the same. Therefore we can build up a dictionary of game states for keys, and the corresponding value is yet another game state representing the best move."

# ╔═╡ 248c158c-41bc-478f-be12-b7e4ab43544d
function flatten_minimax!(flat_tree, tree)
	flat_tree[tree.state] = tree.children[argmin((x->x.winner).(tree.children))].state
	for node ∈ tree.children
		if get_winner(node.state) == EMPTY && length(node.children) > 0
			flatten_minimax!(flat_tree, node)
		end
	end
end

# ╔═╡ 72c6bdcd-6d6b-4bf4-a759-1c4256384352
begin
	flat_tree = Dict()
	flatten_minimax!(flat_tree, tree)
end

# ╔═╡ c0634c74-9228-4d05-8146-3492aaf3a8ef
flat_tree[initial_state]

# ╔═╡ decac4e3-d5d3-4a51-a5bb-fdb658dec971
md"Fantastic! As can be seen above, the minimax tree has determined that the best move for player 1 is the center square!"

# ╔═╡ 2bb59351-cb34-45a7-bd58-72409adf48fa
html"<div style='height: 50px'></div>"

# ╔═╡ 4aa39de7-db17-42d7-924f-abb486c03eed
md"### Building the API"

# ╔═╡ d5ba2170-d687-4ef8-a7fc-e8fef48b3a2c
md"Set **tiles** and **player** from the frontend"

# ╔═╡ b385f71f-c608-4be7-a0b6-30a39397451e
player = PLAYER_2

# ╔═╡ c1480936-bc64-481d-a754-31d5a35a2d6d
md"Note that tiles will be a vector of vectors, not an array"

# ╔═╡ c1cd29c9-b3dc-497b-b200-e6ad08356b39
tiles = [[0, 0, 0], [0, 1, 0], [0, 0, 0]]

# ╔═╡ 7d6a905a-2445-4569-8fe1-8e703b635218
md"And request **next_state**"

# ╔═╡ 4b879529-0359-462e-b032-3bb95a11ac36
next_state = flat_tree[GameState(player, hcat(tiles...))].tiles

# ╔═╡ Cell order:
# ╟─c4e34a90-77b8-11eb-108e-93d91efc7480
# ╟─a6e0b518-4f39-45d0-b2a3-a95cb1de7114
# ╠═72fc2712-61b8-43a6-b68e-b3c5c87ed0a1
# ╠═e6e3a756-6526-483d-af9e-9e53cf6d9f52
# ╠═b3d7a96e-f3fc-4dbd-94a9-552b21426396
# ╟─82323b7f-1e92-46b0-8cff-5d85152d7d5c
# ╠═a51583a3-0faa-4bac-a60b-e763644f674d
# ╠═eb2f779f-c651-4444-a34d-42681de9f3c6
# ╠═f0e3fa72-9acf-4325-9173-622f93497b68
# ╟─48828553-4846-45bf-9ab1-e576b3d16ed4
# ╠═2a78b1ad-63cb-4cfa-98f4-a11ab05a9022
# ╟─b53af45f-2c47-44ba-9e53-acb6093f4199
# ╠═d1efdbe8-1a18-4a1c-84fc-f80dc3b9272d
# ╟─26e40b02-969c-4e87-b9f2-1357ce6b50ba
# ╠═e0e9cbb2-01a8-4523-a6a9-ec7cfdb351d5
# ╟─aca2dc5f-d61c-4751-bce2-c1351f85f60e
# ╠═e9dd6424-1031-44fb-970c-15aa3a4a1385
# ╟─283defad-afcc-4af8-88ec-f52b6b9706a5
# ╠═5feafefc-740c-4450-838d-9e2ac47ceb32
# ╠═7b143cf1-920d-4626-a927-bf33885ae7a9
# ╟─c4773808-c442-4195-82bc-1da5074bfd77
# ╠═31ff651f-b275-46d2-97e9-206c9926dfb8
# ╟─fa48829e-59e8-4642-8256-ca3c2d7c7595
# ╠═258017ed-4bf0-4fdd-8239-2fc381e94d0c
# ╠═45d2cddd-adfe-470a-89bc-56fb5d5982dc
# ╠═d607a5e3-78f5-4308-999f-bf49858004a7
# ╠═c9254d06-75b9-47dc-8d29-495c80c9215d
# ╟─15fd5bd7-d2c4-4337-a2ad-0fc43ad2b4e0
# ╠═248c158c-41bc-478f-be12-b7e4ab43544d
# ╠═72c6bdcd-6d6b-4bf4-a759-1c4256384352
# ╠═c0634c74-9228-4d05-8146-3492aaf3a8ef
# ╟─decac4e3-d5d3-4a51-a5bb-fdb658dec971
# ╟─2bb59351-cb34-45a7-bd58-72409adf48fa
# ╟─4aa39de7-db17-42d7-924f-abb486c03eed
# ╟─d5ba2170-d687-4ef8-a7fc-e8fef48b3a2c
# ╠═b385f71f-c608-4be7-a0b6-30a39397451e
# ╟─c1480936-bc64-481d-a754-31d5a35a2d6d
# ╠═c1cd29c9-b3dc-497b-b200-e6ad08356b39
# ╟─7d6a905a-2445-4569-8fe1-8e703b635218
# ╠═4b879529-0359-462e-b032-3bb95a11ac36
