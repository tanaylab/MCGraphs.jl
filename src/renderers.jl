"""
Render interactive or static graphs.

This provides a selection of basic graph types needed for metacells visualization. For each one, we define a `struct`
containing all the data for the graph, and a separate `struct` containing the configuration of the graph. The rendering
function takes both and either returns a JavaScript blob needed to create the interactive graph, or writes the graph to
a file.
"""
module Renderers

export AbstractGraphConfiguration
export AbstractGraphData
export AxisConfiguration
export BarGraphConfiguration
export BarGraphData
export BarsGraphConfiguration
export BarsGraphData
export CdfDirection
export CdfGraphConfiguration
export CdfGraphData
export CdfsGraphConfiguration
export CdfsGraphData
export DistributionGraphConfiguration
export DistributionGraphData
export DistributionStyleConfiguration
export DistributionsGraphConfiguration
export DistributionsGraphData
export DownToValue
export GraphConfiguration
export HorizontalValues
export LineGraphConfiguration
export LineGraphData
export LineStyleConfiguration
export LinesGraphConfiguration
export LinesGraphData
export PointsGraphConfiguration
export PointsGraphData
export PointsStyleConfiguration
export StackFractions
export StackPercents
export StackValues
export Stacking
export UpToValue
export ValuesOrientation
export VerticalValues
export render

using ..Validations

using Daf.GenericTypes
using PlotlyJS

"""
Common abstract base for all complete graph configuration types. See [`render`](@ref).
"""
abstract type AbstractGraphConfiguration <: ObjectWithValidation end

"""
Common abstract base for all complete graph data types. See [`render`](@ref).
"""
abstract type AbstractGraphData <: ObjectWithValidation end

"""
The orientation of the values axis in a distribution or bars graph:

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

Generic configuration that applies to any graph. Each complete [`AbstractGraphConfiguration`](@ref) contains a `graph`
field of this type.

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
    @kwdef mutable struct DistributionGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        style::DistributionStyleConfiguration = DistributionStyleConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
    end

Configure a graph for showing a distribution (with [`DistributionGraphData`](@ref)) or several distributions (with
[`DistributionsGraphData`](@ref)).

The optional `color` will be chosen automatically if not specified. When showing multiple distributions, it is also
possible to specify the color of each one in the [`DistributionsGraphData`](@ref).
"""
@kwdef mutable struct DistributionGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    style::DistributionStyleConfiguration = DistributionStyleConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
end

"""
    @kwdef mutable struct DistributionsGraphConfiguration <: AbstractGraphConfiguration
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
@kwdef mutable struct DistributionsGraphConfiguration <: AbstractGraphConfiguration
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
        message = validate_object("value", configuration.value_axis)
    end
    return message
end

"""
    @kwdef mutable struct DistributionGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        trace_axis_title::Maybe{AbstractString} = nothing
        values::AbstractVector{<:Real}
        name::Maybe{AbstractString} = nothing
    end

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title` and
the `trace_axis_title`. The optional `name` is used as the tick value for the distribution.
"""
@kwdef mutable struct DistributionGraphData <: AbstractGraphData
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
    @kwdef mutable struct DistributionsGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        trace_axis_title::Maybe{AbstractString} = nothing
        legend_title::Maybe{AbstractString} = nothing
        values::AbstractVector{AbstractVector{<:Real}}
        names::Maybe{AbstractStringVector} = nothing
        colors::Maybe{AbstractStringVector} = nothing
    end

The data for a multiple distributions graph. By default, all the titles are empty. You can specify the overall
`graph_title` as well as the `value_axis_title`, the `trace_axis_title` and the `legend_title` (if `show_legend` is
set). If specified, the `names` and/or the `colors` vectors must contain the same number of elements as the number of
vectors in the `values`.
"""
@kwdef mutable struct DistributionsGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    trace_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    values::AbstractVector{AbstractVector{<:Real}}
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
        data::AbstractGraphData,
        configuration::AbstractGraphConfiguration = ...,
    )::Nothing

Render a graph given its data and configuration. The implementation depends on the specific graph. For each
[`AbstractGraphData`](@ref) there is a matching [`AbstractGraphConfiguration`](@ref) (a default one is provided for the
`configuration`). The supported type pairs are:

| [`AbstractGraphData`](@ref)      | [`AbstractGraphConfiguration`](@ref)      | Description                                          |
|:-------------------------------- |:----------------------------------------- |:---------------------------------------------------- |
| [`BarGraphData`](@ref)           | [`BarGraphConfiguration`](@ref)           | Graph of a single set of bars (histogram).           |
| [`BarsGraphData`](@ref)          | [`BarsGraphConfiguration`](@ref)          | Graph of multiple sets of bars (histograms).         |
| [`CdfGraphData`](@ref)           | [`CdfGraphConfiguration`](@ref)           | Graph of a single cumulative distribution function.  |
| [`CdfsGraphData`](@ref)          | [`CdfsGraphConfiguration`](@ref)          | Graph of multiple cumulative distribution functions. |
| [`DistributionGraphData`](@ref)  | [`DistributionGraphConfiguration`](@ref)  | Graph of a single distribution.                      |
| [`DistributionsGraphData`](@ref) | [`DistributionsGraphConfiguration`](@ref) | Graph of multiple distributions.                     |
| [`LineGraphData`](@ref)          | [`LineGraphConfiguration`](@ref)          | Graph of a single line (e.g. a function y=f(x)).     |
| [`LinesGraphData`](@ref)         | [`LinesGraphConfiguration`](@ref)         | Graph of multiple functions, possibly stacked.       |
| [`PointsGraphData`](@ref)        | [`PointsGraphConfiguration`](@ref)        | Graph of points, possibly with edges between them.   |
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
        nothing,
        configuration,
    )
    layout = distribution_layout(data, configuration; has_tick_names = data.name !== nothing, show_legend = false)
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
            data.legend_title,
            configuration,
        ) for index in 1:n_values
    ]
    layout = distribution_layout(
        data,
        configuration;
        has_tick_names = data.names !== nothing,
        show_legend = configuration.show_legend,
    )
    figure = plot(traces, layout)
    write_graph(figure, configuration.graph)
    return nothing
end

function distribution_trace(
    values::AbstractVector{<:Real},
    name::AbstractString,
    color::Maybe{AbstractString},
    legend_title::Maybe{AbstractString},
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
        legendgrouptitle_text = legend_title,
    )
end

function distribution_layout(
    data::Union{DistributionGraphData, DistributionsGraphData},
    configuration::Union{DistributionGraphConfiguration, DistributionsGraphConfiguration};
    has_tick_names::Bool,
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
    @kwdef mutable struct LineStyleConfiguration <: ObjectWithValidation
        line_width::Maybe{Real} = 1.0
        fill_below::Bool = false
        line_is_dashed::Bool = false
        line_color::Maybe{AbstractString} = nothing
    end

Configure a line in a graph.

By default, a solid line is shown; if `line_is_dashed`, the line will be dashed. If `fill_below` is set, the area below
the line is filled. If the `line_width` is set to `nothing`, no line is shown (and `fill_below` must be set). By
default, the `line_color` is chosen automatically.
"""
@kwdef mutable struct LineStyleConfiguration <: ObjectWithValidation
    line_width::Maybe{Real} = 1.0
    fill_below::Bool = false
    line_is_dashed::Bool = false
    line_color::Maybe{AbstractString} = nothing
end

function Validations.validate_object(configuration::LineStyleConfiguration)::Maybe{AbstractString}
    line_width = configuration.line_width
    if line_width !== nothing && line_width <= 0
        return "non-positive line_width: $(line_width)"
    end
    if line_width === nothing && !configuration.fill_below
        return "either line_width or fill_below must be specified"
    end
    return nothing
end

"""
    @kwdef mutable struct BandRegionConfiguration <: ObjectWithValidation
        line_color::Maybe{AbstractString} = "black"
        line_width::Real = 1.0
        line_is_dashed::Bool = false
        fill_color::Maybe{AbstractString} = nothing
    end

Configure a region of the graph defined by some band of values. The region only exists if `line_offset` is set. To
actually show the region, either the `line_color` and/or the `fill_color` must be set; by default, just the line is
shown. The `line_width` is in pixels (1/96th of an inch).
"""
@kwdef mutable struct BandRegionConfiguration <: ObjectWithValidation
    line_offset::Maybe{Real} = nothing
    line_color::Maybe{AbstractString} = "black"
    line_width::Real = 1.0
    line_is_dashed::Bool = false
    fill_color::Maybe{AbstractString} = nothing
end

function Validations.validate_object(
    of_what::AbstractString,
    of_which::AbstractString,
    configuration::BandRegionConfiguration,
    log_scale::Bool,
)::Maybe{AbstractString}
    if configuration.line_width <= 0
        return "non-positive $(of_what) $(of_which) line_width: $(configuration.line_width)"
    end
    if log_scale && configuration.line_offset !== nothing && configuration.line_offset <= 0
        return "non-positive log_scale $(of_what) $(of_which) line_offset: $(configuration.line_offset)"
    end
    return nothing
end

"""
    @kwdef mutable struct BandsConfiguration <: ObjectWithValidation
        low::BandRegionConfiguration = BandRegionConfiguration(line_is_dashed = true)
        middle::BandRegionConfiguration = BandRegionConfiguration()
        high::BandRegionConfiguration = BandRegionConfiguration(line_is_dashed = true)
    end

Configure the partition of the graph up to three band regions. The `low` and `high` are the "outer" regions (so their
lines are at their border, dashed by default) and the `middle` is the "inner" region between them (so its line is inside
it, solid by default).
"""
@kwdef mutable struct BandsConfiguration <: ObjectWithValidation
    low::BandRegionConfiguration = BandRegionConfiguration(; line_is_dashed = true)
    middle::BandRegionConfiguration = BandRegionConfiguration()
    high::BandRegionConfiguration = BandRegionConfiguration(; line_is_dashed = true)
end

function Validations.validate_object(
    of_what::AbstractString,
    configuration::BandsConfiguration,
    log_scale::Bool,
)::Maybe{AbstractString}
    message = validate_object(of_what, "low", configuration.low, log_scale)
    if message === nothing
        message = validate_object(of_what, "middle", configuration.middle, log_scale)
    end
    if message === nothing
        message = validate_object(of_what, "high", configuration.high, log_scale)
    end
    if message !== nothing
        return message
    end

    if configuration.low.line_offset !== nothing &&
       configuration.middle.line_offset !== nothing &&
       configuration.low.line_offset >= configuration.middle.line_offset
        return "$(of_what) low line_offset: $(configuration.low.line_offset)\n" *
               "is not less than middle line_offset: $(configuration.low.line_offset)"
    end

    if configuration.middle.line_offset !== nothing &&
       configuration.high.line_offset !== nothing &&
       configuration.middle.line_offset >= configuration.high.line_offset
        return "$(of_what) high line_offset: $(configuration.high.line_offset)\n" *
               "is not greater than middle line_offset: $(configuration.middle.line_offset)"
    end

    if configuration.low.line_offset !== nothing &&
       configuration.high.line_offset !== nothing &&
       configuration.low.line_offset >= configuration.high.line_offset
        return "$(of_what) low line_offset: $(configuration.low.line_offset)\n" *
               "is not less than high line_offset: $(configuration.high.line_offset)"
    end

    return nothing
end

"""
    @kwdef mutable struct LineGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        style::LineStyleConfiguration = LineStyleConfiguration()
        vertical_bands::BandsConfiguration = BandsConfiguration()
        horizontal_bands::BandsConfiguration = BandsConfiguration()
    end

Configure a graph for showing line plots.
"""
@kwdef mutable struct LineGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    style::LineStyleConfiguration = LineStyleConfiguration()
    vertical_bands::BandsConfiguration = BandsConfiguration()
    horizontal_bands::BandsConfiguration = BandsConfiguration()
end

"""
    @kwdef mutable struct LineGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        xs::AbstractVector{<:Real}
        ys::AbstractVector{<:Real}
    end

The data for a line graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `x_axis_title` and
`y_axis_title` for the axes.

The `xs` and `ys` vectors must be of the same size. A line will be drawn through all the points, and the area under the
line may be filled.
"""
@kwdef mutable struct LineGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    xs::AbstractVector{<:Real}
    ys::AbstractVector{<:Real}
end

function Validations.validate_object(data::LineGraphData)::Maybe{AbstractString}
    if length(data.xs) != length(data.ys)
        return "the number of xs: $(length(data.xs))\n" * "is different from the number of ys: $(length(data.ys))"
    end
    return nothing
end

function render(data::LineGraphData, configuration::LineGraphConfiguration = LineGraphConfiguration())::Nothing
    assert_valid_object(data)
    assert_valid_object(configuration)

    traces = Vector{GenericTrace}()

    minimum_x = minimum(data.xs)
    minimum_y = minimum(data.ys)
    maximum_x = maximum(data.xs)
    maximum_y = maximum(data.ys)

    push_fill_vertical_bands_traces(traces, configuration.vertical_bands, minimum_x, minimum_y, maximum_x, maximum_y)
    push_fill_horizontal_bands_traces(
        traces,
        configuration.horizontal_bands,
        minimum_x,
        minimum_y,
        maximum_x,
        maximum_y,
    )

    push!(traces, line_trace(data, configuration.style))

    for band in
        (configuration.vertical_bands.low, configuration.vertical_bands.middle, configuration.vertical_bands.high)
        if band.line_offset !== nothing && band.line_color !== nothing
            push!(traces, vertical_line_trace(band, minimum_y, maximum_y))
        end
    end

    for band in
        (configuration.horizontal_bands.low, configuration.horizontal_bands.middle, configuration.horizontal_bands.high)
        if band.line_offset !== nothing && band.line_color !== nothing
            push!(traces, horizontal_line_trace(band, minimum_x, maximum_x))
        end
    end

    layout = lines_layout(data, configuration; show_legend = false)
    figure = plot(traces, layout)
    write_graph(figure, configuration.graph)
    return nothing
end

function line_trace(data::LineGraphData, line_style::LineStyleConfiguration)::GenericTrace
    return scatter(;
        x = data.xs,
        y = data.ys,
        line_color = line_style.line_color,
        line_width = line_style.line_width === nothing ? 0 : line_style.line_width,
        line_dash = line_style.line_is_dashed ? "dash" : nothing,
        fill = line_style.fill_below ? "tozeroy" : nothing,
        name = "",
        mode = "lines",
    )
end

"""
If stacking multiple data sets, how:

`StackValues` - simply add the values on top of each other.

`StackFractions` - normalize the added values so their some is 1.

`StackPercents` - normalize the added values so their some is 100 (percent).
"""
@enum Stacking StackValues StackFractions StackPercents

"""
    @kwdef mutable struct LinesGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        style::LineStyleConfiguration = LineStyleConfiguration()
        vertical_bands::BandsConfiguration = BandsConfiguration()
        horizontal_bands::BandsConfiguration = BandsConfiguration()
        show_legend::Bool = false
        stacking::Maybe{Stacking} = nothing
    end

Configure a graph for showing multiple line plots. This allows using `show_legend` to display a legend of the different
lines, and `stacking` to stack instead of overlay the lines. If `stacking` is specified, then `fill_below` is implied,
regardless of what its actual setting is.
"""
@kwdef mutable struct LinesGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    style::LineStyleConfiguration = LineStyleConfiguration()
    vertical_bands::BandsConfiguration = BandsConfiguration()
    horizontal_bands::BandsConfiguration = BandsConfiguration()
    show_legend::Bool = false
    stacking::Maybe{Stacking} = nothing
end

function Validations.validate_object(
    configuration::Union{LineGraphConfiguration, LinesGraphConfiguration},
)::Maybe{AbstractString}
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
    if message === nothing
        message = validate_object("vertical_bands", configuration.vertical_bands, false)
    end
    if message === nothing
        message = validate_object("horizontal_bands", configuration.horizontal_bands, false)
    end
    return message
end

"""
    @kwdef mutable struct LinesGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        xs::AbstractVector{AbstractVector{<:Real}}
        ys::AbstractVector{AbstractVector{<:Real}}
        colors::Maybe{AbstractStringVector} = nothing
        line_widths::Maybe{AbstractVector{<:Real}} = nothing
    end

The data for multiple lines graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `x_axis_title` and
`y_axis_title` for the axes.

The `xs` and `ys` vectors must be of the same size (one per line). For each line, its `xs` and `ys` coordinate arrays
must also be of the same size; a line will be drawn through all the points, and the area under the line may be filled.
If `stack_lines` is specified in [`LinesGraphConfiguration`](@ref), then the lines are specified in top-to-bottom order.

The `names`, `line_colors`, `line_widths`, `fill_belows` and `are_dashed` arrays must have the same number of
entries (one per line). The `colors` are restricted to explicit colors; therefore the color scale options of the `style`
must not be used.

!!! note

    If `stacked` is spe
"""
@kwdef mutable struct LinesGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    xs::AbstractVector{AbstractVector{<:Real}}
    ys::AbstractVector{AbstractVector{<:Real}}
    names::Maybe{AbstractStringVector} = nothing
    line_colors::Maybe{AbstractStringVector} = nothing
    line_widths::Maybe{AbstractVector{<:Real}} = nothing
    fill_belows::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing
    are_dashed::Maybe{AbstractVector{Bool}} = nothing
end

function Validations.validate_object(data::LinesGraphData)::Maybe{AbstractString}
    if length(data.xs) != length(data.ys)
        return "the number of xs lines: $(length(data.xs))\n" *
               "is different from the number of ys lines: $(length(data.ys))"
    end
    if length(data.xs) == 0
        return "empty lines vectors"
    end

    for (index, (xs, ys)) in enumerate(zip(data.xs, data.ys))
        if length(xs) != length(ys)
            return "the number of line#$(index) xs: $(length(xs))\n" *
                   "is different from the number of ys: $(length(ys))"
        end
        if length(xs) < 2
            return "too few points in line#$(index): $(length(xs))"
        end
    end

    if data.names !== nothing && length(data.names) != length(data.xs)
        return "the number of names: $(length(data.names))\n" *
               "is different from the number of lines: $(length(data.xs))"
    end

    if data.line_colors !== nothing && length(data.line_colors) != length(data.xs)
        return "the number of line_colors: $(length(data.line_colors))\n" *
               "is different from the number of lines: $(length(data.xs))"
    end

    line_widths = data.line_widths
    if line_widths !== nothing
        if length(line_widths) != length(data.xs)
            return "the number of line_widths: $(length(line_widths))\n" *
                   "is different from the number of lines: $(length(data.xs))"
        end
        for (index, line_width) in enumerate(line_widths)
            if line_width <= 0
                return "non-positive line_width#$(index): $(line_width)"
            end
        end
    end

    if data.fill_belows !== nothing && length(data.fill_belows) != length(data.xs)
        return "the number of fill_belows: $(length(data.fill_belows))\n" *
               "is different from the number of lines: $(length(data.xs))"
    end

    if data.are_dashed !== nothing && length(data.are_dashed) != length(data.xs)
        return "the number of are_dashed: $(length(data.are_dashed))\n" *
               "is different from the number of lines: $(length(data.xs))"
    end

    return nothing
end

function render(data::LinesGraphData, configuration::LinesGraphConfiguration = LinesGraphConfiguration())::Nothing
    assert_valid_object(data)
    assert_valid_object(configuration)
    if configuration.stacking == StackPercents || configuration.stacking == StackFractions
        for (line_index, ys) in enumerate(data.ys)
            for (point_index, y) in enumerate(ys)
                @assert y >= 0 "negative stacked fraction/percent line#$(line_index) ys#$(point_index): $(y)"
            end
        end
    end

    if configuration.stacking === nothing
        xs = data.xs
        ys = data.ys
    else
        xs, ys = unify_xs(data.xs, data.ys)
    end

    traces = Vector{GenericTrace}()

    for index in 1:length(data.xs)
        push!(
            traces,
            lines_trace(
                data,
                configuration;
                xs = xs[index],
                ys = ys[index],
                index = index,
                legend_title = data.legend_title,
            ),
        )
    end

    layout = lines_layout(data, configuration; show_legend = configuration.show_legend)
    figure = plot(traces, layout)
    write_graph(figure, configuration.graph)
    return nothing
end

function unify_xs(
    xs::AbstractVector{<:AbstractVector{<:Real}},
    ys::AbstractVector{<:AbstractVector{<:Real}},
)::Tuple{Vector{Vector{Float32}}, Vector{Vector{Float32}}}
    n_lines = length(xs)
    unified_xs = Vector{Vector{Float32}}()
    unified_ys = Vector{Vector{Float32}}()
    zero_before = zeros(Bool, n_lines)
    zero_after = zeros(Bool, n_lines)
    for _ in 1:n_lines
        push!(unified_xs, Vector{Float32}())
        push!(unified_ys, Vector{Float32}())
    end
    next_point_indices = fill(1, n_lines)
    while true
        unified_x = nothing
        for line_index in 1:n_lines
            point_index = next_point_indices[line_index]
            if point_index <= length(xs[line_index])
                if unified_x === nothing
                    unified_x = xs[line_index][point_index]
                else
                    unified_x = min(unified_x, xs[line_index][point_index])
                end
            end
        end
        if unified_x === nothing
            return (unified_xs, unified_ys)
        end
        for line_index in 1:n_lines
            point_index = next_point_indices[line_index]
            next_x = xs[line_index][min(point_index, length(xs[line_index]))]
            if unified_x > next_x
                if !zero_after[line_index]
                    push!(unified_xs[line_index], next_x)
                    push!(unified_ys[line_index], 0)
                    zero_after[line_index] = true
                end
                push!(unified_xs[line_index], unified_x)
                push!(unified_ys[line_index], 0)
            else
                next_y = ys[line_index][point_index]
                if unified_x == next_x
                    if zero_before[line_index]
                        push!(unified_xs[line_index], unified_x)
                        push!(unified_ys[line_index], 0)
                        zero_before[line_index] = false
                    end
                    push!(unified_xs[line_index], next_x)
                    push!(unified_ys[line_index], next_y)
                    next_point_indices[line_index] += 1
                elseif point_index == 1
                    push!(unified_xs[line_index], unified_x)
                    push!(unified_ys[line_index], 0)
                    zero_before[line_index] = true
                else
                    @assert !zero_before[line_index]
                    prev_x = xs[line_index][point_index - 1]
                    prev_y = ys[line_index][point_index - 1]
                    push!(unified_xs[line_index], unified_x)
                    push!(unified_ys[line_index], prev_y + (next_y - prev_y) * (unified_x - prev_x) / (next_x - prev_x))
                end
            end
        end
    end
end

function lines_trace(
    data::LinesGraphData,
    configuration::LinesGraphConfiguration;
    xs::AbstractVector{<:Real},
    ys::AbstractVector{<:Real},
    index::Int,
    legend_title::Maybe{AbstractString},
)::GenericTrace
    return scatter(;
        x = xs,
        y = ys,
        line_color = data.line_colors !== nothing ? data.line_colors[index] : configuration.style.line_color,
        line_width = if data.line_widths !== nothing
            data.line_widths[index]
        elseif configuration.style.line_width === nothing
            0
        else
            configuration.style.line_width  # NOJET
        end,
        line_dash = if (data.are_dashed !== nothing ? data.are_dashed[index] : configuration.style.line_is_dashed)
            "dash"
        else
            nothing
        end,
        fill = if !(data.fill_belows !== nothing ? data.fill_belows[index] : configuration.style.fill_below)
            nothing
        elseif index == length(data.xs)
            "tozeroy"
        else
            "tonexty"
        end,
        name = data.names !== nothing ? data.names[index] : "Trace $(index)",
        stackgroup = configuration.stacking === nothing ? nothing : "stacked",
        groupnorm = if configuration.stacking == StackFractions
            "fraction"
        elseif configuration.stacking == StackPercents
            "percent"
        else
            nothing
        end,
        legendgroup = "lines",
        legendgrouptitle_text = legend_title,
        mode = "lines",
    )
end

function lines_layout(
    data::Union{LinesGraphData, LineGraphData},
    configuration::Union{LinesGraphConfiguration, LineGraphConfiguration};
    show_legend::Bool,
)::Layout
    return Layout(;  # NOJET
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
        yaxis_range = (configuration.y_axis.minimum, configuration.y_axis.maximum),
        yaxis_type = configuration.y_axis.log_scale ? "log" : nothing,
        showlegend = show_legend,
    )
end

"""
The direction of the CDF graph:

`UpToValue` - Show the fraction of values up to each value.

`DownToValue` - Show the fraction of values down to each value.
"""
@enum CdfDirection UpToValue DownToValue

"""
    @kwdef mutable struct CdfGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        fraction_axis::AxisConfiguration = AxisConfiguration()
        style::LineStyleConfiguration = LineStyleConfiguration()
        orientation::ValuesOrientation = HorizontalValues
        direction::CdfDirection = UpToValue
        value_bands::BandsConfiguration = BandsConfiguration()
        fraction_bands::BandsConfiguration = BandsConfiguration()
    end

Configure a graph for showing a CDF (Cumulative Distribution Function) graph. By default, the X axis is used for the
values and the Y axis for the fraction; this can be switched using the `orientation`. By default, the fraction is
of the values up to each value; this can be switched using the `direction`.

By default, the fraction axis units are between 0 and 1; if `show_percent`, this is changed to between 0 and 100.

CDF graphs are internally converted to line graphs for rendering.
"""
@kwdef mutable struct CdfGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    fraction_axis::AxisConfiguration = AxisConfiguration()
    style::LineStyleConfiguration = LineStyleConfiguration()
    orientation::ValuesOrientation = HorizontalValues
    direction::CdfDirection = UpToValue
    value_bands::BandsConfiguration = BandsConfiguration()
    fraction_bands::BandsConfiguration = BandsConfiguration()
    show_percent::Bool = false
end

"""
    @kwdef mutable struct CdfGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        fraction_axis_title::Maybe{AbstractString} = nothing
        values::AbstractVector{<:Real}
    end

The data for a CDF (Cumulative Distribution Function) graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title` and
`fraction_axis_title` for the axes.

The order of the `values` does not matter.
"""
@kwdef mutable struct CdfGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    fraction_axis_title::Maybe{AbstractString} = nothing
    values::AbstractVector{<:Real}
end

function Validations.validate_object(data::CdfGraphData)::Maybe{AbstractString}
    if length(data.values) < 2
        return "too few values: $(length(data.values))"
    end
    return nothing
end

function render(data::CdfGraphData, configuration::CdfGraphConfiguration = CdfGraphConfiguration())::Nothing
    assert_valid_object(data)
    assert_valid_object(configuration)

    line_data = cdf_data_as_line_data(data, configuration)
    line_configuration = cdf_configuration_as_line_configuration(configuration)
    render(line_data, line_configuration)
    return nothing
end

function cdf_data_as_line_data(data::CdfGraphData, configuration::CdfGraphConfiguration)::LineGraphData
    values, fractions = collect_cdf_data(data.values, configuration)
    if configuration.orientation == HorizontalValues
        return LineGraphData(;
            graph_title = data.graph_title,
            x_axis_title = data.value_axis_title,
            y_axis_title = data.fraction_axis_title,
            xs = values,
            ys = fractions,
        )
    else
        return LineGraphData(;
            graph_title = data.graph_title,
            x_axis_title = data.fraction_axis_title,
            y_axis_title = data.value_axis_title,
            xs = fractions,
            ys = values,
        )
    end
end

function cdf_configuration_as_line_configuration(configuration::CdfGraphConfiguration)::LineGraphConfiguration
    if configuration.orientation == HorizontalValues
        return LineGraphConfiguration(;
            graph = configuration.graph,
            x_axis = configuration.value_axis,
            y_axis = configuration.fraction_axis,
            style = configuration.style,
            vertical_bands = configuration.value_bands,
            horizontal_bands = configuration.fraction_bands,
        )
    else
        return LineGraphConfiguration(;
            graph = configuration.graph,
            x_axis = configuration.fraction_axis,
            y_axis = configuration.value_axis,
            style = configuration.style,
            vertical_bands = configuration.fraction_bands,
            horizontal_bands = configuration.value_bands,
        )
    end
end

"""
    @kwdef mutable struct CdfsGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        fraction_axis::AxisConfiguration = AxisConfiguration()
        style::LineStyleConfiguration = LineStyleConfiguration()
        orientation::ValuesOrientation = HorizontalValues
        direction::CdfDirection = UpToValue
        value_bands::BandsConfiguration = BandsConfiguration()
        fraction_bands::BandsConfiguration = BandsConfiguration()
        show_legend::Bool = false
    end

Configure a graph for showing multiple CDF (Cumulative Distribution Function) graph. This is the same as
[`CdfGraphConfiguration`](@ref) with the addition of a `show_legend` field.

CDF graphs are internally converted to line graphs for rendering.
"""
@kwdef mutable struct CdfsGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    fraction_axis::AxisConfiguration = AxisConfiguration()
    style::LineStyleConfiguration = LineStyleConfiguration()
    orientation::ValuesOrientation = HorizontalValues
    direction::CdfDirection = UpToValue
    value_bands::BandsConfiguration = BandsConfiguration()
    fraction_bands::BandsConfiguration = BandsConfiguration()
    show_percent::Bool = false
    show_legend::Bool = false
end

function Validations.validate_object(
    configuration::Union{CdfGraphConfiguration, CdfsGraphConfiguration},
)::Maybe{AbstractString}
    message = validate_object(configuration.graph)
    if message === nothing
        message = validate_object("value", configuration.value_axis)
    end
    if message === nothing
        message = validate_object("fraction", configuration.fraction_axis)
    end
    if message === nothing
        message = validate_object(configuration.style)
    end
    if message === nothing
        message = validate_object("value_bands", configuration.value_bands, false)
    end
    if message === nothing
        message = validate_object("fraction_bands", configuration.fraction_bands, false)
    end
    return message
end

"""
    @kwdef mutable struct CdfsGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        fraction_axis_title::Maybe{AbstractString} = nothing
        values::AbstractVector{<:AbstractVector{<:Real}}
        names::Maybe{AbstractStringVector} = nothing
        line_colors::Maybe{AbstractStringVector} = nothing
        line_widths::Maybe{AbstractVector{<:Real}} = nothing
        fill_belows::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing
        are_dashed::Maybe{AbstractVector{Bool}} = nothing
    end

The data for multiple CDFs (Cumulative Distribution Functions) graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title` and
`fraction_axis_title` for the axes.

The order of the `values` does not matter.
"""
@kwdef mutable struct CdfsGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    fraction_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    values::AbstractVector{<:AbstractVector{<:Real}}
    names::Maybe{AbstractStringVector} = nothing
    line_colors::Maybe{AbstractStringVector} = nothing
    line_widths::Maybe{AbstractVector{<:Real}} = nothing
    fill_belows::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing
    are_dashed::Maybe{AbstractVector{Bool}} = nothing
end

function Validations.validate_object(data::CdfsGraphData)::Maybe{AbstractString}
    if length(data.values) == 0
        return "empty values vector"
    end
    for (index, values) in enumerate(data.values)
        if length(values) < 2
            return "too few values#$(index): $(length(values))"
        end
    end
    return nothing
end

function render(data::CdfsGraphData, configuration::CdfsGraphConfiguration = CdfsGraphConfiguration())::Nothing
    assert_valid_object(data)
    assert_valid_object(configuration)

    lines_data = cdfs_data_as_lines_data(data, configuration)
    lines_configuration = cdfs_configuration_as_lines_configuration(configuration)
    render(lines_data, lines_configuration)
    return nothing
end

function cdfs_data_as_lines_data(data::CdfsGraphData, configuration::CdfsGraphConfiguration)::LinesGraphData
    fractions = Vector{Vector{Float64}}()
    values = Vector{Vector{eltype(eltype(data.values))}}()
    for trace_values in data.values
        trace_values, trace_fractions = collect_cdf_data(trace_values, configuration)
        push!(fractions, trace_fractions)
        push!(values, trace_values)
    end
    if configuration.orientation == HorizontalValues
        return LinesGraphData(;
            graph_title = data.graph_title,
            x_axis_title = data.value_axis_title,
            y_axis_title = data.fraction_axis_title,
            legend_title = data.legend_title,
            xs = values,
            ys = fractions,
            names = data.names,
            line_colors = data.line_colors,
            line_widths = data.line_widths,
            fill_belows = data.fill_belows,
            are_dashed = data.are_dashed,
        )
    else
        return LinesGraphData(;
            graph_title = data.graph_title,
            x_axis_title = data.fraction_axis_title,
            y_axis_title = data.value_axis_title,
            legend_title = data.legend_title,
            xs = fractions,
            ys = values,
            names = data.names,
            line_colors = data.line_colors,
            line_widths = data.line_widths,
            fill_belows = data.fill_belows,
            are_dashed = data.are_dashed,
        )
    end
end

function collect_cdf_data(
    values::AbstractVector{T},
    configuration::Union{CdfGraphConfiguration, CdfsGraphConfiguration},
)::Tuple{Vector{T}, Vector{Float64}} where {T <: Real}
    n_values = length(values)
    sorted_values = sort(values)
    fractions = collect(1.0:length(sorted_values)) ./ n_values
    if configuration.direction == DownToValue
        fractions = (1 + 1 / n_values) .- fractions
    end
    if configuration.show_percent
        fractions .*= 100
    end
    return (sorted_values, fractions)
end

function cdfs_configuration_as_lines_configuration(configuration::CdfsGraphConfiguration)::LinesGraphConfiguration
    if configuration.orientation == HorizontalValues
        return LinesGraphConfiguration(;
            graph = configuration.graph,
            x_axis = configuration.value_axis,
            y_axis = configuration.fraction_axis,
            style = configuration.style,
            vertical_bands = configuration.value_bands,
            horizontal_bands = configuration.fraction_bands,
            show_legend = configuration.show_legend,
        )
    else
        return LinesGraphConfiguration(;
            graph = configuration.graph,
            x_axis = configuration.fraction_axis,
            y_axis = configuration.value_axis,
            style = configuration.style,
            vertical_bands = configuration.fraction_bands,
            horizontal_bands = configuration.value_bands,
            show_legend = configuration.show_legend,
        )
    end
end

"""
    @kwdef mutable struct BarGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        color::Maybe{AbstractString} = nothing
        orientation::ValuesOrientation = VerticalValues
    end

Configure a graph for showing a single bar (histogram) graph. The `color` is chosen automatically. You can override it
globally, or per-bar in the [`BarGraphData`](@ref). By default, the X axis is used for the bars and the Y axis for the
values; this can be switched using the `orientation`.
"""
@kwdef mutable struct BarGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    color::Maybe{AbstractString} = nothing
    orientation::ValuesOrientation = VerticalValues
end

"""
    @kwdef mutable struct BarGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        bar_axis_title::Maybe{AbstractString} = nothing
        values::AbstractVector{<:Real}
        names::Maybe{AbstractStringVector} = nothing
        colors::Maybe{AbstractStringVector} = nothing
        hovers::Maybe{AbstractStringVector} = nothing
    end

The data for a single bar (histogram) graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title` and
`bar_axis_title` for the axes.

If specified, the `names` and/or `colors` and/or `hovers` vectors must contain the same number of elements as the number
of `values`.
"""
@kwdef mutable struct BarGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    bar_axis_title::Maybe{AbstractString} = nothing
    values::AbstractVector{<:Real}
    names::Maybe{AbstractStringVector} = nothing
    colors::Maybe{AbstractStringVector} = nothing
    hovers::Maybe{AbstractStringVector} = nothing
end

function Validations.validate_object(data::BarGraphData)::Maybe{AbstractString}
    if length(data.values) == 0
        return "empty values vector"
    end
    names = data.names
    if names !== nothing && length(names) != length(data.values)
        return "the number of names: $(length(names))\n" *
               "is different from the number of bars: $(length(data.values))"
    end
    colors = data.colors
    if colors !== nothing && length(colors) != length(data.values)
        return "the number of colors: $(length(colors))\n" *
               "is different from the number of bars: $(length(data.values))"
    end
    hovers = data.hovers
    if hovers !== nothing && length(hovers) != length(data.values)
        return "the number of hovers: $(length(hovers))\n" *
               "is different from the number of bars: $(length(data.values))"
    end
    return nothing
end

function render(data::BarGraphData, configuration::BarGraphConfiguration)::Nothing
    assert_valid_object(data)
    assert_valid_object(configuration)

    trace = bar_trace(
        data,
        configuration;
        values = data.values,
        color = data.colors !== nothing ? data.colors : configuration.color,
        hover = data.hovers,
        names = data.names,
    )
    layout = bar_layout(data, configuration; has_tick_names = data.names !== nothing, show_legend = false)
    figure = plot(trace, layout)
    write_graph(figure, configuration.graph)

    return nothing
end

"""
    @kwdef mutable struct BarsGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        color::Maybe{AbstractString} = nothing
        orientation::ValuesOrientation = VerticalValues
        show_legend::Bool = false
        stacking::Maybe{Stacking} = nothing
    end

Configure a graph for showing multiple bars (histograms) graph. This is similar to [`BarGraphConfiguration`](@ref),
without the `color` field (which makes no sense when multiple series are shown), and with the addition of a
`show_legend` and `stacking` fields. If `stacking` isn't specified then the different series are just grouped.
"""
@kwdef mutable struct BarsGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    orientation::ValuesOrientation = VerticalValues
    show_legend::Bool = false
    stacking::Maybe{Stacking} = nothing
end

function Validations.validate_object(
    configuration::Union{BarGraphConfiguration, BarsGraphConfiguration},
)::Maybe{AbstractString}
    message = validate_object(configuration.graph)
    if message === nothing
        message = validate_object("value", configuration.value_axis)
    end
    return message
end

"""
    @kwdef mutable struct BarsGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        bar_axis_title::Maybe{AbstractString} = nothing
        legend_title::Maybe{AbstractString} = nothing
        values::AbstractString{<:AbstractVector{<:Real}}
        names::Maybe{AbstractStringVector} = nothing
        colors::Maybe{AbstractStringVector} = nothing
        hovers::Maybe{AbstractStringVector} = nothing
        bar_names::Maybe{AbstractStringVector} = nothing
    end

The data for a multiple bars (histograms) graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title`,
`bar_axis_title` for the axes, and the `legend_title` (if `show_legend` is set in [`BarsGraphConfiguration`](@ref).

All the `values` vectors must be of the same size. If specified, the `bar_names vector must contain the same number of elements. If specified, the `names`and/or`colors`and/or`hovers`vectors must contain the same number of elements as the number of`values` vectors (that is, the number of series).
"""
@kwdef mutable struct BarsGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    bar_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    values::AbstractVector{<:AbstractVector{<:Real}}
    names::Maybe{AbstractStringVector} = nothing
    colors::Maybe{AbstractStringVector} = nothing
    hovers::Maybe{AbstractStringVector} = nothing
    bar_names::Maybe{AbstractStringVector} = nothing
end

function Validations.validate_object(data::BarsGraphData)::Maybe{AbstractString}
    n_series = length(data.values)
    if n_series == 0
        return "empty values vector"
    end
    n_values = length(data.values[1])
    for (index, values) in enumerate(data.values)
        if length(values) != n_values
            return "the number of values#1: $(n_values)\n" *
                   "is different from the number of values#$(index): $(length(values))"
        end
    end
    if n_values == 0
        return "empty values vectors"
    end
    names = data.names
    if names !== nothing && length(names) != n_series
        return "the number of names: $(length(names))\n" * "is different from the number of series: $(n_series)"
    end
    colors = data.colors
    if colors !== nothing && length(colors) != n_series
        return "the number of colors: $(length(colors))\n" * "is different from the number of series: $(n_series)"
    end
    hovers = data.hovers
    if hovers !== nothing && length(hovers) != n_series
        return "the number of hovers: $(length(hovers))\n" * "is different from the number of series: $(n_series)"
    end
    bar_names = data.bar_names
    if bar_names !== nothing && length(bar_names) != n_values
        return "the number of bar_names: $(length(bar_names))\n" * "is different from the number of bars: $(n_values)"
    end
    return nothing
end

function render(data::BarsGraphData, configuration::BarsGraphConfiguration)::Nothing
    assert_valid_object(data)
    assert_valid_object(configuration)

    stacking = configuration.stacking
    if stacking === nothing
        values = data.values
    else
        for (series_index, values) in enumerate(data.values)
            for (bar_index, value) in enumerate(values)
                @assert value >= 0 "negative stacked value#$(bar_index) of series#$(series_index): $(value)"
            end
        end
        values = stacked_values(stacking, data.values)
    end

    traces = Vector{GenericTrace}()
    for index in 1:length(data.values)
        push!(
            traces,
            bar_trace(
                data,
                configuration;
                values = values[index],
                color = data.colors !== nothing ? data.colors[index] : nothing,
                hover = data.hovers !== nothing ? fill(data.hovers[index], length(values[1])) : nothing,
                names = data.bar_names,
                name = data.names !== nothing ? data.names[index] : "Series $(index)",
                legend_title = data.legend_title,
            ),
        )
    end
    layout = bar_layout(
        data,
        configuration;
        has_tick_names = data.bar_names !== nothing,
        show_legend = configuration.show_legend,
        stacked = configuration.stacking !== nothing,
    )
    figure = plot(traces, layout)
    write_graph(figure, configuration.graph)

    return nothing
end

function stacked_values(stacking::Stacking, values::T)::T where {(T <: AbstractVector{<:AbstractVector{<:Real}})}
    if stacking == StackValues
        return values
    end

    total_values = zeros(eltype(eltype(values)), length(values[1]))
    for series_values in values
        total_values .+= series_values
    end

    if stacking == StackPercents
        total_values ./= 100
    end
    total_values[total_values .== 0] .= 1

    return [series_values ./= total_values for series_values in values]
end

function bar_trace(
    data::Union{BarGraphData, BarsGraphData},
    configuration::Union{BarGraphConfiguration, BarsGraphConfiguration};
    values::AbstractVector{<:Real},
    color::Maybe{Union{AbstractString, AbstractStringVector}},
    hover::Maybe{Union{AbstractString, AbstractStringVector}},
    names::Maybe{AbstractStringVector},
    name::Maybe{AbstractString} = nothing,
    legend_title::Maybe{AbstractString} = nothing,
)::GenericTrace
    if configuration.orientation == HorizontalValues
        xs = values
        ys = names !== nothing ? names : ["Bar $(index)" for index in 1:length(data.values)]
        orientation = "h"
    elseif configuration.orientation == VerticalValues
        xs = names !== nothing ? names : ["Bar $(index)" for index in 1:length(data.values)]
        ys = values
        orientation = "v"
    else
        @assert false
    end
    return bar(;
        x = xs,
        y = ys,
        name = name,
        orientation = orientation,
        marker_color = color,
        customdata = hover,
        hovertemplate = hover === nothing ? nothing : "%{customdata}<extra></extra>",
        legendgroup = "series",
        legendgrouptitle_text = legend_title,
    )
end

function bar_layout(
    data::Union{BarGraphData, BarsGraphData},
    configuration::Union{BarGraphConfiguration, BarsGraphConfiguration};
    has_tick_names::Bool,
    show_legend::Bool,
    stacked::Bool = false,
)::Layout
    if configuration.orientation == HorizontalValues
        xaxis_showgrid = configuration.graph.show_grid
        xaxis_showticklabels = configuration.graph.show_ticks
        xaxis_title = data.value_axis_title
        xaxis_range = (configuration.value_axis.minimum, configuration.value_axis.maximum)
        xaxis_type = configuration.value_axis.log_scale ? "log" : nothing

        yaxis_showgrid = false
        yaxis_showticklabels = has_tick_names
        yaxis_title = data.bar_axis_title
        yaxis_range = nothing
        yaxis_type = nothing
    elseif configuration.orientation == VerticalValues
        xaxis_showgrid = false
        xaxis_showticklabels = has_tick_names
        xaxis_title = data.bar_axis_title
        xaxis_range = nothing
        xaxis_type = nothing

        yaxis_showgrid = configuration.graph.show_grid
        yaxis_showticklabels = configuration.graph.show_ticks
        yaxis_title = data.value_axis_title
        yaxis_range = (configuration.value_axis.minimum, configuration.value_axis.maximum)
        yaxis_type = configuration.value_axis.log_scale ? "log" : nothing
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
        barmode = stacked ? "stack" : nothing,
    )
end

"""
    @kwdef mutable struct PointsStyleConfiguration <: ObjectWithValidation
        size::Maybe{Real} = nothing
        color::Maybe{AbstractString} = nothing
        color_scale::Maybe{Union{
            AbstractString,
            AbstractVector{<:Tuple{<:Real, <:AbstractString}},
            AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        }} = nothing
        reverse_scale::Bool = false
        show_scale::Bool = false
    end

Configure points in a graph. By default, the point `size` and `color` is chosen automatically (when this is applied to
edges, the `size` is the width of the line). You can also override this by specifying sizes and colors in the
[`PointsGraphData`](@ref). If the data contains numeric color values, then the `color_scale` will be used instead; you
can set `reverse_scale` to reverse it. You need to explicitly set `show_scale` to show its legend.

The `color_scale` can be the name of a standard one, a vector of (value, color) tuples for a continuous scale. If the
values are numbers, the scale is continuous; if they are strings, this is a categorical scale. A categorical scale can't
be reversed.
"""
@kwdef mutable struct PointsStyleConfiguration <: ObjectWithValidation
    size::Maybe{Real} = nothing
    color::Maybe{AbstractString} = nothing
    color_scale::Maybe{
        Union{
            AbstractString,
            AbstractVector{<:Tuple{<:Real, <:AbstractString}},
            AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
        },
    } = nothing
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
    color_scale = configuration.color_scale
    if color_scale isa AbstractVector
        if length(color_scale) == 0
            return "empty $(of_what) style.color_scale"
        end
        if eltype(color_scale) <: Tuple{<:Real, <:AbstractString}
            cmin = minimum([value for (value, _) in color_scale])
            cmax = maximum([value for (value, _) in color_scale])
            if cmin == cmax
                return "single $(of_what) style.color_scale value: $(cmax)"
            end
        elseif configuration.reverse_scale
            return "reversed categorical $(of_what) style.color_scale"
        end
    end
    return nothing
end

"""
    @kwdef mutable struct PointsGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        style::PointsStyleConfiguration = PointsStyleConfiguration()
        border_style::PointsStyleConfiguration = PointsStyleConfiguration()
        edges_style::PointsConfiguration = PointsStyleConfiguration()
        vertical_bands::BandsConfiguration = BandsConfiguration()
        horizontal_bands::BandsConfiguration = BandsConfiguration()
        diagonal_bands::BandsConfiguration = BandsConfiguration()
    end

Configure a graph for showing a scatter graph of points.

Using the `vertical_bands`, `horizontal_bands` and/or `diagonal_bands` you can partition the graph into regions. The
`diagonal_bands` can only be used if both axes are linear or both axes are in `log_scale`; they also unify the ranges of
the X and Y axes. If the axes are in `log_scale`, the `line_offset` of the `diagonal_bands` are multiplicative instead
of additive, and must be positive.

The `border_style` is used if the [`PointsGraphData`](@ref) contains either the `border_colors` and/or `border_sizes`.
This allows displaying some additional data per point.

!!! note

    There is no `show_legend` for a [`GraphConfiguration`](@ref) of a points graph. Instead you probably want to set the
    `show_scale` of the `style` (and/or of the `border_style` and/or `edges_style`). In addition, the color scale
    options of the `edges_style` must not be set, as the `edges_colors` of [`PointsGraphData`](@ref) is restricted to
    explicit colors.
"""
@kwdef mutable struct PointsGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    style::PointsStyleConfiguration = PointsStyleConfiguration()
    border_style::PointsStyleConfiguration = PointsStyleConfiguration()
    edges_style::PointsStyleConfiguration = PointsStyleConfiguration()
    vertical_bands::BandsConfiguration = BandsConfiguration()
    horizontal_bands::BandsConfiguration = BandsConfiguration()
    diagonal_bands::BandsConfiguration = BandsConfiguration()
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
    if message === nothing
        message = validate_object("vertical_bands", configuration.vertical_bands, false)
    end
    if message === nothing
        message = validate_object("horizontal_bands", configuration.horizontal_bands, false)
    end
    if message === nothing &&
       configuration.x_axis.log_scale != configuration.y_axis.log_scale &&
       (
           configuration.diagonal_bands.low.line_offset !== nothing ||
           configuration.diagonal_bands.middle.line_offset !== nothing ||
           configuration.diagonal_bands.high.line_offset !== nothing
       )
        message = "diagonal_bands specified for a combination of linear and log scale axes"
    end
    if message === nothing
        message = validate_object("diagonal_bands", configuration.diagonal_bands, configuration.x_axis.log_scale)
    end
    return message
end

"""
    @kwdef mutable struct PointsGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        scale_title::Maybe{AbstractString} = nothing
        border_scale_title::Maybe{AbstractString} = nothing
        xs::AbstractVector{<:Real}
        ys::AbstractVector{<:Real}
        colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing
        sizes::Maybe{AbstractVector{<:Real}} = nothing
        hovers::Maybe{AbstractStringVector} = nothing
        border_colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing
        border_sizes::Maybe{AbstractVector{<:Real}} = nothing
        edges::Maybe{AbstractVector{Tuple{<:Integer, <:Integer}}} = nothing
        edges_colors::Maybe{AbstractStringVector} = nothing
        edges_sizes::Maybe{AbstractVector{<:Real}} = nothing
    end

The data for a scatter graph of points.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `x_axis_title` and
`y_axis_title` for the axes.

The `xs` and `ys` vectors must be of the same size. If specified, the `colors` `sizes` and/or `hovers` vectors must also
be of the same size. The `colors` can be either color names or a numeric value; if the latter, then the configuration's
`color_scale` is used. Sizes are the diameter in pixels (1/96th of an inch). Hovers are only shown in interactive graphs
(or when saving an HTML file).

The `border_colors` and `border_sizes` can be used to display additional data per point. The border size is in addition
to the point size.

The `scale_title` and `border_scale_title` are only used if `show_scale` is set for the relevant color scales. You can't
specify `show_scale` if there is no `colors` data or if the `colors` contain explicit color names.

It is possible to draw straight `edges` between specific point pairs. In this case the `edges_style` of the
[`PointsGraphConfiguration`](@ref) will be used, and the `edges_colors` and `edges_sizes` will override it per edge.
The `edges_colors` are restricted to explicit colors, not a color scale.
"""
@kwdef mutable struct PointsGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    scale_title::Maybe{AbstractString} = nothing
    border_scale_title::Maybe{AbstractString} = nothing
    xs::AbstractVector{<:Real}
    ys::AbstractVector{<:Real}
    colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing
    sizes::Maybe{AbstractVector{<:Real}} = nothing
    hovers::Maybe{AbstractStringVector} = nothing
    border_colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing
    border_sizes::Maybe{AbstractVector{<:Real}} = nothing
    edges::Maybe{AbstractVector{Tuple{<:Integer, <:Integer}}} = nothing
    edges_colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing
    edges_sizes::Maybe{AbstractVector{<:Real}} = nothing
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
    if configuration.style.color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        @assert data.colors isa AbstractStringVector "categorical style.color_scale for non-string points data.colors"
    end
    if configuration.border_style.color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        @assert data.border_colors isa AbstractStringVector (
            "categorical borders_style.color_scale for non-string points data.border_colors"
        )
    end
    if configuration.style.show_scale
        @assert data.colors !== nothing "no data.colors specified for points style.show_scale"
        @assert !(data.colors isa AbstractStringVector) ||
                configuration.style.color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}} (
            "explicit data.colors specified for points style.show_scale"
        )
    end
    if configuration.border_style.color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        @assert data.border_colors isa AbstractStringVector "categorical color_scale for non-string points border_colors data"
    end
    if configuration.border_style.show_scale
        @assert data.border_colors !== nothing "no data.border_colors specified for points border_style.show_scale"
        @assert !(data.border_colors isa AbstractStringVector) ||
                configuration.border_style.color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}} (
            "explicit data.border_colors specified for points border_style.show_scale"
        )
    end

    traces = Vector{GenericTrace}()

    minimum_x = minimum(data.xs)
    minimum_y = minimum(data.ys)
    maximum_x = maximum(data.xs)
    maximum_y = maximum(data.ys)

    push_fill_vertical_bands_traces(traces, configuration.vertical_bands, minimum_x, minimum_y, maximum_x, maximum_y)
    push_fill_horizontal_bands_traces(
        traces,
        configuration.horizontal_bands,
        minimum_x,
        minimum_y,
        maximum_x,
        maximum_y,
    )
    push_fill_diagonal_bands_traces(
        traces,
        configuration.diagonal_bands,
        minimum_x,
        minimum_y,
        maximum_x,
        maximum_y;
        log_scale = configuration.x_axis.log_scale,
    )

    if data.border_colors !== nothing || data.border_sizes !== nothing
        color_scale = configuration.border_style.color_scale
        if color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            border_colors = data.border_colors
            @assert border_colors !== nothing
            for (value, color) in color_scale
                mask = border_colors .== value
                if any(mask)
                    marker_size = border_marker_size(data, configuration, mask)
                    push!(
                        traces,
                        points_trace(
                            data;
                            color = color,
                            marker_size = marker_size,
                            coloraxis = nothing,
                            points_style = configuration.border_style,
                            scale_title = data.border_scale_title,
                            legend_group = "borders",
                            mask = mask,
                            name = value,
                        ),
                    )
                end
            end
        else
            marker_size = border_marker_size(data, configuration)
            push!(
                traces,
                points_trace(
                    data;
                    color = data.border_colors,
                    marker_size = marker_size,
                    coloraxis = "coloraxis2",
                    points_style = configuration.border_style,
                    scale_title = data.border_scale_title,
                    legend_group = "borders",
                ),
            )
        end
    end

    color_scale = configuration.style.color_scale
    if color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        for (value, color) in color_scale
            colors = data.colors
            @assert colors !== nothing
            mask = colors .== value
            if any(mask)
                push!(
                    traces,
                    points_trace(
                        data;
                        color = color,
                        marker_size = data.sizes !== nothing ? data.sizes : configuration.style.size,
                        coloraxis = nothing,
                        points_style = configuration.style,
                        scale_title = data.scale_title,
                        legend_group = "points",
                        mask = mask,
                        name = value,
                    ),
                )
            end
        end
    else
        push!(
            traces,
            points_trace(
                data;
                color = data.colors,
                marker_size = data.sizes !== nothing ? data.sizes : configuration.style.size,
                coloraxis = "coloraxis",
                points_style = configuration.style,
                scale_title = data.scale_title,
                legend_group = "points",
            ),
        )
    end

    edges = data.edges
    if edges !== nothing
        for index in 1:length(edges)
            push!(traces, edge_trace(data, configuration.edges_style; index = index))
        end
    end

    for band in
        (configuration.vertical_bands.low, configuration.vertical_bands.middle, configuration.vertical_bands.high)
        if band.line_offset !== nothing && band.line_color !== nothing
            push!(traces, vertical_line_trace(band, minimum_y, maximum_y))
        end
    end

    for band in
        (configuration.horizontal_bands.low, configuration.horizontal_bands.middle, configuration.horizontal_bands.high)
        if band.line_offset !== nothing && band.line_color !== nothing
            push!(traces, horizontal_line_trace(band, minimum_x, maximum_x))
        end
    end

    for band in
        (configuration.diagonal_bands.low, configuration.diagonal_bands.middle, configuration.diagonal_bands.high)
        if band.line_offset !== nothing && band.line_color !== nothing
            push!(
                traces,
                diagonal_line_trace(
                    band,
                    minimum_x,
                    minimum_y,
                    maximum_x,
                    maximum_y;
                    log_scale = configuration.x_axis.log_scale,
                ),
            )
        end
    end

    layout = points_layout(data, configuration)
    figure = plot(traces, layout)
    write_graph(figure, configuration.graph)

    return nothing
end

function push_fill_vertical_bands_traces(
    traces::Vector{GenericTrace},
    configuration::BandsConfiguration,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
)::Nothing
    if configuration.low.line_offset !== nothing && configuration.low.fill_color !== nothing
        push!(  # NOJET
            traces,
            fill_trace(
                [minimum_x, configuration.low.line_offset, configuration.low.line_offset, minimum_x],
                [minimum_y, minimum_y, maximum_y, maximum_y];
                color = configuration.low.fill_color,
            ),
        )
    end

    if configuration.high.line_offset !== nothing && configuration.high.fill_color !== nothing
        push!(  # NOJET
            traces,
            fill_trace(
                [maximum_x, configuration.high.line_offset, configuration.high.line_offset, maximum_x],
                [minimum_y, minimum_y, maximum_y, maximum_y];
                color = configuration.high.fill_color,
            ),
        )
    end

    if configuration.high.line_offset !== nothing &&
       configuration.low.line_offset !== nothing &&
       configuration.middle.fill_color !== nothing
        push!(  # NOJET
            traces,
            fill_trace(
                [
                    configuration.low.line_offset,
                    configuration.high.line_offset,
                    configuration.high.line_offset,
                    configuration.low.line_offset,
                ],
                [minimum_y, minimum_y, maximum_y, maximum_y];
                color = configuration.middle.fill_color,
            ),
        )
    end

    return nothing
end

function push_fill_horizontal_bands_traces(
    traces::Vector{GenericTrace},
    configuration::BandsConfiguration,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
)::Nothing
    if configuration.low.line_offset !== nothing && configuration.low.fill_color !== nothing
        push!(  # NOJET
            traces,
            fill_trace(
                [minimum_x, minimum_x, maximum_x, maximum_x],
                [minimum_y, configuration.low.line_offset, configuration.low.line_offset, minimum_y];
                color = configuration.low.fill_color,
            ),
        )
    end

    if configuration.high.line_offset !== nothing && configuration.high.fill_color !== nothing
        push!(  # NOJET
            traces,
            fill_trace(
                [minimum_x, minimum_x, maximum_x, maximum_x],
                [maximum_y, configuration.high.line_offset, configuration.high.line_offset, maximum_y];
                color = configuration.high.fill_color,
            ),
        )
    end

    if configuration.high.line_offset !== nothing &&
       configuration.low.line_offset !== nothing &&
       configuration.middle.fill_color !== nothing
        push!(  # NOJET
            traces,
            fill_trace(
                [minimum_x, minimum_x, maximum_x, maximum_x],
                [
                    configuration.low.line_offset,
                    configuration.high.line_offset,
                    configuration.high.line_offset,
                    configuration.low.line_offset,
                ];
                color = configuration.middle.fill_color,
            ),
        )
    end

    return nothing
end

function push_fill_diagonal_bands_traces(
    traces::Vector{GenericTrace},
    configuration::BandsConfiguration,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real;
    log_scale::Bool,
)::Nothing
    if configuration.low.line_offset !== nothing && configuration.low.fill_color !== nothing
        push!(  # NOJET
            traces,
            low_diagonal_trace(
                configuration.low.line_offset,
                minimum_x,
                minimum_y,
                maximum_x,
                maximum_y;
                color = configuration.low.fill_color,
                log_scale = log_scale,
            ),
        )
    end

    if configuration.high.line_offset !== nothing && configuration.high.fill_color !== nothing
        push!(  # NOJET
            traces,
            high_diagonal_trace(
                configuration.high.line_offset,
                minimum_x,
                minimum_y,
                maximum_x,
                maximum_y;
                color = configuration.high.fill_color,
                log_scale = log_scale,
            ),
        )
    end

    if configuration.high.line_offset !== nothing &&
       configuration.low.line_offset !== nothing &&
       configuration.middle.fill_color !== nothing
        push!(  # NOJET
            traces,
            middle_diagonal_trace(
                configuration.low.line_offset,
                configuration.high.line_offset,
                minimum_x,
                minimum_y,
                maximum_x,
                maximum_y;
                color = configuration.middle.fill_color,
                log_scale = log_scale,
            ),
        )
    end

    return nothing
end

function low_diagonal_trace(
    offset::Real,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real;
    color::AbstractString,
    log_scale::Bool,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(log_scale)
    if offset < threshold
        return fill_trace(
            [decrease(minimum_xy, offset), maximum_xy, maximum_xy],
            [minimum_xy, increase(maximum_xy, offset), minimum_xy];
            color = color,
        )
    else
        return fill_trace(
            [minimum_xy, maximum_xy, maximum_xy, decrease(maximum_xy, offset), minimum_xy],
            [minimum_xy, minimum_xy, maximum_xy, maximum_xy, increase(minimum_xy, offset)];
            color = color,
        )
    end
end

function high_diagonal_trace(
    offset::Real,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real;
    color::AbstractString,
    log_scale::Bool,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(log_scale)
    if offset < threshold
        return fill_trace(
            [minimum_xy, minimum_xy, maximum_xy, maximum_xy, decrease(minimum_xy, offset)],
            [minimum_xy, maximum_xy, maximum_xy, increase(maximum_xy, offset), minimum_xy];
            color = color,
        )
    else
        return fill_trace(
            [minimum_xy, decrease(maximum_xy, offset), minimum_xy],
            [increase(minimum_xy, offset), maximum_xy, maximum_xy];
            color = color,
        )
    end
end

function middle_diagonal_trace(
    low_offset::Real,
    high_offset::Real,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real;
    color::AbstractString,
    log_scale::Bool,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(log_scale)
    if high_offset < threshold
        return fill_trace(
            [decrease(minimum_xy, high_offset), decrease(minimum_xy, low_offset), maximum_xy, maximum_xy],
            [minimum_xy, minimum_xy, increase(maximum_xy, low_offset), increase(maximum_xy, high_offset)];
            color = color,
        )
    elseif low_offset > threshold
        return fill_trace(
            [minimum_xy, minimum_xy, decrease(maximum_xy, high_offset), decrease(maximum_xy, low_offset)],
            [increase(minimum_xy, low_offset), increase(minimum_xy, high_offset), maximum_xy, maximum_xy];
            color = color,
        )
    else
        return fill_trace(
            [
                minimum_xy,
                decrease(minimum_xy, low_offset),
                maximum_xy,
                maximum_xy,
                decrease(maximum_xy, high_offset),
                minimum_xy,
            ],
            [
                minimum_xy,
                minimum_xy,
                increase(maximum_xy, low_offset),
                maximum_xy,
                maximum_xy,
                increase(minimum_xy, high_offset),
            ];
            color = color,
        )
    end
end

function fill_trace(xs::AbstractVector{<:Real}, ys::AbstractVector{<:Real}; color::AbstractString)::GenericTrace
    return scatter(; x = xs, y = ys, fill = "toself", fillcolor = color, name = "", mode = "none")
end

function border_marker_size(
    data::PointsGraphData,
    configuration::PointsGraphConfiguration,
    mask::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing,
)::Union{Real, Vector{<:Real}}
    sizes = masked_data(data.sizes, mask)
    border_sizes = masked_data(data.border_sizes, mask)

    if border_sizes === nothing
        border_marker_size = configuration.border_style.size !== nothing ? configuration.border_style.size : 4.0
        if sizes === nothing
            points_marker_size = configuration.style.size !== nothing ? configuration.style.size : 4.0
            return points_marker_size + 2 * border_marker_size
        else
            return sizes .+ 2 * border_marker_size  # untested
        end
    else
        if sizes === nothing
            points_marker_size = configuration.style.size !== nothing ? configuration.style.size : 4.0
            return 2 .* border_sizes .+ points_marker_size
        else
            return 2 .* border_sizes .+ sizes  # untested
        end
    end
end

function points_trace(
    data::PointsGraphData;
    color::Maybe{Union{AbstractString, AbstractStringVector, AbstractVector{<:Real}}},
    marker_size::Maybe{Union{Real, AbstractVector{<:Real}}},
    coloraxis::Maybe{AbstractString},
    points_style::PointsStyleConfiguration,
    scale_title::Maybe{AbstractString},
    legend_group::AbstractString,
    mask::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing,
    name::Maybe{AbstractString} = nothing,
)::GenericTrace
    return scatter(;
        x = masked_data(data.xs, mask),
        y = masked_data(data.ys, mask),
        marker_size = masked_data(marker_size, mask),
        marker_color = color !== nothing ? masked_data(color, mask) : points_style.color,
        marker_colorscale = if points_style.color_scale isa AbstractVector
            nothing
        else
            points_style.color_scale
        end,
        marker_coloraxis = coloraxis,
        marker_showscale = points_style.show_scale &&
                           !(points_style.color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}),
        marker_reversescale = points_style.reverse_scale,
        showlegend = points_style.show_scale &&
                     points_style.color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
        legendgroup = legend_group,
        legendgrouptitle_text = scale_title,
        name = name !== nothing ? name : points_style.show_scale ? "Trace" : "",
        text = data.hovers,
        hovertemplate = data.hovers === nothing ? nothing : "%{text}<extra></extra>",
        mode = "markers",
    )
end

function masked_data(data::Any, ::Any)::Any
    return data
end

function masked_data(data::AbstractVector, mask::Union{AbstractVector{Bool}, BitVector})::AbstractVector
    return data[mask]  # NOJET
end

function edge_trace(data::PointsGraphData, edges_style::PointsStyleConfiguration; index::Int)::GenericTrace
    from_point, to_point = data.edges[index]
    return scatter(;
        x = [data.xs[from_point], data.xs[to_point]],
        y = [data.ys[from_point], data.ys[to_point]],
        line_width = if data.edges_sizes !== nothing
            data.edges_sizes[index]
        else
            edges_style.size
        end,
        line_color = if data.edges_colors !== nothing
            data.edges_colors[index]
        elseif edges_style.color !== nothing
            edges_style.color
        else
            "darkgrey"
        end,
        name = "",
        mode = "lines",
    )
end

function vertical_line_trace(
    band_region_configuration::BandRegionConfiguration,
    minimum_y::Real,
    maximum_y::Real,
)::GenericTrace
    @assert band_region_configuration.line_offset !== nothing
    @assert band_region_configuration.line_color !== nothing
    return scatter(;
        x = [band_region_configuration.line_offset, band_region_configuration.line_offset],
        y = [minimum_y, maximum_y],
        line_width = band_region_configuration.line_width,
        line_color = band_region_configuration.line_color,
        line_dash = band_region_configuration.line_is_dashed ? "dash" : nothing,
        showlegend = false,
        mode = "lines",
    )
end

function horizontal_line_trace(
    band_region_configuration::BandRegionConfiguration,
    minimum_x::Real,
    maximum_x::Real,
)::GenericTrace
    @assert band_region_configuration.line_offset !== nothing
    @assert band_region_configuration.line_color !== nothing
    return scatter(;
        x = [minimum_x, maximum_x],
        y = [band_region_configuration.line_offset, band_region_configuration.line_offset],
        line_width = band_region_configuration.line_width,
        line_color = band_region_configuration.line_color,
        line_dash = band_region_configuration.line_is_dashed ? "dash" : nothing,
        showlegend = false,
        mode = "lines",
    )
end

function diagonal_line_trace(
    band_region_configuration::BandRegionConfiguration,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real;
    log_scale::Bool,
)::GenericTrace
    @assert band_region_configuration.line_offset !== nothing
    @assert band_region_configuration.line_color !== nothing
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)

    offset = band_region_configuration.line_offset
    threshold, increase, decrease = band_operations(log_scale)

    if offset < threshold
        x = [decrease(minimum_xy, offset), maximum_xy]
        y = [minimum_xy, increase(maximum_xy, offset)]
    else
        x = [minimum_xy, decrease(maximum_xy, offset)]
        y = [increase(minimum_xy, offset), maximum_xy]
    end

    return scatter(;
        x = x,
        y = y,
        line_width = band_region_configuration.line_width,
        line_color = band_region_configuration.line_color,
        line_dash = band_region_configuration.line_is_dashed ? "dash" : nothing,
        showlegend = false,
        mode = "lines",
    )
end

function band_operations(log_scale::Bool)::Tuple{Real, Function, Function}
    if log_scale
        return (1, *, /)
    else
        return (0, +, -)
    end
end

function points_layout(data::PointsGraphData, configuration::PointsGraphConfiguration)::Layout
    return Layout(;  # NOJET
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
        yaxis_range = (configuration.y_axis.minimum, configuration.y_axis.maximum),
        yaxis_type = configuration.y_axis.log_scale ? "log" : nothing,
        showlegend = (
            configuration.style.show_scale &&
            configuration.style.color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        ) || (
            configuration.border_style.show_scale &&
            configuration.border_style.color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        ),
        legend_x = if configuration.style.show_scale &&
                      configuration.border_style.show_scale &&
                      configuration.border_style.color_scale isa
                      AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            1.2
        else
            nothing
        end,
        coloraxis2_colorbar_x = if (configuration.border_style.show_scale && configuration.style.show_scale)
            1.2
        else
            nothing
        end,
        coloraxis_showscale = configuration.style.show_scale && !(
            configuration.style.color_scale isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        ),
        coloraxis_reversescale = configuration.style.reverse_scale,
        coloraxis_colorscale = normalized_color_scale(configuration.style.color_scale),
        coloraxis_cmin = lowest_color_scale(configuration.style.color_scale),
        coloraxis_cmax = highest_color_scale(configuration.style.color_scale),
        coloraxis_colorbar_title_text = data.scale_title,
        coloraxis2_showscale = (data.border_colors !== nothing || data.border_sizes !== nothing) &&
                               configuration.border_style.show_scale &&
                               !(
                                   configuration.border_style.color_scale isa
                                   AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
                               ),
        coloraxis2_reversescale = configuration.border_style.reverse_scale,
        coloraxis2_colorscale = normalized_color_scale(configuration.border_style.color_scale),
        coloraxis2_cmin = lowest_color_scale(configuration.border_style.color_scale),
        coloraxis2_cmax = highest_color_scale(configuration.border_style.color_scale),
        coloraxis2_colorbar_title_text = data.border_scale_title,
    )
end

function normalized_color_scale(color_scale::Maybe{AbstractString})::Maybe{AbstractString}
    return color_scale
end

function normalized_color_scale(
    color_scale::AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
)::AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
    return color_scale
end

function normalized_color_scale(
    color_scale::AbstractVector{<:Tuple{<:Real, <:AbstractString}},
)::AbstractVector{<:Tuple{<:Real, <:AbstractString}}
    cmin = lowest_color_scale(color_scale)
    cmax = highest_color_scale(color_scale)
    return [((value - cmin) / (cmax - cmin), color) for (value, color) in color_scale]
end

function lowest_color_scale(
    ::Maybe{Union{AbstractString, AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}}},
)::Nothing
    return nothing
end

function lowest_color_scale(color_scale::AbstractVector{<:Tuple{<:Real, <:AbstractString}})::Real
    return minimum([value for (value, _) in color_scale])
end

function highest_color_scale(
    ::Maybe{Union{AbstractString, AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}}},
)::Nothing
    return nothing
end

function highest_color_scale(color_scale::AbstractVector{<:Tuple{<:Real, <:AbstractString}})::Real
    return maximum([value for (value, _) in color_scale])
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
