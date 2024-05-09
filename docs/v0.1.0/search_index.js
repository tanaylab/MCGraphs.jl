var documenterSearchIndex = {"docs":
[{"location":"renderers.html#Renderers","page":"Renderers","title":"Renderers","text":"","category":"section"},{"location":"renderers.html","page":"Renderers","title":"Renderers","text":"MCGraphs.Renderers\nMCGraphs.Renderers.render\nMCGraphs.Renderers.AbstractGraphData\nMCGraphs.Renderers.AbstractGraphConfiguration\nMCGraphs.Renderers.GraphConfiguration\nMCGraphs.Renderers.AxisConfiguration\nMCGraphs.Renderers.ValuesOrientation","category":"page"},{"location":"renderers.html#MCGraphs.Renderers","page":"Renderers","title":"MCGraphs.Renderers","text":"the Render interactive or static graphs.\n\nThis provides a selection of basic graph types needed for metacells visualization. For each one, we define a struct containing all the data for the graph, and a separate struct containing the configuration of the graph. The rendering function takes both and either returns a JavaScript blob needed to create the interactive graph, or writes the graph to a file.\n\n\n\n\n\n","category":"module"},{"location":"renderers.html#MCGraphs.Renderers.render","page":"Renderers","title":"MCGraphs.Renderers.render","text":"render(\n    data::AbstractGraphData,\n    configuration::AbstractGraphConfiguration = ...,\n)::Nothing\n\nRender a graph given its data and configuration. The implementation depends on the specific graph. For each AbstractGraphData there is a matching AbstractGraphConfiguration (a default one is provided for the configuration). The supported type pairs are:\n\nAbstractGraphData AbstractGraphConfiguration Description\nDistributionGraphData DistributionGraphConfiguration Graph of a single distribution.\nDistributionsGraphData DistributionsGraphConfiguration Graph of multiple distributions.\nLineGraphData LineGraphConfiguration Graph of a single line (e.g. a function y=f(x)).\nPointsGraphData PointsGraphConfiguration Graph of points, possibly with edges between them.\n\n\n\n\n\n","category":"function"},{"location":"renderers.html#MCGraphs.Renderers.AbstractGraphData","page":"Renderers","title":"MCGraphs.Renderers.AbstractGraphData","text":"Common abstract base for all complete graph data types. See render.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.AbstractGraphConfiguration","page":"Renderers","title":"MCGraphs.Renderers.AbstractGraphConfiguration","text":"Common abstract base for all complete graph configuration types. See render.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.GraphConfiguration","page":"Renderers","title":"MCGraphs.Renderers.GraphConfiguration","text":"@kwdef mutable struct GraphConfiguration <: ObjectWithValidation\n    output_file::Maybe{AbstractString} = nothing\n    show_interactive::Bool = false\n    width::Maybe{Int} = nothing\n    height::Maybe{Int} = nothing\n    template::AbstractString = \"simple_white\"\n    show_grid::Bool = true\n    show_ticks::Bool = true\nend\n\nGeneric configuration that applies to any graph. Each complete AbstractGraphConfiguration contains a graph field of this type.\n\nIf output_file is specified, it is the path of a file to write the graph into (ending with .png or .svg). If show_interactive is set, then generate an interactive graph (in a Jupyter notebook). One of output_file and show_interactive must be specified.\n\nThe optional width and height are in pixels, that is, 1/96 of an inch.\n\nBy default, show_grid and show_ticks are set.\n\nThe default template is \"simplewhite\" which is the cleanest. The `showgridandshow_ticks` can be used to disable the grid and/or ticks for an even cleaner (but less informative) look.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.AxisConfiguration","page":"Renderers","title":"MCGraphs.Renderers.AxisConfiguration","text":"@kwdef mutable struct AxisConfiguration <: ObjectWithValidation\n    minimum::Maybe{Real} = nothing\n    maximum::Maybe{Real} = nothing\n    log_scale::Bool,\nend\n\nGeneric configuration for a graph axis. Everything is optional; by default, the minimum and maximum are computed automatically from the data.\n\nIf log_scale is set, the data must contain only positive values, and the axis is shown in log (base 10) scale. To help with finer-grained ratios, each 10x step is broken to three ~2.15 steps (which is \"close enough\" to 2x for intuitive reading of the ratios).\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.ValuesOrientation","page":"Renderers","title":"MCGraphs.Renderers.ValuesOrientation","text":"The orientation of the values axis in a distribution or a bars graph:\n\nHorizontalValues - The values are the X axis\n\nVerticalValues - The values are the Y axis (the default).\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#Distribution","page":"Renderers","title":"Distribution","text":"","category":"section"},{"location":"renderers.html","page":"Renderers","title":"Renderers","text":"MCGraphs.Renderers.DistributionGraphData\nMCGraphs.Renderers.DistributionsGraphData\nMCGraphs.Renderers.DistributionGraphConfiguration\nMCGraphs.Renderers.DistributionsGraphConfiguration\nMCGraphs.Renderers.DistributionStyleConfiguration","category":"page"},{"location":"renderers.html#MCGraphs.Renderers.DistributionGraphData","page":"Renderers","title":"MCGraphs.Renderers.DistributionGraphData","text":"@kwdef mutable struct DistributionGraphData <: AbstractGraphData\n    graph_title::Maybe{AbstractString} = nothing\n    value_axis_title::Maybe{AbstractString} = nothing\n    trace_axis_title::Maybe{AbstractString} = nothing\n    values::AbstractVector{<:Real}\n    name::Maybe{AbstractString} = nothing\nend\n\nBy default, all the titles are empty. You can specify the overall graph_title as well as the value_axis_title and the trace_axis_title. The optional name is used as the tick value for the distribution.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.DistributionsGraphData","page":"Renderers","title":"MCGraphs.Renderers.DistributionsGraphData","text":"@kwdef mutable struct DistributionsGraphData <: AbstractGraphData\n    graph_title::Maybe{AbstractString} = nothing\n    value_axis_title::Maybe{AbstractString} = nothing\n    trace_axis_title::Maybe{AbstractString} = nothing\n    legend_title::Maybe{AbstractString} = nothing\n    values::AbstractVector{AbstractVector{<:Real}}\n    names::Maybe{AbstractStringVector} = nothing\n    colors::Maybe{AbstractStringVector} = nothing\nend\n\nThe data for a multiple distributions graph. By default, all the titles are empty. You can specify the overall graph_title as well as the value_axis_title, the trace_axis_title and the legend_title (if show_legend is set). If specified, the names and/or the colors vectors must contain the same number of elements as the number of vectors in the values.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.DistributionGraphConfiguration","page":"Renderers","title":"MCGraphs.Renderers.DistributionGraphConfiguration","text":"@kwdef mutable struct DistributionGraphConfiguration <: AbstractGraphConfiguration\n    graph::GraphConfiguration = GraphConfiguration()\n    style::DistributionStyleConfiguration = DistributionStyleConfiguration()\n    value_axis::AxisConfiguration = AxisConfiguration()\nend\n\nConfigure a graph for showing a distribution (with DistributionGraphData) or several distributions (with DistributionsGraphData).\n\nThe optional color will be chosen automatically if not specified. When showing multiple distributions, it is also possible to specify the color of each one in the DistributionsGraphData.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.DistributionsGraphConfiguration","page":"Renderers","title":"MCGraphs.Renderers.DistributionsGraphConfiguration","text":"@kwdef mutable struct DistributionsGraphConfiguration <: AbstractGraphConfiguration\n    graph::GraphConfiguration = GraphConfiguration()\n    style::DistributionStyleConfiguration = DistributionStyleConfiguration()\n    value_axis::AxisConfiguration = AxisConfiguration()\n    show_legend::Bool = false\n    overlay::Bool = false\nend\n\nConfigure a graph for showing several distributions several distributions.\n\nThis is identical to DistributionGraphConfiguration with the addition of show_legend to show a legend. This is not set by default as it makes little sense unless overlay is also set. TODO: Implement overlay.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.DistributionStyleConfiguration","page":"Renderers","title":"MCGraphs.Renderers.DistributionStyleConfiguration","text":"@kwdef mutable struct DistributionStyleConfiguration <: ObjectWithValidation\n    show_box::Bool = true\n    show_violin::Bool = false\n    show_curve::Bool = false\n    show_outliers::Bool = false\n    color::Maybe{AbstractString} = nothing\nend\n\nConfigure the style of a distribution graph.\n\nIf show_box, show a box graph.\n\nIf show_violin, show a violin graph.\n\nIf show_curve, show a density curve.\n\nYou can combine the above; however, a density curve is just the positive side of a violin graph, so you can't combine the two.\n\nIn addition to the (combination) of the above, if show_outliers, also show the extreme (outlier) points.\n\nThe color is chosen automatically by default. When showing multiple distributions, you can override it per each one in the DistributionsGraphData.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#Lines","page":"Renderers","title":"Lines","text":"","category":"section"},{"location":"renderers.html","page":"Renderers","title":"Renderers","text":"MCGraphs.Renderers.LineGraphData\nMCGraphs.Renderers.LinesGraphData\nMCGraphs.Renderers.LineGraphConfiguration\nMCGraphs.Renderers.LinesGraphConfiguration\nMCGraphs.Renderers.LineStyleConfiguration\nMCGraphs.Renderers.Stacking","category":"page"},{"location":"renderers.html#MCGraphs.Renderers.LineGraphData","page":"Renderers","title":"MCGraphs.Renderers.LineGraphData","text":"@kwdef mutable struct LineGraphData <: AbstractGraphData\n    graph_title::Maybe{AbstractString} = nothing\n    x_axis_title::Maybe{AbstractString} = nothing\n    y_axis_title::Maybe{AbstractString} = nothing\n    xs::AbstractVector{<:Real}\n    ys::AbstractVector{<:Real}\nend\n\nThe data for a line graph (e.g. a CDF graph).\n\nBy default, all the titles are empty. You can specify the overall graph_title as well as the x_axis_title and y_axis_title for the axes.\n\nThe xs and ys vectors must be of the same size. A line will be drawn through all the points, and the area under the line may be filled.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.LinesGraphData","page":"Renderers","title":"MCGraphs.Renderers.LinesGraphData","text":"@kwdef mutable struct LinesGraphData <: AbstractGraphData\n    graph_title::Maybe{AbstractString} = nothing\n    x_axis_title::Maybe{AbstractString} = nothing\n    y_axis_title::Maybe{AbstractString} = nothing\n    xs::AbstractVector{AbstractVector{<:Real}}\n    ys::AbstractVector{AbstractVector{<:Real}}\n    colors::Maybe{AbstractStringVector} = nothing\n    line_widths::Maybe{AbstractVector{<:Real}} = nothing\nend\n\nThe data for a multiple lines graph.\n\nBy default, all the titles are empty. You can specify the overall graph_title as well as the x_axis_title and y_axis_title for the axes.\n\nThe xs and ys vectors must be of the same size (one per line). For each line, its xs and ys coordinate arrays must also be of the same size; a line will be drawn through all the points, and the area under the line may be filled. If stack_lines is specified in LinesGraphConfiguration, then the lines are specified in top-to-bottom order.\n\nThe names, line_colors, line_widths, fill_belows and are_dashed arrays must have the same number of entries (one per line). The colors are restricted to explicit colors; therefore the color scale options of the style must not be used.\n\nnote: Note\nIf stacked is spe\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.LineGraphConfiguration","page":"Renderers","title":"MCGraphs.Renderers.LineGraphConfiguration","text":"@kwdef mutable struct LineGraphConfiguration <: AbstractGraphConfiguration\n    graph::GraphConfiguration = GraphConfiguration()\n    x_axis::AxisConfiguration = AxisConfiguration()\n    y_axis::AxisConfiguration = AxisConfiguration()\n    style::LineStyleConfiguration = LineStyleConfiguration()\n    vertical_bands::BandsConfiguration = BandsConfiguration()\n    horizontal_bands::BandsConfiguration = BandsConfiguration()\nend\n\nConfigure a graph for showing line plots.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.LinesGraphConfiguration","page":"Renderers","title":"MCGraphs.Renderers.LinesGraphConfiguration","text":"@kwdef mutable struct LinesGraphConfiguration <: AbstractGraphConfiguration\n    graph::GraphConfiguration = GraphConfiguration()\n    x_axis::AxisConfiguration = AxisConfiguration()\n    y_axis::AxisConfiguration = AxisConfiguration()\n    style::LineStyleConfiguration = LineStyleConfiguration()\n    vertical_bands::BandsConfiguration = BandsConfiguration()\n    horizontal_bands::BandsConfiguration = BandsConfiguration()\n    show_legend::Bool = false\n    stacking::Maybe{Stacking} = nothing\nend\n\nConfigure a graph for showing multiple line plots. This allows using show_legend to display a legend of the different lines, and stacking to stack instead of overlay the lines. If stacking is specified, then fill_below is implied, regardless of what its actual setting is.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.LineStyleConfiguration","page":"Renderers","title":"MCGraphs.Renderers.LineStyleConfiguration","text":"@kwdef mutable struct LineStyleConfiguration <: ObjectWithValidation\n    line_width::Maybe{Real} = 1.0\n    fill_below::Bool = false\n    line_is_dashed::Bool = false\n    line_color::Maybe{AbstractString} = nothing\nend\n\nConfigure a line in a graph.\n\nBy default, a solid line is shown; if line_is_dashed, the line will be dashed. If fill_below is set, the area below the line is filled. If the line_width is set to nothing, no line is shown (and fill_below must be set). By default, the line_color is chosen automatically.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.Stacking","page":"Renderers","title":"MCGraphs.Renderers.Stacking","text":"If stacking multiple data sets, how:\n\nStackValues - simply add the values on top of each other.\n\nStackFractions - normalize the added values so their some is 1.\n\nStackPercents - normalize the added values so their some is 100 (percent).\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#Points","page":"Renderers","title":"Points","text":"","category":"section"},{"location":"renderers.html","page":"Renderers","title":"Renderers","text":"MCGraphs.Renderers.PointsGraphData\nMCGraphs.Renderers.PointsGraphConfiguration\nMCGraphs.Renderers.PointsStyleConfiguration","category":"page"},{"location":"renderers.html#MCGraphs.Renderers.PointsGraphData","page":"Renderers","title":"MCGraphs.Renderers.PointsGraphData","text":"@kwdef mutable struct PointsGraphData <: AbstractGraphData\n    graph_title::Maybe{AbstractString} = nothing\n    x_axis_title::Maybe{AbstractString} = nothing\n    y_axis_title::Maybe{AbstractString} = nothing\n    scale_title::Maybe{AbstractString} = nothing\n    border_scale_title::Maybe{AbstractString} = nothing\n    xs::AbstractVector{<:Real}\n    ys::AbstractVector{<:Real}\n    colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing\n    sizes::Maybe{AbstractVector{<:Real}} = nothing\n    hovers::Maybe{AbstractStringVector} = nothing\n    border_colors::Maybe{Union{AbstractStringVector, AbstractVector{<:Real}}} = nothing\n    border_sizes::Maybe{AbstractVector{<:Real}} = nothing\n    edges::Maybe{AbstractVector{Tuple{<:Integer, <:Integer}}} = nothing\n    edges_colors::Maybe{AbstractStringVector} = nothing\n    edges_sizes::Maybe{AbstractVector{<:Real}} = nothing\nend\n\nThe data for a scatter graph of points.\n\nBy default, all the titles are empty. You can specify the overall graph_title as well as the x_axis_title and y_axis_title for the axes.\n\nThe xs and ys vectors must be of the same size. If specified, the colors sizes and/or hovers vectors must also be of the same size. The colors can be either color names or a numeric value; if the latter, then the configuration's color_scale is used. Sizes are the diameter in pixels (1/96th of an inch). Hovers are only shown in interactive graphs (or when saving an HTML file).\n\nThe border_colors and border_sizes can be used to display additional data per point. The border size is in addition to the point size.\n\nThe scale_title and border_scale_title are only used if show_scale is set for the relevant color scales. You can't specify show_scale if there is no colors data or if the colors contain explicit color names.\n\nIt is possible to draw straight edges between specific point pairs. In this case the edges_style of the PointsGraphConfiguration will be used, and the edges_colors and edges_sizes will override it per edge. The edges_colors are restricted to explicit colors, not a color scale.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.PointsGraphConfiguration","page":"Renderers","title":"MCGraphs.Renderers.PointsGraphConfiguration","text":"@kwdef mutable struct PointsGraphConfiguration <: AbstractGraphConfiguration\n    graph::GraphConfiguration = GraphConfiguration()\n    x_axis::AxisConfiguration = AxisConfiguration()\n    y_axis::AxisConfiguration = AxisConfiguration()\n    style::PointsStyleConfiguration = PointsStyleConfiguration()\n    border_style::PointsStyleConfiguration = PointsStyleConfiguration()\n    edges_style::PointsConfiguration = PointsStyleConfiguration()\n    vertical_bands::BandsConfiguration = BandsConfiguration()\n    horizontal_bands::BandsConfiguration = BandsConfiguration()\n    diagonal_bands::BandsConfiguration = BandsConfiguration()\nend\n\nConfigure a graph for showing a scatter graph of points.\n\nUsing the vertical_bands, horizontal_bands and/or diagonal_bands you can partition the graph into regions. The diagonal_bands can only be used if both axes are linear or both axes are in log_scale; they also unify the ranges of the X and Y axes. If the axes are in log_scale, the line_offset of the diagonal_bands are multiplicative instead of additive, and must be positive.\n\nThe border_style is used if the PointsGraphData contains either the border_colors and/or border_sizes. This allows displaying some additional data per point.\n\nnote: Note\nThere is no show_legend for a GraphConfiguration of a points graph. Instead you probably want to set the show_scale of the style (and/or of the border_style and/or edges_style). In addition, the color scale options of the edges_style must not be set, as the edges_colors of PointsGraphData is restricted to explicit colors.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.PointsStyleConfiguration","page":"Renderers","title":"MCGraphs.Renderers.PointsStyleConfiguration","text":"@kwdef mutable struct PointsStyleConfiguration <: ObjectWithValidation\n    size::Maybe{Real} = nothing\n    color::Maybe{AbstractString} = nothing\n    color_scale::Maybe{Union{\n        AbstractString,\n        AbstractVector{<:Tuple{<:Real, <:AbstractString}},\n        AbstractVector{<:Tuple{<:AbstractString, <:AbstractString}}\n    }} = nothing\n    reverse_scale::Bool = false\n    show_scale::Bool = false\nend\n\nConfigure points in a graph. By default, the point size and color is chosen automatically (when this is applied to edges, the size is the width of the line). You can also override this by specifying sizes and colors in the PointsGraphData. If the data contains numeric color values, then the color_scale will be used instead; you can set reverse_scale to reverse it. You need to explicitly set show_scale to show its legend.\n\nThe color_scale can be the name of a standard one, a vector of (value, color) tuples for a continuous scale. If the values are numbers, the scale is continuous; if they are strings, this is a categorical scale. A categorical scale can't be reversed.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#Bands-in-graphs","page":"Renderers","title":"Bands in graphs","text":"","category":"section"},{"location":"renderers.html","page":"Renderers","title":"Renderers","text":"MCGraphs.Renderers.BandsConfiguration\nMCGraphs.Renderers.BandRegionConfiguration","category":"page"},{"location":"renderers.html#MCGraphs.Renderers.BandsConfiguration","page":"Renderers","title":"MCGraphs.Renderers.BandsConfiguration","text":"@kwdef mutable struct BandsConfiguration <: ObjectWithValidation\n    low::BandRegionConfiguration = BandRegionConfiguration(line_is_dashed = true)\n    middle::BandRegionConfiguration = BandRegionConfiguration()\n    high::BandRegionConfiguration = BandRegionConfiguration(line_is_dashed = true)\nend\n\nConfigure the partition of the graph up to three band regions. The low and high are the \"outer\" regions (so their lines are at their border, dashed by default) and the middle is the \"inner\" region between them (so its line is inside it, solid by default).\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.BandRegionConfiguration","page":"Renderers","title":"MCGraphs.Renderers.BandRegionConfiguration","text":"@kwdef mutable struct BandRegionConfiguration <: ObjectWithValidation\n    line_color::Maybe{AbstractString} = \"black\"\n    line_width::Real = 1.0\n    line_is_dashed::Bool = false\n    fill_color::Maybe{AbstractString} = nothing\nend\n\nConfigure a region of the graph defined by some band of values. The region only exists if line_offset is set. To actually show the region, either the line_color and/or the fill_color must be set; by default, just the line is shown. The line_width is in pixels (1/96th of an inch).\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#Index","page":"Renderers","title":"Index","text":"","category":"section"},{"location":"renderers.html","page":"Renderers","title":"Renderers","text":"Pages = [\"renderers.md\"]","category":"page"},{"location":"validations.html#Validations","page":"Validations","title":"Validations","text":"","category":"section"},{"location":"validations.html","page":"Validations","title":"Validations","text":"MCGraphs.Validations\nMCGraphs.Validations.ObjectWithValidation\nMCGraphs.Validations.validate_object\nMCGraphs.Validations.assert_valid_object","category":"page"},{"location":"validations.html#MCGraphs.Validations","page":"Validations","title":"MCGraphs.Validations","text":"Validate user input.\n\nRendering graphs requires two objects: data and configuration. Both objects need to be internally consistent. This is especially relevant for the graph configuration. When creating UI for filling in these objects, we can in general easily validate each field on its own (e.g., ensure that a \"color\" field contains a valid color name). To ensure the overall object is consistent, we provide overall-type-specific validation functions that can be invoked by the UI to inform the user if the combination of (individually valid) field values is not valid for some reason.\n\n\n\n\n\n","category":"module"},{"location":"validations.html#MCGraphs.Validations.ObjectWithValidation","page":"Validations","title":"MCGraphs.Validations.ObjectWithValidation","text":"A common type for objects that support validation, that is, that one can invoke validate_object on.\n\n\n\n\n\n","category":"type"},{"location":"validations.html#MCGraphs.Validations.validate_object","page":"Validations","title":"MCGraphs.Validations.validate_object","text":"validate_object(object::ObjectWithValidation)::Maybe{AbstractString}\n\nValidate all field values of an object are compatible with each other, assuming each one is valid on its own. Returns nothing for a valid object and an error message if something is wrong. By default, this returns nothing.\n\nThis can be used by GUI widgets to validate the object as a whole (as opposed to validating each field based on its type).\n\n\n\n\n\n","category":"function"},{"location":"validations.html#MCGraphs.Validations.assert_valid_object","page":"Validations","title":"MCGraphs.Validations.assert_valid_object","text":"assert_valid_object(object_with_validation::ObjectWithValidation)::Maybe{AbstractString}\n\nThis will @assert that the object_with_validation is valid (that is, validate_object will return nothing for it). This is used in the back-end (graph rendering) code. It is recommended that the front-end (UI) code will invoke validate_object and ensure the user fixes problems before invoking the back-end code.\n\n\n\n\n\n","category":"function"},{"location":"validations.html#Index","page":"Validations","title":"Index","text":"","category":"section"},{"location":"validations.html","page":"Validations","title":"Validations","text":"Pages = [\"validations.md\"]","category":"page"},{"location":"index.html#MCGraphs","page":"MCGraphs","title":"MCGraphs","text":"","category":"section"},{"location":"index.html","page":"MCGraphs","title":"MCGraphs","text":"MCGraphs.MCGraphs","category":"page"},{"location":"index.html#MCGraphs.MCGraphs","page":"MCGraphs","title":"MCGraphs.MCGraphs","text":"Generate graphs for visualizing scRNA-seq metacells data in a Daf data set. The symbols from the main sub-modules are re-exported from the main MCGraphs namespace. These sub-modules are:\n\nValidations - general API allowing controllers to validate use input.\nRenderers - TODO: functions that actually render graphs given their data and configuration.\nExtractors - TODO: functions that extract graph data from metacells Daf data sets.\nPlotters - TODO: functions that combine extraction and rendering, creating a graph in one call.\nControllers - TODO: UI elements for specifying graph data or configuration.\nWidgets - TODO: Combine multiple controllers for generating a complete graph.\nMenus - TODO: A tree of menus for selecting and generating a single graph or a dashboard of multiple graphs.\n\n\n\n\n\n","category":"module"},{"location":"index.html#Index","page":"MCGraphs","title":"Index","text":"","category":"section"},{"location":"index.html","page":"MCGraphs","title":"MCGraphs","text":"","category":"page"}]
}
