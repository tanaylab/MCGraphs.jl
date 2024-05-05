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
export DistributionsGraphConfiguration
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
    end

Generic configuration that applies to any graph.

If `output_file` is specified, it is the path of a file to write the graph into (ending with `.png` or `.svg`). If
`show_interactive` is set, then generate an interactive graph (in a Jupyter notebook). One of `output_file` and
`show_interactive` must be specified.

The optional `width` and `height` are in pixels, that is, 1/96 of an inch.

By default, `show_grid` and `show_ticks` are set.

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
        log_scale::Bool,
    end

Generic configuration for a graph axis. Everything is optional; by default, the `minimum` and `maximum` are computed
automatically from the data.

If `log_scale` is set, the data must contain only positive values, and the axis is shown in log (base 10) scale. To help
with finer-grained ratios, each 10x step is broken to three ~2.15 steps (which is "close enough" to 2x for intuitive
reading of the ratios).
"""
@kwdef mutable struct AxisConfiguration <: ObjectWithValidation
    minimum::Maybe{Real} = nothing
    maximum::Maybe{Real} = nothing
    log_scale::Bool = false
end

function Validations.validate_object(name::AbstractString, configuration::AxisConfiguration)::Maybe{AbstractString}
    minimum = configuration.minimum
    maximum = configuration.maximum

    if minimum !== nothing && maximum !== nothing && maximum <= minimum
        return "$(name) axis maximum: $(maximum)\n" * "is not larger than minimum: $(minimum)"
    end

    if configuration.log_scale && minimum !== nothing && minimum <= 0
        return "non-positive $(name) log axis minimum: $(minimum)"
    end

    if configuration.log_scale && maximum !== nothing && maximum <= 0
        return "non-positive $(name) log axis maximum: $(maximum)"
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

"""
    @kwdef mutable struct DistributionsGraphConfiguration <: ObjectWithValidation
        graph::GraphConfiguration = GraphConfiguration()
        style::DistributionStyleConfiguration = DistributionStyleConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        show_legend::Bool = false
        overlay::Bool = false
    end

Configure a graph for showing several distributions several distributions.

This is identical to [`DistributionGraphConfiguration`](@ref) with the addition of `show_legend` to show a legend. This
is not set by default as it makes little sense unless `overlay` is also set. TODO: Implement `overlay`.
"""
@kwdef mutable struct DistributionsGraphConfiguration <: ObjectWithValidation
    graph::GraphConfiguration = GraphConfiguration()
    style::DistributionStyleConfiguration = DistributionStyleConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    show_legend::Bool = false
    overlay::Bool = false
end

function Validations.validate_object(
    configuration::Union{DistributionGraphConfiguration, DistributionsGraphConfiguration},
)::Maybe{AbstractString}
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
    layout = distribution_layout(data.name !== nothing, data, configuration, false)
    figure = plot(trace, layout)
    write_graph(figure, configuration.graph)
    return nothing
end

function render(
    data::DistributionsGraphData,
    configuration::DistributionsGraphConfiguration = DistributionsGraphConfiguration(),
)::Nothing
    @assert !configuration.overlay "not implemented: overlay"
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
    layout = distribution_layout(data.names !== nothing, data, configuration, configuration.show_legend)
    figure = plot(traces, layout)
    write_graph(figure, configuration.graph)
    return nothing
end

function distribution_trace(
    values::AbstractVector{<:Real},
    name::AbstractString,
    color::Maybe{AbstractString},
    configuration::Union{DistributionGraphConfiguration, DistributionsGraphConfiguration},
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
    configuration::Union{DistributionGraphConfiguration, DistributionsGraphConfiguration},
    show_legend::Bool,
)::Layout
    if configuration.style.orientation == VerticalValues
        xaxis_showticklabels = has_tick_names
        xaxis_showgrid = false
        xaxis_title = data.trace_axis_title
        xaxis_range = (nothing, nothing)
        xaxis_type = nothing
        yaxis_showticklabels = configuration.graph.show_ticks
        yaxis_showgrid = configuration.graph.show_grid
        yaxis_title = data.value_axis_title
        yaxis_range = (configuration.value_axis.minimum, configuration.value_axis.maximum)
        yaxis_type = configuration.value_axis.log_scale ? "log" : nothing
    elseif configuration.style.orientation == HorizontalValues
        xaxis_showticklabels = configuration.graph.show_ticks
        xaxis_showgrid = configuration.graph.show_grid
        xaxis_title = data.value_axis_title
        xaxis_range = (configuration.value_axis.minimum, configuration.value_axis.maximum)
        xaxis_type = configuration.value_axis.log_scale ? "log" : nothing
        yaxis_showticklabels = has_tick_names
        yaxis_showgrid = false
        yaxis_title = data.trace_axis_title
        yaxis_range = (nothing, nothing)
        yaxis_type = nothing
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
        xaxis_type = xaxis_type,
        yaxis_showgrid = yaxis_showgrid,
        yaxis_showticklabels = yaxis_showticklabels,
        yaxis_title = yaxis_title,
        yaxis_range = yaxis_range,
        yaxis_type = yaxis_type,
        showlegend = show_legend,
    )
end

"""
    @kwdef mutable struct PointsStyleConfiguration <: ObjectWithValidation
        size::Maybe{Real} = nothing
        color::Maybe{AbstractString} = nothing
        color_scale::Maybe{AbstractString} = nothing
        reverse_scale::Bool = false
        show_scale::Bool = false
    end

Configure points in a graph. By default, the point `size` and `color` is chosen automatically (when this is applied to
edges, the `size` is the width of the line). You can also override this by specifying sizes and colors in the
[`PointsGraphData`](@ref). If the data contains numeric color values, then the `color_scale` will be used instead; you
can set `reverse_scale` to reverse it. You need to explicitly set `show_scale` to show its legend.
"""
@kwdef mutable struct PointsStyleConfiguration <: ObjectWithValidation
    size::Maybe{Real} = nothing
    color::Maybe{AbstractString} = nothing
    color_scale::Maybe{AbstractString} = nothing
    reverse_scale::Bool = false
    show_scale::Bool = false
end

function Validations.validate_object(
    of_what::AbstractString,
    configuration::PointsStyleConfiguration,
)::Maybe{AbstractString}
    size = configuration.size
    if size !== nothing && size <= 0
        return "non-positive $(of_what) style.size: $(size)"
    end

    return nothing
end

"""
    @kwdef mutable struct PointsGraphConfiguration <: ObjectWithValidation
        graph::GraphConfiguration = GraphConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        style::PointsStyleConfiguration = PointsConfiguration()
        border_style::PointsStyleConfiguration = PointsConfiguration()
        edges_style::PointsConfiguration = PointsConfiguration()
        show_border::Bool = false
        show_same_line::Bool = false
        show_same_band_offset::Maybe{Real} = nothing
    end

Configure a graph for showing a scatter graph of points.

If `show_same_line` is set, a line (x = y) is shown. If `show_same_band_offset` is set, dashed lines above and below the
"same" line are shown at this offset. If the axes are in `log_scale`, the log of the (offset + 1) is used.

If `show_border` is set, a border will be shown around each point using the `border_style` (and, if specified in the
[`PointsGraphData`](@ref), the `border_colors` and/or `border_sizes`). This allows displaying some additional data per
point.

!!! note

    You can't set the `show_legend` of the [`GraphConfiguration`](@ref) of a points graph. Instead you probably want to
    set the `show_scale` of the `style` (and/or of the `border_style` and/or `edges_style`). In addition, the color
    scale options of the `edges_style` must not be set as `edges_colors` of [`PointsGraphData`](@ref) is restricted to
    explicit colors.
"""
@kwdef mutable struct PointsGraphConfiguration <: ObjectWithValidation
    graph::GraphConfiguration = GraphConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    style::PointsStyleConfiguration = PointsStyleConfiguration()
    border_style::PointsStyleConfiguration = PointsStyleConfiguration()
    edges_style::PointsStyleConfiguration = PointsStyleConfiguration()
    show_border::Bool = false
    show_same_line::Bool = false
    show_same_band_offset::Maybe{Real} = nothing
end

function Validations.validate_object(configuration::PointsGraphConfiguration)::Maybe{AbstractString}
    @assert configuration.edges_style.color_scale === nothing "not implemented: points edges_style color_scale"
    @assert !configuration.edges_style.reverse_scale "not implemented: points edges_style reverse_scale"
    @assert !configuration.edges_style.show_scale "not implemented: points edges_style show_scale"

    message = validate_object(configuration.graph)
    if message === nothing
        message = validate_object("x", configuration.x_axis)
    end
    if message === nothing
        message = validate_object("y", configuration.y_axis)
    end
    if message === nothing
        message = validate_object("points", configuration.style)
    end
    if message === nothing
        message = validate_object("points border", configuration.border_style)
    end
    if message === nothing
        message = validate_object("points edges", configuration.edges_style)
    end

    show_same_band_offset = configuration.show_same_band_offset
    if show_same_band_offset !== nothing && show_same_band_offset <= 0
        return "non-positive points show_same_band_offset: $(show_same_band_offset)"
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
        border_colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing
        border_sizes::Maybe{AbstractVector{<:Real}} = nothing
        edges::Maybe{AbstractVector{Tuple{<:Integer, <:Integer}}} = nothing
        edges_colors::Maybe{AbstractStringVector} = nothing
        edges_sizes::Maybe{<:AbstractVector{<:Real}} = nothing
    end

The data for a scatter graph of points.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `x_axis_title` and
`y_axis_title` for the axes.

The `xs` and `ys` vectors must be of the same size. If specified, the `colors` `sizes` and/or `hovers` vectors must also
be of the same size. The `colors` can be either color names or a numeric value; if the latter, then the configuration's
`color_scale` is used. Sizes are the diameter in pixels (1/96th of an inch). Hovers are only shown in interactive graphs
(or when saving an HTML file).

The `border_colors` and `border_sizes` are only used if the `show_border` of [`PointsGraphConfiguration`](@ref) is set.
This will use the `border_style`. The border size is in addition to the point size.

It is possible to draw straight `edges` between specific point pairs. In this case the `edges_style` of the
[`PointsGraphConfiguration`](@ref) will be used, and the `edges_colors` and `edges_sizes` will override it per edge.
The `edges_colors` are restricted to explicit colors, not a color scale.
"""
@kwdef mutable struct PointsGraphData <: ObjectWithValidation
    graph_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    xs::AbstractVector{<:Real}
    ys::AbstractVector{<:Real}
    colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing
    sizes::Maybe{<:AbstractVector{<:Real}} = nothing
    hovers::Maybe{AbstractStringVector} = nothing
    border_colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing
    border_sizes::Maybe{<:AbstractVector{<:Real}} = nothing
    edges::Maybe{AbstractVector{Tuple{<:Integer, <:Integer}}} = nothing
    edges_colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing
    edges_sizes::Maybe{<:AbstractVector{<:Real}} = nothing
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

    border_colors = data.border_colors
    if border_colors !== nothing && length(border_colors) != length(data.xs)
        return "the number of border_colors: $(length(border_colors))\n" *
               "is different from the number of points: $(length(data.xs))"
    end

    border_sizes = data.border_sizes
    if border_sizes !== nothing
        if length(border_sizes) != length(data.xs)
            return "the number of border_sizes: $(length(border_sizes))\n" *
                   "is different from the number of points: $(length(data.xs))"
        end

        for (index, border_size) in enumerate(border_sizes)
            if border_size <= 0.0
                return "non-positive border_size#$(index): $(border_size)"
            end
        end
    end

    hovers = data.hovers
    if hovers !== nothing && length(hovers) != length(data.xs)
        return "the number of hovers: $(length(hovers))\n" *
               "is different from the number of points: $(length(data.xs))"
    end

    edges = data.edges
    if edges !== nothing
        for (index, (from_point, to_point)) in enumerate(edges)
            if from_point < 1 || length(data.xs) < from_point
                return "edge#$(index) from invalid point: $(from_point)"
            end
            if to_point < 1 || length(data.xs) < to_point
                return "edge#$(index) to invalid point: $(to_point)"
            end
            if from_point == to_point
                return "edge#$(index) from point to itself: $(from_point)"
            end
        end
    end

    return nothing
end

function render(data::PointsGraphData, configuration::PointsGraphConfiguration = PointsGraphConfiguration())::Nothing
    assert_valid_object(data)
    assert_valid_object(configuration)
    if configuration.x_axis.log_scale
        for (index, x) in enumerate(data.xs)
            @assert x > 0 "non-positive log x#$(index): $(x)"
        end
    end
    if configuration.y_axis.log_scale
        for (index, y) in enumerate(data.ys)
            @assert y > 0 "non-positive log y#$(index): $(y)"
        end
    end

    traces = Vector{GenericTrace}()

    if configuration.show_border
        if data.border_sizes === nothing
            marker_size = configuration.border_style.size !== nothing ? configuration.border_style.size : 4.0
            if data.sizes === nothing
                marker_size += configuration.style.size !== nothing ? configuration.style.size : 4.0
            else
                marker_size = data.sizes .+ marker_size
            end

        else
            if data.sizes === nothing
                marker_size = configuration.style.size !== nothing ? configuration.style.size : 4.0
                marker_size = data.border_sizes .+ marker_size
            else
                marker_size = data.border_sizes .+ data.sizes
            end
        end

        push!(
            traces,
            scatter(;
                x = data.xs,
                y = data.ys,
                marker_size = marker_size,
                marker_color = data.border_colors !== nothing ? data.border_colors : configuration.border_style.color,
                marker_colorscale = configuration.border_style.color_scale,
                marker_coloraxis = configuration.border_style.show_scale ? "coloraxis2" : nothing,
                marker_showscale = configuration.border_style.show_scale,
                marker_reversescale = configuration.border_style.reverse_scale,
                name = "",
                text = data.hovers,
                hovertemplate = data.hovers === nothing ? nothing : "%{text}<extra></extra>",
                mode = "markers",
            ),
        )
    end

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
            name = "",
            text = data.hovers,
            hovertemplate = data.hovers === nothing ? nothing : "%{text}<extra></extra>",
            mode = "markers",
        ),
    )

    edges = data.edges
    if edges !== nothing
        for (index, (from_point, to_point)) in enumerate(edges)
            push!(
                traces,
                scatter(;
                    x = [data.xs[from_point], data.xs[to_point]],
                    y = [data.ys[from_point], data.ys[to_point]],
                    line_width = if data.edges_sizes !== nothing
                        data.edges_sizes[index]
                    else
                        configuration.edges_style.size
                    end,
                    line_color = if data.edges_colors !== nothing
                        data.edges_colors[index]
                    elseif configuration.edges_style.color !== nothing
                        configuration.edges_style.color
                    else
                        "darkgrey"
                    end,
                    name = "",
                    mode = "lines",
                ),
            )
        end
    end

    show_same_band_offset = configuration.show_same_band_offset
    if configuration.show_same_line || show_same_band_offset !== nothing
        minimum_x = minimum(data.xs)
        minimum_y = minimum(data.ys)
        maximum_x = maximum(data.xs)
        maximum_y = maximum(data.ys)
        minimum_xy = min(minimum_x, minimum_y)
        maximum_xy = max(maximum_x, maximum_y)
        if configuration.show_same_line
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
                    x = [if configuration.x_axis.log_scale
                        minimum_xy * (1 + show_same_band_offset)
                    else
                        minimum_xy + show_same_band_offset
                    end, maximum_xy],
                    y = [minimum_xy, if configuration.y_axis.log_scale
                        maximum_xy / (1 + show_same_band_offset)
                    else
                        maximum_xy - show_same_band_offset
                    end],
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
                    x = [minimum_xy, if configuration.x_axis.log_scale
                        maximum_xy / (1 + show_same_band_offset)
                    else
                        maximum_xy - show_same_band_offset
                    end],
                    y = [if configuration.y_axis.log_scale
                        minimum_xy * (1 + show_same_band_offset)
                    else
                        minimum_xy + show_same_band_offset
                    end, maximum_xy],
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
        xaxis_type = configuration.x_axis.log_scale ? "log" : nothing,
        yaxis_showgrid = configuration.graph.show_grid,
        yaxis_showticklabels = configuration.graph.show_ticks,
        yaxis_title = data.y_axis_title,
        yaxis_range = (configuration.x_axis.minimum, configuration.x_axis.maximum),
        yaxis_type = configuration.y_axis.log_scale ? "log" : nothing,
        showlegend = false,
        coloraxis2_colorbar_x = if (configuration.border_style.show_scale && configuration.style.show_scale)
            1.2
        else
            nothing
        end,
        coloraxis2_colorscale = configuration.border_style.color_scale,
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
