"""
Render interactive or static graphs.

This provides a selection of basic graph types needed for metacells visualization. For each one, we define a `struct`
containing all the data for the graph, and a separate `struct` containing the configuration of the graph. The rendering
function takes both and either returns a JavaScript blob needed to create the interactive graph, or writes the graph to
a file.
"""
module Renderers

export DistributionGraphConfiguration
export DistributionGraphData
export ValuesAxis
export HorizontalValues
export VerticalValues
export render

using ..Validations

using Daf.GenericTypes
using PlotlyJS

"""
The axis of the values in a distribution or bar graph:

`HorizontalValues` - The values are the X axis

`VerticalValues` - The values are the Y axis (the default).
"""
@enum ValuesAxis HorizontalValues VerticalValues

"""
    @kwdef struct DistributionGraphConfiguration <: ObjectWithValidation
        output::AbstractString = nothing
        graph_title::AbstractString = ""
        values_title::AbstractString = ""
        values_axis::ValuesAxis = VerticalValues,
        show_curve::Bool = false
        show_violin::Bool = false
        show_box::Bool = true
        show_outliers::Bool = false
    end

Configure a graph for showing a distribution.

`output` can be the path of a file (ending with `.png` or `.svg`). If it is `nothing` (the default), then render a
JavaScript blob for an interactive graph.

If specified, `graph_title` is used for the whole graph and `values_title` is used for the values axis. The

If `horizontal` (the default), the value would be the X axis and the density would be the Y axis; otherwise, this will
be reversed.

If `show_curve`, show a density curve (which is just the positive side of the violin plot, so you can't specify both
`show_curve` and `show_violin`). If `show_violin`, show a violin plot. If `show_box`, show a box plot. Any other
combination of these can be used as long as at least one of them is (explicitly) set.

If `show_outliers`, also show the extreme (outlier) points.

The optional `color` will be chosen automatically if not specified.
"""
@kwdef mutable struct DistributionGraphConfiguration <: ObjectWithValidation
    output::Maybe{AbstractString} = nothing
    graph_title::AbstractString = ""
    values_title::AbstractString = ""
    color::Maybe{AbstractString} = nothing
    values_axis::ValuesAxis = VerticalValues
    show_curve::Bool = false
    show_violin::Bool = false
    show_box::Bool = false
    show_outliers::Bool = false
end

function Validations.validate_object(configuration::DistributionGraphConfiguration)::Maybe{AbstractString}
    if !configuration.show_curve && !configuration.show_violin && !configuration.show_box
        return "must specify at least one of: show_curve, show_violin, show_box"
    elseif configuration.show_curve && configuration.show_violin
        return "can't specify both of: show_curve, show_violin"
    else
        return nothing
    end
end

"""
    @kwdef struct DistributionGraphData
        values::AbstractVector{<:Real}
    end

The data for a distribution graph, which is simply a vector of values.
"""
@kwdef mutable struct DistributionGraphData <: ObjectWithValidation
    values::AbstractVector{<:Real}
end

function Validations.validate_object(data::DistributionGraphData)::Maybe{AbstractString}
    if length(data.values) == 0
        return "empty values vector"
    else
        return nothing
    end
end

const BOX = 1
const VIOLIN = 2
const CURVE = 4

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
        (configuration.show_box ? BOX : 0) |
        (configuration.show_violin ? VIOLIN : 0) |
        (configuration.show_curve ? CURVE : 0)
    )
    points = configuration.show_outliers ? "outliers" : false
    orientation = configuration.values_axis == HorizontalValues ? "h" : "v"

    if kind == BOX
        if configuration.values_axis == HorizontalValues
            trace = box(;
                x = data.values,
                boxpoints = points,
                name = configuration.values_title,
                marker_color = configuration.color,
            )
        else
            trace = box(;
                y = data.values,
                boxpoints = points,
                name = configuration.values_title,
                marker_color = configuration.color,
            )
        end
    elseif kind == VIOLIN
        if configuration.values_axis == HorizontalValues
            trace = violin(;
                x = data.values,
                points = points,
                orientation = orientation,
                name = configuration.values_title,
                marker_color = configuration.color,
            )
        else
            trace = violin(;
                y = data.values,
                points = points,
                orientation = orientation,
                name = configuration.values_title,
                marker_color = configuration.color,
            )
        end
    elseif kind == VIOLIN | BOX
        if configuration.values_axis == HorizontalValues
            trace = violin(;
                x = data.values,
                box_visible = true,
                points = points,
                orientation = orientation,
                name = configuration.values_title,
                marker_color = configuration.color,
            )
        else
            trace = violin(;
                y = data.values,
                box_visible = true,
                points = points,
                orientation = orientation,
                name = configuration.values_title,
                marker_color = configuration.color,
            )
        end
    elseif kind == CURVE
        if configuration.values_axis == HorizontalValues
            trace = violin(;
                x = data.values,
                side = "positive",
                points = points,
                orientation = orientation,
                name = configuration.values_title,
                marker_color = configuration.color,
            )
        else
            trace = violin(;
                y = data.values,
                side = "positive",
                points = points,
                orientation = orientation,
                name = configuration.values_title,
                marker_color = configuration.color,
            )
        end
    elseif kind == CURVE | BOX
        if configuration.values_axis == HorizontalValues
            trace = violin(;
                x = data.values,
                side = "positive",
                box_visible = true,
                points = points,
                orientation = orientation,
                name = configuration.values_title,
                marker_color = configuration.color,
            )
        else
            trace = violin(;
                y = data.values,
                side = "positive",
                box_visible = true,
                points = points,
                orientation = orientation,
                name = configuration.values_title,
                marker_color = configuration.color,
            )
        end
    else
        @assert false
    end
    plt = plot(trace, Layout(; title = configuration.graph_title))  # NOJET

    if configuration.output !== nothing
        savefig(plt, configuration.output)  # NOJET
    else
        @assert false
    end

    return nothing
end

end
