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
export CdfDownToValue
export CdfGraphConfiguration
export CdfGraphData
export CdfUpToValue
export CdfsGraphConfiguration
export CdfsGraphData
export DistributionGraphConfiguration
export DistributionGraphData
export DistributionStyleConfiguration
export DistributionsGraphConfiguration
export DistributionsGraphData
export GraphConfiguration
export GridGraphConfiguration
export GridGraphData
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
export ValuesOrientation
export VerticalValues
export render

using ..Validations

using Colors
using Daf.GenericTypes
using PlotlyJS

import PlotlyJS.SyncPlot

"""
The type of a rendered graph. See [`render`](@ref).

A figure contains everything needed to display an interactive graph (or generate a static one on disk). It can also be
converted to a JSON string for handing it over to a different programming language (e.g., to be used to display the
interactive graph in a Python Jupyter notebook, given an appropriate wrapper code).
"""
Figure = Union{Plot, SyncPlot}

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
@kwdef mutable struct GraphConfiguration <: ObjectWithValidation
    width::Maybe{Int} = nothing
    height::Maybe{Int} = nothing
    template::AbstractString = "simple_white"
    show_grid::Bool = true
    show_ticks::Bool = true
end

function Validations.validate_object(configuration::GraphConfiguration)::Maybe{AbstractString}
    width = configuration.width
    if width !== nothing && width <= 0
        return "non-positive configuration.graph.width: $(width)"
    end

    height = configuration.height
    if height !== nothing && height <= 0
        return "non-positive configuration.graph.height: $(height)"
    end

    return nothing
end

"""
    @kwdef mutable struct AxisConfiguration <: ObjectWithValidation
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
@kwdef mutable struct AxisConfiguration <: ObjectWithValidation
    minimum::Maybe{Real} = nothing
    maximum::Maybe{Real} = nothing
    log_regularization::Maybe{AbstractFloat} = nothing
end

function Validations.validate_object(name::AbstractString, configuration::AxisConfiguration)::Maybe{AbstractString}
    minimum = configuration.minimum
    maximum = configuration.maximum

    if minimum !== nothing && maximum !== nothing && maximum <= minimum
        return "configuration.$(name)_axis.maximum: $(maximum)\n" *
               "is not larger than configuration.$(name)_axis.minimum: $(minimum)"
    end

    log_regularization = configuration.log_regularization
    if log_regularization !== nothing
        if log_regularization < 0
            return "negative configuration.$(name)_axis.log_regularization: $(log_regularization)"
        end

        if minimum !== nothing && minimum + log_regularization <= 0
            return "log of non-positive configuration.$(name)_axis.minimum: $(minimum + log_regularization)"
        end

        if maximum !== nothing && maximum + log_regularization <= 0
            return "log of non-positive configuration.$(name)_axis.maximum: $(maximum + log_regularization)"
        end
    end

    return nothing
end

"""
    @kwdef mutable struct DistributionStyleConfiguration <: ObjectWithValidation
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
@kwdef mutable struct DistributionStyleConfiguration <: ObjectWithValidation
    values_orientation::ValuesOrientation = VerticalValues
    show_box::Bool = true
    show_violin::Bool = false
    show_curve::Bool = false
    show_outliers::Bool = false
    color::Maybe{AbstractString} = nothing
end

function Validations.validate_object(configuration::DistributionStyleConfiguration)::Maybe{AbstractString}
    if !configuration.show_box && !configuration.show_violin && !configuration.show_curve
        return "must specify at least one of: configuration.distribution_style.show_box, configuration.distribution_style.show_violin, configuration.distribution_style.show_curve"
    end

    if configuration.show_violin && configuration.show_curve
        return "must not specify both of: configuration.distribution_style.show_violin, configuration.distribution_style.show_curve"
    end

    return validate_color("configuration.distribution_style.color", configuration.color)
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
        distribution_style::DistributionStyleConfiguration = DistributionStyleConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
    end

Configure a graph for showing a distribution (with [`DistributionGraphData`](@ref)) or several distributions (with
[`DistributionsGraphData`](@ref)).

The optional `color` will be chosen automatically if not specified. When showing multiple distributions, it is also
possible to specify the color of each one in the [`DistributionsGraphData`](@ref).
"""
@kwdef mutable struct DistributionGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    distribution_style::DistributionStyleConfiguration = DistributionStyleConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
end

function Validations.validate_object(configuration::DistributionGraphConfiguration)::Maybe{AbstractString}
    message = validate_object(configuration.graph)
    if message === nothing
        message = validate_object(configuration.distribution_style)
    end
    if message === nothing
        message = validate_object("value", configuration.value_axis)
    end
    return message
end

"""
    @kwdef mutable struct DistributionsGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        distribution_style::DistributionStyleConfiguration = DistributionStyleConfiguration()
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
    distribution_style::DistributionStyleConfiguration = DistributionStyleConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    show_legend::Bool = false
    distributions_gap::Maybe{Real} = nothing
    overlay_distributions::Bool = false
end

function Validations.validate_object(configuration::DistributionsGraphConfiguration)::Maybe{AbstractString}
    message = validate_object(configuration.graph)
    if message === nothing
        message = validate_object(configuration.distribution_style)
    end
    if message === nothing
        message = validate_object("value", configuration.value_axis)
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
        distribution_values::AbstractVector{<:Real}
        distribution_name::Maybe{AbstractString} = nothing
    end

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title` and
the `trace_axis_title`. The optional `distribution_name` is used as the tick value for the distribution.
"""
@kwdef mutable struct DistributionGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    trace_axis_title::Maybe{AbstractString} = nothing
    distribution_values::AbstractVector{<:Real}
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
        distributions_values::AbstractVector{AbstractVector{<:Real}}
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
    distributions_values::AbstractVector{AbstractVector{<:Real}}
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

const BOX = 1
const VIOLIN = 2
const CURVE = 4

"""
    render(
        data::AbstractGraphData,
        configuration::AbstractGraphConfiguration = ...,
    )::Figure

Render a graph given its data and configuration. The implementation depends on the specific graph. For each
[`AbstractGraphData`](@ref) there is a matching [`AbstractGraphConfiguration`](@ref) (a default one is provided for the
`configuration`). The supported type pairs are:

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

This returns a [`Figure`](@ref) which can be displayed directly, or converted to JSON for transfer to other programming languages
(Python or R)
"""
function render(
    data::DistributionGraphData,
    configuration::DistributionGraphConfiguration = DistributionGraphConfiguration(),
    output_file::Maybe{AbstractString} = nothing,
)::Figure
    assert_valid_object(data)
    assert_valid_object(configuration)

    trace = distribution_trace(;  # NOJET
        distribution_values = data.distribution_values,
        distribution_name = data.distribution_name === nothing ? "Trace" : data.distribution_name,
        color = configuration.distribution_style.color,
        legend_title = nothing,
        configuration = configuration,
        overlay_distributions = false,
    )

    layout = distribution_layout(
        data,
        configuration;
        has_tick_names = data.distribution_name !== nothing,
        show_legend = false,
        distributions_gap = nothing,
    )
    figure = plot(trace, layout)
    write_figure_to_file(figure, configuration.graph, output_file)

    return figure
end

function render(
    data::DistributionsGraphData,
    configuration::DistributionsGraphConfiguration = DistributionsGraphConfiguration(),
    output_file::Maybe{AbstractString} = nothing,
)::Figure
    assert_valid_object(data)
    assert_valid_object(configuration)
    if configuration.distributions_gap !== nothing && configuration.distribution_style.show_curve
        @warn "setting the distributions_gap for curve is buggy in plotly"
    end

    n_distributions = length(data.distributions_values)
    traces = [
        distribution_trace(;
            distribution_values = data.distributions_values[index],
            distribution_name = if data.distributions_names === nothing
                "Trace $(index)"
            else
                data.distributions_names[index]
            end,
            color = if data.distributions_colors === nothing
                configuration.distribution_style.color
            else
                data.distributions_colors[index]
            end,
            legend_title = data.legend_title,
            configuration = configuration,
            overlay_distributions = configuration.overlay_distributions,
        ) for index in 1:n_distributions
    ]

    layout = distribution_layout(
        data,
        configuration;
        has_tick_names = data.distributions_names !== nothing,
        show_legend = configuration.show_legend,
        distributions_gap = configuration.distributions_gap,
    )
    figure = plot(traces, layout)
    write_figure_to_file(figure, configuration.graph, output_file)

    return figure
end

function distribution_trace(;
    distribution_values::AbstractVector{<:Real},
    distribution_name::AbstractString,
    color::Maybe{AbstractString},
    legend_title::Maybe{AbstractString},
    configuration::Union{DistributionGraphConfiguration, DistributionsGraphConfiguration},
    overlay_distributions::Bool,
)::GenericTrace
    style = (
        (configuration.distribution_style.show_box ? BOX : 0) |
        (configuration.distribution_style.show_violin ? VIOLIN : 0) |
        (configuration.distribution_style.show_curve ? CURVE : 0)
    )

    if configuration.distribution_style.values_orientation == VerticalValues
        x = nothing
        y = distribution_values
        x0 = overlay_distributions ? " " : nothing
        y0 = nothing
    elseif configuration.distribution_style.values_orientation == HorizontalValues
        x = distribution_values
        y = nothing
        x0 = nothing
        y0 = overlay_distributions ? " " : nothing
    else
        @assert false
    end

    points = configuration.distribution_style.show_outliers ? "outliers" : false
    tracer = style == BOX ? box : violin

    return tracer(;
        x = x,
        y = y,
        x0 = x0,
        y0 = y0,
        side = configuration.distribution_style.show_curve ? "positive" : nothing,
        box_visible = configuration.distribution_style.show_box,
        boxpoints = points,
        points = points,
        name = distribution_name,
        marker_color = color,
        legendgrouptitle_text = legend_title,
    )
end

function distribution_layout(
    data::Union{DistributionGraphData, DistributionsGraphData},
    configuration::Union{DistributionGraphConfiguration, DistributionsGraphConfiguration};
    has_tick_names::Bool,
    show_legend::Bool,
    distributions_gap::Maybe{Real},
)::Layout
    if configuration.distribution_style.values_orientation == VerticalValues
        xaxis_showticklabels = has_tick_names
        xaxis_showgrid = false
        xaxis_title = data.trace_axis_title
        xaxis_range = (nothing, nothing)
        xaxis_type = nothing
        yaxis_showticklabels = configuration.graph.show_ticks
        yaxis_showgrid = configuration.graph.show_grid
        yaxis_title = data.value_axis_title
        yaxis_range = (configuration.value_axis.minimum, configuration.value_axis.maximum)
        yaxis_type = configuration.value_axis.log_regularization !== nothing ? "log" : nothing
    elseif configuration.distribution_style.values_orientation == HorizontalValues
        xaxis_showticklabels = configuration.graph.show_ticks
        xaxis_showgrid = configuration.graph.show_grid
        xaxis_title = data.value_axis_title
        xaxis_range = (configuration.value_axis.minimum, configuration.value_axis.maximum)
        xaxis_type = configuration.value_axis.log_regularization !== nothing ? "log" : nothing
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
        violingroupgap = distributions_gap === nothing ? nothing : 0,
        boxgroupgap = distributions_gap === nothing ? nothing : 0,
        boxgap = distributions_gap,
        violingap = distributions_gap,
    )
end

"""
    @kwdef mutable struct LineStyleConfiguration <: ObjectWithValidation
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
@kwdef mutable struct LineStyleConfiguration <: ObjectWithValidation
    width::Maybe{Real} = 1
    is_filled::Bool = false
    is_dashed::Bool = false
    color::Maybe{AbstractString} = nothing
end

function Validations.validate_object(configuration::LineStyleConfiguration)::Maybe{AbstractString}
    width = configuration.width
    if width !== nothing && width <= 0
        return "non-positive configuration.line_style.width: $(width)"
    end
    if width === nothing && !configuration.is_filled
        return "either configuration.line_style.width or configuration.line_style.is_filled must be specified"
    end
    return validate_color("configuration.line_style.color", configuration.color)
end

"""
    @kwdef mutable struct BandStyleConfiguration <: ObjectWithValidation
        offset::Maybe{Real} = nothing
        color::Maybe{AbstractString} = nothing
        width::Maybe{Real} = 1.0
        is_dashed::Bool = false
        is_filled::Bool = false
    end

Configure a region of the graph defined by some band of values. This is the same as a `LineStyleConfiguration` (for
controlling the style of the line drawn for the band) with the addition of the `offset` of the line's position. We allow
up to three bands in a complete [`BandsConfiguration`](@ref). The low and high bands are defined as below and above
their line's `offset`, and do not exist if the `offset` is not specified. The middle band is defined to be between these
two lines (and therefore only exists if both are specified). Its `offset` defined a center line, if one is to be
displayed, and is therefore optional.
"""
@kwdef mutable struct BandStyleConfiguration <: ObjectWithValidation
    offset::Maybe{Real} = nothing
    color::Maybe{AbstractString} = nothing
    width::Maybe{Real} = 1.0
    is_dashed::Bool = false
    is_filled::Bool = false
end

function Validations.validate_object(
    of_what::AbstractString,
    of_which::AbstractString,
    configuration::BandStyleConfiguration,
    log_scale::Bool,
)::Maybe{AbstractString}
    if configuration.width !== nothing && configuration.width <= 0
        return "non-positive configuration.$(of_what).$(of_which).width: $(configuration.width)"
    end
    if log_scale && configuration.offset !== nothing && configuration.offset <= 0
        return "log of non-positive configuration.$(of_what).$(of_which).offset: $(configuration.offset)"
    end
    if !is_valid_color(configuration.color)
        return "invalid configuration.$(of_what).$(of_which).color: $(configuration.color)"
    end
    return nothing
end

"""
    @kwdef mutable struct BandsConfiguration <: ObjectWithValidation
        low_band_style::BandStyleConfiguration = BandStyleConfiguration(is_dashed = true)
        middle_band_style::BandStyleConfiguration = BandStyleConfiguration()
        high_band_style::BandStyleConfiguration = BandStyleConfiguration(is_dashed = true)
    end

Configure the partition of the graph up to three band regions. The `low_band_style` and `high_band_style` are for the
"outer" regions (so their lines are at their border, dashed by default) and the `middle_band_style` is for the "inner"
region between them (so its line is inside it, solid by default).
"""
@kwdef mutable struct BandsConfiguration <: ObjectWithValidation
    low_band_style::BandStyleConfiguration = BandStyleConfiguration(; is_dashed = true)
    middle_band_style::BandStyleConfiguration = BandStyleConfiguration()
    high_band_style::BandStyleConfiguration = BandStyleConfiguration(; is_dashed = true)
end

function Validations.validate_object(
    of_what::AbstractString,
    configuration::BandsConfiguration,
    log_scale::Bool,
)::Maybe{AbstractString}
    message = validate_object(of_what, "low_band_style", configuration.low_band_style, log_scale)
    if message === nothing
        message = validate_object(of_what, "middle_band_style", configuration.middle_band_style, log_scale)
    end
    if message === nothing
        message = validate_object(of_what, "high_band_style", configuration.high_band_style, log_scale)
    end
    if message !== nothing
        return message
    end

    low_line_offset = configuration.low_band_style.offset
    middle_line_offset = configuration.middle_band_style.offset
    high_line_offset = configuration.high_band_style.offset

    if low_line_offset !== nothing && middle_line_offset !== nothing && low_line_offset >= middle_line_offset
        return "configuration.$(of_what).low_band_style.offset: $(low_line_offset)\n" *
               "is not less than configuration.$(of_what).middle_band_style.offset: $(low_line_offset)"
    end

    if middle_line_offset !== nothing && high_line_offset !== nothing && middle_line_offset >= high_line_offset
        return "configuration.$(of_what).high_band_style.offset: $(high_line_offset)\n" *
               "is not greater than configuration.$(of_what).middle_band_style.offset: $(middle_line_offset)"
    end

    if low_line_offset !== nothing && high_line_offset !== nothing && low_line_offset >= high_line_offset
        return "configuration.$(of_what).low_band_style.offset: $(low_line_offset)\n" *
               "is not less than configuration.$(of_what).high_band_style.offset: $(high_line_offset)"
    end

    return nothing
end

"""
    @kwdef mutable struct LineGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        line_style::LineStyleConfiguration = LineStyleConfiguration()
        vertical_bands::BandsConfiguration = BandsConfiguration()
        horizontal_bands::BandsConfiguration = BandsConfiguration()
    end

Configure a graph for showing line plots.
"""
@kwdef mutable struct LineGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    line_style::LineStyleConfiguration = LineStyleConfiguration()
    vertical_bands::BandsConfiguration = BandsConfiguration()
    horizontal_bands::BandsConfiguration = BandsConfiguration()
end

"""
    @kwdef mutable struct LineGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        points_xs::AbstractVector{<:Real}
        points_ys::AbstractVector{<:Real}
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
    points_xs::AbstractVector{<:Real}
    points_ys::AbstractVector{<:Real}
end

function Validations.validate_object(data::LineGraphData)::Maybe{AbstractString}
    if length(data.points_xs) != length(data.points_ys)
        return "the data.points_xs size: $(length(data.points_xs))\n" *
               "is different from the data.points_ys size: $(length(data.points_ys))"
    end
    return nothing
end

function render(
    data::LineGraphData,
    configuration::LineGraphConfiguration = LineGraphConfiguration(),
    output_file::Maybe{AbstractString} = nothing,
)::Figure
    assert_valid_object(data)
    assert_valid_object(configuration)

    traces = Vector{GenericTrace}()

    minimum_x = minimum(data.points_xs)
    minimum_y = minimum(data.points_ys)
    maximum_x = maximum(data.points_xs)
    maximum_y = maximum(data.points_ys)

    push_fill_vertical_bands_traces(traces, configuration.vertical_bands, minimum_x, minimum_y, maximum_x, maximum_y)
    push_fill_horizontal_bands_traces(
        traces,
        configuration.horizontal_bands,
        minimum_x,
        minimum_y,
        maximum_x,
        maximum_y,
    )

    push!(traces, line_trace(data, configuration.line_style))

    for band in (
        configuration.vertical_bands.low_band_style,
        configuration.vertical_bands.middle_band_style,
        configuration.vertical_bands.high_band_style,
    )
        if band.offset !== nothing && band.width !== nothing
            push!(traces, vertical_line_trace(band, minimum_y, maximum_y))
        end
    end

    for band in (
        configuration.horizontal_bands.low_band_style,
        configuration.horizontal_bands.middle_band_style,
        configuration.horizontal_bands.high_band_style,
    )
        if band.offset !== nothing && band.width !== nothing
            push!(traces, horizontal_line_trace(band, minimum_x, maximum_x))
        end
    end

    layout = lines_layout(data, configuration; show_legend = false)
    figure = plot(traces, layout)
    write_figure_to_file(figure, configuration.graph, output_file)

    return figure
end

function line_trace(data::LineGraphData, line_style::LineStyleConfiguration)::GenericTrace
    return scatter(;
        x = data.points_xs,
        y = data.points_ys,
        line_color = line_style.color,
        line_width = line_style.width === nothing ? 0 : line_style.width,
        line_dash = line_style.is_dashed ? "dash" : nothing,
        fill = line_style.is_filled ? "tozeroy" : nothing,
        name = "",
        mode = "lines",
    )
end

"""
If stacking multiple data sets, how:

`StackValues` - simply add the values on top of each other.

`StackFractions` - normalize the added values so their some is 1. The values must not be negative.

`StackPercents` - normalize the added values so their some is 100 (percent). The values must not be negative.
"""
@enum Stacking StackValues StackFractions StackPercents

"""
    @kwdef mutable struct LinesGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        line_style::LineStyleConfiguration = LineStyleConfiguration()
        vertical_bands::BandsConfiguration = BandsConfiguration()
        horizontal_bands::BandsConfiguration = BandsConfiguration()
        show_legend::Bool = false
        stacking::Maybe{Stacking} = nothing
    end

Configure a graph for showing multiple line plots. This allows using `show_legend` to display a legend of the different
lines, and `stacking` to stack instead of overlay the lines. If `stacking` is specified, then `is_filled` is implied,
regardless of what its actual setting is.
"""
@kwdef mutable struct LinesGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    line_style::LineStyleConfiguration = LineStyleConfiguration()
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
        message = validate_object(configuration.line_style)
    end
    if message === nothing
        message = validate_object(
            "vertical_bands",
            configuration.vertical_bands,
            configuration.x_axis.log_regularization !== nothing,
        )
    end
    if message === nothing
        message = validate_object(
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
        lines_xs::AbstractVector{AbstractVector{<:Real}}
        lines_ys::AbstractVector{AbstractVector{<:Real}}
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
options of the `line_style` must not be used.
"""
@kwdef mutable struct LinesGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    lines_xs::AbstractVector{AbstractVector{<:Real}}
    lines_ys::AbstractVector{AbstractVector{<:Real}}
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

function render(
    data::LinesGraphData,
    configuration::LinesGraphConfiguration = LinesGraphConfiguration(),
    output_file::Maybe{AbstractString} = nothing,
)::Figure
    assert_valid_object(data)
    assert_valid_object(configuration)
    if configuration.stacking == StackPercents || configuration.stacking == StackFractions
        for (line_index, points_ys) in enumerate(data.lines_ys)
            for (point_index, point_y) in enumerate(points_ys)
                @assert point_y >= 0 "negative stacked fraction/percent data.lines_ys[$(line_index),$(point_index)]: $(point_y)"
            end
        end
    end

    if configuration.stacking === nothing
        lines_xs = data.lines_xs
        lines_ys = data.lines_ys
    else
        lines_xs, lines_ys = unify_xs(data.lines_xs, data.lines_ys)
    end

    traces = Vector{GenericTrace}()

    for index in 1:length(data.lines_xs)
        push!(
            traces,
            lines_trace(
                data,
                configuration;
                points_xs = lines_xs[index],
                points_ys = lines_ys[index],
                index = index,
                legend_title = data.legend_title,
            ),
        )
    end

    layout = lines_layout(data, configuration; show_legend = configuration.show_legend)
    figure = plot(traces, layout)
    write_figure_to_file(figure, configuration.graph, output_file)

    return figure
end

function unify_xs(
    lines_xs::AbstractVector{<:AbstractVector{<:Real}},
    lines_ys::AbstractVector{<:AbstractVector{<:Real}},
)::Tuple{Vector{Vector{Float32}}, Vector{Vector{Float32}}}
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
            return (unified_xs, unified_ys)
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
                    push!(unified_ys[line_index], prev_y + (next_y - prev_y) * (unified_x - prev_x) / (next_x - prev_x))
                end
            end
        end
    end
end

function lines_trace(
    data::LinesGraphData,
    configuration::LinesGraphConfiguration;
    points_xs::AbstractVector{<:Real},
    points_ys::AbstractVector{<:Real},
    index::Int,
    legend_title::Maybe{AbstractString},
)::GenericTrace
    return scatter(;
        x = points_xs,
        y = points_ys,
        line_color = data.lines_colors !== nothing ? data.lines_colors[index] : configuration.line_style.color,
        line_width = if data.lines_widths !== nothing
            data.lines_widths[index]
        elseif configuration.line_style.width === nothing
            0
        else
            configuration.line_style.width  # NOJET
        end,
        line_dash = if (
            data.lines_are_dashed !== nothing ? data.lines_are_dashed[index] : configuration.line_style.is_dashed
        )
            "dash"
        else
            nothing
        end,
        fill = if !(
            data.lines_are_filled !== nothing ? data.lines_are_filled[index] : configuration.line_style.is_filled
        )
            nothing
        elseif index == length(data.lines_xs)
            "tozeroy"
        else
            "tonexty"
        end,
        name = data.lines_names !== nothing ? data.lines_names[index] : "Trace $(index)",
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
        xaxis_type = configuration.x_axis.log_regularization !== nothing ? "log" : nothing,
        yaxis_showgrid = configuration.graph.show_grid,
        yaxis_showticklabels = configuration.graph.show_ticks,
        yaxis_title = data.y_axis_title,
        yaxis_range = (configuration.y_axis.minimum, configuration.y_axis.maximum),
        yaxis_type = configuration.y_axis.log_regularization !== nothing ? "log" : nothing,
        showlegend = show_legend,
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
        line_style::LineStyleConfiguration = LineStyleConfiguration()
        values_orientation::ValuesOrientation = HorizontalValues
        cdf_direction::CdfDirection = CdfUpToValue
        value_bands::BandsConfiguration = BandsConfiguration()
        fraction_bands::BandsConfiguration = BandsConfiguration()
    end

Configure a graph for showing a CDF (Cumulative Distribution Function) graph. By default, the X axis is used for the
values and the Y axis for the fraction; this can be switched using the `values_orientation`. By default, the fraction is
of the values up to each value; this can be switched using the `cdf_direction`.

By default, the fraction axis units are between 0 and 1; if `show_percent`, this is changed to between 0 and 100.

CDF graphs are internally converted to line graphs for rendering.
"""
@kwdef mutable struct CdfGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    value_axis::AxisConfiguration = AxisConfiguration()
    fraction_axis::AxisConfiguration = AxisConfiguration()
    line_style::LineStyleConfiguration = LineStyleConfiguration()
    values_orientation::ValuesOrientation = HorizontalValues
    cdf_direction::CdfDirection = CdfUpToValue
    value_bands::BandsConfiguration = BandsConfiguration()
    fraction_bands::BandsConfiguration = BandsConfiguration()
    show_percent::Bool = false
end

"""
    @kwdef mutable struct CdfGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        value_axis_title::Maybe{AbstractString} = nothing
        fraction_axis_title::Maybe{AbstractString} = nothing
        line_values::AbstractVector{<:Real}
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
    line_values::AbstractVector{<:Real}
end

function Validations.validate_object(data::CdfGraphData)::Maybe{AbstractString}
    if length(data.line_values) < 2
        return "too few data.line_values: $(length(data.line_values))"
    end
    # TRICKY: Validation will be done by the `LineGraphData` we will convert to.
    return nothing
end

function render(
    data::CdfGraphData,
    configuration::CdfGraphConfiguration = CdfGraphConfiguration(),
    output_file::Maybe{AbstractString} = nothing,
)::Figure
    assert_valid_object(data)
    assert_valid_object(configuration)

    line_data = cdf_data_as_line_data(data, configuration)
    line_configuration = cdf_configuration_as_line_configuration(configuration)
    return render(line_data, line_configuration, output_file)
end

function cdf_data_as_line_data(data::CdfGraphData, configuration::CdfGraphConfiguration)::LineGraphData
    values, fractions = collect_cdf_data(data.line_values, configuration)
    if configuration.values_orientation == HorizontalValues
        return LineGraphData(;
            graph_title = data.graph_title,
            x_axis_title = data.value_axis_title,
            y_axis_title = data.fraction_axis_title,
            points_xs = values,
            points_ys = fractions,
        )
    else
        return LineGraphData(;
            graph_title = data.graph_title,
            x_axis_title = data.fraction_axis_title,
            y_axis_title = data.value_axis_title,
            points_xs = fractions,
            points_ys = values,
        )
    end
end

function cdf_configuration_as_line_configuration(configuration::CdfGraphConfiguration)::LineGraphConfiguration
    if configuration.values_orientation == HorizontalValues
        return LineGraphConfiguration(;
            graph = configuration.graph,
            x_axis = configuration.value_axis,
            y_axis = configuration.fraction_axis,
            line_style = configuration.line_style,
            vertical_bands = configuration.value_bands,
            horizontal_bands = configuration.fraction_bands,
        )
    else
        return LineGraphConfiguration(;
            graph = configuration.graph,
            x_axis = configuration.fraction_axis,
            y_axis = configuration.value_axis,
            line_style = configuration.line_style,
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
        line_style::LineStyleConfiguration = LineStyleConfiguration()
        values_orientation::ValuesOrientation = HorizontalValues
        cdf_direction::CdfDirection = CdfUpToValue
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
    line_style::LineStyleConfiguration = LineStyleConfiguration()
    values_orientation::ValuesOrientation = HorizontalValues
    cdf_direction::CdfDirection = CdfUpToValue
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
        message = validate_object(configuration.line_style)
    end
    if message === nothing
        message = validate_object(
            "value_bands",
            configuration.value_bands,
            configuration.value_axis.log_regularization !== nothing,
        )
    end
    if message === nothing
        message = validate_object(
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
        lines_values::AbstractVector{<:AbstractVector{<:Real}}
        lines_names::Maybe{AbstractVector{<:AbstractString}} = nothing
        lines_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
        lines_widths::Maybe{AbstractVector{<:Real}} = nothing
        lines_are_filled::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing
        lines_are_dashed::Maybe{AbstractVector{Bool}} = nothing
    end

The data for multiple CDFs (Cumulative Distribution Functions) graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title` and
`fraction_axis_title` for the axes.

The order of the entries inside each of the `lines_values` does not matter.
"""
@kwdef mutable struct CdfsGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    fraction_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    lines_values::AbstractVector{<:AbstractVector{<:Real}}
    lines_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    lines_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
    lines_widths::Maybe{AbstractVector{<:Real}} = nothing
    lines_are_filled::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing
    lines_are_dashed::Maybe{AbstractVector{Bool}} = nothing
end

function Validations.validate_object(data::CdfsGraphData)::Maybe{AbstractString}
    if length(data.lines_values) == 0
        return "empty data.lines_values vector"
    end
    for (index, values) in enumerate(data.lines_values)
        if length(values) < 2
            return "too few data.lines_values[$(index)]: $(length(values))"
        end
    end
    # TRICKY: Validation will be done by the `LinesGraphData` we will convert to.
    return nothing
end

function render(
    data::CdfsGraphData,
    configuration::CdfsGraphConfiguration = CdfsGraphConfiguration(),
    output_file::Maybe{AbstractString} = nothing,
)::Figure
    assert_valid_object(data)
    assert_valid_object(configuration)

    lines_data = cdfs_data_as_lines_data(data, configuration)
    lines_configuration = cdfs_configuration_as_lines_configuration(configuration)
    return render(lines_data, lines_configuration, output_file)
end

function cdfs_data_as_lines_data(data::CdfsGraphData, configuration::CdfsGraphConfiguration)::LinesGraphData
    fractions = Vector{Vector{Float64}}()
    lines_values = Vector{Vector{eltype(eltype(data.lines_values))}}()
    for line_values in data.lines_values
        line_values, trace_fractions = collect_cdf_data(line_values, configuration)
        push!(fractions, trace_fractions)
        push!(lines_values, line_values)
    end
    if configuration.values_orientation == HorizontalValues
        return LinesGraphData(;
            graph_title = data.graph_title,
            x_axis_title = data.value_axis_title,
            y_axis_title = data.fraction_axis_title,
            legend_title = data.legend_title,
            lines_xs = lines_values,
            lines_ys = fractions,
            lines_names = data.lines_names,
            lines_colors = data.lines_colors,
            lines_widths = data.lines_widths,
            lines_are_filled = data.lines_are_filled,
            lines_are_dashed = data.lines_are_dashed,
        )
    else
        return LinesGraphData(;
            graph_title = data.graph_title,
            x_axis_title = data.fraction_axis_title,
            y_axis_title = data.value_axis_title,
            legend_title = data.legend_title,
            lines_xs = fractions,
            lines_ys = lines_values,
            lines_names = data.lines_names,
            lines_colors = data.lines_colors,
            lines_widths = data.lines_widths,
            lines_are_filled = data.lines_are_filled,
            lines_are_dashed = data.lines_are_dashed,
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
    if configuration.cdf_direction == CdfDownToValue
        fractions = (1 + 1 / n_values) .- fractions
    end
    if configuration.show_percent
        fractions .*= 100
    end
    return (sorted_values, fractions)
end

function cdfs_configuration_as_lines_configuration(configuration::CdfsGraphConfiguration)::LinesGraphConfiguration
    if configuration.values_orientation == HorizontalValues
        return LinesGraphConfiguration(;
            graph = configuration.graph,
            x_axis = configuration.value_axis,
            y_axis = configuration.fraction_axis,
            line_style = configuration.line_style,
            vertical_bands = configuration.value_bands,
            horizontal_bands = configuration.fraction_bands,
            show_legend = configuration.show_legend,
        )
    else
        return LinesGraphConfiguration(;
            graph = configuration.graph,
            x_axis = configuration.fraction_axis,
            y_axis = configuration.value_axis,
            line_style = configuration.line_style,
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
        bars_values::AbstractVector{<:Real}
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
    bars_values::AbstractVector{<:Real}
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

function render(
    data::BarGraphData,
    configuration::BarGraphConfiguration = BarGraphConfiguration(),
    output_file::Maybe{AbstractString} = nothing,
)::Figure
    assert_valid_object(data)
    assert_valid_object(configuration)

    trace = bar_trace(
        configuration;
        values = data.bars_values,
        color = data.bars_colors !== nothing ? data.bars_colors : configuration.bars_color,
        hover = data.bars_hovers,
        names = data.bars_names,
    )

    layout = bar_layout(data, configuration; has_tick_names = data.bars_names !== nothing, show_legend = false)
    figure = plot(trace, layout)
    write_figure_to_file(figure, configuration.graph, output_file)

    return figure
end

"""
    @kwdef mutable struct BarsGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        value_axis::AxisConfiguration = AxisConfiguration()
        color::Maybe{AbstractString} = nothing
        values_orientation::ValuesOrientation = VerticalValues
        bars_gap::Maybe{Real} = nothing
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
    values_orientation::ValuesOrientation = VerticalValues
    bars_gap::Maybe{Real} = nothing
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
        series_values::AbstractString{<:AbstractVector{<:Real}}
        names::Maybe{AbstractVector{<:AbstractString}} = nothing
        colors::Maybe{AbstractVector{<:AbstractString}} = nothing
        hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
        bars_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    end

The data for a multiple bars (histograms) graph.

By default, all the titles are empty. You can specify the overall `graph_title` as well as the `value_axis_title`,
`bar_axis_title` for the axes, and the `legend_title` (if `show_legend` is set in [`BarsGraphConfiguration`](@ref).

All the `series_values` vectors must be of the same size. If specified, the `names` vector must contain the same number
of elements. If specified, the `bars_names` and/or `colors` and/or `hovers` vectors must contain the same number of
elements as the number of `series_values` vectors.
"""
@kwdef mutable struct BarsGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    value_axis_title::Maybe{AbstractString} = nothing
    bar_axis_title::Maybe{AbstractString} = nothing
    legend_title::Maybe{AbstractString} = nothing
    series_values::AbstractVector{<:AbstractVector{<:Real}}
    series_names::Maybe{AbstractVector{<:AbstractString}} = nothing
    series_colors::Maybe{AbstractVector{<:AbstractString}} = nothing
    series_hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
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
    hovers = data.series_hovers
    if hovers !== nothing && length(hovers) != n_series
        return "the data.series_hovers size: $(length(hovers))\n" *
               "is different from the data.series_values size: $(n_series)"
    end
    bars_names = data.bars_names
    if bars_names !== nothing && length(bars_names) != n_bars
        return "the data.bars_names size: $(length(bars_names))\n" *
               "is different from the data.series_values[:] size: $(n_bars)"
    end
    return nothing
end

function render(
    data::BarsGraphData,
    configuration::BarsGraphConfiguration = BarsGraphConfiguration(),
    output_file::Maybe{AbstractString} = nothing,
)::Figure
    assert_valid_object(data)
    assert_valid_object(configuration)

    stacking = configuration.stacking
    if stacking === nothing
        series_values = data.series_values
    else
        for (series_index, bars_values) in enumerate(data.series_values)
            for (bar_index, value) in enumerate(bars_values)
                @assert value >= 0 "negative stacked data.series_values[$(series_index),$(bar_index)]: $(value)"
            end
        end
        series_values = stacked_values(stacking, data.series_values)
    end

    traces = Vector{GenericTrace}()
    for index in 1:length(data.series_values)
        push!(
            traces,
            bar_trace(
                configuration;
                values = series_values[index],
                color = data.series_colors !== nothing ? data.series_colors[index] : nothing,
                hover = if data.series_hovers !== nothing
                    fill(data.series_hovers[index], length(series_values[index]))
                else
                    nothing
                end,
                names = data.bars_names,
                name = data.series_names !== nothing ? data.series_names[index] : "Series $(index)",
                legend_title = data.legend_title,
            ),
        )
    end

    layout = bar_layout(
        data,
        configuration;
        has_tick_names = data.bars_names !== nothing,
        show_legend = configuration.show_legend,
        stacked = configuration.stacking !== nothing,
    )
    figure = plot(traces, layout)
    write_figure_to_file(figure, configuration.graph, output_file)

    return figure
end

function stacked_values(stacking::Stacking, series_values::T)::T where {(T <: AbstractVector{<:AbstractVector{<:Real}})}
    if stacking == StackValues
        return series_values
    end

    total_values = zeros(eltype(eltype(series_values)), length(series_values[1]))
    for bars_values in series_values
        total_values .+= bars_values
    end

    if stacking == StackPercents
        total_values ./= 100
    end
    total_values[total_values .== 0] .= 1

    return [bars_values ./= total_values for bars_values in series_values]
end

function bar_trace(
    configuration::Union{BarGraphConfiguration, BarsGraphConfiguration};
    values::AbstractVector{<:Real},
    color::Maybe{Union{AbstractString, AbstractVector{<:AbstractString}}},
    hover::Maybe{Union{AbstractString, AbstractVector{<:AbstractString}}},
    names::Maybe{AbstractVector{<:AbstractString}},
    name::Maybe{AbstractString} = nothing,
    legend_title::Maybe{AbstractString} = nothing,
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
    if configuration.values_orientation == HorizontalValues
        xaxis_showgrid = configuration.graph.show_grid
        xaxis_showticklabels = configuration.graph.show_ticks
        xaxis_title = data.value_axis_title
        xaxis_range = (configuration.value_axis.minimum, configuration.value_axis.maximum)
        xaxis_type = configuration.value_axis.log_regularization !== nothing ? "log" : nothing

        yaxis_showgrid = false
        yaxis_showticklabels = has_tick_names
        yaxis_title = data.bar_axis_title
        yaxis_range = nothing
        yaxis_type = nothing
    elseif configuration.values_orientation == VerticalValues
        xaxis_showgrid = false
        xaxis_showticklabels = has_tick_names
        xaxis_title = data.bar_axis_title
        xaxis_range = nothing
        xaxis_type = nothing

        yaxis_showgrid = configuration.graph.show_grid
        yaxis_showticklabels = configuration.graph.show_ticks
        yaxis_title = data.value_axis_title
        yaxis_range = (configuration.value_axis.minimum, configuration.value_axis.maximum)
        yaxis_type = configuration.value_axis.log_regularization !== nothing ? "log" : nothing
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
        bargap = configuration.bars_gap,
    )
end

"""
    @kwdef mutable struct ScaleConfiguration <: ObjectWithValidation
        minimum::Maybe{Real} = nothing
        maximum::Maybe{Real} = nothing
        log_regularization::Maybe{AbstractFloat} = nothing
        reverse_scale::Bool = false
        show_scale::Bool = false
    end

Configure a color (or sizes) scale. If `show_scale` is set, the color scale is displayed next to the graph. The rest of
the fields are only relevant for continuous scales. By default, the `minimum` and `maximum` values are determined
automatically by the data. Setting `log_regularization` converts the scale to a log scale, using the (non-negative)
regularization to avoid log of zero values. If `reverse_scale` is set, the direction of the color scale is reversed.
"""
@kwdef mutable struct ScaleConfiguration <: ObjectWithValidation
    minimum::Maybe{Real} = nothing
    maximum::Maybe{Real} = nothing
    log_regularization::Maybe{AbstractFloat} = nothing
    reverse_scale::Bool = false
    show_scale::Bool = false
end

function Validations.validate_object(
    of_what::AbstractString,
    of_which::AbstractString,
    configuration::ScaleConfiguration,
)::Maybe{AbstractString}
    minimum = configuration.minimum
    maximum = configuration.maximum
    if minimum !== nothing && maximum !== nothing && maximum <= minimum
        return "configuration.$(of_what).$(of_which).maximum: $(maximum)\n" *
               "is not larger than configuration.$(of_what).$(of_which).minimum: $(minimum)"
    end

    log_regularization = configuration.log_regularization
    if log_regularization !== nothing
        if log_regularization < 0
            return "negative configuration.$(of_what).$(of_which).log_regularization: $(log_regularization)"
        end

        if minimum !== nothing && minimum + log_regularization <= 0
            return "log of non-positive configuration.$(of_what).$(of_which).minimum: $(minimum + log_regularization)"
        end

        if maximum !== nothing && maximum + log_regularization <= 0
            return "log of non-positive configuration.$(of_what).$(of_which).maximum: $(maximum + log_regularization)"
        end
    end

    return nothing
end

"""
    @kwdef mutable struct SizeRangeConfiguration <: ObjectWithValidation
        smallest::Maybe{Real} = nothing
        largest::Maybe{Real} = nothing
    end

Configure the range of sizes in pixels (1/96th of an inch) to map the sizes data into. If no bounds are given, and also
the scale is linear, then we assume the sizes data is just the size in pixels. Otherwise, by default we use 2 pixels for
the `smallest` size and make the `largest` size be 8 pixels larger than the `smallest` size.
"""
@kwdef mutable struct SizeRangeConfiguration <: ObjectWithValidation
    smallest::Maybe{Real} = nothing
    largest::Maybe{Real} = nothing
end

function Validations.validate_object(
    of_what::AbstractString,
    configuration::SizeRangeConfiguration,
)::Maybe{AbstractString}
    smallest = configuration.smallest
    largest = configuration.largest
    if smallest !== nothing && largest !== nothing && largest <= smallest
        return "configuration.$(of_what).size_range.largest: $(largest)\n" *
               "is not larger than configuration.$(of_what).size_range.smallest: $(smallest)"
    end
    return nothing
end

"""
    @kwdef mutable struct PointsStyleConfiguration <: ObjectWithValidation
        color::Maybe{AbstractString} = nothing
        color_scale::ScaleConfiguration = ScaleConfiguration()
        color_palette::Maybe{Union{
            AbstractString,
            AbstractVector{<:Tuple{<:Real, <:AbstractString}},
            AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        }} = nothing
        size::Maybe{Real} = nothing
        size_scale::ScaleConfiguration = ScaleConfiguration()
        size_range::SizeRangeConfiguration = SizeRangeConfiguration()
    end

Configure points in a graph. By default, the point `color` and `size` is chosen automatically (when this is applied to
edges, the `size` is the width of the line). You can override this by specifying colors and/or sizes in the
[`PointsGraphData`](@ref). For color values, the `color_palette` is applied; this can be the name of a standard one, a
vector of (value, color) tuples for a continuous (numeric value) scale or categorical (string value) scales. For sizes,
the `size_range` is applied. The `color_scale` and `size_scale` configurations further control the color scales.
"""
@kwdef mutable struct PointsStyleConfiguration <: ObjectWithValidation
    color::Maybe{AbstractString} = nothing
    color_scale::ScaleConfiguration = ScaleConfiguration()
    color_palette::Maybe{
        Union{
            AbstractString,
            AbstractVector{<:Tuple{<:Real, <:AbstractString}},
            AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
        },
    } = nothing
    size::Maybe{Real} = nothing
    size_scale::ScaleConfiguration = ScaleConfiguration()
    size_range::SizeRangeConfiguration = SizeRangeConfiguration()
end

function Validations.validate_object(
    of_what::AbstractString,
    configuration::PointsStyleConfiguration,
)::Maybe{AbstractString}
    message = validate_object(of_what, "color_scale", configuration.color_scale)
    if message === nothing
        message = validate_object(of_what, "size_scale", configuration.size_scale)
    end
    if message === nothing
        message = validate_object(of_what, configuration.size_range)
    end
    if message !== nothing
        return message
    end

    size = configuration.size
    if size !== nothing && size <= 0
        return "non-positive configuration.$(of_what).size: $(size)"
    end

    color_palette = configuration.color_palette
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
            log_color_scale_regularization = configuration.color_scale.log_regularization
            if log_color_scale_regularization !== nothing && cmin + log_color_scale_regularization <= 0
                index = argmin(color_palette)
                return "log of non-positive configuration.$(of_what).color_palette[$(index)]: $(cmin + log_color_scale_regularization)"
            end
        elseif configuration.color_scale.reverse_scale
            return "reversed categorical configuration.$(of_what).color_palette"
        end
    end

    if !is_valid_color(configuration.color)
        return "invalid configuration.$(of_what).color: $(configuration.color)"
    end

    return nothing
end

"""
    @kwdef mutable struct PointsGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        x_axis::AxisConfiguration = AxisConfiguration()
        y_axis::AxisConfiguration = AxisConfiguration()
        points_style::PointsStyleConfiguration = PointsStyleConfiguration()
        border_style::PointsStyleConfiguration = PointsStyleConfiguration()
        edges_style::PointsStyleConfiguration = PointsStyleConfiguration()
        vertical_bands::BandsConfiguration = BandsConfiguration()
        horizontal_bands::BandsConfiguration = BandsConfiguration()
        diagonal_bands::BandsConfiguration = BandsConfiguration()
    end

Configure a graph for showing a scatter graph of points.

Using the `vertical_bands`, `horizontal_bands` and/or `diagonal_bands` you can partition the graph into regions. The
`diagonal_bands` can only be used if both axes are linear or both axes are in log scale; they also unify the ranges of
the X and Y axes. If the axes are in log scale, the `offset` of the `diagonal_bands` are multiplicative instead of
additive, and must be positive.

The `border_style` is used if the [`PointsGraphData`](@ref) contains either the `borders_colors` and/or `borders_sizes`.
This allows displaying some additional data per point.

!!! note

    There is no `show_legend` for a [`GraphConfiguration`](@ref) of a points graph. Instead you probably want to set the
    `show_scale` of the `color_scale` (and/or of the `border_style` and/or `edges_style`). In addition, the color scale
    options of the `edges_style` must not be set, as the `edges_colors` of [`PointsGraphData`](@ref) is restricted to
    explicit colors.
"""
@kwdef mutable struct PointsGraphConfiguration <: AbstractGraphConfiguration
    graph::GraphConfiguration = GraphConfiguration()
    x_axis::AxisConfiguration = AxisConfiguration()
    y_axis::AxisConfiguration = AxisConfiguration()
    points_style::PointsStyleConfiguration = PointsStyleConfiguration()
    border_style::PointsStyleConfiguration = PointsStyleConfiguration()
    edges_style::PointsStyleConfiguration = PointsStyleConfiguration()
    vertical_bands::BandsConfiguration = BandsConfiguration()
    horizontal_bands::BandsConfiguration = BandsConfiguration()
    diagonal_bands::BandsConfiguration = BandsConfiguration()
end

function Validations.validate_object(configuration::PointsGraphConfiguration)::Maybe{AbstractString}
    @assert configuration.edges_style.color_palette === nothing "not implemented: points edges_style color_palette"
    @assert !configuration.edges_style.color_scale.reverse_scale "not implemented: points edges_style.color_scale.reverse_scale"
    @assert !configuration.edges_style.color_scale.show_scale "not implemented: points edges_style.color_scale.show_scale"
    @assert !configuration.edges_style.size_scale.show_scale "not implemented: points edges_style.size_scale.show_scale"

    message = validate_object(configuration.graph)
    if message === nothing
        message = validate_object("x", configuration.x_axis)
    end
    if message === nothing
        message = validate_object("y", configuration.y_axis)
    end
    if message === nothing
        message = validate_object("points_style", configuration.points_style)
    end
    if message === nothing
        message = validate_object("border_style", configuration.border_style)
    end
    if message === nothing
        message = validate_object("edges_style", configuration.edges_style)
    end
    if message === nothing
        message = validate_object(
            "vertical_bands",
            configuration.vertical_bands,
            configuration.x_axis.log_regularization !== nothing,
        )
    end
    if message === nothing
        message = validate_object(
            "horizontal_bands",
            configuration.horizontal_bands,
            configuration.y_axis.log_regularization !== nothing,
        )
    end
    if message === nothing &&
       (configuration.x_axis.log_regularization === nothing) != (configuration.y_axis.log_regularization === nothing) &&
       (
           configuration.diagonal_bands.low_band_style.offset !== nothing ||
           configuration.diagonal_bands.middle_band_style.offset !== nothing ||
           configuration.diagonal_bands.high_band_style.offset !== nothing
       )
        message = "configuration.diagonal_bands specified for a combination of linear and log scale axes"
    end
    if message === nothing
        message = validate_object(
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
        scale_title::Maybe{AbstractString} = nothing
        border_scale_title::Maybe{AbstractString} = nothing
        points_xs::AbstractVector{<:Real}
        points_ys::AbstractVector{<:Real}
        points_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing
        sizes::Maybe{AbstractVector{<:Real}} = nothing
        hovers::Maybe{AbstractVector{<:AbstractString}} = nothing
        borders_colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}} = nothing
        borders_sizes::Maybe{AbstractVector{<:Real}} = nothing
        edges::Maybe{AbstractVector{Tuple{<:Integer, <:Integer}}} = nothing
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

The `scale_title` and `border_scale_title` are only used if `show_scale` is set for the relevant color scales. You can't
specify `show_scale` if there is no `points_colors` data or if the `points_colors` contain explicit color names.

It is possible to draw straight `edges` between specific point pairs. In this case the `edges_style` of the
[`PointsGraphConfiguration`](@ref) will be used, and the `edges_colors` and `edges_sizes` will override it per edge.
The `edges_colors` are restricted to explicit colors, not a color scale.

A point (or a point border, or an edge) with a zero size and/or an empty string color (either from the data or from a
categorical `color_palette`) will not be shown.
"""
@kwdef mutable struct PointsGraphData <: AbstractGraphData
    graph_title::Maybe{AbstractString} = nothing
    x_axis_title::Maybe{AbstractString} = nothing
    y_axis_title::Maybe{AbstractString} = nothing
    scale_title::Maybe{AbstractString} = nothing
    border_scale_title::Maybe{AbstractString} = nothing
    points_xs::AbstractVector{<:Real}
    points_ys::AbstractVector{<:Real}
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

function render(
    data::PointsGraphData,
    configuration::PointsGraphConfiguration = PointsGraphConfiguration(),
    output_file::Maybe{AbstractString} = nothing,
)::Figure
    assert_valid_object(data)
    assert_valid_object(configuration)
    assert_valid_render(data, configuration)

    traces = Vector{GenericTrace}()

    minimum_x = minimum(data.points_xs)
    minimum_y = minimum(data.points_ys)
    maximum_x = maximum(data.points_xs)
    maximum_y = maximum(data.points_ys)

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
        log_scale = configuration.x_axis.log_regularization !== nothing ||
            configuration.y_axis.log_regularization !== nothing,
    )

    sizes = fix_sizes(data.points_sizes, configuration.points_style)

    if data.borders_colors !== nothing || data.borders_sizes !== nothing
        marker_size = border_marker_size(data, configuration, sizes)
        if marker_size isa AbstractVector{<:Real}
            marker_size_mask = marker_size .> 0  # NOJET
        else
            marker_size_mask = nothing
        end

        color_palette = configuration.border_style.color_palette
        if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            borders_colors = data.borders_colors
            @assert borders_colors isa AbstractVector{<:AbstractString}
            for (value, color) in color_palette
                if color != ""
                    mask = borders_colors .== value
                    if marker_size_mask !== nothing
                        mask .&= marker_size_mask
                    end
                    if any(mask)
                        push!(
                            traces,
                            points_trace(
                                data;
                                x_log_regularization = configuration.x_axis.log_regularization,
                                y_log_regularization = configuration.y_axis.log_regularization,
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
            end
        else
            borders_colors = data.borders_colors
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
                points_trace(
                    data;
                    x_log_regularization = configuration.x_axis.log_regularization,
                    y_log_regularization = configuration.y_axis.log_regularization,
                    color = if borders_colors !== nothing
                        fix_colors(borders_colors, configuration.border_style.color_scale.log_regularization)
                    else
                        configuration.border_style.color
                    end,
                    marker_size = marker_size,
                    coloraxis = "coloraxis2",
                    points_style = configuration.border_style,
                    scale_title = data.border_scale_title,
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

    color_palette = configuration.points_style.color_palette
    if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        for (value, color) in color_palette
            if color != ""
                colors = data.points_colors
                @assert colors isa AbstractVector{<:AbstractString}
                mask = colors .== value
                if marker_size_mask !== nothing
                    mask .&= marker_size_mask
                end
                if any(mask)
                    push!(
                        traces,
                        points_trace(
                            data;
                            x_log_regularization = configuration.x_axis.log_regularization,
                            y_log_regularization = configuration.y_axis.log_regularization,
                            color = color,
                            marker_size = sizes,
                            coloraxis = nothing,
                            points_style = configuration.points_style,
                            scale_title = data.scale_title,
                            legend_group = "points",
                            mask = mask,
                            name = value,
                        ),
                    )
                end
            end
        end
    else
        colors = data.points_colors
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
                points_trace(
                    data;
                    x_log_regularization = configuration.x_axis.log_regularization,
                    y_log_regularization = configuration.y_axis.log_regularization,
                    color = if colors !== nothing
                        fix_colors(colors, configuration.points_style.color_scale.log_regularization)
                    else
                        configuration.points_style.color
                    end,
                    marker_size = sizes,
                    coloraxis = "coloraxis",
                    points_style = configuration.points_style,
                    scale_title = data.scale_title,
                    legend_group = "points",
                    mask = mask,
                ),
            )
        end
    end

    edges_points = data.edges_points
    if edges_points !== nothing
        for index in 1:length(edges_points)
            push!(traces, edge_trace(data, configuration.edges_style; index = index))
        end
    end

    for band in (
        configuration.vertical_bands.low_band_style,
        configuration.vertical_bands.middle_band_style,
        configuration.vertical_bands.high_band_style,
    )
        if band.offset !== nothing && band.width !== nothing
            push!(traces, vertical_line_trace(band, minimum_y, maximum_y))
        end
    end

    for band in (
        configuration.horizontal_bands.low_band_style,
        configuration.horizontal_bands.middle_band_style,
        configuration.horizontal_bands.high_band_style,
    )
        if band.offset !== nothing && band.width !== nothing
            push!(traces, horizontal_line_trace(band, minimum_x, maximum_x))
        end
    end

    for band in (
        configuration.diagonal_bands.low_band_style,
        configuration.diagonal_bands.middle_band_style,
        configuration.diagonal_bands.high_band_style,
    )
        if band.offset !== nothing && band.width !== nothing
            push!(
                traces,
                diagonal_line_trace(
                    band,
                    minimum_x,
                    minimum_y,
                    maximum_x,
                    maximum_y;
                    log_scale = configuration.x_axis.log_regularization !== nothing ||
                        configuration.y_axis.log_regularization !== nothing,
                ),
            )
        end
    end

    layout = points_layout(;
        data = data,
        configuration = configuration,
        x_axis = configuration.x_axis,
        y_axis = configuration.y_axis,
    )
    figure = plot(traces, layout)
    write_figure_to_file(figure, configuration.graph, output_file)

    return figure
end

function push_fill_vertical_bands_traces(
    traces::Vector{GenericTrace},
    configuration::BandsConfiguration,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real,
)::Nothing
    if configuration.low_band_style.offset !== nothing && configuration.low_band_style.is_filled
        push!(  # NOJET
            traces,
            fill_trace(
                [minimum_x, configuration.low_band_style.offset, configuration.low_band_style.offset, minimum_x],
                [minimum_y, minimum_y, maximum_y, maximum_y];
                line_color = configuration.low_band_style.color,
            ),
        )
    end

    if configuration.high_band_style.offset !== nothing && configuration.high_band_style.is_filled
        push!(  # NOJET
            traces,
            fill_trace(
                [maximum_x, configuration.high_band_style.offset, configuration.high_band_style.offset, maximum_x],
                [minimum_y, minimum_y, maximum_y, maximum_y];
                line_color = configuration.high_band_style.color,
            ),
        )
    end

    if configuration.high_band_style.offset !== nothing &&
       configuration.low_band_style.offset !== nothing &&
       configuration.middle_band_style.is_filled
        push!(  # NOJET
            traces,
            fill_trace(
                [
                    configuration.low_band_style.offset,
                    configuration.high_band_style.offset,
                    configuration.high_band_style.offset,
                    configuration.low_band_style.offset,
                ],
                [minimum_y, minimum_y, maximum_y, maximum_y];
                line_color = configuration.middle_band_style.color,
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
    if configuration.low_band_style.offset !== nothing && configuration.low_band_style.is_filled
        push!(  # NOJET
            traces,
            fill_trace(
                [minimum_x, minimum_x, maximum_x, maximum_x],
                [minimum_y, configuration.low_band_style.offset, configuration.low_band_style.offset, minimum_y];
                line_color = configuration.low_band_style.color,
            ),
        )
    end

    if configuration.high_band_style.offset !== nothing && configuration.high_band_style.is_filled
        push!(  # NOJET
            traces,
            fill_trace(
                [minimum_x, minimum_x, maximum_x, maximum_x],
                [maximum_y, configuration.high_band_style.offset, configuration.high_band_style.offset, maximum_y];
                line_color = configuration.high_band_style.color,
            ),
        )
    end

    if configuration.high_band_style.offset !== nothing &&
       configuration.low_band_style.offset !== nothing &&
       configuration.middle_band_style.is_filled
        push!(  # NOJET
            traces,
            fill_trace(
                [minimum_x, minimum_x, maximum_x, maximum_x],
                [
                    configuration.low_band_style.offset,
                    configuration.high_band_style.offset,
                    configuration.high_band_style.offset,
                    configuration.low_band_style.offset,
                ];
                line_color = configuration.middle_band_style.color,
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
    if configuration.low_band_style.offset !== nothing && configuration.low_band_style.is_filled
        push!(  # NOJET
            traces,
            fill_low_diagonal_trace(
                configuration.low_band_style.offset,
                minimum_x,
                minimum_y,
                maximum_x,
                maximum_y;
                line_color = configuration.low_band_style.color,
                log_scale = log_scale,
            ),
        )
    end

    if configuration.high_band_style.offset !== nothing && configuration.high_band_style.is_filled
        push!(  # NOJET
            traces,
            fill_high_diagonal_trace(
                configuration.high_band_style.offset,
                minimum_x,
                minimum_y,
                maximum_x,
                maximum_y;
                line_color = configuration.high_band_style.color,
                log_scale = log_scale,
            ),
        )
    end

    if configuration.high_band_style.offset !== nothing &&
       configuration.low_band_style.offset !== nothing &&
       configuration.middle_band_style.is_filled
        push!(  # NOJET
            traces,
            fill_middle_diagonal_trace(
                configuration.low_band_style.offset,
                configuration.high_band_style.offset,
                minimum_x,
                minimum_y,
                maximum_x,
                maximum_y;
                line_color = configuration.middle_band_style.color,
                log_scale = log_scale,
            ),
        )
    end

    return nothing
end

function fill_low_diagonal_trace(
    offset::Real,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real;
    line_color::Maybe{AbstractString},
    log_scale::Bool,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(log_scale)
    if offset < threshold
        return fill_trace(
            [decrease(minimum_xy, offset), maximum_xy, maximum_xy],
            [minimum_xy, increase(maximum_xy, offset), minimum_xy];
            line_color = line_color,
        )
    else
        return fill_trace(
            [minimum_xy, maximum_xy, maximum_xy, decrease(maximum_xy, offset), minimum_xy],
            [minimum_xy, minimum_xy, maximum_xy, maximum_xy, increase(minimum_xy, offset)];
            line_color = line_color,
        )
    end
end

function fill_high_diagonal_trace(
    offset::Real,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real;
    line_color::Maybe{AbstractString},
    log_scale::Bool,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(log_scale)
    if offset < threshold
        return fill_trace(
            [minimum_xy, minimum_xy, maximum_xy, maximum_xy, decrease(minimum_xy, offset)],
            [minimum_xy, maximum_xy, maximum_xy, increase(maximum_xy, offset), minimum_xy];
            line_color = line_color,
        )
    else
        return fill_trace(
            [minimum_xy, decrease(maximum_xy, offset), minimum_xy],
            [increase(minimum_xy, offset), maximum_xy, maximum_xy];
            line_color = line_color,
        )
    end
end

function fill_middle_diagonal_trace(
    low_offset::Real,
    high_offset::Real,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real;
    line_color::Maybe{AbstractString},
    log_scale::Bool,
)::GenericTrace
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)
    threshold, increase, decrease = band_operations(log_scale)
    if high_offset < threshold
        return fill_trace(
            [decrease(minimum_xy, high_offset), decrease(minimum_xy, low_offset), maximum_xy, maximum_xy],
            [minimum_xy, minimum_xy, increase(maximum_xy, low_offset), increase(maximum_xy, high_offset)];
            line_color = line_color,
        )
    elseif low_offset > threshold
        return fill_trace(
            [minimum_xy, minimum_xy, decrease(maximum_xy, high_offset), decrease(maximum_xy, low_offset)],
            [increase(minimum_xy, low_offset), increase(minimum_xy, high_offset), maximum_xy, maximum_xy];
            line_color = line_color,
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
            line_color = line_color,
        )
    end
end

function fill_trace(
    points_xs::AbstractVector{<:Real},
    points_ys::AbstractVector{<:Real};
    line_color::Maybe{AbstractString},
)::GenericTrace
    return scatter(;
        x = points_xs,
        y = points_ys,
        fill = "toself",
        fillcolor = fill_color(line_color),
        name = "",
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

function points_trace(
    data::PointsGraphData;
    x_log_regularization::Maybe{AbstractFloat},
    y_log_regularization::Maybe{AbstractFloat},
    color::Maybe{Union{AbstractString, AbstractVector{<:AbstractString}, AbstractVector{<:Real}}},
    marker_size::Maybe{Union{Real, AbstractVector{<:Real}}},
    coloraxis::Maybe{AbstractString},
    points_style::PointsStyleConfiguration,
    scale_title::Maybe{AbstractString},
    legend_group::AbstractString,
    mask::Maybe{Union{AbstractVector{Bool}, BitVector}} = nothing,
    name::Maybe{AbstractString} = nothing,
)::GenericTrace
    return scatter(;
        x = masked_data(data.points_xs, mask) .+ (x_log_regularization === nothing ? 0 : x_log_regularization),
        y = masked_data(data.points_ys, mask) .+ (y_log_regularization === nothing ? 0 : y_log_regularization),
        marker_size = masked_data(marker_size, mask),
        marker_color = color !== nothing ? masked_data(color, mask) : points_style.color,
        marker_colorscale = if points_style.color_palette isa AbstractVector ||
                               points_style.color_scale.log_regularization !== nothing
            nothing
        else
            points_style.color_palette
        end,
        marker_coloraxis = coloraxis,
        marker_showscale = points_style.color_scale.show_scale && !(
            points_style.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        ),
        marker_reversescale = points_style.color_scale.reverse_scale,
        showlegend = points_style.color_scale.show_scale &&
                     points_style.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
        legendgroup = legend_group,
        legendgrouptitle_text = scale_title,
        name = name !== nothing ? name : points_style.color_scale.show_scale ? "Trace" : "",
        text = data.points_hovers,
        hovertemplate = data.points_hovers === nothing ? nothing : "%{text}<extra></extra>",
        mode = "markers",
    )
end

function edge_trace(data::PointsGraphData, edges_style::PointsStyleConfiguration; index::Int)::GenericTrace
    from_point, to_point = data.edges_points[index]
    return scatter(;
        x = [data.points_xs[from_point], data.points_xs[to_point]],
        y = [data.points_ys[from_point], data.points_ys[to_point]],
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

function vertical_line_trace(configuration::BandStyleConfiguration, minimum_y::Real, maximum_y::Real)::GenericTrace
    @assert configuration.offset !== nothing
    return scatter(;
        x = [configuration.offset, configuration.offset],
        y = [minimum_y, maximum_y],
        line_width = configuration.width,
        line_color = configuration.color !== nothing ? configuration.color : "black",
        line_dash = configuration.is_dashed ? "dash" : nothing,
        showlegend = false,
        mode = "lines",
    )
end

function horizontal_line_trace(configuration::BandStyleConfiguration, minimum_x::Real, maximum_x::Real)::GenericTrace
    @assert configuration.offset !== nothing
    return scatter(;
        x = [minimum_x, maximum_x],
        y = [configuration.offset, configuration.offset],
        line_width = configuration.width,
        line_color = configuration.color !== nothing ? configuration.color : "black",
        line_dash = configuration.is_dashed ? "dash" : nothing,
        showlegend = false,
        mode = "lines",
    )
end

function diagonal_line_trace(
    configuration::BandStyleConfiguration,
    minimum_x::Real,
    minimum_y::Real,
    maximum_x::Real,
    maximum_y::Real;
    log_scale::Bool,
)::GenericTrace
    offset = configuration.offset
    @assert offset !== nothing
    minimum_xy = min(minimum_x, minimum_y)
    maximum_xy = max(maximum_x, maximum_y)

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
        line_width = configuration.width,
        line_color = configuration.color !== nothing ? configuration.color : "black",
        line_dash = configuration.is_dashed ? "dash" : nothing,
        showlegend = false,
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
    points_style::PointsStyleConfiguration,
)::Tuple{Maybe{Vector{Float32}}, Maybe{Vector{String}}}
    log_color_scale_regularization = points_style.color_scale.log_regularization
    if log_color_scale_regularization === nothing || !points_style.color_scale.show_scale
        return nothing, nothing
    else
        @assert colors isa AbstractVector{<:Real}
        cmin =
            lowest_color(points_style.color_palette, points_style.color_scale.minimum, log_color_scale_regularization)  # NOJET
        if cmin === nothing
            cmin = log10(minimum(colors) + log_color_scale_regularization)
        end
        cmax =
            highest_color(points_style.color_palette, points_style.color_scale.maximum, log_color_scale_regularization)  # NOJET
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

function normalized_color_palette(color_palette::Maybe{AbstractString}, ::ScaleConfiguration)::Maybe{AbstractString}
    return color_palette
end

function normalized_color_palette(
    color_palette::AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
    ::ScaleConfiguration,
)::AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
    return color_palette
end

function normalized_color_palette(
    color_palette::AbstractVector{<:Tuple{<:Real, <:AbstractString}},
    color_scale::ScaleConfiguration,
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

function write_figure_to_file(::Figure, ::GraphConfiguration, ::Nothing)::Nothing  # untested
    return nothing
end

function write_figure_to_file(figure::Figure, configuration::GraphConfiguration, output_file::AbstractString)::Nothing
    savefig(figure, output_file; height = configuration.height, width = configuration.width)  # NOJET
    return nothing
end

"""
    @kwdef mutable struct GridGraphConfiguration <: AbstractGraphConfiguration
        graph::GraphConfiguration = GraphConfiguration()
        points_style::PointsStyleConfiguration = PointsStyleConfiguration()
        border_style::PointsStyleConfiguration = PointsStyleConfiguration()
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
    points_style::PointsStyleConfiguration = PointsStyleConfiguration()
    border_style::PointsStyleConfiguration = PointsStyleConfiguration()
end

function Validations.validate_object(configuration::GridGraphConfiguration)::Maybe{AbstractString}
    message = validate_object(configuration.graph)
    if message === nothing
        message = validate_object("points_style", configuration.points_style)
    end
    if message === nothing
        message = validate_object("border_style", configuration.border_style)
    end
    return message
end

"""
    @kwdef mutable struct GridGraphData <: AbstractGraphData
        graph_title::Maybe{AbstractString} = nothing
        x_axis_title::Maybe{AbstractString} = nothing
        y_axis_title::Maybe{AbstractString} = nothing
        scale_title::Maybe{AbstractString} = nothing
        border_scale_title::Maybe{AbstractString} = nothing
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
    scale_title::Maybe{AbstractString} = nothing
    border_scale_title::Maybe{AbstractString} = nothing
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

function render(
    data::GridGraphData,
    configuration::GridGraphConfiguration = GridGraphConfiguration(),
    output_file::Maybe{AbstractString} = nothing,
)::Figure
    assert_valid_object(data)
    assert_valid_object(configuration)
    assert_valid_render(data, configuration)

    if data.points_sizes !== nothing
        n_rows, n_columns = size(data.points_sizes)
    else
        @assert data.points_colors !== nothing
        n_rows, n_columns = size(data.points_colors)
    end

    traces = Vector{GenericTrace}()

    sizes = fix_sizes(data.points_sizes, configuration.points_style)

    borders_colors = data.borders_colors
    if borders_colors !== nothing || data.borders_sizes !== nothing
        marker_size = border_marker_size(data, configuration, sizes)
        if marker_size isa AbstractVector{<:Real}
            marker_size_mask = marker_size .> 0
        else
            marker_size_mask = nothing
        end

        color_palette = configuration.border_style.color_palette
        if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            @assert borders_colors isa AbstractMatrix{<:AbstractString}
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
                                data = data,
                                n_rows = n_rows,
                                n_columns = n_columns,
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
            end
        else
            borders_colors = data.borders_colors
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
                        data = data,
                        n_rows = n_rows,
                        n_columns = n_columns,
                        color = if borders_colors !== nothing
                            fix_colors(borders_colors, configuration.border_style.color_scale.log_regularization)
                        else
                            configuration.border_style.color
                        end,
                        marker_size = marker_size,
                        coloraxis = "coloraxis2",
                        points_style = configuration.border_style,
                        scale_title = data.border_scale_title,
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

    color_palette = configuration.points_style.color_palette
    if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        colors = data.points_colors
        @assert colors isa AbstractMatrix{<:AbstractString}
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
                            data = data,
                            n_rows = n_rows,
                            n_columns = n_columns,
                            color = color,
                            marker_size = sizes,
                            coloraxis = nothing,
                            points_style = configuration.points_style,
                            scale_title = data.scale_title,
                            legend_group = "points",
                            mask = mask,
                            name = value,
                        ),
                    )
                end
            end
        end
    else
        colors = data.points_colors
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
                    data = data,
                    n_rows = n_rows,
                    n_columns = n_columns,
                    color = if colors !== nothing
                        fix_colors(colors, configuration.points_style.color_scale.log_regularization)
                    else
                        configuration.points_style.color
                    end,
                    marker_size = sizes,
                    coloraxis = "coloraxis",
                    points_style = configuration.points_style,
                    scale_title = data.scale_title,
                    mask = mask,
                    legend_group = "points",
                ),
            )
        end
    end

    columns_names = data.columns_names
    if columns_names === nothing
        columns_names = [string(index) for index in 1:n_columns]
    end
    rows_names = data.rows_names
    if rows_names === nothing
        rows_names = [string(index) for index in 1:n_rows]
    end

    layout = points_layout(;
        data = data,
        configuration = configuration,
        x_axis = AxisConfiguration(; minimum = 0.5, maximum = n_columns + 0.5),
        y_axis = AxisConfiguration(; minimum = 0.5, maximum = n_rows + 0.5),
        rows_names = rows_names,
        columns_names = columns_names,
    )
    figure = plot(traces, layout)
    write_figure_to_file(figure, configuration.graph, output_file)

    return figure
end

function assert_valid_render(data::PointsGraphData, configuration::PointsGraphConfiguration)::Nothing
    x_log_regularization = configuration.x_axis.log_regularization
    if x_log_regularization !== nothing
        for (index, x) in enumerate(data.points_xs)
            @assert x + x_log_regularization > 0 "log of non-positive data.points_xs[$(index)]: $(x + x_log_regularization)"
        end
    end

    y_log_regularization = configuration.y_axis.log_regularization
    if y_log_regularization !== nothing
        for (index, y) in enumerate(data.points_ys)
            @assert y + y_log_regularization > 0 "log of non-positive data.points_ys[$(index)]: $(y + y_log_regularization)"
        end
    end

    assert_valid_vector_colors(
        "data.points_colors",
        data.points_colors,
        "configuration.points_style",
        configuration.points_style,
    )
    assert_valid_vector_colors(
        "data.borders_colors",
        data.borders_colors,
        "configuration.border_style",
        configuration.border_style,
    )

    return nothing
end

function assert_valid_render(data::GridGraphData, configuration::GridGraphConfiguration)::Nothing
    assert_valid_matrix_colors(
        "data.points_colors",
        data.points_colors,
        "configuration.points_style",
        configuration.points_style,
    )
    assert_valid_matrix_colors(
        "data.borders_colors",
        data.borders_colors,
        "configuration.border_style",
        configuration.border_style,
    )

    return nothing
end

function assert_valid_vector_colors(
    what_colors::AbstractString,
    colors::Maybe{Union{AbstractVector{<:AbstractString}, AbstractVector{<:Real}}},
    what_configuration::AbstractString,
    configuration::PointsStyleConfiguration,
)::Nothing
    color_palette = configuration.color_palette
    if colors isa AbstractVector{<:AbstractString}
        if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            scale_colors = Set{AbstractString}([value for (value, _) in color_palette])
            for (index, color) in enumerate(colors)
                if color != ""
                    @assert color in scale_colors "categorical $(what_configuration).color_palette does not contain $(what_colors)[$(index)]: $(color)"
                end
            end
        else
            for (index, color) in enumerate(colors)
                if color != ""
                    @assert is_valid_color(color) "invalid $(what_colors)[$(index)]: $(color)"
                end
            end
        end
    else
        @assert !(color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}) "non-string $(what_colors) for categorical $(what_configuration).color_pallete"
    end

    if configuration.color_scale.show_scale
        @assert colors !== nothing "no $(what_colors) specified for $(what_configuration).color_scale.show_scale"
        @assert !(colors isa AbstractVector{<:AbstractString}) ||
                configuration.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}} (
            "explicit $(what_colors) specified for $(what_configuration).color_scale.show_scale"
        )
    end

    if configuration.color_scale.log_regularization !== nothing
        @assert colors isa AbstractVector{<:Real} "non-real $(what_colors) with $(what_configuration).color_scale.log_regularization"
        index = argmin(colors)  # NOJET
        minimal_color = colors[index] + configuration.color_scale.log_regularization
        @assert minimal_color > 0 "log of non-positive $(what_colors)[$(index)]: $(minimal_color)"
    end

    return nothing
end

function assert_valid_matrix_colors(
    what_colors::AbstractString,
    colors::Maybe{Union{AbstractMatrix{<:AbstractString}, AbstractMatrix{<:Real}}},
    what_configuration::AbstractString,
    configuration::PointsStyleConfiguration,
)::Nothing
    color_palette = configuration.color_palette
    if colors isa AbstractMatrix{<:AbstractString}
        n_rows, n_columns = size(colors)
        if color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            scale_colors = Set{AbstractString}([value for (value, _) in color_palette])
            for row_index in 1:n_rows
                for column_index in 1:n_columns
                    color = colors[row_index, column_index]
                    if color != ""
                        @assert color in scale_colors "categorical $(what_configuration).color_palette does not contain $(what_colors)[$(row_index),$(column_index))]: $(color)"
                    end
                end
            end
        else
            for row_index in 1:n_rows
                for column_index in 1:n_columns
                    color = colors[row_index, column_index]
                    if color != ""
                        @assert is_valid_color(color) "invalid $(what_colors)[$(row_index),$(column_index)]: $(color)"
                    end
                end
            end
        end
    else
        @assert !(color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}) "non-string $(what_colors) for categorical $(what_configuration).color_pallete"
    end

    if configuration.color_scale.show_scale
        @assert colors !== nothing "no $(what_colors) specified for $(what_configuration).color_scale.show_scale"
        @assert !(colors isa AbstractMatrix{<:AbstractString}) ||
                configuration.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}} (
            "explicit $(what_colors) specified for $(what_configuration).color_scale.show_scale"
        )
    end

    if configuration.color_scale.log_regularization !== nothing
        @assert colors isa AbstractMatrix{<:Real} "non-real $(what_colors) with $(what_configuration).color_scale.log_regularization"
        row_index, column_index = argmin(colors).I
        minimal_color = colors[row_index, column_index] + configuration.color_scale.log_regularization
        @assert minimal_color > 0 "log of non-positive $(what_colors)[$(row_index),$(column_index)]: $(minimal_color)"
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
    points_style::PointsStyleConfiguration,
    scale_title::Maybe{AbstractString},
    legend_group::AbstractString,
    mask::Maybe{Union{Vector{Bool}, BitVector}} = nothing,
    name::Maybe{AbstractString} = nothing,
)::GenericTrace
    return scatter(;
        x = masked_xs(n_rows, n_columns, mask),
        y = masked_ys(n_rows, n_columns, mask),
        marker_size = masked_data(marker_size, mask),
        marker_color = color !== nothing ? masked_data(color, mask) : points_style.color,
        marker_colorscale = if points_style.color_palette isa AbstractVector ||
                               points_style.color_scale.log_regularization !== nothing
            nothing
        else
            points_style.color_palette
        end,
        marker_coloraxis = coloraxis,
        marker_showscale = points_style.color_scale.show_scale && !(
            points_style.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        ),
        marker_reversescale = points_style.color_scale.reverse_scale,
        showlegend = points_style.color_scale.show_scale &&
                     points_style.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}},
        legendgroup = legend_group,
        legendgrouptitle_text = scale_title,
        name = name !== nothing ? name : points_style.color_scale.show_scale ? "Trace" : "",
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
    configuration::Union{PointsGraphConfiguration, GridGraphConfiguration},
    x_axis::AxisConfiguration,
    y_axis::AxisConfiguration,
    rows_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
    columns_names::Maybe{AbstractVector{<:AbstractString}} = nothing,
)::Layout
    color_tickvals, color_ticktext = log_color_scale_ticks(data.points_colors, configuration.points_style)
    border_color_tickvals, border_color_ticktext =
        log_color_scale_ticks(data.borders_colors, configuration.border_style)
    x_tickvals, x_ticknames = xy_ticks(columns_names)
    y_tickvals, y_ticknames = xy_ticks(rows_names)
    return Layout(;  # NOJET
        title = data.graph_title,
        template = configuration.graph.template,
        xaxis_showgrid = configuration.graph.show_grid,
        xaxis_showticklabels = configuration.graph.show_ticks,
        xaxis_title = data.x_axis_title,
        xaxis_range = (x_axis.minimum, x_axis.maximum),
        xaxis_type = x_axis.log_regularization !== nothing ? "log" : nothing,
        xaxis_tickvals = x_tickvals,
        xaxis_ticktext = x_ticknames,
        yaxis_showgrid = configuration.graph.show_grid,
        yaxis_showticklabels = configuration.graph.show_ticks,
        yaxis_title = data.y_axis_title,
        yaxis_range = (y_axis.minimum, y_axis.maximum),
        yaxis_type = y_axis.log_regularization !== nothing ? "log" : nothing,
        yaxis_tickvals = y_tickvals,
        yaxis_ticktext = y_ticknames,
        showlegend = (
            configuration.points_style.color_scale.show_scale &&
            configuration.points_style.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        ) || (
            configuration.border_style.color_scale.show_scale &&
            configuration.border_style.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        ),
        legend_x = if configuration.points_style.color_scale.show_scale &&
                      configuration.border_style.color_scale.show_scale &&
                      configuration.border_style.color_palette isa
                      AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
            1.2
        else
            nothing
        end,
        coloraxis2_colorbar_x = if (
            configuration.border_style.color_scale.show_scale && configuration.points_style.color_scale.show_scale
        )
            1.2
        else
            nothing  # NOJET
        end,
        coloraxis_showscale = configuration.points_style.color_scale.show_scale && !(
            configuration.points_style.color_palette isa AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
        ),
        coloraxis_reversescale = configuration.points_style.color_scale.reverse_scale,
        coloraxis_colorscale = normalized_color_palette(
            configuration.points_style.color_palette,
            configuration.points_style.color_scale,
        ),
        coloraxis_cmin = lowest_color(
            configuration.points_style.color_palette,
            configuration.points_style.color_scale.minimum,
            configuration.points_style.color_scale.log_regularization,
        ),
        coloraxis_cmax = highest_color(
            configuration.points_style.color_palette,
            configuration.points_style.color_scale.maximum,
            configuration.points_style.color_scale.log_regularization,
        ),
        coloraxis_colorbar_title_text = data.scale_title,
        coloraxis_colorbar_tickvals = color_tickvals,
        coloraxis_colorbar_ticktext = color_ticktext,
        coloraxis2_showscale = (data.borders_colors !== nothing || data.borders_sizes !== nothing) &&
                               configuration.border_style.color_scale.show_scale &&
                               !(
                                   configuration.border_style.color_palette isa
                                   AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}
                               ),
        coloraxis2_reversescale = configuration.border_style.color_scale.reverse_scale,
        coloraxis2_colorscale = normalized_color_palette(
            configuration.border_style.color_palette,
            configuration.border_style.color_scale,
        ),
        coloraxis2_cmin = lowest_color(
            configuration.border_style.color_palette,
            configuration.border_style.color_scale.minimum,
            configuration.border_style.color_scale.log_regularization,
        ),
        coloraxis2_cmax = highest_color(
            configuration.border_style.color_palette,
            configuration.border_style.color_scale.maximum,
            configuration.border_style.color_scale.log_regularization,
        ),
        coloraxis2_colorbar_title_text = data.border_scale_title,
        coloraxis2_colorbar_tickvals = border_color_tickvals,
        coloraxis2_colorbar_ticktext = border_color_ticktext,
    )
end

function border_marker_size(
    data::Union{PointsGraphData, GridGraphData},
    configuration::Union{PointsGraphConfiguration, GridGraphConfiguration},
    sizes::Maybe{Union{Real, AbstractVector{<:Real}}},
)::Union{Real, Vector{<:Real}}
    sizes = sizes
    borders_sizes = fix_sizes(data.borders_sizes, configuration.border_style)

    if borders_sizes === nothing
        border_marker_size = configuration.border_style.size !== nothing ? configuration.border_style.size : 4.0
        @assert border_marker_size !== nothing
        if sizes === nothing
            points_marker_size = configuration.points_style.size !== nothing ? configuration.points_style.size : 4.0
            return points_marker_size + 2 * border_marker_size
        else
            return sizes .+ 2 * border_marker_size
        end
    else
        if sizes === nothing
            points_marker_size = configuration.points_style.size !== nothing ? configuration.points_style.size : 4.0
            return 2 .* borders_sizes .+ points_marker_size
        else
            return 2 .* borders_sizes .+ sizes
        end
    end
end

function fix_sizes(
    sizes::Maybe{Union{AbstractVector{<:Real}, AbstractMatrix{<:Real}}},
    configuration::PointsStyleConfiguration,
)::Maybe{Union{Real, Vector{<:Real}}}
    if sizes === nothing
        return configuration.size
    end

    sizes = vec(sizes)

    smallest = configuration.size_range.smallest
    largest = configuration.size_range.largest
    log_regularization = configuration.size_scale.log_regularization
    if smallest === nothing && largest === nothing && log_regularization === nothing
        return sizes
    end

    smin = configuration.size_scale.minimum !== nothing ? configuration.size_scale.minimum : minimum(sizes)
    smax = configuration.size_scale.maximum !== nothing ? configuration.size_scale.maximum : maximum(sizes)

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

end  # module
