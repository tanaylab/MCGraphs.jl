"""
Generate graphs for visualizing scRNA-seq metacells data in a `Daf` data set. The symbols from the main sub-modules
are re-exported from the main `MCGraphs` namespace. These sub-modules are:

  - [`Validations`](@ref MCGraphs.Validations) - general API allowing controllers to validate use input.
  - [`Renderers`](@ref MCGraphs.Renderers) - functions that actually render graphs given their data and configuration.
  - [`Extractors`](@ref MCGraphs.Extractors) - functions that extract graph data from metacells `Daf` data sets.
  - [`Plotters`](@ref MCGraphs.Plotters) - functions that combine extraction and rendering, creating a graph in one call.
  - `Controllers` - TODO: UI elements for specifying graph data or configuration.
  - `Widgets` - TODO: Combine multiple controllers for generating a complete graph.
  - `Menus` - TODO: A tree of menus for selecting and generating a single graph or a dashboard of multiple graphs.
"""
module MCGraphs

using Reexport

include("validations.jl")
@reexport using .Validations

include("renderers.jl")
@reexport using .Renderers

include("shorthands.jl")

include("extractors.jl")
@reexport using .Extractors

include("plotters.jl")
@reexport using .Plotters

end # module
