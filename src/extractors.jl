"""
Extract data from a metacells `Daf` for standard graphs.
"""
module Extractors

export default_box_box_configuration
export default_gene_gene_configuration
export default_marker_genes_configuration
export extract_box_box_data
export extract_boxes_gene_gene_data
export extract_boxes_marker_genes_data
export extract_metacells_gene_gene_data
export extract_metacells_marker_genes_data

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
import Metacells.Boxes.compute_confidence_log_fraction_of_genes_in_metacells
import Metacells.Boxes.gene_distance

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
        color_query::Maybe{QueryString} = $(DEFAULT.color_query),
        colors_title::Maybe{AbstractString} = $(DEFAULT.colors_title),
        metacells_hovers::Maybe{FrameColumns} = $(DEFAULT.metacells_hovers),
    )::PointsGraphData

Extract the data for a metacells gene-gene graph from the `daf` data. The X coordinate of each point is the fraction of the
`x_gene` and the Y coordinate of each gene is the fraction of the `y_gene` in each of the metacells.

We ignore genes that don't have at least `min_significant_gene_UMIs` between both entries.

If a `colors_query` is specified, it can be a suffix of a query that fetches a value for each metacell, or a full query that
groups by metacells. By default we color by the type of the metacell. The `colors_title` is used for the legend.

For each metacell point, the hover will include the `metacells_hovers` per-metacell data.

$(CONTRACT)
"""
@logged @computation Contract(
    is_relaxed = true,
    axes = [gene_axis(RequiredInput), metacell_axis(RequiredInput), type_axis(RequiredInput)],
    data = [
        metacell_total_UMIs_vector(RequiredInput),
        metacell_type_vector(OptionalInput),
        type_color_vector(OptionalInput),
        gene_metacell_fraction_matrix(RequiredInput),
        gene_metacell_total_UMIs_matrix(RequiredInput),
    ],
) function extract_metacells_gene_gene_data(  # untested
    daf::DafReader;
    x_gene::AbstractString,
    y_gene::AbstractString,
    min_significant_gene_UMIs::Integer = MIN_SIGNIFICANT_GENE_UMIS,
    color_query::Maybe{QueryString} = ": type => color",
    colors_title::Maybe{AbstractString} = "Type",
    metacells_hovers::Maybe{FrameColumns} = ["type" => "="],
)::PointsGraphData
    return extract_gene_gene_data(
        daf;
        axis_name = "metacell",
        x_gene = x_gene,
        y_gene = y_gene,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        color_query = color_query,
        colors_title = colors_title,
        entries_hovers = metacells_hovers,
    )
end

"""
    extract_boxes_gene_gene_data(
        daf::DafReader;
        x_gene::AbstractString,
        y_gene::AbstractString,
        min_significant_gene_UMIs::Integer = $(DEFAULT.min_significant_gene_UMIs),
        color_query::Maybe{QueryString} = $(DEFAULT.color_query),
        colors_title::Maybe{AbstractString} = $(DEFAULT.colors_title),
        boxes_hovers::Maybe{FrameColumns} = $(DEFAULT.boxes_hovers),
    )::PointsGraphData

Extract the data for a boxes gene-gene graph from the `daf` data. The X coordinate of each point is the fraction of the
`x_gene` and the Y coordinate of each gene is the fraction of the `y_gene` in each of the boxes.

We ignore genes that don't have at least `min_significant_gene_UMIs` between both entries.

If a `colors_query` is specified, it can be a suffix of a query that fetches a value for each box, or a full query that
groups by boxes. By default we color by the type of the box. The `colors_title` is used for the legend.

For each box point, the hover will include the `boxes_hovers` per-box data.

$(CONTRACT)
"""
@logged @computation Contract(
    is_relaxed = true,
    axes = [gene_axis(RequiredInput), box_axis(RequiredInput), type_axis(RequiredInput)],
    data = [
        box_total_UMIs_vector(RequiredInput),
        box_type_vector(OptionalInput),
        type_color_vector(OptionalInput),
        gene_box_fraction_matrix(RequiredInput),
        gene_box_total_UMIs_matrix(RequiredInput),
    ],
) function extract_boxes_gene_gene_data(  # untested
    daf::DafReader;
    x_gene::AbstractString,
    y_gene::AbstractString,
    min_significant_gene_UMIs::Integer = MIN_SIGNIFICANT_GENE_UMIS,
    color_query::Maybe{QueryString} = ": type => color",
    colors_title::Maybe{AbstractString} = "Type",
    boxes_hovers::Maybe{FrameColumns} = ["type" => "="],
)::PointsGraphData
    return extract_gene_gene_data(
        daf;
        axis_name = "box",
        x_gene = x_gene,
        y_gene = y_gene,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        color_query = color_query,
        colors_title = colors_title,
        entries_hovers = boxes_hovers,
    )
end

function extract_gene_gene_data(  # untested
    daf::DafReader;
    axis_name::AbstractString,
    x_gene::AbstractString,
    y_gene::AbstractString,
    min_significant_gene_UMIs::Integer,
    color_query::Maybe{QueryString},
    colors_title::Maybe{AbstractString},
    entries_hovers::Maybe{FrameColumns},
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

    if entries_hovers === nothing
        columns_of_entries_hovers = nothing
    else
        columns_of_entries_hovers = pairs(DataFrames.DataFrameColumns(get_frame(daf, axis_name, entries_hovers)))
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
        if columns_of_entries_hovers !== nothing
            for (column_name, column_values_of_entries) in columns_of_entries_hovers  # NOJET
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

    if color_query === nothing
        colors = nothing
    else
        colors = get_query(daf, Axis(axis_name) |> color_query)
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
        [color_query::Maybe{QueryString} = $(DEFAULT.color_query),
        gene_fraction_regularization::Maybe{AbstractFloat} = $(DEFAULT.gene_fraction_regularization)]
    )::PointsGraphConfiguration

Return a default configuration for a gene-gene graph. This applies the log scale to the axes, and sets up the color
palette. Will modify `configuration` in-place and return it.
"""
@logged @computation function default_gene_gene_configuration(  # untested
    daf::DafReader,
    configuration = PointsGraphConfiguration();
    color_query::Maybe{QueryString} = "/ type : color",
    gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
)::PointsGraphConfiguration
    @assert gene_fraction_regularization === nothing || gene_fraction_regularization >= 0
    configuration.x_axis.log_regularization = gene_fraction_regularization
    configuration.y_axis.log_regularization = gene_fraction_regularization
    if color_query !== nothing
        configuration.points.color_palette = extract_categorical_color_palette(daf, color_query)
    end
    return configuration
end

"""
    function extract_box_box_data(
        daf::DafReader;
        x_box::AbstractString,
        y_box::AbstractString,
        [min_significant_gene_UMIs::Integer = $(DEFAULT.min_significant_gene_UMIs),
        max_box_span::AbstractFloat = $(DEFAULT.max_box_span),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization)],
        fold_confidence::AbstractFloat = $(DEFAULT.fold_confidence),
    )::PointsGraphData

Extract the data for a box-box graph. This shows why two boxes were not merged (or, if given the same box
name twice, why the box was merged).

$(CONTRACT)
"""
@logged @computation Contract(
    axes = [
        gene_axis(RequiredInput),
        metacell_axis(RequiredInput),
        box_axis(RequiredInput),
        neighborhood_axis(RequiredInput),
    ],
    data = [
        metacell_box_vector(RequiredInput),
        metacell_total_UMIs_vector(RequiredInput),
        gene_is_lateral_vector(RequiredInput),
        gene_divergence_vector(RequiredInput),
        box_main_neighborhood_vector(RequiredInput),
        neighborhood_span_vector(RequiredInput),
        gene_metacell_fraction_matrix(RequiredInput),
        gene_metacell_total_UMIs_matrix(RequiredInput),
        gene_neighborhood_is_correlated_matrix(RequiredInput),
        box_neighborhood_is_member_matrix(RequiredInput),
    ],
) function extract_box_box_data(  # untested
    daf::DafReader;
    x_box::AbstractString,
    y_box::AbstractString,
    min_significant_gene_UMIs::Integer = MIN_SIGNIFICANT_GENE_UMIS,
    max_box_span::AbstractFloat = function_default(compute_boxes!, :max_box_span),
    gene_fraction_regularization::AbstractFloat = GENE_FRACTION_REGULARIZATION,
    fold_confidence::AbstractFloat = function_default(compute_boxes!, :fold_confidence),
)::PointsGraphData
    @assert gene_fraction_regularization > 0

    names_of_x_metacells,
    total_UMIs_of_x_metacells,
    total_UMIs_of_x_metacells_of_genes,
    fraction_of_x_metacells_of_genes = read_box_box_data(daf, x_box)
    log_decreased_fraction_of_genes_in_x_metacells, log_increased_fraction_of_genes_in_x_metacells =
        compute_confidence_log_fraction_of_genes_in_metacells(;
            gene_fraction_regularization = gene_fraction_regularization,
            fraction_of_genes_in_metacells = transposer(fraction_of_x_metacells_of_genes),
            total_UMIs_of_metacells = total_UMIs_of_x_metacells,
            fold_confidence = fold_confidence,
        )
    log_decreased_fraction_of_x_metacells_of_genes = transposer(log_decreased_fraction_of_genes_in_x_metacells)
    log_increased_fraction_of_x_metacells_of_genes = transposer(log_increased_fraction_of_genes_in_x_metacells)
    @assert all(log_decreased_fraction_of_x_metacells_of_genes .<= log_increased_fraction_of_x_metacells_of_genes)

    is_self_difference = x_box == y_box
    if is_self_difference
        names_of_y_metacells, total_UMIs_of_y_metacells_of_genes, fraction_of_y_metacells_of_genes =
            names_of_x_metacells, total_UMIs_of_x_metacells_of_genes, fraction_of_x_metacells_of_genes
        log_decreased_fraction_of_y_metacells_of_genes, log_increased_fraction_of_y_metacells_of_genes =
            log_decreased_fraction_of_x_metacells_of_genes, log_increased_fraction_of_x_metacells_of_genes
    else
        names_of_y_metacells,
        total_UMIs_of_y_metacells,
        total_UMIs_of_y_metacells_of_genes,
        fraction_of_y_metacells_of_genes = read_box_box_data(daf, y_box)
        log_decreased_fraction_of_genes_in_y_metacells, log_increased_fraction_of_genes_in_y_metacells =
            compute_confidence_log_fraction_of_genes_in_metacells(;
                gene_fraction_regularization = gene_fraction_regularization,
                fraction_of_genes_in_metacells = transposer(fraction_of_y_metacells_of_genes),
                total_UMIs_of_metacells = total_UMIs_of_y_metacells,
                fold_confidence = fold_confidence,
            )
        log_decreased_fraction_of_y_metacells_of_genes = transposer(log_decreased_fraction_of_genes_in_y_metacells)
        log_increased_fraction_of_y_metacells_of_genes = transposer(log_increased_fraction_of_genes_in_y_metacells)
    end
    @assert all(log_decreased_fraction_of_y_metacells_of_genes .<= log_increased_fraction_of_y_metacells_of_genes)

    divergence_of_genes = get_vector(daf, "gene", "divergence")

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
    main_neighborhoods_of_boxes = get_vector(daf, "box", "neighborhood.main")
    x_neighborhood = main_neighborhoods_of_boxes[x_box]
    y_neighborhood = main_neighborhoods_of_boxes[y_box]

    is_correlated_of_x_neighborhood_of_genes =
        get_query(daf, Axis("neighborhood") |> IsEqual(x_neighborhood) |> Axis("gene") |> Lookup("is_correlated"))
    is_correlated_of_y_neighborhood_of_genes =
        get_query(daf, Axis("neighborhood") |> IsEqual(y_neighborhood) |> Axis("gene") |> Lookup("is_correlated"))

    n_significant_genes = sum(mask_of_genes)
    @assert n_significant_genes > 0

    points_xs = Vector{Float32}(undef, n_significant_genes * 3)
    points_ys = Vector{Float32}(undef, n_significant_genes * 3)
    points_colors = Vector{AbstractString}(undef, n_significant_genes * 3)
    points_hovers = Vector{AbstractString}(undef, n_significant_genes * 3)
    edges_points = Vector{Tuple{Int, Int}}(undef, n_significant_genes * 2)
    borders_colors = Vector{AbstractString}(undef, n_significant_genes * 3)

    not_correlated = "uncorrelated for both"
    x_correlated = "correlated for $(x_box)"
    y_correlated = "correlated for $(y_box)"
    xy_correlated = "correlated for both"

    spans_of_neighborhoods = get_vector(daf, "neighborhood", "span")
    is_member_of_boxes_in_neighborhoods = get_matrix(daf, "box", "neighborhood", "is_member")
    if x_neighborhood == y_neighborhood
        neighborhood_span = spans_of_neighborhoods[x_neighborhood]
        x_axis_title = "$(x_box) (main: $(x_neighborhood) span: $(neighborhood_span))"
        y_axis_title = "$(y_box) (main: $(y_neighborhood) span: $(neighborhood_span))"
    else
        x_span = spans_of_neighborhoods[x_neighborhood]
        is_x_box_member_of_main_neighborhood_of_y_box = is_member_of_boxes_in_neighborhoods[x_box, y_neighborhood]
        if is_x_box_member_of_main_neighborhood_of_y_box
            x_is_not = "is"
        else
            x_is_not = "not"
        end
        x_axis_title = "$(x_box) (main: $(x_neighborhood) span: $(x_span), $(x_is_not) in: $(y_neighborhood))"

        y_span = spans_of_neighborhoods[x_neighborhood]

        is_y_box_member_of_main_neighborhood_of_x_box = is_member_of_boxes_in_neighborhoods[y_box, x_neighborhood]
        if is_y_box_member_of_main_neighborhood_of_x_box
            y_is_not = "is"
        else
            y_is_not = "not"
        end
        y_axis_title = "$(y_box) (main: $(y_neighborhood) span: $(y_span), $(y_is_not) in: $(x_neighborhood))"

        neighborhood_span = x_span
    end

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

        if is_lateral_of_genes[gene_index]
            points_colors[point_index] = "lateral"
        elseif is_correlated_of_x_neighborhood_of_genes[gene_index]
            if is_correlated_of_y_neighborhood_of_genes[gene_index]
                points_colors[point_index] = xy_correlated
            else
                points_colors[point_index] = x_correlated
            end
        else
            if is_correlated_of_y_neighborhood_of_genes[gene_index]
                points_colors[point_index] = y_correlated
            else
                points_colors[point_index] = not_correlated
            end
        end

        if is_self_difference
            x_label, y_label = "$(x_box) low:", "$(x_box) high:"
        else
            x_label, y_label = "$(x_box):", "$(y_box):"
        end

        @assert neighborhood_span > max_box_span

        borders_colors[point_index] = "not a certificate"
        if points_colors[point_index] != not_correlated && !is_lateral_of_genes[gene_index]
            if distance_of_genes[gene_index] >= neighborhood_span
                borders_colors[point_index] = "certificate for $(x_box) neighborhood"
            elseif distance_of_genes[gene_index] >= max_box_span
                borders_colors[point_index] = "certificate for $(x_box) box"
            end
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

    resize!(points_xs, point_index)
    resize!(points_ys, point_index)
    resize!(points_colors, point_index)
    resize!(points_hovers, point_index)
    resize!(borders_colors, point_index)
    resize!(edges_points, edge_index)

    return PointsGraphData(;
        figure_title = "Boxes Genes Difference",
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

function read_box_box_data(  # untested
    daf::DafReader,
    box::AbstractString,
)::Tuple{
    AbstractVector{<:AbstractString},
    AbstractVector{<:Unsigned},
    AbstractMatrix{<:Unsigned},
    AbstractMatrix{<:AbstractFloat},
}
    metacells_query = Axis("metacell") |> And("box") |> IsEqual(box)
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

    @assert size(total_UMIs_of_x_metacells_of_genes) == (n_x_metacells, n_genes)
    @assert size(log_decreased_fraction_of_x_metacells_of_genes) == (n_x_metacells, n_genes)
    @assert size(log_increased_fraction_of_x_metacells_of_genes) == (n_x_metacells, n_genes)

    @assert require_major_axis(total_UMIs_of_x_metacells_of_genes) == Columns
    @assert require_major_axis(log_decreased_fraction_of_x_metacells_of_genes) == Columns
    @assert require_major_axis(log_increased_fraction_of_x_metacells_of_genes) == Columns

    @assert size(total_UMIs_of_y_metacells_of_genes) == (n_y_metacells, n_genes)
    @assert size(log_decreased_fraction_of_y_metacells_of_genes) == (n_y_metacells, n_genes)
    @assert size(log_increased_fraction_of_y_metacells_of_genes) == (n_y_metacells, n_genes)

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
    default_box_box_configuration(
        [configuration::PointsGraphConfiguration = PointsGraphConfiguration()];
        x_box::AbstractString,
        y_box::AbstractString,
        x_neighborhood::AbstractString,
        [max_box_span::AbstractFloat = $(DEFAULT.max_box_span),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization)],
    )::PointsGraphConfiguration

Return a default configuration for a box-box graph. Will modify `configuration` in-place and return it.
"""
@logged @computation function default_box_box_configuration(  # untested
    configuration::PointsGraphConfiguration = PointsGraphConfiguration();
    x_box::AbstractString,
    y_box::AbstractString,
    max_box_span::AbstractFloat = function_default(compute_boxes!, :max_box_span),
    gene_fraction_regularization::AbstractFloat = GENE_FRACTION_REGULARIZATION,
)::PointsGraphConfiguration
    @assert gene_fraction_regularization === nothing || gene_fraction_regularization >= 0
    configuration.diagonal_bands.low.offset = 2^-max_box_span
    configuration.diagonal_bands.middle.offset = 1.0
    configuration.diagonal_bands.high.offset = 2^max_box_span
    configuration.x_axis.log_regularization = gene_fraction_regularization
    configuration.y_axis.log_regularization = gene_fraction_regularization
    configuration.edges_over_points = false
    configuration.edges.show_color_scale = true
    configuration.points.show_color_scale = true
    configuration.borders.show_color_scale = true
    configuration.points.color_palette = [
        ("lateral", "grey"),
        ("uncorrelated for both", "salmon"),
        ("correlated for $(x_box)", "seagreen"),
        ("correlated for $(y_box)", "royalblue"),
        ("correlated for both", "darkturquoise"),
    ]
    configuration.borders.color_palette = [
        ("not a certificate", "lavender"),
        ("certificate for $(x_box) box", "mediumpurple"),
        ("certificate for $(x_box) neighborhood", "mediumorchid"),
    ]
    return configuration
end

"""
    function extract_metacells_marker_genes_data(
        daf::DafReader;
        [gene_names::Maybe{Vector{AbstractString}} = $(DEFAULT.gene_names),
        max_marker_genes::Integer = $(DEFAULT.max_marker_genes),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization),
        type_annotation::Bool = $(DEFAULT.type_annotation),
        expression_annotations::Maybe{FrameColumns} = $(DEFAULT.expression_annotations),
        gene_annotations::Maybe{FrameColumns} = $(DEFAULT.gene_annotations),
        reorder_by_type::Bool = $(DEFAULT.reorder_by_type)]
    )::HeatmapGraphData

Extract the data for a metacells marker genes graph. This shows the genes that most distinguish between metacells. If
set, `type_annotation` is is added based on the type of each metacell. Optional `expression_annotations` and
`gene_annotations` are added as well.

If `gene_names` is specified, these genes will always appear in the graph. This list is supplemented with additional
`is_marker` genes to show at least `min_marker_genes`. A number of strongest such genes is chosen from each profile,
such that the total number of these genes together with the forced `gene_names` is at least `min_marker_genes`.

If `named_gene_annotation` is set, and any `gene_names` were specified, then this is added as a gene annotation called
"named".

The data is clustered to show the structure of both genes and metacells. If `reorder_by_type` is specified, then the
profiles are reordered so that each type is contiguous.

$(CONTRACT)
"""
@logged @computation Contract(
    is_relaxed = true,
    axes = [gene_axis(RequiredInput), metacell_axis(RequiredInput), type_axis(OptionalInput)],
    data = [
        gene_divergence_vector(RequiredInput),
        gene_is_lateral_vector(OptionalInput),
        gene_box_fraction_matrix(RequiredInput),
        box_type_vector(OptionalInput),
        type_color_vector(OptionalInput),
    ],
) function extract_metacells_marker_genes_data(  # untested
    daf::DafReader;
    gene_names::Maybe{Vector{AbstractString}} = nothing,
    max_marker_genes::Integer = 100,
    gene_fraction_regularization::AbstractFloat = GENE_FRACTION_REGULARIZATION,
    type_annotation::Bool = true,
    expression_annotations::Maybe{FrameColumns} = nothing,
    named_gene_annotation::Bool = true,
    gene_annotations::Maybe{FrameColumns} = ["is_lateral", "divergence"],
    reorder_by_type::Bool = true,
)::HeatmapGraphData
    return extract_marker_genes_data(
        daf;
        axis_name = "metacell",
        gene_names = gene_names,
        max_marker_genes = max_marker_genes,
        gene_fraction_regularization = gene_fraction_regularization,
        type_annotation = type_annotation,
        expression_annotations = expression_annotations,
        named_gene_annotation = named_gene_annotation,
        gene_annotations = gene_annotations,
        reorder_by_type = reorder_by_type,
    )
end

"""
    function extract_boxes_marker_genes_data(
        daf::DafReader;
        [gene_names::Maybe{Vector{AbstractString}} = $(DEFAULT.gene_names),
        max_marker_genes::Integer = $(DEFAULT.max_marker_genes),
        gene_fraction_regularization::AbstractFloat = $(DEFAULT.gene_fraction_regularization),
        type_annotation::Bool = $(DEFAULT.type_annotation),
        expression_annotations::Maybe{FrameColumns} = $(DEFAULT.expression_annotations),
        named_gene_annotation::Bool = $(DEFAULT.named_gene_annotation),
        gene_annotations::Maybe{FrameColumns} = $(DEFAULT.gene_annotations),
        reorder_by_type::Bool = $(DEFAULT.reorder_by_type)]
    )::HeatmapGraphData

Extract the data for a boxes marker genes graph. This shows the genes that most distinguish between boxes. If set,
`type_annotation` is is added based on the type of each box. Optional `expression_annotations` and `gene_annotations`
are added as well.

If `gene_names` is specified, these genes will always appear in the graph. This list is supplemented with additional
`is_marker` genes to show at least `min_marker_genes`. A number of strongest such genes is chosen from each profile,
such that the total number of these genes together with the forced `gene_names` is at least `min_marker_genes`.

If `named_gene_annotation` is set, and any `gene_names` were specified, then this is added as a gene annotation called
"named".

The data is clustered to show the structure of both genes and boxes. If `reorder_by_type` is specified, and
`type_property` is not be `nothing`, then the profiles are reordered so that each type is contiguous.

$(CONTRACT)
"""
@logged @computation Contract(
    is_relaxed = true,
    axes = [gene_axis(RequiredInput), box_axis(RequiredInput), type_axis(OptionalInput)],
    data = [
        gene_divergence_vector(RequiredInput),
        gene_is_lateral_vector(OptionalInput),
        gene_box_fraction_matrix(RequiredInput),
        box_type_vector(OptionalInput),
        type_color_vector(OptionalInput),
    ],
) function extract_boxes_marker_genes_data(  # untested
    daf::DafReader;
    gene_names::Maybe{Vector{AbstractString}} = nothing,
    max_marker_genes::Integer = 100,
    gene_fraction_regularization::AbstractFloat = GENE_FRACTION_REGULARIZATION,
    type_annotation::Bool = true,
    expression_annotations::Maybe{FrameColumns} = nothing,
    named_gene_annotation::Bool = true,
    gene_annotations::Maybe{FrameColumns} = ["is_lateral", "divergence"],
    reorder_by_type::Bool = true,
)::HeatmapGraphData
    return extract_marker_genes_data(
        daf;
        axis_name = "box",
        gene_names = gene_names,
        max_marker_genes = max_marker_genes,
        gene_fraction_regularization = gene_fraction_regularization,
        type_annotation = type_annotation,
        expression_annotations = expression_annotations,
        named_gene_annotation = named_gene_annotation,
        gene_annotations = gene_annotations,
        reorder_by_type = reorder_by_type,
    )
end

function extract_marker_genes_data(  # untested
    daf::DafReader;
    axis_name::AbstractString,
    gene_names::Maybe{Vector{AbstractString}},
    max_marker_genes::Integer,
    gene_fraction_regularization::AbstractFloat,
    type_annotation::Bool,
    expression_annotations::Maybe{FrameColumns},
    named_gene_annotation::Bool,
    gene_annotations::Maybe{FrameColumns},
    reorder_by_type::Bool,
)::HeatmapGraphData
    @assert max_marker_genes > 0

    power_of_selected_genes_of_profiles,
    names_of_selected_genes,
    indices_of_selected_genes,
    mask_of_named_selected_genes =
        compute_marker_genes(daf, axis_name, gene_names, max_marker_genes, gene_fraction_regularization)
    columns_annotations = marker_genes_columns_annotations(daf, axis_name, type_annotation, expression_annotations)

    rows_annotations = marker_genes_rows_annotations(  # NOJET
        daf,
        gene_annotations,
        indices_of_selected_genes,
        named_gene_annotation,
        mask_of_named_selected_genes,
    )

    if reorder_by_type
        type_indices_of_profiles = columns_annotations[1].values
        type_of_profiles = get_vector(daf, axis_name, "type")
        type_indices_of_profiles = axis_indices(daf, "type", type_of_profiles.array)
    else
        type_indices_of_profiles = nothing
    end

    order_of_profiles = reorder_matrix_columns(power_of_selected_genes_of_profiles, type_indices_of_profiles)
    order_of_genes = reorder_matrix_columns(transposer(power_of_selected_genes_of_profiles))

    power_of_selected_genes_of_profiles = power_of_selected_genes_of_profiles[order_of_genes, order_of_profiles]
    reorder_annotations!(columns_annotations, order_of_profiles)
    reorder_annotations!(rows_annotations, order_of_genes)  # NOJET

    return HeatmapGraphData(;
        figure_title = "$(uppercasefirst(axis_name))s Marker Genes",
        x_axis_title = uppercasefirst(axis_name),
        y_axis_title = "Genes",
        entries_colors_title = "Fold Factor",
        rows_names = names_of_selected_genes,
        entries_colors = power_of_selected_genes_of_profiles,
        columns_annotations = columns_annotations,
        rows_annotations = rows_annotations,
    )
end

function compute_marker_genes(  # untested
    daf::DafReader,
    axis::AbstractString,
    gene_names::Maybe{AbstractVector{<:AbstractString}},
    min_marker_genes::Integer,
    gene_fraction_regularization::AbstractFloat = GENE_FRACTION_REGULARIZATION,
)::Tuple{Matrix{<:Real}, AbstractVector{<:AbstractString}, AbstractVector{<:Integer}, Vector{Bool}}
    if gene_names === nothing
        gene_names = AbstractString[]
    else
        gene_names = copy_array(gene_names)
    end

    n_genes = axis_length(daf, "gene")
    n_profiles = axis_length(daf, axis)

    fractions_of_profiles_of_genes = get_matrix(daf, axis, "gene", "fraction").array
    @assert size(fractions_of_profiles_of_genes) == (n_profiles, n_genes)

    divergence_of_genes = get_vector(daf, "gene", "divergence")

    indices_of_named_genes = axis_indices(daf, "gene", gene_names)  # NOJET
    n_named_genes = length(indices_of_named_genes)

    if length(gene_names) >= min_marker_genes
        fractions_of_profiles_of_named_genes = fractions_of_profiles_of_genes[:, indices_of_named_genes]
        @assert size(fractions_of_profiles_of_genes) == (n_profiles, n_named_genes)

        fractions_of_named_genes_of_profiles = transposer(fractions_of_profiles_of_named_genes)
        @assert size(fractions_of_named_genes_of_profiles) == (n_named_genes, n_profiles)

        median_fractions_of_named_genes = median(fractions_of_named_genes_of_profiles; dims = 2)
        @assert length(median_fractions_of_named_genes) == n_named_genes

        divergence_of_named_genes = divergence_of_genes[indices_of_named_genes]
        power_of_named_genes_of_profiles =
            log2.(
                (fractions_of_named_genes_of_profiles .+ gene_fraction_regularization) ./
                transpose(median_fractions_of_named_genes .+ gene_fraction_regularization)
            ) .* (1 .- transpose(divergence_of_named_genes))
        @assert size(power_of_named_genes_of_profiles) == (n_named_genes, n_profiles)

        power_of_selected_genes_of_profiles = power_of_named_genes_of_profiles
        names_of_selected_genes = gene_names
        indices_of_selected_genes = indices_of_named_genes
        mask_of_named_selected_genes = ones(Bool, length(gene_names))
    else
        mask_of_candidate_genes = copy_array(get_vector(daf, "gene", "is_marker").array)
        mask_of_candidate_genes[indices_of_named_genes] .= true
        indices_of_candidate_genes = findall(mask_of_candidate_genes)
        names_of_candidate_genes = axis_array(daf, "gene")[indices_of_candidate_genes]
        n_candidate_genes = length(indices_of_candidate_genes)

        fractions_of_profiles_of_candidate_genes = fractions_of_profiles_of_genes[:, indices_of_candidate_genes]
        @assert size(fractions_of_profiles_of_candidate_genes) == (n_profiles, n_candidate_genes)

        median_fractions_of_candidate_genes = median(fractions_of_profiles_of_candidate_genes; dims = 1)  # NOJET
        @assert length(median_fractions_of_candidate_genes) == n_candidate_genes

        fractions_of_candidate_genes_of_profiles = transposer(fractions_of_profiles_of_candidate_genes)
        @assert size(fractions_of_candidate_genes_of_profiles) == (n_candidate_genes, n_profiles)

        divergence_of_candidate_genes = divergence_of_genes[indices_of_candidate_genes]
        power_of_candidate_genes_of_profiles =
            log2.(
                (fractions_of_candidate_genes_of_profiles .+ gene_fraction_regularization) ./
                transpose(median_fractions_of_candidate_genes .+ gene_fraction_regularization)
            ) .* (1 .- divergence_of_candidate_genes)
        @assert size(power_of_candidate_genes_of_profiles) == (n_candidate_genes, n_profiles)
        if n_candidate_genes <= min_marker_genes
            selected_genes_mask = ones(Bool, n_candidate_genes)
        else
            rank_of_candidate_genes_of_profiles = Matrix{Int32}(undef, n_candidate_genes, n_profiles)
            @threads for profile_index in 1:n_profiles
                @views power_of_candidate_genes_of_profile = power_of_candidate_genes_of_profiles[:, profile_index]
                rank_of_candidate_genes_of_profiles[:, profile_index] =
                    sortperm(abs.(power_of_candidate_genes_of_profile); rev = true)
                rank_of_candidate_genes_of_profiles[indices_of_named_genes, profile_index] .= 0
            end

            threshold = 1
            votes_of_candidate_genes = nothing
            while true
                votes_of_candidate_genes = vec(sum(rank_of_candidate_genes_of_profiles .<= threshold; dims = 2))
                @assert length(votes_of_candidate_genes) == n_candidate_genes
                if sum(votes_of_candidate_genes .> 0) >= min_marker_genes
                    break
                end
                threshold += 1
            end
            order_of_candidate_genes = sortperm(votes_of_candidate_genes; rev = true)
            selected_genes_mask = zeros(Bool, n_candidate_genes)
            selected_genes_mask[order_of_candidate_genes[1:min_marker_genes]] .= true
        end

        power_of_selected_genes_of_profiles = power_of_candidate_genes_of_profiles[selected_genes_mask, :]
        names_of_selected_genes = names_of_candidate_genes[selected_genes_mask]
        indices_of_selected_genes = axis_indices(daf, "gene", names_of_selected_genes)
        gene_names_set = Set(gene_names)
        mask_of_named_selected_genes = [gene_name in gene_names_set for gene_name in names_of_selected_genes]
    end

    return (
        power_of_selected_genes_of_profiles,
        names_of_selected_genes,
        indices_of_selected_genes,
        mask_of_named_selected_genes,
    )
end

function marker_genes_columns_annotations(::DafReader, ::AbstractString, ::Nothing, ::Nothing)::Nothing  # untested
    return nothing
end

function marker_genes_columns_annotations(  # untested
    daf::DafReader,
    axis::AbstractString,
    type_annotation::Bool,
    expression_annotations::Maybe{FrameColumns},
)::Maybe{Vector{AnnotationsData}}
    annotations = AnnotationsData[]
    if type_annotation
        type_of_profiles = get_vector(daf, axis, "type")
        push!(
            annotations,
            AnnotationsData(;
                name = "type",
                title = "type",
                values = axis_indices(daf, "type", type_of_profiles.array),
                hovers = [
                    "$(name): $(type)" for (name, type) in zip(names(type_of_profiles, 1), type_of_profiles.array)
                ],
            ),
        )
    end
    if expression_annotations !== nothing
        data_frame = get_frame(daf, axis, expression_annotations)
        for (name, values) in pairs(eachcol(data_frame))
            push!(annotations, AnnotationsData(; title = string(name), values = Float32.(values)))
        end
    end
    return annotations
end

function marker_genes_rows_annotations(  # untested
    ::DafReader,
    ::Nothing,
    ::AbstractVector{<:Integer},
    ::Bool,
    ::Vector{Bool},
)::Nothing
    return nothing
end

function marker_cells_rows_annotations(  # untested
    daf::DafReader,
    gene_annotations::FrameColumns,
    indices_of_selected_genes::AbstractVector{<:Integer},
    named_gene_annotation::Bool,
    mask_of_named_selected_genes::Vector{Bool},
)::Vector{AnnotationsData}
    annotations = AnnotationsData[]
    if named_gene_annotation
        push!(annotations, AnnotationsData(; title = "is_named", values = mask_of_named_selected_genes))
    end
    if gene_annotations !== nothing
        data_frame = get_frame(daf, "gene", gene_annotations)
        for (name, values) in pairs(eachcol(data_frame))
            push!(
                annotations,
                AnnotationsData(;
                    title = string(name),
                    name = eltype(values) <: Bool ? "bool" : nothing,
                    values = Float32.(values[indices_of_selected_genes]),
                ),
            )
        end
    end
    return annotations
end

function reorder_matrix_columns(  # untested
    matrix::Matrix{<:Real},
    type_indices_of_columns::Maybe{Vector{<:Integer}} = nothing,
)::Vector{<:Integer}
    _, n_columns = size(matrix)
    distances_between_columns = pairwise(CorrDist(), matrix; dims = 2)
    @assert size(distances_between_columns) == (n_columns, n_columns)
    distances_between_columns = pairwise(CorrDist(), distances_between_columns; dims = 2)
    @assert size(distances_between_columns) == (n_columns, n_columns)

    if type_indices_of_columns !== nothing
        @assert length(type_indices_of_columns) == n_columns
        distances_between_columns .+= (type_indices_of_columns .!= transpose(type_indices_of_columns)) .* 2  # NOJET
    end

    clustering = hclust(distances_between_columns; linkage = :ward, branchorder = :optimal)  # NOJET
    return clustering.order
end

function reorder_annotations(::Nothing, ::Vector{<:Integer})::Nothing  # untested
    return nothing
end

function reorder_annotations!(annotations::Vector{AnnotationsData}, order::Vector{<:Integer})::Nothing  # untested
    for annotations_data in annotations
        annotations_data.values = annotations_data.values[order]
        hovers = annotations_data.hovers
        if hovers !== nothing
            annotations_data.hovers = hovers[order]
        end
    end
    return nothing
end

"""
    default_marker_genes_configuration(
        daf::DafReader,
        [configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
        type_annotation::Bool = $(DEFAULT.type_annotation),
        min_significant_fold::Real = $(DEFAULT.min_significant_fold),
        max_significant_fold::Real = $(DEFAULT.max_significant_fold)],
    )::HeatmapGraphConfiguration

Return a default configuration for a markers heatmap graph. Will modify `configuration` in-place and return it.

Genes whose (absolute) fold factor (log base 2 of the ratio between the expression level and the median of the
population) is less than `min_significant_fold` are colored in white. The color scale continues until
`max_significant_fold`.

If `type_annotation` is set, sets up the color palette for the type annotations.

$(CONTRACT)
"""
@logged @computation Contract(
    #! format: off
    axes = [type_axis(OptionalInput)],
    data = [type_color_vector(OptionalInput)]
    #! format: on
) function default_marker_genes_configuration(  # untested
    daf::DafReader,
    configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
    type_annotation::Bool = true,
    min_significant_fold::Real = 0.5,
    max_significant_fold::Real = 3.0,
)::HeatmapGraphConfiguration
    configuration.figure.margins.left = 100
    configuration.figure.margins.bottom = 100
    configuration.entries.show_color_scale = true
    configuration.entries.color_palette = [
        (-max_significant_fold - 0.05, "#0000FF"),
        (-max_significant_fold - 1e-6, "#0000FF"),
        (-max_significant_fold, "#2222B2FF"),
        (-min_significant_fold, "#ffffff"),
        (min_significant_fold, "#ffffff"),
        (max_significant_fold, "#B22222FF"),
        (max_significant_fold + 1e-6, "#FF0000"),
        (max_significant_fold + 0.05, "#FF0000"),
    ]
    configuration.entries.color_scale.minimum = -max_significant_fold - 0.05
    configuration.entries.color_scale.maximum = max_significant_fold + 0.05
    if type_annotation
        configuration.annotations["type"] =
            AnnotationsConfiguration(; color_palette = collect(enumerate(get_vector(daf, "type", "color").array)))
    end
    configuration.annotations["bool"] = AnnotationsConfiguration(; color_palette = [(0.0, "#ffffff"), (1.0, "#000000")])
    return configuration
end

function extract_categorical_color_palette(  # untested
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

end  # module
