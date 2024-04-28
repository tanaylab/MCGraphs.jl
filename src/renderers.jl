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
        title::AbstractString = ""
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

The default `template` is "simple_white" which is the cleanest.
"""
@kwdef mutable struct GraphConfiguration <: ObjectWithValidation
    output_file::Maybe{AbstractString} = nothing
    show_interactive::Bool = false
    title::AbstractString = ""
    width::Maybe{Int} = nothing
    height::Maybe{Int} = nothing
    template::AbstractString = "simple_white"
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
        title::AbstractString = ""
        minimum::Maybe{Real} = nothing
        maximum::Maybe{Real} = nothing
    end

Generic configuration for a graph axis. Everything is optional; by default, the `title` is empty and the `minimum` and
`maximum` are computed automatically from the data.
"""
@kwdef mutable struct AxisConfiguration <: ObjectWithValidation
    title::AbstractString = ""
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
        trace_title::Maybe{AbstractString} = nothing
    end

Configure a graph for showing a distribution.

The optional `color` will be chosen automatically if not specified.
"""
@kwdef mutable struct DistributionGraphConfiguration <: ObjectWithValidation
    graph::GraphConfiguration = GraphConfiguration()
    shape::DistributionShapeConfiguration = DistributionShapeConfiguration()
    orientation::ValuesOrientation = VerticalValues
    color::Maybe{AbstractString} = nothing
    values_axis::AxisConfiguration = AxisConfiguration()
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

The data for a distribution graph, which is simply a vector of values.
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

    shape = (
        (configuration.shape.show_box ? BOX : 0) |
        (configuration.shape.show_violin ? VIOLIN : 0) |
        (configuration.shape.show_curve ? CURVE : 0)
    )
    points = configuration.shape.show_outliers ? "outliers" : false

    if shape == BOX
        if configuration.orientation == HorizontalValues
            trace = box(; x = data.values, boxpoints = points, name = "", marker_color = configuration.color)
        else
            trace = box(; y = data.values, boxpoints = points, name = "", marker_color = configuration.color)
        end
    elseif shape == VIOLIN
        if configuration.orientation == HorizontalValues
            trace = violin(; x = data.values, points = points, name = "", marker_color = configuration.color)
        else
            trace = violin(; y = data.values, points = points, name = "", marker_color = configuration.color)
        end
    elseif shape == VIOLIN | BOX
        if configuration.orientation == HorizontalValues
            trace = violin(;
                x = data.values,
                box_visible = true,
                points = points,
                name = "",
                marker_color = configuration.color,
            )
        else
            trace = violin(;
                y = data.values,
                box_visible = true,
                points = points,
                name = "",
                marker_color = configuration.color,
            )
        end
    elseif shape == CURVE
        if configuration.orientation == HorizontalValues
            trace = violin(;
                x = data.values,
                side = "positive",
                points = points,
                name = "",
                marker_color = configuration.color,
            )
        else
            trace = violin(;
                y = data.values,
                side = "positive",
                points = points,
                name = "",
                marker_color = configuration.color,
            )
        end
    elseif shape == CURVE | BOX
        if configuration.orientation == HorizontalValues
            trace = violin(;
                x = data.values,
                side = "positive",
                box_visible = true,
                points = points,
                name = "",
                marker_color = configuration.color,
            )
        else
            trace = violin(;
                y = data.values,
                side = "positive",
                box_visible = true,
                points = points,
                name = "",
                marker_color = configuration.color,
            )
        end
    else
        @assert false
    end

    if configuration.orientation == VerticalValues
        xaxis_title = data.title
        yaxis_title = configuration.values_axis.title
    elseif configuration.orientation == HorizontalValues
        xaxis_title = configuration.values_axis.title
        yaxis_title = data.title
    else
        @assert false
    end
    figure =  # NOJET
        plot(
            trace,
            Layout(;
                title = configuration.graph.title,
                template = configuration.graph.template,
                xaxis_title = xaxis_title,
                yaxis_title = yaxis_title,
            ),
        )

    write_graph(figure, configuration.graph)

    return nothing
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
