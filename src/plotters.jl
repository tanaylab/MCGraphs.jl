"""
Generate complete graphs from a metacells `Daf` for standard graphs.
"""
module Plotters

export plot_gene_gene
export plot_box_box
export plot_marker_genes

using Daf
using Daf.GenericTypes
using NamedArrays
using ..Renderers
using ..Extractors

"""
    plot_gene_gene(
        daf::DafReader
        [configuration::PointsGraphConfiguration = PointsGraphConfiguration()];
        x_gene::AbstractString,
        y_gene::AbstractString,
        [axis::QueryString = "metacell",
        color::Maybe{QueryString} = "type",
        min_significant_gene_UMIs::Integer = 40,
        gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
        colors::Maybe{QueryString} = "/ type : color",
        entries_hovers::Maybe{FrameColumns} = ["total_UMIs" => "=", "type" => "="],
        genes_hovers::Maybe{FrameColumns} = nothing,]
    )::PointsGraph

Generate a complete gene-gene graph using [`extract_gene_gene_data`](@ref), [`extract_categorical_color_palette`](@ref),
and [`default_gene_gene_configuration`](@ref).

By default, we look at gene expression per metacell; you can override this using the `axis` parameter. Each point in the
graph is a gene which has a robust comparable expression (at least `min_significant_gene_UMIs` between both axis
entries).
"""
function plot_gene_gene(  # untested
    daf::DafReader,
    configuration::PointsGraphConfiguration = PointsGraphConfiguration();
    x_gene::AbstractString,
    y_gene::AbstractString,
    axis::QueryString = "metacell",
    color::Maybe{QueryString} = "type",
    min_significant_gene_UMIs::Integer = 40,
    gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
    colors::Maybe{QueryString} = "/ type : color",
    entries_hovers::Maybe{FrameColumns} = ["total_UMIs" => "=", "type" => "="],
    genes_hovers::Maybe{FrameColumns} = nothing,
)::PointsGraph
    data = extract_gene_gene_data(
        daf;
        x_gene = x_gene,
        y_gene = y_gene,
        axis = axis,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        color = color,
        entries_hovers = entries_hovers,
        genes_hovers = genes_hovers,
    )
    default_gene_gene_configuration(configuration; gene_fraction_regularization = gene_fraction_regularization)
    if colors !== nothing
        configuration.points.color_palette = extract_categorical_color_palette(daf, colors)
    end
    return PointsGraph(data, configuration)
end

"""
    plot_box_box(
        daf::DafReader,
        [configuration::PointsGraphConfiguration = PointsGraphConfiguration()];
        x_box::AbstractString,
        y_box::AbstractString,
        [min_significant_gene_UMIs::Integer = 40,
        max_box_span::AbstractFloat = 2.0,
        gene_fraction_regularization::AbstractFloat = 1e-5,
        confidence::AbstractFloat = 0.9],
    )::PointsGraph

Generate a complete box-box graph using [`extract_box_box_data`](@ref) and
[`default_box_box_configuration`](@ref).

Each point in the graph is a gene which has a robust comparable expression (at least `min_significant_gene_UMIs` between
both spgeres). A line is attached to each point showing the confidence modification used when deciding on grouping of
metacells into boxes.
"""
function plot_box_box(
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
    function plot_marker_genes(
        daf::DafReader,
        [configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
        axis::abstractstring = "metacell",
        gene_names::maybe{vector{abstractstring}} = nothing,
        max_marker_genes::integer = 100,
        gene_fraction_regularization::abstractfloat = 1e-5,
        type_property::maybe{abstractstring} = "type",
        expression_annotations::maybe{querycolumns} = nothing,
        gene_annotations::maybe{querycolumns} = ["is_lateral", "divergence"],
        min_significant_fold::Real = 3.0,
        max_significant_fold::Real = 5.0],
    )::HeatmapGraph

Generate a marker genes graph. This shows the genes that most distinguish between metacells (or profiles using another
axis). Type annotations are added based on the `type_property` (which should name an axis with a `color` property), and
optional `expression_annotations` and `gene_annotations`.

If `gene_names` is specified, these genes will always appear in the graph. This list is supplemented with additional
`is_marker` genes to show at least `min_marker_genes`. A number of strongest such genes is chosen from each profile,
such that the total number of these genes together with the forced `gene_names` is at least `min_marker_genes`.

Genes whose (absolute) fold factor (log base 2 of the ratio between the expression level and the median of the
population) is less than `min_significant_fold` are colored in white. The color scale continues until
`max_significant_fold`.
"""
function plot_marker_genes(
    daf::DafReader,
    configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
    axis::AbstractString = "metacell",
    gene_names::Maybe{Vector{AbstractString}} = nothing,
    max_marker_genes::Integer = 100,
    gene_fraction_regularization::AbstractFloat = 1e-5,
    type_property::Maybe{AbstractString} = "type",
    expression_annotations::Maybe{FrameColumns} = nothing,
    gene_annotations::Maybe{FrameColumns} = ["is_lateral", "divergence"],
    min_significant_fold::Real = 3.0,
    max_significant_fold::Real = 5.0,
)::HeatmapGraph
    data = extract_marker_genes_data(
        daf;
        axis = axis,
        gene_names = gene_names,
        max_marker_genes = max_marker_genes,
        gene_fraction_regularization = gene_fraction_regularization,
        type_property = type_property,
        expression_annotations = expression_annotations,
        gene_annotations = gene_annotations,
    )
    configuration = default_marker_genes_configuration(
        daf,
        configuration;
        type_property = type_property,
        min_significant_fold = min_significant_fold,
        max_significant_fold = max_significant_fold,
    )
    return Graph(data, configuration)
end

end  # module
