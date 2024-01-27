module game_of_life

using Agents, GLMakie, Random

rules = (2, 3, 3, 3) # (Death, Survival, Reproduction, Overpopulation)

@agent Automaton GridAgent{2} begin end  # dummy agent required by ABM

function build_model(rules::Tuple;
    alive_probability=0.2,
    dims=(100, 100), metric=:chebyshev, seed=42
)
    space = GridSpaceSingle(dims; metric)
    properties = Dict(:rules => rules)
    status = zeros(Bool, dims)
    # We use a second copy so that we can do a "synchronous" update of the status
    new_status = zeros(Bool, dims)
    # We use a `NamedTuple` for the properties container to avoid type instabilities
    properties = (; rules, status, new_status)
    model = ABM(Automaton, space; properties, rng=MersenneTwister(seed))
    # Turn some of the cells on
    for pos in positions(model)
        if rand(model.rng) < alive_probability
            status[pos...] = true
        end
    end
    return model
end

function get_living_neighbors(pos, model)
    living_neighbors = 0
    @inbounds for near_pos in nearby_positions(pos, model)
        if model.status[near_pos...] == true
            living_neighbors += 1
        end
    end
    return living_neighbors
end

function game_of_life_step!(model)
    new_status = model.new_status
    status = model.status
    @inbounds for pos in positions(model)
        living_neighbors = get_living_neighbors(pos, model)
        if status[pos...] == true && (living_neighbors ≤ model.rules[4] && living_neighbors ≥ model.rules[1])
            new_status[pos...] = true
        elseif status[pos...] == false && (living_neighbors ≥ model.rules[3] && living_neighbors ≤ model.rules[4])
            new_status[pos...] = true
        else
            new_status[pos...] = false
        end
    end
    status .= new_status  # update new statuses into the old
    return
end

model = build_model(rules)

plotkwargs = (
    add_colorbar=false,
    heatarray=:status,
    heatkwargs=(
        colorrange=(0, 1),
        colormap=cgrad([:white, :black]; categorical=true),
    ),
)

abmvideo(
    "game_of_life.mp4",
    model,
    dummystep,
    game_of_life_step!;
    title="Game of Life",
    framerate=10,
    frames=60,
    plotkwargs...,
)

end # module game_of_life
