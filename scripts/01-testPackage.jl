import Agents
import Compose
import Cairo 
import Fontconfig


const Abm = Agents

"""
AbstractModel type for the Schelling Model

Object should always be a subtype of AbstractModel.
"""
mutable struct SchellingModel{T<:Integer, Y<:AbstractArray,
                              Z<:Abm.AbstractSpace} <: Abm.AbstractModel 

  "A field of the model for a space object, always a subtype of AbstractSpace."
  space::Z
    
  "A list of agents."
  agents::Y
    
  "A field for the scheduler function."
  scheduler::Function
    
  "The minimum number of neighbors for agent to be happy."
  min_to_be_happy::T
    
end

@doc Abm.AbstractSpace

@doc Abm.AbstractModel 

"""
AbstractAgent type for the Schelling Agent

Object should always be a subtype of AbstractAgent.
"""
mutable struct SchellingAgent{T<:Integer} <: Abm.AbstractAgent
  "The identifier number of the agent."
  id::T
  "The x, y location of the agent."
  pos::Tuple{T, T}
  """
  Whether or not the agent is happy with cell.

  Where true is "happy" and false is "unhappy"

  """
  mood::Bool
  "The group of the agent, determines mood as it interacts with neighbors."
  group::T
end

"The space of the experiment."
mutable struct MyGrid{T<:Integer, Y<:AbstractArray} <: Abm.AbstractSpace
  "Dimensions of the grid."
  dimensions::Tuple{T, T}
  "The space type."
  space::Abm.SimpleGraph
  "An array of arrays for each grid node."
  agent_positions::Y  
end

@doc Abm.grid

@doc Abm.gridsize

@doc Abm.random_activation

@doc Abm.add_agent_single!

"1) Creates an array of empty arrays as many as there are agents."
create_agent_positions(griddims) = [Int64[] for i in 1:Abm.gridsize(griddims)]

"2) Use MyGrid to create a grid from griddims and agent_positions using the
grid function."
create_mygrid(griddims, agent_positions) = MyGrid(griddims,
                                          Abm.grid(griddims, false, true),
                                          agent_positions)

"3) Instantiate the model using mygrid, the SchellingAgent type, the
random_activation function from Agents.jl and the argument min_to_be_happy."
SchellingModel(mygrid, min_to_be_happy) = SchellingModel(mygrid,
                                                SchellingAgent[],
                                                Abm.random_activation,
                                                min_to_be_happy)

create_model(griddims, min_to_be_happy) = ((griddims |> create_agent_positions) |>
                                           (agentpositions -> create_mygrid(griddims, agentpositions)) |>
                                           (mygrid -> SchellingModel(mygrid, min_to_be_happy)))

"4) Create a 1-dimension list of agents, balanced evenly between group 0 and group 1"
create_agents(numagents) = vcat([SchellingAgent(Int(i),
                                         (1,1),
                                         false, 0) for i in 1:(numagents/2)],
                                [SchellingAgent(Int(i),
                                                (1,1),
                                                false, 1) for i in (numagents/2)+1:numagents])

"Function to instantiate the model."
function instantiate_model(;numagents=320, griddims=(20, 20), min_to_be_happy=3)
    model = create_model(griddims, min_to_be_happy)
    agents = create_agents(numagents)
    for agent in agents
        Abm.add_agent_single!(agent, model)
        end
    return(model)
end

@doc Abm.node_neighbors

@doc Abm.get_node_contents

@doc Abm.move_agent_single!

"Move a single agent until a satisfactory location is found."
function agent_step!(agent, model)
  if agent.mood == true
    return(nothing)
  end
 
  while agent.mood == false
    neighbor_cells = Abm.node_neighbors(agent, model)
    count_neighbors_same_group = 0

    # For each neighbor, get group and compare to current agent's group...
    # ...and increment count_neighbors_same_group as appropriately.  
    for neighbor_cell in neighbor_cells
      node_contents = Abm.get_node_contents(neighbor_cell, model)
      # Skip iteration if the node is empty.
      if length(node_contents) == 0
        continue
      else
        # Otherwise, get the first agent in the node...
        node_contents = node_contents[1]
      end
      # ...and increment count_neighbors_same_group if the neighbor's group is
      # the same. 
      neighbor_agent_group = model.agents[node_contents].group
      if neighbor_agent_group == agent.group
        count_neighbors_same_group += 1
      end
    end

    # After evaluating and adding up the groups of the neighbors, decide
    # whether or not to move the agent.
    # If count_neighbors_same_group is at least the min_to_be_happy, set the
    # mood to true. Otherwise, move the agent using move_agent_single.
    if count_neighbors_same_group >= model.min_to_be_happy
      agent.mood = true
    else
      Abm.move_agent_single!(agent, model)
    end
  end
end

@doc Abm.step!

# Instantiate the model with 370 agents on a 20 by 20 grid. 
model = instantiate_model(numagents=370, griddims=(20,20), min_to_be_happy=2)
# An array of Symbols for the agent fields that are to be collected.
agent_properties = [:pos, :mood, :group]
# Specifies at which steps data should be collected.
steps_to_collect_data = collect(range(1, stop=100))
# Use the step function to run the model and collect data into a DataFrame.
@time data = Abm.step!(agent_step!, model, 1000, agent_properties, steps_to_collect_data);

size(data)

last(data)

@doc Abm.visualize_2D_agent_distribution

function visualize_2D_agent_distribution_png(data::Abm.DataFrame,
                                      model::Abm.AbstractModel,
                                      position_column::Symbol;
                                      types::Symbol=:id,
                                      savename::AbstractString="2D_agent_distribution",
                                      cc::Dict=Dict())
  g = model.space.space
  locs_x, locs_y, = Abm.node_locs(g, model.space.dimensions)
  
  # base node color is light grey
  nodefillc = [Abm.RGBA(0.1,0.1,0.1,.1) for i in 1:Abm.gridsize(model.space.dimensions)]

  # change node color given the position of the agents. Automatically uses any columns with names: pos, or pos_{some number}
  # TODO a new plot where the alpha value of a node corresponds to the value of an individual on a node
  if types == :id  # there is only one type
    pos = position_column
    d = Abm.by(data, pos, N = pos => length)
    maxval = maximum(d[!, :N])
    nodefillc[d[pos]] .= [Abm.RGBA(0.1, 0.1, 0.1, i) for i in  (d[!, :N] ./ maxval) .- 0.001]
  else  # there are different types of agents based on the values of the "types" column
    dd = Abm.dropmissing(data[:, [position_column, types]])
    unique_types = sort(unique(dd[!, types]))
    pos = position_column
    if length(cc) == 0
      colors = Abm.colorrgb(length(unique_types))
      colordict = Dict{Any, Tuple}()
      colorvalues = collect(values(colors))
      for ut in 1:length(unique_types)
        colordict[unique_types[ut]] = colorvalues[ut]
      end
    else
      colors = Abm.colorrgb(collect(values(cc)))
      colordict = Dict{Any, Tuple}()
      for key in keys(cc)
        colordict[key] = colors[cc[key]]
      end
    end
    colorrev = Dict(v=>k for (k,v) in colors)
    for index in 1:length(unique_types)
      tt = unique_types[index]
      d = Abm.by(dd[dd[!, types] .== tt, :], pos, N = pos => length)
      maxval = maximum(d[!, :N])
      # colormapname = "L$(index+1)"  # a linear colormap
      # (cmapc, name, desc) = cmap(colormapname, returnname=true)
      # nodefillc[d[pos]] .= [cmapc[round(Int64, i*256)] for i in  (d[:N] ./ maxval) .- 0.001]
      # println("$tt: $name")
      nodefillc[d[!, pos]] .= [Abm.RGBA(colordict[tt][1], colordict[tt][2], colordict[tt][3], i) for i in  (d[!, :N] ./ maxval) .- 0.001]
      println("$tt: $(colorrev[colordict[tt]])")
    end
  end

  NODESIZE = 0.8/sqrt(Abm.gridsize(model))
  Abm.draw(Compose.PNG("img/$savename.png"), Abm.gplot(g, locs_x, locs_y, nodefillc=nodefillc, edgestrokec=Abm.RGBA(0.1,0.1,0.1,.1), NODESIZE=NODESIZE))
end

first(data)

# Use visualize_2D_agent_distribution to plot distribution of agents at every step.
for i in 1:2
  visualize_2D_agent_distribution_png(data, model, Symbol("pos_$i"),
  types=Symbol("group_$i"), savename="step_$i", cc=Dict(0=>"blue", 1=>"red"))
end
