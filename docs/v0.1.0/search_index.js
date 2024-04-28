var documenterSearchIndex = {"docs":
[{"location":"renderers.html#Renderers","page":"Renderers","title":"Renderers","text":"","category":"section"},{"location":"renderers.html","page":"Renderers","title":"Renderers","text":"MCGraphs.Renderers\nMCGraphs.Renderers.render\nMCGraphs.Renderers.GraphConfiguration\nMCGraphs.Renderers.AxisConfiguration\nMCGraphs.Renderers.ValuesOrientation","category":"page"},{"location":"renderers.html#MCGraphs.Renderers","page":"Renderers","title":"MCGraphs.Renderers","text":"Render interactive or static graphs.\n\nThis provides a selection of basic graph types needed for metacells visualization. For each one, we define a struct containing all the data for the graph, and a separate struct containing the configuration of the graph. The rendering function takes both and either returns a JavaScript blob needed to create the interactive graph, or writes the graph to a file.\n\n\n\n\n\n","category":"module"},{"location":"renderers.html#MCGraphs.Renderers.render","page":"Renderers","title":"MCGraphs.Renderers.render","text":"render(\n    data::SomeGraphData,\n    configuration::SomeGraphConfiguration = SomeGraphConfiguration()\n)::Nothing\n\nRender a graph given its data and configuration. The implementation depends on the specific graph.\n\n\n\n\n\n","category":"function"},{"location":"renderers.html#MCGraphs.Renderers.GraphConfiguration","page":"Renderers","title":"MCGraphs.Renderers.GraphConfiguration","text":"@kwdef mutable struct GraphConfiguration <: ObjectWithValidation\n    file::Maybe{AbstractString} = nothing\n    title::AbstractString = \"\"\n    width::Maybe{Int} = nothing\n    height::Maybe{Int} = nothing\nend\n\nGeneric configuration that applies to any graph.\n\nIf output_file is specified, it is the path of a file to write the graph into (ending with .png or .svg). If show_interactive is set, then generate an interactive graph (in a Jupyter notebook). One of output_file and show_interactive must be specified.\n\nIf specified, graph_title is used for the whole graph.\n\nThe optional graph_width and graph_height are in pixels, that is, 1/96 of an inch.\n\nIf set (the default), a grid is shown across the graph area.\n\nThe default template is \"simple_white\" which is the cleanest.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.AxisConfiguration","page":"Renderers","title":"MCGraphs.Renderers.AxisConfiguration","text":"@kwdef mutable struct AxisConfiguration <: ObjectWithValidation\n    title::AbstractString = \"\"\n    minimum::Maybe{Real} = nothing\n    maximum::Maybe{Real} = nothing\nend\n\nGeneric configuration for a graph axis. Everything is optional; by default, the title is empty and the minimum and maximum are computed automatically from the data.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.ValuesOrientation","page":"Renderers","title":"MCGraphs.Renderers.ValuesOrientation","text":"The orientation of the values axis in a distribution or bar graph:\n\nHorizontalValues - The values are the X axis\n\nVerticalValues - The values are the Y axis (the default).\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#Distribution","page":"Renderers","title":"Distribution","text":"","category":"section"},{"location":"renderers.html","page":"Renderers","title":"Renderers","text":"MCGraphs.Renderers.DistributionGraphConfiguration\nMCGraphs.Renderers.DistributionShapeConfiguration\nMCGraphs.Renderers.DistributionGraphData","category":"page"},{"location":"renderers.html#MCGraphs.Renderers.DistributionGraphConfiguration","page":"Renderers","title":"MCGraphs.Renderers.DistributionGraphConfiguration","text":"@kwdef mutable struct DistributionGraphConfiguration <: ObjectWithValidation\n    graph::GraphConfiguration = GraphConfiguration()\n    shape::DistributionShapeConfiguration = DistributionShapeConfiguration()\n    orientation::ValuesOrientation = VerticalValues\n    color::Maybe{AbstractString} = nothing\n    values_axis::AxisConfiguration = AxisConfiguration()\n    trace_title::Maybe{AbstractString} = nothing\nend\n\nConfigure a graph for showing a distribution.\n\nThe optional color will be chosen automatically if not specified.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.DistributionShapeConfiguration","page":"Renderers","title":"MCGraphs.Renderers.DistributionShapeConfiguration","text":"@kwdef mutable struct DistributionShapeConfiguration <: ObjectWithValidation\n    show_box::Bool = true\n    show_violin::Bool = false\n    show_curve::Bool = false\n    show_outliers::Bool = false\nend\n\nConfigure the shape of a distribution graph.\n\nIf show_box, show a box graph.\n\nIf show_violin, show a violin graph.\n\nIf show_curve, show a density curve.\n\nYou can combine the above; however, a density curve is just the positive side of a violin graph, so you can't combine the two.\n\nIn addition to the (combination) of the above, if show_outliers, also show the extreme (outlier) points.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#MCGraphs.Renderers.DistributionGraphData","page":"Renderers","title":"MCGraphs.Renderers.DistributionGraphData","text":"@kwdef mutable struct DistributionGraphData\n    values::AbstractVector{<:Real}\n    title::Maybe{AbstractString} = nothing\nend\n\nThe data for a distribution graph, which is simply a vector of values.\n\n\n\n\n\n","category":"type"},{"location":"renderers.html#Index","page":"Renderers","title":"Index","text":"","category":"section"},{"location":"renderers.html","page":"Renderers","title":"Renderers","text":"Pages = [\"renderers.md\"]","category":"page"},{"location":"validations.html#Validations","page":"Validations","title":"Validations","text":"","category":"section"},{"location":"validations.html","page":"Validations","title":"Validations","text":"MCGraphs.Validations\nMCGraphs.Validations.ObjectWithValidation\nMCGraphs.Validations.validate_object\nMCGraphs.Validations.assert_valid_object","category":"page"},{"location":"validations.html#MCGraphs.Validations","page":"Validations","title":"MCGraphs.Validations","text":"Validate user input.\n\nRendering graphs requires two objects: data and configuration. Both objects need to be internally consistent. This is especially relevant for the graph configuration. When creating UI for filling in these objects, we can in general easily validate each field on its own (e.g., ensure that a \"color\" field contains a valid color name). To ensure the overall object is consistent, we provide overall-type-specific validation functions that can be invoked by the UI to inform the user if the combination of (individually valid) field values is not valid for some reason.\n\n\n\n\n\n","category":"module"},{"location":"validations.html#MCGraphs.Validations.ObjectWithValidation","page":"Validations","title":"MCGraphs.Validations.ObjectWithValidation","text":"A common type for objects that support validation, that is, that one can invoke validate_object on.\n\n\n\n\n\n","category":"type"},{"location":"validations.html#MCGraphs.Validations.validate_object","page":"Validations","title":"MCGraphs.Validations.validate_object","text":"validate_object(object::ObjectWithValidation)::Maybe{AbstractString}\n\nValidate all field values of an object are compatible with each other, assuming each one is valid on its own. Returns nothing for a valid object and an error message if something is wrong. By default, this returns nothing.\n\nThis can be used by GUI widgets to validate the object as a whole (as opposed to validating each field based on its type).\n\n\n\n\n\n","category":"function"},{"location":"validations.html#MCGraphs.Validations.assert_valid_object","page":"Validations","title":"MCGraphs.Validations.assert_valid_object","text":"assert_valid_object(object_with_validation::ObjectWithValidation)::Maybe{AbstractString}\n\nThis will @assert that the object_with_validation is valid (that is, validate_object will return nothing for it). This is used in the back-end (graph rendering) code. It is recommended that the front-end (UI) code will invoke validate_object and ensure the user fixes problems before invoking the back-end code.\n\n\n\n\n\n","category":"function"},{"location":"validations.html#Index","page":"Validations","title":"Index","text":"","category":"section"},{"location":"validations.html","page":"Validations","title":"Validations","text":"Pages = [\"validations.md\"]","category":"page"},{"location":"index.html#MCGraphs","page":"MCGraphs","title":"MCGraphs","text":"","category":"section"},{"location":"index.html","page":"MCGraphs","title":"MCGraphs","text":"MCGraphs.MCGraphs","category":"page"},{"location":"index.html#MCGraphs.MCGraphs","page":"MCGraphs","title":"MCGraphs.MCGraphs","text":"Generate graphs for visualizing scRNA-seq metacells data in a Daf data set. The symbols from the main sub-modules are re-exported from the main MCGraphs namespace. These sub-modules are:\n\nValidations - general API allowing controllers to validate use input.\nRenderers - TODO: functions that actually render graphs given their data and configuration.\nExtractors - TODO: functions that extract graph data from metacells Daf data sets.\nPlotters - TODO: functions that combine extraction and rendering, creating a graph in one call.\nControllers - TODO: UI elements for specifying graph data or configuration.\nWidgets - TODO: Combine multiple controllers for generating a complete graph.\nMenus - TODO: A tree of menus for selecting and generating a single graph or a dashboard of multiple graphs.\n\n\n\n\n\n","category":"module"},{"location":"index.html#Index","page":"MCGraphs","title":"Index","text":"","category":"section"},{"location":"index.html","page":"MCGraphs","title":"MCGraphs","text":"","category":"page"}]
}
