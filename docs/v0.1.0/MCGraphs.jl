"""
Generate graphs for visualizing scRNA-seq metacells data in a `Daf` data set.

The goals of this are:

  - Provide a specific set of graphs allowing for investigation and visualization of the metacells data.
  - Generate static PNG and/or SVG files (for publishing).
  - Generate interactive graphs in Jupyter notebook, both from Python and from R (for exploration).
  - Provide guided UI in Jupyter notebook for accessing and customizing the graphs, as well as generating standard
    dashboards of related graphs.
  - Be reasonably efficient when the data is large.

The overall architecture of the solution is based on the following layered implementation:

Julia code:

  - [`Validations`](@ref MCGraphs.Validations) contains functions for validating user input which can be invoked by the
    UI to ensure valid inputs.
  - `Renderers` contains functions that actually render graphs, given the graph data and configuration. Each basic
    graph type has its own specification for the data and for the configuration. For example, a scatter plot data
    contains x coordinates, y coordinates, and colors, while the configuration controls the graph size, point shape and
    size, axis and graph titles, etc. We render most graphs using `Plotly`, but use `ClusterGrammer` for heatmaps.
  - `Extractors` contains functions that extract graph data from a `Daf` data set. For example, a gene-gene plot will
    extract the expression of two genes in all metacells as the x and y coordinates, colored according to the type of
    the metacells.
  - `Plotters` contains functions that combine extraction and rendering, that is, will render a graph given a `Daf`
    data set and a graph configuration. Each plot can specify different defaults for the graph configuration. For
    example, the default titles of a gene-gene plot would be different from the default titles of a differential
    expression plot, even though both will use the same scatter plot renderer.

Jupyter notebook code (need to be implemented in all Jupyter languages):

  - `Controllers` are Jupyter notebook UI elements for specifying which data to extract for a graph, or the
    configuration of a graph. For example, a data controller for a gene-gene plot will allow selecting the two genes,
    and a configuration controller for a scatter plot graph will allow specifying the point shape and size.
  - `Widgets` combine multiple controllers to fully specify a graph to render. For example, a gene-gene graph widget
    will combine both the gene-gene plot data selection with the scatter plot graph configuration, using the specific
    defaults of the gene-gene graph.
  - `Menus` allow selecting a single widget (for rendering a single graph) or several related widgets (for rendering a
    standard dashboard of graphs). For example, one entry in a menu could be "gene-gene plot" which generates a single
    graph while another might be "metacells QC dashboard" which generates multiple graphs visualizing various metacells
    QC measures. Menus are nested in a tree, such that invoking the root menu allows the user to interactively navigate
    to any of the provided plots and dashboards, without having to memorize the function names and configuration
    options.

Generating graphs is in general a read-only operation, allowing the analyst to explore the data. However, some work
flows require creating and modifying data, for example, manual metacells type annotations. This is supported by
dedicated controllers that write data back into the `Daf` data set, which is typically a chain consisting of a large
read-only base data set combined with a small writeable data set containing the manually entered data. This allows
reusing the same base data set with multiple alternative manual annotations.

!!! note

    While the overall architecture of the code here generalizes well, the functionality here is intentionally restricted
    to what we found useful for visualizing scRNA-seq metacells data in `Daf` data sets. Likewise, the amount of
    customization of the graphs is intentionally limited. The intent here is to make it as easy as possible for the
    analyst working in Jupyter notebook to explore the data, and generate graphs for academic papers, **not** to create
    yet another end-all-be-all graphs framework (of which there are too many already).

This is intentionally separated from the [`Metacells.jl`]((https://github.com/tanaylab/Metacells.jl) package itself,
which is dedicated to computing the metacells.
"""
module MCGraphs

using Reexport

include("validations.jl")
@reexport using .Validations

end # module
