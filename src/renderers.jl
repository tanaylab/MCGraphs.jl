"""
Render interactive or static graphs.

This provides a selection of basic graph types needed for metacells visualization. For each one, we define a `struct`
containing all the data for the graph, and a separate `struct` containing the configuration of the graph. The rendering
function takes both and either returns a JavaScript blob needed to create the interactive graph, or writes the graph to
a file.
"""
module Renderers

export AxisConfiguration
export DistributionGraphConfiguration
export DistributionGraphData
export DistributionsGraphData
export DistributionShapeConfiguration
export GraphConfiguration
export HorizontalValues
export ValuesOrientation
export VerticalValues
export render

using ..Validations

using Daf.GenericTypes
using PlotlyJS

"""
The orientation of the values axis in a distribution or bar graph:

`HorizontalValues` - The values are the X axis

`VerticalValues` - The values are the Y axis (the default).
"""
@enum ValuesOrientation HorizontalValues VerticalValues

"""
    @kwdef mutable struct GraphConfiguration <: ObjectWithValidation
        file::Maybe{AbstractString} = nothing
        title::Maybe{AbstractString} = nothing
        width::Maybe{Int} = nothing
        height::Maybe{Int} = nothing
    end

Generic configuration that applies to any graph.

If `output_file` is specified, it is the path of a file to write the graph into (ending with `.png` or `.svg`). If
`show_interactive` is set, then generate an interactive graph (in a Jupyter notebook). One of `output_file` and
`show_interactive` must be specified.

If specified, `graph_title` is used for the whole graph.

The optional `graph_width` and `graph_height` are in pixels, that is, 1/96 of an inch.

If set (the default), a `grid` is shown across the graph area.

The default `template` is "simple_white" which is the cleanest. The `show_grid` and `show_ticks` can be used to disable
the grid and/or ticks for an even cleaner (but less informative) look.
"""
@kwdef mutable struct GraphConfiguration <: ObjectWithValidation
    output_file::Maybe{AbstractString} = nothing
    show_interactive::Bool = false
    title::Maybe{AbstractString} = nothing
    width::Maybe{Int} = nothing
    height::Maybe{Int} = nothing
    template::AbstractString = "simple_white"
    show_grid::Bool = true
    show_ticks::Bool = true
end

function Validations.validate_object(configuration::GraphConfiguration)::Maybe{AbstractString}
    if configuration.output_file === nothing && !configuration.show_interactive
        return "must specify at least one of: graph.output_file, graph.show_interactive"
    end

    width = configuration.width
    if width !== nothing && width <= 0
        return "non-positive graph width: $(width)"
    end

    height = configuration.height
    if height !== nothing && height <= 0
        return "non-positive graph height: $(height)"
    end

    return nothing
end

"""
    @kwdef mutable struct AxisConfiguration <: ObjectWithValidation
        title::Maybe{AbstractString} = nothing
        minimum::Maybe{Real} = nothing
        maximum::Maybe{Real} = nothing
    end

Generic configuration for a graph axis. Everything is optional; by default, the `title` is empty and the `minimum` and
`maximum` are computed automatically from the data.
"""
@kwdef mutable struct AxisConfiguration <: ObjectWithValidation
    title::Maybe{AbstractString} = nothing
    minimum::Maybe{Real} = nothing
    maximum::Maybe{Real} = nothing
end

function Validations.validate_object(name::AbstractString, configuration::AxisConfiguration)::Maybe{AbstractString}
    minimum = configuration.minimum
    maximum = configuration.maximum

    if minimum !== nothing && maximum !== nothing && maximum <= minimum
        return "$(name) axis maximum: $(maximum)\n" * "is not larger than minimum: $(minimum)"
    end

    return nothing
end

"""
    @kwdef mutable struct DistributionShapeConfiguration <: ObjectWithValidation
        show_box::Bool = true
        show_violin::Bool = false
        show_curve::Bool = false
        show_outliers::Bool = false
    end

Configure the shape of a distribution graph.

If `show_box`, show a box graph.

If `show_violin`, show a violin graph.

If `show_curve`, show a density curve.

You can combine the above; however, a density curve is just the positive side of a violin graph, so you can't combine
the two.

In addition to the (combination) of the above, if `show_outliers`, also show the extreme (outlier) points.
"""
@kwdef mutable struct DistributionShapeConfiguration <: ObjectWithValidation
    show_box::Bool = true
    show_violin::Bool = false
    show_curve::Bool = false
    show_outliers::Bool = false
end

function Validations.validate_object(configuration::DistributionShapeConfiguration)::Maybe{AbstractString}
    if !configuration.show_box && !configuration.show_violin && !configuration.show_curve
        return "must specify at least one of: shape.show_box, shape.show_violin, shape.show_curve"
    end

    if configuration.show_violin && configuration.show_curve
        return "can't specify both of: shape.show_violin, shape.show_curve"
    end

    return nothing
end

"""
    @kwdef mutable struct DistributionGraphConfiguration <: ObjectWithValidation
        graph::GraphConfiguration = GraphConfiguration()
        shape::DistributionShapeConfiguration = DistributionShapeConfiguration()
        orientation::ValuesOrientation = VerticalValues
        color::Maybe{AbstractString} = nothing
        values_axis::AxisConfiguration = AxisConfiguration()
    end

Configure a graph for showing a distribution (with [`DistributionGraphData`](@ref)) or several distributions (with
[`DistributionsGraphData`](@ref)). Setting `show_legend` will show an explicit legend as well.

The optional `color` will be chosen automatically if not specified. When showing multiple distributions, it is also
possible to specify the color of each one in the [`DistributionsGraphData`](@ref).
"""
@kwdef mutable struct DistributionGraphConfiguration <: ObjectWithValidation
    graph::GraphConfiguration = GraphConfiguration()
    shape::DistributionShapeConfiguration = DistributionShapeConfiguration()
    orientation::ValuesOrientation = VerticalValues
    color::Maybe{AbstractString} = nothing
    values_axis::AxisConfiguration = AxisConfiguration()
    show_legend::Bool = false
end

function Validations.validate_object(configuration::DistributionGraphConfiguration)::Maybe{AbstractString}
    message = validate_object(configuration.graph)
    if message === nothing
        message = validate_object(configuration.shape)
    end
    if message === nothing
        message = validate_object("values", configuration.values_axis)
    end
    return message
end

"""
    @kwdef mutable struct DistributionGraphData
        values::AbstractVector{<:Real}
        title::Maybe{AbstractString} = nothing
    end

The data for a distribution graph.
"""
@kwdef mutable struct DistributionGraphData <: ObjectWithValidation
    values::AbstractVector{<:Real}
    title::Maybe{AbstractString} = nothing
end

function Validations.validate_object(data::DistributionGraphData)::Maybe{AbstractString}
    if length(data.values) == 0
        return "empty values vector"
    end

    return nothing
end

"""
    @kwdef mutable struct DistributionsGraphData <: ObjectWithValidation
        values::AbstractVector{<:AbstractVector{<:Real}}
        titles::Maybe{AbstractStringVector} = nothing
        colors::Maybe{AbstractStringVector} = nothing
    end

The data for a multiple distributions graph. If specified, the `titles` and/or the `colors` vectors must contain the
same number of elements as the number of vectors in the `values`.
"""
@kwdef mutable struct DistributionsGraphData <: ObjectWithValidation
    values::AbstractVector{<:AbstractVector{<:Real}}
    titles::Maybe{AbstractStringVector} = nothing
    colors::Maybe{AbstractStringVector} = nothing
end

function Validations.validate_object(data::DistributionsGraphData)::Maybe{AbstractString}
    if length(data.values) == 0
        return "empty values vector"
    end

    for (index, values) in enumerate(data.values)
        if length(values) == 0
            return "empty values#$(index) vector"
        end
    end

    if data.titles !== nothing && length(data.titles) != length(data.values)
        return "number of titles: $(length(data.titles))\n" *
               "is different from number of values: $(length(data.values))"
    end

    if data.colors !== nothing && length(data.colors) != length(data.values)
        return "number of colors: $(length(data.colors))\n" *
               "is different from number of values: $(length(data.values))"
    end

    return nothing
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
    trace = distribution_trace(  # NOJET
        data.values,
        data.title === nothing ? "Trace" : data.title,
        configuration.color,
        configuration,
    )
    layout = distribution_layout(data.title !== nothing, configuration)
    figure = plot(trace, layout)
    write_graph(figure, configuration.graph)
    return nothing
end

function render(
    data::DistributionsGraphData,
    configuration::DistributionGraphConfiguration = DistributionGraphConfiguration(),
)::Nothing
    assert_valid_object(data)
    assert_valid_object(configuration)

    n_values = length(data.values)
    traces = [
        distribution_trace(
            data.values[index],
            data.titles === nothing ? "Trace $(index)" : data.titles[index],
            data.colors === nothing ? configuration.color : data.colors[index],
            configuration,
        ) for index in 1:n_values
    ]
    layout = distribution_layout(data.titles !== nothing, configuration)
    figure = plot(traces, layout)
    write_graph(figure, configuration.graph)
    return nothing
end

function distribution_trace(
    values::AbstractVector{<:Real},
    name::AbstractString,
    color::Maybe{AbstractString},
    configuration::DistributionGraphConfiguration,
)::GenericTrace
    shape = (
        (configuration.shape.show_box ? BOX : 0) |
        (configuration.shape.show_violin ? VIOLIN : 0) |
        (configuration.shape.show_curve ? CURVE : 0)
    )

    if configuration.orientation == VerticalValues
        y = values
        x = nothing
    elseif configuration.orientation == HorizontalValues
        x = values
        y = nothing
    else
        @assert false
    end

    points = configuration.shape.show_outliers ? "outliers" : false
    tracer = shape == BOX ? box : violin

    return tracer(;
        x = x,
        y = y,
        side = configuration.shape.show_curve ? "positive" : nothing,
        box_visible = configuration.shape.show_box,
        boxpoints = points,
        points = points,
        name = name,
        marker_color = color,
    )
end

function distribution_layout(has_tick_titles::Bool, configuration::DistributionGraphConfiguration)::Layout
    if configuration.orientation == VerticalValues
        xaxis_showticklabels = has_tick_titles
        xaxis_showgrid = false
        xaxis_title = nothing
        xaxis_range = (nothing, nothing)
        yaxis_showticklabels = configuration.graph.show_ticks
        yaxis_showgrid = configuration.graph.show_grid
        yaxis_title = configuration.values_axis.title
        yaxis_range = (configuration.values_axis.minimum, configuration.values_axis.maximum)
    elseif configuration.orientation == HorizontalValues
        xaxis_showticklabels = configuration.graph.show_ticks
        xaxis_showgrid = configuration.graph.show_grid
        xaxis_title = configuration.values_axis.title
        xaxis_range = (configuration.values_axis.minimum, configuration.values_axis.maximum)
        yaxis_showticklabels = has_tick_titles
        yaxis_showgrid = false
        yaxis_title = nothing
        yaxis_range = (nothing, nothing)
    else
        @assert false
    end

    return Layout(;  # NOJET
        title = configuration.graph.title,
        template = configuration.graph.template,
        xaxis_showgrid = xaxis_showgrid,
        xaxis_showticklabels = xaxis_showticklabels,
        xaxis_title = xaxis_title,
        xaxis_range = xaxis_range,
        yaxis_showgrid = yaxis_showgrid,
        yaxis_showticklabels = yaxis_showticklabels,
        yaxis_title = yaxis_title,
        yaxis_range = yaxis_range,
        showlegend = configuration.show_legend,
    )
end

function write_graph(figure, configuration::GraphConfiguration)::Nothing
    output_file = configuration.output_file
    if output_file !== nothing
        savefig(figure, output_file; height = configuration.height, width = configuration.width)  # NOJET
    else
        @assert false
    end
    return nothing
end

end
