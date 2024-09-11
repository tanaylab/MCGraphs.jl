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
export AnnotationData
export AxisConfiguration
export BandConfiguration
export BandsConfiguration
export BarGraph
export BarGraphConfiguration
export BarGraphData
export BarsGraph
export BarsGraphConfiguration
export BarsGraphData
export CategoricalColors
export CdfDirection
export CdfDownToValue
export CdfGraph
export CdfGraphConfiguration
export CdfGraphData
export CdfUpToValue
export CdfsGraph
export CdfsGraphConfiguration
export CdfsGraphData
export ColorsConfiguration
export ContinuousColors
export DistributionConfiguration
export DistributionGraph
export DistributionGraphConfiguration
export DistributionGraphData
export DistributionsGraph
export DistributionsGraphConfiguration
export DistributionsGraphData
export FigureConfiguration
export Graph
export GridGraph
export GridGraphConfiguration
export GridGraphData
export HeatmapGraph
export HeatmapGraphConfiguration
export HeatmapGraphData
export HorizontalValues
export LineConfiguration
export LineGraph
export LineGraphConfiguration
export LineGraphData
export LinesGraph
export LinesGraphConfiguration
export LinesGraphData
export Log10Scale
export Log2Scale
export LogScale
export NAMED_COLOR_PALETTES
export PlotlyFigure
export PointsConfiguration
export PointsGraph
export PointsGraphConfiguration
export PointsGraphData
export SizeRangeConfiguration
export StackFractions
export StackValues
export Stacking
export ValuesOrientation
export VerticalValues
export bar_graph
export bars_graph
export cdf_graph
export cdfs_graph
export distribution_graph
export distributions_graph
export graph_to_figure
export grid_graph
export heatmap_graph
export line_graph
export lines_graph
export points_graph
export save_graph

using ..Validations

using Base.Multimedia
using Colors
using Daf
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

Accessing the `.figure` property of the graph will return it as a `PlotlyFigure`, which can be displayed in interactive
environments (Julia REPL and/or Jupyter notebooks). You should call [`save_graph`](@ref) to save the graph to a file
(instead of calling `savefig` on the `.figure`).

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

function Base.show(io::IO, graph::Graph)::Nothing
    print(io, "$(typeof(graph)) (use .figure to show the graph)")
    return nothing
end

function Base.getproperty(graph::Graph, property::Symbol)::Any
    if property == :figure
        return graph_to_figure(graph)
    else
        return getfield(graph, property)
    end
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
        width = graph.configuration.figure.width,
        height = graph.configuration.figure.height,
    )
    return nothing
end

"""
    graph_to_figure(graph::Graph)::PlotlyFigure

Render a graph given its data and configuration. Technically this just converts the graph to a [`PlotlyFigure`](@ref)
which Julia knows how display for us, rather than actually display the graph. The implementation depends on the specific
graph type.

You can just write `graph.figure` instead of `graph_to_figure(graph)`.

!!! note

    When saving a figure to a file, Plotly in its infinite wisdom ignores the graph `width` and `height` specified
    inside the figure, (except for saving HTML file). You should therefore use [`save_graph`](@ref) rather than call
    `savefig` on the result of `graph_to_figure`.
"""
function graph_to_figure end

"""
The orientation of the values axis in a distribution or bars graph:

`HorizontalValues` - The values are the X axis

`VerticalValues` - The values are the Y axis (the default).
"""
@enum ValuesOrientation HorizontalValues VerticalValues

"""
    @kwdef mutable struct MarginsConfiguration
        left::Int = 50
        bottom::Int = 50
        right::Int = 50
        top::Int = 50
    end

Configure the margins of the graph. Sizes are in pixels (1/96th of an inch).
"""
@kwdef mutable struct MarginsConfiguration
    left::Int = 50
    bottom::Int = 50
    right::Int = 50
    top::Int = 50
end

function validate_margins_configuration(margins_configuration::MarginsConfiguration)::Maybe{AbstractString}
    if margins_configuration.left < 0
        return "negative configuration.figure.margins.left: $(margins_configuration.left)"
    end
    if margins_configuration.right < 0
        return "negative configuration.figure.margins.right: $(margins_configuration.right)"
    end
    if margins_configuration.bottom < 0
        return "negative configuration.figure.margins.bottom: $(margins_configuration.bottom)"
    end
    if margins_configuration.top < 0
        return "negative configuration.figure.margins.top: $(margins_configuration.top)"
    end
    return nothing
end

"""
    @kwdef mutable struct FigureConfiguration
        width::Maybe{Int} = nothing
        height::Maybe{Int} = nothing
        template::AbstractString = "simple_white"
        show_grid::Bool = true
        show_ticks::Bool = true
    end

Generic configuration that applies to the whole figure. Each complete [`AbstractGraphConfiguration`](@ref) contains a
`figure` field of this type.

The optional `width` and `height` are in pixels, that is, 1/96 of an inch. Due to Plotly limitations, you may have to
adjust the `margins` to ensure tick labels will fit inside the graph.

By default, `show_grid` and `show_ticks` are set.

The default `template` is "simple_white" which is the cleanest. The `show_grid` and `show_ticks` can be used to disable
the grid and/or ticks for an even cleaner (but less informative) look.
"""
@kwdef mutable struct FigureConfiguration
    margins::MarginsConfiguration = MarginsConfiguration()
    width::Maybe{Int} = nothing
    height::Maybe{Int} = nothing
    template::AbstractString = "simple_white"
    show_grid::Bool = true
    show_ticks::Bool = true
end

function validate_graph_configuration(graph_configuration::FigureConfiguration)::Maybe{AbstractString}
    message = validate_margins_configuration(graph_configuration.margins)
    if message !== nothing
        return message
    end

    width = graph_configuration.width
    if width !== nothing && width <= 0
        return "non-positive configuration.figure.width: $(width)"
    end

    height = graph_configuration.height
    if height !== nothing && height <= 0
        return "non-positive configuration.figure.height: $(height)"
    end

    return nothing
end

"""
Supported log scales:

  - `Log10Scale` uses Plotly's log (base 10) scale, so while the coordinates are in log scale, the ticks display the
    original values.

  - `Log2Scale` converts values to their log (base 2). Unlike `Log10Scale`, both the coordinates and the ticks show the
    log of the original values.
"""
@enum LogScale Log10Scale Log2Scale

"""
    @kwdef mutable struct AxisConfiguration
        minimum::Maybe{Real} = nothing
        maximum::Maybe{Real} = nothing
        log_scale::Maybe{LogScale} = nothing
        log_regularization::Real = 0
        percent::Bool = false
    end

Generic configuration for a graph axis. Everything is optional; by default, the `minimum` and `maximum` are computed
automatically from the data.

If `log_scale` is specified, then the `log_regularization` is added to the coordinate to avoid zero values, and the axis
is shown according to the [`LogScale`](@ref).

If `percent` is set, then the values are multiplied by 100 and a `%` suffix is added.
"""
@kwdef mutable struct AxisConfiguration
    minimum::Maybe{Real} = nothing
    maximum::Maybe{Real} = nothing
    log_scale::Maybe{LogScale} = nothing
    log_regularization::Real = 0
    percent::Bool = false
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
    if axis_configuration.log_scale === nothing
        if log_regularization != 0
            return "linear non-zero configuration.$(of_what)$(of_which).log_regularization: $(log_regularization)"
        end

    else
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
        values_orientation::ValuesOrientation = HorizontalValues
        show_box::Bool = false
        show_violin::Bool = false
        show_curve::Bool = true
        show_outliers::Bool = false
        color::Maybe{AbstractString} = nothing
    end

Configure the style of a distribution graph.

The `values_orientation` controls which axis is used for the values (the other axis is used for the density). By default
the values are shown on the Y axis (vertical values).

If `show_box`, show a box graph.

If `show_violin`, show a violin graph.

If `show_curve`, show a density curve. This is the default.

You can combine the above; however, a density curve is just the positive side of a violin graph, so you can't combine
the two.

In addition to the (combination) of the above, if `show_outliers`, also show the extreme (outlier) points.

The `color` is chosen automatically by default. When showing multiple distributions, you can override it per each one in
the [`DistributionsGraphData`](@ref).
"""
@kwdef mutable struct DistributionConfiguration
    values_orientation::ValuesOrientation = HorizontalValues
    show_box::Bool = false
    show_violin::Bool = false
    show_curve::Bool = true
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
        figure::FigureConfiguration = FigureConfiguration()
        distribution::DistributionConfiguration = DistributionConfiguration(show_curve = false, show_box = true)
        value_axis::AxisConfiguration = AxisConfiguration()
    end

Configure a graph for showing a distribution (with [`DistributionGraphData`](@ref)) or several distributions (with
[`DistributionsGraphData`](@ref)).

The optional `color` will be chosen automatically if not specified. When showing multiple distributions, it is also
possible to specify the color of each one in the [`DistributionsGraphData`](@ref).
"""
@kwdef mutable struct DistributionGraphConfiguration <: AbstractGraphConfiguration
    figure::FigureConfiguration = FigureConfiguration()
    distribution::DistributionConfiguration = DistributionConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
end

function Validations.validate_object(configuration::DistributionGraphConfiguration)::Maybe{AbstractString}
    message = validate_graph_configuration(configuration.figure)
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
        figure::FigureConfiguration = FigureConfiguration()
        distribution::DistributionConfiguration = DistributionConfiguration(show_curve = false, show_box = true)
        value_axis::AxisConfiguration = AxisConfiguration()
        show_legend::Bool = false
        distributions_gap::Maybe{Real} = nothing
        overlay_distributions::Bool = false
    end

Configure a graph for showing several distributions several distributions.

By defaults, we show box plots when visualizing multiple distributions.

This is identical to [`DistributionGraphConfiguration`](@ref) with the addition of `show_legend` to show a legend. This
is not set by default as it makes little sense unless `overlay_distributions` is also set. The `distributions_gap` is
the fraction of white space between the distributions.

!!! note

    Specifying a `distributions_gap` will end badly if using `show_curve` because Plotly.
"""
@kwdef mutable struct DistributionsGraphConfiguration <: AbstractGraphConfiguration
    figure::FigureConfiguration = FigureConfiguration()
    distribution::DistributionConfiguration = DistributionConfiguration(; show_curve = false, show_box = true)
    value_axis::AxisConfiguration = AxisConfiguration()
    show_legend::Bool = false
    distributions_gap::Maybe{Real} = nothing
    overlay_distributions::Bool = false
end

function Validations.validate_object(configuration::DistributionsGraphConfiguration)::Maybe{AbstractString}
    message = validate_graph_configuration(configuration.figure)
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
        figure_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        trace_axis_title::Maybe{AbstractString} = nothing
        distribution_values::AbstractVector{<:Real} = Float32[]
        distribution_name::Maybe{AbstractString} = nothing
    end

By default, all the titles are empty. You can specify the overall `figure_title` as well as the `value_axis_title` and
the `trace_axis_title`. The optional `distribution_name` is used as the tick value for the distribution.
"""
@kwdef mutable struct DistributionGraphData <: AbstractGraphData
    figure_title::Maybe{AbstractString} = nothing
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
        figure_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        trace_axis_title::Maybe{AbstractString} = nothing
        legend_title::Maybe{AbstractString} = nothing
        distributions_values::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[]
        distributions_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        distributions_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
    end

The data for a multiple distributions graph. By default, all the titles are empty. You can specify the overall
`figure_title` as well as the `value_axis_title`, the `trace_axis_title` and the `legend_title` (if `show_legend` is
set). If specified, the `distributions_names` and/or the `distributions_colors` vectors must contain the same number of
elements as the number of vectors in the `distributions_values`.
"""
@kwdef mutable struct DistributionsGraphData <: AbstractGraphData
    figure_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    trace_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    distributions_values::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[]
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
    function distribution_graph(;
        [figure_title::Maybe{AbstractString} = nothing,
        value_axis_title::Maybe{AbstractString} = nothing,
        trace_axis_title::Maybe{AbstractString} = nothing,
        distribution_values::AbstractVector{<:Real} = Float32[],
        distribution_name::Maybe{AbstractString} = nothing],
    )::DistributionGraph

Create a [`DistributionGraph`](@ref) by initializing only the [`DistributionGraphData`](@ref) fields.
"""
function distribution_graph(;
    figure_title::Maybe{AbstractString} = nothing,
    value_axis_title::Maybe{AbstractString} = nothing,
    trace_axis_title::Maybe{AbstractString} = nothing,
    distribution_values::AbstractVector{<:Real} = Float32[],
    distribution_name::Maybe{AbstractString} = nothing,
)::DistributionGraph
    return DistributionGraph(
        DistributionGraphData(;
            figure_title = figure_title,
            value_axis_title = value_axis_title,
            trace_axis_title = trace_axis_title,
            distribution_values = distribution_values,
            distribution_name = distribution_name,
        ),
        DistributionGraphConfiguration(),
    )
end

"""
A graph for visualizing multiple distributions. See [`DistributionsGraphData`](@ref) and
[`DistributionsGraphConfiguration`](@ref).
"""
DistributionsGraph = Graph{DistributionsGraphData, DistributionsGraphConfiguration}

"""
    function distributions_graph(;
        [figure_title::Maybe{AbstractString} = nothing,
        value_axis_title::Maybe{AbstractString} = nothing,
        trace_axis_title::Maybe{AbstractString} = nothing,
        legend_title::Maybe{AbstractString} = nothing,
        distributions_values::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[],
        distributions_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
        distributions_colors::Maybe{AbstractVector{<:AbstractString}} = nothing],
    )::DistributionsGraph

Create a [`DistributionsGraph`](@ref) by initializing only the [`DistributionsGraphData`](@ref) fields.
"""
function distributions_graph(;
    figure_title::Maybe{AbstractString} = nothing,
    value_axis_title::Maybe{AbstractString} = nothing,
    trace_axis_title::Maybe{AbstractString} = nothing,
    legend_title::Maybe{AbstractString} = nothing,
    distributions_values::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[],
    distributions_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
    distributions_colors::Maybe{AbstractVector{<:AbstractString}} = nothing,
)::DistributionsGraph
    return DistributionsGraph(
        DistributionsGraphData(;
            figure_title = figure_title,
            value_axis_title = value_axis_title,
            trace_axis_title = trace_axis_title,
            legend_title = legend_title,
            distributions_values = distributions_values,
            distributions_names = distributions_names,
            distributions_colors = distributions_colors,
        ),
        DistributionsGraphConfiguration(),
    )
end

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

    return plotly_figure(trace, layout)
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

    return plotly_figure(traces, layout)
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
        y = scale_values(distribution_values, configuration.value_axis)
        x0 = overlay_distributions ? " " : nothing
        y0 = nothing
    elseif configuration.distribution.values_orientation == HorizontalValues
        x = scale_values(distribution_values, configuration.value_axis)
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
        xaxis_tickprefix = nothing
        xaxis_ticksuffix = nothing
        xaxis_zeroline = nothing

        yaxis_showticklabels = graph.configuration.figure.show_ticks
        yaxis_showgrid = graph.configuration.figure.show_grid
        yaxis_title = graph.data.value_axis_title
        yaxis_range = (graph.configuration.value_axis.minimum, graph.configuration.value_axis.maximum)
        yaxis_type = graph.configuration.value_axis.log_scale == Log10Scale ? "log" : nothing
        yaxis_tickprefix = graph.configuration.value_axis.log_scale == Log2Scale ? "<sub>2</sub>" : nothing
        yaxis_ticksuffix = graph.configuration.value_axis.percent ? "<sub>%</sub>" : nothing
        yaxis_zeroline = graph.configuration.value_axis.log_scale === nothing ? nothing : false

    elseif graph.configuration.distribution.values_orientation == HorizontalValues
        xaxis_showticklabels = graph.configuration.figure.show_ticks
        xaxis_showgrid = graph.configuration.figure.show_grid
        xaxis_title = graph.data.value_axis_title
        xaxis_range = (graph.configuration.value_axis.minimum, graph.configuration.value_axis.maximum)
        xaxis_type = graph.configuration.value_axis.log_scale == Log10Scale ? "log" : nothing
        xaxis_tickprefix = graph.configuration.value_axis.log_scale == Log2Scale ? "<sub>2</sub>" : nothing
        xaxis_ticksuffix = graph.configuration.value_axis.percent ? "<sub>%</sub>" : nothing
        xaxis_zeroline = graph.configuration.value_axis.log_scale === nothing ? nothing : false

        yaxis_showticklabels = has_tick_names
        yaxis_showgrid = false
        yaxis_title = graph.data.trace_axis_title
        yaxis_range = (nothing, nothing)
        yaxis_type = nothing
        yaxis_tickprefix = nothing
        yaxis_ticksuffix = nothing
        yaxis_zeroline = nothing
    else
        @assert false
    end

    return graph_layout(
        graph.configuration.figure,
        Layout(;  # NOJET
            title = graph.data.figure_title,
            xaxis_showgrid = xaxis_showgrid,
            xaxis_showticklabels = xaxis_showticklabels,
            xaxis_title = xaxis_title,
            xaxis_range = xaxis_range,
            xaxis_type = xaxis_type,
            xaxis_tickprefix = xaxis_tickprefix,
            xaxis_ticksuffix = xaxis_ticksuffix,
            xaxis_zeroline = xaxis_zeroline,
            yaxis_showgrid = yaxis_showgrid,
            yaxis_showticklabels = yaxis_showticklabels,
            yaxis_title = yaxis_title,
            yaxis_range = yaxis_range,
            yaxis_type = yaxis_type,
            yaxis_tickprefix = yaxis_tickprefix,
            yaxis_ticksuffix = yaxis_ticksuffix,
            yaxis_zeroline = yaxis_zeroline,
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
        width::Maybe{Real} = 1
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
    width::Maybe{Real} = 1
    is_dashed::Bool = false
    is_filled::Bool = false
end

function validate_band_configuration(
    of_what::AbstractString,
    of_which::AbstractString,
    band_configuration::BandConfiguration,
    axis_configuration::AxisConfiguration,
)::Maybe{AbstractString}
    if band_configuration.width !== nothing && band_configuration.width <= 0
        return "non-positive configuration.$(of_what).$(of_which).width: $(band_configuration.width)"
    end
    if axis_configuration.log_scale !== nothing &&
       band_configuration.offset !== nothing &&
       band_configuration.offset <= 0
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
    axis_configuration::AxisConfiguration,
)::Maybe{AbstractString}
    message = validate_band_configuration(of_what, "low", bands_configuration.low, axis_configuration)
    if message === nothing
        message = validate_band_configuration(of_what, "middle", bands_configuration.middle, axis_configuration)
    end
    if message === nothing
        message = validate_band_configuration(of_what, "high", bands_configuration.high, axis_configuration)
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
        figure::FigureConfiguration = FigureConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        line::LineConfiguration = LineConfiguration()
        vertical_bands::BandsConfiguration = BandsConfiguration()
        horizontal_bands::BandsConfiguration = BandsConfiguration()
    end

Configure a graph for showing line plots.
"""
@kwdef mutable struct LineGraphConfiguration <: AbstractGraphConfiguration
    figure::FigureConfiguration = FigureConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    line::LineConfiguration = LineConfiguration()
    vertical_bands::BandsConfiguration = BandsConfiguration()
    horizontal_bands::BandsConfiguration = BandsConfiguration()
end

"""
    @kwdef mutable struct LineGraphData <: AbstractGraphData
        figure_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        vertical_bands::BandsData = BandsData()
        horizontal_bands::BandsData = BandsData()
        points_xs::AbstractVector{<:Real} = Float32[]
        points_ys::AbstractVector{<:Real} = Float32[]
    end

The data for a line graph.

By default, all the titles are empty. You can specify the overall `figure_title` as well as the `x_axis_title` and
`y_axis_title` for the axes.

The `points_xs` and `points_ys` vectors must be of the same size. A line will be drawn through all the points, and the
area under the line may be filled.
"""
@kwdef mutable struct LineGraphData <: AbstractGraphData
    figure_title::Maybe{AbstractString} = nothing
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

"""
    function line_graph(;
        [figure_title::Maybe{AbstractString} = nothing,
        x_axis_title::Maybe{AbstractString} = nothing,
        y_axis_title::Maybe{AbstractString} = nothing,
        vertical_bands::BandsData = BandsData(),
        horizontal_bands::BandsData = BandsData(),
        points_xs::AbstractVector{<:Real} = Float32[],
        points_ys::AbstractVector{<:Real} = Float32[]],
    )::LineGraph

Create a [`LineGraph`](@ref) by initializing only the [`LineGraphData`](@ref) fields.
"""
function line_graph(;
    figure_title::Maybe{AbstractString} = nothing,
    x_axis_title::Maybe{AbstractString} = nothing,
    y_axis_title::Maybe{AbstractString} = nothing,
    vertical_bands::BandsData = BandsData(),
    horizontal_bands::BandsData = BandsData(),
    points_xs::AbstractVector{<:Real} = Float32[],
    points_ys::AbstractVector{<:Real} = Float32[],
)::LineGraph
    return LineGraph(
        LineGraphData(;
            figure_title = figure_title,
            x_axis_title = x_axis_title,
            y_axis_title = y_axis_title,
            vertical_bands = vertical_bands,
            horizontal_bands = horizontal_bands,
            points_xs = points_xs,
            points_ys = points_ys,
        ),
        LineGraphConfiguration(),
    )
end

function graph_to_figure(graph::LineGraph)::PlotlyFigure
    assert_valid_object(graph)

    traces = Vector{GenericTrace}()

    minimum_x, maximum_x = range_of([graph.data.points_xs], graph.configuration.x_axis)
    minimum_y, maximum_y = range_of([graph.data.points_ys], graph.configuration.y_axis)

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
        percent = graph.configuration.x_axis.percent,
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
        percent = graph.configuration.y_axis.percent,
    )

    push!(traces, line_trace(graph.data, graph.configuration))

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
                    percent = graph.configuration.x_axis.percent,
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
                    percent = graph.configuration.y_axis.percent,
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

    return plotly_figure(traces, layout)
end

function line_trace(data::LineGraphData, configuration::LineGraphConfiguration)::GenericTrace
    return scatter(;
        x = scale_values(data.points_xs, configuration.x_axis),
        y = scale_values(data.points_ys, configuration.y_axis),
        line_color = configuration.line.color,
        line_width = configuration.line.width === nothing ? 0 : configuration.line.width,
        line_dash = configuration.line.is_dashed ? "dash" : nothing,
        fill = configuration.line.is_filled ? "tozeroy" : nothing,
        showlegend = false,
        name = "",
        mode = "lines",
    )
end

"""
If stacking elements, how to do so:

`StackValues` just adds the raw values on top of each other.

`StackFractions` normalizes the values so their sum is 1. This can be combined with setting the `percent` field of the
relevant [`AxisConfiguration`](@ref) to display percents.
"""
@enum Stacking StackValues StackFractions

"""
    @kwdef mutable struct LinesGraphConfiguration <: AbstractGraphConfiguration
        figure::FigureConfiguration = FigureConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        line::LineConfiguration = LineConfiguration()
        vertical_bands::BandsConfiguration = BandsConfiguration()
        horizontal_bands::BandsConfiguration = BandsConfiguration()
        show_legend::Bool = false
        stacking::Maybe{Stacking} = nothing
    end

Configure a graph for showing multiple line plots. This allows using `show_legend` to display a legend of the different
lines. If `stacking` is set, then `is_filled` is implied, regardless of what its actual setting is.
"""
@kwdef mutable struct LinesGraphConfiguration <: AbstractGraphConfiguration
    figure::FigureConfiguration = FigureConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    line::LineConfiguration = LineConfiguration()
    vertical_bands::BandsConfiguration = BandsConfiguration()
    horizontal_bands::BandsConfiguration = BandsConfiguration()
    show_legend::Bool = false
    stacking::Maybe{Stacking} = nothing
end

function Validations.validate_object(
    configuration::Union{LineGraphConfiguration, LinesGraphConfiguration},
)::Maybe{AbstractString}
    if configuration isa LinesGraphConfiguration &&
       configuration.stacking !== nothing &&
       configuration.y_axis.log_scale !== nothing
        return "log of stacked data"
    end
    message = validate_graph_configuration(configuration.figure)
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
        message = validate_bands_configuration("vertical_bands", configuration.vertical_bands, configuration.x_axis)
    end
    if message === nothing
        message = validate_bands_configuration("horizontal_bands", configuration.horizontal_bands, configuration.y_axis)
    end
    return message
end

"""
    @kwdef mutable struct LinesGraphData <: AbstractGraphData
        figure_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        legend_title::Maybe{AbstractString} = nothing
        vertical_bands::BandsData = BandsData()
        horizontal_bands::BandsData = BandsData()
        lines_xs::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[]
        lines_ys::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[]
        lines_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        lines_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
        lines_widths::Maybe{AbstractVector{<:Real}} = nothing
        lines_are_filled::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing
        lines_are_dashed::Maybe{AbstractVector{Bool}} = nothing
    end

The data for multiple lines graph.

By default, all the titles are empty. You can specify the overall `figure_title` as well as the `x_axis_title` and
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
    figure_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    vertical_bands::BandsData = BandsData()
    horizontal_bands::BandsData = BandsData()
    lines_xs::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[]
    lines_ys::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[]
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

"""
    function lines_graph(;
        [figure_title::Maybe{AbstractString} = nothing,
        x_axis_title::Maybe{AbstractString} = nothing,
        y_axis_title::Maybe{AbstractString} = nothing,
        legend_title::Maybe{AbstractString} = nothing,
        vertical_bands::BandsData = BandsData(),
        horizontal_bands::BandsData = BandsData(),
        lines_xs::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[],
        lines_ys::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[],
        lines_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
        lines_colors::Maybe{AbstractVector{<:AbstractString}} = nothing,
        lines_widths::Maybe{AbstractVector{<:Real}} = nothing,
        lines_are_filled::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing,
        lines_are_dashed::Maybe{AbstractVector{Bool}} = nothing],
    )::LinesGraph

Create a [`LinesGraph`](@ref) by initializing only the [`LinesGraphData`](@ref) fields.
"""
function lines_graph(;
    figure_title::Maybe{AbstractString} = nothing,
    x_axis_title::Maybe{AbstractString} = nothing,
    y_axis_title::Maybe{AbstractString} = nothing,
    legend_title::Maybe{AbstractString} = nothing,
    vertical_bands::BandsData = BandsData(),
    horizontal_bands::BandsData = BandsData(),
    lines_xs::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[],
    lines_ys::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[],
    lines_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
    lines_colors::Maybe{AbstractVector{<:AbstractString}} = nothing,
    lines_widths::Maybe{AbstractVector{<:Real}} = nothing,
    lines_are_filled::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing,
    lines_are_dashed::Maybe{AbstractVector{Bool}} = nothing,
)::LinesGraph
    return LinesGraph(
        LinesGraphData(;
            figure_title = figure_title,
            x_axis_title = x_axis_title,
            y_axis_title = y_axis_title,
            legend_title = legend_title,
            vertical_bands = vertical_bands,
            horizontal_bands = horizontal_bands,
            lines_xs = lines_xs,
            lines_ys = lines_ys,
            lines_names = lines_names,
            lines_colors = lines_colors,
            lines_widths = lines_widths,
            lines_are_filled = lines_are_filled,
            lines_are_dashed = lines_are_dashed,
        ),
        LinesGraphConfiguration(),
    )
end

function graph_to_figure(graph::LinesGraph)::PlotlyFigure
    assert_valid_object(graph)

    if graph.configuration.stacking == StackFractions
        for (line_index, points_ys) in enumerate(graph.data.lines_ys)
            for (point_index, point_y) in enumerate(points_ys)
                @assert point_y >= 0 "negative normalized stacked fraction/percent data.lines_ys[$(line_index),$(point_index)]: $(point_y)"
            end
        end
    end

    if graph.configuration.stacking === nothing
        lines_xs = graph.data.lines_xs
        lines_ys = graph.data.lines_ys
    else
        lines_xs, lines_ys, minimum_y, maximum_y = unify_xs(graph.data.lines_xs, graph.data.lines_ys)
    end

    traces = Vector{GenericTrace}()

    minimum_x, maximum_x = range_of(lines_xs, graph.configuration.x_axis)

    if graph.configuration.stacking === nothing
        minimum_y, maximum_y = range_of(lines_ys, graph.configuration.y_axis)
    elseif graph.configuration.stacking == StackFractions
        if graph.configuration.y_axis.percent
            minimum_y, maximum_y = -5, 105
        else
            minimum_y, maximum_y = -0.05, 1.05
        end
    elseif graph.configuration.stacking == StackValues
        minimum_y = scale_percent(graph.configuration.y_axis.percent, minimum_y)
        maximum_y = scale_percent(graph.configuration.y_axis.percent, maximum_y)
    else
        @assert false
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
        percent = graph.configuration.x_axis.percent,
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
        percent = graph.configuration.y_axis.percent,
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
                    percent = graph.configuration.x_axis.percent,
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
                    percent = graph.configuration.y_axis.percent,
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

    return plotly_figure(traces, layout)
end

function unify_xs(
    lines_xs::AbstractVector{<:AbstractVector{<:Real}},
    lines_ys::AbstractVector{<:AbstractVector{<:Real}},
)::Tuple{Vector{Vector{Float32}}, Vector{Vector{Float32}}, Float32, Float32}
    minimum_y = 0
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
            margin = (maximum_y - minimum_y) * 0.05
            return (unified_xs, unified_ys, minimum_y - margin, maximum_y + margin)
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
                    minimum_y = min(minimum_y, last_y)
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
                    minimum_y = min(minimum_y, last_y)
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
        x = scale_values(points_xs, graph.configuration.x_axis),
        y = scale_values(points_ys, graph.configuration.y_axis),
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
        stackgroup = graph.configuration.stacking === nothing ? nothing : "stacked",
        groupnorm = if graph.configuration.stacking != StackFractions
            nothing
        elseif graph.configuration.y_axis.percent
            "percent"
        else
            "fraction"
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
        graph.configuration.figure,
        Layout(;  # NOJET
            title = graph.data.figure_title,
            xaxis_showgrid = graph.configuration.figure.show_grid,
            xaxis_showticklabels = graph.configuration.figure.show_ticks,
            xaxis_title = graph.data.x_axis_title,
            xaxis_range = scale_range(
                x_axis.minimum !== nothing ? x_axis.minimum : minimum_x,
                x_axis.maximum !== nothing ? x_axis.maximum : maximum_x,
                x_axis,
            ),
            xaxis_type = x_axis.log_scale == Log10Scale ? "log" : nothing,
            xaxis_ticksuffix = graph.configuration.x_axis.percent ? "<sub>%</sub>" : nothing,
            xaxis_tickprefix = graph.configuration.x_axis.log_scale == Log2Scale ? "<sub>2</sub>" : nothing,
            xaxis_zeroline = graph.configuration.x_axis.log_scale === nothing ? nothing : false,
            yaxis_showgrid = graph.configuration.figure.show_grid,
            yaxis_showticklabels = graph.configuration.figure.show_ticks,
            yaxis_title = graph.data.y_axis_title,
            yaxis_range = scale_range(
                y_axis.minimum !== nothing ? y_axis.minimum : minimum_y,
                y_axis.maximum !== nothing ? y_axis.maximum : maximum_y,
                y_axis,
            ),
            yaxis_type = y_axis.log_scale == Log10Scale ? "log" : nothing,
            yaxis_ticksuffix = graph.configuration.y_axis.percent ? "<sub>%</sub>" : nothing,
            yaxis_tickprefix = graph.configuration.y_axis.log_scale == Log2Scale ? "<sub>2</sub>" : nothing,
            yaxis_zeroline = graph.configuration.y_axis.log_scale === nothing ? nothing : false,
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
        figure::FigureConfiguration = FigureConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        fraction_axis::AxisConfiguration = AxisConfiguration()
        normalize::Bool = true,
        line::LineConfiguration = LineConfiguration()
        values_orientation::ValuesOrientation = HorizontalValues
        cdf_direction::CdfDirection = CdfUpToValue
        value_bands::BandsConfiguration = BandsConfiguration()
        fraction_bands::BandsConfiguration = BandsConfiguration()
    end

Configure a graph for showing a CDF (Cumulative Distribution Function) graph. By default, the X axis is used for the
values and the Y axis for the fraction; this can be switched using the `values_orientation`. By default, the fraction is
of the values up to each value; this can be switched using the `cdf_direction`.

If `normalize`, we scale everything to be between zero and one. The `fraction_bands` offset is always given
as a fraction between zero and one, to allow for easily switching the normalization on and off without worrying about
the band offset.

CDF graphs are internally converted to line graphs for rendering.
"""
@kwdef mutable struct CdfGraphConfiguration <: AbstractGraphConfiguration
    figure::FigureConfiguration = FigureConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    fraction_axis::AxisConfiguration = AxisConfiguration()
    normalize::Bool = true
    line::LineConfiguration = LineConfiguration()
    values_orientation::ValuesOrientation = HorizontalValues
    cdf_direction::CdfDirection = CdfUpToValue
    value_bands::BandsConfiguration = BandsConfiguration()
    fraction_bands::BandsConfiguration = BandsConfiguration()
end

"""
    @kwdef mutable struct CdfGraphData <: AbstractGraphData
        figure_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        fraction_axis_title::Maybe{AbstractString} = nothing
        cdf_values::AbstractVector{<:Real} = Float32[]
    end

The data for a CDF (Cumulative Distribution Function) graph.

By default, all the titles are empty. You can specify the overall `figure_title` as well as the `value_axis_title` and
`fraction_axis_title` for the axes.

The order of the `line_values` does not matter.
"""
@kwdef mutable struct CdfGraphData <: AbstractGraphData
    figure_title::Maybe{AbstractString} = nothing
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

"""
    function cdf_graph(;
        [figure_title::Maybe{AbstractString} = nothing,
        value_axis_title::Maybe{AbstractString} = nothing,
        fraction_axis_title::Maybe{AbstractString} = nothing,
        value_bands::BandsData = BandsData(),
        fraction_bands::BandsData = BandsData(),
        cdf_values::AbstractVector{<:Real} = Float32[]],
    )::CdfGraph

Create a [`CdfGraph`](@ref) by initializing only the [`CdfGraphData`](@ref) fields.
"""
function cdf_graph(;
    figure_title::Maybe{AbstractString} = nothing,
    value_axis_title::Maybe{AbstractString} = nothing,
    fraction_axis_title::Maybe{AbstractString} = nothing,
    value_bands::BandsData = BandsData(),
    fraction_bands::BandsData = BandsData(),
    cdf_values::AbstractVector{<:Real} = Float32[],
)::CdfGraph
    return CdfGraph(
        CdfGraphData(;
            figure_title = figure_title,
            value_axis_title = value_axis_title,
            fraction_axis_title = fraction_axis_title,
            value_bands = value_bands,
            fraction_bands = fraction_bands,
            cdf_values = cdf_values,
        ),
        CdfGraphConfiguration(),
    )
end

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
            figure_title = graph.data.figure_title,
            x_axis_title = graph.data.value_axis_title,
            y_axis_title = graph.data.fraction_axis_title,
            vertical_bands = graph.data.value_bands,
            horizontal_bands = graph.data.fraction_bands,
            points_xs = values,
            points_ys = fractions,
        )
    else
        return LineGraphData(;
            figure_title = graph.data.figure_title,
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
            figure = graph.configuration.figure,
            x_axis = graph.configuration.value_axis,
            y_axis = graph.configuration.fraction_axis,
            line = graph.configuration.line,
            vertical_bands = graph.configuration.value_bands,
            horizontal_bands = normalized_bands(
                graph.configuration.fraction_bands,
                graph.configuration.normalize,
                length(graph.data.cdf_values),
            ),
        )
    else
        return LineGraphConfiguration(;
            figure = graph.configuration.figure,
            x_axis = graph.configuration.fraction_axis,
            y_axis = graph.configuration.value_axis,
            line = graph.configuration.line,
            vertical_bands = normalized_bands(
                graph.configuration.fraction_bands,
                graph.configuration.normalize,
                length(graph.data.cdf_values),
            ),
            horizontal_bands = graph.configuration.value_bands,
        )
    end
end

function normalized_bands(
    bands_configuration::BandsConfiguration,
    normalize::Bool,
    n_values::Integer,
)::BandsConfiguration
    return BandsConfiguration(;
        low = normalized_band(bands_configuration.low, normalize, n_values),
        middle = normalized_band(bands_configuration.middle, normalize, n_values),
        high = normalized_band(bands_configuration.high, normalize, n_values),
        show_legend = bands_configuration.show_legend,
    )
end

function normalized_band(band_configuration::BandConfiguration, normalize::Bool, n_values::Integer)::BandConfiguration
    if band_configuration.offset === nothing
        offset = band_configuration.offset
    elseif normalize
        offset = band_configuration.offset
    else
        offset = band_configuration.offset * n_values
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
        figure::FigureConfiguration = FigureConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        fraction_axis::AxisConfiguration = AxisConfiguration()
        normalize::Bool = true
        line::LineConfiguration = LineConfiguration()
        values_orientation::ValuesOrientation = HorizontalValues
        cdf_direction::CdfDirection = CdfUpToValue
        value_bands::BandsConfiguration = BandsConfiguration()
        fraction_bands::BandsConfiguration = BandsConfiguration()
        show_legend::Bool = false
    end

Configure a graph for showing multiple CDF (Cumulative Distribution Function) graph. This is the same as
[`CdfGraphConfiguration`](@ref) with the addition of a `show_legend` field.

If not `normalize`, then the number of values in all the `cdfs_values` vectors must be the same.

CDF graphs are internally converted to line graphs for rendering.
"""
@kwdef mutable struct CdfsGraphConfiguration <: AbstractGraphConfiguration
    figure::FigureConfiguration = FigureConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    fraction_axis::AxisConfiguration = AxisConfiguration()
    normalize::Bool = true
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
    if !configuration.normalize && configuration.fraction_axis.percent
        return "percent of non-normalized fractions"
    end
    message = validate_graph_configuration(configuration.figure)
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
        message = validate_bands_configuration("value_bands", configuration.value_bands, configuration.value_axis)
    end
    if message === nothing
        message =
            validate_bands_configuration("fraction_bands", configuration.fraction_bands, configuration.fraction_axis)
    end
    return message
end

"""
    @kwdef mutable struct CdfsGraphData <: AbstractGraphData
        figure_title::Maybe{AbstractString} = nothing
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

By default, all the titles are empty. You can specify the overall `figure_title` as well as the `value_axis_title` and
`fraction_axis_title` for the axes.

The order of the entries inside each of the `cdfs_values` does not matter.
"""
@kwdef mutable struct CdfsGraphData <: AbstractGraphData
    figure_title::Maybe{AbstractString} = nothing
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

"""
    function cdfs_graph(;
        [figure_title::Maybe{AbstractString} = nothing,
        value_axis_title::Maybe{AbstractString} = nothing,
        fraction_axis_title::Maybe{AbstractString} = nothing,
        legend_title::Maybe{AbstractString} = nothing,
        cdfs_values::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[],
        cdfs_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
        cdfs_colors::Maybe{AbstractVector{<:AbstractString}} = nothing,
        cdfs_widths::Maybe{AbstractVector{<:Real}} = nothing,
        cdfs_are_filled::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing,
        cdfs_are_dashed::Maybe{AbstractVector{Bool}} = nothing],
    )::CdfsGraph

Create a [`CdfsGraph`](@ref) by initializing only the [`CdfsGraphData`](@ref) fields.
"""
function cdfs_graph(;
    figure_title::Maybe{AbstractString} = nothing,
    value_axis_title::Maybe{AbstractString} = nothing,
    fraction_axis_title::Maybe{AbstractString} = nothing,
    legend_title::Maybe{AbstractString} = nothing,
    cdfs_values::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[],
    cdfs_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
    cdfs_colors::Maybe{AbstractVector{<:AbstractString}} = nothing,
    cdfs_widths::Maybe{AbstractVector{<:Real}} = nothing,
    cdfs_are_filled::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing,
    cdfs_are_dashed::Maybe{AbstractVector{Bool}} = nothing,
)::CdfsGraph
    return CdfsGraph(
        CdfsGraphData(;
            figure_title = figure_title,
            value_axis_title = value_axis_title,
            fraction_axis_title = fraction_axis_title,
            legend_title = legend_title,
            cdfs_values = cdfs_values,
            cdfs_names = cdfs_names,
            cdfs_colors = cdfs_colors,
            cdfs_widths = cdfs_widths,
            cdfs_are_filled = cdfs_are_filled,
            cdfs_are_dashed = cdfs_are_dashed,
        ),
        CdfsGraphConfiguration(),
    )
end

function validate_graph(graph::CdfsGraph)::Maybe{AbstractString}
    if !graph.configuration.normalize
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
            figure_title = graph.data.figure_title,
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
            figure_title = graph.data.figure_title,
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

    if configuration.normalize
        fractions ./= n_values
    end

    return (sorted_values, fractions)
end

function cdfs_configuration_as_lines_configuration(graph::CdfsGraph)::LinesGraphConfiguration
    if graph.configuration.values_orientation == HorizontalValues
        return LinesGraphConfiguration(;
            figure = graph.configuration.figure,
            x_axis = graph.configuration.value_axis,
            y_axis = graph.configuration.fraction_axis,
            line = graph.configuration.line,
            vertical_bands = graph.configuration.value_bands,
            horizontal_bands = normalized_bands(
                graph.configuration.fraction_bands,
                graph.configuration.normalize,
                length(graph.data.cdfs_values[1]),
            ),
            show_legend = graph.configuration.show_legend,
        )
    else
        return LinesGraphConfiguration(;
            figure = graph.configuration.figure,
            x_axis = graph.configuration.fraction_axis,
            y_axis = graph.configuration.value_axis,
            line = graph.configuration.line,
            vertical_bands = normalized_bands(
                graph.configuration.fraction_bands,
                graph.configuration.normalize,
                length(graph.data.cdfs_values[1]),
            ),
            horizontal_bands = graph.configuration.value_bands,
            show_legend = graph.configuration.show_legend,
        )
    end
end

"""
    @kwdef mutable struct BarGraphConfiguration <: AbstractGraphConfiguration
        figure::FigureConfiguration = FigureConfiguration()
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
    figure::FigureConfiguration = FigureConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    values_orientation::ValuesOrientation = VerticalValues
    bars_color::Maybe{AbstractString} = nothing
    bars_gap::Maybe{Real} = nothing
end

"""
    @kwdef mutable struct BarGraphData <: AbstractGraphData
        figure_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        bar_axis_title::Maybe{AbstractString} = nothing
        bars_values::AbstractVector{<:Real} = Float32[]
        bars_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        bars_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
        bars_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
    end

The data for a single bar (histogram) graph.

By default, all the titles are empty. You can specify the overall `figure_title` as well as the `value_axis_title` and
`bar_axis_title` for the axes.

If specified, the `bars_names` and/or `bars_colors` and/or `bars_hovers` vectors must contain the same number of
elements as the number of `bars_values`.
"""
@kwdef mutable struct BarGraphData <: AbstractGraphData
    figure_title::Maybe{AbstractString} = nothing
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

"""
    function bar_graph(;
        [figure_title::Maybe{AbstractString} = nothing,
        value_axis_title::Maybe{AbstractString} = nothing,
        bar_axis_title::Maybe{AbstractString} = nothing,
        bars_values::AbstractVector{<:Real} = Float32[],
        bars_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
        bars_colors::Maybe{AbstractVector{<:AbstractString}} = nothing,
        bars_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing],
    )::BarGraph

Create a [`BarGraph`](@ref) by initializing only the [`BarGraphData`](@ref) fields.
"""
function bar_graph(;
    figure_title::Maybe{AbstractString} = nothing,
    value_axis_title::Maybe{AbstractString} = nothing,
    bar_axis_title::Maybe{AbstractString} = nothing,
    bars_values::AbstractVector{<:Real} = Float32[],
    bars_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
    bars_colors::Maybe{AbstractVector{<:AbstractString}} = nothing,
    bars_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing,
)::BarGraph
    return BarGraph(
        BarGraphData(;
            figure_title = figure_title,
            value_axis_title = value_axis_title,
            bar_axis_title = bar_axis_title,
            bars_values = bars_values,
            bars_names = bars_names,
            bars_colors = bars_colors,
            bars_hovers = bars_hovers,
        ),
        BarGraphConfiguration(),
    )
end

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

    return plotly_figure(trace, layout)
end

"""
    @kwdef mutable struct BarsGraphConfiguration <: AbstractGraphConfiguration
        figure::FigureConfiguration = FigureConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        values_orientation::ValuesOrientation = VerticalValues
        bars_gap::Maybe{Real} = nothing
        show_legend::Bool = false
        stacking::Maybe{Stacking} = nothing
    end

Configure a graph for showing multiple bars (histograms) graph. This is similar to [`BarGraphConfiguration`](@ref),
without the `color` field (which makes no sense when multiple series are shown), and with the addition of a
`show_legend` and `stacking` fields similar to [`LinesGraphConfiguration`](@ref).
"""
@kwdef mutable struct BarsGraphConfiguration <: AbstractGraphConfiguration
    figure::FigureConfiguration = FigureConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    values_orientation::ValuesOrientation = VerticalValues
    bars_gap::Maybe{Real} = nothing
    show_legend::Bool = false
    stacking::Maybe{Stacking} = nothing
end

function Validations.validate_object(
    configuration::Union{BarGraphConfiguration, BarsGraphConfiguration},
)::Maybe{AbstractString}
    if configuration isa BarsGraphConfiguration &&
       configuration.stacking !== nothing &&
       configuration.value_axis.log_scale !== nothing
        return "log of stacked data"
    end
    message = validate_graph_configuration(configuration.figure)
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
        figure_title::Maybe{AbstractString} = nothing
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

The data for a multiple bars (histograms) graph.

By default, all the titles are empty. You can specify the overall `figure_title` as well as the `value_axis_title`,
`bar_axis_title` for the axes, and the `legend_title` (if `show_legend` is set in [`BarsGraphConfiguration`](@ref).

All the `series_values` vectors must be of the same size. If specified, the `series_names` and `series_colors` vectors
must contain the same number of elements. If specified, the `bars_names` and/or `bars_hovers` vectors must contain the
same number of elements in the each of the `series_values` vectors.
"""
@kwdef mutable struct BarsGraphData <: AbstractGraphData
    figure_title::Maybe{AbstractString} = nothing
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

"""
    function bars_graph(;
        [figure_title::Maybe{AbstractString} = nothing,
        value_axis_title::Maybe{AbstractString} = nothing,
        bar_axis_title::Maybe{AbstractString} = nothing,
        legend_title::Maybe{AbstractString} = nothing,
        series_values::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[],
        series_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
        series_colors::Maybe{AbstractVector{<:AbstractString}} = nothing,
        series_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing,
        bars_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing,
        bars_names::Maybe{AbstractVector{<:AbstractString}} = nothing],
    )::BarsGraph

Create a [`BarsGraph`](@ref) by initializing only the [`BarsGraphData`](@ref) fields.
"""
function bars_graph(;
    figure_title::Maybe{AbstractString} = nothing,
    value_axis_title::Maybe{AbstractString} = nothing,
    bar_axis_title::Maybe{AbstractString} = nothing,
    legend_title::Maybe{AbstractString} = nothing,
    series_values::AbstractVector{<:AbstractVector{<:Real}} = Vector{Float32}[],
    series_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
    series_colors::Maybe{AbstractVector{<:AbstractString}} = nothing,
    series_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing,
    bars_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing,
    bars_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
)::BarsGraph
    return BarsGraph(
        BarsGraphData(;
            figure_title = figure_title,
            value_axis_title = value_axis_title,
            bar_axis_title = bar_axis_title,
            legend_title = legend_title,
            series_values = series_values,
            series_names = series_names,
            series_colors = series_colors,
            series_hovers = series_hovers,
            bars_hovers = bars_hovers,
            bars_names = bars_names,
        ),
        BarsGraphConfiguration(),
    )
end

function graph_to_figure(graph::BarsGraph)::PlotlyFigure
    assert_valid_object(graph)

    if graph.configuration.stacking === nothing
        series_values = graph.data.series_values
    else
        for (series_index, bars_values) in enumerate(graph.data.series_values)
            for (bar_index, value) in enumerate(bars_values)
                @assert value >= 0 "negative stacked data.series_values[$(series_index),$(bar_index)]: $(value)"
            end
        end
        series_values =
            stacked_values(graph.data.series_values; normalize = graph.configuration.stacking == StackFractions)
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
                        (graph.data.series_hovers[index] * "<br>") .* graph.data.bars_hovers  # NOJET
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
        stacking = graph.configuration.stacking,
    )

    return plotly_figure(traces, layout)
end

function stacked_values(series_values::T; normalize::Bool)::T where {(T <: AbstractVector{<:AbstractVector{<:Real}})}
    if !normalize
        return series_values
    end

    total_values = zeros(eltype(eltype(series_values)), length(series_values[1]))
    for bars_values in series_values
        total_values .+= bars_values
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
        xs = scale_values(values, configuration.value_axis)
        ys = names !== nothing ? names : ["Bar $(index)" for index in 1:length(values)]
        orientation = "h"
    elseif configuration.values_orientation == VerticalValues
        xs = names !== nothing ? names : ["Bar $(index)" for index in 1:length(values)]
        ys = scale_values(values, configuration.value_axis)
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
    stacking::Maybe{Stacking} = nothing,
)::Layout
    if graph.configuration.values_orientation == HorizontalValues
        xaxis_showgrid = graph.configuration.figure.show_grid
        xaxis_showticklabels = graph.configuration.figure.show_ticks
        xaxis_title = graph.data.value_axis_title
        xaxis_range = scale_range(
            graph.configuration.value_axis.minimum,
            graph.configuration.value_axis.maximum,
            graph.configuration.value_axis,
        )
        xaxis_type = graph.configuration.value_axis.log_scale == Log10Scale ? "log" : nothing
        xaxis_tickprefix = graph.configuration.value_axis.log_scale == Log2Scale ? "<sub>2</sub>" : nothing
        xaxis_ticksuffix = graph.configuration.value_axis.percent ? "<sub>%</sub>" : nothing
        xaxis_zeroline = graph.configuration.value_axis.log_scale === nothing ? nothing : false

        yaxis_showgrid = false
        yaxis_showticklabels = has_tick_names
        yaxis_title = graph.data.bar_axis_title
        yaxis_range = nothing
        yaxis_type = nothing
        yaxis_tickprefix = nothing
        yaxis_ticksuffix = nothing
        yaxis_zeroline = nothing
    elseif graph.configuration.values_orientation == VerticalValues
        xaxis_showgrid = false
        xaxis_showticklabels = has_tick_names
        xaxis_title = graph.data.bar_axis_title
        xaxis_range = nothing
        xaxis_type = nothing
        xaxis_tickprefix = nothing
        xaxis_ticksuffix = nothing
        xaxis_zeroline = nothing

        yaxis_showgrid = graph.configuration.figure.show_grid
        yaxis_showticklabels = graph.configuration.figure.show_ticks
        yaxis_title = graph.data.value_axis_title
        yaxis_range = scale_range(
            graph.configuration.value_axis.minimum,
            graph.configuration.value_axis.maximum,
            graph.configuration.value_axis,
        )
        yaxis_type = graph.configuration.value_axis.log_scale == Log10Scale ? "log" : nothing
        yaxis_tickprefix = graph.configuration.value_axis.log_scale == Log2Scale ? "<sub>2</sub>" : nothing
        yaxis_ticksuffix = graph.configuration.value_axis.percent ? "<sub>%</sub>" : nothing
        yaxis_zeroline = graph.configuration.value_axis.log_scale === nothing ? nothing : false
    else
        @assert false
    end

    return graph_layout(
        graph.configuration.figure,
        Layout(;  # NOJET
            title = graph.data.figure_title,
            xaxis_showgrid = xaxis_showgrid,
            xaxis_showticklabels = xaxis_showticklabels,
            xaxis_title = xaxis_title,
            xaxis_range = xaxis_range,
            xaxis_type = xaxis_type,
            xaxis_tickprefix = xaxis_tickprefix,
            xaxis_ticksuffix = xaxis_ticksuffix,
            xaxis_zeroline = xaxis_zeroline,
            yaxis_showgrid = yaxis_showgrid,
            yaxis_showticklabels = yaxis_showticklabels,
            yaxis_title = yaxis_title,
            yaxis_range = yaxis_range,
            yaxis_type = yaxis_type,
            yaxis_tickprefix = yaxis_tickprefix,
            yaxis_ticksuffix = yaxis_ticksuffix,
            yaxis_zeroline = yaxis_zeroline,
            showlegend = show_legend,
            legend_tracegroupgap = 0,
            legend_itemdoubleclick = false,
            barmode = stacking === nothing ? nothing : "stack",
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
A continuous colors palette, mapping numeric values to colors. We also allow specifying tuples instead of pairs to make
it easy to invoke the API from other languages such as Python which do not have the concept of a `Pair`.
"""
ContinuousColors =
    Union{AbstractVector{<:Pair{<:Real, <:AbstractString}}, AbstractVector{<:Tuple{<:Real, <:AbstractString}}}

"""
A categorical colors palette, mapping string values to colors. We also allow specifying tuples instead of pairs to make
it easy to invoke the API from other languages such as Python which do not have the concept of a `Pair`.
"""
CategoricalColors = Union{
    AbstractVector{<:Pair{<:AbstractString, <:AbstractString}},
    AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
}

"""
    @kwdef mutable struct ColorsConfiguration
        show_legend::Bool = false
        color_axis::AxisConfiguration = AxisConfiguration()
        reverse::Bool = false
        colors_palette::Maybe{Union{QueryString, AbstractString, ContinuousColors, CategoricalColors}} = nothing
    end

Configure how to color some values. The `colors_palette` is applied; this can be the name of a standard [Plotly
palette](https://plotly.com/python/builtin-colorscales/), a vector of (value, color) tuples for a continuous (numeric
value) scale or categorical (string value) scales. The `color_axis` and `reverse` can also be used to tweak the colors.
If `show_legend` is set, then the colors will be shown (in the legend or as a color bar, as appropriate).

For sizes, the `size_range` is applied.

!!! note

    Trying to directly render a [`Query`](@ref) `colors_palette` will fail. Specifying a query for the palette is only
    supported when passing [`AnnotationData`](@ref) parameter(s) to a data extraction function (that also has access to
    a `Daf` data set to fetch the data from). In such functions, if the `colors_palette` is a string, then it is
    interpreted as a pallete name if it consists of a simple name, and a query otherwise.
"""
@kwdef mutable struct ColorsConfiguration
    show_legend::Bool = false
    color_axis::AxisConfiguration = AxisConfiguration()
    reverse::Bool = false
    colors_palette::Maybe{Union{QueryString, AbstractString, ContinuousColors, CategoricalColors}} = nothing
end

function continuous_colors(colors::AbstractVector{<:AbstractString})::ContinuousColors
    size = length(colors)
    return [((index - 1) / (size - 1)) => color for (index, color) in enumerate(colors)]
end

"""
Builtin color palattes from [Plotly](https://plotly.com/python/builtin-colorscales/), both linear: `Blackbody`,
`Bluered`, `Blues`, `Cividis`, `Earth`, `Electric`, `Greens`, `Greys`, `Hot`, `Jet`, `Picnic`, `Portland`, `Rainbow`,
`RdBu`, `Reds`, `Viridis`, `YlGnBu`, `YlOrRd` and cyclical: `Twilight`, `IceFire`, `Edge`, `Phase`, `HSV`, `mrybm`,
`mygbm`.

The `_r` (reversed) variants are not included as explicit entries in the dictionary; they are computed on-the-fly if
used.

!!! note

    You would think we could just give the builtin color palette names to plotly, but it turns out that "builtin" in
    Python plotly doesn't mean "builtin" in JavaScript plotly because "reasons". We therefore have to copy their
    definition here. An upside of having this dictionary is that you are free to insert additional named palettes into
    and gain the convenience of refering to them by name (e.g., for coloring heatmap annotations).
"""
NAMED_COLOR_PALETTES = Dict{String, ContinuousColors}([
    "Twilight" => continuous_colors([
        "#e2d9e2",
        "#9ebbc9",
        "#6785be",
        "#5e43a5",
        "#421257",
        "#471340",
        "#8e2c50",
        "#ba6657",
        "#ceac94",
        "#e2d9e2",
    ]),
    "IceFire" => continuous_colors([
        "#000000",
        "#001f4d",
        "#003786",
        "#0e58a8",
        "#217eb8",
        "#30a4ca",
        "#54c8df",
        "#9be4ef",
        "#e1e9d1",
        "#f3d573",
        "#e7b000",
        "#da8200",
        "#c65400",
        "#ac2301",
        "#820000",
        "#4c0000",
        "#000000",
    ]),
    "Edge" => continuous_colors([
        "#313131",
        "#3d019d",
        "#3810dc",
        "#2d47f9",
        "#2593ff",
        "#2adef6",
        "#60fdfa",
        "#aefdff",
        "#f3f3f1",
        "#fffda9",
        "#fafd5b",
        "#f7da29",
        "#ff8e25",
        "#f8432d",
        "#d90d39",
        "#97023d",
        "#313131",
    ]),
    "Phase" => continuous_colors([
        "rgb(167, 119, 12)",
        "rgb(197, 96, 51)",
        "rgb(217, 67, 96)",
        "rgb(221, 38, 163)",
        "rgb(196, 59, 224)",
        "rgb(153, 97, 244)",
        "rgb(95, 127, 228)",
        "rgb(40, 144, 183)",
        "rgb(15, 151, 136)",
        "rgb(39, 153, 79)",
        "rgb(119, 141, 17)",
        "rgb(167, 119, 12)",
    ]),
    "HSV" => continuous_colors([
        "#ff0000",
        "#ffa700",
        "#afff00",
        "#08ff00",
        "#00ff9f",
        "#00b7ff",
        "#0010ff",
        "#9700ff",
        "#ff00bf",
        "#ff0000",
    ]),
    "mrybm" => continuous_colors([
        "#f884f7",
        "#f968c4",
        "#ea4388",
        "#cf244b",
        "#b51a15",
        "#bd4304",
        "#cc6904",
        "#d58f04",
        "#cfaa27",
        "#a19f62",
        "#588a93",
        "#2269c4",
        "#3e3ef0",
        "#6b4ef9",
        "#956bfa",
        "#cd7dfe",
        "#f884f7",
    ]),
    "mygbm" => continuous_colors([
        "#ef55f1",
        "#fb84ce",
        "#fbafa1",
        "#fcd471",
        "#f0ed35",
        "#c6e516",
        "#96d310",
        "#61c10b",
        "#31ac28",
        "#439064",
        "#3d719a",
        "#284ec8",
        "#2e21ea",
        "#6324f5",
        "#9139fa",
        "#c543fa",
        "#ef55f1",
    ]),
    "Blackbody" =>
        continuous_colors(["rgb(0,0,0)", "rgb(230,0,0)", "rgb(230,210,0)", "rgb(255,255,255)", "rgb(160,200,255)"]),
    "Bluered" => continuous_colors(["rgb(0,0,255)", "rgb(255,0,0)"]),
    "Blues" => continuous_colors([
        "rgb(5,10,172)",
        "rgb(40,60,190)",
        "rgb(70,100,245)",
        "rgb(90,120,245)",
        "rgb(106,137,247)",
        "rgb(220,220,220)",
    ]),
    "Cividis" => continuous_colors([
        "rgb(0,32,76)",
        "rgb(0,42,102)",
        "rgb(0,52,110)",
        "rgb(39,63,108)",
        "rgb(60,74,107)",
        "rgb(76,85,107)",
        "rgb(91,95,109)",
        "rgb(104,106,112)",
        "rgb(117,117,117)",
        "rgb(131,129,120)",
        "rgb(146,140,120)",
        "rgb(161,152,118)",
        "rgb(176,165,114)",
        "rgb(192,177,109)",
        "rgb(209,191,102)",
        "rgb(225,204,92)",
        "rgb(243,219,79)",
        "rgb(255,233,69)",
    ]),
    "Earth" => continuous_colors([
        "rgb(0,0,130)",
        "rgb(0,180,180)",
        "rgb(40,210,40)",
        "rgb(230,230,50)",
        "rgb(120,70,20)",
        "rgb(255,255,255)",
    ]),
    "Electric" => continuous_colors([
        "rgb(0,0,0)",
        "rgb(30,0,100)",
        "rgb(120,0,100)",
        "rgb(160,90,0)",
        "rgb(230,200,0)",
        "rgb(255,250,220)",
    ]),
    "Greens" => continuous_colors([
        "rgb(0,68,27)",
        "rgb(0,109,44)",
        "rgb(35,139,69)",
        "rgb(65,171,93)",
        "rgb(116,196,118)",
        "rgb(161,217,155)",
        "rgb(199,233,192)",
        "rgb(229,245,224)",
        "rgb(247,252,245)",
    ]),
    "Greys" => continuous_colors(["rgb(0,0,0)", "rgb(255,255,255)"]),
    "Hot" => continuous_colors(["rgb(0,0,0)", "rgb(230,0,0)", "rgb(255,210,0)", "rgb(255,255,255)"]),
    "Jet" => continuous_colors([
        "rgb(0,0,131)",
        "rgb(0,60,170)",
        "rgb(5,255,255)",
        "rgb(255,255,0)",
        "rgb(250,0,0)",
        "rgb(128,0,0)",
    ]),
    "Picnic" => continuous_colors([
        "rgb(0,0,255)",
        "rgb(51,153,255)",
        "rgb(102,204,255)",
        "rgb(153,204,255)",
        "rgb(204,204,255)",
        "rgb(255,255,255)",
        "rgb(255,204,255)",
        "rgb(255,153,255)",
        "rgb(255,102,204)",
        "rgb(255,102,102)",
        "rgb(255,0,0)",
    ]),
    "Portland" => continuous_colors([
        "rgb(12,51,131)",
        "rgb(10,136,186)",
        "rgb(242,211,56)",
        "rgb(242,143,56)",
        "rgb(217,30,30)",
    ]),
    "Rainbow" => continuous_colors([
        "rgb(150,0,90)",
        "rgb(0,0,200)",
        "rgb(0,25,255)",
        "rgb(0,152,255)",
        "rgb(44,255,150)",
        "rgb(151,255,0)",
        "rgb(255,234,0)",
        "rgb(255,111,0)",
        "rgb(255,0,0)",
    ]),
    "RdBu" => continuous_colors([
        "rgb(5,10,172)",
        "rgb(106,137,247)",
        "rgb(190,190,190)",
        "rgb(220,170,132)",
        "rgb(230,145,90)",
        "rgb(178,10,28)",
    ]),
    "Reds" => continuous_colors(["rgb(220,220,220)", "rgb(245,195,157)", "rgb(245,160,105)", "rgb(178,10,28)"]),
    "Viridis" => continuous_colors([
        "#440154",
        "#48186a",
        "#472d7b",
        "#424086",
        "#3b528b",
        "#33638d",
        "#2c728e",
        "#26828e",
        "#21918c",
        "#1fa088",
        "#28ae80",
        "#3fbc73",
        "#5ec962",
        "#84d44b",
        "#addc30",
        "#d8e219",
        "#fde725",
    ]),
    "YlGnBu" => continuous_colors([
        "rgb(8,29,88)",
        "rgb(37,52,148)",
        "rgb(34,94,168)",
        "rgb(29,145,192)",
        "rgb(65,182,196)",
        "rgb(127,205,187)",
        "rgb(199,233,180)",
        "rgb(237,248,217)",
        "rgb(255,255,217)",
    ]),
    "YlOrRd" => continuous_colors([
        "rgb(128,0,38)",
        "rgb(189,0,38)",
        "rgb(227,26,28)",
        "rgb(252,78,42)",
        "rgb(253,141,60)",
        "rgb(254,178,76)",
        "rgb(254,217,118)",
        "rgb(255,237,160)",
        "rgb(255,255,204)",
    ]),
])

function validate_colors_configuration(
    of_what::AbstractString,
    colors_configuration::ColorsConfiguration,
)::Maybe{AbstractString}
    @assert !colors_configuration.color_axis.percent "not implemented: $(of_what).colors_configuration.color_axis.percent"

    message = validate_axis_configuration(of_what, ".colors_configuration.color_axis", colors_configuration.color_axis)
    if message !== nothing
        return message
    end

    if colors_configuration.color_axis.log_scale !== nothing && colors_configuration.reverse
        return "reversed log configuration.$(of_what).colors_configuration.color_axis"
    end

    colors_palette = colors_configuration.colors_palette
    if colors_palette isa Query
        return "invalid (query) configuration.$(of_what).colors_configuration.colors_palette: $(colors_palette)"
    end

    if colors_palette isa AbstractString
        if endswith(colors_palette, "_r")
            named_palette = get(NAMED_COLOR_PALETTES, colors_palette[1:(end - 2)], nothing)
        else
            named_palette = get(NAMED_COLOR_PALETTES, colors_palette, nothing)
        end
        if named_palette === nothing
            return "invalid configuration.$(of_what).colors_configuration.colors_palette: $(colors_palette)"
        end
        colors_palette = named_palette
    elseif colors_palette isa AbstractVector
        if length(colors_palette) == 0
            return "empty configuration.$(of_what).colors_configuration.colors_palette"
        end
        for (index, (_, color)) in enumerate(colors_palette)
            if color != "" && !is_valid_color(color)
                return "invalid configuration.$(of_what).colors_configuration.colors_palette[$(index)] color: $(color)"
            end
        end
        if eltype(colors_palette) <: Union{Pair{<:Real, <:AbstractString}, Tuple{<:Real, <:AbstractString}}
            cmin = minimum([value for (value, _) in colors_palette])
            cmax = maximum([value for (value, _) in colors_palette])
            if cmin == cmax
                return "single configuration.$(of_what).colors_configuration.colors_palette value: $(cmax)"
            end
            log_colors_axis_regularization = colors_configuration.color_axis.log_regularization
            if colors_configuration.color_axis.log_scale !== nothing && cmin + log_colors_axis_regularization <= 0
                index = argmin(colors_palette)  # NOJET
                return "log of non-positive configuration.$(of_what).colors_configuration.colors_palette[$(index)]: $(cmin + log_colors_axis_regularization)"
            end
        elseif colors_configuration.reverse
            return "reversed categorical configuration.$(of_what).colors_configuration.colors_palette"
        end
    end

    return nothing
end

"""
    @kwdef mutable struct PointsConfiguration
        color::Maybe{AbstractString} = nothing
        colors_configuration::ColorsConfiguration = ColorsConfiguration(),
        size::Maybe{Real} = nothing
        size_axis::AxisConfiguration = AxisConfiguration()
        size_range::SizeRangeConfiguration = SizeRangeConfiguration()
    end

Configure points in a graph. By default, the point `color` and `size` is chosen automatically (when this is applied to
edges, the `size` is the width of the line). You can override this by specifying colors and/or sizes in the
[`PointsGraphData`](@ref).

For color values, the `colors_configuration` is applied.

If `size_axis` and/or `size_range` are specified, they are used to control the conversion of the data sizes
to pixel sizes.
"""
@kwdef mutable struct PointsConfiguration
    color::Maybe{AbstractString} = nothing
    colors_configuration::ColorsConfiguration = ColorsConfiguration()
    size::Maybe{Real} = nothing
    size_axis::AxisConfiguration = AxisConfiguration()
    size_range::SizeRangeConfiguration = SizeRangeConfiguration()
end

function validate_points_configuration(
    of_what::AbstractString,
    points_configuration::PointsConfiguration,
)::Maybe{AbstractString}
    message = validate_colors_configuration(of_what, points_configuration.colors_configuration)
    if message === nothing
        message = validate_axis_configuration(of_what, ".size_axis", points_configuration.size_axis)
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

    if !is_valid_color(points_configuration.color)
        return "invalid configuration.$(of_what).color: $(points_configuration.color)"
    end

    return nothing
end

"""
    @kwdef mutable struct PointsGraphConfiguration <: AbstractGraphConfiguration
        figure::FigureConfiguration = FigureConfiguration()
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

    There is no `show_legend` here. Instead you probably want to set the `show_legend` of the `points` (and/or of the
    `borders`). In addition, the color scale options of the `edges` must not be set, as the `edges_colors` of
    [`PointsGraphData`](@ref) is restricted to explicit colors.
"""
@kwdef mutable struct PointsGraphConfiguration <: AbstractGraphConfiguration
    figure::FigureConfiguration = FigureConfiguration()
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
    @assert configuration.edges.colors_configuration.colors_palette === nothing "not implemented: points.edges.colors_configuration.colors_palette"
    @assert !configuration.edges.colors_configuration.reverse "not implemented: points.edges.colors_configuration.reverse"
    @assert !configuration.edges.colors_configuration.color_axis.percent "not implemented: points.edges.size_axis.percent"

    message = validate_graph_configuration(configuration.figure)
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
        message = validate_bands_configuration("vertical_bands", configuration.vertical_bands, configuration.x_axis)
    end
    if message === nothing
        message = validate_bands_configuration("horizontal_bands", configuration.horizontal_bands, configuration.y_axis)
    end
    if configuration.diagonal_bands.low.offset !== nothing ||
       configuration.diagonal_bands.middle.offset !== nothing ||
       configuration.diagonal_bands.high.offset !== nothing
        if message === nothing && configuration.x_axis.log_scale != configuration.y_axis.log_scale
            message = "configuration.diagonal_bands specified for a combination of different linear and/or log scale axes"
        end
        if message === nothing && configuration.x_axis.percent != configuration.y_axis.percent
            message = "configuration.diagonal_bands specified for a combination of percent and non-percent axes"
        end
    end
    if message === nothing
        message = validate_bands_configuration("diagonal_bands", configuration.diagonal_bands, configuration.x_axis)
    end
    return message
end

"""
    @kwdef mutable struct PointsGraphData <: AbstractGraphData
        figure_title::Maybe{AbstractString} = nothing
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

By default, all the titles are empty. You can specify the overall `figure_title` as well as the `x_axis_title` and
`y_axis_title` for the axes.

The `points_xs` and `points_ys` vectors must be of the same size. If specified, the `points_colors` `sizes` and/or `hovers`
vectors must also be of the same size. The `points_colors` can be either color names or a numeric value; if the latter, then
the configuration's `colors_palette` is used. Sizes are the diameter in pixels (1/96th of an inch). Hovers are only shown
in interactive graphs (or when saving an HTML file).

The `borders_colors` and `borders_sizes` can be used to display additional data per point. The border size is in addition
to the point size.

The `points_colors_title`, `points_sizes_title`, `borders_colors_title` and `borders_sizes_title` are only used if
`show_legend` is set for the relevant color scales. You can't specify `show_legend` if there is no
`points_colors` data or if the `points_colors` contain explicit color names.

It is possible to draw straight `edges_points` between specific point pairs. In this case the `edges` of the
[`PointsGraphConfiguration`](@ref) will be used, and the `edges_colors` and `edges_sizes` will override it per edge. The
`edges_colors` are restricted to explicit colors, not a color scale.

A point (or a point border, or an edge) with a zero size and/or an empty string color (either from the data or from a
categorical `colors_palette`) will not be shown.
"""
@kwdef mutable struct PointsGraphData <: AbstractGraphData
    figure_title::Maybe{AbstractString} = nothing
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
            if size < 0
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
            if border_size < 0
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

"""
    function points_graph(;
        [figure_title::Maybe{AbstractString} = nothing,
        x_axis_title::Maybe{AbstractString} = nothing,
        y_axis_title::Maybe{AbstractString} = nothing,
        vertical_bands::BandsData = BandsData(),
        horizontal_bands::BandsData = BandsData(),
        diagonal_bands::BandsData = BandsData(),
        points_colors_title::Maybe{AbstractString} = nothing,
        points_sizes_title::Maybe{AbstractString} = nothing,
        borders_colors_title::Maybe{AbstractString} = nothing,
        borders_sizes_title::Maybe{AbstractString} = nothing,
        edges_group_title::Maybe{AbstractString} = nothing,
        edges_line_title::Maybe{AbstractString} = nothing,
        points_xs::AbstractVector{<:Real} = Float32[],
        points_ys::AbstractVector{<:Real} = Float32[],
        points_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing,
        points_sizes::Maybe{AbstractVector{<:Real}} = nothing,
        points_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing,
        borders_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing,
        borders_sizes::Maybe{AbstractVector{<:Real}} = nothing,
        edges_points::Maybe{AbstractVector{Tuple{<:Integer, <:Integer}}} = nothing,
        edges_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing,
        edges_sizes::Maybe{AbstractVector{<:Real}} = nothing],
    )::PointsGraph

Create a [`PointsGraph`](@ref) by initializing only the [`PointsGraphData`](@ref) fields.
"""
function points_graph(;
    figure_title::Maybe{AbstractString} = nothing,
    x_axis_title::Maybe{AbstractString} = nothing,
    y_axis_title::Maybe{AbstractString} = nothing,
    vertical_bands::BandsData = BandsData(),
    horizontal_bands::BandsData = BandsData(),
    diagonal_bands::BandsData = BandsData(),
    points_colors_title::Maybe{AbstractString} = nothing,
    points_sizes_title::Maybe{AbstractString} = nothing,
    borders_colors_title::Maybe{AbstractString} = nothing,
    borders_sizes_title::Maybe{AbstractString} = nothing,
    edges_group_title::Maybe{AbstractString} = nothing,
    edges_line_title::Maybe{AbstractString} = nothing,
    points_xs::AbstractVector{<:Real} = Float32[],
    points_ys::AbstractVector{<:Real} = Float32[],
    points_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing,
    points_sizes::Maybe{AbstractVector{<:Real}} = nothing,
    points_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing,
    borders_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing,
    borders_sizes::Maybe{AbstractVector{<:Real}} = nothing,
    edges_points::Maybe{AbstractVector{Tuple{<:Integer, <:Integer}}} = nothing,
    edges_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing,
    edges_sizes::Maybe{AbstractVector{<:Real}} = nothing,
)::PointsGraph
    return PointsGraph(
        PointsGraphData(;
            figure_title = figure_title,
            x_axis_title = x_axis_title,
            y_axis_title = y_axis_title,
            vertical_bands = vertical_bands,
            horizontal_bands = horizontal_bands,
            diagonal_bands = diagonal_bands,
            points_colors_title = points_colors_title,
            points_sizes_title = points_sizes_title,
            borders_colors_title = borders_colors_title,
            borders_sizes_title = borders_sizes_title,
            edges_group_title = edges_group_title,
            edges_line_title = edges_line_title,
            points_xs = points_xs,
            points_ys = points_ys,
            points_colors = points_colors,
            points_sizes = points_sizes,
            points_hovers = points_hovers,
            borders_colors = borders_colors,
            borders_sizes = borders_sizes,
            edges_points = edges_points,
            edges_colors = edges_colors,
            edges_sizes = edges_sizes,
        ),
        PointsGraphConfiguration(),
    )
end

function graph_to_figure(graph::PointsGraph)::PlotlyFigure
    assert_valid_object(graph)

    traces = Vector{GenericTrace}()

    minimum_x, maximum_x = range_of([graph.data.points_xs], graph.configuration.x_axis)
    minimum_y, maximum_y = range_of([graph.data.points_ys], graph.configuration.y_axis)

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
        percent = graph.configuration.x_axis.percent,
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
        percent = graph.configuration.y_axis.percent,
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
        axis_configuration = graph.configuration.x_axis,
        percent = graph.configuration.x_axis.percent,
    )

    edges_points = graph.data.edges_points
    if edges_points !== nothing && !graph.configuration.edges_over_points
        for index in 1:length(edges_points)
            push!(
                traces,
                edge_trace(;
                    data = graph.data,
                    edges_configuration = graph.configuration.edges,
                    x_axis_configuration = graph.configuration.x_axis,
                    y_axis_configuration = graph.configuration.y_axis,
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

        colors_palette = graph.configuration.borders.colors_configuration.colors_palette
        if colors_palette isa CategoricalColors
            borders_colors = graph.data.borders_colors
            @assert borders_colors isa AbstractVector{<:AbstractString}
            is_first = true
            for (value, color) in colors_palette
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
                                x_axis_configuration = graph.configuration.x_axis,
                                y_axis_configuration = graph.configuration.y_axis,
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
                    x_axis_configuration = graph.configuration.x_axis,
                    y_axis_configuration = graph.configuration.y_axis,
                    color = if borders_colors !== nothing
                        fix_colors(borders_colors, graph.configuration.borders.colors_configuration.color_axis)
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

    colors_palette = graph.configuration.points.colors_configuration.colors_palette
    if colors_palette isa CategoricalColors
        colors = graph.data.points_colors
        @assert colors isa AbstractVector{<:AbstractString}
        is_first = true
        for (value, color) in colors_palette
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
                            x_axis_configuration = graph.configuration.x_axis,
                            y_axis_configuration = graph.configuration.y_axis,
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
                    x_axis_configuration = graph.configuration.x_axis,
                    y_axis_configuration = graph.configuration.y_axis,
                    color = if colors !== nothing
                        fix_colors(colors, graph.configuration.points.colors_configuration.color_axis)
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
                    x_axis_configuration = graph.configuration.x_axis,
                    y_axis_configuration = graph.configuration.y_axis,
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
                    percent = graph.configuration.x_axis.percent,
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
                    percent = graph.configuration.y_axis.percent,
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
                    axis_configuration = graph.configuration.x_axis,
                    show_legend = !is_filled && graph.configuration.diagonal_bands.show_legend,
                    legend_title = diagonal_legend_title,
                    name = name,
                    percent = graph.configuration.y_axis.percent,
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

    return plotly_figure(traces, layout)
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
    percent::Bool,
)::Tuple{Bool, Bool, Bool}
    high_offset = scale_percent(percent, bands_configuration.high.offset)
    low_offset = scale_percent(percent, bands_configuration.low.offset)

    fill_high = high_offset !== nothing && bands_configuration.high.is_filled
    if fill_high
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [maximum_x, high_offset, high_offset, maximum_x],
                points_ys = [minimum_y, minimum_y, maximum_y, maximum_y],
                line_color = bands_configuration.high.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.high_title === nothing ? "right" : bands_data.high_title,
            ),
        )
    end

    fill_middle = high_offset !== nothing && low_offset !== nothing && bands_configuration.middle.is_filled
    if fill_middle
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [low_offset, high_offset, high_offset, low_offset],
                points_ys = [minimum_y, minimum_y, maximum_y, maximum_y],
                line_color = bands_configuration.middle.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.middle_title === nothing ? "center" : bands_data.middle_title,
            ),
        )
    end

    fill_low = low_offset !== nothing && bands_configuration.low.is_filled
    if fill_low
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [minimum_x, low_offset, low_offset, minimum_x],
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
    percent::Bool,
)::Tuple{Bool, Bool, Bool}
    high_offset = scale_percent(percent, bands_configuration.high.offset)
    low_offset = scale_percent(percent, bands_configuration.low.offset)

    fill_high = high_offset !== nothing && bands_configuration.high.is_filled
    if fill_high
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [minimum_x, minimum_x, maximum_x, maximum_x],
                points_ys = [maximum_y, high_offset, high_offset, maximum_y],
                line_color = bands_configuration.high.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.high_title === nothing ? "high" : bands_data.high_title,
            ),
        )
    end

    fill_middle = high_offset !== nothing && low_offset !== nothing && bands_configuration.middle.is_filled
    if fill_middle
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [minimum_x, minimum_x, maximum_x, maximum_x],
                points_ys = [low_offset, high_offset, high_offset, low_offset],
                line_color = bands_configuration.middle.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.middle_title === nothing ? "middle" : bands_data.middle_title,
            ),
        )
    end

    fill_low = low_offset !== nothing && bands_configuration.low.is_filled
    if fill_low
        push!(  # NOJET
            traces,
            fill_trace(;
                points_xs = [minimum_x, minimum_x, maximum_x, maximum_x],
                points_ys = [minimum_y, low_offset, low_offset, minimum_y],
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
    axis_configuration::AxisConfiguration,
    percent::Bool,
)::Tuple{Bool, Bool, Bool}
    if axis_configuration.log_scale === nothing
        high_offset = scale_percent(percent, bands_configuration.high.offset)
        low_offset = scale_percent(percent, bands_configuration.low.offset)
    else
        high_offset = bands_configuration.high.offset
        low_offset = bands_configuration.low.offset
    end

    fill_high = high_offset !== nothing && bands_configuration.high.is_filled
    if fill_high
        push!(  # NOJET
            traces,
            fill_high_diagonal_trace(;
                offset = high_offset,
                minimum_x = minimum_x,
                minimum_y = minimum_y,
                maximum_x = maximum_x,
                maximum_y = maximum_y,
                line_color = bands_configuration.high.color,
                show_legend = bands_configuration.show_legend,
                name = bands_data.high_title === nothing ? "higher" : bands_data.high_title,
                legend_title = legend_title,
                axis_configuration = axis_configuration,
            ),
        )
    end

    fill_middle = high_offset !== nothing && low_offset !== nothing && bands_configuration.middle.is_filled
    if fill_middle
        push!(  # NOJET
            traces,
            fill_middle_diagonal_trace(;
                low_offset = low_offset,
                high_offset = high_offset,
                minimum_x = minimum_x,
                minimum_y = minimum_y,
                maximum_x = maximum_x,
                maximum_y = maximum_y,
                line_color = bands_configuration.middle.color,
                show_legend = bands_configuration.show_legend,
                legend_title = legend_title,
                name = bands_data.middle_title === nothing ? "comparable" : bands_data.middle_title,
                axis_configuration = axis_configuration,
            ),
        )
    end

    fill_low = low_offset !== nothing && bands_configuration.low.is_filled
    if fill_low
        push!(  # NOJET
            traces,
            fill_low_diagonal_trace(;
                offset = low_offset,
                minimum_x = minimum_x,
                minimum_y = minimum_y,
                maximum_x = maximum_x,
                maximum_y = maximum_y,
                line_color = bands_configuration.low.color,
                show_legend = bands_configuration.show_legend,
                name = bands_data.low_title === nothing ? "lower" : bands_data.low_title,
                legend_title = legend_title,
                axis_configuration = axis_configuration,
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
    axis_configuration::AxisConfiguration,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(axis_configuration)
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
    axis_configuration::AxisConfiguration,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(axis_configuration)
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
    axis_configuration::AxisConfiguration,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(axis_configuration)
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
    x_axis_configuration::AxisConfiguration,
    y_axis_configuration::AxisConfiguration,
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
    name = name !== nothing ? name : points_configuration.colors_configuration.show_legend ? "Trace" : ""
    return scatter(;
        x = scale_values(masked_values(data.points_xs, mask), x_axis_configuration),
        y = scale_values(masked_values(data.points_ys, mask), y_axis_configuration),
        marker_size = masked_values(marker_size, mask),
        marker_color = color !== nothing ? masked_values(color, mask) : points_configuration.color,
        marker_colorscale = if points_configuration.colors_configuration.colors_palette isa AbstractVector ||
                               points_configuration.colors_configuration.color_axis.log_scale == Log10Scale
            nothing
        else
            points_configuration.colors_configuration.colors_palette
        end,
        marker_coloraxis = coloraxis,
        marker_showscale = points_configuration.colors_configuration.show_legend &&
                           !(points_configuration.colors_configuration.colors_palette isa CategoricalColors),
        marker_reversescale = points_configuration.colors_configuration.reverse,
        showlegend = points_configuration.colors_configuration.show_legend &&
                     points_configuration.colors_configuration.colors_palette isa CategoricalColors,
        legendgroup = is_first ? "$(legend_group) $(name)" : nothing,
        legendgrouptitle_text = is_first ? colors_title : nothing,
        name = name,
        text = masked_values(data.points_hovers, mask),
        hovertemplate = data.points_hovers === nothing ? nothing : "%{text}<extra></extra>",
        mode = "markers",
    )
end

function edge_trace(;
    data::PointsGraphData,
    edges_configuration::PointsConfiguration,
    x_axis_configuration::AxisConfiguration,
    y_axis_configuration::AxisConfiguration,
    index::Int,
)::GenericTrace
    from_point, to_point = data.edges_points[index]

    xs = scale_values([data.points_xs[from_point], data.points_xs[to_point]], x_axis_configuration)
    ys = scale_values([data.points_ys[from_point], data.points_ys[to_point]], y_axis_configuration)

    return scatter(;
        x = xs,
        y = ys,
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
        showlegend = index == 1 && edges_configuration.colors_configuration.show_legend,
    )
end

function vertical_line_trace(;
    band_configuration::BandConfiguration,
    minimum_y::Real,
    maximum_y::Real,
    show_legend::Bool,
    legend_title::Vector{Maybe{AbstractString}},
    name::AbstractString,
    percent::Bool,
)::GenericTrace
    offset = scale_percent(percent, band_configuration.offset)
    @assert offset !== nothing
    legendgrouptitle_text = legend_title[1]
    legend_title[1] = nothing
    return scatter(;
        x = [offset, offset],
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
    percent::Bool,
)::GenericTrace
    offset = scale_percent(percent, band_configuration.offset)
    @assert offset !== nothing
    legendgrouptitle_text = legend_title[1]
    legend_title[1] = nothing
    return scatter(;
        x = [minimum_x, maximum_x],
        y = [offset, offset],
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
    axis_configuration::AxisConfiguration,
    show_legend::Bool,
    legend_title::Vector{Maybe{AbstractString}},
    name::AbstractString,
    percent::Bool,
)::GenericTrace
    if axis_configuration.log_scale === nothing
        offset = scale_percent(percent, band_configuration.offset)
    else
        offset = band_configuration.offset
    end
    @assert offset !== nothing
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)

    legendgrouptitle_text = legend_title[1]
    legend_title[1] = nothing

    threshold, increase, decrease = band_operations(axis_configuration)

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

function scale_percent(::Bool, ::Nothing)::Nothing
    return nothing
end

function scale_percent(percent::Bool, value::Real)::Real
    if percent
        return value * 100
    else
        return value
    end
end

function band_operations(axis_configuration::AxisConfiguration)::Tuple{AbstractFloat, Function, Function}
    if axis_configuration.log_scale == Log10Scale
        return (1, *, /)
    else
        @assert axis_configuration.log_scale === nothing || axis_configuration.log_scale == Log2Scale
        return (0, +, -)
    end
end

function fix_colors(
    colors::Union{AbstractString, AbstractVector{<:AbstractString}, AbstractMatrix{<:AbstractString}},
    ::AxisConfiguration,
)::Union{AbstractString, AbstractVector{<:AbstractString}, AbstractMatrix{<:AbstractString}}
    return colors
end

function fix_colors(
    colors::Union{AbstractVector{<:Real}, AbstractMatrix{<:Real}},
    color_axis::AxisConfiguration,
)::Union{AbstractVector{<:Real}, AbstractMatrix{<:Real}}
    if color_axis.log_scale == Log10Scale
        return log10.(colors .+ color_axis.log_regularization)
    elseif color_axis.log_scale == Log2Scale
        return log2.(colors .+ color_axis.log_regularization)
    else
        @assert color_axis.log_scale === nothing
        return colors .+ color_axis.log_regularization
    end
end

function xy_ticks(::Nothing)::Tuple{Nothing, Nothing}
    return (nothing, nothing)
end

function xy_ticks(names::AbstractVector{<:AbstractString})::Tuple{Vector{<:Integer}, AbstractVector{<:AbstractString}}
    return (collect(1:length(names)), names)
end

function lowest_color(colors_configuration::ColorsConfiguration)::Maybe{AbstractFloat}
    colors_palette = colors_configuration.colors_palette
    color_axis = colors_configuration.color_axis
    if color_axis.minimum !== nothing
        return color_axis.minimum
    elseif colors_palette isa Union{Maybe{AbstractString}, CategoricalColors}
        return nothing
    elseif color_axis.log_scale === nothing
        return (minimum([value for (value, _) in colors_palette]) + color_axis.log_regularization)
    elseif color_axis.log_scale == Log10Scale
        return log10(minimum([value for (value, _) in colors_palette]) + color_axis.log_regularization)
    elseif color_axis.log_scale == Log2Scale
        return log2(minimum([value for (value, _) in colors_palette]) + color_axis.log_regularization)
    else
        @assert false
    end
end

function highest_color(colors_configuration::ColorsConfiguration)::Maybe{AbstractFloat}
    colors_palette = colors_configuration.colors_palette
    color_axis = colors_configuration.color_axis
    if color_axis.maximum !== nothing
        return color_axis.maximum
    elseif colors_palette isa Union{Maybe{AbstractString}, CategoricalColors}
        return nothing
    elseif color_axis.log_scale === nothing
        return (maximum([value for (value, _) in colors_palette]) + color_axis.log_regularization)
    elseif color_axis.log_scale == Log10Scale
        return log10(maximum([value for (value, _) in colors_palette]) + color_axis.log_regularization)
    elseif color_axis.log_scale == Log2Scale
        return log2(maximum([value for (value, _) in colors_palette]) + color_axis.log_regularization)
    else
        @assert false
    end
end

"""
    @kwdef mutable struct GridGraphConfiguration <: AbstractGraphConfiguration
        figure::FigureConfiguration = FigureConfiguration()
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
    figure::FigureConfiguration = FigureConfiguration()
    points::PointsConfiguration = PointsConfiguration()
    borders::PointsConfiguration = PointsConfiguration()
end

function Validations.validate_object(configuration::GridGraphConfiguration)::Maybe{AbstractString}
    message = validate_graph_configuration(configuration.figure)
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
        figure_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        points_colors_title::Maybe{AbstractString} = nothing
        borders_colors_title::Maybe{AbstractString} = nothing
        columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        points_colors::Maybe{AbstractMatrix{<:Union{AbstractString, Real}}} = nothing
        points_sizes::Maybe{AbstractMatrix{<:Real}} = nothing
        points_hovers::Maybe{AbstractMatrix{<:AbstractString}} = nothing
        borders_colors::Maybe{AbstractMatrix{<:Union{AbstractString, Real}}} = nothing
        borders_sizes::Maybe{AbstractMatrix{<:Real}} = nothing
    end

The data for a graph showing a grid of points (e.g. for correlations).

This is similar to a [`PointsGraphData`](@ref), except that the data is given as a matrix instead of a vector, and no X
and Y coordinates are given. Instead each matrix entry is plotted as a point at the matching grid location.
"""
@kwdef mutable struct GridGraphData <: AbstractGraphData
    figure_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    points_colors_title::Maybe{AbstractString} = nothing
    borders_colors_title::Maybe{AbstractString} = nothing
    columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    points_colors::Maybe{AbstractMatrix{<:Union{AbstractString, Real}}} = nothing
    points_sizes::Maybe{AbstractMatrix{<:Real}} = nothing
    points_hovers::Maybe{AbstractMatrix{<:AbstractString}} = nothing
    borders_colors::Maybe{AbstractMatrix{<:Union{AbstractString, Real}}} = nothing
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
    if n_rows == 0
        return "no rows in data.points_colors and/or data.points_sizes"
    end
    if n_columns == 0
        return "no columns in data.points_colors and/or data.points_sizes"
    end

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

"""
    function grid_graph(;
        [figure_title::Maybe{AbstractString} = nothing,
        x_axis_title::Maybe{AbstractString} = nothing,
        y_axis_title::Maybe{AbstractString} = nothing,
        points_colors_title::Maybe{AbstractString} = nothing,
        borders_colors_title::Maybe{AbstractString} = nothing,
        columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
        rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
        points_colors::Maybe{AbstractMatrix<:Union{AbstractString, <:Real}}}} = nothing,
        points_sizes::Maybe{AbstractMatrix{<:Real}} = nothing,
        points_hovers::Maybe{AbstractMatrix{<:AbstractString}} = nothing,
        borders_colors::Maybe{AbstractMatrix{<:Union{AbstractString, Real}}} = nothing,
        borders_sizes::Maybe{AbstractMatrix{<:Real}} = nothing],
    )::GridGraph

Create a [`GridGraph`](@ref) by initializing only the [`GridGraphData`](@ref) fields.
"""
function grid_graph(;
    figure_title::Maybe{AbstractString} = nothing,
    x_axis_title::Maybe{AbstractString} = nothing,
    y_axis_title::Maybe{AbstractString} = nothing,
    points_colors_title::Maybe{AbstractString} = nothing,
    borders_colors_title::Maybe{AbstractString} = nothing,
    columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
    rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
    points_colors::Maybe{AbstractMatrix{<:Union{AbstractString, Real}}} = nothing,
    points_sizes::Maybe{AbstractMatrix{<:Real}} = nothing,
    points_hovers::Maybe{AbstractMatrix{<:AbstractString}} = nothing,
    borders_colors::Maybe{AbstractMatrix{<:Union{AbstractString, Real}}} = nothing,
    borders_sizes::Maybe{AbstractMatrix{<:Real}} = nothing,
)::GridGraph
    return GridGraph(
        GridGraphData(;
            figure_title = figure_title,
            x_axis_title = x_axis_title,
            y_axis_title = y_axis_title,
            points_colors_title = points_colors_title,
            borders_colors_title = borders_colors_title,
            columns_names = columns_names,
            rows_names = rows_names,
            points_colors = points_colors,
            points_sizes = points_sizes,
            points_hovers = points_hovers,
            borders_colors = borders_colors,
            borders_sizes = borders_sizes,
        ),
        GridGraphConfiguration(),
    )
end

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

        colors_palette = graph.configuration.borders.colors_configuration.colors_palette
        if colors_palette isa CategoricalColors
            @assert borders_colors isa AbstractMatrix{<:AbstractString}
            is_first = true
            for (value, color) in colors_palette
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
                            fix_colors(borders_colors, graph.configuration.borders.colors_configuration.color_axis)
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

    colors_palette = graph.configuration.points.colors_configuration.colors_palette
    if colors_palette isa CategoricalColors
        colors = graph.data.points_colors
        @assert colors isa AbstractMatrix{<:AbstractString}
        is_first = true
        for (value, color) in colors_palette
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
                        fix_colors(colors, graph.configuration.points.colors_configuration.color_axis)
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
    layout[:shapes] = [borders_rectangle(nothing, nothing)]
    return plotly_figure(traces, layout)
end

function validate_graph(graph::PointsGraph)::Maybe{AbstractString}
    if graph.configuration.x_axis.log_scale !== nothing
        x_log_regularization = graph.configuration.x_axis.log_regularization
        for (index, x) in enumerate(graph.data.points_xs)
            if x + x_log_regularization <= 0
                return "log of non-positive data.points_xs[$(index)]: $(x + x_log_regularization)"
            end
        end
    end

    if graph.configuration.y_axis.log_scale !== nothing
        y_log_regularization = graph.configuration.y_axis.log_regularization
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
        graph.configuration.points.colors_configuration,
    )
    if message === nothing
        message = validate_vector_colors(
            "data.borders_colors",
            graph.data.borders_colors,
            "configuration.borders",
            graph.configuration.borders.colors_configuration,
        )
    end

    return message
end

function validate_graph(graph::GridGraph)::Maybe{AbstractString}
    message = validate_matrix_colors(
        "data.points_colors",
        graph.data.points_colors,
        "configuration.points",
        graph.configuration.points.colors_configuration,
    )
    if message === nothing
        message = validate_matrix_colors(
            "data.borders_colors",
            graph.data.borders_colors,
            "configuration.borders",
            graph.configuration.borders.colors_configuration,
        )
    end
    return message
end

function validate_vector_colors(
    what_colors::AbstractString,
    colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}},
    what_configuration::AbstractString,
    colors_configuration::ColorsConfiguration,
)::Maybe{AbstractString}
    colors_palette = colors_configuration.colors_palette
    if colors isa AbstractVector{<:AbstractString}
        if colors_palette isa CategoricalColors
            scale_colors = Set{AbstractString}([value for (value, _) in colors_palette])
            for (index, color) in enumerate(colors)
                if color != "" && !(color in scale_colors)
                    return "categorical $(what_configuration).colors_configuration.colors_palette does not contain $(what_colors)[$(index)]: $(color)"
                end
            end
        else
            for (index, color) in enumerate(colors)
                if color != "" && !is_valid_color(color)
                    return "invalid $(what_colors)[$(index)]: $(color)"
                end
            end
        end
    elseif colors !== nothing && colors_palette isa CategoricalColors
        return "non-string $(what_colors) for categorical $(what_configuration).colors_configuration.colors_palette"
    end

    if colors_configuration.show_legend
        if colors === nothing
            return "no $(what_colors) specified for $(what_configuration).colors_configuration.show_legend"
        end
        if colors isa AbstractVector{<:AbstractString} && !(colors_configuration.colors_palette isa CategoricalColors)
            return "explicit $(what_colors) specified for $(what_configuration).colors_configuration.show_legend"
        end
    end

    if colors_configuration.color_axis.log_scale !== nothing
        if !(colors isa AbstractVector{<:Real})
            return "non-real $(what_colors) with $(what_configuration).colors_configuration.color_axis.log_scale"
        end
        index = argmin(colors)  # NOJET
        minimal_color = colors[index] + colors_configuration.color_axis.log_regularization
        if minimal_color <= 0
            return "log of non-positive $(what_colors)[$(index)]: $(minimal_color)"
        end
    end

    return nothing
end

function grid_trace(;
    data::GridGraphData,
    n_rows::Integer,
    n_columns::Integer,
    color::Maybe{Union{AbstractString, AbstractMatrix{<:Union{AbstractString, Real}}}},
    marker_size::Maybe{Union{Real, AbstractVector{<:Real}}},
    coloraxis::Maybe{AbstractString},
    points_configuration::PointsConfiguration,
    colors_title::Maybe{AbstractString},
    legend_group::AbstractString,
    mask::Maybe{Union{Vector{Bool}, BitVector}} = nothing,
    name::Maybe{AbstractString} = nothing,
    is_first::Bool = true,
)::GenericTrace
    name = name !== nothing ? name : points_configuration.colors_configuration.show_legend ? "Trace" : ""
    return scatter(;
        x = masked_xs(n_rows, n_columns, mask),
        y = masked_ys(n_rows, n_columns, mask),
        marker_size = masked_values(marker_size, mask),
        marker_color = color !== nothing ? masked_values(color, mask) : points_configuration.color,
        marker_colorscale = if points_configuration.colors_configuration.colors_palette isa AbstractVector ||
                               points_configuration.colors_configuration.color_axis.log_scale !== nothing
            nothing
        else
            points_configuration.colors_configuration.colors_palette
        end,
        marker_coloraxis = coloraxis,
        marker_showscale = points_configuration.colors_configuration.show_legend &&
                           !(points_configuration.colors_configuration.colors_palette isa CategoricalColors),
        marker_reversescale = points_configuration.colors_configuration.reverse,
        showlegend = points_configuration.colors_configuration.show_legend &&
                     points_configuration.colors_configuration.colors_palette isa CategoricalColors,
        legendgroup = "$(legend_group) $(name)",
        legendgrouptitle_text = is_first ? colors_title : nothing,
        name = name,
        text = masked_values(data.points_hovers, mask),
        hovertemplate = data.points_hovers === nothing ? nothing : "%{text}<extra></extra>",
        mode = "markers",
    )
end

function scale_values(values::AbstractVector{<:Real}, axis_configuration::AxisConfiguration)::AbstractVector{<:Real}
    values = values .+ axis_configuration.log_regularization
    if axis_configuration.percent
        values .*= 100
    end
    if axis_configuration.log_scale == Log2Scale
        values = log2.(values)
    else
        @assert axis_configuration.log_scale === nothing || axis_configuration.log_scale == Log10Scale
    end
    return values
end

function scale_range(
    minimum_value::Maybe{Real},
    maximum_value::Maybe{Real},
    axis_configuration::AxisConfiguration,
)::Tuple{Maybe{Real}, Maybe{Real}}
    if axis_configuration.log_scale == Log10Scale
        if minimum_value !== nothing
            minimum_value = log10(minimum_value)
        end
        if maximum_value !== nothing
            maximum_value = log10(maximum_value)
        end
    else
        @assert axis_configuration.log_scale === nothing || axis_configuration.log_scale == Log2Scale
    end
    return (minimum_value, maximum_value)
end

function masked_values(values::Any, ::Any)::Any
    return values
end

function masked_values(values::AbstractVector, mask::Union{AbstractVector{Bool}, BitVector})::AbstractVector
    return values[mask]  # NOJET
end

function masked_values(values::AbstractMatrix, mask::Union{AbstractVector{Bool}, BitVector})::AbstractVector
    return vec(values)[mask]  # NOJET
end

function masked_values(values::AbstractMatrix, ::Nothing)::AbstractVector
    return vec(values)
end

function masked_xs(
    n_rows::Integer,
    n_columns::Integer,
    mask::Maybe{Union{AbstractVector{Bool}, BitVector}},
)::Vector{Int}
    points_xs = Matrix{Int}(undef, n_rows, n_columns)
    points_xs .= transpose(1:n_columns)
    return masked_values(points_xs, mask)
end

function masked_ys(
    n_rows::Integer,
    n_columns::Integer,
    mask::Maybe{Union{AbstractVector{Bool}, BitVector}},
)::Vector{Int}
    points_ys = Matrix{Int}(undef, n_rows, n_columns)
    points_ys .= 1:n_rows
    return masked_values(points_ys, mask)
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
    color_tickvals, color_ticktext, color_tickprefix =
        log_colors_axis_ticks(data.points_colors, configuration.points.colors_configuration)
    border_color_tickvals, border_color_ticktext, border_color_tickprefix =
        log_colors_axis_ticks(data.borders_colors, configuration.borders.colors_configuration)
    x_tickvals, x_ticknames = xy_ticks(columns_names)
    y_tickvals, y_ticknames = xy_ticks(rows_names)

    if x_axis_configuration.log_scale == Log10Scale
        minimum_x = log10(minimum_x)
        maximum_x = log10(maximum_x)
    else
        @assert x_axis_configuration.log_scale === nothing || x_axis_configuration.log_scale == Log2Scale
    end

    if y_axis_configuration.log_scale == Log10Scale
        minimum_y = log10(minimum_y)
        maximum_y = log10(maximum_y)
    else
        @assert y_axis_configuration.log_scale === nothing || y_axis_configuration.log_scale == Log2Scale
    end

    return graph_layout(
        configuration.figure,
        Layout(;  # NOJET
            title = data.figure_title,
            xaxis_showgrid = configuration.figure.show_grid,
            xaxis_showticklabels = configuration.figure.show_ticks,
            xaxis_title = data.x_axis_title,
            xaxis_range = [
                x_axis_configuration.minimum !== nothing ? x_axis_configuration.minimum : minimum_x,
                x_axis_configuration.maximum !== nothing ? x_axis_configuration.maximum : maximum_x,
            ],
            xaxis_type = x_axis_configuration.log_scale == Log10Scale ? "log" : nothing,
            xaxis_tickprefix = x_axis_configuration.log_scale == Log2Scale ? "<sub>2</sub>" : nothing,
            xaxis_ticksuffix = x_axis_configuration.percent ? "<sub>%</sub>" : nothing,
            xaxis_zeroline = x_axis_configuration.log_scale === nothing ? nothing : false,
            xaxis_tickvals = x_tickvals,
            xaxis_ticktext = x_ticknames,
            yaxis_showgrid = configuration.figure.show_grid,
            yaxis_showticklabels = configuration.figure.show_ticks,
            yaxis_title = data.y_axis_title,
            yaxis_range = [
                y_axis_configuration.minimum !== nothing ? y_axis_configuration.minimum : minimum_y,
                y_axis_configuration.maximum !== nothing ? y_axis_configuration.maximum : maximum_y,
            ],
            yaxis_type = y_axis_configuration.log_scale == Log10Scale ? "log" : nothing,
            yaxis_tickprefix = y_axis_configuration.log_scale == Log2Scale ? "<sub>2</sub>" : nothing,
            yaxis_ticksuffix = y_axis_configuration.percent ? "<sub>%</sub>" : nothing,
            yaxis_zeroline = y_axis_configuration.log_scale === nothing ? nothing : false,
            yaxis_tickvals = y_tickvals,
            yaxis_ticktext = y_ticknames,
            showlegend = (
                configuration.points.colors_configuration.show_legend &&
                configuration.points.colors_configuration.colors_palette isa CategoricalColors
            ) || (
                configuration.borders.colors_configuration.show_legend &&
                configuration.borders.colors_configuration.colors_palette isa CategoricalColors
            ),
            legend_tracegroupgap = 0,
            legend_itemdoubleclick = false,
            legend_x = if configuration.points.colors_configuration.show_legend &&
                          configuration.borders.colors_configuration.show_legend &&
                          configuration.borders.colors_configuration.colors_palette isa CategoricalColors
                1.2
            else
                nothing
            end,
            coloraxis2_colorbar_x = if (
                configuration.borders.colors_configuration.show_legend &&
                configuration.points.colors_configuration.show_legend
            )
                1.2
            else
                nothing  # NOJET
            end,
            coloraxis_showscale = configuration.points.colors_configuration.show_legend &&
                                  !(configuration.points.colors_configuration.colors_palette isa CategoricalColors),
            coloraxis_reversescale = configuration.points.colors_configuration.reverse,
            coloraxis_colorscale = normalized_colors_palette(configuration.points.colors_configuration),
            coloraxis_cmin = lowest_color(configuration.points.colors_configuration),
            coloraxis_cmax = highest_color(configuration.points.colors_configuration),
            coloraxis_colorbar_title_text = data.points_colors_title,
            coloraxis_colorbar_tickvals = color_tickvals,
            coloraxis_colorbar_ticktext = color_ticktext,
            coloraxis_colorbar_tickprefix = color_tickprefix,
            coloraxis2_showscale = (data.borders_colors !== nothing || data.borders_sizes !== nothing) &&
                                   configuration.borders.colors_configuration.show_legend &&
                                   !(configuration.borders.colors_configuration.colors_palette isa CategoricalColors),
            coloraxis2_reversescale = configuration.borders.colors_configuration.reverse,
            coloraxis2_colorscale = normalized_colors_palette(configuration.borders.colors_configuration),
            coloraxis2_cmin = lowest_color(configuration.borders.colors_configuration),
            coloraxis2_cmax = highest_color(configuration.borders.colors_configuration),
            coloraxis2_colorbar_title_text = data.borders_colors_title,
            coloraxis2_colorbar_tickvals = border_color_tickvals,
            coloraxis2_colorbar_ticktext = border_color_ticktext,
            coloraxis2_colorbar_tickprefix = border_color_tickprefix,
        ),
    )
end

function normalized_colors_palette(
    colors_configuration::ColorsConfiguration,
)::Union{Maybe{AbstractString}, CategoricalColors, ContinuousColors}
    colors_palette = colors_configuration.colors_palette
    if colors_palette === nothing
        return nothing
    elseif colors_palette isa AbstractString
        if endswith(colors_palette, "_r")
            return reverse([
                (1.0 - value, color) for (value, color) in NAMED_COLOR_PALETTES[colors_palette[1:(end - 2)]]
            ])
        else
            return [(value, color) for (value, color) in NAMED_COLOR_PALETTES[colors_palette]]
        end
    elseif colors_palette isa CategoricalColors
        return [(value, color) for (value, color) in colors_palette]
    else
        @assert colors_configuration.colors_palette isa ContinuousColors
        cmin = lowest_color(colors_configuration)
        @assert cmin !== nothing
        cmax = highest_color(colors_configuration)
        @assert cmax !== nothing
        @assert cmax > cmin
        color_axis = colors_configuration.color_axis
        if color_axis.log_scale === nothing
            return [
                (clamp(((value + color_axis.log_regularization) - cmin) / (cmax - cmin), 0, 1), color) for
                (value, color) in colors_palette
            ]
        end

        if color_axis.log_scale == Log2Scale
            log_function = log2
        elseif color_axis.log_scale == Log10Scale
            log_function = log10
        else
            @assert false
        end

        return [
            (clamp((log_function(value + color_axis.log_regularization) - cmin) / (cmax - cmin), 0, 1), color) for
            (value, color) in colors_palette
        ]
    end
end

function border_marker_size(
    data::Union{PointsGraphData, GridGraphData},
    configuration::Union{PointsGraphConfiguration, GridGraphConfiguration},
    sizes::Maybe{Union{Real, AbstractVector{<:Real}}},
)::Union{Real, Vector{<:Real}}
    sizes = sizes
    borders_sizes = fix_sizes(data.borders_sizes, configuration.borders)

    if borders_sizes === nothing
        border_marker_size = configuration.borders.size !== nothing ? configuration.borders.size : 4
        @assert border_marker_size !== nothing
        if sizes === nothing
            points_marker_size = configuration.points.size !== nothing ? configuration.points.size : 4
            return points_marker_size + 2 * border_marker_size
        else
            return sizes .+ 2 * border_marker_size
        end
    else
        if sizes === nothing
            points_marker_size = configuration.points.size !== nothing ? configuration.points.size : 4
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
    log_scale = points_configuration.size_axis.log_scale
    if smallest === nothing && largest === nothing && log_scale === nothing
        return sizes
    end

    smin = points_configuration.size_axis.minimum !== nothing ? points_configuration.size_axis.minimum : minimum(sizes)
    smax = points_configuration.size_axis.maximum !== nothing ? points_configuration.size_axis.maximum : maximum(sizes)

    log_regularization = points_configuration.size_axis.log_regularization
    if log_scale == Log10Scale
        smin = log10(smin + log_regularization)
        smax = log10(smax + log_regularization)
        sizes = log10.(sizes .+ log_regularization)
    elseif log_scale == Log2Scale
        smin = log2(smin + log_regularization)
        smax = log2(smax + log_regularization)
        sizes = log2.(sizes .+ log_regularization)
    else
        @assert log_scale === nothing
    end

    if smallest === nothing
        smallest = 2
    end
    if largest === nothing
        largest = smallest + 8
    end

    return (sizes .- smin) .* (largest - smallest) ./ (smax - smin) .+ smallest
end

function range_of(
    values::AbstractVector{<:AbstractVector{<:Real}},
    axis_configuration::AxisConfiguration,
)::Tuple{Real, Real}
    if axis_configuration.percent
        values_scale = 100
    else
        values_scale = 1
    end

    minimum_value = minimum([minimum(vector) for vector in values]) + axis_configuration.log_regularization
    maximum_value = maximum([maximum(vector) for vector in values]) + axis_configuration.log_regularization

    if axis_configuration.log_scale == Log10Scale
        minimum_value = log10(minimum_value) + log10(values_scale)
        maximum_value = log10(maximum_value) + log10(values_scale)
    elseif axis_configuration.log_scale == Log2Scale
        minimum_value = log2(minimum_value) + log2(values_scale)
        maximum_value = log2(maximum_value) + log2(values_scale)
    else
        @assert axis_configuration.log_scale === nothing
        minimum_value *= values_scale
        maximum_value *= values_scale
    end

    margin_value = (maximum_value - minimum_value) / 20
    minimum_value -= margin_value
    maximum_value += margin_value

    if axis_configuration.log_scale == Log10Scale
        minimum_value = 10^minimum_value
        maximum_value = 10^maximum_value
    else
        @assert axis_configuration.log_scale == Log2Scale || axis_configuration.log_scale === nothing
    end

    return (minimum_value, maximum_value)
end

"""
    @kwdef mutable struct HeatmapGraphConfiguration <: AbstractGraphConfiguration
        figure::FigureConfiguration = FigureConfiguration()
        entries::ColorsConfiguration = ColorsConfiguration()
        annotations::Dict{<:AbstractString,AnnotationsConfiguration} = Dict{String,AnnotationsConfiguration}()
        annotations_gap::AbstractFloat = 0.005
    end

Configure a graph showing a heatmap.

This displays a matrix of values using a rectangle at each position. The only control we have is setting the color of
each rectangle. An advantage of this over a grid is that it can handle large amount of data. Due to Plotly's
limitations, you still need to manually tweak the graph size for best results.

The `annotations` specify the colors for any annotations attached to the rows and/or columns axes. The key is the
`color_axis` of the [`AnnotationData`](@ref). A white space of `annotations_gap` will be left around the annotations.
Due to Plotly's limitations, this is a fraction of the total size of the graph, instead of an absolute size.
"""
@kwdef mutable struct HeatmapGraphConfiguration <: AbstractGraphConfiguration
    figure::FigureConfiguration = FigureConfiguration()
    entries::ColorsConfiguration = ColorsConfiguration()
    columns_annotations_size::AbstractFloat = 0.05
    rows_annotations_size::AbstractFloat = 0.05
    annotations_gap::AbstractFloat = 0.005
end

function Validations.validate_object(configuration::HeatmapGraphConfiguration)::Maybe{AbstractString}
    @assert configuration.annotations_gap >= 0 "negative annotations_gap: $(configuration.annotations_gap)"
    @assert configuration.columns_annotations_size >= 0 "negative columns_annotations_size: $(configuration.columns_annotations_size)"
    @assert configuration.rows_annotations_size >= 0 "negative rows_annotations_size: $(configuration.rows_annotations_size)"
    message = validate_graph_configuration(configuration.figure)
    if message === nothing
        message = validate_colors_configuration("entries", configuration.entries)
    end
    return message
end

"""
    @kwdef mutable struct AnnotationData
        title::Maybe{AbstractString} = nothing
        values::Union{AbstractVector{<:Real}, AbstractVector{<:AbstractString}} = Float32[]
        hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
        colors_configuration::ColorsConfiguration = ColorsConfiguration()
    end

An annotation to attach to an axis. This applies to discrete axes (bars axis for a [`BarGraph`](@ref) or the rows and/or
columns of a [`HeatmapGraph`](@ref)). The number of the `values` and the optional `hovers` must be the same as the
number of entries in the axis.

Colors are controlled via the `colors_configuration`. We include this as part of the data because the color of
annotations (in particular, categorical ones) is tightly coupled with the annotations data. By default, Boolean
annotations are colored black-and-white, and categorical (string) annotations are converted to indices (based on
alphabetical order) and colored using the `HSV` color palette. Other annotations are colored automatically by Plotly.

!!! note

    Trying to directly render a [`QueryString`](@ref) `values` and/or `hovers` (or for the `colors_palette` of the
    `colors_configuration`) will fail. Specifying queries is only supported when passing `AnnotationData` parameter(s)
    to a data extraction function (that also has access to a `Daf` data set to fetch the data from).

!!! note

    Showing the color scale of annotations is not supported.
"""
@kwdef mutable struct AnnotationData
    title::Maybe{AbstractString} = nothing
    values::Union{QueryString, AbstractVector{<:Real}, AbstractVector{<:AbstractString}} = Float32[]
    hovers::Maybe{Union{QueryString, AbstractVector{<:AbstractString}}} = nothing
    colors_configuration::ColorsConfiguration = ColorsConfiguration()
end

"""
    @kwdef mutable struct HeatmapGraphData <: AbstractGraphData
        figure_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        entries_colors_title::Maybe{AbstractString} = nothing
        columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        entries_colors::Maybe{AbstractMatrix{<:Real}} = Float32[;;]
        entries_hovers::Maybe{AbstractMatrix{<:AbstractString}} = nothing
        columns_annotations::Maybe{AbstractVector{AnnotationData}} = nothing
        rows_annotations::Maybe{AbstractVector{AnnotationData}} = nothing
        columns_order::Maybe{AbstractVector{<:Integer}}} = nothing
        rows_order::Maybe{AbstractVector{<:Integer}}} = nothing
    end

The data for a graph showing a heatmap (matrix) of entries.

This is shown as a 2D image where each matrix entry is a small rectangle with some color. Due to Plotly limitation,
colors can't be categorical (or explicit color names).

If `columns_order` and/or `rows_order` are arrays, they should hold a permutation of the 1:n indices expressing the
desired reordering of the columns and/or rows.
"""
@kwdef mutable struct HeatmapGraphData <: AbstractGraphData
    figure_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    entries_colors_title::Maybe{AbstractString} = nothing
    columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    entries_colors::AbstractMatrix{<:Real} = Float32[;;]
    entries_hovers::Maybe{AbstractMatrix{<:AbstractString}} = nothing
    columns_annotations::Maybe{AbstractVector{AnnotationData}} = nothing
    rows_annotations::Maybe{AbstractVector{AnnotationData}} = nothing
    columns_order::Maybe{AbstractVector{<:Integer}} = nothing
    rows_order::Maybe{AbstractVector{<:Integer}} = nothing
end

function Validations.validate_object(data::HeatmapGraphData)::Maybe{AbstractString}
    matrix_size = size(data.entries_colors)

    n_rows, n_columns = matrix_size
    if n_columns == 0
        return "no columns in data.entries_colors"
    end
    if n_rows == 0
        return "no rows in data.entries_colors"
    end

    columns_order = data.columns_order
    if columns_order !== nothing && length(columns_order) !== n_columns
        return "the data.columns_order size: $(length(columns_order))\n" *
               "is different from the number of columns: $(n_columns)"
    end

    rows_order = data.rows_order
    if rows_order !== nothing && length(rows_order) !== n_rows
        return "the data.rows_order size: $(length(rows_order))\n" * "is different from the number of rows: $(n_rows)"
    end

    hovers = data.entries_hovers
    if hovers !== nothing && size(hovers) != matrix_size
        return "the data.entries_hovers size: $(size(hovers))\n" *
               "is different from the data.entries_colors size: $(matrix_size)"
    end

    columns_annotations = data.columns_annotations
    if columns_annotations !== nothing
        for (index, annotation_data) in enumerate(columns_annotations)
            message =
                validate_annotation_data("columns", "data.columns_annotations[$(index)]", annotation_data, n_columns)
            if message !== nothing
                return message
            end
        end
    end

    rows_annotations = data.rows_annotations
    if rows_annotations !== nothing
        for (index, annotation_data) in enumerate(rows_annotations)
            message = validate_annotation_data("rows", "data.rows_annotations[$(index)]", annotation_data, n_rows)
            if message !== nothing
                return message
            end
        end
    end

    return nothing
end

function validate_annotation_data(
    entries::AbstractString,
    of_what::AbstractString,
    annotation_data::AnnotationData,
    n_entries::Integer,
)::Maybe{AbstractString}
    values = annotation_data.values
    if values isa QueryString
        return "invalid (query) $(of_what).values: $(values)"
    end

    if length(values) != n_entries
        return (
            "the $(of_what).values size: $(length(values))\n" *
            "is different from the number of $(entries): $(n_entries)"
        )
    end

    hovers = annotation_data.hovers
    if hovers isa QueryString
        return "invalid (query) $(of_what).hovers: $(hovers)"
    end

    if hovers !== nothing && length(hovers) != n_entries
        return (
            "the $(of_what).hovers size: $(length(annotation_data.hovers))\n" *
            "is different from the number of $(entries): $(n_entries)"
        )
    end

    message = validate_colors_configuration(of_what, annotation_data.colors_configuration)
    if message === nothing
        message = validate_vector_colors("$(of_what).values", values, of_what, annotation_data.colors_configuration)
    end

    return message
end

"""
A graph visualizing a matrix of entries.. See [`HeatmapGraphData`](@ref) and [`HeatmapGraphConfiguration`](@ref).

An advantage of this over a grid is that it can handle large amount of data. Due to Plotly's limitations, you still need
to manually tweak the graph size for best results.
"""
HeatmapGraph = Graph{HeatmapGraphData, HeatmapGraphConfiguration}

"""
    function heatmap_graph(;
        [figure_title::Maybe{AbstractString} = nothing,
        x_axis_title::Maybe{AbstractString} = nothing,
        y_axis_title::Maybe{AbstractString} = nothing,
        entries_colors_title::Maybe{AbstractString} = nothing,
        columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
        rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
        entries_colors::AbstractMatrix{<:Union{AbstractString, Real}} = Float32[;;],
        entries_hovers::Maybe{AbstractMatrix{<:AbstractString}} = nothing],
        columns_annotations::Maybe{AbstractVector{AnnotationData}} = nothing,
        rows_annotations::Maybe{AbstractVector{AnnotationData}} = nothing,
    )::HeatmapGraph

Create a [`GridGraph`](@ref) by initializing only the [`GridGraphData`](@ref) fields.
"""
function heatmap_graph(;
    figure_title::Maybe{AbstractString} = nothing,
    x_axis_title::Maybe{AbstractString} = nothing,
    y_axis_title::Maybe{AbstractString} = nothing,
    entries_colors_title::Maybe{AbstractString} = nothing,
    columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
    rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
    entries_colors::AbstractMatrix{<:Union{AbstractString, Real}} = Float32[;;],
    entries_hovers::Maybe{AbstractMatrix{<:AbstractString}} = nothing,
    columns_annotations::Maybe{AbstractVector{AnnotationData}} = nothing,
    rows_annotations::Maybe{AbstractVector{AnnotationData}} = nothing,
)::HeatmapGraph
    return HeatmapGraph(
        HeatmapGraphData(;
            figure_title = figure_title,
            x_axis_title = x_axis_title,
            y_axis_title = y_axis_title,
            entries_colors_title = entries_colors_title,
            columns_names = columns_names,
            rows_names = rows_names,
            entries_colors = entries_colors,
            entries_hovers = entries_hovers,
            columns_annotations = columns_annotations,
            rows_annotations = rows_annotations,
        ),
        HeatmapGraphConfiguration(),
    )
end

function validate_graph(graph::HeatmapGraph)::Maybe{AbstractString}
    return validate_matrix_colors(
        "data.entries_colors",
        graph.data.entries_colors,
        "configuration.entries",
        graph.configuration.entries,
    )
end

function validate_matrix_colors(
    what_colors::AbstractString,
    colors::Maybe{AbstractMatrix{<:Union{AbstractString, Real}}},
    what_configuration::AbstractString,
    colors_configuration::ColorsConfiguration,
)::Maybe{AbstractString}
    colors_palette = colors_configuration.colors_palette
    if colors isa AbstractMatrix{<:AbstractString}
        n_rows, n_columns = size(colors)
        if colors_palette isa CategoricalColors
            scale_colors = Set{AbstractString}([value for (value, _) in colors_palette])
            for row_index in 1:n_rows
                for column_index in 1:n_columns
                    color = colors[row_index, column_index]
                    if color != "" && !(color in scale_colors)
                        return "categorical $(what_configuration).colors_configuration.colors_palette does not contain $(what_colors)[$(row_index),$(column_index))]: $(color)"
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
    elseif colors !== nothing && colors_palette isa CategoricalColors
        return "non-string $(what_colors) for categorical $(what_configuration).colors_configuration.colors_palette"
    end

    if colors_configuration.show_legend
        if colors === nothing
            return "no $(what_colors) specified for $(what_configuration).colors_configuration.show_legend"
        end
        if colors isa AbstractMatrix{<:AbstractString} && !(colors_configuration.colors_palette isa CategoricalColors)
            return "explicit $(what_colors) specified for $(what_configuration).colors_configuration.show_legend"
        end
    end

    if colors_configuration.color_axis.log_scale !== nothing
        if !(colors isa AbstractMatrix{<:Real})
            return "non-real $(what_colors) with $(what_configuration).colors_configuration.color_axis.log_scale"
        end
        row_index, column_index = argmin(colors).I  # NOJET
        minimal_color = colors[row_index, column_index] + colors_configuration.color_axis.log_regularization
        if minimal_color <= 0
            return "log of non-positive $(what_colors)[$(row_index),$(column_index)]: $(minimal_color)"
        end
    end

    return nothing
end

function graph_to_figure(graph::HeatmapGraph)::PlotlyFigure
    assert_valid_object(graph)

    traces = GenericTrace[]

    coloraxis_index = [1]

    columns_annotations = graph.data.columns_annotations
    rows_annotations = graph.data.rows_annotations
    n_columns_annotations = columns_annotations === nothing ? 0 : length(columns_annotations)
    n_rows_annotations = rows_annotations === nothing ? 0 : length(rows_annotations)

    if columns_annotations === nothing
        patched_columns_annotations = nothing
    else
        patched_columns_annotations = Vector{AnnotationData}(undef, length(columns_annotations))
        for (annotations_index, annotation_data) in enumerate(columns_annotations)
            patched_columns_annotations[annotations_index] =
                patched_annotation_data = patch_annotation_data(annotation_data)
            push!(
                traces,
                annotation_trace(
                    patched_annotation_data;
                    order = graph.data.columns_order,
                    coloraxis_index = coloraxis_index,
                    x_axis_index = n_rows_annotations + 2,
                    y_axis_index = annotations_index + 1,
                    transpose = false,
                ),
            )
        end
    end

    if rows_annotations === nothing
        patched_rows_annotations = nothing
    else
        patched_rows_annotations = Vector{AnnotationData}(undef, length(rows_annotations))
        for (annotations_index, annotation_data) in enumerate(rows_annotations)
            patched_rows_annotations[annotations_index] =
                patched_annotation_data = patch_annotation_data(annotation_data)
            push!(
                traces,
                annotation_trace(
                    patched_annotation_data;
                    order = graph.data.rows_order,
                    coloraxis_index = coloraxis_index,
                    x_axis_index = annotations_index + 1,
                    y_axis_index = n_columns_annotations + 2,
                    transpose = true,
                ),
            )
        end
    end

    push!(traces, heatmap_trace(graph; x_axis_index = n_rows_annotations + 2, y_axis_index = n_columns_annotations + 2))

    layout = heatmap_layout(graph, patched_columns_annotations, patched_rows_annotations)
    return plotly_figure(traces, layout)
end

function heatmap_trace(graph::HeatmapGraph; x_axis_index::Integer, y_axis_index::Integer)::GenericTrace
    n_rows, n_columns = size(graph.data.entries_colors)

    columns_order = graph.data.columns_order
    if columns_order === nothing
        columns_order = 1:n_columns
    end

    rows_order = graph.data.rows_order
    if rows_order === nothing
        rows_order = 1:n_rows
    end

    return heatmap(;
        name = "",
        z = graph.data.entries_colors[rows_order, columns_order],
        xaxis = "x$(x_axis_index)",
        yaxis = "y$(y_axis_index)",
        text = if graph.data.entries_hovers !== nothing
            permutedims(graph.data.entries_hovers[rows_order, columns_order])
        else
            nothing
        end,
        coloraxis = "coloraxis",
    )
end

function patch_annotation_data(annotation_data::AnnotationData)::AnnotationData
    if eltype(annotation_data.values) <: Real
        return annotation_data
    end

    @assert eltype(annotation_data.values) <: AbstractString

    set_of_values = Set(annotation_data.values)
    scale = 1 / length(set_of_values)
    indices_of_values = Dict([value => index * scale for (index, value) in enumerate(sort!(collect(set_of_values)))])
    values = [indices_of_values[value] for value in annotation_data.values]

    hovers = annotation_data.hovers

    colors_palette = annotation_data.colors_configuration.colors_palette
    if colors_palette isa CategoricalColors
        colors_palette =
            [(indices_of_values[value], color) for (value, color) in colors_palette if haskey(indices_of_values, value)]
        if hovers === nothing
            hovers = annotation_data.values
        end
    else
        @assert colors_palette === nothing
        colors_palette = [(index, value) for (value, index) in indices_of_values]
    end

    return AnnotationData(;
        title = annotation_data.title,
        values = values,
        hovers = hovers,
        colors_configuration = ColorsConfiguration(;
            show_legend = annotation_data.colors_configuration.show_legend,
            color_axis = annotation_data.colors_configuration.color_axis,
            reverse = annotation_data.colors_configuration.reverse,
            colors_palette = colors_palette isa AbstractVector ? sort!(colors_palette) : colors_palette,
        ),
    )
end

function annotation_trace(
    data::AnnotationData;
    coloraxis_index::Vector{Int},
    order::Maybe{AbstractVector{<:Integer}},
    x_axis_index::Integer,
    y_axis_index::Integer,
    transpose::Bool,
)::GenericTrace
    coloraxis_index[1] += 1
    if order === nothing
        order = 1:length(data.values)
    end
    return heatmap(;
        name = "",
        z = [Float32.(data.values[order])],
        text = data.hovers === nothing ? nothing : !transpose ? [data.hovers[order]] : permutedims(data.hovers[order]),
        xaxis = "x$(x_axis_index)",
        yaxis = "y$(y_axis_index)",
        coloraxis = "coloraxis$(coloraxis_index[1])",
        transpose = transpose,
    )
end

function heatmap_layout(
    graph::HeatmapGraph,
    columns_annotations::Maybe{AbstractVector{AnnotationData}},
    rows_annotations::Maybe{AbstractVector{AnnotationData}},
)::Layout
    n_rows, n_columns = size(graph.data.entries_colors)

    columns_order = graph.data.columns_order
    if columns_order === nothing
        columns_order = 1:n_columns
    end

    rows_order = graph.data.rows_order
    if rows_order === nothing
        rows_order = 1:n_rows
    end

    color_tickvals, color_ticktext, color_tickprefix =
        log_colors_axis_ticks(graph.data.entries_colors, graph.configuration.entries)

    y_axis_index = 2
    if columns_annotations === nothing
        y_axis_domain = nothing
    else
        total_size =
            (graph.configuration.columns_annotations_size + graph.configuration.annotations_gap) *
            length(columns_annotations)
        y_axis_domain = [total_size, 1]
        y_axis_index += length(columns_annotations)
    end

    x_axis_index = 2
    if rows_annotations === nothing
        x_axis_domain = nothing
    else
        total_size =
            (graph.configuration.rows_annotations_size + graph.configuration.annotations_gap) * length(rows_annotations)
        x_axis_domain = [total_size, 1]
        x_axis_index += length(rows_annotations)
    end

    layout = graph_layout(
        graph.configuration.figure,
        Layout(;  # NOJET
            title = graph.data.figure_title,
            coloraxis_showscale = graph.configuration.entries.show_legend,
            coloraxis_reversescale = graph.configuration.entries.reverse,
            coloraxis_colorscale = normalized_colors_palette(graph.configuration.entries),
            coloraxis_cmin = lowest_color(graph.configuration.entries),
            coloraxis_cmax = highest_color(graph.configuration.entries),
            coloraxis_colorbar_title_text = graph.data.entries_colors_title,
            coloraxis_colorbar_tickvals = color_tickvals,
            coloraxis_colorbar_ticktext = color_ticktext,
            coloraxis_colorbar_tickprefix = color_tickprefix,
        ),
    )
    layout[Symbol("xaxis$(x_axis_index)")] = Dict(
        :showgrid => graph.configuration.figure.show_grid,
        :showticklabels => graph.configuration.figure.show_ticks && graph.data.columns_names !== nothing,
        :title => graph.data.x_axis_title,
        :tickvals => graph.data.columns_names === nothing ? nothing : collect(0:(n_columns - 1)),
        :tickangle => graph.data.columns_names === nothing ? nothing : -45,
        :ticktext => graph.data.columns_names === nothing ? nothing : graph.data.columns_names[columns_order],
        :domain => x_axis_domain,
    )
    layout[Symbol("yaxis$(y_axis_index)")] = Dict(
        :showgrid => graph.configuration.figure.show_grid,
        :showticklabels => graph.configuration.figure.show_ticks && graph.data.rows_names !== nothing,
        :title => graph.data.y_axis_title,
        :ticktext => graph.data.rows_names === nothing ? nothing : graph.data.rows_names[rows_order],
        :tickvals => graph.data.rows_names === nothing ? nothing : collect(0:(n_rows - 1)),
        :domain => y_axis_domain,
    )

    shapes = [borders_rectangle(x_axis_domain, y_axis_domain)]
    layout[:shapes] = shapes

    coloraxis_index = 1

    if columns_annotations !== nothing
        bottom_size = 0
        for (annotations_index, annotation_data) in enumerate(columns_annotations)
            coloraxis_index += 1
            colors_palette = normalized_colors_palette(annotation_data.colors_configuration)
            layout[Symbol("coloraxis$(coloraxis_index)")] = Dict(
                :colorscale => colors_palette,
                :cmin => lowest_color(annotation_data.colors_configuration),
                :cmax => highest_color(annotation_data.colors_configuration),
                :showscale => false,
                :reversescale => annotation_data.colors_configuration.reverse,
            )
            top_size = bottom_size + graph.configuration.columns_annotations_size
            domain = [bottom_size, top_size]
            bottom_size = top_size + graph.configuration.annotations_gap
            layout[Symbol("yaxis$(annotations_index + 1)")] = Dict(
                :showgrid => graph.configuration.figure.show_grid,
                :ticktext => [annotation_data.title !== nothing ? annotation_data.title : ""],
                :tickvals => [0],
                :domain => domain,
            )
            if shapes !== nothing
                push!(shapes, borders_rectangle(x_axis_domain, domain))
            end
        end
    end

    if rows_annotations !== nothing
        bottom_size = 0
        for (annotations_index, annotation_data) in enumerate(rows_annotations)
            coloraxis_index += 1
            colors_palette = normalized_colors_palette(annotation_data.colors_configuration)
            layout[Symbol("coloraxis$(coloraxis_index)")] = Dict(
                :colorscale => colors_palette,
                :cmin => lowest_color(annotation_data.colors_configuration),
                :cmax => highest_color(annotation_data.colors_configuration),
                :showscale => false,
                :reversescale => annotation_data.colors_configuration.reverse,
            )
            top_size = bottom_size + graph.configuration.rows_annotations_size
            domain = [bottom_size, top_size]
            bottom_size = top_size + graph.configuration.annotations_gap
            layout[Symbol("xaxis$(annotations_index + 1)")] = Dict(
                :showgrid => graph.configuration.figure.show_grid,
                :ticktext => [annotation_data.title !== nothing ? annotation_data.title : ""],
                :tickvals => [0],
                :tickangle => -45,
                :domain => domain,
            )
            if shapes !== nothing
                push!(shapes, borders_rectangle(domain, y_axis_domain))
            end
        end
    end

    return layout
end

function borders_rectangle(x_domain::Maybe{Vector{<:Real}}, y_domain::Maybe{Vector{<:Real}})::Dict
    x0, x1 = domain_low_high(x_domain)
    y0, y1 = domain_low_high(y_domain)
    return Dict(
        :type => "rectangle",
        :x0 => x0,
        :x1 => x1,
        :y0 => y0,
        :y1 => y1,
        :xref => "paper",
        :yref => "paper",
        :line => Dict(:width => 1),
    )
end

function domain_low_high(::Nothing)::Tuple{Real, Real}
    return 0, 1
end

function domain_low_high(domain::Vector{<:Real})::Tuple{Real, Real}
    return domain[1], domain[2]
end

function log_colors_axis_ticks(
    colors::Maybe{Union{AbstractVector{<:Union{Real, AbstractString}}, AbstractMatrix{<:Union{Real, AbstractString}}}},
    colors_configuration::ColorsConfiguration,
)::Tuple{Maybe{Vector{Float32}}, Maybe{Vector{String}}, Maybe{String}}
    log_colors_axis = colors_configuration.color_axis.log_scale
    if log_colors_axis === nothing || !colors_configuration.show_legend
        return (nothing, nothing, nothing)
    elseif log_colors_axis == Log2Scale
        return (nothing, nothing, "<sub>2</sub>")
    elseif log_colors_axis == Log10Scale
        log_colors_axis_regularization = colors_configuration.color_axis.log_regularization
        @assert colors isa AbstractVector{<:Real}
        cmin = lowest_color(colors_configuration)  # NOJET
        if cmin === nothing
            cmin = log10(minimum(colors) + log_colors_axis_regularization)
        end
        cmax = highest_color(colors_configuration)  # NOJET
        if cmax === nothing
            cmax = log10(maximum(colors) + log_colors_axis_regularization)
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
            tickvals[tick_index + 1] = at + log10(2)
            tickvals[tick_index + 2] = at + log10(5)
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
        return (tickvals, log10_tick_text_for_vals(tickvals, first_int_index), nothing)
    else
        @assert false
    end
end

function log10_tick_text_for_vals(tickvals::AbstractVector{Float32}, first_int_index::Int)::Vector{String}
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

function graph_layout(configuration::FigureConfiguration, layout::Layout)::Layout
    layout["margin"] = Dict(
        :l => configuration.margins.left,
        :r => configuration.margins.right,
        :t => configuration.margins.top,
        :b => configuration.margins.bottom,
    )
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

function plotly_figure(trace::GenericTrace, layout::Layout)::PlotlyFigure
    purge_nulls!(trace.fields)
    purge_nulls!(layout.fields)
    return plot(trace, layout)  # NOJET
end

function plotly_figure(traces::AbstractVector{<:GenericTrace}, layout::Layout)::PlotlyFigure
    for trace in traces
        purge_nulls!(trace.fields)
    end
    purge_nulls!(layout.fields)
    return plot(traces, layout)
end

function purge_nulls!(dict::T)::T where {T <: AbstractDict}
    for (_, value) in dict
        if value isa AbstractDict
            purge_nulls!(value)
        end
    end
    filter!(dict) do pair
        return pair.second !== nothing && !(pair.second isa AbstractDict && isempty(pair.second))
    end
    return dict
end

end  # module
