"""
Render interactive or static graphs.

This provides a selection of basic graph types needed for metacells visualization. For each one, we define a `struct`
containing all the data for the graph, and a separate `struct` containing the configuration of the graph. The rendering
function takes both and either returns a JavaScript blob needed to create the interactive graph, or writes the graph to
a file.

TODO:

  - Sizes legends.
  - Heatmaps.
  - Heatmap subplots as annotations for bar graph.
  - Heatmap subplots as annotations for heatmaps.
"""
module Renderers

export AbstractGraphConfiguration
export AbstractGraphData
export AxisConfiguration
export BandConfiguration
export BandsConfiguration
export BarGraph
export BarGraphConfiguration
export BarGraphData
export BarsGraph
export BarsGraphConfiguration
export BarsGraphData
export CdfDirection
export CdfDownToValue
export CdfGraph
export CdfGraphConfiguration
export CdfGraphData
export CdfUpToValue
export CdfsGraph
export CdfsGraphConfiguration
export CdfsGraphData
export DistributionConfiguration
export DistributionGraph
export DistributionGraphConfiguration
export DistributionGraphData
export DistributionsGraph
export DistributionsGraphConfiguration
export DistributionsGraphData
export Graph
export GraphConfiguration
export GraphNormalization
export GridGraph
export GridGraphConfiguration
export GridGraphData
export HorizontalValues
export LineConfiguration
export LineGraph
export LineGraphConfiguration
export LineGraphData
export LinesGraph
export LinesGraphConfiguration
export LinesGraphData
export NormalizeToFractions
export NormalizeToPercents
export NormalizeToValues
export PlotlyFigure
export PointsConfiguration
export PointsGraph
export PointsGraphConfiguration
export PointsGraphData
export SizeRangeConfiguration
export ValuesOrientation
export VerticalValues
export graph_to_figure
export save_graph

using ..Validations

using Base.Multimedia
using Colors
using Daf.GenericTypes
using PlotlyJS

import PlotlyJS.SyncPlot
import REPL

"""
The type of a rendered graph which Julia knows how to display. See [`graph_to_figure`](@ref).

A plotly figure contains everything needed to display an interactive graph (or generate a static one on disk). It can also be
converted to a JSON string for handing it over to a different programming language (e.g., to be used to display the
interactive graph in a Python Jupyter notebook, given an appropriate wrapper code).
"""
PlotlyFigure = Union{Plot, SyncPlot}

"""
Common abstract base for all complete graph configuration types. See [`Graph`](@ref).
"""
abstract type AbstractGraphConfiguration <: ObjectWithValidation end

"""
Common abstract base for all complete graph data types. See [`Graph`](@ref).
"""
abstract type AbstractGraphData <: ObjectWithValidation end

"""
The type of a figure we can display. This is a combination of some [`AbstractGraphData`](@ref) and
[`AbstractGraphConfiguration`](@ref), which we can pass to [`graph_to_figure`](@ref) to obtain a [`PlotlyFigure`](@ref)
which Julia knows how to display for us.

You can `display` the `Graph` inside interactive environments (Julia REPL and/or Jupyter notebooks), and/or use
`save_graph` to write it to a file.

The valid combinations of concrete data and configuration which we can render are:

| [`AbstractGraphData`](@ref)      | [`AbstractGraphConfiguration`](@ref)      | Description                                          |
|:-------------------------------- |:----------------------------------------- |:---------------------------------------------------- |
| [`PointsGraphData`](@ref)        | [`PointsGraphConfiguration`](@ref)        | Graph of points, possibly with edges between them.   |
| [`GridGraphData`](@ref)          | [`GridGraphConfiguration`](@ref)          | Graph of a grid of points (e.g. for correlations).   |
| [`LineGraphData`](@ref)          | [`LineGraphConfiguration`](@ref)          | Graph of a single line (e.g. a function y=f(x)).     |
| [`LinesGraphData`](@ref)         | [`LinesGraphConfiguration`](@ref)         | Graph of multiple functions, possibly stacked.       |
| [`CdfGraphData`](@ref)           | [`CdfGraphConfiguration`](@ref)           | Graph of a single cumulative distribution function.  |
| [`CdfsGraphData`](@ref)          | [`CdfsGraphConfiguration`](@ref)          | Graph of multiple cumulative distribution functions. |
| [`DistributionGraphData`](@ref)  | [`DistributionGraphConfiguration`](@ref)  | Graph of a single distribution.                      |
| [`DistributionsGraphData`](@ref) | [`DistributionsGraphConfiguration`](@ref) | Graph of multiple distributions.                     |
| [`BarGraphData`](@ref)           | [`BarGraphConfiguration`](@ref)           | Graph of a single set of bars (histogram).           |
| [`BarsGraphData`](@ref)          | [`BarsGraphConfiguration`](@ref)          | Graph of multiple sets of bars (histograms).         |
"""
@kwdef mutable struct Graph{D, C} <:  # NOJET
                      ObjectWithValidation where {D <: AbstractGraphData, C <: AbstractGraphConfiguration}
    data::D = D()
    configuration::C = C()
end

function Validations.validate_object(graph::Graph)::Maybe{AbstractString}
    message = validate_object(graph.data)
    if message === nothing
        message = validate_object(graph.configuration)
    end
    if message === nothing
        message = validate_graph(graph)
    end
    return message
end

function validate_graph(::Graph)::Maybe{AbstractString}
    return nothing
end

"""
    save_graph(graph::Graph, output_file::AbstractString)::Nothing

Save the graph to a file. Unlike the Plotly `savefig` function, this function will actually obey the `width` and
`height` parameters specified in the graph's configuration. The format is deduced from the suffix of the file name.
"""
function save_graph(graph::Graph, output_file::AbstractString)::Nothing
    savefig(  # NOJET
        graph_to_figure(graph),
        output_file;
        width = graph.configuration.graph.width,
        height = graph.configuration.graph.height,
    )
    return nothing
end

"""
    graph_to_figure(graph::Graph)::PlotlyFigure

Render a graph given its data and configuration. Technically this just converts the graph to a [`PlotlyFigure`](@ref)
which Julia knows how display for us, rather than actually display the graph. The implementation depends on the specific
graph type.

!!! note

    When saving a figure to a file, Plotly in its infinite wisdom ignores the graph `width` and `height` specified
    inside the figure, (except for saving HTML file). You should therefore use [`save_graph`](@ref) rather than call
    `savefig` on the result of `graph_to_figure`.
"""
function graph_to_figure end

function Base.Multimedia.display(graph::Graph)::Any  # untested
    return Base.Multimedia.display(graph_to_figure(graph))  # NOLINT
end

function Base.Multimedia.display(mime::AbstractString, graph::Graph)::Any  # untested
    return Base.Multimedia.display(mime, graph_to_figure(graph))  # NOLINT
end

function Base.Multimedia.display(on_display::AbstractDisplay, graph::Graph)::Any  # untested
    return Base.Multimedia.display(on_display, graph_to_figure(graph))  # NOLINT
end

function Base.Multimedia.display(on_display::TextDisplay, graph::Graph)::Any  # untested
    return Base.Multimedia.display(on_display, graph_to_figure(graph))  # NOLINT
end

function Base.Multimedia.display(on_display::REPL.REPLDisplay, graph::Graph)::Any  # untested
    return Base.Multimedia.display(on_display, graph_to_figure(graph))  # NOLINT
end

function Base.Multimedia.display(on_display::AbstractDisplay, mime::AbstractString, graph::Graph)::Any  # untested
    return Base.Multimedia.display(on_display, mime, graph_to_figure(graph))  # NOLINT
end

"""
The orientation of the values axis in a distribution or bars graph:

`HorizontalValues` - The values are the X axis

`VerticalValues` - The values are the Y axis (the default).
"""
@enum ValuesOrientation HorizontalValues VerticalValues

"""
    @kwdef mutable struct GraphConfiguration
        width::Maybe{Int} = nothing
        height::Maybe{Int} = nothing
        template::AbstractString = "simple_white"
        show_grid::Bool = true
        show_ticks::Bool = true
    end

Generic configuration that applies to any graph. Each complete [`AbstractGraphConfiguration`](@ref) contains a `graph`
field of this type.

The optional `width` and `height` are in pixels, that is, 1/96 of an inch.

By default, `show_grid` and `show_ticks` are set.

The default `template` is "simple_white" which is the cleanest. The `show_grid` and `show_ticks` can be used to disable
the grid and/or ticks for an even cleaner (but less informative) look.
"""
@kwdef mutable struct GraphConfiguration
    width::Maybe{Int} = nothing
    height::Maybe{Int} = nothing
    template::AbstractString = "simple_white"
    show_grid::Bool = true
    show_ticks::Bool = true
end

function validate_graph_configuration(graph_configuration::GraphConfiguration)::Maybe{AbstractString}
    width = graph_configuration.width
    if width !== nothing && width <= 0
        return "non-positive configuration.graph.width: $(width)"
    end

    height = graph_configuration.height
    if height !== nothing && height <= 0
        return "non-positive configuration.graph.height: $(height)"
    end

    return nothing
end

"""
    @kwdef mutable struct AxisConfiguration
        minimum::Maybe{Real} = nothing
        maximum::Maybe{Real} = nothing
        log_regularization::Maybe{AbstractFloat} = nothing,
    end

Generic configuration for a graph axis. Everything is optional; by default, the `minimum` and `maximum` are computed
automatically from the data.

If `log_regularization` is set, it is added to the coordinate to avoid zero values, and the axis is shown in log (base
10) scale. To help with finer-grained ratios, each 10x step is broken to three ~2.15 steps (which is "close enough" to
2x for intuitive reading of the ratios).
"""
@kwdef mutable struct AxisConfiguration
    minimum::Maybe{Real} = nothing
    maximum::Maybe{Real} = nothing
    log_regularization::Maybe{AbstractFloat} = nothing
end

function validate_axis_configuration(
    of_what::AbstractString,
    of_which::AbstractString,
    axis_configuration::AxisConfiguration,
)::Maybe{AbstractString}
    minimum = axis_configuration.minimum
    maximum = axis_configuration.maximum

    if minimum !== nothing && maximum !== nothing && maximum <= minimum
        return "configuration.$(of_what)$(of_which).maximum: $(maximum)\n" *
               "is not larger than configuration.$(of_what)$(of_which).minimum: $(minimum)"
    end

    log_regularization = axis_configuration.log_regularization
    if log_regularization !== nothing
        if log_regularization < 0
            return "negative configuration.$(of_what)$(of_which).log_regularization: $(log_regularization)"
        end

        if minimum !== nothing && minimum + log_regularization <= 0
            return "log of non-positive configuration.$(of_what)$(of_which).minimum: $(minimum + log_regularization)"
        end

        if maximum !== nothing && maximum + log_regularization <= 0
            return "log of non-positive configuration.$(of_what)$(of_which).maximum: $(maximum + log_regularization)"
        end
    end

    return nothing
end

"""
    @kwdef mutable struct DistributionConfiguration
        values_orientation::ValuesOrientation = VerticalValues
        show_box::Bool = true
        show_violin::Bool = false
        show_curve::Bool = false
        show_outliers::Bool = false
        color::Maybe{AbstractString} = nothing
    end

Configure the style of a distribution graph.

The `values_orientation` controls which axis is used for the values (the other axis is used for the density). By default
the values are shown on the Y axis (vertical values).

If `show_box`, show a box graph.

If `show_violin`, show a violin graph.

If `show_curve`, show a density curve.

You can combine the above; however, a density curve is just the positive side of a violin graph, so you can't combine
the two.

In addition to the (combination) of the above, if `show_outliers`, also show the extreme (outlier) points.

The `color` is chosen automatically by default. When showing multiple distributions, you can override it per each one in
the [`DistributionsGraphData`](@ref).
"""
@kwdef mutable struct DistributionConfiguration
    values_orientation::ValuesOrientation = VerticalValues
    show_box::Bool = true
    show_violin::Bool = false
    show_curve::Bool = false
    show_outliers::Bool = false
    color::Maybe{AbstractString} = nothing
end

function validate_distribution_configuration(
    distribution_configuration::DistributionConfiguration,
)::Maybe{AbstractString}
    if !distribution_configuration.show_box &&
       !distribution_configuration.show_violin &&
       !distribution_configuration.show_curve
        return "must specify at least one of: configuration.distribution.show_box, configuration.distribution.show_violin, configuration.distribution.show_curve"
    end

    if distribution_configuration.show_violin && distribution_configuration.show_curve
        return "must not specify both of: configuration.distribution.show_violin, configuration.distribution.show_curve"
    end

    return validate_color("configuration.distribution.color", distribution_configuration.color)
end

function validate_color(what::AbstractString, color::Maybe{AbstractString})::Maybe{AbstractString}
    if is_valid_color(color)
        return nothing
    else
        return "invalid $(what): $(color)"
    end
end

function is_valid_color(::Nothing)::Bool
    return true
end

function is_valid_color(color::AbstractString)::Bool
    try
        parse(Colorant, color)  # NOJET
        return true
    catch
        return false
    end
end

"""
    @kwdef mutable struct DistributionGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        distribution::DistributionConfiguration = DistributionConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
    end

Configure a graph for showing a distribution (with [`DistributionGraphData`](@ref)) or several distributions (with
[`DistributionsGraphData`](@ref)).

The optional `color` will be chosen automatically if not specified. When showing multiple distributions, it is also
possible to specify the color of each one in the [`DistributionsGraphData`](@ref).
"""
@kwdef mutable struct DistributionGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    distribution::DistributionConfiguration = DistributionConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
end

function Validations.validate_object(configuration::DistributionGraphConfiguration)::Maybe{AbstractString}
    message = validate_graph_configuration(configuration.graph)
    if message === nothing
        message = validate_distribution_configuration(configuration.distribution)
    end
    if message === nothing
        message = validate_axis_configuration("value", "_axis", configuration.value_axis)
    end
    return message
end

"""
    @kwdef mutable struct DistributionsGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        distribution::DistributionConfiguration = DistributionConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        show_legend::Bool = false
        distributions_gap::Maybe{Real} = nothing
        overlay_distributions::Bool = false
    end

Configure a graph for showing several distributions several distributions.

This is identical to [`DistributionGraphConfiguration`](@ref) with the addition of `show_legend` to show a legend. This
is not set by default as it makes little sense unless `overlay_distributions` is also set. The `distributions_gap` is
the fraction of white space between the distributions.

!!! note

    Specifying a `distributions_gap` will end badly if using `show_curve` because Plotly.
"""
@kwdef mutable struct DistributionsGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    distribution::DistributionConfiguration = DistributionConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    show_legend::Bool = false
    distributions_gap::Maybe{Real} = nothing
    overlay_distributions::Bool = false
end

function Validations.validate_object(configuration::DistributionsGraphConfiguration)::Maybe{AbstractString}
    message = validate_graph_configuration(configuration.graph)
    if message === nothing
        message = validate_distribution_configuration(configuration.distribution)
    end
    if message === nothing
        message = validate_axis_configuration("value", "_axis", configuration.value_axis)
    end
    if message === nothing
        distributions_gap = configuration.distributions_gap
        if distributions_gap !== nothing
            if distributions_gap < 0
                message = "non-positive configuration.distributions_gap: $(distributions_gap)"
            elseif distributions_gap >= 1
                message = "too-large configuration.distributions_gap: $(distributions_gap)"
            end
        end
    end
    return message
end

"""
    @kwdef mutable struct DistributionGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        trace_axis_title::Maybe{AbstractString} = nothing
        distribution_values::AbstractVector{<:Real} = Float32[]
        distribution_name::Maybe{AbstractString} = nothing
    end

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title` and
the `trace_axis_title`. The optional `distribution_name` is used as the tick value for the distribution.
"""
@kwdef mutable struct DistributionGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    trace_axis_title::Maybe{AbstractString} = nothing
    distribution_values::AbstractVector{<:Real} = Float32[]
    distribution_name::Maybe{AbstractString} = nothing
end

function Validations.validate_object(data::DistributionGraphData)::Maybe{AbstractString}
    if length(data.distribution_values) == 0
        return "empty data.distribution_values vector"
    end

    return nothing
end

"""
    @kwdef mutable struct DistributionsGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        trace_axis_title::Maybe{AbstractString} = nothing
        legend_title::Maybe{AbstractString} = nothing
        distributions_values::AbstractVector{AbstractVector{<:Real}} = Vector{Float32}[]
        distributions_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        distributions_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
    end

The data for a multiple distributions graph. By default, all the titles are empty. You can specify the overall
`graph_title` as well as the `value_axis_title`, the `trace_axis_title` and the `legend_title` (if `show_legend` is
set). If specified, the `distributions_names` and/or the `distributions_colors` vectors must contain the same number of
elements as the number of vectors in the `distributions_values`.
"""
@kwdef mutable struct DistributionsGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    trace_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    distributions_values::AbstractVector{AbstractVector{<:Real}} = Vector{Float32}[]
    distributions_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    distributions_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
end

function Validations.validate_object(data::DistributionsGraphData)::Maybe{AbstractString}
    n_distributions = length(data.distributions_values)
    if n_distributions == 0
        return "empty data.distributions_values vector"
    end

    for (index, distribution_values) in enumerate(data.distributions_values)
        if length(distribution_values) == 0
            return "empty data.distributions_values[$(index)] vector"
        end
    end

    names = data.distributions_names
    if names !== nothing && length(names) != n_distributions
        return "the data.distributions_names size: $(length(names))\n" *
               "is different from the data.distributions_values size: $(n_distributions)"
    end

    colors = data.distributions_colors
    if colors !== nothing
        if length(colors) != n_distributions
            return "the data.distributions_colors size: $(length(colors))\n" *
                   "is different from the data.distributions_values size: $(n_distributions)"
        end
        for (color_index, color) in enumerate(colors)
            if !is_valid_color(color)
                return "invalid data.distributions_colors[$(color_index)]: $(color)"
            end
        end
    end

    return nothing
end

"""
A graph for visualizing a single distribution. See [`DistributionGraphData`](@ref) and
[`DistributionGraphConfiguration`](@ref).
"""
DistributionGraph = Graph{DistributionGraphData, DistributionGraphConfiguration}

"""
A graph for visualizing multiple distributions. See [`DistributionsGraphData`](@ref) and
[`DistributionsGraphConfiguration`](@ref).
"""
DistributionsGraph = Graph{DistributionsGraphData, DistributionsGraphConfiguration}

const BOX = 1
const VIOLIN = 2
const CURVE = 4

function graph_to_figure(graph::DistributionGraph)::PlotlyFigure
    assert_valid_object(graph)

    trace = distribution_trace(;  # NOJET
        distribution_values = graph.data.distribution_values,
        distribution_name = graph.data.distribution_name === nothing ? "Trace" : graph.data.distribution_name,
        color = graph.configuration.distribution.color,
        legend_title = nothing,
        configuration = graph.configuration,
        overlay_distributions = false,
    )

    layout = distribution_layout(;
        graph = graph,
        has_tick_names = graph.data.distribution_name !== nothing,
        show_legend = false,
        distributions_gap = nothing,
    )

    return plot(trace, layout)
end

function graph_to_figure(graph::DistributionsGraph)::PlotlyFigure
    assert_valid_object(graph)

    if graph.configuration.distributions_gap !== nothing && graph.configuration.distribution.show_curve
        @warn "setting the distributions_gap for curve is buggy in plotly"
    end

    n_distributions = length(graph.data.distributions_values)
    traces = [
        distribution_trace(;
            distribution_values = graph.data.distributions_values[index],
            distribution_name = if graph.data.distributions_names === nothing
                "Trace $(index)"
            else
                graph.data.distributions_names[index]
            end,
            color = if graph.data.distributions_colors === nothing
                graph.configuration.distribution.color
            else
                graph.data.distributions_colors[index]
            end,
            legend_title = graph.data.legend_title,
            configuration = graph.configuration,
            overlay_distributions = graph.configuration.overlay_distributions,
            is_first = index == 1,
        ) for index in 1:n_distributions
    ]

    layout = distribution_layout(;
        graph = graph,
        has_tick_names = graph.data.distributions_names !== nothing,
        show_legend = graph.configuration.show_legend,
        distributions_gap = graph.configuration.distributions_gap,
    )

    return plot(traces, layout)
end

function distribution_trace(;
    distribution_values::AbstractVector{<:Real},
    distribution_name::AbstractString,
    color::Maybe{AbstractString},
    legend_title::Maybe{AbstractString},
    configuration::Union{DistributionGraphConfiguration, DistributionsGraphConfiguration},
    overlay_distributions::Bool,
    is_first::Bool = true,
)::GenericTrace
    style = (
        (configuration.distribution.show_box ? BOX : 0) |
        (configuration.distribution.show_violin ? VIOLIN : 0) |
        (configuration.distribution.show_curve ? CURVE : 0)
    )

    if configuration.distribution.values_orientation == VerticalValues
        x = nothing
        y = distribution_values
        x0 = overlay_distributions ? " " : nothing
        y0 = nothing
    elseif configuration.distribution.values_orientation == HorizontalValues
        x = distribution_values
        y = nothing
        x0 = nothing
        y0 = overlay_distributions ? " " : nothing
    else
        @assert false
    end

    points = configuration.distribution.show_outliers ? "outliers" : false
    tracer = style == BOX ? box : violin

    return tracer(;
        x = x,
        y = y,
        x0 = x0,
        y0 = y0,
        side = configuration.distribution.show_curve ? "positive" : nothing,
        box_visible = configuration.distribution.show_box,
        boxpoints = points,
        points = points,
        name = distribution_name,
        marker_color = color,
        legendgroup = distribution_name,
        legendgrouptitle_text = is_first ? legend_title : nothing,
    )
end

function distribution_layout(;
    graph::Union{DistributionGraph, DistributionsGraph},
    has_tick_names::Bool,
    show_legend::Bool,
    distributions_gap::Maybe{Real},
)::Layout
    if graph.configuration.distribution.values_orientation == VerticalValues
        xaxis_showticklabels = has_tick_names
        xaxis_showgrid = false
        xaxis_title = graph.data.trace_axis_title
        xaxis_range = (nothing, nothing)
        xaxis_type = nothing
        yaxis_showticklabels = graph.configuration.graph.show_ticks
        yaxis_showgrid = graph.configuration.graph.show_grid
        yaxis_title = graph.data.value_axis_title
        yaxis_range = (graph.configuration.value_axis.minimum, graph.configuration.value_axis.maximum)
        yaxis_type = graph.configuration.value_axis.log_regularization !== nothing ? "log" : nothing
    elseif graph.configuration.distribution.values_orientation == HorizontalValues
        xaxis_showticklabels = graph.configuration.graph.show_ticks
        xaxis_showgrid = graph.configuration.graph.show_grid
        xaxis_title = graph.data.value_axis_title
        xaxis_range = (graph.configuration.value_axis.minimum, graph.configuration.value_axis.maximum)
        xaxis_type = graph.configuration.value_axis.log_regularization !== nothing ? "log" : nothing
        yaxis_showticklabels = has_tick_names
        yaxis_showgrid = false
        yaxis_title = graph.data.trace_axis_title
        yaxis_range = (nothing, nothing)
        yaxis_type = nothing
    else
        @assert false
    end

    return graph_layout(
        graph.configuration.graph,
        Layout(;  # NOJET
            title = graph.data.graph_title,
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
            legend_tracegroupgap = 0,
            legend_itemdoubleclick = false,
            violingroupgap = distributions_gap === nothing ? nothing : 0,
            boxgroupgap = distributions_gap === nothing ? nothing : 0,
            boxgap = distributions_gap,
            violingap = distributions_gap,
        ),
    )
end

"""
    @kwdef mutable struct LineConfiguration
        width::Maybe{Real} = 1
        is_filled::Bool = false
        is_dashed::Bool = false
        color::Maybe{AbstractString} = nothing
    end

Configure a line in a graph.

By default, a solid line is shown; if `is_dashed`, the line will be dashed. If `is_filled` is set, the area below the
line is filled. If the `width` is set to `nothing`, no line is shown (and `is_filled` must be set). By default, the
`color` is chosen automatically.
"""
@kwdef mutable struct LineConfiguration
    width::Maybe{Real} = 1
    is_filled::Bool = false
    is_dashed::Bool = false
    color::Maybe{AbstractString} = nothing
end

function validate_line_configuration(line_configuration::LineConfiguration)::Maybe{AbstractString}
    width = line_configuration.width
    if width !== nothing && width <= 0
        return "non-positive configuration.line.width: $(width)"
    end
    if width === nothing && !line_configuration.is_filled
        return "either configuration.line.width or configuration.line.is_filled must be specified"
    end
    return validate_color("configuration.line.color", line_configuration.color)
end

"""
    @kwdef mutable struct BandConfiguration
        offset::Maybe{Real} = nothing
        color::Maybe{AbstractString} = nothing
        width::Maybe{Real} = 1.0
        is_dashed::Bool = false
        is_filled::Bool = false
    end

Configure a region of the graph defined by some band of values. This is the same as a `LineConfiguration` (for
controlling the style of the line drawn for the band) with the addition of the `offset` of the line's position. We allow
up to three bands in a complete [`BandsConfiguration`](@ref). The low and high bands are defined as below and above
their line's `offset`, and do not exist if the `offset` is not specified. The middle band is defined to be between these
two lines (and therefore only exists if both are specified). Its `offset` defined a center line, if one is to be
displayed, and is therefore optional.
"""
@kwdef mutable struct BandConfiguration
    offset::Maybe{Real} = nothing
    color::Maybe{AbstractString} = nothing
    width::Maybe{Real} = 1.0
    is_dashed::Bool = false
    is_filled::Bool = false
end

function validate_band_configuration(
    of_what::AbstractString,
    of_which::AbstractString,
    band_configuration::BandConfiguration,
    log_scale::Bool,
)::Maybe{AbstractString}
    if band_configuration.width !== nothing && band_configuration.width <= 0
        return "non-positive configuration.$(of_what).$(of_which).width: $(band_configuration.width)"
    end
    if log_scale && band_configuration.offset !== nothing && band_configuration.offset <= 0
        return "log of non-positive configuration.$(of_what).$(of_which).offset: $(band_configuration.offset)"
    end
    if !is_valid_color(band_configuration.color)
        return "invalid configuration.$(of_what).$(of_which).color: $(band_configuration.color)"
    end
    return nothing
end

"""
    @kwdef mutable struct BandsConfiguration
        low::BandConfiguration = BandConfiguration(is_dashed = true)
        middle::BandConfiguration = BandConfiguration()
        high::BandConfiguration = BandConfiguration(is_dashed = true)
        show_legend::Bool = false
    end

Configure the partition of the graph up to three band regions. The `low` and `high` bands are for the "outer" regions
(so their lines are at their border, dashed by default) and the `middle` band is for the "inner" region between them (so
its line is inside it, solid by default).

If `show_legend`, then a legend showing the bands will be shown.
"""
@kwdef mutable struct BandsConfiguration
    low::BandConfiguration = BandConfiguration(; is_dashed = true)
    middle::BandConfiguration = BandConfiguration()
    high::BandConfiguration = BandConfiguration(; is_dashed = true)
    show_legend::Bool = false
end

function validate_bands_configuration(
    of_what::AbstractString,
    bands_configuration::BandsConfiguration,
    log_scale::Bool,
)::Maybe{AbstractString}
    message = validate_band_configuration(of_what, "low", bands_configuration.low, log_scale)
    if message === nothing
        message = validate_band_configuration(of_what, "middle", bands_configuration.middle, log_scale)
    end
    if message === nothing
        message = validate_band_configuration(of_what, "high", bands_configuration.high, log_scale)
    end
    if message !== nothing
        return message
    end

    low_line_offset = bands_configuration.low.offset
    middle_line_offset = bands_configuration.middle.offset
    high_line_offset = bands_configuration.high.offset

    if low_line_offset !== nothing && middle_line_offset !== nothing && low_line_offset >= middle_line_offset
        return "configuration.$(of_what).low.offset: $(low_line_offset)\n" *
               "is not less than configuration.$(of_what).middle.offset: $(low_line_offset)"
    end

    if middle_line_offset !== nothing && high_line_offset !== nothing && middle_line_offset >= high_line_offset
        return "configuration.$(of_what).high.offset: $(high_line_offset)\n" *
               "is not greater than configuration.$(of_what).middle.offset: $(middle_line_offset)"
    end

    if low_line_offset !== nothing && high_line_offset !== nothing && low_line_offset >= high_line_offset
        return "configuration.$(of_what).low.offset: $(low_line_offset)\n" *
               "is not less than configuration.$(of_what).high.offset: $(high_line_offset)"
    end

    return nothing
end

"""
    @kwdef mutable struct BandsData
        legend_title::Maybe{AbstractString} = nothing
        low_title::Maybe{AbstractString} = nothing
        middle_title::Maybe{AbstractString} = nothing
        high_title::Maybe{AbstractString} = nothing
    end

Legend titles for a set of bands.
"""
@kwdef mutable struct BandsData
    legend_title::Maybe{AbstractString} = nothing
    low_title::Maybe{AbstractString} = nothing
    middle_title::Maybe{AbstractString} = nothing
    high_title::Maybe{AbstractString} = nothing
end

"""
    @kwdef mutable struct LineGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        line::LineConfiguration = LineConfiguration()
        vertical_bands::BandsConfiguration = BandsConfiguration()
        horizontal_bands::BandsConfiguration = BandsConfiguration()
    end

Configure a graph for showing line plots.
"""
@kwdef mutable struct LineGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    line::LineConfiguration = LineConfiguration()
    vertical_bands::BandsConfiguration = BandsConfiguration()
    horizontal_bands::BandsConfiguration = BandsConfiguration()
end

"""
    @kwdef mutable struct LineGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        vertical_bands::BandsData = BandsData()
        horizontal_bands::BandsData = BandsData()
        points_xs::AbstractVector{<:Real} = Float32[]
        points_ys::AbstractVector{<:Real} = Float32[]
    end

The data for a line graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `x_axis_title` and
`y_axis_title` for the axes.

The `points_xs` and `points_ys` vectors must be of the same size. A line will be drawn through all the points, and the
area under the line may be filled.
"""
@kwdef mutable struct LineGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    vertical_bands::BandsData = BandsData()
    horizontal_bands::BandsData = BandsData()
    points_xs::AbstractVector{<:Real} = Float32[]
    points_ys::AbstractVector{<:Real} = Float32[]
end

function Validations.validate_object(data::LineGraphData)::Maybe{AbstractString}
    if length(data.points_xs) != length(data.points_ys)
        return "the data.points_xs size: $(length(data.points_xs))\n" *
               "is different from the data.points_ys size: $(length(data.points_ys))"
    end
    return nothing
end

"""
A graph for visualizing a single line (typically Y as a function of X). See [`LineGraphData`](@ref) and
[`LineGraphConfiguration`](@ref).
"""
LineGraph = Graph{LineGraphData, LineGraphConfiguration}

function graph_to_figure(graph::LineGraph)::PlotlyFigure
    assert_valid_object(graph)

    traces = Vector{GenericTrace}()

    minimum_x, maximum_x = range_of(;
        values = [graph.data.points_xs],
        log_regularization = graph.configuration.x_axis.log_regularization,
        apply_log = false,
    )
    minimum_y, maximum_y = range_of(;
        values = [graph.data.points_ys],
        log_regularization = graph.configuration.y_axis.log_regularization,
        apply_log = false,
    )

    vertical_legend_title = Maybe{AbstractString}[graph.data.vertical_bands.legend_title]
    horizontal_legend_title = Maybe{AbstractString}[graph.data.horizontal_bands.legend_title]

    (filled_vertical_low, filled_vertical_middle, filled_vertical_high) = push_fill_vertical_bands_traces(;
        traces = traces,
        legend_title = vertical_legend_title,
        bands_data = graph.data.vertical_bands,
        bands_configuration = graph.configuration.vertical_bands,
        minimum_x = minimum_x,
        minimum_y = minimum_y,
        maximum_x = maximum_x,
        maximum_y = maximum_y,
    )
    (filled_horizontal_low, filled_horizontal_middle, filled_horizontal_high) = push_fill_horizontal_bands_traces(;
        traces = traces,
        legend_title = horizontal_legend_title,
        bands_data = graph.data.horizontal_bands,
        bands_configuration = graph.configuration.horizontal_bands,
        minimum_x = minimum_x,
        minimum_y = minimum_y,
        maximum_x = maximum_x,
        maximum_y = maximum_y,
    )

    push!(traces, line_trace(graph.data, graph.configuration.line))

    for (band_configuration, is_filled, name) in (
        (
            graph.configuration.vertical_bands.high,
            filled_vertical_high,
            graph.data.vertical_bands.high_title === nothing ? "right" : graph.data.vertical_bands.high_title,
        ),
        (
            graph.configuration.vertical_bands.middle,
            filled_vertical_middle,
            graph.data.vertical_bands.middle_title === nothing ? "center" : graph.data.vertical_bands.middle_title,
        ),
        (
            graph.configuration.vertical_bands.low,
            filled_vertical_low,
            graph.data.vertical_bands.low_title === nothing ? "left" : graph.data.vertical_bands.low_title,
        ),
    )
        if band_configuration.offset !== nothing && band_configuration.width !== nothing
            push!(
                traces,
                vertical_line_trace(;
                    band_configuration = band_configuration,
                    minimum_y = minimum_y,
                    maximum_y = maximum_y,
                    show_legend = !is_filled && graph.configuration.vertical_bands.show_legend,
                    legend_title = vertical_legend_title,
                    name = name,
                ),
            )
        end
    end

    for (band_configuration, is_filled, name) in (
        (
            graph.configuration.horizontal_bands.high,
            filled_horizontal_high,
            graph.data.horizontal_bands.high_title === nothing ? "high" : graph.data.horizontal_bands.high_title,
        ),
        (
            graph.configuration.horizontal_bands.middle,
            filled_horizontal_middle,
            graph.data.horizontal_bands.middle_title === nothing ? "middle" : graph.data.horizontal_bands.middle_title,
        ),
        (
            graph.configuration.horizontal_bands.low,
            filled_horizontal_low,
            graph.data.horizontal_bands.low_title === nothing ? "low" : graph.data.horizontal_bands.low_title,
        ),
    )
        if band_configuration.offset !== nothing && band_configuration.width !== nothing
            push!(
                traces,
                horizontal_line_trace(;
                    band_configuration = band_configuration,
                    minimum_x = minimum_x,
                    maximum_x = maximum_x,
                    show_legend = !is_filled && graph.configuration.horizontal_bands.show_legend,
                    legend_title = horizontal_legend_title,
                    name = name,
                ),
            )
        end
    end

    layout = lines_layout(;
        graph = graph,
        minimum_x = minimum_x,
        minimum_y = minimum_y,
        maximum_x = maximum_x,
        maximum_y = maximum_y,
        show_legend = graph.configuration.horizontal_bands.show_legend ||
                      graph.configuration.vertical_bands.show_legend,
    )

    return plot(traces, layout)
end

function line_trace(data::LineGraphData, line::LineConfiguration)::GenericTrace
    return scatter(;
        x = data.points_xs,
        y = data.points_ys,
        line_color = line.color,
        line_width = line.width === nothing ? 0 : line.width,
        line_dash = line.is_dashed ? "dash" : nothing,
        fill = line.is_filled ? "tozeroy" : nothing,
        showlegend = false,
        name = "",
        mode = "lines",
    )
end

"""
If normalizing the data of a graphs, how:

`NormalizeToValues` - simply add the values on top of each other.

`NormalizeToFractions` - normalize the added values so their some is 1. The values must not be negative.

`NormalizeToPercents` - normalize the added values so their some is 100 (percent). The values must not be negative.
"""
@enum GraphNormalization NormalizeToValues NormalizeToFractions NormalizeToPercents

"""
    @kwdef mutable struct LinesGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        line::LineConfiguration = LineConfiguration()
        vertical_bands::BandsConfiguration = BandsConfiguration()
        horizontal_bands::BandsConfiguration = BandsConfiguration()
        show_legend::Bool = false
        stacking_normalization::Maybe{GraphNormalization} = nothing
    end

Configure a graph for showing multiple line plots. This allows using `show_legend` to display a legend of the different
lines, and `stacking_normalization` to stack instead of overlay the lines. If `stacking_normalization` is specified,
then `is_filled` is implied, regardless of what its actual setting is.
"""
@kwdef mutable struct LinesGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    line::LineConfiguration = LineConfiguration()
    vertical_bands::BandsConfiguration = BandsConfiguration()
    horizontal_bands::BandsConfiguration = BandsConfiguration()
    show_legend::Bool = false
    stacking_normalization::Maybe{GraphNormalization} = nothing
end

function Validations.validate_object(
    configuration::Union{LineGraphConfiguration, LinesGraphConfiguration},
)::Maybe{AbstractString}
    message = validate_graph_configuration(configuration.graph)
    if message === nothing
        message = validate_axis_configuration("x", "_axis", configuration.x_axis)
    end
    if message === nothing
        message = validate_axis_configuration("y", "_axis", configuration.y_axis)
    end
    if message === nothing
        message = validate_line_configuration(configuration.line)
    end
    if message === nothing
        message = validate_bands_configuration(
            "vertical_bands",
            configuration.vertical_bands,
            configuration.x_axis.log_regularization !== nothing,
        )
    end
    if message === nothing
        message = validate_bands_configuration(
            "horizontal_bands",
            configuration.horizontal_bands,
            configuration.y_axis.log_regularization !== nothing,
        )
    end
    return message
end

"""
    @kwdef mutable struct LinesGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        legend_title::Maybe{AbstractString} = nothing
        vertical_bands::BandsData = BandsData()
        horizontal_bands::BandsData = BandsData()
        lines_xs::AbstractVector{AbstractVector{<:Real}} = Vector{Float32}[]
        lines_ys::AbstractVector{AbstractVector{<:Real}} = Vector{Float32}[]
        lines_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        lines_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
        lines_widths::Maybe{AbstractVector{<:Real}} = nothing
        lines_are_filled::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing
        lines_are_dashed::Maybe{AbstractVector{Bool}} = nothing
    end

The data for multiple lines graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `x_axis_title` and
`y_axis_title` for the axes.

The `lines_xs` and `lines_ys` vectors must be of the same size (one per line). For each line, its points `xs` and `ys`
coordinate arrays must also be of the same size; a line will be drawn through all the points, and the area under the
line may be filled. If `stack_lines` is specified in [`LinesGraphConfiguration`](@ref), then the lines are specified in
top-to-bottom order.

The `lines_names`, `lines_colors`, `lines_widths`, `lines_are_filled` and `lines_are_dashed` arrays must have the same
number of entries (one per line). The `lines_colors` are restricted to explicit colors; therefore the color scale
options of the `line` must not be used.
"""
@kwdef mutable struct LinesGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    vertical_bands::BandsData = BandsData()
    horizontal_bands::BandsData = BandsData()
    lines_xs::AbstractVector{AbstractVector{<:Real}} = Vector{Float32}[]
    lines_ys::AbstractVector{AbstractVector{<:Real}} = Vector{Float32}[]
    lines_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    lines_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
    lines_widths::Maybe{AbstractVector{<:Real}} = nothing
    lines_are_filled::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing
    lines_are_dashed::Maybe{AbstractVector{Bool}} = nothing
end

function Validations.validate_object(data::LinesGraphData)::Maybe{AbstractString}
    n_lines = length(data.lines_xs)
    if length(data.lines_ys) != n_lines
        return "the data.lines_xs size: $(n_lines)\n" *
               "is different from the data.lines_ys size: $(length(data.lines_ys))"
    end
    if n_lines == 0
        return "empty data.lines_xs and data.lines_ys vectors"
    end

    for (index, (points_xs, points_ys)) in enumerate(zip(data.lines_xs, data.lines_ys))
        if length(points_xs) != length(points_ys)
            return "the data.lines_xs[$(index)] size: $(length(points_xs))\n" *
                   "is different from the data.lines_ys[$(index)] size: $(length(points_ys))"
        end
        if length(points_xs) < 2
            return "too few points in data.lines_xs[$(index)] and data.lines_ys[$(index)]: $(length(points_xs))"
        end
    end

    if data.lines_names !== nothing && length(data.lines_names) != n_lines
        return "the data.lines_names size: $(length(data.lines_names))\n" *
               "is different from the data.lines_xs and data.lines_ys size: $(n_lines)"
    end

    colors = data.lines_colors
    if colors !== nothing
        if length(colors) != n_lines
            return "the data.lines_colors size: $(length(colors))\n" *
                   "is different from the data.lines_xs and data.lines_ys size: $(n_lines)"
        end
        for (color_index, color) in enumerate(colors)
            if !is_valid_color(color)
                return "invalid data.lines_colors[$(color_index)]: $(color)"
            end
        end
    end

    lines_widths = data.lines_widths
    if lines_widths !== nothing
        if length(lines_widths) != n_lines
            return "the data.lines_widths size: $(length(lines_widths))\n" *
                   "is different from the data.lines_xs and data.lines_ys size: $(n_lines)"
        end
        for (index, line_width) in enumerate(lines_widths)
            if line_width <= 0
                return "non-positive data.lines_widths[$(index)]: $(line_width)"
            end
        end
    end

    if data.lines_are_filled !== nothing && length(data.lines_are_filled) != n_lines
        return "the data.lines_are_filled size: $(length(data.lines_are_filled))\n" *
               "is different from the data.lines_xs and data.lines_ys size: $(n_lines)"
    end

    if data.lines_are_dashed !== nothing && length(data.lines_are_dashed) != n_lines
        return "the data.lines_are_dashed size: $(length(data.lines_are_dashed))\n" *
               "is different from the data.lines_xs and data.lines_ys size: $(n_lines)"
    end

    return nothing
end

"""
A graph visualizing multiple lines (typically Ys as functions of the same X). See [`LinesGraphData`](@ref) and
[`LinesGraphConfiguration`](@ref).
"""
LinesGraph = Graph{LinesGraphData, LinesGraphConfiguration}

function graph_to_figure(graph::LinesGraph)::PlotlyFigure
    assert_valid_object(graph)

    if graph.configuration.stacking_normalization == NormalizeToPercents ||
       graph.configuration.stacking_normalization == NormalizeToFractions
        for (line_index, points_ys) in enumerate(graph.data.lines_ys)
            for (point_index, point_y) in enumerate(points_ys)
                @assert point_y >= 0 "negative stacked fraction/percent data.lines_ys[$(line_index),$(point_index)]: $(point_y)"
            end
        end
    end

    if graph.configuration.stacking_normalization === nothing
        lines_xs = graph.data.lines_xs
        lines_ys = graph.data.lines_ys
    else
        lines_xs, lines_ys, maximum_y = unify_xs(graph.data.lines_xs, graph.data.lines_ys)
    end

    traces = Vector{GenericTrace}()

    minimum_x, maximum_x = range_of(;
        values = lines_xs,
        log_regularization = graph.configuration.x_axis.log_regularization,
        apply_log = false,
    )

    if graph.configuration.stacking_normalization == NormalizeToFractions
        minimum_y, maximum_y = -0.05, 1.05
    elseif graph.configuration.stacking_normalization == NormalizeToPercents
        minimum_y, maximum_y = -5.0, 105.0
    elseif graph.configuration.stacking_normalization == NormalizeToValues
        minimum_y = maximum_x * -0.05 / 1.05
    else
        minimum_y, maximum_y = range_of(;
            values = lines_ys,
            log_regularization = graph.configuration.y_axis.log_regularization,
            apply_log = false,
        )
    end

    vertical_legend_title = Maybe{AbstractString}[graph.data.vertical_bands.legend_title]
    horizontal_legend_title = Maybe{AbstractString}[graph.data.horizontal_bands.legend_title]

    (filled_vertical_low, filled_vertical_middle, filled_vertical_high) = push_fill_vertical_bands_traces(;
        traces = traces,
        legend_title = vertical_legend_title,
        bands_data = graph.data.vertical_bands,
        bands_configuration = graph.configuration.vertical_bands,
        minimum_x = minimum_x,
        minimum_y = minimum_y,
        maximum_x = maximum_x,
        maximum_y = maximum_y,
    )
    (filled_horizontal_low, filled_horizontal_middle, filled_horizontal_high) = push_fill_horizontal_bands_traces(;
        traces = traces,
        legend_title = horizontal_legend_title,
        bands_data = graph.data.horizontal_bands,
        bands_configuration = graph.configuration.horizontal_bands,
        minimum_x = minimum_x,
        minimum_y = minimum_y,
        maximum_x = maximum_x,
        maximum_y = maximum_y,
    )

    for index in 1:length(graph.data.lines_xs)
        push!(
            traces,
            lines_trace(;
                graph = graph,
                points_xs = lines_xs[index],
                points_ys = lines_ys[index],
                index = index,
                show_legend = graph.configuration.show_legend,
                legend_title = graph.data.legend_title,
            ),
        )
    end

    for (band_configuration, is_filled, name) in (
        (
            graph.configuration.vertical_bands.high,
            filled_vertical_high,
            graph.data.vertical_bands.high_title === nothing ? "right" : graph.data.vertical_bands.high_title,
        ),
        (
            graph.configuration.vertical_bands.middle,
            filled_vertical_middle,
            graph.data.vertical_bands.middle_title === nothing ? "center" : graph.data.vertical_bands.middle_title,
        ),
        (
            graph.configuration.vertical_bands.low,
            filled_vertical_low,
            graph.data.vertical_bands.low_title === nothing ? "left" : graph.data.vertical_bands.low_title,
        ),
    )
        if band_configuration.offset !== nothing && band_configuration.width !== nothing
            push!(
                traces,
                vertical_line_trace(;
                    band_configuration = band_configuration,
                    minimum_y = minimum_y,
                    maximum_y = maximum_y,
                    show_legend = !is_filled && graph.configuration.vertical_bands.show_legend,
                    legend_title = vertical_legend_title,
                    name = name,
                ),
            )
        end
    end

    for (band_configuration, is_filled, name) in (
        (
            graph.configuration.horizontal_bands.high,
            filled_horizontal_high,
            graph.data.horizontal_bands.high_title === nothing ? "high" : graph.data.horizontal_bands.high_title,
        ),
        (
            graph.configuration.horizontal_bands.middle,
            filled_horizontal_middle,
            graph.data.horizontal_bands.middle_title === nothing ? "middle" : graph.data.horizontal_bands.middle_title,
        ),
        (
            graph.configuration.horizontal_bands.low,
            filled_horizontal_low,
            graph.data.horizontal_bands.low_title === nothing ? "low" : graph.data.horizontal_bands.low_title,
        ),
    )
        if band_configuration.offset !== nothing && band_configuration.width !== nothing
            push!(
                traces,
                horizontal_line_trace(;
                    band_configuration = band_configuration,
                    minimum_x = minimum_x,
                    maximum_x = maximum_x,
                    show_legend = !is_filled && graph.configuration.horizontal_bands.show_legend,
                    legend_title = horizontal_legend_title,
                    name = name,
                ),
            )
        end
    end

    layout = lines_layout(;
        graph = graph,
        minimum_x = minimum_x,
        minimum_y = minimum_y,
        maximum_x = maximum_x,
        maximum_y = maximum_y,
        show_legend = graph.configuration.show_legend ||
                      graph.configuration.vertical_bands.show_legend ||
                      graph.configuration.horizontal_bands.show_legend,
    )

    return plot(traces, layout)
end

function unify_xs(
    lines_xs::AbstractVector{<:AbstractVector{<:Real}},
    lines_ys::AbstractVector{<:AbstractVector{<:Real}},
)::Tuple{Vector{Vector{Float32}}, Vector{Vector{Float32}}, Float32}
    maximum_y = 0
    n_lines = length(lines_xs)
    unified_xs = Vector{Vector{Float32}}()
    unified_ys = Vector{Vector{Float32}}()
    zero_before = zeros(Bool, n_lines)
    zero_after = zeros(Bool, n_lines)
    for _ in 1:n_lines
        push!(unified_xs, Vector{Float32}())
        push!(unified_ys, Vector{Float32}())
    end
    next_point_indices = fill(1, n_lines)
    last_x = nothing
    last_y = nothing
    while true
        unified_x = nothing
        for line_index in 1:n_lines
            point_index = next_point_indices[line_index]
            if point_index <= length(lines_xs[line_index])
                if unified_x === nothing
                    unified_x = lines_xs[line_index][point_index]
                else
                    unified_x = min(unified_x, lines_xs[line_index][point_index])
                end
            end
        end
        if unified_x === nothing
            return (unified_xs, unified_ys, maximum_y * 1.05)
        end
        if unified_x != last_x
            last_x = unified_x
            last_y = 0
        end
        for line_index in 1:n_lines
            point_index = next_point_indices[line_index]
            next_x = lines_xs[line_index][min(point_index, length(lines_xs[line_index]))]
            if unified_x > next_x
                if !zero_after[line_index]
                    push!(unified_xs[line_index], next_x)
                    push!(unified_ys[line_index], 0)
                    zero_after[line_index] = true
                end
                push!(unified_xs[line_index], unified_x)
                push!(unified_ys[line_index], 0)
            else
                next_y = lines_ys[line_index][point_index]
                if unified_x == next_x
                    if zero_before[line_index]
                        push!(unified_xs[line_index], unified_x)
                        push!(unified_ys[line_index], 0)
                        zero_before[line_index] = false
                    end
                    last_y += next_y
                    maximum_y = max(maximum_y, last_y)
                    push!(unified_xs[line_index], next_x)
                    push!(unified_ys[line_index], next_y)
                    next_point_indices[line_index] += 1
                elseif point_index == 1
                    push!(unified_xs[line_index], unified_x)
                    push!(unified_ys[line_index], 0)
                    zero_before[line_index] = true
                else
                    @assert !zero_before[line_index]
                    prev_x = lines_xs[line_index][point_index - 1]
                    prev_y = lines_ys[line_index][point_index - 1]
                    push!(unified_xs[line_index], unified_x)
                    mid_y = prev_y + (next_y - prev_y) * (unified_x - prev_x) / (next_x - prev_x)
                    push!(unified_ys[line_index], mid_y)
                    last_y += mid_y
                    maximum_y = max(maximum_y, last_y)
                end
            end
        end
    end
end

function lines_trace(;
    graph::LinesGraph,
    points_xs::AbstractVector{<:Real},
    points_ys::AbstractVector{<:Real},
    index::Int,
    show_legend::Bool,
    legend_title::Maybe{AbstractString},
)::GenericTrace
    return scatter(;
        x = points_xs,
        y = points_ys,
        line_color = if graph.data.lines_colors !== nothing
            graph.data.lines_colors[index]
        else
            graph.configuration.line.color
        end,
        line_width = if graph.data.lines_widths !== nothing
            graph.data.lines_widths[index]
        elseif graph.configuration.line.width === nothing
            0
        else
            graph.configuration.line.width  # NOJET
        end,
        line_dash = if (
            if graph.data.lines_are_dashed !== nothing
                graph.data.lines_are_dashed[index]
            else
                graph.configuration.line.is_dashed
            end
        )
            "dash"
        else
            nothing
        end,
        fill = if !(
            if graph.data.lines_are_filled !== nothing
                graph.data.lines_are_filled[index]
            else
                graph.configuration.line.is_filled
            end
        )
            nothing
        elseif index == length(graph.data.lines_xs)
            "tozeroy"
        else
            "tonexty"
        end,
        name = graph.data.lines_names !== nothing ? graph.data.lines_names[index] : "Trace $(index)",
        stackgroup = graph.configuration.stacking_normalization === nothing ? nothing : "stacked",
        groupnorm = if graph.configuration.stacking_normalization == NormalizeToFractions
            "fraction"
        elseif graph.configuration.stacking_normalization == NormalizeToPercents
            "percent"
        else
            nothing
        end,
        showlegend = show_legend,
        legendgroup = "lines$(index)",
        legendgrouptitle_text = index == 1 ? legend_title : nothing,
        mode = "lines",
    )
end

function lines_layout(;
    graph::Union{LineGraph, LinesGraph},
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
    show_legend::Bool,
)::Layout
    x_axis = graph.configuration.x_axis
    y_axis = graph.configuration.y_axis

    return graph_layout(
        graph.configuration.graph,
        Layout(;  # NOJET
            title = graph.data.graph_title,
            xaxis_showgrid = graph.configuration.graph.show_grid,
            xaxis_showticklabels = graph.configuration.graph.show_ticks,
            xaxis_title = graph.data.x_axis_title,
            xaxis_range = (
                x_axis.minimum !== nothing ? x_axis.minimum : minimum_x,
                x_axis.maximum !== nothing ? x_axis.maximum : maximum_x,
            ),
            xaxis_type = x_axis.log_regularization !== nothing ? "log" : nothing,
            yaxis_showgrid = graph.configuration.graph.show_grid,
            yaxis_showticklabels = graph.configuration.graph.show_ticks,
            yaxis_title = graph.data.y_axis_title,
            yaxis_range = (
                y_axis.minimum !== nothing ? y_axis.minimum : minimum_y,
                y_axis.maximum !== nothing ? y_axis.maximum : maximum_y,
            ),
            yaxis_type = y_axis.log_regularization !== nothing ? "log" : nothing,
            showlegend = show_legend,
            legend_tracegroupgap = 0,
            legend_itemdoubleclick = false,
        ),
    )
end

"""
The direction of the CDF graph:

`CdfUpToValue` - Show the fraction of values up to each value.

`CdfDownToValue` - Show the fraction of values down to each value.
"""
@enum CdfDirection CdfUpToValue CdfDownToValue

"""
    @kwdef mutable struct CdfGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        fraction_axis::AxisConfiguration = AxisConfiguration()
        fractions_normalization::GraphNormalization = NormalizeToFractions,
        line::LineConfiguration = LineConfiguration()
        values_orientation::ValuesOrientation = HorizontalValues
        cdf_direction::CdfDirection = CdfUpToValue
        value_bands::BandsConfiguration = BandsConfiguration()
        fraction_bands::BandsConfiguration = BandsConfiguration()
    end

Configure a graph for showing a CDF (Cumulative Distribution Function) graph. By default, the X axis is used for the
values and the Y axis for the fraction; this can be switched using the `values_orientation`. By default, the fraction is
of the values up to each value; this can be switched using the `cdf_direction`.

The fraction axis is normalized according to `fractions_normalization`. The `fraction_bands` offset is always given as a
fraction between zero and one, to allow for easily switching the axis normalization without worrying about the band
offset.

CDF graphs are internally converted to line graphs for rendering.
"""
@kwdef mutable struct CdfGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    fraction_axis::AxisConfiguration = AxisConfiguration()
    fractions_normalization::GraphNormalization = NormalizeToFractions
    line::LineConfiguration = LineConfiguration()
    values_orientation::ValuesOrientation = HorizontalValues
    cdf_direction::CdfDirection = CdfUpToValue
    value_bands::BandsConfiguration = BandsConfiguration()
    fraction_bands::BandsConfiguration = BandsConfiguration()
end

"""
    @kwdef mutable struct CdfGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        fraction_axis_title::Maybe{AbstractString} = nothing
        cdf_values::AbstractVector{<:Real} = Float32[]
    end

The data for a CDF (Cumulative Distribution Function) graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title` and
`fraction_axis_title` for the axes.

The order of the `line_values` does not matter.
"""
@kwdef mutable struct CdfGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    fraction_axis_title::Maybe{AbstractString} = nothing
    value_bands::BandsData = BandsData()
    fraction_bands::BandsData = BandsData()
    cdf_values::AbstractVector{<:Real} = Float32[]
end

function Validations.validate_object(data::CdfGraphData)::Maybe{AbstractString}
    if length(data.cdf_values) < 2
        return "too few data.cdf_values: $(length(data.cdf_values))"
    end
    # TRICKY: Validation will be done by the `LineGraphData` we will convert to.
    return nothing
end

"""
A graph visualizing a single cumulative distribution function. See [`CdfGraphData`](@ref) and
[`CdfGraphConfiguration`](@ref).
"""
CdfGraph = Graph{CdfGraphData, CdfGraphConfiguration}

function graph_to_figure(graph::CdfGraph)::PlotlyFigure
    assert_valid_object(graph)
    line_data = cdf_data_as_line_data(graph)
    line_configuration = cdf_configuration_as_line_configuration(graph)
    return graph_to_figure(LineGraph(line_data, line_configuration))
end

function cdf_data_as_line_data(graph::CdfGraph)::LineGraphData
    values, fractions = collect_cdf_data(graph.data.cdf_values, graph.configuration)
    if graph.configuration.values_orientation == HorizontalValues
        return LineGraphData(;
            graph_title = graph.data.graph_title,
            x_axis_title = graph.data.value_axis_title,
            y_axis_title = graph.data.fraction_axis_title,
            vertical_bands = graph.data.value_bands,
            horizontal_bands = graph.data.fraction_bands,
            points_xs = values,
            points_ys = fractions,
        )
    else
        return LineGraphData(;
            graph_title = graph.data.graph_title,
            x_axis_title = graph.data.fraction_axis_title,
            y_axis_title = graph.data.value_axis_title,
            vertical_bands = graph.data.fraction_bands,
            horizontal_bands = graph.data.value_bands,
            points_xs = fractions,
            points_ys = values,
        )
    end
end

function cdf_configuration_as_line_configuration(graph::CdfGraph)::LineGraphConfiguration
    if graph.configuration.values_orientation == HorizontalValues
        return LineGraphConfiguration(;
            graph = graph.configuration.graph,
            x_axis = graph.configuration.value_axis,
            y_axis = graph.configuration.fraction_axis,
            line = graph.configuration.line,
            vertical_bands = graph.configuration.value_bands,
            horizontal_bands = normalized_bands(
                graph.configuration.fraction_bands,
                graph.configuration.fractions_normalization,
                length(graph.data.cdf_values),
            ),
        )
    else
        return LineGraphConfiguration(;
            graph = graph.configuration.graph,
            x_axis = graph.configuration.fraction_axis,
            y_axis = graph.configuration.value_axis,
            line = graph.configuration.line,
            vertical_bands = normalized_bands(
                graph.configuration.fraction_bands,
                graph.configuration.fractions_normalization,
                length(graph.data.cdf_values),
            ),
            horizontal_bands = graph.configuration.value_bands,
        )
    end
end

function normalized_bands(
    bands_configuration::BandsConfiguration,
    fractions_normalization::GraphNormalization,
    n_values::Integer,
)::BandsConfiguration
    return BandsConfiguration(;
        low = normalized_band(bands_configuration.low, fractions_normalization, n_values),
        middle = normalized_band(bands_configuration.middle, fractions_normalization, n_values),
        high = normalized_band(bands_configuration.high, fractions_normalization, n_values),
        show_legend = bands_configuration.show_legend,
    )
end

function normalized_band(
    band_configuration::BandConfiguration,
    fractions_normalization::GraphNormalization,
    n_values::Integer,
)::BandConfiguration
    if band_configuration.offset === nothing
        offset = band_configuration.offset
    elseif fractions_normalization == NormalizeToValues
        offset = band_configuration.offset * n_values
    elseif fractions_normalization == NormalizeToFractions
        offset = band_configuration.offset
    elseif fractions_normalization == NormalizeToPercents
        offset = band_configuration.offset * 100
    else
        @assert false
    end

    return BandConfiguration(;
        offset = offset,
        color = band_configuration.color,
        width = band_configuration.width,
        is_dashed = band_configuration.is_dashed,
        is_filled = band_configuration.is_filled,
    )
end

"""
    @kwdef mutable struct CdfsGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        fraction_axis::AxisConfiguration = AxisConfiguration()
        fractions_normalization::GraphNormalization = NormalizeToFractions
        line::LineConfiguration = LineConfiguration()
        values_orientation::ValuesOrientation = HorizontalValues
        cdf_direction::CdfDirection = CdfUpToValue
        value_bands::BandsConfiguration = BandsConfiguration()
        fraction_bands::BandsConfiguration = BandsConfiguration()
        show_legend::Bool = false
    end

Configure a graph for showing multiple CDF (Cumulative Distribution Function) graph. This is the same as
[`CdfGraphConfiguration`](@ref) with the addition of a `show_legend` field.

If `fractions_normalization` is `NormalizeToValues`, then the number of values in all the `cdfs_values` vectors must be
the same.

CDF graphs are internally converted to line graphs for rendering.
"""
@kwdef mutable struct CdfsGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    fraction_axis::AxisConfiguration = AxisConfiguration()
    fractions_normalization::GraphNormalization = NormalizeToFractions
    line::LineConfiguration = LineConfiguration()
    values_orientation::ValuesOrientation = HorizontalValues
    cdf_direction::CdfDirection = CdfUpToValue
    value_bands::BandsConfiguration = BandsConfiguration()
    fraction_bands::BandsConfiguration = BandsConfiguration()
    show_legend::Bool = false
end

function Validations.validate_object(
    configuration::Union{CdfGraphConfiguration, CdfsGraphConfiguration},
)::Maybe{AbstractString}
    message = validate_graph_configuration(configuration.graph)
    if message === nothing
        message = validate_axis_configuration("value", "_axis", configuration.value_axis)
    end
    if message === nothing
        message = validate_axis_configuration("fraction", "_axis", configuration.fraction_axis)
    end
    if message === nothing
        message = validate_line_configuration(configuration.line)
    end
    if message === nothing
        message = validate_bands_configuration(
            "value_bands",
            configuration.value_bands,
            configuration.value_axis.log_regularization !== nothing,
        )
    end
    if message === nothing
        message = validate_bands_configuration(
            "fraction_bands",
            configuration.fraction_bands,
            configuration.fraction_axis.log_regularization !== nothing,
        )
    end
    return message
end

"""
    @kwdef mutable struct CdfsGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        fraction_axis_title::Maybe{AbstractString} = nothing
        cdfs_values::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[]
        cdfs_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        cdfs_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
        cdfs_widths::Maybe{AbstractVector{<:Real}} = nothing
        cdfs_are_filled::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing
        cdfs_are_dashed::Maybe{AbstractVector{Bool}} = nothing
    end

The data for multiple CDFs (Cumulative Distribution Functions) graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title` and
`fraction_axis_title` for the axes.

The order of the entries inside each of the `cdfs_values` does not matter.
"""
@kwdef mutable struct CdfsGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    fraction_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    cdfs_values::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[]
    cdfs_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    cdfs_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
    cdfs_widths::Maybe{AbstractVector{<:Real}} = nothing
    cdfs_are_filled::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing
    cdfs_are_dashed::Maybe{AbstractVector{Bool}} = nothing
end

function Validations.validate_object(data::CdfsGraphData)::Maybe{AbstractString}
    if length(data.cdfs_values) == 0
        return "empty data.cdfs_values vector"
    end
    for (index, values) in enumerate(data.cdfs_values)
        if length(values) < 2
            return "too few data.cdfs_values[$(index)]: $(length(values))"
        end
    end
    # TRICKY: Validation will be done by the `LinesGraphData` we will convert to.
    return nothing
end

"""
A graph visualizing multiple cumulative distribution functions. See [`CdfsGraphData`](@ref) and
[`CdfsGraphConfiguration`](@ref).
"""
CdfsGraph = Graph{CdfsGraphData, CdfsGraphConfiguration}

function validate_graph(graph::CdfsGraph)::Maybe{AbstractString}
    if graph.configuration.fractions_normalization == NormalizeToValues
        n_values = length(graph.data.cdfs_values[1])
        for (index, cdfs_values) in enumerate(graph.data.cdfs_values)
            if length(cdfs_values) != n_values
                return "the data.cdfs_values[$(index)] size: $(length(cdfs_values))\n" *
                       "is different from the data.cdfs_values[1] size: $(n_values)"
            end
        end
    end
    return nothing
end

function graph_to_figure(graph::CdfsGraph)::PlotlyFigure
    assert_valid_object(graph)

    lines_data = cdfs_data_as_lines_data(graph)
    lines_configuration = cdfs_configuration_as_lines_configuration(graph)
    return graph_to_figure(LinesGraph(lines_data, lines_configuration))
end

function cdfs_data_as_lines_data(graph::CdfsGraph)::LinesGraphData
    cdfs_fractions = Vector{Vector{Float64}}()
    cdfs_values = Vector{Vector{eltype(eltype(graph.data.cdfs_values))}}()
    for cdf_values in graph.data.cdfs_values
        values, fractions = collect_cdf_data(cdf_values, graph.configuration)
        push!(cdfs_fractions, fractions)
        push!(cdfs_values, values)
    end
    if graph.configuration.values_orientation == HorizontalValues
        return LinesGraphData(;
            graph_title = graph.data.graph_title,
            x_axis_title = graph.data.value_axis_title,
            y_axis_title = graph.data.fraction_axis_title,
            legend_title = graph.data.legend_title,
            lines_xs = cdfs_values,
            lines_ys = cdfs_fractions,
            lines_names = graph.data.cdfs_names,
            lines_colors = graph.data.cdfs_colors,
            lines_widths = graph.data.cdfs_widths,
            lines_are_filled = graph.data.cdfs_are_filled,
            lines_are_dashed = graph.data.cdfs_are_dashed,
        )
    else
        return LinesGraphData(;
            graph_title = graph.data.graph_title,
            x_axis_title = graph.data.fraction_axis_title,
            y_axis_title = graph.data.value_axis_title,
            legend_title = graph.data.legend_title,
            lines_xs = cdfs_fractions,
            lines_ys = cdfs_values,
            lines_names = graph.data.cdfs_names,
            lines_colors = graph.data.cdfs_colors,
            lines_widths = graph.data.cdfs_widths,
            lines_are_filled = graph.data.cdfs_are_filled,
            lines_are_dashed = graph.data.cdfs_are_dashed,
        )
    end
end

function collect_cdf_data(
    values::AbstractVector{T},
    configuration::Union{CdfGraphConfiguration, CdfsGraphConfiguration},
)::Tuple{Vector{T}, Vector{Float64}} where {T <: Real}
    n_values = length(values)
    sorted_values = sort(values)

    fractions = collect(1.0:length(sorted_values))
    if configuration.cdf_direction == CdfDownToValue
        fractions = 1.0 + n_values .- fractions
    end

    if configuration.fractions_normalization == NormalizeToFractions
        fractions ./= n_values
    elseif configuration.fractions_normalization == NormalizeToPercents
        fractions .*= 100 / n_values
    else
        @assert configuration.fractions_normalization == NormalizeToValues
    end

    return (sorted_values, fractions)
end

function cdfs_configuration_as_lines_configuration(graph::CdfsGraph)::LinesGraphConfiguration
    if graph.configuration.values_orientation == HorizontalValues
        return LinesGraphConfiguration(;
            graph = graph.configuration.graph,
            x_axis = graph.configuration.value_axis,
            y_axis = graph.configuration.fraction_axis,
            line = graph.configuration.line,
            vertical_bands = graph.configuration.value_bands,
            horizontal_bands = normalized_bands(
                graph.configuration.fraction_bands,
                graph.configuration.fractions_normalization,
                length(graph.data.cdfs_values[1]),
            ),
            show_legend = graph.configuration.show_legend,
        )
    else
        return LinesGraphConfiguration(;
            graph = graph.configuration.graph,
            x_axis = graph.configuration.fraction_axis,
            y_axis = graph.configuration.value_axis,
            line = graph.configuration.line,
            vertical_bands = normalized_bands(
                graph.configuration.fraction_bands,
                graph.configuration.fractions_normalization,
                length(graph.data.cdfs_values[1]),
            ),
            horizontal_bands = graph.configuration.value_bands,
            show_legend = graph.configuration.show_legend,
        )
    end
end

"""
    @kwdef mutable struct BarGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        values_orientation::ValuesOrientation = VerticalValues
        bars_color::Maybe{AbstractString} = nothing
        bars_gap::Maybe{Real} = nothing
    end

Configure a graph for showing a single bar (histogram) graph. The `bars_color` is chosen automatically. You can override
it globally, or per-bar in the [`BarGraphData`](@ref). By default, the X axis is used for the bars and the Y axis for
the values; this can be switched using the `values_orientation`. The `bars_gap` is the fraction of white space between
bars.
"""
@kwdef mutable struct BarGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    values_orientation::ValuesOrientation = VerticalValues
    bars_color::Maybe{AbstractString} = nothing
    bars_gap::Maybe{Real} = nothing
end

"""
    @kwdef mutable struct BarGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        bar_axis_title::Maybe{AbstractString} = nothing
        bars_values::AbstractVector{<:Real} = Float32[]
        bars_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        bars_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
        bars_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
    end

The data for a single bar (histogram) graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title` and
`bar_axis_title` for the axes.

If specified, the `bars_names` and/or `bars_colors` and/or `bars_hovers` vectors must contain the same number of
elements as the number of `bars_values`.
"""
@kwdef mutable struct BarGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    bar_axis_title::Maybe{AbstractString} = nothing
    bars_values::AbstractVector{<:Real} = Float32[]
    bars_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    bars_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
    bars_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
end

function Validations.validate_object(data::BarGraphData)::Maybe{AbstractString}
    if length(data.bars_values) == 0
        return "empty data.bars_values vector"
    end
    names = data.bars_names
    if names !== nothing && length(names) != length(data.bars_values)
        return "the data.bars_names size: $(length(names))\n" *
               "is different from the data.bars_values size: $(length(data.bars_values))"
    end
    colors = data.bars_colors
    if colors !== nothing
        if length(colors) != length(data.bars_values)
            return "the data.bars_colors size: $(length(colors))\n" *
                   "is different from the data.bars_values size: $(length(data.bars_values))"
        end
        for (color_index, color) in enumerate(colors)
            if !is_valid_color(color)
                return "invalid data.bars_colors[$(color_index)]: $(color)"
            end
        end
    end
    hovers = data.bars_hovers
    if hovers !== nothing && length(hovers) != length(data.bars_values)
        return "the data.bars_hovers size: $(length(hovers))\n" *
               "is different from the data.bars_values size: $(length(data.bars_values))"
    end
    return nothing
end

"""
A graph visualizing a single series of bars. See [`BarGraphData`](@ref) and [`BarGraphConfiguration`](@ref).
"""
BarGraph = Graph{BarGraphData, BarGraphConfiguration}

function graph_to_figure(graph::BarGraph)::PlotlyFigure
    assert_valid_object(graph)

    trace = bar_trace(;
        configuration = graph.configuration,
        values = graph.data.bars_values,
        color = graph.data.bars_colors !== nothing ? graph.data.bars_colors : graph.configuration.bars_color,
        hover = graph.data.bars_hovers,
        names = graph.data.bars_names,
    )

    layout = bar_layout(; graph = graph, has_tick_names = graph.data.bars_names !== nothing, show_legend = false)

    return plot(trace, layout)
end

"""
    @kwdef mutable struct BarsGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        values_orientation::ValuesOrientation = VerticalValues
        bars_gap::Maybe{Real} = nothing
        show_legend::Bool = false
        stacking_normalization::Maybe{GraphNormalization} = nothing
    end

Configure a graph for showing multiple bars (histograms) graph. This is similar to [`BarGraphConfiguration`](@ref),
without the `color` field (which makes no sense when multiple series are shown), and with the addition of a
`show_legend` and `stacking_normalization` fields. If `stacking_normalization` isn't specified then the different series
are just grouped.
"""
@kwdef mutable struct BarsGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    values_orientation::ValuesOrientation = VerticalValues
    bars_gap::Maybe{Real} = nothing
    show_legend::Bool = false
    stacking_normalization::Maybe{GraphNormalization} = nothing
end

function Validations.validate_object(
    configuration::Union{BarGraphConfiguration, BarsGraphConfiguration},
)::Maybe{AbstractString}
    message = validate_graph_configuration(configuration.graph)
    if message === nothing
        message = validate_axis_configuration("value", "_axis", configuration.value_axis)
    end
    if message === nothing
        bars_gap = configuration.bars_gap
        if bars_gap !== nothing
            if bars_gap < 0
                message = "non-positive configuration.bars_gap: $(bars_gap)"
            elseif bars_gap >= 1
                message = "too-large configuration.bars_gap: $(bars_gap)"
            end
        end
    end
    if message === nothing && configuration isa BarGraphConfiguration
        message = validate_color("configuration.bars_color", configuration.bars_color)
    end
    return message
end

"""
    @kwdef mutable struct BarsGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        bar_axis_title::Maybe{AbstractString} = nothing
        legend_title::Maybe{AbstractString} = nothing
        series_values::AbstractString{<:AbstractVector{<:Real}} = Vector{Float32}[]
        series_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        series_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
        series_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
        bars_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
        bars_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    end

The data for a multiple bars (histograms) graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title`,
`bar_axis_title` for the axes, and the `legend_title` (if `show_legend` is set in [`BarsGraphConfiguration`](@ref).

All the `series_values` vectors must be of the same size. If specified, the `series_names` and `series_colors` vectors
must contain the same number of elements. If specified, the `bars_names` and/or `bars_hovers` vectors must contain the
same number of elements in the each of the `series_values` vectors.
"""
@kwdef mutable struct BarsGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    bar_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    series_values::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[]
    series_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    series_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
    series_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
    bars_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
    bars_names::Maybe{AbstractVector{<:AbstractString}} = nothing
end

function Validations.validate_object(data::BarsGraphData)::Maybe{AbstractString}
    n_series = length(data.series_values)
    if n_series == 0
        return "empty data.series_values vector"
    end
    n_bars = length(data.series_values[1])
    for (index, bars_values) in enumerate(data.series_values)
        if length(bars_values) != n_bars
            return "the data.series_values[$(index)] size: $(length(bars_values))\n" *
                   "is different from the data.series_values[1] size: $(n_bars)"
        end
    end
    if n_bars == 0
        return "empty data.series_values vectors"
    end
    names = data.series_names
    if names !== nothing && length(names) != n_series
        return "the data.series_names size: $(length(names))\n" *
               "is different from the data.series_values size: $(n_series)"
    end
    colors = data.series_colors
    if colors !== nothing
        if length(colors) != n_series
            return "the data.series_colors size: $(length(colors))\n" *
                   "is different from the data.series_values size: $(n_series)"
        end
        for (color_index, color) in enumerate(colors)
            if !is_valid_color(color)
                return "invalid data.series_colors[$(color_index)]: $(color)"
            end
        end
    end
    series_hovers = data.series_hovers
    if series_hovers !== nothing && length(series_hovers) != n_series
        return "the data.series_hovers size: $(length(series_hovers))\n" *
               "is different from the data.series_values size: $(n_series)"
    end
    bars_hovers = data.bars_hovers
    if bars_hovers !== nothing && length(bars_hovers) != n_bars
        return "the data.bars_hovers size: $(length(bars_hovers))\n" *
               "is different from the data.series_values[:] size: $(n_bars)"
    end
    bars_names = data.bars_names
    if bars_names !== nothing && length(bars_names) != n_bars
        return "the data.bars_names size: $(length(bars_names))\n" *
               "is different from the data.series_values[:] size: $(n_bars)"
    end
    return nothing
end

"""
A graph visualizing multiple series of bars. See [`BarsGraphData`](@ref) and [`BarsGraphConfiguration`](@ref).
"""
BarsGraph = Graph{BarsGraphData, BarsGraphConfiguration}

function graph_to_figure(graph::BarsGraph)::PlotlyFigure
    assert_valid_object(graph)

    stacking_normalization = graph.configuration.stacking_normalization
    if stacking_normalization === nothing
        series_values = graph.data.series_values
    else
        for (series_index, bars_values) in enumerate(graph.data.series_values)
            for (bar_index, value) in enumerate(bars_values)
                @assert value >= 0 "negative stacked data.series_values[$(series_index),$(bar_index)]: $(value)"
            end
        end
        series_values = stacked_values(stacking_normalization, graph.data.series_values)
    end

    traces = Vector{GenericTrace}()
    for index in 1:length(graph.data.series_values)
        push!(
            traces,
            bar_trace(;
                configuration = graph.configuration,
                values = series_values[index],
                color = graph.data.series_colors !== nothing ? graph.data.series_colors[index] : nothing,
                hover = if graph.data.series_hovers === nothing
                    if graph.data.bars_hovers === nothing
                        nothing
                    else
                        graph.data.bars_hovers
                    end
                else
                    if graph.data.bars_hovers === nothing
                        fill(graph.data.series_hovers[index], length(series_values[index]))
                    else
                        (graph.data.series_hovers[index] * "<br>") .* graph.data.bars_hovers
                    end
                end,
                names = graph.data.bars_names,
                name = graph.data.series_names !== nothing ? graph.data.series_names[index] : "Series $(index)",
                legend_title = index == 1 ? graph.data.legend_title : nothing,
                show_legend = graph.configuration.show_legend,
            ),
        )
    end

    layout = bar_layout(;
        graph = graph,
        has_tick_names = graph.data.bars_names !== nothing,
        show_legend = graph.configuration.show_legend,
        stacked = graph.configuration.stacking_normalization !== nothing,
    )

    return plot(traces, layout)
end

function stacked_values(
    stacking_normalization::GraphNormalization,
    series_values::T,
)::T where {(T <: AbstractVector{<:AbstractVector{<:Real}})}
    if stacking_normalization == NormalizeToValues
        return series_values
    end

    total_values = zeros(eltype(eltype(series_values)), length(series_values[1]))
    for bars_values in series_values
        total_values .+= bars_values
    end

    if stacking_normalization == NormalizeToPercents
        total_values ./= 100
    end
    total_values[total_values .== 0] .= 1

    return [bars_values ./= total_values for bars_values in series_values]
end

function bar_trace(;
    configuration::Union{BarGraphConfiguration, BarsGraphConfiguration},
    values::AbstractVector{<:Real},
    color::Maybe{Union{AbstractString, AbstractVector{<:AbstractString}}},
    hover::Maybe{Union{AbstractString, AbstractVector{<:AbstractString}}},
    names::Maybe{AbstractVector{<:AbstractString}},
    name::Maybe{AbstractString} = nothing,
    legend_title::Maybe{AbstractString} = nothing,
    show_legend::Bool = false,
)::GenericTrace
    if configuration.values_orientation == HorizontalValues
        xs = values
        ys = names !== nothing ? names : ["Bar $(index)" for index in 1:length(values)]
        orientation = "h"
    elseif configuration.values_orientation == VerticalValues
        xs = names !== nothing ? names : ["Bar $(index)" for index in 1:length(values)]
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
        showlegend = show_legend,
        legendgroup = name,
        legendgrouptitle_text = legend_title,
    )
end

function bar_layout(;
    graph::Union{BarGraph, BarsGraph},
    has_tick_names::Bool,
    show_legend::Bool,
    stacked::Bool = false,
)::Layout
    if graph.configuration.values_orientation == HorizontalValues
        xaxis_showgrid = graph.configuration.graph.show_grid
        xaxis_showticklabels = graph.configuration.graph.show_ticks
        xaxis_title = graph.data.value_axis_title
        xaxis_range = (graph.configuration.value_axis.minimum, graph.configuration.value_axis.maximum)
        xaxis_type = graph.configuration.value_axis.log_regularization !== nothing ? "log" : nothing

        yaxis_showgrid = false
        yaxis_showticklabels = has_tick_names
        yaxis_title = graph.data.bar_axis_title
        yaxis_range = nothing
        yaxis_type = nothing
    elseif graph.configuration.values_orientation == VerticalValues
        xaxis_showgrid = false
        xaxis_showticklabels = has_tick_names
        xaxis_title = graph.data.bar_axis_title
        xaxis_range = nothing
        xaxis_type = nothing

        yaxis_showgrid = graph.configuration.graph.show_grid
        yaxis_showticklabels = graph.configuration.graph.show_ticks
        yaxis_title = graph.data.value_axis_title
        yaxis_range = (graph.configuration.value_axis.minimum, graph.configuration.value_axis.maximum)
        yaxis_type = graph.configuration.value_axis.log_regularization !== nothing ? "log" : nothing
    else
        @assert false
    end

    return graph_layout(
        graph.configuration.graph,
        Layout(;  # NOJET
            title = graph.data.graph_title,
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
            legend_tracegroupgap = 0,
            legend_itemdoubleclick = false,
            barmode = stacked ? "stack" : nothing,
            bargap = graph.configuration.bars_gap,
        ),
    )
end

"""
    @kwdef mutable struct SizeRangeConfiguration
        smallest::Maybe{Real} = nothing
        largest::Maybe{Real} = nothing
    end

Configure the range of sizes in pixels (1/96th of an inch) to map the sizes data into. If no bounds are given, and also
the scale is linear, then we assume the sizes data is just the size in pixels. Otherwise, by default we use 2 pixels for
the `smallest` size and make the `largest` size be 8 pixels larger than the `smallest` size.
"""
@kwdef mutable struct SizeRangeConfiguration
    smallest::Maybe{Real} = nothing
    largest::Maybe{Real} = nothing
end

function validate_size_range(
    of_what::AbstractString,
    size_range_configuration::SizeRangeConfiguration,
)::Maybe{AbstractString}
    smallest = size_range_configuration.smallest
    largest = size_range_configuration.largest
    if smallest !== nothing && largest !== nothing && largest <= smallest
        return "configuration.$(of_what).size_range.largest: $(largest)\n" *
               "is not larger than configuration.$(of_what).size_range.smallest: $(smallest)"
    end
    return nothing
end

"""
    @kwdef mutable struct PointsConfiguration
        color::Maybe{AbstractString} = nothing
        color_scale::AxisScale = AxisScale()
        show_color_scale::Bool = false,
        reverse_color_scale::Bool = false,
        color_palette::Maybe{Union{
            AbstractString,
            AbstractVector{<:Tuple{<:Real, <:AbstractString}},
            AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        }} = nothing
        size::Maybe{Real} = nothing
        size_scale::AxisScale = AxisScale()
        size_range::SizeRangeConfiguration = SizeRangeConfiguration()
    end

Configure points in a graph. By default, the point `color` and `size` is chosen automatically (when this is applied to
edges, the `size` is the width of the line). You can override this by specifying colors and/or sizes in the
[`PointsGraphData`](@ref).

For color values, the `color_palette` is applied; this can be the name of a standard one, a vector of (value, color)
tuples for a continuous (numeric value) scale or categorical (string value) scales. For sizes, the `size_range` is
applied. The `color_scale` and `reverse_color_scale` can also be used to tweak the colors. If `show_color_scale` is set,
then the colors will be shown (in the legend or as a color bar, as appropriate).

If `size_scale` and/or `size_range` are specified, they are used to control the conversion of the data sizes
to pixel sizes.
"""
@kwdef mutable struct PointsConfiguration
    color::Maybe{AbstractString} = nothing
    color_scale::AxisConfiguration = AxisConfiguration()
    show_color_scale::Bool = false
    reverse_color_scale::Bool = false
    color_palette::Maybe{
        Union{
            AbstractString,
            AbstractVector{<:Tuple{<:Real, <:AbstractString}},
            AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
        },
    } = nothing
    size::Maybe{Real} = nothing
    size_scale::AxisConfiguration = AxisConfiguration()
    size_range::SizeRangeConfiguration = SizeRangeConfiguration()
end

function validate_points_configuration(
    of_what::AbstractString,
    points_configuration::PointsConfiguration,
)::Maybe{AbstractString}
    message = validate_axis_configuration(of_what, ".color_scale", points_configuration.color_scale)
    if message === nothing
        message = validate_axis_configuration(of_what, ".size_scale", points_configuration.size_scale)
    end
    if message === nothing
        message = validate_size_range(of_what, points_configuration.size_range)
    end
    if message !== nothing
        return message
    end

    size = points_configuration.size
    if size !== nothing && size <= 0
        return "non-positive configuration.$(of_what).size: $(size)"
    end

    color_palette = points_configuration.color_palette
    if color_palette isa AbstractVector
        if length(color_palette) == 0
            return "empty configuration.$(of_what).color_palette"
        end
        for (index, (_, color)) in enumerate(color_palette)
            if color != "" && !is_valid_color(color)
                return "invalid configuration.$(of_what).color_palette[$(index)] color: $(color)"
            end
        end
        if eltype(color_palette) <: Tuple{<:Real, <:AbstractString}
            cmin = minimum([value for (value, _) in color_palette])
            cmax = maximum([value for (value, _) in color_palette])
            if cmin == cmax
                return "single configuration.$(of_what).color_palette value: $(cmax)"
            end
            log_color_scale_regularization = points_configuration.color_scale.log_regularization
            if log_color_scale_regularization !== nothing && cmin + log_color_scale_regularization <= 0
                index = argmin(color_palette)
                return "log of non-positive configuration.$(of_what).color_palette[$(index)]: $(cmin + log_color_scale_regularization)"
            end
        elseif points_configuration.reverse_color_scale
            return "reversed categorical configuration.$(of_what).color_palette"
        end
    elseif points_configuration.color_scale.log_regularization !== nothing && points_configuration.reverse_color_scale
        return "reversed log configuration.$(of_what).color_scale"
    end

    if !is_valid_color(points_configuration.color)
        return "invalid configuration.$(of_what).color: $(points_configuration.color)"
    end

    return nothing
end

"""
    @kwdef mutable struct PointsGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        points::PointsConfiguration = PointsConfiguration()
        borders::PointsConfiguration = PointsConfiguration()
        edges::PointsConfiguration = PointsConfiguration()
        edges_over_points::Bool = true
        vertical_bands::BandsConfiguration = BandsConfiguration()
        horizontal_bands::BandsConfiguration = BandsConfiguration()
        diagonal_bands::BandsConfiguration = BandsConfiguration()
    end

Configure a graph for showing a scatter graph of points.

Using the `vertical_bands`, `horizontal_bands` and/or `diagonal_bands` you can partition the graph into regions. The
`diagonal_bands` can only be used if both axes are linear or both axes are in log scale; they also unify the ranges of
the X and Y axes. If the axes are in log scale, the `offset` of the `diagonal_bands` are multiplicative instead of
additive, and must be positive.

If `edges_over_points` is set, the edges will be plotted above the points; otherwise, the points will be plotted above
the edges.

The `borders` is used if the [`PointsGraphData`](@ref) contains either the `borders_colors` and/or `borders_sizes`.
This allows displaying some additional data per point.

!!! note

    There is no `show_legend` for a [`GraphConfiguration`](@ref) of a points graph. Instead you probably want to set the
    `show_color_scale` of the `points` (and/or of the `borders`). In addition, the color scale options of the `edges`
    must not be set, as the `edges_colors` of [`PointsGraphData`](@ref) is restricted to explicit colors.
"""
@kwdef mutable struct PointsGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    points::PointsConfiguration = PointsConfiguration()
    borders::PointsConfiguration = PointsConfiguration()
    edges::PointsConfiguration = PointsConfiguration()
    edges_over_points::Bool = true
    vertical_bands::BandsConfiguration = BandsConfiguration()
    horizontal_bands::BandsConfiguration = BandsConfiguration()
    diagonal_bands::BandsConfiguration = BandsConfiguration()
end

function Validations.validate_object(configuration::PointsGraphConfiguration)::Maybe{AbstractString}
    @assert configuration.edges.color_palette === nothing "not implemented: points edges color_palette"
    @assert !configuration.edges.reverse_color_scale "not implemented: points edges.reverse_color_scale"

    message = validate_graph_configuration(configuration.graph)
    if message === nothing
        message = validate_axis_configuration("x", "_axis", configuration.x_axis)
    end
    if message === nothing
        message = validate_axis_configuration("y", "_axis", configuration.y_axis)
    end
    if message === nothing
        message = validate_points_configuration("points", configuration.points)
    end
    if message === nothing
        message = validate_points_configuration("borders", configuration.borders)
    end
    if message === nothing
        message = validate_points_configuration("edges", configuration.edges)
    end
    if message === nothing
        message = validate_bands_configuration(
            "vertical_bands",
            configuration.vertical_bands,
            configuration.x_axis.log_regularization !== nothing,
        )
    end
    if message === nothing
        message = validate_bands_configuration(
            "horizontal_bands",
            configuration.horizontal_bands,
            configuration.y_axis.log_regularization !== nothing,
        )
    end
    if message === nothing &&
       (configuration.x_axis.log_regularization === nothing) != (configuration.y_axis.log_regularization === nothing) &&
       (
           configuration.diagonal_bands.low.offset !== nothing ||
           configuration.diagonal_bands.middle.offset !== nothing ||
           configuration.diagonal_bands.high.offset !== nothing
       )
        message = "configuration.diagonal_bands specified for a combination of linear and log scale axes"
    end
    if message === nothing
        message = validate_bands_configuration(
            "diagonal_bands",
            configuration.diagonal_bands,
            configuration.x_axis.log_regularization !== nothing || configuration.y_axis.log_regularization !== nothing,
        )
    end
    return message
end

"""
    @kwdef mutable struct PointsGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        vertical_bands::BandsData = BandsData()
        horizontal_bands::BandsData = BandsData()
        diagonal_bands::BandsData = BandsData()
        points_colors_title::Maybe{AbstractString} = nothing
        points_sizes_title::Maybe{AbstractString} = nothing
        borders_colors_title::Maybe{AbstractString} = nothing
        borders_sizes_title::Maybe{AbstractString} = nothing
        edges_group_title::Maybe{AbstractString} = nothing
        edges_line_title::Maybe{AbstractString} = nothing
        points_xs::AbstractVector{<:Real} = Float32[]
        points_ys::AbstractVector{<:Real = Float32[]
        points_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing
        sizes::Maybe{AbstractVector{<:Real}} = nothing
        hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
        borders_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing
        borders_sizes::Maybe{AbstractVector{<:Real}} = nothing
        edges_points::Maybe{AbstractVector{Tuple{<:Integer, <:Integer}}} = nothing
        edges_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
        edges_sizes::Maybe{AbstractVector{<:Real}} = nothing
    end

The data for a scatter graph of points.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `x_axis_title` and
`y_axis_title` for the axes.

The `points_xs` and `points_ys` vectors must be of the same size. If specified, the `points_colors` `sizes` and/or `hovers`
vectors must also be of the same size. The `points_colors` can be either color names or a numeric value; if the latter, then
the configuration's `color_palette` is used. Sizes are the diameter in pixels (1/96th of an inch). Hovers are only shown
in interactive graphs (or when saving an HTML file).

The `borders_colors` and `borders_sizes` can be used to display additional data per point. The border size is in addition
to the point size.

The `points_colors_title`, `points_sizes_title`, `borders_colors_title` and `borders_sizes_title` are only used if
`show_color_scale` is set for the relevant color scales. You can't specify `show_color_scale` if there is no
`points_colors` data or if the `points_colors` contain explicit color names.

It is possible to draw straight `edges_points` between specific point pairs. In this case the `edges` of the
[`PointsGraphConfiguration`](@ref) will be used, and the `edges_colors` and `edges_sizes` will override it per edge. The
`edges_colors` are restricted to explicit colors, not a color scale.

A point (or a point border, or an edge) with a zero size and/or an empty string color (either from the data or from a
categorical `color_palette`) will not be shown.
"""
@kwdef mutable struct PointsGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    vertical_bands::BandsData = BandsData()
    horizontal_bands::BandsData = BandsData()
    diagonal_bands::BandsData = BandsData()
    points_colors_title::Maybe{AbstractString} = nothing
    points_sizes_title::Maybe{AbstractString} = nothing
    borders_colors_title::Maybe{AbstractString} = nothing
    borders_sizes_title::Maybe{AbstractString} = nothing
    edges_group_title::Maybe{AbstractString} = nothing
    edges_line_title::Maybe{AbstractString} = nothing
    points_xs::AbstractVector{<:Real} = Float32[]
    points_ys::AbstractVector{<:Real} = Float32[]
    points_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing
    points_sizes::Maybe{AbstractVector{<:Real}} = nothing
    points_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
    borders_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing
    borders_sizes::Maybe{AbstractVector{<:Real}} = nothing
    edges_points::Maybe{AbstractVector{Tuple{<:Integer, <:Integer}}} = nothing
    edges_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing
    edges_sizes::Maybe{AbstractVector{<:Real}} = nothing
end

function Validations.validate_object(data::PointsGraphData)::Maybe{AbstractString}
    if length(data.points_xs) != length(data.points_ys)
        return "the data.points_xs size: $(length(data.points_xs))\n" *
               "is different from the data.points_ys size: $(length(data.points_ys))"
    end

    colors = data.points_colors
    if colors !== nothing && length(colors) != length(data.points_xs)
        return "the data.points_colors size: $(length(colors))\n" *
               "is different from the data.points_xs and data.points_ys size: $(length(data.points_xs))"
    end

    sizes = data.points_sizes
    if sizes !== nothing
        if length(sizes) != length(data.points_xs)
            return "the data.points_sizes size: $(length(sizes))\n" *
                   "is different from the data.points_xs and data.points_ys size: $(length(data.points_xs))"
        end

        for (index, size) in enumerate(sizes)
            if size < 0.0
                return "negative data.points_sizes[$(index)]: $(size)"
            end
        end
    end

    borders_colors = data.borders_colors
    if borders_colors !== nothing && length(borders_colors) != length(data.points_xs)
        return "the data.borders_colors size: $(length(borders_colors))\n" *
               "is different from the data.points_xs and data.points_ys size: $(length(data.points_xs))"
    end

    borders_sizes = data.borders_sizes
    if borders_sizes !== nothing
        if length(borders_sizes) != length(data.points_xs)
            return "the data.borders_sizes size: $(length(borders_sizes))\n" *
                   "is different from the data.points_xs and data.points_ys size: $(length(data.points_xs))"
        end

        for (index, border_size) in enumerate(borders_sizes)
            if border_size < 0.0
                return "negative data.borders_sizes[$(index)]: $(border_size)"
            end
        end
    end

    hovers = data.points_hovers
    if hovers !== nothing && length(hovers) != length(data.points_xs)
        return "the data.points_hovers size: $(length(hovers))\n" *
               "is different from the data.points_xs and data.points_ys size: $(length(data.points_xs))"
    end

    edges_points = data.edges_points
    if edges_points !== nothing
        for (index, (from_point, to_point)) in enumerate(edges_points)
            if from_point < 1 || length(data.points_xs) < from_point
                return "data.edges_points[$(index)] from invalid point: $(from_point)"
            end
            if to_point < 1 || length(data.points_xs) < to_point
                return "data.edges_points[$(index)] to invalid point: $(to_point)"
            end
            if from_point == to_point
                return "data.edges_points[$(index)] from point to itself: $(from_point)"
            end
        end
    end

    return nothing
end

"""
A graph visualizing scattered points (possibly with edges between them). See [`PointsGraphData`](@ref) and
[`PointsGraphConfiguration`](@ref).
"""
PointsGraph = Graph{PointsGraphData, PointsGraphConfiguration}

function graph_to_figure(graph::PointsGraph)::PlotlyFigure
    assert_valid_object(graph)

    traces = Vector{GenericTrace}()

    minimum_x, maximum_x = range_of(;
        values = [graph.data.points_xs],
        log_regularization = graph.configuration.x_axis.log_regularization,
        apply_log = false,
    )
    minimum_y, maximum_y = range_of(;
        values = [graph.data.points_ys],
        log_regularization = graph.configuration.y_axis.log_regularization,
        apply_log = false,
    )

    vertical_legend_title = Maybe{AbstractString}[graph.data.vertical_bands.legend_title]
    horizontal_legend_title = Maybe{AbstractString}[graph.data.horizontal_bands.legend_title]
    diagonal_legend_title = Maybe{AbstractString}[graph.data.diagonal_bands.legend_title]

    (filled_vertical_low, filled_vertical_middle, filled_vertical_high) = push_fill_vertical_bands_traces(;
        traces = traces,
        legend_title = vertical_legend_title,
        bands_data = graph.data.vertical_bands,
        bands_configuration = graph.configuration.vertical_bands,
        minimum_x = minimum_x,
        minimum_y = minimum_y,
        maximum_x = maximum_x,
        maximum_y = maximum_y,
    )
    (filled_horizontal_low, filled_horizontal_middle, filled_horizontal_high) = push_fill_horizontal_bands_traces(;
        traces = traces,
        legend_title = horizontal_legend_title,
        bands_data = graph.data.horizontal_bands,
        bands_configuration = graph.configuration.horizontal_bands,
        minimum_x = minimum_x,
        minimum_y = minimum_y,
        maximum_x = maximum_x,
        maximum_y = maximum_y,
    )
    (filled_diagonal_low, filled_diagonal_middle, filled_diagonal_high) = push_fill_diagonal_bands_traces(;
        traces = traces,
        legend_title = diagonal_legend_title,
        bands_data = graph.data.diagonal_bands,
        bands_configuration = graph.configuration.diagonal_bands,
        minimum_x = minimum_x,
        minimum_y = minimum_y,
        maximum_x = maximum_x,
        maximum_y = maximum_y,
        log_scale = graph.configuration.x_axis.log_regularization !== nothing,
    )

    edges_points = graph.data.edges_points
    if edges_points !== nothing && !graph.configuration.edges_over_points
        for index in 1:length(edges_points)
            push!(
                traces,
                edge_trace(;
                    data = graph.data,
                    edges_configuration = graph.configuration.edges,
                    x_log_regularization = graph.configuration.x_axis.log_regularization,
                    y_log_regularization = graph.configuration.y_axis.log_regularization,
                    index = index,
                ),
            )
        end
    end

    sizes = fix_sizes(graph.data.points_sizes, graph.configuration.points)

    if graph.data.borders_colors !== nothing || graph.data.borders_sizes !== nothing
        marker_size = border_marker_size(graph.data, graph.configuration, sizes)
        if marker_size isa AbstractVector{<:Real}
            marker_size_mask = marker_size .> 0  # NOJET
        else
            marker_size_mask = nothing
        end

        color_palette = graph.configuration.borders.color_palette
        if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            borders_colors = graph.data.borders_colors
            @assert borders_colors isa AbstractVector{<:AbstractString}
            is_first = true
            for (value, color) in color_palette
                if color != ""
                    mask = borders_colors .== value
                    if marker_size_mask !== nothing
                        mask .&= marker_size_mask
                    end
                    if any(mask)
                        push!(
                            traces,
                            points_trace(;
                                data = graph.data,
                                x_log_regularization = graph.configuration.x_axis.log_regularization,
                                y_log_regularization = graph.configuration.y_axis.log_regularization,
                                color = color,
                                marker_size = marker_size,
                                coloraxis = nothing,
                                points_configuration = graph.configuration.borders,
                                colors_title = graph.data.borders_colors_title,
                                legend_group = "borders",
                                mask = mask,
                                name = value,
                                is_first = is_first,
                            ),
                        )
                        is_first = false
                    end
                end
            end
        else
            borders_colors = graph.data.borders_colors
            if borders_colors isa AbstractVector{<:AbstractString}
                mask = borders_colors .!= ""
                if mask !== nothing && marker_size_mask !== nothing
                    mask .&= marker_size_mask
                end
            else
                mask = marker_size_mask
            end

            push!(  # NOJET
                traces,
                points_trace(;
                    data = graph.data,
                    x_log_regularization = graph.configuration.x_axis.log_regularization,
                    y_log_regularization = graph.configuration.y_axis.log_regularization,
                    color = if borders_colors !== nothing
                        fix_colors(borders_colors, graph.configuration.borders.color_scale.log_regularization)
                    else
                        graph.configuration.borders.color
                    end,
                    marker_size = marker_size,
                    coloraxis = "coloraxis2",
                    points_configuration = graph.configuration.borders,
                    colors_title = graph.data.borders_colors_title,
                    legend_group = "borders",
                    mask = mask,
                ),
            )
        end
    end

    if sizes isa AbstractVector{<:Real}
        marker_size_mask = sizes .> 0
    else
        marker_size_mask = nothing
    end

    color_palette = graph.configuration.points.color_palette
    if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        colors = graph.data.points_colors
        @assert colors isa AbstractVector{<:AbstractString}
        is_first = true
        for (value, color) in color_palette
            if color != ""
                mask = colors .== value
                if marker_size_mask !== nothing
                    mask .&= marker_size_mask
                end
                if any(mask)
                    push!(
                        traces,
                        points_trace(;
                            data = graph.data,
                            x_log_regularization = graph.configuration.x_axis.log_regularization,
                            y_log_regularization = graph.configuration.y_axis.log_regularization,
                            color = color,
                            marker_size = sizes,
                            coloraxis = nothing,
                            points_configuration = graph.configuration.points,
                            colors_title = graph.data.points_colors_title,
                            legend_group = "points",
                            mask = mask,
                            name = value,
                            is_first = is_first,
                        ),
                    )
                    is_first = false
                end
            end
        end
    else
        colors = graph.data.points_colors
        if colors isa AbstractVector{<:AbstractString}
            mask = colors .!= ""
            if marker_size_mask !== nothing
                mask .&= marker_size_mask
            end
        else
            mask = marker_size_mask
        end

        if mask === nothing || any(mask)
            push!(  # NOJET
                traces,
                points_trace(;
                    data = graph.data,
                    x_log_regularization = graph.configuration.x_axis.log_regularization,
                    y_log_regularization = graph.configuration.y_axis.log_regularization,
                    color = if colors !== nothing
                        fix_colors(colors, graph.configuration.points.color_scale.log_regularization)
                    else
                        graph.configuration.points.color
                    end,
                    marker_size = sizes,
                    coloraxis = "coloraxis",
                    points_configuration = graph.configuration.points,
                    colors_title = graph.data.points_colors_title,
                    legend_group = "points",
                    mask = mask,
                ),
            )
        end
    end

    if edges_points !== nothing && graph.configuration.edges_over_points
        for index in 1:length(edges_points)
            push!(
                traces,
                edge_trace(;
                    data = graph.data,
                    edges_configuration = graph.configuration.edges,
                    x_log_regularization = graph.configuration.x_axis.log_regularization,
                    y_log_regularization = graph.configuration.y_axis.log_regularization,
                    index = index,
                ),
            )
        end
    end

    for (band_configuration, is_filled, name) in (
        (
            graph.configuration.vertical_bands.high,
            filled_vertical_high,
            graph.data.vertical_bands.high_title === nothing ? "right" : graph.data.vertical_bands.high_title,
        ),
        (
            graph.configuration.vertical_bands.middle,
            filled_vertical_middle,
            graph.data.vertical_bands.middle_title === nothing ? "center" : graph.data.vertical_bands.middle_title,
        ),
        (
            graph.configuration.vertical_bands.low,
            filled_vertical_low,
            graph.data.vertical_bands.low_title === nothing ? "left" : graph.data.vertical_bands.low_title,
        ),
    )
        if band_configuration.offset !== nothing && band_configuration.width !== nothing
            push!(
                traces,
                vertical_line_trace(;
                    band_configuration = band_configuration,
                    minimum_y = minimum_y,
                    maximum_y = maximum_y,
                    show_legend = !is_filled && graph.configuration.vertical_bands.show_legend,
                    legend_title = vertical_legend_title,
                    name = name,
                ),
            )
        end
    end

    for (band_configuration, is_filled, name) in (
        (
            graph.configuration.horizontal_bands.high,
            filled_horizontal_high,
            graph.data.horizontal_bands.high_title === nothing ? "high" : graph.data.horizontal_bands.high_title,
        ),
        (
            graph.configuration.horizontal_bands.middle,
            filled_horizontal_middle,
            graph.data.horizontal_bands.middle_title === nothing ? "middle" : graph.data.horizontal_bands.middle_title,
        ),
        (
            graph.configuration.horizontal_bands.low,
            filled_horizontal_low,
            graph.data.horizontal_bands.low_title === nothing ? "low" : graph.data.horizontal_bands.low_title,
        ),
    )
        if band_configuration.offset !== nothing && band_configuration.width !== nothing
            push!(
                traces,
                horizontal_line_trace(;
                    band_configuration = band_configuration,
                    minimum_x = minimum_x,
                    maximum_x = maximum_x,
                    show_legend = !is_filled && graph.configuration.horizontal_bands.show_legend,
                    legend_title = horizontal_legend_title,
                    name = name,
                ),
            )
        end
    end

    for (band_configuration, is_filled, name) in (
        (
            graph.configuration.diagonal_bands.high,
            filled_diagonal_high,
            graph.data.diagonal_bands.high_title === nothing ? "high" : graph.data.diagonal_bands.high_title,
        ),
        (
            graph.configuration.diagonal_bands.middle,
            filled_diagonal_middle,
            graph.data.diagonal_bands.middle_title === nothing ? "middle" : graph.data.diagonal_bands.middle_title,
        ),
        (
            graph.configuration.diagonal_bands.low,
            filled_diagonal_low,
            graph.data.diagonal_bands.low_title === nothing ? "low" : graph.data.diagonal_bands.low_title,
        ),
    )
        if band_configuration.offset !== nothing && band_configuration.width !== nothing
            push!(
                traces,
                diagonal_line_trace(;
                    band_configuration = band_configuration,
                    minimum_x = minimum_x,
                    maximum_x = maximum_x,
                    minimum_y = minimum_y,
                    maximum_y = maximum_y,
                    log_scale = graph.configuration.x_axis.log_regularization !== nothing,
                    show_legend = !is_filled && graph.configuration.diagonal_bands.show_legend,
                    legend_title = diagonal_legend_title,
                    name = name,
                ),
            )
        end
    end

    layout = points_layout(;
        data = graph.data,
        minimum_x = minimum_x,
        minimum_y = minimum_y,
        maximum_x = maximum_x,
        maximum_y = maximum_y,
        configuration = graph.configuration,
        x_axis_configuration = graph.configuration.x_axis,
        y_axis_configuration = graph.configuration.y_axis,
    )

    return plot(traces, layout)
end

function push_fill_vertical_bands_traces(;
    traces::Vector{GenericTrace},
    legend_title::Vector{Maybe{AbstractString}},
    bands_data::BandsData,
    bands_configuration::BandsConfiguration,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
)::Tuple{Bool, Bool, Bool}
    fill_high = bands_configuration.high.offset !== nothing && bands_configuration.high.is_filled
    if fill_high
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [maximum_x, bands_configuration.high.offset, bands_configuration.high.offset, maximum_x],
                points_ys = [minimum_y, minimum_y, maximum_y, maximum_y],
                line_color = bands_configuration.high.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.high_title === nothing ? "right" : bands_data.high_title,
            ),
        )
    end

    fill_middle =
        bands_configuration.high.offset !== nothing &&
        bands_configuration.low.offset !== nothing &&
        bands_configuration.middle.is_filled
    if fill_middle
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [
                    bands_configuration.low.offset,
                    bands_configuration.high.offset,
                    bands_configuration.high.offset,
                    bands_configuration.low.offset,
                ],
                points_ys = [minimum_y, minimum_y, maximum_y, maximum_y],
                line_color = bands_configuration.middle.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.middle_title === nothing ? "center" : bands_data.middle_title,
            ),
        )
    end

    fill_low = bands_configuration.low.offset !== nothing && bands_configuration.low.is_filled
    if fill_low
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [minimum_x, bands_configuration.low.offset, bands_configuration.low.offset, minimum_x],
                points_ys = [minimum_y, minimum_y, maximum_y, maximum_y],
                line_color = bands_configuration.low.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.low_title === nothing ? "left" : bands_data.low_title,
            ),
        )
    end

    return fill_low, fill_middle, fill_high
end

function push_fill_horizontal_bands_traces(;
    traces::Vector{GenericTrace},
    legend_title::Vector{Maybe{AbstractString}},
    bands_data::BandsData,
    bands_configuration::BandsConfiguration,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
)::Tuple{Bool, Bool, Bool}
    fill_high = bands_configuration.high.offset !== nothing && bands_configuration.high.is_filled
    if fill_high
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [minimum_x, minimum_x, maximum_x, maximum_x],
                points_ys = [maximum_y, bands_configuration.high.offset, bands_configuration.high.offset, maximum_y],
                line_color = bands_configuration.high.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.high_title === nothing ? "high" : bands_data.high_title,
            ),
        )
    end

    fill_middle =
        bands_configuration.high.offset !== nothing &&
        bands_configuration.low.offset !== nothing &&
        bands_configuration.middle.is_filled
    if fill_middle
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [minimum_x, minimum_x, maximum_x, maximum_x],
                points_ys = [
                    bands_configuration.low.offset,
                    bands_configuration.high.offset,
                    bands_configuration.high.offset,
                    bands_configuration.low.offset,
                ],
                line_color = bands_configuration.middle.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.middle_title === nothing ? "middle" : bands_data.middle_title,
            ),
        )
    end

    fill_low = bands_configuration.low.offset !== nothing && bands_configuration.low.is_filled
    if fill_low
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [minimum_x, minimum_x, maximum_x, maximum_x],
                points_ys = [minimum_y, bands_configuration.low.offset, bands_configuration.low.offset, minimum_y],
                line_color = bands_configuration.low.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.low_title === nothing ? "low" : bands_data.low_title,
            ),
        )
    end

    return fill_low, fill_middle, fill_high
end

function push_fill_diagonal_bands_traces(;
    traces::Vector{GenericTrace},
    legend_title::Vector{Maybe{AbstractString}},
    bands_data::BandsData,
    bands_configuration::BandsConfiguration,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
    log_scale::Bool,
)::Tuple{Bool, Bool, Bool}
    fill_high = bands_configuration.high.offset !== nothing && bands_configuration.high.is_filled
    if fill_high
        push!(  # NOJET
            traces,
            fill_high_diagonal_trace(;
                offset = bands_configuration.high.offset,
                minimum_x = minimum_x,
                minimum_y = minimum_y,
                maximum_x = maximum_x,
                maximum_y = maximum_y,
                line_color = bands_configuration.high.color,
                show_legend = bands_configuration.show_legend,
                name = bands_data.high_title === nothing ? "higher" : bands_data.high_title,
                legend_title = legend_title,
                log_scale = log_scale,
            ),
        )
    end

    fill_middle =
        bands_configuration.high.offset !== nothing &&
        bands_configuration.low.offset !== nothing &&
        bands_configuration.middle.is_filled
    if fill_middle
        push!(  # NOJET
            traces,
            fill_middle_diagonal_trace(;
                low_offset = bands_configuration.low.offset,
                high_offset = bands_configuration.high.offset,
                minimum_x = minimum_x,
                minimum_y = minimum_y,
                maximum_x = maximum_x,
                maximum_y = maximum_y,
                line_color = bands_configuration.middle.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.middle_title === nothing ? "comparable" : bands_data.middle_title,
                log_scale = log_scale,
            ),
        )
    end

    fill_low = bands_configuration.low.offset !== nothing && bands_configuration.low.is_filled
    if fill_low
        push!(  # NOJET
            traces,
            fill_low_diagonal_trace(;
                offset = bands_configuration.low.offset,
                minimum_x = minimum_x,
                minimum_y = minimum_y,
                maximum_x = maximum_x,
                maximum_y = maximum_y,
                line_color = bands_configuration.low.color,
                show_legend = bands_configuration.show_legend,
                name = bands_data.low_title === nothing ? "lower" : bands_data.low_title,
                legend_title = legend_title,
                log_scale = log_scale,
            ),
        )
    end

    return fill_low, fill_middle, fill_high
end

function fill_low_diagonal_trace(;
    offset::Real,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
    line_color::Maybe{AbstractString},
    show_legend::Bool,
    legend_title::Vector{Maybe{AbstractString}},
    name::AbstractString,
    log_scale::Bool,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(log_scale)
    if offset < threshold
        return fill_trace(;
            points_xs = [decrease(minimum_xy, offset), maximum_xy, maximum_xy],
            points_ys = [minimum_xy, increase(maximum_xy, offset), minimum_xy],
            line_color = line_color,
            show_legend = show_legend,
            legend_title = legend_title,
            name = name,
        )
    else
        return fill_trace(;
            points_xs = [minimum_xy, maximum_xy, maximum_xy, decrease(maximum_xy, offset), minimum_xy],
            points_ys = [minimum_xy, minimum_xy, maximum_xy, maximum_xy, increase(minimum_xy, offset)],
            line_color = line_color,
            show_legend = show_legend,
            legend_title = legend_title,
            name = name,
        )
    end
end

function fill_high_diagonal_trace(;
    offset::Real,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
    line_color::Maybe{AbstractString},
    show_legend::Bool,
    legend_title::Vector{Maybe{AbstractString}},
    name::AbstractString,
    log_scale::Bool,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(log_scale)
    if offset < threshold
        return fill_trace(;
            points_xs = [minimum_xy, minimum_xy, maximum_xy, maximum_xy, decrease(minimum_xy, offset)],
            points_ys = [minimum_xy, maximum_xy, maximum_xy, increase(maximum_xy, offset), minimum_xy],
            line_color = line_color,
            show_legend = show_legend,
            legend_title = legend_title,
            name = name,
        )
    else
        return fill_trace(;
            points_xs = [minimum_xy, decrease(maximum_xy, offset), minimum_xy],
            points_ys = [increase(minimum_xy, offset), maximum_xy, maximum_xy],
            line_color = line_color,
            show_legend = show_legend,
            legend_title = legend_title,
            name = name,
        )
    end
end

function fill_middle_diagonal_trace(;
    low_offset::Real,
    high_offset::Real,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
    line_color::Maybe{AbstractString},
    show_legend::Bool,
    legend_title::Vector{Maybe{AbstractString}},
    name::AbstractString,
    log_scale::Bool,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(log_scale)
    if high_offset < threshold
        return fill_trace(;
            points_xs = [decrease(minimum_xy, high_offset), decrease(minimum_xy, low_offset), maximum_xy, maximum_xy],
            points_ys = [minimum_xy, minimum_xy, increase(maximum_xy, low_offset), increase(maximum_xy, high_offset)],
            line_color = line_color,
            show_legend = show_legend,
            legend_title = legend_title,
            name = name,
        )
    elseif low_offset > threshold
        return fill_trace(;
            points_xs = [minimum_xy, minimum_xy, decrease(maximum_xy, high_offset), decrease(maximum_xy, low_offset)],
            points_ys = [increase(minimum_xy, low_offset), increase(minimum_xy, high_offset), maximum_xy, maximum_xy],
            line_color = line_color,
            show_legend = show_legend,
            legend_title = legend_title,
            name = name,
        )
    else
        return fill_trace(;
            points_xs = [
                minimum_xy,
                decrease(minimum_xy, low_offset),
                maximum_xy,
                maximum_xy,
                decrease(maximum_xy, high_offset),
                minimum_xy,
            ],
            points_ys = [
                minimum_xy,
                minimum_xy,
                increase(maximum_xy, low_offset),
                maximum_xy,
                maximum_xy,
                increase(minimum_xy, high_offset),
            ],
            line_color = line_color,
            show_legend = show_legend,
            legend_title = legend_title,
            name = name,
        )
    end
end

function fill_trace(;
    points_xs::AbstractVector{<:Real},
    points_ys::AbstractVector{<:Real},
    line_color::Maybe{AbstractString},
    show_legend::Bool,
    legend_title::Vector{Maybe{AbstractString}},
    name::AbstractString,
)::GenericTrace
    legendgrouptitle_text = legend_title[1]
    legend_title[1] = nothing
    return scatter(;
        x = points_xs,
        y = points_ys,
        fill = "toself",
        fillcolor = fill_color(line_color),
        showlegend = show_legend,
        name = name,
        legendgroup = name,
        legendgrouptitle_text = legendgrouptitle_text,
        mode = "none",
    )
end

function fill_color(::Nothing)::Nothing
    return nothing
end

function fill_color(line_color::AbstractString)::AbstractString
    rgba = parse(RGBA, line_color)
    return hex(RGBA(rgba.r, rgba.g, rgba.b, rgba.alpha * 0.5), :RRGGBBAA)
end

function points_trace(;
    data::PointsGraphData,
    x_log_regularization::Maybe{AbstractFloat},
    y_log_regularization::Maybe{AbstractFloat},
    color::Maybe{Union{AbstractString, AbstractVector{<:AbstractString}, AbstractVector{<:Real}}},
    marker_size::Maybe{Union{Real, AbstractVector{<:Real}}},
    coloraxis::Maybe{AbstractString},
    points_configuration::PointsConfiguration,
    colors_title::Maybe{AbstractString},
    legend_group::AbstractString,
    mask::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing,
    name::Maybe{AbstractString} = nothing,
    is_first::Bool = true,
)::GenericTrace
    name = name !== nothing ? name : points_configuration.show_color_scale ? "Trace" : ""
    return scatter(;
        x = masked_data(data.points_xs, mask) .+ (x_log_regularization === nothing ? 0 : x_log_regularization),
        y = masked_data(data.points_ys, mask) .+ (y_log_regularization === nothing ? 0 : y_log_regularization),
        marker_size = masked_data(marker_size, mask),
        marker_color = color !== nothing ? masked_data(color, mask) : points_configuration.color,
        marker_colorscale = if points_configuration.color_palette isa AbstractVector ||
                               points_configuration.color_scale.log_regularization !== nothing
            nothing
        else
            points_configuration.color_palette
        end,
        marker_coloraxis = coloraxis,
        marker_showscale = points_configuration.show_color_scale && !(
            points_configuration.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        ),
        marker_reversescale = points_configuration.reverse_color_scale,
        showlegend = points_configuration.show_color_scale &&
                     points_configuration.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
        legendgroup = is_first ? "$(legend_group) $(name)" : nothing,
        legendgrouptitle_text = is_first ? colors_title : nothing,
        name = name,
        text = masked_data(data.points_hovers, mask),
        hovertemplate = data.points_hovers === nothing ? nothing : "%{text}<extra></extra>",
        mode = "markers",
    )
end

function edge_trace(;
    data::PointsGraphData,
    edges_configuration::PointsConfiguration,
    x_log_regularization::Maybe{AbstractFloat},
    y_log_regularization::Maybe{AbstractFloat},
    index::Int,
)::GenericTrace
    if x_log_regularization === nothing
        x_log_regularization = 0
    end
    if y_log_regularization === nothing
        y_log_regularization = 0
    end
    from_point, to_point = data.edges_points[index]
    return scatter(;
        x = [data.points_xs[from_point] + x_log_regularization, data.points_xs[to_point] + x_log_regularization],
        y = [data.points_ys[from_point] + y_log_regularization, data.points_ys[to_point] + y_log_regularization],
        line_width = if data.edges_sizes !== nothing
            data.edges_sizes[index]
        else
            edges_configuration.size
        end,
        line_color = if data.edges_colors !== nothing
            data.edges_colors[index]
        elseif edges_configuration.color !== nothing
            edges_configuration.color
        else
            "darkgrey"
        end,
        name = data.edges_line_title !== nothing ? data.edges_line_title : "",
        mode = "lines",
        legendgroup = "edges",
        legendgrouptitle_text = data.edges_group_title,
        showlegend = index == 1 && edges_configuration.show_color_scale,
    )
end

function vertical_line_trace(;
    band_configuration::BandConfiguration,
    minimum_y::Real,
    maximum_y::Real,
    show_legend::Bool,
    legend_title::Vector{Maybe{AbstractString}},
    name::AbstractString,
)::GenericTrace
    @assert band_configuration.offset !== nothing
    legendgrouptitle_text = legend_title[1]
    legend_title[1] = nothing
    return scatter(;
        x = [band_configuration.offset, band_configuration.offset],
        y = [minimum_y, maximum_y],
        line_width = band_configuration.width,
        line_color = band_configuration.color !== nothing ? band_configuration.color : "black",
        line_dash = band_configuration.is_dashed ? "dash" : nothing,
        showlegend = show_legend,
        legendgroup = name,
        legendgrouptitle_text = legendgrouptitle_text,
        name = name,
        mode = "lines",
    )
end

function horizontal_line_trace(;
    band_configuration::BandConfiguration,
    minimum_x::Real,
    maximum_x::Real,
    show_legend::Bool,
    legend_title::Vector{Maybe{AbstractString}},
    name::AbstractString,
)::GenericTrace
    @assert band_configuration.offset !== nothing
    legendgrouptitle_text = legend_title[1]
    legend_title[1] = nothing
    return scatter(;
        x = [minimum_x, maximum_x],
        y = [band_configuration.offset, band_configuration.offset],
        line_width = band_configuration.width,
        line_color = band_configuration.color !== nothing ? band_configuration.color : "black",
        line_dash = band_configuration.is_dashed ? "dash" : nothing,
        showlegend = show_legend,
        legendgroup = name,
        legendgrouptitle_text = legendgrouptitle_text,
        name = name,
        mode = "lines",
    )
end

function diagonal_line_trace(;
    band_configuration::BandConfiguration,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
    log_scale::Bool,
    show_legend::Bool,
    legend_title::Vector{Maybe{AbstractString}},
    name::AbstractString,
)::GenericTrace
    offset = band_configuration.offset
    @assert offset !== nothing
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)

    legendgrouptitle_text = legend_title[1]
    legend_title[1] = nothing

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
        line_width = band_configuration.width,
        line_color = band_configuration.color !== nothing ? band_configuration.color : "black",
        line_dash = band_configuration.is_dashed ? "dash" : nothing,
        showlegend = show_legend,
        legendgroup = name,
        legendgrouptitle_text = legendgrouptitle_text,
        name = name,
        mode = "lines",
    )
end

function band_operations(log_scale::Bool)::Tuple{AbstractFloat, Function, Function}
    if log_scale
        return (1.0, *, /)
    else
        return (0.0, +, -)
    end
end

function fix_colors(
    colors::Maybe{
        Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}, AbstractMatrix{<:Union{Real, AbstractString}}},
    },
    ::Nothing,
)::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}, AbstractMatrix{<:Union{Real, AbstractString}}}}
    return colors
end

function fix_colors(
    colors::Union{AbstractVector{<:Real}, AbstractMatrix{<:Real}},
    log_color_scale_regularization::AbstractFloat,
)::Union{AbstractVector{<:Real}, AbstractMatrix{<:Real}}
    return log10.(colors .+ log_color_scale_regularization)
end

function xy_ticks(::Nothing)::Tuple{Nothing, Nothing}
    return (nothing, nothing)
end

function xy_ticks(names::AbstractVector{<:AbstractString})::Tuple{Vector{<:Integer}, AbstractVector{<:AbstractString}}
    return (collect(1:length(names)), names)
end

function log_color_scale_ticks(
    colors::Maybe{Union{AbstractVector{<:Union{Real, AbstractString}}, AbstractMatrix{<:Union{Real, AbstractString}}}},
    points_configuration::PointsConfiguration,
)::Tuple{Maybe{Vector{Float32}}, Maybe{Vector{String}}}
    log_color_scale_regularization = points_configuration.color_scale.log_regularization
    if log_color_scale_regularization === nothing || !points_configuration.show_color_scale
        return nothing, nothing
    else
        @assert colors isa AbstractVector{<:Real}
        cmin = lowest_color(
            points_configuration.color_palette,
            points_configuration.color_scale.minimum,
            log_color_scale_regularization,
        )  # NOJET
        if cmin === nothing
            cmin = log10(minimum(colors) + log_color_scale_regularization)
        end
        cmax = highest_color(
            points_configuration.color_palette,
            points_configuration.color_scale.maximum,
            log_color_scale_regularization,
        )  # NOJET
        if cmax === nothing
            cmax = log10(maximum(colors) + log_color_scale_regularization)
        end
        int_cmin = Int(floor(cmin))
        int_cmax = Int(ceil(cmax))
        if int_cmin == int_cmax
            return nothing, nothing  # untested
        end
        tickvals = Vector{Float32}(undef, (int_cmax - int_cmin) * 3 + 1)
        tick_index = 1
        for at in int_cmin:(int_cmax - 1)
            tickvals[tick_index] = at
            tickvals[tick_index + 1] = at + log10(2.0)
            tickvals[tick_index + 2] = at + log10(5.0)
            tick_index += 3
        end
        first_int_index = 1
        tickvals[tick_index] = int_cmax
        while length(tickvals) > 1 && tickvals[1] < cmin
            @views tickvals = tickvals[2:end]
            first_int_index = (first_int_index + 2) % 3
        end
        while length(tickvals) > 1 && tickvals[end] > cmax
            @views tickvals = tickvals[1:(end - 1)]
        end
        return tickvals, log_tick_text_for_vals(tickvals, first_int_index)
    end
end

function log_tick_text_for_vals(tickvals::AbstractVector{Float32}, first_int_index::Int)::Vector{String}
    show_middle_ticks = length(tickvals) <= 7
    ticktext = fill("", length(tickvals))
    for (index, tickval) in enumerate(tickvals)
        offset = (3 + index - first_int_index) % 3
        if offset == 0
            ticktext[index] = "1e$(Int(round(tickval)))"
        elseif !show_middle_ticks
            ticktext[index] = ""
        elseif offset == 1
            ticktext[index] = "2e$(Int(floor(tickval)))"
        elseif offset == 2
            ticktext[index] = "5e$(Int(floor(tickval)))"
        else
            @assert false
        end
    end
    return ticktext
end

function normalized_color_palette(color_palette::Maybe{AbstractString}, ::AxisConfiguration)::Maybe{AbstractString}
    return color_palette
end

function normalized_color_palette(
    color_palette::AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
    ::AxisConfiguration,
)::AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
    return color_palette
end

function normalized_color_palette(
    color_palette::AbstractVector{<:Tuple{<:Real, <:AbstractString}},
    color_scale::AxisConfiguration,
)::AbstractVector{<:Tuple{<:Real, <:AbstractString}}
    log_regularization = color_scale.log_regularization
    if log_regularization === nothing
        cmin = lowest_color(color_palette, color_scale.minimum, nothing)
        cmax = highest_color(color_palette, color_scale.maximum, nothing)
        return [(clamp((value - cmin) / (cmax - cmin), 0.0, 1.0), color) for (value, color) in color_palette]
    else
        cmin = lowest_color(color_palette, color_scale.minimum, log_regularization)
        cmax = highest_color(color_palette, color_scale.maximum, log_regularization)
        return [
            (clamp((log10(value + log_regularization) - cmin) / (cmax - cmin), 0.0, 1.0), color) for
            (value, color) in color_palette
        ]
    end
end

function lowest_color(::Any, minimum::Real, ::Any)::Real
    return minimum
end

function lowest_color(
    ::Maybe{Union{AbstractString, AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}}},
    ::Nothing,
    ::Maybe{AbstractFloat},
)::Nothing
    return nothing
end

function lowest_color(color_palette::AbstractVector{<:Tuple{<:Real, <:AbstractString}}, ::Nothing, ::Nothing)::Real
    return minimum([value for (value, _) in color_palette])
end

function lowest_color(
    color_palette::AbstractVector{<:Tuple{<:Real, <:AbstractString}},
    ::Nothing,
    log_color_scale_regularization::AbstractFloat,
)::AbstractFloat
    return log10(minimum([value for (value, _) in color_palette]) + log_color_scale_regularization)
end

function highest_color(::Any, maximum::Real, ::Any)::Real
    return maximum
end

function highest_color(
    ::Maybe{Union{AbstractString, AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}}},
    ::Nothing,
    ::Maybe{AbstractFloat},
)::Nothing
    return nothing
end

function highest_color(color_palette::AbstractVector{<:Tuple{<:Real, <:AbstractString}}, ::Nothing, ::Nothing)::Real
    return maximum([value for (value, _) in color_palette])
end

function highest_color(
    color_palette::AbstractVector{<:Tuple{<:Real, <:AbstractString}},
    ::Nothing,
    log_color_scale_regularization::AbstractFloat,
)::AbstractFloat
    return log10(maximum([value for (value, _) in color_palette]) + log_color_scale_regularization)
end

"""
    @kwdef mutable struct GridGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        points::PointsConfiguration = PointsConfiguration()
        borders::PointsConfiguration = PointsConfiguration()
    end

Configure a graph showing a grid of points (e.g. for correlations).

This displays a matrix of values using a point at each grid position. This is often used to show correlations between
two sets of discrete variables. For large amounts of data, use a heatmap instead. An advantage of this over a heatmap is
that you can control the color, size, and border color and size of the points to show more than one value per point. A
disadvantage of this plot is that it only works for "small" amount of data. Also, you will need to manually tweak the
graph size vs. the point sizes for best results, as Plotly's defaults aren't very good here.
"""
@kwdef mutable struct GridGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    points::PointsConfiguration = PointsConfiguration()
    borders::PointsConfiguration = PointsConfiguration()
end

function Validations.validate_object(configuration::GridGraphConfiguration)::Maybe{AbstractString}
    message = validate_graph_configuration(configuration.graph)
    if message === nothing
        message = validate_points_configuration("points", configuration.points)
    end
    if message === nothing
        message = validate_points_configuration("borders", configuration.borders)
    end
    return message
end

"""
    @kwdef mutable struct GridGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        points_colors_title::Maybe{AbstractString} = nothing
        borders_colors_title::Maybe{AbstractString} = nothing
        columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        points_colors::Maybe{Union{AbstractMatrix{<:Union{AbstractString, <:Real}}}} = nothing
        points_sizes::Maybe{AbstractMatrix{<:Real}} = nothing
        points_hovers::Maybe{AbstractMatrix{<:AbstractString}} = nothing
        borders_colors::Maybe{Union{AbstractMatrix{<:Union{AbstractString, <:Real}}}} = nothing
        borders_sizes::Maybe{AbstractMatrix{<:Real}} = nothing
    end

The data for a graph showing a grid of points (e.g. for correlations).

This is similar to a [`PointsGraphData`](@ref), except that the data is given as a matrix instead of a vector, and no X
and Y coordinates are given. Instead each matrix entry is plotted as a point at the matching grid location.
"""
@kwdef mutable struct GridGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    points_colors_title::Maybe{AbstractString} = nothing
    borders_colors_title::Maybe{AbstractString} = nothing
    columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    points_colors::Maybe{Union{AbstractMatrix{<:Union{AbstractString, <:Real}}}} = nothing
    points_sizes::Maybe{AbstractMatrix{<:Real}} = nothing
    points_hovers::Maybe{AbstractMatrix{<:AbstractString}} = nothing
    borders_colors::Maybe{Union{AbstractMatrix{<:Union{AbstractString, <:Real}}}} = nothing
    borders_sizes::Maybe{AbstractMatrix{<:Real}} = nothing
end

function Validations.validate_object(data::GridGraphData)::Maybe{AbstractString}
    colors = data.points_colors
    sizes = data.points_sizes

    if colors === nothing && sizes === nothing
        return "neither data.points_colors nor data.points_sizes specified for grid points"
    end

    if colors !== nothing && sizes !== nothing && size(colors) != size(sizes)
        return "the data.points_colors size: $(size(colors))\n" *
               "is different from the data.points_sizes size: $(size(sizes))"
    end

    if colors !== nothing
        grid_size = size(colors)
    else
        @assert sizes !== nothing
        grid_size = size(sizes)
    end

    n_rows, n_columns = grid_size
    if sizes !== nothing
        for row_index in 1:n_rows
            for column_index in 1:n_columns
                point_size = sizes[row_index, column_index]
                if point_size < 0
                    return "negative data.points_sizes[$(row_index),$(column_index)]: $(point_size)"
                end
            end
        end
    end

    borders_colors = data.borders_colors
    if borders_colors !== nothing && size(borders_colors) != grid_size
        return "the data.borders_colors size: $(size(borders_colors))\n" *
               "is different from the data.points_colors and/or data.points_sizes size: $(grid_size)"
    end

    borders_sizes = data.borders_sizes
    if borders_sizes !== nothing && size(borders_sizes) != grid_size
        return "the data.borders_sizes size: $(size(borders_sizes))\n" *
               "is different from the data.points_colors and/or data.points_sizes size: $(grid_size)"
    end

    if borders_sizes !== nothing
        for row_index in 1:n_rows
            for column_index in 1:n_columns
                border_size = borders_sizes[row_index, column_index]
                if border_size < 0
                    return "negative data.borders_sizes[$(row_index),$(column_index)]: $(border_size)"
                end
            end
        end
    end

    hovers = data.points_hovers
    if hovers !== nothing && size(hovers) != grid_size
        return "the data.points_hovers size: $(size(hovers))\n" *
               "is different from the data.points_colors and/or data.points_sizes size: $(grid_size)"
    end

    return nothing
end

"""
A graph visualizing points along a grid. See [`GridGraphData`](@ref) and [`GridGraphConfiguration`](@ref).

An advantage of this over a heatmap is that you can control the color, size, and border color and size of the points to
show more than one value per point. A disadvantage of this plot compared to a heatmap is that it only works for "small"
amount of data. Also, you will need to manually tweak the graph size vs. the point sizes for best results, as Plotly's
defaults aren't very good here.
"""
GridGraph = Graph{GridGraphData, GridGraphConfiguration}

function graph_to_figure(graph::GridGraph)::PlotlyFigure
    assert_valid_object(graph)

    if graph.data.points_sizes !== nothing
        n_rows, n_columns = size(graph.data.points_sizes)
    else
        @assert graph.data.points_colors !== nothing
        n_rows, n_columns = size(graph.data.points_colors)
    end

    traces = Vector{GenericTrace}()

    sizes = fix_sizes(graph.data.points_sizes, graph.configuration.points)

    borders_colors = graph.data.borders_colors
    if borders_colors !== nothing || graph.data.borders_sizes !== nothing
        marker_size = border_marker_size(graph.data, graph.configuration, sizes)
        if marker_size isa AbstractVector{<:Real}
            marker_size_mask = marker_size .> 0
        else
            marker_size_mask = nothing
        end

        color_palette = graph.configuration.borders.color_palette
        if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            @assert borders_colors isa AbstractMatrix{<:AbstractString}
            is_first = true
            for (value, color) in color_palette
                if color != ""
                    mask = vec(borders_colors) .== value
                    if marker_size_mask !== nothing
                        mask .&= marker_size_mask
                    end
                    if any(mask)
                        push!(
                            traces,
                            grid_trace(;
                                data = graph.data,
                                n_rows = n_rows,
                                n_columns = n_columns,
                                color = color,
                                marker_size = marker_size,
                                coloraxis = nothing,
                                points_configuration = graph.configuration.borders,
                                colors_title = graph.data.borders_colors_title,
                                legend_group = "borders",
                                mask = mask,
                                name = value,
                                is_first = is_first,
                            ),
                        )
                        is_first = false
                    end
                end
            end
        else
            borders_colors = graph.data.borders_colors
            if borders_colors isa AbstractMatrix{<:AbstractString}
                mask = vec(borders_colors) .!= ""
                if marker_size_mask !== nothing
                    mask .&= marker_size_mask
                end
            else
                mask = marker_size_mask
            end

            if mask === nothing || any(mask)
                push!(  # NOJET
                    traces,
                    grid_trace(;
                        data = graph.data,
                        n_rows = n_rows,
                        n_columns = n_columns,
                        color = if borders_colors !== nothing
                            fix_colors(borders_colors, graph.configuration.borders.color_scale.log_regularization)
                        else
                            graph.configuration.borders.color
                        end,
                        marker_size = marker_size,
                        coloraxis = "coloraxis2",
                        points_configuration = graph.configuration.borders,
                        colors_title = graph.data.borders_colors_title,
                        mask = mask,
                        legend_group = "borders",
                    ),
                )
            end
        end
    end

    if sizes isa AbstractVector{<:Real}
        marker_size_mask = sizes .> 0
    else
        marker_size_mask = nothing
    end

    color_palette = graph.configuration.points.color_palette
    if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        colors = graph.data.points_colors
        @assert colors isa AbstractMatrix{<:AbstractString}
        is_first = true
        for (value, color) in color_palette
            if color != ""
                mask = vec(colors .== value)
                if marker_size_mask !== nothing
                    mask .&= marker_size_mask
                end
                if any(mask)
                    push!(
                        traces,
                        grid_trace(;
                            data = graph.data,
                            n_rows = n_rows,
                            n_columns = n_columns,
                            color = color,
                            marker_size = sizes,
                            coloraxis = nothing,
                            points_configuration = graph.configuration.points,
                            colors_title = graph.data.points_colors_title,
                            legend_group = "points",
                            mask = mask,
                            name = value,
                            is_first = is_first,
                        ),
                    )
                end
                is_first = false
            end
        end
    else
        colors = graph.data.points_colors
        if colors isa AbstractMatrix{<:AbstractString}
            mask = vec(colors) .!= ""
            if marker_size_mask !== nothing
                mask .&= marker_size_mask
            end
        else
            mask = marker_size_mask
        end

        if mask === nothing || any(mask)
            push!(  # NOJET
                traces,
                grid_trace(;
                    data = graph.data,
                    n_rows = n_rows,
                    n_columns = n_columns,
                    color = if colors !== nothing
                        fix_colors(colors, graph.configuration.points.color_scale.log_regularization)
                    else
                        graph.configuration.points.color
                    end,
                    marker_size = sizes,
                    coloraxis = "coloraxis",
                    points_configuration = graph.configuration.points,
                    colors_title = graph.data.points_colors_title,
                    mask = mask,
                    legend_group = "points",
                ),
            )
        end
    end

    columns_names = graph.data.columns_names
    if columns_names === nothing
        columns_names = [string(index) for index in 1:n_columns]
    end
    rows_names = graph.data.rows_names
    if rows_names === nothing
        rows_names = [string(index) for index in 1:n_rows]
    end

    layout = points_layout(;
        data = graph.data,
        minimum_x = 0.5,
        minimum_y = 0.5,
        maximum_x = n_columns + 0.5,
        maximum_y = n_rows + 0.5,
        configuration = graph.configuration,
        x_axis_configuration = AxisConfiguration(),
        y_axis_configuration = AxisConfiguration(),
        rows_names = rows_names,
        columns_names = columns_names,
    )
    return plot(traces, layout)
end

function validate_graph(graph::PointsGraph)::Maybe{AbstractString}
    x_log_regularization = graph.configuration.x_axis.log_regularization
    if x_log_regularization !== nothing
        for (index, x) in enumerate(graph.data.points_xs)
            if x + x_log_regularization <= 0
                return "log of non-positive data.points_xs[$(index)]: $(x + x_log_regularization)"
            end
        end
    end

    y_log_regularization = graph.configuration.y_axis.log_regularization
    if y_log_regularization !== nothing
        for (index, y) in enumerate(graph.data.points_ys)
            if y + y_log_regularization <= 0
                return "log of non-positive data.points_ys[$(index)]: $(y + y_log_regularization)"
            end
        end
    end

    message = validate_vector_colors(
        "data.points_colors",
        graph.data.points_colors,
        "configuration.points",
        graph.configuration.points,
    )
    if message === nothing
        message = validate_vector_colors(
            "data.borders_colors",
            graph.data.borders_colors,
            "configuration.borders",
            graph.configuration.borders,
        )
    end

    return message
end

function validate_graph(graph::GridGraph)::Maybe{AbstractString}
    message = validate_matrix_colors(
        "data.points_colors",
        graph.data.points_colors,
        "configuration.points",
        graph.configuration.points,
    )
    if message === nothing
        message = validate_matrix_colors(
            "data.borders_colors",
            graph.data.borders_colors,
            "configuration.borders",
            graph.configuration.borders,
        )
    end
    return message
end

function validate_vector_colors(
    what_colors::AbstractString,
    colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}},
    what_configuration::AbstractString,
    configuration::PointsConfiguration,
)::Maybe{AbstractString}
    color_palette = configuration.color_palette
    if colors isa AbstractVector{<:AbstractString}
        if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            scale_colors = Set{AbstractString}([value for (value, _) in color_palette])
            for (index, color) in enumerate(colors)
                if color != "" && !(color in scale_colors)
                    return "categorical $(what_configuration).color_palette does not contain $(what_colors)[$(index)]: $(color)"
                end
            end
        else
            for (index, color) in enumerate(colors)
                if color != "" && !is_valid_color(color)
                    return "invalid $(what_colors)[$(index)]: $(color)"
                end
            end
        end
    elseif (color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}})
        return "non-string $(what_colors) for categorical $(what_configuration).color_palette"
    end

    if configuration.show_color_scale
        if colors === nothing
            return "no $(what_colors) specified for $(what_configuration).show_color_scale"
        end
        if colors isa AbstractVector{<:AbstractString} &&
           !(configuration.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}})
            return "explicit $(what_colors) specified for $(what_configuration).show_color_scale"
        end
    end

    if configuration.color_scale.log_regularization !== nothing
        if !(colors isa AbstractVector{<:Real})
            return "non-real $(what_colors) with $(what_configuration).color_scale.log_regularization"
        end
        index = argmin(colors)  # NOJET
        minimal_color = colors[index] + configuration.color_scale.log_regularization
        if minimal_color <= 0
            return "log of non-positive $(what_colors)[$(index)]: $(minimal_color)"
        end
    end

    return nothing
end

function validate_matrix_colors(
    what_colors::AbstractString,
    colors::Maybe{Union{AbstractMatrix{<:AbstractString}, AbstractMatrix{<:Real}}},
    what_configuration::AbstractString,
    configuration::PointsConfiguration,
)::Maybe{AbstractString}
    color_palette = configuration.color_palette
    if colors isa AbstractMatrix{<:AbstractString}
        n_rows, n_columns = size(colors)
        if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            scale_colors = Set{AbstractString}([value for (value, _) in color_palette])
            for row_index in 1:n_rows
                for column_index in 1:n_columns
                    color = colors[row_index, column_index]
                    if color != "" && !(color in scale_colors)
                        return "categorical $(what_configuration).color_palette does not contain $(what_colors)[$(row_index),$(column_index))]: $(color)"
                    end
                end
            end
        else
            for row_index in 1:n_rows
                for column_index in 1:n_columns
                    color = colors[row_index, column_index]
                    if color != "" && !is_valid_color(color)
                        return "invalid $(what_colors)[$(row_index),$(column_index)]: $(color)"
                    end
                end
            end
        end
    elseif color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        return "non-string $(what_colors) for categorical $(what_configuration).color_palette"
    end

    if configuration.show_color_scale
        if colors === nothing
            return "no $(what_colors) specified for $(what_configuration).show_color_scale"
        end
        if colors isa AbstractMatrix{<:AbstractString} &&
           !(configuration.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}})
            return "explicit $(what_colors) specified for $(what_configuration).show_color_scale"
        end
    end

    if configuration.color_scale.log_regularization !== nothing
        if !(colors isa AbstractMatrix{<:Real})
            return "non-real $(what_colors) with $(what_configuration).color_scale.log_regularization"
        end
        row_index, column_index = argmin(colors).I  # NOJET
        minimal_color = colors[row_index, column_index] + configuration.color_scale.log_regularization
        if minimal_color <= 0
            return "log of non-positive $(what_colors)[$(row_index),$(column_index)]: $(minimal_color)"
        end
    end

    return nothing
end

function grid_trace(;
    data::GridGraphData,
    n_rows::Integer,
    n_columns::Integer,
    color::Maybe{Union{AbstractString, AbstractMatrix{<:Union{<:AbstractString, Real}}}},
    marker_size::Maybe{Union{Real, AbstractVector{<:Real}}},
    coloraxis::Maybe{AbstractString},
    points_configuration::PointsConfiguration,
    colors_title::Maybe{AbstractString},
    legend_group::AbstractString,
    mask::Maybe{Union{Vector{Bool}, BitVector}} = nothing,
    name::Maybe{AbstractString} = nothing,
    is_first::Bool = true,
)::GenericTrace
    name = name !== nothing ? name : points_configuration.show_color_scale ? "Trace" : ""
    return scatter(;
        x = masked_xs(n_rows, n_columns, mask),
        y = masked_ys(n_rows, n_columns, mask),
        marker_size = masked_data(marker_size, mask),
        marker_color = color !== nothing ? masked_data(color, mask) : points_configuration.color,
        marker_colorscale = if points_configuration.color_palette isa AbstractVector ||
                               points_configuration.color_scale.log_regularization !== nothing
            nothing
        else
            points_configuration.color_palette
        end,
        marker_coloraxis = coloraxis,
        marker_showscale = points_configuration.show_color_scale && !(
            points_configuration.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        ),
        marker_reversescale = points_configuration.reverse_color_scale,
        showlegend = points_configuration.show_color_scale &&
                     points_configuration.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
        legendgroup = "$(legend_group) $(name)",
        legendgrouptitle_text = is_first ? colors_title : nothing,
        name = name,
        text = masked_data(data.points_hovers, mask),
        hovertemplate = data.points_hovers === nothing ? nothing : "%{text}<extra></extra>",
        mode = "markers",
    )
end

function masked_data(data::Any, ::Any)::Any
    return data
end

function masked_data(data::AbstractVector, mask::Union{AbstractVector{Bool}, BitVector})::AbstractVector
    return data[mask]  # NOJET
end

function masked_data(data::AbstractMatrix, mask::Union{AbstractVector{Bool}, BitVector})::AbstractVector
    return vec(data)[mask]  # NOJET
end

function masked_data(data::AbstractMatrix, ::Nothing)::AbstractVector
    return vec(data)
end

function masked_xs(
    n_rows::Integer,
    n_columns::Integer,
    mask::Maybe{Union{AbstractVector{Bool}, BitVector}},
)::Vector{Int}
    points_xs = Matrix{Int}(undef, n_rows, n_columns)
    points_xs .= transpose(1:n_columns)
    return masked_data(points_xs, mask)
end

function masked_ys(
    n_rows::Integer,
    n_columns::Integer,
    mask::Maybe{Union{AbstractVector{Bool}, BitVector}},
)::Vector{Int}
    points_ys = Matrix{Int}(undef, n_rows, n_columns)
    points_ys .= 1:n_rows
    return masked_data(points_ys, mask)
end

function points_layout(;
    data::Union{PointsGraphData, GridGraphData},
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
    configuration::Union{PointsGraphConfiguration, GridGraphConfiguration},
    x_axis_configuration::AxisConfiguration,
    y_axis_configuration::AxisConfiguration,
    rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
    columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
)::Layout
    color_tickvals, color_ticktext = log_color_scale_ticks(data.points_colors, configuration.points)
    border_color_tickvals, border_color_ticktext = log_color_scale_ticks(data.borders_colors, configuration.borders)
    x_tickvals, x_ticknames = xy_ticks(columns_names)
    y_tickvals, y_ticknames = xy_ticks(rows_names)

    if x_axis_configuration.log_regularization !== nothing
        minimum_x = log10(minimum_x)
        maximum_x = log10(maximum_x)
    end

    if y_axis_configuration.log_regularization !== nothing
        minimum_y = log10(minimum_y)
        maximum_y = log10(maximum_y)
    end

    return graph_layout(
        configuration.graph,
        Layout(;  # NOJET
            title = data.graph_title,
            xaxis_showgrid = configuration.graph.show_grid,
            xaxis_showticklabels = configuration.graph.show_ticks,
            xaxis_title = data.x_axis_title,
            xaxis_range = (
                x_axis_configuration.minimum !== nothing ? x_axis_configuration.minimum : minimum_x,
                x_axis_configuration.maximum !== nothing ? x_axis_configuration.maximum : maximum_x,
            ),
            xaxis_type = x_axis_configuration.log_regularization !== nothing ? "log" : nothing,
            xaxis_tickvals = x_tickvals,
            xaxis_ticktext = x_ticknames,
            yaxis_showgrid = configuration.graph.show_grid,
            yaxis_showticklabels = configuration.graph.show_ticks,
            yaxis_title = data.y_axis_title,
            yaxis_range = (
                y_axis_configuration.minimum !== nothing ? y_axis_configuration.minimum : minimum_y,
                y_axis_configuration.maximum !== nothing ? y_axis_configuration.maximum : maximum_y,
            ),
            yaxis_type = y_axis_configuration.log_regularization !== nothing ? "log" : nothing,
            yaxis_tickvals = y_tickvals,
            yaxis_ticktext = y_ticknames,
            showlegend = (
                configuration.points.show_color_scale &&
                configuration.points.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            ) || (
                configuration.borders.show_color_scale &&
                configuration.borders.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            ),
            legend_tracegroupgap = 0,
            legend_itemdoubleclick = false,
            legend_x = if configuration.points.show_color_scale &&
                          configuration.borders.show_color_scale &&
                          configuration.borders.color_palette isa
                          AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
                1.2
            else
                nothing
            end,
            coloraxis2_colorbar_x = if (
                configuration.borders.show_color_scale && configuration.points.show_color_scale
            )
                1.2
            else
                nothing  # NOJET
            end,
            coloraxis_showscale = configuration.points.show_color_scale && !(
                configuration.points.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            ),
            coloraxis_reversescale = configuration.points.reverse_color_scale,
            coloraxis_colorscale = normalized_color_palette(
                configuration.points.color_palette,
                configuration.points.color_scale,
            ),
            coloraxis_cmin = lowest_color(
                configuration.points.color_palette,
                configuration.points.color_scale.minimum,
                configuration.points.color_scale.log_regularization,
            ),
            coloraxis_cmax = highest_color(
                configuration.points.color_palette,
                configuration.points.color_scale.maximum,
                configuration.points.color_scale.log_regularization,
            ),
            coloraxis_colorbar_title_text = data.points_colors_title,
            coloraxis_colorbar_tickvals = color_tickvals,
            coloraxis_colorbar_ticktext = color_ticktext,
            coloraxis2_showscale = (data.borders_colors !== nothing || data.borders_sizes !== nothing) &&
                                   configuration.borders.show_color_scale &&
                                   !(
                                       configuration.borders.color_palette isa
                                       AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
                                   ),
            coloraxis2_reversescale = configuration.borders.reverse_color_scale,
            coloraxis2_colorscale = normalized_color_palette(
                configuration.borders.color_palette,
                configuration.borders.color_scale,
            ),
            coloraxis2_cmin = lowest_color(
                configuration.borders.color_palette,
                configuration.borders.color_scale.minimum,
                configuration.borders.color_scale.log_regularization,
            ),
            coloraxis2_cmax = highest_color(
                configuration.borders.color_palette,
                configuration.borders.color_scale.maximum,
                configuration.borders.color_scale.log_regularization,
            ),
            coloraxis2_colorbar_title_text = data.borders_colors_title,
            coloraxis2_colorbar_tickvals = border_color_tickvals,
            coloraxis2_colorbar_ticktext = border_color_ticktext,
        ),
    )
end

function border_marker_size(
    data::Union{PointsGraphData, GridGraphData},
    configuration::Union{PointsGraphConfiguration, GridGraphConfiguration},
    sizes::Maybe{Union{Real, AbstractVector{<:Real}}},
)::Union{Real, Vector{<:Real}}
    sizes = sizes
    borders_sizes = fix_sizes(data.borders_sizes, configuration.borders)

    if borders_sizes === nothing
        border_marker_size = configuration.borders.size !== nothing ? configuration.borders.size : 4.0
        @assert border_marker_size !== nothing
        if sizes === nothing
            points_marker_size = configuration.points.size !== nothing ? configuration.points.size : 4.0
            return points_marker_size + 2 * border_marker_size
        else
            return sizes .+ 2 * border_marker_size
        end
    else
        if sizes === nothing
            points_marker_size = configuration.points.size !== nothing ? configuration.points.size : 4.0
            return 2 .* borders_sizes .+ points_marker_size
        else
            return 2 .* borders_sizes .+ sizes
        end
    end
end

function fix_sizes(
    sizes::Maybe{Union{AbstractVector{<:Real}, AbstractMatrix{<:Real}}},
    points_configuration::PointsConfiguration,
)::Maybe{Union{Real, Vector{<:Real}}}
    if sizes === nothing
        return points_configuration.size
    end

    sizes = vec(sizes)

    smallest = points_configuration.size_range.smallest
    largest = points_configuration.size_range.largest
    log_regularization = points_configuration.size_scale.log_regularization
    if smallest === nothing && largest === nothing && log_regularization === nothing
        return sizes
    end

    smin =
        points_configuration.size_scale.minimum !== nothing ? points_configuration.size_scale.minimum : minimum(sizes)
    smax =
        points_configuration.size_scale.maximum !== nothing ? points_configuration.size_scale.maximum : maximum(sizes)

    if log_regularization !== nothing
        smin = log10(smin + log_regularization)
        smax = log10(smax + log_regularization)
        sizes = log10.(sizes .+ log_regularization)
    end

    if smallest === nothing
        smallest = 2.0
    end
    if largest === nothing
        largest = smallest + 8.0
    end

    return (sizes .- smin) .* (largest - smallest) ./ (smax - smin) .+ smallest
end

function range_of(;
    values::AbstractVector{<:AbstractVector{<:Real}},
    log_regularization::Maybe{Real},
    apply_log::Bool,
)::Tuple{Real, Real}
    minimum_value = minimum([minimum(vector) for vector in values])
    maximum_value = maximum([maximum(vector) for vector in values])
    if log_regularization !== nothing
        minimum_value = log10(minimum_value + log_regularization)
        maximum_value = log10(maximum_value + log_regularization)
    end
    margin_value = (maximum_value - minimum_value) / 20.0
    minimum_value -= margin_value
    maximum_value += margin_value
    if log_regularization !== nothing && !apply_log
        minimum_value = 10^minimum_value
        maximum_value = 10^maximum_value
    end
    return (minimum_value, maximum_value)
end

function graph_layout(configuration::GraphConfiguration, layout::Layout)::Layout
    if configuration.template !== nothing
        layout["template"] = configuration.template
    end
    if configuration.width !== nothing
        layout["width"] = configuration.width
    end
    if configuration.height !== nothing
        layout["height"] = configuration.height
    end
    return layout
end

end  # module
