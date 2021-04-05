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

# ╔═╡ fd12ac50-9633-11eb-05ab-df8a67a47c96
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add(["Flux", "Serialization", "MLDatasets", "Images", "ImageIO", "PlutoUI"])
	
	using Flux, Serialization, MLDatasets, Images, ImageIO, Statistics, PlutoUI
	
	html"""<h3 style="border-bottom: none; margin-top: 0; font-weight: normal"><b>Author</b>: Connor Burns</h3>"""
end

# ╔═╡ e66e4c79-5408-40ca-b31d-9ffa9a8ff122
md"## PlutoCon 2021 WYSIWYR Demo (MNIST)"

# ╔═╡ 5fbc7f13-e043-442b-b51f-3337ca0fb1c9
md"In this notebook we will load a pretrained model for classifying MNIST handwritten digits from 28x28 greyscale images. However, this notebook is less about the model and more about interacting with it via \"what you see is what you REST\" features."

# ╔═╡ a25e898b-bb40-410c-9987-0571a737c9c4
ENV["DATADEPS_ALWAYS_ACCEPT"] = "true";

# ╔═╡ d5372041-c6ad-4e7c-85f1-b5f99457023a
md"### Loading Data

To start off we will download the MNIST dataset using the `MLDatasets` package."

# ╔═╡ e303a531-db01-4e67-a1f6-33d2ca023eee
MNIST.download(; i_accept_the_terms_of_use=true);

# ╔═╡ bd2902c6-205a-40a0-95e1-175abb5dd7b5
md"Now we load a pre-trained model which has been serialized with Julia's native [serialization library](https://docs.julialang.org/en/v1/stdlib/Serialization/). The model is made up of 3 convolutional layers, 3 max pooling layers, and one dense layer." 

# ╔═╡ 35d38823-aa1d-44f1-a66a-2afe4c30478c
model = open(io -> deserialize(io), "mnist_conv.jls")

# ╔═╡ 9267d0e8-e736-434f-9da8-b12316dc248e
md"To test our model we will only load in the test data. Our model was trained with training data from `MNIST.traindata()` in another notebook."

# ╔═╡ 95197d78-f492-40e6-a08f-fa01950fda12
test_x, test_y = MNIST.testdata();

# ╔═╡ 9d2b7e8e-c667-44b0-9ac5-2c47b6dadb84
md"
`test_x` shape: $(size(test_x)),
`test_y` shape: $(size(test_y))
"

# ╔═╡ 6b2af920-7b1d-4a95-acef-7c4bf48bd682
html"<h3>Testing the model <i style=\"font-size: 0.75em\">(and building the API too!)</i></h3>
"

# ╔═╡ 40cdd1ae-4109-4d6a-a7de-734970d2b607
md"First we assign a variable `input_images` to a small slice of test data."

# ╔═╡ 87d01adf-3a42-4c1d-bdda-5b3f3b67f50d
md"""
Start Index: $(@bind start_index NumberField(1:length(test_y); default=1))

End Index: $(@bind end_index NumberField(1:length(test_y); default=10))
"""

# ╔═╡ 17775e37-13d3-48ea-9033-8332502043e7
md"For example, the first (and only) element in the sample is a 7"

# ╔═╡ 0ff0c714-d5c9-4f1a-8787-f4670f635e61
md"Passing our `input_images` through the model loaded earlier, we get a 10x1 matrix, where each column corresponds to an input image, and each row corresponds to the class which the model thinks the image corresponds to. For example, a high value in the first row corresponds to a high confidence that the image contains a 0 digit.

The highest value by far is in the 8th index, which corresponds to the model predicting a 7 digit."

# ╔═╡ b17950b2-b742-4cb2-8275-5f4c0e3d98c4
md"The last step is to convert these predictions into numbers, then compare them to their true labels"

# ╔═╡ 500e9a99-e6ad-4f9f-80ac-d17fd046513c
md"Finally we can measure the accuracy of the model by comparing our predictions to the actual labels and finding the average."

# ╔═╡ 04579da3-d4f7-4498-8e4d-81ded9bbd077
html"""<h3 style="margin-top: 100px;">Helpers</h3>"""

# ╔═╡ f06ff43e-2d33-4a3e-9c72-fa63d11a879a
function default(x)
	return y -> (isnothing(y) || isnan(y)) ? x : y
end

# ╔═╡ 83df5406-aade-4c9d-ae55-eeaea102e812
safe_start_index = max(start_index |> default(1), 1)

# ╔═╡ 8a0b0855-913a-4342-a876-f292cc88447f
safe_end_index = min(end_index |> default(10), length(test_y))

# ╔═╡ 2156a6a2-ad5f-40ff-b02b-d5ce70abfd6e
input_images_slice = min(safe_start_index, safe_end_index):max(safe_start_index, safe_end_index)

# ╔═╡ 1fa33e70-00e2-48b4-9738-290ba9ab7b67
input_images = Flux.unsqueeze(test_x, 3)[:, :, :, input_images_slice];

# ╔═╡ c7628b87-06d6-4de1-9581-92a08620d212
predictions = model(input_images)

# ╔═╡ 3cacfe80-fe88-4580-9c38-b4d5779901cb
output_labels = Flux.onecold(predictions, 0:9)

# ╔═╡ e78e5119-93fd-44b7-9672-f6cc65e21039
test_labels = test_y[input_images_slice]

# ╔═╡ 68b045b2-5781-4d07-9a9d-30567509b4c6
Int.(output_labels .== test_labels)

# ╔═╡ 2ca1a052-4160-4b4e-90a3-779e3a5f8510
accuracy = mean(output_labels .== test_labels)

# ╔═╡ 3e496639-02fa-4643-b80d-46df33c736b0
function display_digit(img)
	Gray.(permutedims(img, (2, 1)))
end

# ╔═╡ acc15562-6a27-46fc-820b-6c60106d1880
display_digit(input_images[:, :, 1, 1])

# ╔═╡ Cell order:
# ╟─e66e4c79-5408-40ca-b31d-9ffa9a8ff122
# ╟─fd12ac50-9633-11eb-05ab-df8a67a47c96
# ╟─5fbc7f13-e043-442b-b51f-3337ca0fb1c9
# ╟─a25e898b-bb40-410c-9987-0571a737c9c4
# ╟─d5372041-c6ad-4e7c-85f1-b5f99457023a
# ╠═e303a531-db01-4e67-a1f6-33d2ca023eee
# ╟─bd2902c6-205a-40a0-95e1-175abb5dd7b5
# ╠═35d38823-aa1d-44f1-a66a-2afe4c30478c
# ╟─9267d0e8-e736-434f-9da8-b12316dc248e
# ╠═95197d78-f492-40e6-a08f-fa01950fda12
# ╟─9d2b7e8e-c667-44b0-9ac5-2c47b6dadb84
# ╟─6b2af920-7b1d-4a95-acef-7c4bf48bd682
# ╟─40cdd1ae-4109-4d6a-a7de-734970d2b607
# ╟─87d01adf-3a42-4c1d-bdda-5b3f3b67f50d
# ╠═83df5406-aade-4c9d-ae55-eeaea102e812
# ╠═8a0b0855-913a-4342-a876-f292cc88447f
# ╠═2156a6a2-ad5f-40ff-b02b-d5ce70abfd6e
# ╠═1fa33e70-00e2-48b4-9738-290ba9ab7b67
# ╟─17775e37-13d3-48ea-9033-8332502043e7
# ╠═acc15562-6a27-46fc-820b-6c60106d1880
# ╟─0ff0c714-d5c9-4f1a-8787-f4670f635e61
# ╠═c7628b87-06d6-4de1-9581-92a08620d212
# ╟─b17950b2-b742-4cb2-8275-5f4c0e3d98c4
# ╠═3cacfe80-fe88-4580-9c38-b4d5779901cb
# ╠═e78e5119-93fd-44b7-9672-f6cc65e21039
# ╟─500e9a99-e6ad-4f9f-80ac-d17fd046513c
# ╠═68b045b2-5781-4d07-9a9d-30567509b4c6
# ╠═2ca1a052-4160-4b4e-90a3-779e3a5f8510
# ╟─04579da3-d4f7-4498-8e4d-81ded9bbd077
# ╠═f06ff43e-2d33-4a3e-9c72-fa63d11a879a
# ╠═3e496639-02fa-4643-b80d-46df33c736b0
