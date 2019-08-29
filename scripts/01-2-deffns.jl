
@doc Abm.grid

@doc Abm.gridsize

@doc Abm.random_activation

@doc Abm.add_agent_single!

"1) Creates an array of empty arrays as many as there are agents."
create_agent_positions(griddims) = [Int64[] for i in 1:Abm.gridsize(griddims)]

"2) Use MyGrid to create a grid from griddims and agent_positions using the
grid function."
MyGrid(griddims, agent_positions) = MyGrid(griddims,
                                          Abm.grid(griddims, false, true),
                                          agent_positions)

"3) Instantiate the model using mygrid, the SchellingAgent type, the
random_activation function from Agents.jl and the argument min_to_be_happy."
SchellingModel(mygrid, min_to_be_happy) = SchellingModel(mygrid,
                                                SchellingAgent[],
                                                Abm.random_activation,
                                                min_to_be_happy)

create_model(griddims, min_to_be_happy) = ((griddims |> create_agent_positions) |>
                                           (agentpositions -> MyGrid(griddims, agentpositions)) |>
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
