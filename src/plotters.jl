"""
Generate complete graphs from a metacells `Daf` for standard graphs.
"""
module Plotters

export plot_gene_gene
export plot_sphere_sphere

using Daf
using Daf.GenericTypes
using NamedArrays
using ..Renderers
using ..Extractors

"""
    plot_gene_gene(
        daf::DafReader;
        x_gene::AbstractString,
        y_gene::AbstractString,
        axis::Union{AbstractString, Query},
        color::Maybe{Union{AbstractString, Query}} = nothing,
        gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
        colors::Maybe{Union{AbstractString, Query}} = nothing,
    )::Graph

Generate a complete gene-gene graph using [`extract_gene_gene_data`](@ref), [`extract_categorical_color_palette`](@ref),
and [`default_gene_gene_configuration`](@ref).

By default, we look at gene expression per metacell; you can override this using the `axis` parameter. Each point in the
graph is a gene which has a robust comparable expression (at least `min_significant_gene_UMIs` between both axis
entries).
"""
function plot_gene_gene(  # untested
    daf::DafReader;
    x_gene::AbstractString,
    y_gene::AbstractString,
    axis::Union{AbstractString, Query} = "metacell",
    color::Maybe{Union{AbstractString, Query}} = "type",
    min_significant_gene_UMIs::Integer = 40,
    gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
    colors::Maybe{Union{AbstractString, Query}} = "/ type : color",
    entries_hovers::Maybe{QueryColumns} = ["total_UMIs" => "=", "type" => "="],
    genes_hovers::Maybe{QueryColumns} = nothing,
)::Graph
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
    configuration = default_gene_gene_configuration(; gene_fraction_regularization = gene_fraction_regularization)
    if colors !== nothing
        configuration.points.color_palette = extract_categorical_color_palette(daf, colors)
    end
    return Graph(data, configuration)
end

"""
    plot_sphere_sphere(
        daf::DafReader;
        x_sphere::AbstractString,
        y_sphere::AbstractString,
        min_significant_gene_UMIs::Integer = 40,
        max_sphere_diameter::AbstractFloat = 2.0,
        gene_fraction_regularization::AbstractFloat = 1e-5,
        confidence::AbstractFloat = 0.9,
    )::Graph

Generate a complete sphere-sphere graph using [`extract_sphere_sphere_data`](@ref) and
[`default_sphere_sphere_configuration`](@ref).

Each point in the graph is a gene which has a robust comparable expression (at least `min_significant_gene_UMIs` between
both spgeres). A line is attached to each point showing the confidence modification used when deciding on grouping of
metacells into spheres.
"""
function plot_sphere_sphere(
    daf::DafReader;
    x_sphere::AbstractString,
    y_sphere::AbstractString,
    min_significant_gene_UMIs::Integer = 40,
    max_sphere_diameter::AbstractFloat = 2.0,
    gene_fraction_regularization::AbstractFloat = 1e-5,
    confidence::AbstractFloat = 0.9,
)::Graph
    data = extract_sphere_sphere_data(
        daf;
        x_sphere = x_sphere,
        y_sphere = y_sphere,
        min_significant_gene_UMIs = min_significant_gene_UMIs,
        gene_fraction_regularization = gene_fraction_regularization,
        confidence = confidence,
    )
    configuration = default_sphere_sphere_configuration(;
        x_sphere = x_sphere,
        y_sphere = y_sphere,
        max_sphere_diameter = max_sphere_diameter,
        gene_fraction_regularization = gene_fraction_regularization,
    )
    return Graph(data, configuration)
end

end  # module
