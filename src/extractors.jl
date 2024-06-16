"""
Extract data from a metacells `Daf` for standard graphs.
"""
module Extractors

export default_gene_gene_configuration
export default_marker_genes_configuration
export default_sphere_sphere_configuration
export extract_categorical_color_palette
export extract_gene_gene_data
export extract_marker_genes_data
export extract_sphere_sphere_data

using Base.Threads
using Base.Unicode
using Daf
using Daf.GenericTypes
using DataFrames
using LinearAlgebra
using NamedArrays
using Statistics
using ..Renderers

import Printf
import Metacells.Spheres.compute_confidence_log_fraction_of_genes_in_metacells
import Metacells.Spheres.gene_distance

GENE_FRACTION_FORMAT = Printf.Format("%.1e")

function format_gene_fraction(gene_fraction::AbstractFloat)::AbstractString  # untested
    return Printf.format(GENE_FRACTION_FORMAT, gene_fraction)
end

"""
    extract_gene_gene_data(
        daf::DafReader;
        x_gene::AbstractString,
        y_gene::AbstractString,
        axis::QueryString,
        [min_significant_gene_UMIs::Integer = 40,
        color::Maybe{QueryString} = nothing,
        entries_hovers::Maybe{FrameColumns} = ["total_UMIs" => "=", "type" => "="],
        genes_hovers::Maybe{FrameColumns} = nothing],
    )::PointsGraphData

Extract the data for a gene-gene graph from the `daf` data. The X coordinate of each point is the fraction of the
`x_gene` and the Y coordinate of each gene is the fraction of the `y_gene` in each of the entries of the `axis`. By
default we show the genes fractions of all metacells.

We ignore genes that don't have at least `min_significant_gene_UMIs` between both entries.

If a `colors_query` is specified, it can be a suffix of a query that fetches a value for each entry of the `axis`, or a
full query that groups by the axis. By default we color by the type of the `axis`.

Anything listed in `hovers` will be collected per metacell and used in the hover data.
"""
function extract_gene_gene_data(  # untested
    daf::DafReader;
    x_gene::AbstractString,
    y_gene::AbstractString,
    axis::QueryString = "metacell",
    min_significant_gene_UMIs::Integer = 40,
    color::Maybe{QueryString} = "type",
    entries_hovers::Maybe{FrameColumns} = ["total_UMIs" => "=", "type" => "="],
    genes_hovers::Maybe{FrameColumns} = nothing,
)::PointsGraphData
    axis_query = Query(axis, Axis)  # NOJET
    axis_name = query_axis_name(axis_query)

    x_gene_query = Axis("gene") |> IsEqual(x_gene) |> Lookup("fraction")
    y_gene_query = Axis("gene") |> IsEqual(y_gene) |> Lookup("fraction")
    full_x_gene_query = full_vector_query(axis_query, x_gene_query)
    full_y_gene_query = full_vector_query(axis_query, y_gene_query)
    fractions_of_x_gene = get_query(daf, full_x_gene_query)
    fractions_of_y_gene = get_query(daf, full_y_gene_query)
    @assert names(fractions_of_x_gene, 1) == names(fractions_of_y_gene, 1)

    x_gene_query = Axis("gene") |> IsEqual(x_gene) |> Lookup("total_UMIs")
    y_gene_query = Axis("gene") |> IsEqual(y_gene) |> Lookup("total_UMIs")
    full_x_gene_query = full_vector_query(axis_query, x_gene_query)
    full_y_gene_query = full_vector_query(axis_query, y_gene_query)
    total_UMIs_of_x_gene = get_query(daf, full_x_gene_query)
    total_UMIs_of_y_gene = get_query(daf, full_y_gene_query)
    @assert names(total_UMIs_of_x_gene, 1) == names(fractions_of_x_gene, 1)
    @assert names(total_UMIs_of_x_gene, 1) == names(total_UMIs_of_y_gene, 1)

    entries_mask = total_UMIs_of_x_gene .+ total_UMIs_of_y_gene .> min_significant_gene_UMIs

    if entries_hovers === nothing
        columns_of_entries_hovers = nothing
    else
        columns_of_entries_hovers = pairs(DataFrames.DataFrameColumns(get_frame(daf, axis_query, entries_hovers)))
    end

    if genes_hovers === nothing
        columns_of_x_gene_hovers = nothing
        columns_of_y_gene_hovers = nothing
    else
        x_genes_query = Axis("gene") |> And("name") |> IsEqual(x_gene)
        y_genes_query = Axis("gene") |> And("name") |> IsEqual(y_gene)

        columns_of_x_gene_hovers = pairs(DataFrames.DataFrameColumns(get_frame(daf, x_genes_query, genes_hovers)))
        columns_of_y_gene_hovers = pairs(DataFrames.DataFrameColumns(get_frame(daf, y_genes_query, genes_hovers)))
    end

    names_of_entries = names(fractions_of_x_gene, 1)
    n_entries = length(names_of_entries)
    hovers = Vector{String}(undef, n_entries)
    for entry_index in 1:n_entries
        if !entries_mask[entry_index]
            continue
        end
        hover = ["$(uppercasefirst(axis_name)): $(names_of_entries[entry_index])"]
        if columns_of_entries_hovers !== nothing
            for (column_name, column_values_of_entries) in columns_of_entries_hovers  # NOJET
                push!(hover, "- $(column_name): $(column_values_of_entries[entry_index])")
            end
        end

        push!(hover, "$(x_gene):")
        push!(hover, "- fraction: $(format_gene_fraction(fractions_of_x_gene[entry_index]))")
        push!(hover, "- total_UMIs: $(total_UMIs_of_x_gene[entry_index])")
        if columns_of_x_gene_hovers !== nothing
            for (column_name, column_values_of_x_gene) in columns_of_x_gene_hovers
                push!(hover, "- $(column_name): $(column_values_of_x_gene[1])")
            end
        end

        push!(hover, "$(y_gene):")
        push!(hover, "- fraction: $(format_gene_fraction(fractions_of_y_gene[entry_index]))")
        push!(hover, "- total_UMIs: $(total_UMIs_of_y_gene[entry_index])")
        if columns_of_y_gene_hovers !== nothing
            for (column_name, column_values_of_y_gene) in columns_of_y_gene_hovers
                push!(hover, "- $(column_name): $(column_values_of_y_gene[1])")
            end
        end

        hovers[entry_index] = join(hover, "<br>")
    end

    hovers = hovers[entries_mask]
    fractions_of_x_gene = fractions_of_x_gene.array[entries_mask]
    fractions_of_y_gene = fractions_of_y_gene.array[entries_mask]

    if color === nothing
        colors = nothing
    else
        color_query = Query(color, Lookup)
        full_color_query = full_vector_query(axis_query, color_query)
        colors = get_query(daf, full_color_query)
        colors = colors.array[entries_mask]
    end

    return PointsGraphData(;
        figure_title = "$(uppercasefirst(axis_name))s Gene-Gene",
        x_axis_title = x_gene,
        y_axis_title = y_gene,
        points_colors_title = string(color),
        points_xs = fractions_of_y_gene,
        points_ys = fractions_of_x_gene,
        points_colors = colors,
        points_hovers = hovers,
    )
end

"""
    extract_categorical_color_palette(
        daf::DafReader,
        query::QueryString
    )::AbstractVector{<:AbstractString, <:AbstractString}

Convert the results of a `query` to a color palette for rendering. The query must return a named vector of strings; the
names are taken to be the values and the strings are taken to be the color names. For example,
`extract_categorical_color_palette(daf, q"/ type : color")` will return a color palette mapping each type to its color.
"""
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

"""
    default_gene_gene_configuration(
        configuration = PointsGraphConfiguration();
        [gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5],
    )::PointsGraphConfiguration

Return a default configuration for a gene-gene graph. This just applies the log scale to the axes.
Will modify `configuration` in-place and return it.
"""
function default_gene_gene_configuration(  # untested
    configuration = PointsGraphConfiguration();
    gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
)::PointsGraphConfiguration
    @assert gene_fraction_regularization === nothing || gene_fraction_regularization >= 0
    configuration.x_axis.log_regularization = gene_fraction_regularization
    configuration.y_axis.log_regularization = gene_fraction_regularization
    return configuration
end

"""
    function extract_sphere_sphere_data(
        daf::DafReader;
        x_sphere::AbstractString,
        y_sphere::AbstractString,
        [min_significant_gene_UMIs::Integer = 40,
        max_sphere_diameter::AbstractFloat = 2.0,
        gene_fraction_regularization::AbstractFloat = 1e-5],
    )::PointsGraphData

Extract the data for a sphere-sphere graph. This shows why two spheres were not merged (or, if given the same sphere
name twice, why the sphere was merged).
"""
function extract_sphere_sphere_data(
    daf::DafReader;
    x_sphere::AbstractString,
    y_sphere::AbstractString,
    min_significant_gene_UMIs::Integer = 40,
    max_sphere_diameter::AbstractFloat = 2.0,
    gene_fraction_regularization::AbstractFloat = 1e-5,
    confidence::AbstractFloat = 0.9,
)::PointsGraphData
    @assert gene_fraction_regularization > 0

    names_of_x_metacells,
    total_UMIs_of_x_metacells,
    total_UMIs_of_x_metacells_of_genes,
    fraction_of_x_metacells_of_genes = read_sphere_sphere_data(daf, x_sphere)
    log_decreased_fraction_of_genes_in_x_metacells, log_increased_fraction_of_genes_in_x_metacells =
        compute_confidence_log_fraction_of_genes_in_metacells(;
            gene_fraction_regularization = gene_fraction_regularization,
            fraction_of_genes_in_metacells = transposer!(fraction_of_x_metacells_of_genes),
            total_UMIs_of_metacells = total_UMIs_of_x_metacells,
            confidence = confidence,
        )
    log_decreased_fraction_of_x_metacells_of_genes = transposer!(log_decreased_fraction_of_genes_in_x_metacells)
    log_increased_fraction_of_x_metacells_of_genes = transposer!(log_increased_fraction_of_genes_in_x_metacells)
    @assert all(log_decreased_fraction_of_x_metacells_of_genes .<= log_increased_fraction_of_x_metacells_of_genes)

    is_self_difference = x_sphere == y_sphere
    if is_self_difference
        names_of_y_metacells, total_UMIs_of_y_metacells_of_genes, fraction_of_y_metacells_of_genes =
            names_of_x_metacells, total_UMIs_of_x_metacells_of_genes, fraction_of_x_metacells_of_genes
        log_decreased_fraction_of_y_metacells_of_genes, log_increased_fraction_of_y_metacells_of_genes =
            log_decreased_fraction_of_x_metacells_of_genes, log_increased_fraction_of_x_metacells_of_genes
    else
        names_of_y_metacells,
        total_UMIs_of_y_metacells,
        total_UMIs_of_y_metacells_of_genes,
        fraction_of_y_metacells_of_genes = read_sphere_sphere_data(daf, y_sphere)
        log_decreased_fraction_of_genes_in_y_metacells, log_increased_fraction_of_genes_in_y_metacells =
            compute_confidence_log_fraction_of_genes_in_metacells(;
                gene_fraction_regularization = gene_fraction_regularization,
                fraction_of_genes_in_metacells = transposer!(fraction_of_y_metacells_of_genes),
                total_UMIs_of_metacells = total_UMIs_of_y_metacells,
                confidence = confidence,
            )
        log_decreased_fraction_of_y_metacells_of_genes = transposer!(log_decreased_fraction_of_genes_in_y_metacells)
        log_increased_fraction_of_y_metacells_of_genes = transposer!(log_increased_fraction_of_genes_in_y_metacells)
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
    main_neighborhoods_of_spheres = get_vector(daf, "sphere", "neighborhood.main")
    x_neighborhood = main_neighborhoods_of_spheres[x_sphere]
    y_neighborhood = main_neighborhoods_of_spheres[y_sphere]

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
    x_correlated = "correlated for $(x_sphere)"
    y_correlated = "correlated for $(y_sphere)"
    xy_correlated = "correlated for both"

    diameters_of_neighborhoods = get_vector(daf, "neighborhood", "diameter")
    is_member_of_spheres_in_neighborhoods = get_matrix(daf, "sphere", "neighborhood", "is_member")
    if x_neighborhood == y_neighborhood
        neighborhood_diameter = diameters_of_neighborhoods[x_neighborhood]
        x_axis_title = "$(x_sphere) (main: $(x_neighborhood) diameter: $(neighborhood_diameter))"
        y_axis_title = "$(y_sphere) (main: $(y_neighborhood) diameter: $(neighborhood_diameter))"
    else
        x_diameter = diameters_of_neighborhoods[x_neighborhood]
        is_x_sphere_member_of_main_neighborhood_of_y_sphere =
            is_member_of_spheres_in_neighborhoods[x_sphere, y_neighborhood]
        if is_x_sphere_member_of_main_neighborhood_of_y_sphere
            x_is_not = "is"
        else
            x_is_not = "not"
        end
        x_axis_title = "$(x_sphere) (main: $(x_neighborhood) diameter: $(x_diameter), $(x_is_not) in: $(y_neighborhood))"

        y_diameter = diameters_of_neighborhoods[x_neighborhood]

        is_y_sphere_member_of_main_neighborhood_of_x_sphere =
            is_member_of_spheres_in_neighborhoods[y_sphere, x_neighborhood]
        if is_y_sphere_member_of_main_neighborhood_of_x_sphere
            y_is_not = "is"
        else
            y_is_not = "not"
        end
        y_axis_title = "$(y_sphere) (main: $(y_neighborhood) diameter: $(y_diameter), $(y_is_not) in: $(x_neighborhood))"

        neighborhood_diameter = x_diameter
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
            x_label, y_label = "$(x_sphere) low:", "$(x_sphere) high:"
        else
            x_label, y_label = "$(x_sphere):", "$(y_sphere):"
        end

        @assert neighborhood_diameter > max_sphere_diameter

        borders_colors[point_index] = "not a certificate"
        if points_colors[point_index] != not_correlated && !is_lateral_of_genes[gene_index]
            if distance_of_genes[gene_index] >= neighborhood_diameter
                borders_colors[point_index] = "certificate for $(x_sphere) neighborhood"
            elseif distance_of_genes[gene_index] >= max_sphere_diameter
                borders_colors[point_index] = "certificate for $(x_sphere) sphere"
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
            points_ys[point_index] =
                points_xs[point_index] * (points_ys[point_index] / points_xs[point_index])^(1 - divergence)
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
        figure_title = "Spheres Genes Difference",
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

function read_sphere_sphere_data(  # untested
    daf::DafReader,
    sphere::AbstractString,
)::Tuple{
    AbstractVector{<:AbstractString},
    AbstractVector{<:Unsigned},
    AbstractMatrix{<:Unsigned},
    AbstractMatrix{<:AbstractFloat},
}
    metacells_query = Axis("metacell") |> And("sphere") |> IsEqual(sphere)
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
    default_sphere_sphere_configuration(
        [configuration::PointsGraphConfiguration = PointsGraphConfiguration()];
        x_sphere::AbstractString,
        y_sphere::AbstractString,
        x_neighborhood::AbstractString,
        [max_sphere_diameter::AbstractFloat = 2.0,
        gene_fraction_regularization::AbstractFloat = 1e-5],
    )::PointsGraphConfiguration

Return a default configuration for a sphere-sphere graph. Will modify `configuration` in-place and return it.
"""
function default_sphere_sphere_configuration(  # untested
    configuration::PointsGraphConfiguration = PointsGraphConfiguration();
    x_sphere::AbstractString,
    y_sphere::AbstractString,
    max_sphere_diameter::AbstractFloat = 2.0,
    gene_fraction_regularization::AbstractFloat = 1e-5,
)::PointsGraphConfiguration
    @assert gene_fraction_regularization === nothing || gene_fraction_regularization >= 0
    configuration.diagonal_bands.low.offset = 2^-max_sphere_diameter
    configuration.diagonal_bands.middle.offset = 1.0
    configuration.diagonal_bands.high.offset = 2^max_sphere_diameter
    configuration.x_axis.log_regularization = gene_fraction_regularization
    configuration.y_axis.log_regularization = gene_fraction_regularization
    configuration.edges_over_points = false
    configuration.edges.show_color_scale = true
    configuration.points.show_color_scale = true
    configuration.borders.show_color_scale = true
    configuration.points.color_palette = [
        ("lateral", "grey"),
        ("uncorrelated for both", "salmon"),
        ("correlated for $(x_sphere)", "seagreen"),
        ("correlated for $(y_sphere)", "royalblue"),
        ("correlated for both", "darkturquoise"),
    ]
    configuration.borders.color_palette = [
        ("not a certificate", "lavender"),
        ("certificate for $(x_sphere) sphere", "mediumpurple"),
        ("certificate for $(x_sphere) neighborhood", "mediumorchid"),
    ]
    return configuration
end

"""
    function extract_marker_genes_data(
        daf::DafReader;
        [axis::AbstractString = "metacell",
        min_marker_genes::Integer = 100,
        type_property::Maybe{AbstractString} = "type",
        expression_annotations::Maybe{FrameColumns} = nothing,
        gene_annotations::Maybe{FrameColumns} = ["is_lateral", "divergence"],
        gene_names::Maybe{Vector{AbstractString}} = nothing],
    )::HeatmapGraphData

Extract the data for a marker genes graph. This shows the genes that most distinguish between metacells (or profiles
using another axis). Type annotations are added based on the `type_property` (which should name an axis with a `color`
property), and optional `expression_annotations` and `gene_annotations`.

If `gene_names` is specified, these genes will always appear in the graph. This list is supplemented with additional
`is_marker` genes to show at least `min_marker_genes`. A number of strongest such genes is chosen from each profile,
such that the total number of these genes together with the forced `gene_names` is at least `min_marker_genes`.
"""
function extract_marker_genes_data(  # untested
    daf::DafReader;
    axis::AbstractString = "metacell",
    gene_names::Maybe{Vector{AbstractString}} = nothing,
    max_marker_genes::Integer = 100,
    gene_fraction_regularization::AbstractFloat = 1e-5,
    type_property::Maybe{AbstractString} = "type",
    expression_annotations::Maybe{FrameColumns} = nothing,
    gene_annotations::Maybe{FrameColumns} = ["is_lateral", "divergence"],
)::HeatmapGraphData
    @assert max_marker_genes > 0
    @assert type_property !== nothing || expression_annotations === nothing
    power_of_selected_genes_of_profiles, names_of_selected_genes, indices_of_selected_genes =
        compute_marker_genes(daf, axis, gene_names, max_marker_genes, gene_fraction_regularization)
    columns_annotations = marker_genes_columns_annotations(daf, axis, type_property, expression_annotations)
    rows_annotations = marker_genes_rows_annotations(daf, gene_annotations, indices_of_selected_genes)
    return HeatmapGraphData(;
        figure_title = "$(uppercasefirst(axis))s Marker Genes",
        x_axis_title = uppercasefirst(axis),
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
    gene_fraction_regularization::AbstractFloat = 1e-5,
)::Tuple{AbstractMatrix{<:Real}, AbstractVector{<:AbstractString}, AbstractVector{<:Integer}}
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

        fractions_of_named_genes_of_profiles = transposer!(fractions_of_profiles_of_named_genes)
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

        fractions_of_candidate_genes_of_profiles = transposer!(fractions_of_profiles_of_candidate_genes)
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
    end

    return power_of_selected_genes_of_profiles, names_of_selected_genes, indices_of_selected_genes
end

function marker_genes_columns_annotations(::DafReader, ::AbstractString, ::Nothing, ::Maybe{FrameColumns})::Nothing  # untested
    return nothing
end

function marker_genes_columns_annotations(  # untested
    daf::DafReader,
    axis::AbstractString,
    type_property::AbstractString,
    expression_annotations::Maybe{FrameColumns},
)::Maybe{Vector{AnnotationsData}}
    annotations = AnnotationsData[]
    type_of_profiles = get_vector(daf, axis, type_property)
    push!(
        annotations,
        AnnotationsData(;
            name = "type",
            title = type_property,
            values = axis_indices(daf, type_property, type_of_profiles.array),
            hovers = names(type_of_profiles, 1),
        ),
    )
    if expression_annotations !== nothing
        data_frame = get_frame(daf, type_property, expression_annotations)
        for (name, values) in pairs(eachcol(data_frame))
            push!(annotations, AnnotationsData(; title = string(name), values = Float32.(values)))
        end
    end
    return annotations
end

function marker_genes_rows_annotations(::DafReader, ::Nothing, ::AbstractVector{<:Integer})::Nothing  # untested
    return nothing
end

function marker_genes_rows_annotations(
    daf::DafReader,
    gene_annotations::FrameColumns,
    indices_of_selected_genes::AbstractVector{<:Integer},
)::Vector{AnnotationsData}  # untested
    data_frame = get_frame(daf, "gene", gene_annotations)
    return [
        AnnotationsData(;
            title = string(name),
            name = eltype(values) <: Bool ? "bool" : nothing,
            values = Float32.(values[indices_of_selected_genes]),
        ) for (name, values) in pairs(eachcol(data_frame))
    ]
end

"""
    default_marker_genes_configuration(
        daf::DafReader,
        [configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
        type_property::Maybe{AbstractString},
        min_significant_fold::Real = 0.5,
        max_significant_fold::Real = 3.0],
    )::HeatmapGraphConfiguration

Return a default configuration for a markers heatmap graph. Will modify `configuration` in-place and return it.

Genes whose (absolute) fold factor (log base 2 of the ratio between the expression level and the median of the
population) is less than `min_significant_fold` are colored in white. The color scale continues until
`max_significant_fold`.
"""
function default_marker_genes_configuration(  # untested
    daf::DafReader,
    configuration::HeatmapGraphConfiguration = HeatmapGraphConfiguration();
    type_property::Maybe{AbstractString},
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
    if type_property !== nothing
        configuration.annotations["type"] = AnnotationsConfiguration(;
            color_palette = collect(enumerate(get_vector(daf, type_property, "color").array)),
        )
    end
    configuration.annotations["bool"] = AnnotationsConfiguration(; color_palette = [(0.0, "#ffffff"), (1.0, "#000000")])
    return configuration
end

end  # module
