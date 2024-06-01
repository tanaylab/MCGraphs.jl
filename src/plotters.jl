"""
Generate complete graphs from a metacells `Daf` for standard graphs.
"""
module Plotters

export plot_gene_gene

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

Generate a complete gene-gene plot using [`extract_gene_gene_data`](@ref), [`extract_categorical_color_palette`](@ref),
and [`default_gene_gene_configuration`](@ref).
"""
function plot_gene_gene(  # untested
    daf::DafReader;
    x_gene::AbstractString,
    y_gene::AbstractString,
    axis::Union{AbstractString, Query} = "metacell",
    color::Maybe{Union{AbstractString, Query}} = "type",
    gene_fraction_regularization::Maybe{AbstractFloat} = 1e-5,
    colors::Maybe{Union{AbstractString, Query}} = "/ type : color",
)::Graph
    data = extract_gene_gene_data(daf; x_gene = x_gene, y_gene = y_gene, axis = axis, color = color)
    configuration = default_gene_gene_configuration(; gene_fraction_regularization = gene_fraction_regularization)
    if colors !== nothing
        configuration.points.color_palette = extract_categorical_color_palette(daf, colors)
    end
    return Graph(data, configuration)
end

end  # module
