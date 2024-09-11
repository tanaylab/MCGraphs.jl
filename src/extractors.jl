"""
Extract data from a metacells `Daf` for standard graphs.
"""
module Extractors

export default_block_block_configuration
export default_block_programs_configuration
export default_gene_gene_configuration
export default_marker_genes_configuration
export extract_block_block_data
export extract_block_programs_data
export extract_blocks_gene_gene_data
export extract_blocks_marker_genes_data
export extract_metacells_gene_gene_data
export extract_metacells_marker_genes_data
export extract_metacells_marker_genes_data
export extract_metacells_marker_genes_data
export extract_block_programs_data

using Base.Threads
using Base.Unicode
using Clustering
using Daf
using Daf.GenericLogging
using Daf.GenericTypes
using DataFrames
using Distances
using LinearAlgebra
using Metacells
using NamedArrays
using Statistics
using ..Renderers

import Printf
import Metacells.Programs.compute_confidence_log_fraction_of_genes_in_metacells
import Metacells.Programs.gene_distance

GENE_FRACTION_FORMAT = Printf.Format("%.1e")

function format_gene_fraction(gene_fraction::AbstractFloat)::AbstractString  # untested
    return Printf.format(GENE_FRACTION_FORMAT, gene_fraction)
end

"""
    extract_metacells_gene_gene_data(
        daf::DafReader;
        x_gene::AbstractString,
        y_gene::AbstractString,
        min_significant_gene_UMIs::Integer = $(DEFAULT.min_significant_gene_UMIs),
        colors_query::Maybe{QueryString} = $(DEFAULT.colors_query),
        colors_title::Maybe{AbstractString} = $(DEFAULT.colors_title),
        hovers_columns::Maybe{FrameColumns} = $(DEFAULT.hovers_columns),
    )::PointsGraphData

Extract the data for a metacells gene-gene graph from the `daf` data. The X coordinate of each point is the fraction of the
`x_gene` and the Y coordinate of each gene is the fraction of the `y_gene` in each of the metacells.

We ignore genes that don't have at least `min_significant_gene_UMIs` between both entries.

If a `colors_query` is specified, it can be a suffix of a query that fetches a value for each metacell, or a full query that
groups by metacells. By default we color by the type of the metacell. The `colors_title` is used for the legend.

For each metacell point, the hover will include the `hovers_columns` per-metacell data.

$(CONTRACT)
"""
@logged @computation Contract(
    is_relaxed = true,
    axes = [gene_axis(RequiredInput), metacell_axis(RequiredInput)],
    data = [
        metacell_total_UMIs_vector(RequiredInput),
        gene_metacell_fraction_matrix(RequiredInput),
        gene_metacell_total_UMIs_matrix(RequiredInput),
    ],
) function extract_metacells_gene_gene_data(  # untested
    daf::DafReader;
    x_gene::AbstractString,
    y_gene::AbstractString,
    min_significant_gene_UMIs::Integer = MIN_SIGNIFICANT_GENE_UMIS,
    colors_query::Maybe{QueryString} = ": type",
    colors_title::Maybe{AbstractString} = "Type",
    hovers_columns::Maybe{FrameColumns} = ["type" => "="],
)::PointsGraphData
    return extract_gene_gene_data(
        daf;
        axis_name = "metacell",
        x_gene = x_gene,
        y_gene = y_gene,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        colors_query = colors_query,
        colors_title = colors_title,
        hovers_columns = hovers_columns,
    )
end

"""
    extract_blocks_gene_gene_data(
        daf::DafReader;
        x_gene::AbstractString,
        y_gene::AbstractString,
        min_significant_gene_UMIs::Integer = $(DEFAULT.min_significant_gene_UMIs),
        colors_query::Maybe{QueryString} = $(DEFAULT.colors_query),
        colors_title::Maybe{AbstractString} = $(DEFAULT.colors_title),
        hovers_columns::Maybe{FrameColumns} = $(DEFAULT.hovers_columns),
    )::PointsGraphData

Extract the data for a blocks gene-gene graph from the `daf` data. The X coordinate of each point is the fraction of the
`x_gene` and the Y coordinate of each gene is the fraction of the `y_gene` in each of the blocks.

We ignore genes that don't have at least `min_significant_gene_UMIs` between both entries.

If a `colors_query` is specified, it can be a suffix of a query that fetches a value for each block, or a full query
that groups by blocks. For each block point, the hover will include the `hovers_columns` per-block data, if any.

$(CONTRACT)
"""
@logged @computation Contract(
    is_relaxed = true,
    axes = [gene_axis(RequiredInput), block_axis(RequiredInput)],
    data = [
        block_total_UMIs_vector(RequiredInput),
        gene_block_fraction_matrix(RequiredInput),
        gene_block_total_UMIs_matrix(RequiredInput),
    ],
) function extract_blocks_gene_gene_data(  # untested
    daf::DafReader;
    x_gene::AbstractString,
    y_gene::AbstractString,
    min_significant_gene_UMIs::Integer = MIN_SIGNIFICANT_GENE_UMIS,
    colors_query::Maybe{QueryString} = nothing,
    colors_title::Maybe{AbstractString} = nothing,
    hovers_columns::Maybe{FrameColumns} = nothing,
)::PointsGraphData
    return extract_gene_gene_data(
        daf;
        axis_name = "block",
        x_gene = x_gene,
        y_gene = y_gene,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        colors_query = colors_query,
        colors_title = colors_title,
        hovers_columns = hovers_columns,
    )
end

function extract_gene_gene_data(  # untested
    daf::DafReader;
    axis_name::AbstractString,
    x_gene::AbstractString,
    y_gene::AbstractString,
    min_significant_gene_UMIs::Integer,
    colors_query::Maybe{QueryString},
    colors_title::Maybe{AbstractString},
    hovers_columns::Maybe{FrameColumns},
)::PointsGraphData
    fractions_of_x_gene = get_query(daf, Axis(axis_name) |> Axis("gene") |> IsEqual(x_gene) |> Lookup("fraction"))
    fractions_of_y_gene = get_query(daf, Axis(axis_name) |> Axis("gene") |> IsEqual(y_gene) |> Lookup("fraction"))
    @assert names(fractions_of_x_gene, 1) == names(fractions_of_y_gene, 1)

    total_UMIs_of_x_gene = get_query(daf, Axis(axis_name) |> Axis("gene") |> IsEqual(x_gene) |> Lookup("total_UMIs"))
    total_UMIs_of_y_gene = get_query(daf, Axis(axis_name) |> Axis("gene") |> IsEqual(y_gene) |> Lookup("total_UMIs"))
    @assert names(total_UMIs_of_x_gene, 1) == names(fractions_of_x_gene, 1)
    @assert names(total_UMIs_of_x_gene, 1) == names(total_UMIs_of_y_gene, 1)

    total_umis_of_entries = get_vector(daf, axis_name, "total_UMIs")
    names_of_entries = axis_array(daf, axis_name)
    n_entries = axis_length(daf, axis_name)

    if hovers_columns === nothing
        columns = nothing
    else
        columns = pairs(DataFrames.DataFrameColumns(get_frame(daf, axis_name, hovers_columns)))
    end

    entries_mask = total_UMIs_of_x_gene .+ total_UMIs_of_y_gene .> min_significant_gene_UMIs
    @assert any(entries_mask)
    n_visible_entries = sum(entries_mask)
    @assert n_visible_entries > 0

    visible_entry_index = 0
    hovers = Vector{String}(undef, n_visible_entries)
    for entry_index in 1:n_entries
        if !entries_mask[entry_index]
            continue
        end
        visible_entry_index += 1
        hover = ["$(uppercasefirst(axis_name)): $(names_of_entries[entry_index])"]
        if columns !== nothing
            for (column_name, column_values_of_entries) in columns  # NOJET
                push!(hover, "- $(column_name): $(column_values_of_entries[entry_index])")
            end
        end

        push!(hover, "$(x_gene):")
        push!(hover, "- fraction: $(format_gene_fraction(fractions_of_x_gene[entry_index]))")
        push!(hover, "- total_UMIs: $(total_UMIs_of_x_gene[entry_index]) out of $(total_umis_of_entries[entry_index])")

        push!(hover, "$(y_gene):")
        push!(hover, "- fraction: $(format_gene_fraction(fractions_of_y_gene[entry_index]))")
        push!(hover, "- total_UMIs: $(total_UMIs_of_y_gene[entry_index]) out of $(total_umis_of_entries[entry_index])")

        hovers[visible_entry_index] = join(hover, "<br>")
    end

    if colors_query === nothing
        colors = nothing
    else
        colors = get_query(daf, Axis(axis_name) |> colors_query)
        colors = colors.array[entries_mask]
    end

    return PointsGraphData(;
        figure_title = "$(uppercasefirst(axis_name))s Gene-Gene",
        x_axis_title = x_gene,
        y_axis_title = y_gene,
        points_colors_title = colors_title,
        points_xs = fractions_of_y_gene.array[entries_mask],
        points_ys = fractions_of_x_gene.array[entries_mask],
        points_colors = colors,
        points_hovers = hovers,
    )
end

"""
    default_gene_gene_configuration(
        daf::DafReader,
        configuration = PointsGraphConfiguration();
        [colors_palette_query::Maybe{QueryString} = $(DEFAULT.colors_palette_query),
        gene_fraction_regularization::Maybe{AbstractFloat} = $(DEFAULT.gene_fraction_regularization)]
    )::PointsGraphConfiguration

Return a default configuration for a gene-gene graph. This applies the log scale to the axes, and sets up the color
palette. Will modify `configuration` in-place and return it.
"""
@logged @computation function default_gene_gene_configuration(  # untested
    daf::DafReader,
    configuration = PointsGraphConfiguration();
    colors_palette_query::Maybe{QueryString} = nothing,
    gene_fraction_regularization::AbstractFloat = GENE_FRACTION_REGULARIZATION,
)::PointsGraphConfiguration
    @assert gene_fraction_regularization >= 0
    configuration.x_axis.log_scale = Log10Scale
    configuration.y_axis.log_scale = Log10Scale
    configuration.x_axis.log_regularization = gene_fraction_regularization
    configuration.y_axis.log_regularization = gene_fraction_regularization
    configuration.x_axis.percent = true
    configuration.y_axis.percent = true
    configuration.points.size = 10
    if colors_palette_query !== nothing
        configuration.points.colors_configuration.colors_palette =
            extract_categorical_colors_palette(daf, colors_palette_query)
    end
    return configuration
end

"""
    function extract_block_block_data(
        daf::DafReader;
        x_block::AbstractString,
        y_block::AbstractString,
        [min_significant_gene_UMIs::Integer = $(DEFAULT.min_significant_gene_UMIs),
        max_block_span::Real = $(DEFAULT.max_block_span),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization)],
        fold_confidence::AbstractFloat = $(DEFAULT.fold_confidence),
    )::PointsGraphData

Extract the data for a block-block graph. This shows why two blocks were not merged (or, if given the same block
name twice, why the block was merged).

$(CONTRACT)
"""
@logged @computation Contract(
    axes = [gene_axis(RequiredInput), metacell_axis(RequiredInput)],
    data = [
        metacell_block_vector(RequiredInput),
        metacell_total_UMIs_vector(RequiredInput),
        gene_is_lateral_vector(RequiredInput),
        gene_is_marker_vector(RequiredInput),
        gene_is_transcription_factor_vector(RequiredInput),
        gene_factor_priority_vector(RequiredInput),
        gene_is_global_predictive_factor_vector(RequiredInput),
        gene_divergence_vector(RequiredInput),
        gene_metacell_fraction_matrix(RequiredInput),
        gene_metacell_total_UMIs_matrix(RequiredInput),
    ],
) function extract_block_block_data(  # untested
    daf::DafReader;
    x_block::AbstractString,
    y_block::AbstractString,
    min_significant_gene_UMIs::Integer = function_default(compute_blocks!, :min_significant_gene_UMIs),
    max_block_span::Real = function_default(compute_blocks!, :max_block_span),
    gene_fraction_regularization::AbstractFloat = function_default(compute_blocks!, :gene_fraction_regularization),
    fold_confidence::AbstractFloat = function_default(compute_blocks!, :fold_confidence),
)::PointsGraphData
    @assert gene_fraction_regularization > 0

    names_of_x_metacells,
    total_UMIs_of_x_metacells,
    total_UMIs_of_x_metacells_of_genes,
    fraction_of_x_metacells_of_genes = read_block_block_data(daf, x_block)
    log_decreased_fraction_of_genes_in_x_metacells, log_increased_fraction_of_genes_in_x_metacells =
        compute_confidence_log_fraction_of_genes_in_metacells(;
            gene_fraction_regularization = gene_fraction_regularization,
            fractions_of_genes_in_metacells = transposer(fraction_of_x_metacells_of_genes),
            total_UMIs_of_metacells = total_UMIs_of_x_metacells,
            fold_confidence = fold_confidence,
        )
    log_decreased_fraction_of_x_metacells_of_genes = transposer(log_decreased_fraction_of_genes_in_x_metacells)
    log_increased_fraction_of_x_metacells_of_genes = transposer(log_increased_fraction_of_genes_in_x_metacells)
    @assert all(log_decreased_fraction_of_x_metacells_of_genes .<= log_increased_fraction_of_x_metacells_of_genes)

    is_self_difference = x_block == y_block
    if is_self_difference
        names_of_y_metacells,
        total_UMIs_of_y_metacells,
        total_UMIs_of_y_metacells_of_genes,
        fraction_of_y_metacells_of_genes = names_of_x_metacells,
        total_UMIs_of_x_metacells,
        total_UMIs_of_x_metacells_of_genes,
        fraction_of_x_metacells_of_genes
        log_decreased_fraction_of_y_metacells_of_genes, log_increased_fraction_of_y_metacells_of_genes =
            log_decreased_fraction_of_x_metacells_of_genes, log_increased_fraction_of_x_metacells_of_genes
    else
        names_of_y_metacells,
        total_UMIs_of_y_metacells,
        total_UMIs_of_y_metacells_of_genes,
        fraction_of_y_metacells_of_genes = read_block_block_data(daf, y_block)
        log_decreased_fraction_of_genes_in_y_metacells, log_increased_fraction_of_genes_in_y_metacells =
            compute_confidence_log_fraction_of_genes_in_metacells(;
                gene_fraction_regularization = gene_fraction_regularization,
                fractions_of_genes_in_metacells = transposer(fraction_of_y_metacells_of_genes),
                total_UMIs_of_metacells = total_UMIs_of_y_metacells,
                fold_confidence = fold_confidence,
            )
        log_decreased_fraction_of_y_metacells_of_genes = transposer(log_decreased_fraction_of_genes_in_y_metacells)
        log_increased_fraction_of_y_metacells_of_genes = transposer(log_increased_fraction_of_genes_in_y_metacells)
    end
    @assert all(log_decreased_fraction_of_y_metacells_of_genes .<= log_increased_fraction_of_y_metacells_of_genes)

    divergence_of_genes = get_vector(daf, "gene", "divergence").array

    n_genes = axis_length(daf, "gene")
    mask_of_genes = zeros(Bool, n_genes)
    distance_of_genes = Vector{Float32}(undef, n_genes)
    x_metacell_of_genes = fill("", n_genes)
    y_metacell_of_genes = fill("", n_genes)
    x_total_UMIs_of_genes = Vector{Int32}(undef, n_genes)
    y_total_UMIs_of_genes = Vector{Int32}(undef, n_genes)
    x_total_UMIs_of_metacell_of_genes = Vector{Int32}(undef, n_genes)
    y_total_UMIs_of_metacell_of_genes = Vector{Int32}(undef, n_genes)
    x_fraction_of_genes = Vector{Float32}(undef, n_genes)
    y_fraction_of_genes = Vector{Float32}(undef, n_genes)
    x_confidence_fraction_of_genes = Vector{Float32}(undef, n_genes)
    y_confidence_fraction_of_genes = Vector{Float32}(undef, n_genes)

    @threads for gene_index in 1:n_genes
        distance, x_metacell_index, y_metacell_index = compute_most_different_metacells_of_gene(;
            total_UMIs_of_x_metacells_of_genes = total_UMIs_of_x_metacells_of_genes,
            total_UMIs_of_y_metacells_of_genes = total_UMIs_of_y_metacells_of_genes,
            fraction_of_x_metacells_of_genes = fraction_of_x_metacells_of_genes,
            log_decreased_fraction_of_x_metacells_of_genes = log_decreased_fraction_of_x_metacells_of_genes,
            log_increased_fraction_of_x_metacells_of_genes = log_increased_fraction_of_x_metacells_of_genes,
            fraction_of_y_metacells_of_genes = fraction_of_y_metacells_of_genes,
            log_decreased_fraction_of_y_metacells_of_genes = log_decreased_fraction_of_y_metacells_of_genes,
            log_increased_fraction_of_y_metacells_of_genes = log_increased_fraction_of_y_metacells_of_genes,
            min_significant_gene_UMIs = min_significant_gene_UMIs,
            is_self_difference = is_self_difference,
            gene_index = gene_index,
            divergence_of_gene = divergence_of_genes[gene_index],
            gene_fraction_regularization = gene_fraction_regularization,
        )
        if x_metacell_index !== nothing && y_metacell_index !== nothing
            mask_of_genes[gene_index] = true
            distance_of_genes[gene_index] = distance
            x_metacell_of_genes[gene_index] = names_of_x_metacells[x_metacell_index]
            y_metacell_of_genes[gene_index] = names_of_y_metacells[y_metacell_index]
            x_total_UMIs_of_genes[gene_index] = total_UMIs_of_x_metacells_of_genes[x_metacell_index, gene_index]
            y_total_UMIs_of_genes[gene_index] = total_UMIs_of_y_metacells_of_genes[y_metacell_index, gene_index]
            x_total_UMIs_of_metacell_of_genes[gene_index] = total_UMIs_of_x_metacells[x_metacell_index]
            y_total_UMIs_of_metacell_of_genes[gene_index] = total_UMIs_of_y_metacells[y_metacell_index]
            x_fraction_of_genes[gene_index] = fraction_of_x_metacells_of_genes[x_metacell_index, gene_index]
            y_fraction_of_genes[gene_index] = fraction_of_y_metacells_of_genes[y_metacell_index, gene_index]
            if x_fraction_of_genes[gene_index] < y_fraction_of_genes[gene_index]
                x_confidence_fraction_of_genes[gene_index] =
                    2^log_increased_fraction_of_x_metacells_of_genes[x_metacell_index, gene_index]
                y_confidence_fraction_of_genes[gene_index] =
                    2^log_decreased_fraction_of_y_metacells_of_genes[y_metacell_index, gene_index]
            else
                x_confidence_fraction_of_genes[gene_index] =
                    2^log_decreased_fraction_of_x_metacells_of_genes[x_metacell_index, gene_index]
                y_confidence_fraction_of_genes[gene_index] =
                    2^log_increased_fraction_of_y_metacells_of_genes[y_metacell_index, gene_index]
            end
        end
    end

    is_lateral_of_genes = get_vector(daf, "gene", "is_lateral")
    is_marker_of_genes = get_vector(daf, "gene", "is_marker")
    is_transcription_factor_of_genes = get_vector(daf, "gene", "is_transcription_factor")
    is_global_predictive_factor_of_genes = get_vector(daf, "gene", "is_global_predictive_factor")
    is_candidate_predictive_factor_of_genes = get_vector(daf, "gene", "factor_priority").array .> 0

    n_significant_genes = sum(mask_of_genes)
    @assert n_significant_genes > 0

    points_xs = Vector{Float32}(undef, n_significant_genes * 3)
    points_ys = Vector{Float32}(undef, n_significant_genes * 3)
    points_colors = Vector{AbstractString}(undef, n_significant_genes * 3)
    points_hovers = Vector{AbstractString}(undef, n_significant_genes * 3)
    edges_points = Vector{Tuple{Int, Int}}(undef, n_significant_genes * 2)
    borders_colors = Vector{AbstractString}(undef, n_significant_genes * 3)

    x_n_metacells = length(total_UMIs_of_x_metacells)
    y_n_metacells = length(total_UMIs_of_y_metacells)
    x_axis_title = "$(x_block) ($(x_n_metacells) metacells)"
    y_axis_title = "$(y_block) ($(y_n_metacells) metacells)"

    edge_index = 0
    point_index = 0
    names_of_genes = axis_array(daf, "gene")
    for gene_index in 1:n_genes
        if !mask_of_genes[gene_index]
            continue
        end

        point_index += 1
        points_xs[point_index] = x_fraction_of_genes[gene_index]
        points_ys[point_index] = y_fraction_of_genes[gene_index]

        if is_global_predictive_factor_of_genes[gene_index]
            points_colors[point_index] = "global predictive factors"
        elseif is_candidate_predictive_factor_of_genes[gene_index]
            points_colors[point_index] = "candidate predictive factors"
        elseif is_transcription_factor_of_genes[gene_index]
            points_colors[point_index] = "transcription factors"
        elseif is_lateral_of_genes[gene_index]
            points_colors[point_index] = "lateral genes"
        elseif is_marker_of_genes[gene_index]
            points_colors[point_index] = "marker genes"
        else
            points_colors[point_index] = "other genes"
        end

        if is_self_difference
            x_label, y_label = "$(x_block) low:", "$(x_block) high:"
        else
            x_label, y_label = "$(x_block):", "$(y_block):"
        end

        divergence = divergence_of_genes[gene_index]
        points_hovers[point_index] = join(  # NOJET
            [
                "Gene: $(names_of_genes[gene_index])",
                "distance: $(distance_of_genes[gene_index])",
                "divergence: $(divergence)",
                x_label,
                "- metacell: $(x_metacell_of_genes[gene_index])",
                "- fraction: $(format_gene_fraction(x_fraction_of_genes[gene_index]))",
                "- confident: $(format_gene_fraction(x_confidence_fraction_of_genes[gene_index]))",
                "- total_UMIs: $(x_total_UMIs_of_genes[gene_index]) / $(x_total_UMIs_of_metacell_of_genes[gene_index])",
                y_label,
                "- metacell: $(y_metacell_of_genes[gene_index])",
                "- fraction: $(format_gene_fraction(y_fraction_of_genes[gene_index]))",
                "- confident: $(format_gene_fraction(y_confidence_fraction_of_genes[gene_index]))",
                "- total_UMIs: $(y_total_UMIs_of_genes[gene_index]) / $(y_total_UMIs_of_metacell_of_genes[gene_index])",
            ],
            "<br>",
        )

        borders_colors[point_index] = ""
        if is_global_predictive_factor_of_genes[gene_index]
            if distance_of_genes[gene_index] >= max_block_span
                borders_colors[point_index] = "certificates"
            end

            edge_index += 1
            edges_points[edge_index] = (point_index, point_index + 1)

            point_index += 1
            points_xs[point_index] = x_confidence_fraction_of_genes[gene_index]
            points_ys[point_index] = y_confidence_fraction_of_genes[gene_index]
            points_colors[point_index] = ""
            points_hovers[point_index] = ""
            borders_colors[point_index] = ""

            if divergence > 0
                edge_index += 1
                edges_points[edge_index] = (point_index, point_index + 1)

                point_index += 1
                points_xs[point_index] = x_confidence_fraction_of_genes[gene_index]
                points_ys[point_index] = y_confidence_fraction_of_genes[gene_index]
                if points_ys[point_index] > points_xs[point_index]
                    points_ys[point_index] =
                        points_xs[point_index] * (points_ys[point_index] / points_xs[point_index])^(1 - divergence)
                else
                    points_xs[point_index] =
                        points_ys[point_index] * (points_xs[point_index] / points_ys[point_index])^(1 - divergence)
                end
                points_colors[point_index] = ""
                points_hovers[point_index] = ""
                borders_colors[point_index] = ""
            end
        end
    end

    resize!(points_xs, point_index)
    resize!(points_ys, point_index)
    resize!(points_colors, point_index)
    resize!(points_hovers, point_index)
    resize!(borders_colors, point_index)
    resize!(edges_points, edge_index)

    return PointsGraphData(;
        figure_title = "Blocks Genes Difference",
        x_axis_title = x_axis_title,
        y_axis_title = y_axis_title,
        points_colors_title = "Genes",
        borders_colors_title = "Certificates",
        edges_group_title = "Lines",
        edges_line_title = "Confidence",
        points_xs = points_xs,
        points_ys = points_ys,
        points_colors = points_colors,
        points_hovers = points_hovers,
        borders_colors = borders_colors,
        edges_points = edges_points,
    )
end

function read_block_block_data(  # untested
    daf::DafReader,
    block::AbstractString,
)::Tuple{
    AbstractVector{<:AbstractString},
    AbstractVector{<:Unsigned},
    AbstractMatrix{<:Unsigned},
    AbstractMatrix{<:AbstractFloat},
}
    metacells_query = Axis("metacell") |> And("block") |> IsEqual(block)
    names_of_metacells = get_query(daf, metacells_query |> Lookup("name")).array
    total_UMIs_of_metacells = get_query(daf, metacells_query |> Lookup("total_UMIs")).array
    total_UMIs_of_metacells_of_genes = get_query(daf, metacells_query |> Axis("gene") |> Lookup("total_UMIs")).array
    fraction_of_metacells_of_genes = get_query(daf, metacells_query |> Axis("gene") |> Lookup("fraction")).array
    return names_of_metacells, total_UMIs_of_metacells, total_UMIs_of_metacells_of_genes, fraction_of_metacells_of_genes
end

function compute_most_different_metacells_of_gene(;  # untested
    total_UMIs_of_x_metacells_of_genes::AbstractMatrix{<:Unsigned},
    total_UMIs_of_y_metacells_of_genes::AbstractMatrix{<:Unsigned},
    fraction_of_x_metacells_of_genes::AbstractMatrix{<:AbstractFloat},
    log_decreased_fraction_of_x_metacells_of_genes::AbstractMatrix{<:AbstractFloat},
    log_increased_fraction_of_x_metacells_of_genes::AbstractMatrix{<:AbstractFloat},
    fraction_of_y_metacells_of_genes::AbstractMatrix{<:AbstractFloat},
    log_decreased_fraction_of_y_metacells_of_genes::AbstractMatrix{<:AbstractFloat},
    log_increased_fraction_of_y_metacells_of_genes::AbstractMatrix{<:AbstractFloat},
    min_significant_gene_UMIs::Integer,
    is_self_difference::Bool,
    gene_index::Integer,
    divergence_of_gene::Union{AbstractFloat, Bool},
    gene_fraction_regularization::Real,
)::Tuple{Float32, Maybe{Int}, Maybe{Int}}
    n_genes = size(total_UMIs_of_x_metacells_of_genes, 2)
    n_x_metacells = size(total_UMIs_of_x_metacells_of_genes, 1)
    n_y_metacells = size(total_UMIs_of_y_metacells_of_genes, 1)

    @assert_matrix(total_UMIs_of_x_metacells_of_genes, n_x_metacells, n_genes, Columns)
    @assert_matrix(log_decreased_fraction_of_x_metacells_of_genes, n_x_metacells, n_genes, Columns)
    @assert_matrix(log_increased_fraction_of_x_metacells_of_genes, n_x_metacells, n_genes, Columns)

    @assert require_major_axis(total_UMIs_of_x_metacells_of_genes) == Columns
    @assert require_major_axis(log_decreased_fraction_of_x_metacells_of_genes) == Columns
    @assert require_major_axis(log_increased_fraction_of_x_metacells_of_genes) == Columns

    @assert_matrix(total_UMIs_of_y_metacells_of_genes, n_y_metacells, n_genes, Columns)
    @assert_matrix(log_decreased_fraction_of_y_metacells_of_genes, n_y_metacells, n_genes, Columns)
    @assert_matrix(log_increased_fraction_of_y_metacells_of_genes, n_y_metacells, n_genes, Columns)

    @assert require_major_axis(total_UMIs_of_y_metacells_of_genes) == Columns
    @assert require_major_axis(log_decreased_fraction_of_y_metacells_of_genes) == Columns
    @assert require_major_axis(log_increased_fraction_of_y_metacells_of_genes) == Columns

    most_x_metacell_index = most_y_metacell_index = nothing
    most_distance = 0
    for x_metacell_index in 1:n_x_metacells
        for y_metacell_index in 1:n_y_metacells
            if total_UMIs_of_x_metacells_of_genes[x_metacell_index, gene_index] +
               total_UMIs_of_y_metacells_of_genes[y_metacell_index, gene_index] >= min_significant_gene_UMIs
                distance =
                    fraction_of_y_metacells_of_genes[y_metacell_index] -
                    fraction_of_x_metacells_of_genes[x_metacell_index]
                if is_self_difference && distance < 0
                    continue
                end
                distance = gene_distance(  # NOJET
                    min_significant_gene_UMIs,
                    total_UMIs_of_x_metacells_of_genes[x_metacell_index, gene_index],
                    log_decreased_fraction_of_x_metacells_of_genes[x_metacell_index, gene_index],
                    log_increased_fraction_of_x_metacells_of_genes[x_metacell_index, gene_index],
                    total_UMIs_of_y_metacells_of_genes[y_metacell_index, gene_index],
                    log_decreased_fraction_of_y_metacells_of_genes[y_metacell_index, gene_index],
                    log_increased_fraction_of_y_metacells_of_genes[y_metacell_index, gene_index],
                    divergence_of_gene,
                )
                if distance > most_distance
                    most_x_metacell_index = x_metacell_index
                    most_y_metacell_index = y_metacell_index
                    most_distance = distance
                end
            end
        end
    end

    if most_x_metacell_index !== nothing && most_distance == 0
        for x_metacell_index in 1:n_x_metacells
            for y_metacell_index in 1:n_y_metacells
                if total_UMIs_of_x_metacells_of_genes[x_metacell_index, gene_index] +
                   total_UMIs_of_y_metacells_of_genes[y_metacell_index, gene_index] >= min_significant_gene_UMIs
                    distance =
                        log2(fraction_of_y_metacells_of_genes[y_metacell_index] .+ gene_fraction_regularization) -
                        log2(fraction_of_x_metacells_of_genes[x_metacell_index] .+ gene_fraction_regularization)
                    if !is_self_difference
                        distance = abs(distance)
                    end
                    if distance > most_distance
                        most_distance = distance
                        most_x_metacell_index = x_metacell_index
                        most_y_metacell_index = y_metacell_index
                    end
                end
            end
        end
        most_distance = 0
    end

    return most_distance, most_x_metacell_index, most_y_metacell_index
end

"""
    default_block_block_configuration(
        [configuration::PointsGraphConfiguration = PointsGraphConfiguration()];
        [max_block_span::Real = $(DEFAULT.max_block_span),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization)],
    )::PointsGraphConfiguration

Return a default configuration for a block-block graph. Will modify `configuration` in-place and return it.
"""
@logged @computation function default_block_block_configuration(  # untested
    configuration::PointsGraphConfiguration = PointsGraphConfiguration();
    max_block_span::Real = function_default(compute_blocks!, :max_block_span),
    gene_fraction_regularization::AbstractFloat = function_default(compute_blocks!, :gene_fraction_regularization),
)::PointsGraphConfiguration
    @assert gene_fraction_regularization === nothing || gene_fraction_regularization >= 0
    configuration.diagonal_bands.low.offset = 2^Float32(-max_block_span)
    configuration.diagonal_bands.middle.offset = 1.0
    configuration.diagonal_bands.high.offset = 2^Float32(max_block_span)
    configuration.x_axis.log_scale = Log10Scale
    configuration.y_axis.log_scale = Log10Scale
    configuration.x_axis.percent = true
    configuration.y_axis.percent = true
    configuration.x_axis.log_regularization = gene_fraction_regularization
    configuration.y_axis.log_regularization = gene_fraction_regularization
    configuration.edges_over_points = false
    configuration.edges.colors_configuration.show_legend = true
    configuration.points.colors_configuration.show_legend = true
    configuration.borders.colors_configuration.show_legend = true
    configuration.points.colors_configuration.colors_palette = [
        "other genes" => "lightgrey",
        "lateral genes" => "grey",
        "marker genes" => "seagreen",
        "transcription factors" => "royalblue",
        "candidate predictive factors" => "darkturquoise",
        "global predictive factors" => "salmon",
    ]
    configuration.borders.colors_configuration.colors_palette = ["certificates" => "mediumpurple"]
    return configuration
end

"""
    function extract_metacells_marker_genes_data(
        daf::DafReader;
        [forced_genes::Maybe{AbstractVector{<:AbstractString}} = $(DEFAULT.forced_genes),
        max_marker_genes::Integer = $(DEFAULT.max_marker_genes),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization),
        metacells_annotations::Maybe{AbstractVector{AnnotationData}} = $(DEFAULT.metacells_annotations),
        metacells_group_by::Maybe{Union{QueryString, AbstractVector}} = $(DEFAULT.metacells_group_by)]
        genes_annotations::Maybe{Maybe{AbstractVector{AnnotationData}} = $(DEFAULT.genes_annotations),
        forced_genes_title::Maybe{AbstractString} = $(DEFAULT.forced_genes_title),
        forced_genes_colors_palette::Maybe{AbstractString} = $(DEFAULT.forced_genes_colors_palette),
    )::HeatmapGraphData

Extract the data for a metacells marker genes graph. This shows the genes that most distinguish between metacells. The
displayed values are the fold factors between the gene expression levels (fractions) and the median of the gene
expression levels in the metacells.

If `forced_genes` is specified, these genes will always appear in the graph. This list is supplemented with the
additional genes to show at most `max_marker_genes`, considering only `is_marker` genes. A number of strongest genes is
chosen from each profile, such that the total number of these genes together with the `forced_genes` is at most
`max_marker_genes`.

The optional `metacells_annotations` and/or `genes_annotations` can specify queries for the values, hovers and/or colors
palette, which will be fetched from the `daf` data set. By default, numeric values are colored automatically;
categorical (string) annotations, are expected to contain valid color names. If the color palette is a simple name, it
is assumed to be the name of one of the standard [`NAMED_COLOR_PALETTES`](@ref), which match the standard [Plotly
palette](https://plotly.com/python/builtin-colorscales/).

The metacells and the genes will be reordered using Hclust.

If `metacells_group_by` is specified, it should be either a vector of one value per metacell, or a query returning such
a vector. The metacells will be further reordered so that each value is continuous.

If `forced_gene_title` is specified, and any `forced_genes` were specified, then this is added as a gene annotation with
that name, using the `forced_genes_colors_palette`.

TODOX

$(CONTRACT)
"""
@logged @computation Contract(
    is_relaxed = true,
    axes = [gene_axis(RequiredInput), metacell_axis(RequiredInput)],
    data = [
        gene_is_marker_vector(RequiredInput),
        gene_divergence_vector(RequiredInput),
        gene_metacell_fraction_matrix(RequiredInput),
    ],
) function extract_metacells_marker_genes_data(  # untested
    daf::DafReader;
    forced_genes::Maybe{AbstractVector{<:AbstractString}} = nothing,
    max_marker_genes::Integer = 100,
    gene_fraction_regularization::AbstractFloat = GENE_FRACTION_REGULARIZATION,
    metacells_annotations::Maybe{AbstractVector{<:AnnotationData}} = nothing,
    metacells_group_by::Maybe{Union{QueryString, AbstractVector}} = nothing,
    genes_annotations::Maybe{AbstractVector{<:AnnotationData}} = nothing,
    forced_genes_title::Maybe{AbstractString} = nothing,
    forced_genes_colors_palette::Maybe{AbstractString} = nothing,
)::HeatmapGraphData
    return extract_profiles_marker_genes_data(
        daf;
        forced_genes = forced_genes,
        max_marker_genes = max_marker_genes,
        gene_fraction_regularization = gene_fraction_regularization,
        profiles_axis = "metacell",
        profiles_annotations = metacells_annotations,
        profiles_group_by = metacells_group_by,
        genes_annotations = genes_annotations,
        forced_genes_title = forced_genes_title,
        forced_genes_colors_palette = forced_genes_colors_palette,
    )
end

"""
    function extract_blocks_marker_genes_data(
        daf::DafReader;
        [forced_genes::Maybe{AbstractVector{<:AbstractString}} = $(DEFAULT.forced_genes),
        max_marker_genes::Integer = $(DEFAULT.max_marker_genes),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization),
        blocks_annotations::Maybe{AbstractVector{<:AnnotationData}} = $(DEFAULT.blocks_annotations),
        blocks_group_by::Maybe{Union{QueryString, AbstractVector}} = $(DEFAULT.blocks_group_by)]
        genes_annotations::Maybe{AbstractVector{<:AnnotationData}} = $(DEFAULT.genes_annotations),
        forced_genes_title::Maybe{AbstractString} = $(DEFAULT.forced_genes_title),
        forced_genes_colors_palette::Maybe{AbstractString} = $(DEFAULT.forced_genes_colors_palette),
    )::HeatmapGraphData

Similar to [`extract_metacells_marker_genes_data`](@ref), but extract data for blocks rather than metacells.
"""
@logged @computation Contract(
    is_relaxed = true,
    axes = [gene_axis(RequiredInput), block_axis(RequiredInput)],
    data = [
        gene_is_marker_vector(RequiredInput),
        gene_divergence_vector(RequiredInput),
        gene_block_fraction_matrix(RequiredInput),
    ],
) function extract_blocks_marker_genes_data(  # untested
    daf::DafReader;
    forced_genes::Maybe{AbstractVector{<:AbstractString}} = nothing,
    max_marker_genes::Integer = 100,
    gene_fraction_regularization::AbstractFloat = function_default(compute_blocks!, :gene_fraction_regularization),
    blocks_annotations::Maybe{AbstractVector{<:AnnotationData}} = nothing,
    blocks_group_by::Maybe{Union{QueryString, AbstractVector}} = nothing,
    genes_annotations::Maybe{AbstractVector{<:AnnotationData}} = nothing,
    forced_genes_title::Maybe{AbstractString} = nothing,
    forced_genes_colors_palette::Maybe{AbstractString} = nothing,
)::HeatmapGraphData
    return extract_profiles_marker_genes_data(
        daf;
        forced_genes = forced_genes,
        max_marker_genes = max_marker_genes,
        gene_fraction_regularization = gene_fraction_regularization,
        profiles_axis = "block",
        profiles_annotations = blocks_annotations,
        profiles_group_by = blocks_group_by,
        genes_annotations = genes_annotations,
        forced_genes_title = forced_genes_title,
        forced_genes_colors_palette = forced_genes_colors_palette,
    )
end

function extract_profiles_marker_genes_data(  # untested
    daf::DafReader;
    forced_genes::Maybe{AbstractVector{<:AbstractString}},
    max_marker_genes::Integer,
    gene_fraction_regularization::AbstractFloat,
    profiles_axis::AbstractString,
    profiles_annotations::Maybe{AbstractVector{<:AnnotationData}},
    profiles_group_by::Maybe{Union{QueryString, AbstractVector}},
    genes_annotations::Maybe{AbstractVector{<:AnnotationData}},
    forced_genes_title::Maybe{AbstractString},
    forced_genes_colors_palette::Maybe{AbstractString},
)::HeatmapGraphData
    @assert max_marker_genes > 0

    power_of_selected_genes_of_profiles,
    names_of_selected_genes,
    indices_of_selected_genes,
    mask_of_forced_selected_genes = compute_marker_genes(
        daf;
        profiles_axis = profiles_axis,
        forced_genes = forced_genes,
        max_marker_genes = max_marker_genes,
        gene_fraction_regularization = gene_fraction_regularization,
    )

    columns_annotations = expand_annotations(daf; axis = profiles_axis, annotations = profiles_annotations)
    rows_annotations = expand_annotations(
        daf;
        axis = "gene",
        annotations = genes_annotations,
        selected_indices = indices_of_selected_genes,
    )

    if forced_genes_title !== nothing
        push!(
            rows_annotations,
            AnnotationData(;
                title = forced_genes_title,
                values = mask_of_forced_selected_genes,
                colors_configuration = ColorsConfiguration(;
                    colors_palette = forced_genes_colors_palette,
                    color_axis = AxisConfiguration(; minimum = 0, maximum = 1),
                ),
            ),
        )
    end

    if profiles_group_by === nothing
        group_by_values = nothing
    else
        group_by_values = get_query(daf, Axis(profiles_axis) |> profiles_group_by)
        @assert (
            length(group_by_values) === axis_length(daf, profiles_axis) &&
            all(names(group_by_values, 1) .== axis_array(daf, profiles_axis))
        ) "invalid $(profiles_axis) order query: $(profiles_group_by)"
    end

    columns_order = best_order_of_matrix_columns(power_of_selected_genes_of_profiles, group_by_values)
    rows_order = best_order_of_matrix_columns(transposer(power_of_selected_genes_of_profiles))

    return HeatmapGraphData(;
        figure_title = "$(uppercasefirst(profiles_axis))s Marker Genes",
        x_axis_title = uppercasefirst(profiles_axis),
        y_axis_title = "Gene",
        entries_colors_title = "Fold Factor",
        entries_colors = power_of_selected_genes_of_profiles,
        columns_annotations = columns_annotations,
        columns_order = columns_order,
        rows_names = names_of_selected_genes,
        rows_annotations = rows_annotations,
        rows_order = rows_order,
    )
end

function compute_marker_genes(  # untested
    daf::DafReader;
    profiles_axis::AbstractString,
    forced_genes::Maybe{AbstractVector{<:AbstractString}},
    max_marker_genes::Integer,
    gene_fraction_regularization::AbstractFloat,
)::Tuple{AbstractMatrix{<:Real}, AbstractVector{<:AbstractString}, AbstractVector{<:Integer}, Vector{Bool}}
    if forced_genes === nothing
        forced_genes = AbstractString[]
    else
        forced_genes = copy_array(forced_genes)
    end

    n_genes = axis_length(daf, "gene")
    n_profiles = axis_length(daf, profiles_axis)

    fractions_of_profiles_of_genes = get_matrix(daf, profiles_axis, "gene", "fraction").array
    @assert_matrix(fractions_of_profiles_of_genes, n_profiles, n_genes, Columns)

    divergence_of_genes = get_vector(daf, "gene", "divergence").array

    indices_of_forced_genes = axis_indices(daf, "gene", forced_genes)  # NOJET
    n_forced_genes = length(indices_of_forced_genes)
    mask_of_candidate_genes = copy_array(get_vector(daf, "gene", "is_marker"; default = true).array)

    if length(forced_genes) >= max_marker_genes
        fractions_of_profiles_of_forced_genes = fractions_of_profiles_of_genes[:, indices_of_forced_genes]
        @assert_matrix(fractions_of_profiles_of_forced_genes, n_profiles, n_forced_genes, Columns)

        fractions_of_forced_genes_of_profiles = transposer(fractions_of_profiles_of_forced_genes)
        @assert_matrix(fractions_of_forced_genes_of_profiles, n_forced_genes, n_profiles, Columns)

        median_fractions_of_forced_genes = median(fractions_of_forced_genes_of_profiles; dims = 2)
        @assert length(median_fractions_of_forced_genes) == n_forced_genes

        divergence_of_forced_genes = divergence_of_genes[indices_of_forced_genes]
        power_of_forced_genes_of_profiles =
            log2.(
                (fractions_of_forced_genes_of_profiles .+ gene_fraction_regularization) ./
                (median_fractions_of_forced_genes .+ gene_fraction_regularization)
            ) .* (1 .- divergence_of_forced_genes)
        @assert_matrix(power_of_forced_genes_of_profiles, n_forced_genes, n_profiles, Columns)

        power_of_selected_genes_of_profiles = power_of_forced_genes_of_profiles
        names_of_selected_genes = forced_genes
        indices_of_selected_genes = indices_of_forced_genes
        mask_of_forced_selected_genes = ones(Bool, length(forced_genes))

    else
        mask_of_candidate_genes[indices_of_forced_genes] .= true
        indices_of_candidate_genes = findall(mask_of_candidate_genes)
        names_of_candidate_genes = axis_array(daf, "gene")[indices_of_candidate_genes]
        n_candidate_genes = length(indices_of_candidate_genes)

        mask_of_forced_genes = zeros(Bool, n_genes)
        mask_of_forced_genes[indices_of_forced_genes] .= true
        mask_of_forced_candidate_genes = mask_of_forced_genes[mask_of_candidate_genes]
        @assert sum(mask_of_forced_genes) == length(indices_of_forced_genes)

        fractions_of_profiles_of_candidate_genes = fractions_of_profiles_of_genes[:, indices_of_candidate_genes]
        @assert_matrix(fractions_of_profiles_of_candidate_genes, n_profiles, n_candidate_genes, Columns)

        median_fractions_of_candidate_genes = median(fractions_of_profiles_of_candidate_genes; dims = 1)  # NOJET
        @assert length(median_fractions_of_candidate_genes) == n_candidate_genes

        fractions_of_candidate_genes_of_profiles = transposer(fractions_of_profiles_of_candidate_genes)
        @assert_matrix(fractions_of_candidate_genes_of_profiles, n_candidate_genes, n_profiles, Columns)

        divergence_of_candidate_genes = divergence_of_genes[indices_of_candidate_genes]
        power_of_candidate_genes_of_profiles =
            log2.(
                (fractions_of_candidate_genes_of_profiles .+ gene_fraction_regularization) ./
                transpose(median_fractions_of_candidate_genes .+ gene_fraction_regularization)
            ) .* (1 .- divergence_of_candidate_genes)
        @assert_matrix(power_of_candidate_genes_of_profiles, n_candidate_genes, n_profiles, Columns)

        if n_candidate_genes <= max_marker_genes
            mask_of_selected_candidate_genes = ones(Bool, n_candidate_genes)
        else
            mask_of_selected_candidate_genes = select_strongest_rows(
                power_of_candidate_genes_of_profiles,
                max_marker_genes,
                mask_of_forced_candidate_genes,
            )
        end

        power_of_selected_genes_of_profiles = power_of_candidate_genes_of_profiles[mask_of_selected_candidate_genes, :]
        names_of_selected_genes = names_of_candidate_genes[mask_of_selected_candidate_genes]
        indices_of_selected_genes = axis_indices(daf, "gene", names_of_selected_genes)
        mask_of_forced_selected_genes = mask_of_forced_candidate_genes[mask_of_selected_candidate_genes]
    end

    return (
        power_of_selected_genes_of_profiles,
        names_of_selected_genes,
        indices_of_selected_genes,
        mask_of_forced_selected_genes,
    )
end

function expand_annotations(
    daf::DafReader;
    axis::AbstractString,
    annotations::Maybe{AbstractVector{AnnotationData}},
    selected_indices::Maybe{AbstractVector{<:Integer}} = nothing,
)::Vector{AnnotationData}
    if annotations === nothing
        return nothing
    else
        return [
            expand_annotation(daf; axis = axis, annotation_data = annotation_data, selected_indices = selected_indices)
            for annotation_data in annotations
        ]
    end
end

function expand_annotation(
    daf::DafReader;
    axis::AbstractString,
    annotation_data::AnnotationData,
    selected_indices::Maybe{AbstractVector{<:Integer}} = nothing,
)::AnnotationData
    values = annotation_data.values
    if values isa QueryString
        values = get_query(daf, Axis(axis) |> values)
        if selected_indices !== nothing
            values = values[selected_indices]
        end
    end

    hovers = annotation_data.hovers
    if hovers isa QueryString
        hovers = get_query(daf, Axis(axis) |> hovers)
        if selected_indices !== nothing
            hovers = hovers[selected_indices]
        end
    end

    colors_palette = annotation_data.colors_configuration.colors_palette
    if colors_palette isa AbstractString
        tokens = Daf.Tokens.tokenize(colors_palette, Daf.Queries.QUERY_OPERATORS)
        if length(tokens) > 1
            colors_palette = Query(colors_palette)
        end
    end
    if colors_palette isa Query
        colors = get_query(daf, colors_palette)
        colors_palette = collect(zip(names(colors, 1), colors.array))
    end

    return AnnotationData(;
        title = annotation_data.title,
        values = values,
        hovers = hovers,
        colors_configuration = ColorsConfiguration(;
            show_legend = annotation_data.colors_configuration.show_legend,
            color_axis = annotation_data.colors_configuration.color_axis,
            reverse = annotation_data.colors_configuration.reverse,
            colors_palette = colors_palette,
        ),
    )
end

function annotations_by_frame_columns(
    daf::DafReader;
    axis::AbstractString,
    annotation_columns::FrameColumns,
    color_columns::Maybe{FrameColumns},
    hover_columns::Maybe{FrameColumns},
    selected_indices::Maybe{AbstractVector{<:Integer}} = nothing,
)::Tuple{Vector{String}, Vector{AnnotationData}}
    annotations = Vector{AnnotationData}()

    colors_of_columns =
        Dict{AbstractString, Union{AbstractString, AbstractVector{<:AbstractString}, AbstractVector{<:Real}}}()
    if color_columns !== nothing
        frame_columns = FrameColumn[]
        for column in color_columns
            if column isa AbstractString
                push!(frame_columns, column)
            else
                column_name, colors_query = column
                tokens = Daf.Tokens.tokenize(colors_query, Daf.Queries.QUERY_OPERATORS)
                if length(tokens) == 1
                    colors_of_columns[column_name] = tokens[1].value
                else
                    push!(frame_columns, column)
                end
            end
        end
        if length(frame_columns) > 0
            colors_frame = get_frame(daf, axis, frame_columns)
            for (column_name, column_colors) in pairs(eachcol(colors_frame))
                colors_of_columns[string(column_name)] = column_colors
            end
        end
    end

    hovers_data = Dict{AbstractString, AbstractVector{<:AbstractString}}()
    if hover_columns !== nothing
        hovers_frame = get_frame(daf, axis, hover_columns)
        for (name, values) in pairs(eachcol(hovers_frame))
            hovers_data[string(name)] = vec(values)
        end
    end

    data_frame = get_frame(daf, axis, annotation_columns)
    names = String[]
    for (name, values) in pairs(eachcol(data_frame))
        name = string(name)
        push!(names, name)
        hovers = get(hovers_data, name, nothing)

        if selected_indices !== nothing
            values = values[selected_indices]
        end

        colors = get(colors_of_columns, name, nothing)
        if colors isa AbstractString
            colors_configuration = ColorsConfiguration(; colors_palette = colors)

        elseif colors isa AbstractVector
            if selected_indices !== nothing
                colors = colors[selected_indices]
            end

            if hovers === nothing
                hovers = values
            end
            values = colors
            colors_configuration = ColorsConfiguration()

        else
            colors_configuration = ColorsConfiguration()
        end

        if !(eltype(values) <: AbstractString)
            values = Float32.(values)
        end

        push!(
            annotations,
            AnnotationData(;
                title = name,
                values = values,
                hovers = hovers,
                colors_configuration = colors_configuration,
            ),
        )
    end

    return (names, annotations)
end

function best_order_of_matrix_columns(  # untested
    matrix::AbstractMatrix{<:Real},
    group_by_values::Maybe{AbstractVector} = nothing,
)::Vector{<:Integer}
    n_columns = size(matrix, 2)
    @assert n_columns > 0

    distances_between_columns = pairwise(CorrDist(), matrix; dims = 2)  # NOJET
    @assert_matrix(distances_between_columns, n_columns, n_columns, Columns)
    distances_between_columns = pairwise(CorrDist(), distances_between_columns; dims = 2)
    @assert_matrix(distances_between_columns, n_columns, n_columns, Columns)

    if group_by_values !== nothing
        @assert length(group_by_values) == n_columns
        distances_between_columns .+= (group_by_values .!= permutedims(group_by_values)) .* 2  # NOJET
    end

    clustering = hclust(distances_between_columns; linkage = :ward, branchorder = :optimal)  # NOJET
    return clustering.order
end

function reorder_annotations!(::Nothing, ::Vector{<:Integer})::Nothing  # untested
    return nothing
end

function reorder_annotations!(annotations::Vector{AnnotationData}, order::Vector{<:Integer})::Nothing  # untested
    for (annotation_index, annotation_data) in enumerate(annotations)
        values = annotation_data.values[order]
        hovers = annotation_data.hovers
        if hovers !== nothing
            hovers = hovers[order]
        end
        annotations[annotation_index] = AnnotationData(;
            title = annotation_data.title,
            values = values,
            hovers = hovers,
            colors_configuration = annotation_data.colors_configuration,
        )
    end
    return nothing
end

"""
    default_marker_genes_configuration(
        daf::DafReader,
        [configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
        categories_axes::Maybe{FrameColumns},
        min_significant_fold::Real = $(DEFAULT.min_significant_fold),
        max_significant_fold::Real = $(DEFAULT.max_significant_fold)],
    )::HeatmapGraphConfiguration

Return a default configuration for a markers heatmap graph. Will modify `configuration` in-place and return it.

Genes whose (absolute) fold factor (log base 2 of the ratio between the expression level and the median of the
population) is less than `min_significant_fold` are colored in white. The color scale continues until
`max_significant_fold`.

This creates [`AnnotationsConfiguration`](@ref) for all the listed `categories_axes`. You can also manually tweak the
final configuration to force the use of specific colors for specific numerical categories.
"""
@logged @computation function default_marker_genes_configuration(  # untested
    configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
    min_significant_fold::Real = 0.0,
    max_significant_fold::Real = 3.0,
)::HeatmapGraphConfiguration
    @assert 0 <= min_significant_fold < max_significant_fold
    configuration.figure.margins.left = 100
    configuration.figure.margins.bottom = 100
    configuration.entries.show_legend = true
    configuration.entries.colors_palette = [
        -max_significant_fold * 1.05 => "#0000FF",
        -max_significant_fold - 1e-6 => "#0000FF",
        -max_significant_fold => "#2222B2FF",
        -min_significant_fold => "#ffffff",
        min_significant_fold => "#ffffff",
        max_significant_fold => "#B22222FF",
        max_significant_fold + 1e-6 => "#FF0000",
        max_significant_fold * 1.05 => "#FF0000",
    ]
    configuration.entries.color_axis.minimum = -max_significant_fold * 1.05
    configuration.entries.color_axis.maximum = max_significant_fold * 1.05
    return configuration
end

function extract_categorical_colors_palette(  # untested
    daf::DafReader,
    query::QueryString,
)::AbstractVector{Tuple{<:AbstractString, <:AbstractString}}
    colors = get_query(daf, query)
    @assert colors isa AbstractVector (
        "invalid type: $(typeof(colors))\n" * "of the color palette query: $(query)\n" * "of the daf data: $(daf.name)"
    )
    @assert eltype(colors) <: AbstractString (
        "invalid categorical values type: $(eltype(colors))\n" *
        "of the color palette query: $(query)\n" *
        "of the daf data: $(daf.name)"
    )
    return collect(zip(names(colors, 1), colors.array))
end

"""
TODOX
"""
@logged @computation Contract(
    is_relaxed = true,
    axes = [gene_axis(RequiredInput)],
    data = [gene_block_is_local_predictive_factor_matrix(RequiredInput), gene_factor_priority_vector(RequiredInput)],
) function extract_block_programs_data(  # untested
    daf::DafReader;
    block::AbstractString,
    all_local_predictive_genes::Bool = false,
    max_programs_genes::Integer = 100,
    genes_annotations::Maybe{AbstractVector{AnnotationData}} = nothing,
    factors_annotations::Maybe{AbstractVector{AnnotationData}} = nothing,
)::HeatmapGraphData
    if all_local_predictive_genes
        predictive_factors_mask = daf["/ block / gene : is_local_predictive_factor %> Max"]
    else
        predictive_factors_mask = daf["/ block = $(block) / gene : is_local_predictive_factor"]
    end

    factor_priority_of_genes = get_vector(daf, "gene", "factor_priority").array
    factor_priority_of_factors = factor_priority_of_genes[predictive_factors_mask]
    rows_order = sortperm(factor_priority_of_factors)

    coefficients_of_genes_of_factors = get_matrix(daf, "gene", "gene", "$(block)_program_coefficient")
    coefficients_of_genes_of_factors = coefficients_of_genes_of_factors[:, predictive_factors_mask]
    coefficients_of_genes_of_factors = densify(coefficients_of_genes_of_factors)
    coefficients_of_genes_of_factors[abs.(coefficients_of_genes_of_factors) .< 1e-2] .= 0

    selected_genes_mask = select_strongest_rows(coefficients_of_genes_of_factors, max_programs_genes)
    coefficients_of_genes_of_factors = coefficients_of_genes_of_factors[selected_genes_mask, :]
    coefficients_of_factors_of_genes = transposer(coefficients_of_genes_of_factors)

    rows_annotations = expand_annotations(
        daf;
        axis = "gene",
        annotations = factors_annotations,
        selected_indices = findall(predictive_factors_mask),
    )
    columns_annotations = expand_annotations(
        daf;
        axis = "gene",
        annotations = genes_annotations,
        selected_indices = findall(selected_genes_mask),
    )

    rows_names = names(coefficients_of_factors_of_genes, 1)
    columns_names = names(coefficients_of_factors_of_genes, 2)

    return HeatmapGraphData(;
        figure_title = "$(block) Programs",
        x_axis_title = "Gene",
        y_axis_title = "Factor",
        entries_colors_title = "Coefficient",
        rows_names = rows_names,
        columns_names = columns_names,
        entries_colors = coefficients_of_factors_of_genes.array,
        columns_annotations = columns_annotations,
        rows_annotations = rows_annotations,
        columns_order = sortperm(columns_names),
        rows_order = rows_order,
    )
end

@logged @computation function default_block_programs_configuration(  # untested
    configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
    min_significant_coefficient::Real = 0.0,
    max_significant_coefficient::Real = 0.2,
)::HeatmapGraphConfiguration
    @assert 0 <= min_significant_coefficient < max_significant_coefficient
    configuration.figure.margins.left = 100
    configuration.figure.margins.bottom = 100
    configuration.entries.show_legend = true
    configuration.entries.colors_palette = [
        0 => "#ffffff",
        min_significant_coefficient + 1e-6 => "#ffffff",
        max_significant_coefficient => "#B22222FF",
        max_significant_coefficient + 1e-6 => "#FF0000",
        max_significant_coefficient * 1.05 => "#FF0000",
    ]
    println(configuration.entries.colors_palette)
    configuration.entries.color_axis.minimum = 0
    configuration.entries.color_axis.maximum = max_significant_coefficient * 1.05
    return configuration
end

function select_strongest_rows(
    matrix::AbstractMatrix{<:Real},
    max_selected_rows::Integer,
    forced_rows::Maybe{Union{BitVector, AbstractVector{Bool}}} = nothing,
)::Union{BitVector, AbstractVector{Bool}}
    if forced_rows !== nothing
        n_forced = sum(forced_rows)
        if n_forced >= max_selected_rows
            return forced_rows
        end
    end

    n_rows, n_columns = size(matrix)
    ranks = Matrix{Int32}(undef, n_rows, n_columns)

    @threads for column_index in 1:n_columns
        @views column_vector = matrix[:, column_index]
        column_vector = abs.(column_vector)
        ranks[:, column_index] = sortperm(abs.(column_vector))
        ranks[column_vector .== 0, column_index] .= 0
        if forced_rows !== nothing
            ranks[forced_rows, column_index] .= n_rows + 1
        end
    end

    rank_threshold = n_rows
    candidate_rows_mask = nothing
    while true
        votes_of_rows = vec(sum(ranks .>= rank_threshold; dims = 2))
        @assert_vector(votes_of_rows, n_rows)
        candidate_rows_mask = votes_of_rows .> 0
        if sum(candidate_rows_mask) >= max_selected_rows || rank_threshold == 1
            break
        end
        rank_threshold -= 1
    end

    ranks[ranks .< rank_threshold] .= 0
    votes_of_rows = vec(sum(ranks; dims = 2))
    @assert_vector(votes_of_rows, n_rows)

    threshold_index = partialsortperm(votes_of_rows, max_selected_rows; rev = true)
    votes_threshold = votes_of_rows[threshold_index]
    mask_of_selected_rows = votes_of_rows .>= votes_threshold
    if sum(mask_of_selected_rows) > max_selected_rows
        mask_of_selected_rows = votes_of_rows .> votes_threshold
    end
    @assert sum(mask_of_selected_rows) <= max_selected_rows

    return mask_of_selected_rows
end

end  # module
