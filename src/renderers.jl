"""
Render interactive or static graphs.

This provides a selection of basic graph types needed for metacells visualization. For each one, we define a `struct`
containing all the data for the graph, and a separate `struct` containing the configuration of the graph. The rendering
function takes both and either returns a JavaScript blob needed to create the interactive graph, or writes the graph to
a file.
"""
module Renderers

export render
export DistributionGraphConfiguration
export DistributionGraphData

using ..Validations

using Daf.GenericTypes
using Plotly

"""
    @kwdef struct DistributionGraphConfiguration <: ObjectWithValidation
        output::AbstractString = nothing
        title::AbstractString = nothing
        values_title::AbstractString = nothing
        horizontal::Bool = true
        violin::Bool = true
        box::Bool = false
        points::Bool = false
    end

Configure a graph for showing a distribution.

`output` can be the path of a file (ending with `.png` or `.svg`). If it is `nothing` (the default), then render a
JavaScript blob for an interactive graph.

If specified, `title` is used for the whole graph and `values_title` is used for the values axis.

If `horizontal` (the default), the value would be the X axis and the density would be the Y axis; otherwise, this will
be reversed.

If `violin`, show a violin plot. If `curve`, show a density curve (which is just the positive side of the violin plot,
so you can't specify both `curve` and `violin`). If `box`, show a box plot. If `points`, show the data points. Any other
combination of these can be used as long as at least one of them is set. By defaults, shows just the `curve` plot.

The optional `line_color`, `fill_color` or `point_color` will be automatically chosen if not specified. The
`point_color` is only used if showing the `points`. Also, if the graph data contains a color per point, then it
overrides the configuration `point_color`.
"""
@kwdef mutable struct DistributionGraphConfiguration <: ObjectWithValidation
    output::Maybe{AbstractString} = nothing
    plot_title::Maybe{AbstractString} = nothing
    values_title::Maybe{AbstractString} = nothing
    line_color::Maybe{AbstractString} = nothing
    fill_color::Maybe{AbstractString} = nothing
    point_color::Maybe{AbstractString} = nothing
    horizontal::Bool = true
    curve::Bool = true
    violin::Bool = false
    box::Bool = false
    points::Bool = false
end

function Validations.validate_object(configuration::DistributionGraphConfiguration)::Maybe{AbstractString}
    if !configuration.curve && !configuration.violin && !configuration.box && !configuration.points
        return "must specify at least one of: curve, violin, box, points"
    elseif configuration.curve && configuration.violin
        return "can't specify both of: curve, violin"
    else
        return nothing
    end
end

"""
    @kwdef struct DistributionGraphData
        values::AbstractVector{<:AbstractFloat}
        colors::Maybe{AbstractStringVector} = nothing
    end

The data for a distribution graph. The `values` vector is mandatory. The `colors` vector is optional and not normally
specified. It only has an effect if the [`DistributionGraphConfiguration`](@ref) specifies showing the points.
"""
@kwdef mutable struct DistributionGraphData <: ObjectWithValidation
    values::AbstractVector{<:AbstractFloat}
    colors::Maybe{AbstractStringVector} = nothing
end

function Validations.validate_object(data::DistributionGraphData)::Maybe{AbstractString}
    if length(data.values) == 0
        return "empty values vector"
    elseif data.colors !== nothing && length(data.colors) != length(data.values)
        return "length of colors: $(length(data.colors))\n" *
               "is different from length of values: $(length(data.values))"
    else
        return nothing
    end
end

const POINTS = 1
const BOX = 2
const VIOLIN = 4
const CURVE = 8

"""
    render(
        data::SomeGraphData,
        configuration::SomeGraphConfiguration = SomeGraphConfiguration()
    )::Nothing

Render a graph given its data and configuration. The implementation depends on the specific graph.
"""
function render(
    data::DistributionGraphData,
    configuration::DistributionGraphConfiguration = DistributionGraphConfiguration(),
)::Nothing
    assert_valid_object(data)
    assert_valid_object(configuration)

    kind = (
        (configuration.points ? POINTS : 0) |
        (configuration.box ? BOX : 0) |
        (configuration.violin ? VIOLIN : 0) |
        (configuration.curve ? CURVE : 0)
    )

    if kind == POINTS
        @assert false
    elseif kind == BOX
        trace = box(; y = data.values)
        plt = plot(trace)  # NOJET
    elseif kind == BOX | POINTS
        @assert false
    elseif kind == VIOLIN
        trace = violin(; y = data.values)
        plt = plot(trace)  # NOJET
    elseif kind == VIOLIN | POINTS
        @assert false
    elseif kind == VIOLIN | BOX | POINTS
        @assert false
    elseif kind == CURVE
        @assert false
    elseif kind == CURVE | POINTS
        @assert false
    elseif kind == CURVE | BOX | POINTS
        @assert false
    else
        @assert false
    end

    if configuration.output !== nothing
        savefig(plt, configuration.output)  # NOJET
    else
        @assert false
    end

    return nothing
end

end
