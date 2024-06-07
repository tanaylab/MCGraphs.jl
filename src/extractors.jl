"""
Extract data from a metacells `Daf` for standard graphs.
"""
module Extractors

export default_gene_gene_configuration
export default_sphere_sphere_configuration
export extract_categorical_color_palette
export extract_gene_gene_data
export extract_sphere_sphere_data

using Base.Threads
using Base.Unicode
using Daf
using Daf.GenericTypes
using DataFrames
using LinearAlgebra
using NamedArrays
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
        min_significant_gene_UMIs::Integer = 40,
        color::Maybe{QueryString} = nothing,
        entries_hovers::Maybe{QueryColumns} = ["total_UMIs" => "=", "type" => "="],
        genes_hovers::Maybe{QueryColumns} = nothing,
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
    entries_hovers::Maybe{QueryColumns} = ["total_UMIs" => "=", "type" => "="],
    genes_hovers::Maybe{QueryColumns} = nothing,
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
        graph_title = "$(uppercasefirst(axis_name))s Gene-Gene",
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
        gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
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
        min_significant_gene_UMIs::Integer = 40,
        gene_fraction_regularization::AbstractFloat = 1e-5,
    )::PointsGraphData

Extract the data for a sphere-sphere graph. This shows why two spheres were not merged (or, if given the same sphere
name twice, why the sphere was merged).
"""
@computation Contract(;
    axes = [
        "metacell" => (RequiredInput, "The metacells to compare group(s) of."),
        "gene" => (RequiredInput, "The genes to consider (typically, only marker genes)."),
    ],
    data = [
        ("gene", "divergence") => (RequiredInput, AbstractFloat, "How to scale fold factors for this gene."),
        ("gene", "is_lateral") => (RequiredInput, Bool, "A mask of genes of behaviors we want to ignore."),
        ("gene", "neighborhood", "is_correlated") =>
            (RequiredInput, Bool, "Which genes are correlated in each neighborhood."),
        ("metacell", "sphere") => (RequiredInput, AbstractString, "The sphere each metacell belongs to."),
        ("metacell", "gene", "fraction") =>
            (RequiredInput, AbstractFloat, "The fraction of the UMIs of each gene in each metacell."),
        ("metacell", "total_UMIs") => (
            RequiredInput,
            Unsigned,
            "The total number of UMIs used to estimate the fraction of all the genes in each metacell.",
        ),
        ("metacell", "gene", "total_UMIs") => (
            RequiredInput,
            Unsigned,
            "The total number of UMIs used to estimate the fraction of each gene in each metacell.",
        ),
        ("sphere", "neighborhood.main") => (RequiredInput, AbstractString, "The main neighborhood of each sphere."),
        ("sphere", "neighborhood", "is_member") =>
            (GuaranteedOutput, Bool, "Membership matrix for spheres and neighborhoods."),
    ],
) function extract_sphere_sphere_data(
    daf::DafReader;
    x_sphere::AbstractString,
    y_sphere::AbstractString,
    min_significant_gene_UMIs::Integer = 40,
    gene_fraction_regularization::AbstractFloat = 1e-5,
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
        )
    log_decreased_fraction_of_x_metacells_of_genes = transposer!(log_decreased_fraction_of_genes_in_x_metacells)
    log_increased_fraction_of_x_metacells_of_genes = transposer!(log_increased_fraction_of_genes_in_x_metacells)

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
            )
        log_decreased_fraction_of_y_metacells_of_genes = transposer!(log_decreased_fraction_of_genes_in_y_metacells)
        log_increased_fraction_of_y_metacells_of_genes = transposer!(log_increased_fraction_of_genes_in_y_metacells)
    end

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
                x_confidence_fraction_of_genes[gene_index] = max(
                    2^log_increased_fraction_of_x_metacells_of_genes[x_metacell_index, gene_index] -
                    gene_fraction_regularization,
                    0.0,
                )
                y_confidence_fraction_of_genes[gene_index] = max(
                    2^log_decreased_fraction_of_y_metacells_of_genes[y_metacell_index, gene_index] -
                    gene_fraction_regularization,
                    0.0,
                )
            else
                x_confidence_fraction_of_genes[gene_index] = max(
                    2^log_decreased_fraction_of_x_metacells_of_genes[x_metacell_index, gene_index] -
                    gene_fraction_regularization,
                    0.0,
                )
                y_confidence_fraction_of_genes[gene_index] = max(
                    2^log_increased_fraction_of_y_metacells_of_genes[y_metacell_index, gene_index] -
                    gene_fraction_regularization,
                    0.0,
                )
            end
        end
    end

    is_lateral_of_genes = get_vector(daf, "gene", "is_lateral"; default = false)
    main_neighborhoods_of_spheres = get_vector(daf, "sphere", "neighborhood.main")
    x_neighborhood = main_neighborhoods_of_spheres[x_sphere]
    y_neighborhood = main_neighborhoods_of_spheres[y_sphere]

    is_correlated_of_x_neighborhood_of_genes =
        get_query(daf, Axis("neighborhood") |> IsEqual(x_neighborhood) |> Axis("gene") |> Lookup("is_correlated"))
    is_correlated_of_y_neighborhood_of_genes =
        get_query(daf, Axis("neighborhood") |> IsEqual(y_neighborhood) |> Axis("gene") |> Lookup("is_correlated"))

    get_matrix(daf, "sphere", "gene", "is_correlated"; default = false)

    n_significant_genes = sum(mask_of_genes)
    @assert n_significant_genes > 0

    points_xs = Vector{Float32}(undef, n_significant_genes * 2)
    points_ys = Vector{Float32}(undef, n_significant_genes * 2)
    points_colors = Vector{AbstractString}(undef, n_significant_genes * 2)
    points_hovers = Vector{AbstractString}(undef, n_significant_genes * 2)
    edges_points = Vector{Tuple{Int, Int}}(undef, n_significant_genes)

    not_correlated = "uncorrelated for both"
    x_correlated = "correlated for $(x_sphere)"
    y_correlated = "correlated for $(y_sphere)"
    xy_correlated = "correlated for both"

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

        points_hovers[point_index] = join(  # NOJET
            [
                "Gene: $(names_of_genes[gene_index])",
                "distance: $(distance_of_genes[gene_index])",
                "divergence: $(divergence_of_genes[gene_index])",
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
    end
    @assert point_index == n_significant_genes * 2
    @assert edge_index == n_significant_genes

    diameters_of_neighborhoods = get_vector(daf, "neighborhood", "diameter")
    is_member_of_spheres_in_neighborhoods = get_matrix(daf, "sphere", "neighborhood", "is_member")
    if x_neighborhood == y_neighborhood
        diameter = diameters_of_neighborhoods[x_neighborhood]
        x_axis_title = "$(x_sphere) (main: $(x_neighborhood) diameter: $(diameter))"
        y_axis_title = "$(y_sphere) (main: $(y_neighborhood) diameter: $(diameter))"
    else
        x_diameter = diameters_of_neighborhoods[x_neighborhood]
        is_x_sphere_member_of_main_neighborhood_of_y_sphere =
            is_member_of_spheres_in_neighborhoods[x_sphere, y_neighborhood]
        if is_x_sphere_member_of_main_neighborhood_of_y_sphere
            x_axis_title = "$(x_sphere) (main: $(x_neighborhood) diameter: $(x_diameter), not in: $(y_neighborhood))"
        else
            x_axis_title = "$(x_sphere) (main: $(x_neighborhood) diameter: $(x_diameter), is in: $(y_neighborhood))"
        end

        y_diameter = diameters_of_neighborhoods[x_neighborhood]
        is_y_sphere_member_of_main_neighborhood_of_x_sphere =
            is_member_of_spheres_in_neighborhoods[y_sphere, x_neighborhood]
        if is_y_sphere_member_of_main_neighborhood_of_x_sphere
            y_axis_title = "$(y_sphere) (main: $(y_neighborhood) diameter: $(y_diameter), not in: $(x_neighborhood))"
        else
            y_axis_title = "$(y_sphere) (main: $(y_neighborhood) diameter: $(y_diameter), is in: $(x_neighborhood))"
        end
    end

    return PointsGraphData(;
        graph_title = "Spheres Genes Difference",
        x_axis_title = x_axis_title,
        y_axis_title = y_axis_title,
        points_colors_title = "Genes",
        edges_group_title = "Lines",
        edges_line_title = "Confidence",
        points_xs = points_xs,
        points_ys = points_ys,
        points_colors = points_colors,
        points_hovers = points_hovers,
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
    divergence_of_gene::AbstractFloat,
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
                distance = gene_distance(
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
        configuration::PointsGraphConfiguration = PointsGraphConfiguration();
        x_sphere::AbstractString,
        y_sphere::AbstractString,
        gene_fraction_regularization::AbstractFloat = 1e-5,
    )::PointsGraphConfiguration

Return a default configuration for a sphere-sphere graph. Will modify `configuration` in-place and return it.
"""
function default_sphere_sphere_configuration(;  # untested
    configuration::PointsGraphConfiguration = PointsGraphConfiguration(),
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
    configuration.points.color_palette = [
        ("lateral", "grey"),
        ("uncorrelated for both", "salmon"),
        ("correlated for $(x_sphere)", "seagreen"),
        ("correlated for $(y_sphere)", "royalblue"),
        ("correlated for both", "darkturquoise"),
    ]
    configuration.borders.show_color_scale = true
    configuration.borders.size = 2
    configuration.borders.color_palette = [("noisy", "darkorchid")]
    return configuration
end

end  # module
