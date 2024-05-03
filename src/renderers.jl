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
export DistributionStyleConfiguration
export DistributionsGraphData
export GraphConfiguration
export HorizontalValues
export PointsGraphConfiguration
export PointsGraphData
export PointsStyleConfiguration
export ValuesOrientation
export VerticalValues
export render

using ..Validations

using Daf.GenericTypes
using PlotlyJS

"""
The orientation of the values axis in a distribution or a bars graph:

`HorizontalValues` - The values are the X axis

`VerticalValues` - The values are the Y axis (the default).
"""
@enum ValuesOrientation HorizontalValues VerticalValues

"""
    @kwdef mutable struct GraphConfiguration <: ObjectWithValidation
        output_file::Maybe{AbstractString} = nothing
        show_interactive::Bool = false
        width::Maybe{Int} = nothing
        height::Maybe{Int} = nothing
        template::AbstractString = "simple_white"
        show_grid::Bool = true
        show_ticks::Bool = true
        show_legend::Bool = false
    end

Generic configuration that applies to any graph.

If `output_file` is specified, it is the path of a file to write the graph into (ending with `.png` or `.svg`). If
`show_interactive` is set, then generate an interactive graph (in a Jupyter notebook). One of `output_file` and
`show_interactive` must be specified.

The optional `width` and `height` are in pixels, that is, 1/96 of an inch.

By default, `show_grid` and `show_ticks` are set, but `show_legend` is not.

The default `template` is "simple_white" which is the cleanest. The `show_grid` and `show_ticks` can be used to disable
the grid and/or ticks for an even cleaner (but less informative) look.
"""
@kwdef mutable struct GraphConfiguration <: ObjectWithValidation
    output_file::Maybe{AbstractString} = nothing
    show_interactive::Bool = false
    width::Maybe{Int} = nothing
    height::Maybe{Int} = nothing
    template::AbstractString = "simple_white"
    show_grid::Bool = true
    show_ticks::Bool = true
    show_legend::Bool = false
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
        minimum::Maybe{Real} = nothing
        maximum::Maybe{Real} = nothing
    end

Generic configuration for a graph axis. Everything is optional; by default, the `minimum` and `maximum` are computed
automatically from the data.
"""
@kwdef mutable struct AxisConfiguration <: ObjectWithValidation
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
    @kwdef mutable struct DistributionStyleConfiguration <: ObjectWithValidation
        show_box::Bool = true
        show_violin::Bool = false
        show_curve::Bool = false
        show_outliers::Bool = false
        color::Maybe{AbstractString} = nothing
    end

Configure the style of a distribution graph.

If `show_box`, show a box graph.

If `show_violin`, show a violin graph.

If `show_curve`, show a density curve.

You can combine the above; however, a density curve is just the positive side of a violin graph, so you can't combine
the two.

In addition to the (combination) of the above, if `show_outliers`, also show the extreme (outlier) points.

The `color` is chosen automatically by default. When showing multiple distributions, you can override it per each one in
the [`DistributionsGraphData`](@ref).
"""
@kwdef mutable struct DistributionStyleConfiguration <: ObjectWithValidation
    orientation::ValuesOrientation = VerticalValues
    show_box::Bool = true
    show_violin::Bool = false
    show_curve::Bool = false
    show_outliers::Bool = false
    color::Maybe{AbstractString} = nothing
end

function Validations.validate_object(configuration::DistributionStyleConfiguration)::Maybe{AbstractString}
    if !configuration.show_box && !configuration.show_violin && !configuration.show_curve
        return "must specify at least one of: distribution style.show_box, style.show_violin, style.show_curve"
    end

    if configuration.show_violin && configuration.show_curve
        return "can't specify both of: distribution style.show_violin, style.show_curve"
    end

    return nothing
end

"""
    @kwdef mutable struct DistributionGraphConfiguration <: ObjectWithValidation
        graph::GraphConfiguration = GraphConfiguration()
        style::DistributionStyleConfiguration = DistributionStyleConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
    end

Configure a graph for showing a distribution (with [`DistributionGraphData`](@ref)) or several distributions (with
[`DistributionsGraphData`](@ref)).

The optional `color` will be chosen automatically if not specified. When showing multiple distributions, it is also
possible to specify the color of each one in the [`DistributionsGraphData`](@ref).
"""
@kwdef mutable struct DistributionGraphConfiguration <: ObjectWithValidation
    graph::GraphConfiguration = GraphConfiguration()
    style::DistributionStyleConfiguration = DistributionStyleConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
end

function Validations.validate_object(configuration::DistributionGraphConfiguration)::Maybe{AbstractString}
    message = validate_object(configuration.graph)
    if message === nothing
        message = validate_object(configuration.style)
    end
    if message === nothing
        message = validate_object("values", configuration.value_axis)
    end
    return message
end

"""
    @kwdef mutable struct DistributionGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        trace_axis_title::Maybe{AbstractString} = nothing
        values::AbstractVector{<:Real}
        name::Maybe{AbstractString} = nothing
    end

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title` and
the `trace_axis_title`. The optional `name` is used as the tick value for the distribution.
"""
@kwdef mutable struct DistributionGraphData <: ObjectWithValidation
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    trace_axis_title::Maybe{AbstractString} = nothing
    values::AbstractVector{<:Real}
    name::Maybe{AbstractString} = nothing
end

function Validations.validate_object(data::DistributionGraphData)::Maybe{AbstractString}
    if length(data.values) == 0
        return "empty values vector"
    end

    return nothing
end

"""
    @kwdef mutable struct DistributionsGraphData <: ObjectWithValidation
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        trace_axis_title::Maybe{AbstractString} = nothing
        values::AbstractVector{<:AbstractVector{<:Real}}
        names::Maybe{AbstractStringVector} = nothing
        colors::Maybe{AbstractStringVector} = nothing
    end

The data for a multiple distributions graph. By default, all the titles are empty. You can specify the overall
`graph_title` as well as the `value_axis_title` and the `trace_axis_title`. If specified, the `names` and/or the
`colors` vectors must contain the same number of elements as the number of vectors in the `values`.
"""
@kwdef mutable struct DistributionsGraphData <: ObjectWithValidation
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    trace_axis_title::Maybe{AbstractString} = nothing
    values::AbstractVector{<:AbstractVector{<:Real}}
    names::Maybe{AbstractStringVector} = nothing
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

    if data.names !== nothing && length(data.names) != length(data.values)
        return "the number of names: $(length(data.names))\n" *
               "is different from the number of values: $(length(data.values))"
    end

    if data.colors !== nothing && length(data.colors) != length(data.values)
        return "the number of colors: $(length(data.colors))\n" *
               "is different from the number of values: $(length(data.values))"
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
        data.name === nothing ? "Trace" : data.name,
        configuration.style.color,
        configuration,
    )
    layout = distribution_layout(data.name !== nothing, data, configuration)
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
            data.names === nothing ? "Trace $(index)" : data.names[index],
            data.colors === nothing ? configuration.style.color : data.colors[index],
            configuration,
        ) for index in 1:n_values
    ]
    layout = distribution_layout(data.names !== nothing, data, configuration)
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
    style = (
        (configuration.style.show_box ? BOX : 0) |
        (configuration.style.show_violin ? VIOLIN : 0) |
        (configuration.style.show_curve ? CURVE : 0)
    )

    if configuration.style.orientation == VerticalValues
        y = values
        x = nothing
    elseif configuration.style.orientation == HorizontalValues
        x = values
        y = nothing
    else
        @assert false
    end

    points = configuration.style.show_outliers ? "outliers" : false
    tracer = style == BOX ? box : violin

    return tracer(;
        x = x,
        y = y,
        side = configuration.style.show_curve ? "positive" : nothing,
        box_visible = configuration.style.show_box,
        boxpoints = points,
        points = points,
        name = name,
        marker_color = color,
    )
end

function distribution_layout(
    has_tick_names::Bool,
    data::Union{DistributionGraphData, DistributionsGraphData},
    configuration::DistributionGraphConfiguration,
)::Layout
    if configuration.style.orientation == VerticalValues
        xaxis_showticklabels = has_tick_names
        xaxis_showgrid = false
        xaxis_title = data.trace_axis_title
        xaxis_range = (nothing, nothing)
        yaxis_showticklabels = configuration.graph.show_ticks
        yaxis_showgrid = configuration.graph.show_grid
        yaxis_title = data.value_axis_title
        yaxis_range = (configuration.value_axis.minimum, configuration.value_axis.maximum)
    elseif configuration.style.orientation == HorizontalValues
        xaxis_showticklabels = configuration.graph.show_ticks
        xaxis_showgrid = configuration.graph.show_grid
        xaxis_title = data.value_axis_title
        xaxis_range = (configuration.value_axis.minimum, configuration.value_axis.maximum)
        yaxis_showticklabels = has_tick_names
        yaxis_showgrid = false
        yaxis_title = data.trace_axis_title
        yaxis_range = (nothing, nothing)
    else
        @assert false
    end

    return Layout(;  # NOJET
        title = data.graph_title,
        template = configuration.graph.template,
        xaxis_showgrid = xaxis_showgrid,
        xaxis_showticklabels = xaxis_showticklabels,
        xaxis_title = xaxis_title,
        xaxis_range = xaxis_range,
        yaxis_showgrid = yaxis_showgrid,
        yaxis_showticklabels = yaxis_showticklabels,
        yaxis_title = yaxis_title,
        yaxis_range = yaxis_range,
        showlegend = configuration.graph.show_legend,
    )
end

"""
    @kwdef mutable struct PointsStyleConfiguration <: ObjectWithValidation
        size::Maybe{Real} = nothing
        color::Maybe{AbstractString} = nothing
        color_scale::Maybe{AbstractString} = nothing
        reverse_scale::Bool = false
        show_same_line::Bool = false
        show_same_band_offset::Maybe{Real} = nothing
    end

Configure points in a graph. By default, the point `size` and `color` is chosen automatically. You can also override it
by specifying colors in the [`PointsGraphData`](@ref). If the data contains numeric color values, then the `color_scale`
will be used instead; you can set `reverse_scale` to reverse it. You need to explicitly set `show_scale` to show its
legend.

If `show_same_line` is set, a line (x = y) is shown. If `show_same_band_offset` is set, dashed lines above and below the
"same" line are shown at this offset.
"""
@kwdef mutable struct PointsStyleConfiguration <: ObjectWithValidation
    size::Maybe{Real} = nothing
    color::Maybe{AbstractString} = nothing
    color_scale::Maybe{AbstractString} = nothing
    reverse_scale::Bool = false
    show_scale::Bool = false
    show_same_line::Bool = false
    show_same_band_offset::Maybe{Real} = nothing
end

function Validations.validate_object(configuration::PointsStyleConfiguration)::Maybe{AbstractString}
    size = configuration.size
    if size !== nothing && size <= 0
        return "non-positive points style.size: $(size)"
    end

    show_same_band_offset = configuration.show_same_band_offset
    if show_same_band_offset !== nothing && show_same_band_offset <= 0
        return "non-positive points style.show_same_band_offset: $(show_same_band_offset)"
    end

    return nothing
end

"""
    @kwdef mutable struct PointsGraphConfiguration <: ObjectWithValidation
        graph::GraphConfiguration = GraphConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        style::PointsStyleConfiguration = PointsConfiguration()
    end

Configure a graph for showing a scatter graph of points.
"""
@kwdef mutable struct PointsGraphConfiguration <: ObjectWithValidation
    graph::GraphConfiguration = GraphConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    style::PointsStyleConfiguration = PointsStyleConfiguration()
end

function Validations.validate_object(configuration::PointsGraphConfiguration)::Maybe{AbstractString}
    message = validate_object(configuration.graph)
    if message === nothing
        message = validate_object("x", configuration.x_axis)
    end
    if message === nothing
        message = validate_object("y", configuration.y_axis)
    end
    if message === nothing
        message = validate_object(configuration.style)
    end

    return message
end

"""
    @kwdef mutable struct PointsGraphData <: ObjectWithValidation
        graph_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        xs::AbstractVector{<:Real}
        ys::AbstractVector{<:Real}
        colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing
        sizes::Maybe{AbstractVector{<:Real}} = nothing
        hovers::Maybe{AbstractStringVector} = nothing
    end

The data for a scatter graph of points.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `x_axis_title` and
`y_axis_title` for the axes. The `name` is only useful when `show_legend` is set.

The `xs` and `ys` vectors must be of the same size. If specified, the `colors` `sizes` and/or `hovers` vectors must also
be of the same size. The `colors` can be either color names or a numeric value; if the latter, then the configuration's
`color_scale` is used. Sizes are the diameter in pixels (1/96th of an inch).
"""
@kwdef mutable struct PointsGraphData <: ObjectWithValidation
    graph_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    name::Maybe{AbstractString} = nothing
    xs::AbstractVector{<:Real}
    ys::AbstractVector{<:Real}
    colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing
    sizes::Maybe{<:AbstractVector{<:Real}} = nothing
    hovers::Maybe{AbstractStringVector} = nothing
end

function Validations.validate_object(data::PointsGraphData)::Maybe{AbstractString}
    if length(data.xs) != length(data.ys)
        return "the number of xs: $(length(data.xs))\n" * "is different from the number of ys: $(length(data.ys))"
    end

    colors = data.colors
    if colors !== nothing && length(colors) != length(data.xs)
        return "the number of colors: $(length(colors))\n" *
               "is different from the number of points: $(length(data.xs))"
    end

    sizes = data.sizes
    if sizes !== nothing
        if length(sizes) != length(data.xs)
            return "the number of sizes: $(length(sizes))\n" *
                   "is different from the number of points: $(length(data.xs))"
        end

        for (index, size) in enumerate(sizes)
            if size <= 0.0
                return "non-positive size#$(index): $(size)"
            end
        end
    end

    return nothing
end

function render(data::PointsGraphData, configuration::PointsGraphConfiguration = PointsGraphConfiguration())::Nothing
    assert_valid_object(data)
    assert_valid_object(configuration)

    traces = Vector{GenericTrace}()

    push!(
        traces,
        scatter(;
            x = data.xs,
            y = data.ys,
            marker_size = data.sizes !== nothing ? data.sizes : configuration.style.size,
            marker_color = data.colors !== nothing ? data.colors : configuration.style.color,
            marker_colorscale = configuration.style.color_scale,
            marker_showscale = configuration.style.show_scale,
            marker_reversescale = configuration.style.reverse_scale,
            name = data.name !== nothing ? data.name : "Trace",
            mode = "markers",
        ),
    )

    show_same_band_offset = configuration.style.show_same_band_offset
    if configuration.style.show_same_line || show_same_band_offset !== nothing
        minimum_x = minimum(data.xs)
        minimum_y = minimum(data.ys)
        maximum_x = maximum(data.xs)
        maximum_y = maximum(data.ys)
        minimum_xy = min(minimum_x, minimum_y)
        maximum_xy = max(maximum_x, maximum_y)
        if configuration.style.show_same_line
            push!(
                traces,
                scatter(;
                    x = [minimum_xy, maximum_xy],
                    y = [minimum_xy, maximum_xy],
                    line_width = 1.0,
                    line_color = "black",
                    showlegend = false,
                    mode = "lines",
                ),
            )
        end
        if show_same_band_offset !== nothing
            push!(
                traces,
                scatter(;
                    x = [minimum_xy + show_same_band_offset, maximum_xy],
                    y = [minimum_xy, maximum_xy - show_same_band_offset],
                    line_width = 1.0,
                    line_color = "black",
                    line_dash = "dash",
                    showlegend = false,
                    mode = "lines",
                ),
            )
            push!(
                traces,
                scatter(;
                    x = [minimum_xy, maximum_xy - show_same_band_offset],
                    y = [minimum_xy + show_same_band_offset, maximum_xy],
                    line_width = 1.0,
                    line_color = "black",
                    line_dash = "dash",
                    showlegend = false,
                    mode = "lines",
                ),
            )
        end
    end

    layout = Layout(;  # NOJET
        title = data.graph_title,
        template = configuration.graph.template,
        xaxis_showgrid = configuration.graph.show_grid,
        xaxis_showticklabels = configuration.graph.show_ticks,
        xaxis_title = data.x_axis_title,
        xaxis_range = (configuration.x_axis.minimum, configuration.x_axis.maximum),
        yaxis_showgrid = configuration.graph.show_grid,
        yaxis_showticklabels = configuration.graph.show_ticks,
        yaxis_title = data.y_axis_title,
        yaxis_range = (configuration.x_axis.minimum, configuration.x_axis.maximum),
        showlegend = configuration.graph.show_legend,
    )
    figure = plot(traces, layout)
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
