import Agents
import Compose
import Cairo 
import Fontconfig


const Abm = Agents

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
