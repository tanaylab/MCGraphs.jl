"""
Generate complete graphs from a metacells `Daf` for standard graphs.
"""
module Plotters

export plot_box_box
export plot_boxes_gene_gene
export plot_boxes_marker_genes
export plot_metacells_gene_gene
export plot_metacells_marker_genes

using Daf
using Daf.GenericLogging
using Daf.GenericTypes
using NamedArrays
using ..Renderers
using ..Extractors

"""
    plot_metacells_gene_gene(
        daf::DafReader
        [configuration::PointsGraphConfiguration = PointsGraphConfiguration()];
        x_gene::AbstractString,
        y_gene::AbstractString,
        [min_significant_gene_UMIs::Integer = $(DEFAULT.min_significant_gene_UMIs),
        gene_fraction_regularization::Maybe{AbstractFloat} = $(DEFAULT.gene_fraction_regularization),
        color_query::Maybe{QueryString} = $(DEFAULT.color_query),
        metacells_hovers::Maybe{FrameColumns} = $(DEFAULT.metacells_hovers)]
    )::PointsGraph

Generate a complete metacells gene-gene graph using [`extract_metacells_gene_gene_data`](@ref) and
[`default_gene_gene_configuration`](@ref).

Each point in the graph is a gene which has a robust comparable expression (at least `min_significant_gene_UMIs` between
both metacells).

$(CONTRACT)
"""
@logged @computation function_contract(extract_metacells_gene_gene_data) function plot_metacells_gene_gene(  # untested
    daf::DafReader,
    configuration::PointsGraphConfiguration = PointsGraphConfiguration();
    x_gene::AbstractString,
    y_gene::AbstractString,
    min_significant_gene_UMIs::Integer = 40,
    gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
    color_query::Maybe{QueryString} = ": type => color",
    metacells_hovers::Maybe{FrameColumns} = ["type" => "="],
)::PointsGraph
    data = extract_metacells_gene_gene_data(
        daf;
        x_gene = x_gene,
        y_gene = y_gene,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        color_query = color_query,
        metacells_hovers = metacells_hovers,
    )
    default_gene_gene_configuration(
        daf,
        configuration;
        color_query = color_query,
        gene_fraction_regularization = gene_fraction_regularization,
    )
    return PointsGraph(data, configuration)
end

"""
    plot_boxes_gene_gene(
        daf::DafReader
        [configuration::PointsGraphConfiguration = PointsGraphConfiguration()];
        x_gene::AbstractString,
        y_gene::AbstractString,
        [min_significant_gene_UMIs::Integer = $(DEFAULT.min_significant_gene_UMIs),
        gene_fraction_regularization::Maybe{AbstractFloat} = $(DEFAULT.gene_fraction_regularization),
        color_query::Maybe{QueryString} = $(DEFAULT.color_query),
        boxes_hovers::Maybe{FrameColumns} = $(DEFAULT.boxes_hovers)]
    )::PointsGraph

Generate a complete boxes gene-gene graph using [`extract_boxes_gene_gene_data`](@ref) and
[`default_gene_gene_configuration`](@ref).

Each point in the graph is a gene which has a robust comparable expression (at least `min_significant_gene_UMIs` between
both boxes).

$(CONTRACT)
"""
@logged @computation function_contract(extract_boxes_gene_gene_data) function plot_boxes_gene_gene(  # untested
    daf::DafReader,
    configuration::PointsGraphConfiguration = PointsGraphConfiguration();
    x_gene::AbstractString,
    y_gene::AbstractString,
    min_significant_gene_UMIs::Integer = 40,
    gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
    color_query::Maybe{QueryString} = ": type => color",
    boxes_hovers::Maybe{FrameColumns} = ["type" => "="],
)::PointsGraph
    data = extract_boxes_gene_gene_data(
        daf;
        x_gene = x_gene,
        y_gene = y_gene,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        color_query = color_query,
        boxes_hovers = boxes_hovers,
    )
    default_gene_gene_configuration(
        daf,
        configuration;
        color_query = color_query,
        gene_fraction_regularization = gene_fraction_regularization,
    )
    return PointsGraph(data, configuration)
end

"""
    plot_box_box(
        daf::DafReader,
        [configuration::PointsGraphConfiguration = PointsGraphConfiguration()];
        x_box::AbstractString,
        y_box::AbstractString,
        [min_significant_gene_UMIs::Integer = $(DEFAULT.min_significant_gene_UMIs),
        max_box_span::AbstractFloat = $(DEFAULT.max_box_span),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization)],
    )::PointsGraph

Generate a complete box-box graph using [`extract_box_box_data`](@ref) and
[`default_box_box_configuration`](@ref).

Each point in the graph is a gene which has a robust comparable expression (at least `min_significant_gene_UMIs` between
both spgeres). A line is attached to each point showing the confidence modification used when deciding on grouping of
metacells into boxes.

$(CONTRACT)
"""
@logged @computation function_contract(extract_box_box_data) function plot_box_box(  # untested
    daf::DafReader,
    configuration::PointsGraphConfiguration = PointsGraphConfiguration();
    x_box::AbstractString,
    y_box::AbstractString,
    min_significant_gene_UMIs::Integer = 40,
    max_box_span::AbstractFloat = 2.0,
    gene_fraction_regularization::AbstractFloat = 1e-5,
)::PointsGraph
    data = extract_box_box_data(
        daf;
        x_box = x_box,
        y_box = y_box,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        gene_fraction_regularization = gene_fraction_regularization,
    )
    default_box_box_configuration(
        configuration;
        x_box = x_box,
        y_box = y_box,
        max_box_span = max_box_span,
        gene_fraction_regularization = gene_fraction_regularization,
    )
    return Graph(data, configuration)
end

"""
    function plot_metacells_marker_genes(
        daf::DafReader,
        [configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
        gene_names::Maybe{Vector{AbstractString}} = $(DEFAULT.gene_names),
        max_marker_genes::Integer = $(DEFAULT.max_marker_genes),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization),
        type_annotation::Bool = $(DEFAULT.type_annotation),
        expression_annotations::Maybe{FrameColumns} = $(DEFAULT.expression_annotations),
        named_gene_annotation::Bool = $(DEFAULT.named_gene_annotation),
        gene_annotations::Maybe{FrameColumns} = $(DEFAULT.gene_annotations),
        reorder_by_type::Bool = $(DEFAULT.reorder_by_type),
        min_significant_fold::Real = $(DEFAULT.min_significant_fold),
        max_significant_fold::Real = $(DEFAULT.max_significant_fold)]
    )::HeatmapGraph

Generate a metacells marker genes graph. This shows the genes that most distinguish between metacells (or profiles using
another axis). Type annotations are added based on the `type_property` (which should name an axis with a `color`
property), and optional `expression_annotations` and `gene_annotations`.

If `gene_names` is specified, these genes will always appear in the graph. This list is supplemented with additional
`is_marker` genes to show at least `min_marker_genes`. A number of strongest such genes is chosen from each profile,
such that the total number of these genes together with the forced `gene_names` is at least `min_marker_genes`.

The data is clustered to show the structure of both genes and metacells (or profiles using another axis). If
`reorder_by_type` is specified, and `type_property` is not be `nothing`, then the profiles are reordered so that each
type is contiguous.

Genes whose (absolute) fold factor (log base 2 of the ratio between the expression level and the median of the
population) is less than `min_significant_fold` are colored in white. The color scale continues until
`max_significant_fold`.

$(CONTRACT)
"""
@logged @computation (
    function_contract(extract_metacells_marker_genes_data) |> function_contract(default_marker_genes_configuration)
) function plot_metacells_marker_genes(  # untested
    daf::DafReader,
    configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
    gene_names::Maybe{Vector{AbstractString}} = nothing,
    max_marker_genes::Integer = 100,
    gene_fraction_regularization::AbstractFloat = 1e-5,
    type_annotation::Bool = true,
    expression_annotations::Maybe{FrameColumns} = nothing,
    named_gene_annotation::Bool = true,
    gene_annotations::Maybe{FrameColumns} = ["is_lateral", "divergence"],
    reorder_by_type::Bool = true,
    min_significant_fold::Real = 0.5,
    max_significant_fold::Real = 3.0,
)::HeatmapGraph
    data = extract_metacells_marker_genes_data(
        daf;
        gene_names = gene_names,
        max_marker_genes = max_marker_genes,
        gene_fraction_regularization = gene_fraction_regularization,
        type_annotation = type_annotation,
        expression_annotations = expression_annotations,
        named_gene_annotation = named_gene_annotation,
        gene_annotations = gene_annotations,
        reorder_by_type = reorder_by_type,
    )
    configuration = default_marker_genes_configuration(
        daf,
        configuration;
        type_annotation = type_annotation,
        min_significant_fold = min_significant_fold,
        max_significant_fold = max_significant_fold,
    )
    return Graph(data, configuration)
end

"""
    function plot_boxes_marker_genes(
        daf::DafReader,
        [configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
        gene_names::Maybe{Vector{AbstractString}} = $(DEFAULT.gene_names),
        max_marker_genes::Integer = $(DEFAULT.max_marker_genes),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization),
        type_annotation::Bool = $(DEFAULT.type_annotation),
        expression_annotations::Maybe{FrameColumns} = $(DEFAULT.expression_annotations),
        named_gene_annotation::Bool = $(DEFAULT.named_gene_annotation),
        gene_annotations::Maybe{FrameColumns} = $(DEFAULT.gene_annotations),
        reorder_by_type::Bool = $(DEFAULT.reorder_by_type)m
        min_significant_fold::Real = $(DEFAULT.min_significant_fold),
        max_significant_fold::Real = $(DEFAULT.max_significant_fold)]
    )::HeatmapGraph

Generate a boxes marker genes graph. This shows the genes that most distinguish between boxes (or profiles using another
axis). Type annotations are added based on the `type_property` (which should name an axis with a `color` property), and
optional `expression_annotations` and `gene_annotations`.

If `gene_names` is specified, these genes will always appear in the graph. This list is supplemented with additional
`is_marker` genes to show at least `min_marker_genes`. A number of strongest such genes is chosen from each profile,
such that the total number of these genes together with the forced `gene_names` is at least `min_marker_genes`.

The data is clustered to show the structure of both genes and boxes (or profiles using another axis). If
`reorder_by_type` is specified, and `type_property` is not be `nothing`, then the profiles are reordered so that each
type is contiguous.

Genes whose (absolute) fold factor (log base 2 of the ratio between the expression level and the median of the
population) is less than `min_significant_fold` are colored in white. The color scale continues until
`max_significant_fold`.

$(CONTRACT)
"""
@logged @computation (
    function_contract(extract_boxes_marker_genes_data) |> function_contract(default_marker_genes_configuration)
) function plot_boxes_marker_genes(  # untested
    daf::DafReader,
    configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
    gene_names::Maybe{Vector{AbstractString}} = nothing,
    max_marker_genes::Integer = 100,
    gene_fraction_regularization::AbstractFloat = 1e-5,
    type_annotation::Bool = true,
    expression_annotations::Maybe{FrameColumns} = nothing,
    named_gene_annotation::Bool = true,
    gene_annotations::Maybe{FrameColumns} = ["is_lateral", "divergence"],
    reorder_by_type::Bool = true,
    min_significant_fold::Real = 0.5,
    max_significant_fold::Real = 3.0,
)::HeatmapGraph
    data = extract_boxes_marker_genes_data(
        daf;
        gene_names = gene_names,
        max_marker_genes = max_marker_genes,
        gene_fraction_regularization = gene_fraction_regularization,
        type_annotation = type_annotation,
        expression_annotations = expression_annotations,
        named_gene_annotation = named_gene_annotation,
        gene_annotations = gene_annotations,
        reorder_by_type = reorder_by_type,
    )
    configuration = default_marker_genes_configuration(
        daf,
        configuration;
        type_annotation = type_annotation,
        min_significant_fold = min_significant_fold,
        max_significant_fold = max_significant_fold,
    )
    return Graph(data, configuration)
end

end  # module
