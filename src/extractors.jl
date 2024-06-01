"""
Extract data from a metacells `Daf` for standard graphs.
"""
module Extractors

export extract_gene_gene_data
export extract_categorical_color_palette
export default_gene_gene_configuration

using Daf
using Daf.GenericTypes
using NamedArrays
using ..Renderers

import Printf

GENE_FRACTION_FORMAT = Printf.Format("%.1e")

function format_gene_fraction(gene_fraction::AbstractFloat)::AbstractString
    return Printf.format(GENE_FRACTION_FORMAT, gene_fraction)
end

"""
    extract_gene_gene_data(
        daf::DafReader;
        x_gene::AbstractString,
        y_gene::AbstractString,
        axis::Union{AbstractString, Query},
        color::Maybe{Union{AbstractString, Query}} = nothing,
    )::PointsGraphData

Extract the data for a gene-gene points graph from the `daf` data. The X coordinate of each point is the fraction of the
`x_gene` and the Y coordinate of each gene is the fraction of the `y_gene` in each of the entries of the `axis`. By
default we show the genes fractions of all metacells.

If a `colors_query` is specified, it can be a suffix of a query that fetches a value for each entry of the `axis`, or a
full query that groups by the axis. By default we color by the type of the `axis`.
"""
function extract_gene_gene_data(  # untested
    daf::DafReader;
    x_gene::AbstractString,
    y_gene::AbstractString,
    axis::Union{AbstractString, Query} = "metacell",
    color::Maybe{Union{AbstractString, Query}} = "type",
)::PointsGraphData
    axis_query = Query(axis, Axis)  # NOJET

    x_genes_query = Axis("gene") |> IsEqual(x_gene) |> Lookup("fraction")
    y_genes_query = Axis("gene") |> IsEqual(y_gene) |> Lookup("fraction")
    full_x_genes_query = full_vector_query(axis_query, x_genes_query)
    full_y_genes_query = full_vector_query(axis_query, y_genes_query)
    fractions_of_x_genes = get_query(daf, full_x_genes_query)
    fractions_of_y_genes = get_query(daf, full_y_genes_query)
    @assert names(fractions_of_x_genes, 1) == names(fractions_of_y_genes, 1)

    axis_name = query_axis_name(axis_query)
    entry_names_of_genes = names(fractions_of_x_genes, 1)
    hovers = [
        "$(axis_name): $(entry_name)<br>$(x_gene): $(format_gene_fraction(x_gene_fraction))<br>$(y_gene): $(format_gene_fraction(y_gene_fraction))"
        for (entry_name, x_gene_fraction, y_gene_fraction) in
        zip(entry_names_of_genes, fractions_of_x_genes, fractions_of_y_genes)
    ]

    if color === nothing
        colors = nothing
    else
        color_query = Query(color, Lookup)
        full_color_query = full_vector_query(axis_query, color_query)
        colors = get_query(daf, full_color_query)
        @assert colors isa NamedVector && names(colors, 1) == names(fractions_of_x_genes, 1) (
            "invalid color query: $(full_color_query)\n" *
            "for the axis query: $(axis_query)\n" *
            "of the daf data: $(daf.name)"
        )
        hovers .*= ["<br>$(color): $(color_value)" for color_value in colors.array]
        colors = colors.array
    end

    return PointsGraphData(;
        graph_title = "$(axis_name) gene-gene",
        x_axis_title = x_gene,
        y_axis_title = y_gene,
        points_colors_title = string(color),
        points_xs = fractions_of_y_genes.array,
        points_ys = fractions_of_x_genes.array,
        points_colors = colors,
        points_hovers = hovers,
    )
end

"""
    extract_categorical_color_palette(
        daf::DafReader,
        query::Union{AbstractString, Query}
    )::AbstractVector{<:AbstractString, <:AbstractString}

Convert the results of a `query` to a color palette for rendering. The query must return a named vector of strings; the
names are taken to be the values and the strings are taken to be the color names. For example,
`extract_categorical_color_palette(daf, q"/ type : color")` will return a color palette mapping each type to its color.
"""
function extract_categorical_color_palette(  # untested
    daf::DafReader,
    query::Union{AbstractString, Query},
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
    default_gene_gene_configuration(;
        gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
    )::PointsGraphConfiguration

Return a default configuration for a gene-gene plot. This typically applies the log scale to the axes.
"""
function default_gene_gene_configuration(;
    gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
)::PointsGraphConfiguration
    @assert gene_fraction_regularization === nothing || gene_fraction_regularization >= 0
    return PointsGraphConfiguration(;
        x_axis = AxisConfiguration(; log_regularization = gene_fraction_regularization),
        y_axis = AxisConfiguration(; log_regularization = gene_fraction_regularization),
    )
end

end  # module
