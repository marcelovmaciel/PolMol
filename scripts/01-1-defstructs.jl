
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


