"""
Generate complete graphs from a metacells `Daf` for standard graphs.
"""
module Plotters

export plot_block_block
export plot_block_programs
export plot_blocks_gene_gene
export plot_blocks_marker_genes
export plot_blocks_marker_genes
export plot_metacells_gene_gene
export plot_metacells_marker_genes

using Daf
using Daf.GenericLogging
using Daf.GenericTypes
using Metacells
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
        colors_query::Maybe{QueryString} = $(DEFAULT.colors_query),
        hovers_columns::Maybe{FrameColumns} = $(DEFAULT.metacells_hovers)]
        colors_palette_query::Maybe{QueryString} = $(DEFAULT.colors_palette_query),
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
    min_significant_gene_UMIs::Integer = function_default(extract_metacells_gene_gene_data, :min_significant_gene_UMIs),
    gene_fraction_regularization::AbstractFloat = function_default(
        compute_factor_priority_of_genes!,
        :gene_fraction_regularization,
    ),
    colors_query::Maybe{QueryString} = function_default(extract_metacells_gene_gene_data, :colors_query),
    hovers_columns::Maybe{FrameColumns} = function_default(extract_metacells_gene_gene_data, :hovers_columns),
    colors_palette_query::Maybe{QueryString} = function_default(default_gene_gene_configuration, :colors_palette_query),
)::PointsGraph
    data = extract_metacells_gene_gene_data(
        daf;
        x_gene = x_gene,
        y_gene = y_gene,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        colors_query = colors_query,
        hovers_columns = hovers_columns,
    )
    default_gene_gene_configuration(
        daf,
        configuration;
        colors_palette_query = colors_palette_query,
        gene_fraction_regularization = gene_fraction_regularization,
    )
    return PointsGraph(data, configuration)
end

"""
    plot_blocks_gene_gene(
        daf::DafReader
        [configuration::PointsGraphConfiguration = PointsGraphConfiguration()];
        x_gene::AbstractString,
        y_gene::AbstractString,
        [min_significant_gene_UMIs::Integer = $(DEFAULT.min_significant_gene_UMIs),
        gene_fraction_regularization::Maybe{AbstractFloat} = $(DEFAULT.gene_fraction_regularization),
        colors_query::Maybe{QueryString} = $(DEFAULT.colors_query),
        hovers_columns::Maybe{FrameColumns} = $(DEFAULT.hovers_columns)]
        colors_palette_query::Maybe{QueryString} = $(DEFAULT.colors_palette_query),
    )::PointsGraph

Generate a complete blocks gene-gene graph using [`extract_blocks_gene_gene_data`](@ref) and
[`default_gene_gene_configuration`](@ref).

Each point in the graph is a gene which has a robust comparable expression (at least `min_significant_gene_UMIs` between
both blocks).

$(CONTRACT)
"""
@logged @computation function_contract(extract_blocks_gene_gene_data) function plot_blocks_gene_gene(  # untested
    daf::DafReader,
    configuration::PointsGraphConfiguration = PointsGraphConfiguration();
    x_gene::AbstractString,
    y_gene::AbstractString,
    min_significant_gene_UMIs::Integer = function_default(extract_blocks_gene_gene_data, :min_significant_gene_UMIs),
    gene_fraction_regularization::AbstractFloat = function_default(compute_blocks!, :gene_fraction_regularization),
    colors_query::Maybe{QueryString} = function_default(extract_blocks_gene_gene_data, :colors_query),
    hovers_columns::Maybe{FrameColumns} = function_default(extract_blocks_gene_gene_data, :hovers_columns),
    colors_palette_query::Maybe{QueryString} = function_default(default_gene_gene_configuration, :colors_palette_query),
)::PointsGraph
    data = extract_blocks_gene_gene_data(
        daf;
        x_gene = x_gene,
        y_gene = y_gene,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        colors_query = colors_query,
        hovers_columns = hovers_columns,
    )
    default_gene_gene_configuration(
        daf,
        configuration;
        colors_palette_query = colors_palette_query,
        gene_fraction_regularization = gene_fraction_regularization,
    )
    return PointsGraph(data, configuration)
end

"""
    plot_block_block(
        daf::DafReader,
        [configuration::PointsGraphConfiguration = PointsGraphConfiguration()];
        x_block::AbstractString,
        y_block::AbstractString,
        [min_significant_gene_UMIs::Integer = $(DEFAULT.min_significant_gene_UMIs),
        max_block_span::Real = $(DEFAULT.max_block_span),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization)],
    )::PointsGraph

Generate a complete block-block graph using [`extract_block_block_data`](@ref) and
[`default_block_block_configuration`](@ref).

Each point in the graph is a gene which has a robust comparable expression (at least `min_significant_gene_UMIs` between
both blocks). A line is attached to each point showing the confidence modification used when deciding on grouping of
metacells into blocks.

$(CONTRACT)
"""
@logged @computation function_contract(extract_block_block_data) function plot_block_block(  # untested
    daf::DafReader,
    configuration::PointsGraphConfiguration = PointsGraphConfiguration();
    x_block::AbstractString,
    y_block::AbstractString,
    min_significant_gene_UMIs::Integer = function_default(compute_blocks!, :min_significant_gene_UMIs),
    max_block_span::Real = function_default(compute_blocks!, :max_block_span),
    gene_fraction_regularization::AbstractFloat = function_default(compute_blocks!, :gene_fraction_regularization),
    fold_confidence::AbstractFloat = function_default(compute_blocks!, :fold_confidence),
)::PointsGraph
    data = extract_block_block_data(
        daf;
        x_block = x_block,
        y_block = y_block,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        gene_fraction_regularization = gene_fraction_regularization,
        fold_confidence = fold_confidence,
    )
    default_block_block_configuration(
        configuration;
        max_block_span = max_block_span,
        gene_fraction_regularization = gene_fraction_regularization,
    )
    return Graph(data, configuration)
end

"""
    function plot_metacells_marker_genes(
        daf::DafReader,
        [configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
        forced_genes::Maybe{AbstractVector{<:AbstractString}} = $(DEFAULT.forced_genes),
        max_marker_genes::Integer = $(DEFAULT.max_marker_genes),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization),
        metacells_annotations::Maybe{AbstractVector{AnnotationData}} = $(DEFAULT.metacells_annotations),
        metacells_group_by::Maybe{QueryString} = $(DEFAULT.metacells_group_by),
        genes_annotations::Maybe{AbstractVector{AnnotationData}} = $(DEFAULT.genes_annotations),
        forced_genes_title::Maybe{AbstractString} = $(DEFAULT.forced_genes_title),
        forced_genes_colors_palette::Maybe{AbstractString} = $(DEFAULT.forced_genes_colors_palette),
        forced_genes_hovers::Maybe{AbstractString} = $(DEFAULT.forced_genes_hovers),
        min_significant_fold::Real = $(DEFAULT.min_significant_fold),
        max_significant_fold::Real = $(DEFAULT.max_significant_fold),
    )::HeatmapGraph

TODOX

$(CONTRACT)
"""
@logged @computation function_contract(extract_metacells_marker_genes_data) function plot_metacells_marker_genes(  # untested
    daf::DafReader,
    configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
    forced_genes::Maybe{AbstractVector{<:AbstractString}} = function_default(
        extract_metacells_marker_genes_data,
        :forced_genes,
    ),
    max_marker_genes::Integer = function_default(extract_metacells_marker_genes_data, :max_marker_genes),
    gene_fraction_regularization::AbstractFloat = function_default(
        extract_metacells_marker_genes_data,
        :gene_fraction_regularization,
    ),
    metacells_annotations::Maybe{AbstractVector{AnnotationData}} = function_default(
        extract_metacells_marker_genes_data,
        :metacells_annotations,
    ),
    metacells_group_by::Maybe{AbstractString} = function_default(
        extract_metacells_marker_genes_data,
        :metacells_group_by,
    ),
    genes_annotations::Maybe{AbstractVector{AnnotationData}} = function_default(
        extract_metacells_marker_genes_data,
        :genes_annotations,
    ),
    forced_genes_title::Maybe{AbstractString} = function_default(
        extract_metacells_marker_genes_data,
        :forced_genes_title,
    ),
    forced_genes_colors_palette::Maybe{Union{AbstractString, ContinuousColors}} = function_default(
        extract_blocks_marker_genes_data,
        :forced_genes_colors_palette,
    ),
    min_significant_fold::Real = function_default(default_marker_genes_configuration, :min_significant_fold),
    max_significant_fold::Real = function_default(default_marker_genes_configuration, :max_significant_fold),
)::HeatmapGraph
    data = extract_metacells_marker_genes_data(
        daf;
        forced_genes = forced_genes,
        max_marker_genes = max_marker_genes,
        gene_fraction_regularization = gene_fraction_regularization,
        metacells_annotations = metacells_annotations,
        metacells_group_by = metacells_group_by,
        genes_annotations = genes_annotations,
        forced_genes_title = forced_genes_title,
        forced_genes_colors_palette = forced_genes_colors_palette,
    )
    configuration = default_marker_genes_configuration(
        configuration;
        min_significant_fold = min_significant_fold,
        max_significant_fold = max_significant_fold,
    )
    return Graph(data, configuration)
end

"""
    function plot_blocks_marker_genes(
        daf::DafReader,
        [configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
        forced_genes::Maybe{AbstractVector{<:AbstractString}} = $(DEFAULT.forced_genes),
        max_marker_genes::Integer = $(DEFAULT.max_marker_genes),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization),
        blocks_annotations::Maybe{AbstractVector{AnnotationData}} = $(DEFAULT.blocks_annotations),
        blocks_group_by::Maybe{AbstractString} = $(DEFAULT.blocks_group_by)(,
        genes_annotations::Maybe{AbstractVector{AnnotationData}} = $(DEFAULT.genes_annotations),
        forced_genes_title::Maybe{AbstractString} = $(DEFAULT.forced_genes_title),
        forced_genes_colors_palette::Maybe{AbstractString} = $(DEFAULT.forced_genes_colors_palette),
        min_significant_fold::Real = $(DEFAULT.min_significant_fold),
        max_significant_fold::Real = $(DEFAULT.max_significant_fold),
    )::HeatmapGraph

TODOX

$(CONTRACT)
"""
@logged @computation function_contract(extract_blocks_marker_genes_data) function plot_blocks_marker_genes(  # untested
    daf::DafReader,
    configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
    forced_genes::Maybe{AbstractVector{<:AbstractString}} = function_default(
        extract_blocks_marker_genes_data,
        :forced_genes,
    ),
    max_marker_genes::Integer = function_default(extract_blocks_marker_genes_data, :max_marker_genes),
    gene_fraction_regularization::AbstractFloat = function_default(compute_blocks!, :gene_fraction_regularization),
    blocks_annotations::Maybe{AbstractVector{AnnotationData}} = function_default(
        extract_blocks_marker_genes_data,
        :blocks_annotations,
    ),
    blocks_group_by::Maybe{AbstractString} = function_default(extract_blocks_marker_genes_data, :blocks_group_by),
    genes_annotations::Maybe{AbstractVector{AnnotationData}} = function_default(
        extract_blocks_marker_genes_data,
        :genes_annotations,
    ),
    forced_genes_title::Maybe{AbstractString} = function_default(extract_blocks_marker_genes_data, :forced_genes_title),
    forced_genes_colors_palette::Maybe{Union{AbstractString, ContinuousColors}} = function_default(
        extract_blocks_marker_genes_data,
        :forced_genes_colors_palette,
    ),
    min_significant_fold::Real = function_default(default_marker_genes_configuration, :min_significant_fold),
    max_significant_fold::Real = function_default(default_marker_genes_configuration, :max_significant_fold),
)::HeatmapGraph
    data = extract_blocks_marker_genes_data(
        daf;
        forced_genes = forced_genes,
        max_marker_genes = max_marker_genes,
        gene_fraction_regularization = gene_fraction_regularization,
        blocks_annotations = blocks_annotations,
        blocks_group_by = blocks_group_by,
        genes_annotations = genes_annotations,
        forced_genes_title = forced_genes_title,
        forced_genes_colors_palette = forced_genes_colors_palette,
    )
    configuration = default_marker_genes_configuration(
        configuration;
        min_significant_fold = min_significant_fold,
        max_significant_fold = max_significant_fold,
    )
    return Graph(data, configuration)
end

"""
TODOX
"""
@logged @computation function_contract(extract_block_programs_data) function plot_block_programs(  # untested
    daf::DafReader,
    configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
    block::AbstractString,
    all_local_predictive_genes::Bool = function_default(extract_block_programs_data, :all_local_predictive_genes),
    max_programs_genes::Integer = function_default(extract_block_programs_data, :max_programs_genes),
    genes_annotations::Maybe{AbstractVector{AnnotationData}} = function_default(
        extract_block_programs_data,
        :genes_annotations,
    ),
    factors_annotations::Maybe{AbstractVector{AnnotationData}} = function_default(
        extract_block_programs_data,
        :factors_annotations,
    ),
    min_significant_coefficient::Real = function_default(
        default_block_programs_configuration,
        :min_significant_coefficient,
    ),
    max_significant_coefficient::Real = function_default(
        default_block_programs_configuration,
        :max_significant_coefficient,
    ),
)::HeatmapGraph
    data = extract_block_programs_data(
        daf;
        block = block,
        all_local_predictive_genes = all_local_predictive_genes,
        max_programs_genes = max_programs_genes,
        genes_annotations = genes_annotations,
        factors_annotations = factors_annotations,
    )
    configuration = default_block_programs_configuration(
        configuration;
        min_significant_coefficient = min_significant_coefficient,
        max_significant_coefficient = max_significant_coefficient,
    )
    return Graph(data, configuration)
end

end  # module
