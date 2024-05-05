# MCGraphs - Generate graphs for visualizing scRNA-seq metacells data in a Daf data set.

## Motivation

The goals of this are:

  - Provide a specific set of graphs allowing for investigation and visualization of the
    [Metacells.jl](https://tanaylab.github.io/Metacells.jl) data stored in
    [Daf.jl](https://tanaylab.github.io/Metacells.jl).
  - Generate static PNG and/or SVG files (for publishing).
  - Generate interactive graphs in Jupyter notebook, both from Python and from R (for exploration).
  - Provide guided UI in Jupyter notebook for accessing and customizing the graphs, as well as generating standard
    dashboards of related graphs.
  - Be reasonably efficient when the data is large.
  - Be separated from the `Metacells` package itself, so people only doing computations will not be forced to
    bring in the plotting packages as dependencies.

If/when this is mature, this should replace [MCView](https://github.com/tanaylab/MCView). Right now this is very much
WIP. See the [v0.1.0 documentation](https://tanaylab.github.io/MCGraphs.jl/v0.1.0) for details.

## Architecture

The overall architecture of the solution is based on the following layered implementation:

Julia code:

  - `Validations` contains functions for validating user input which can be invoked by the UI to ensure valid inputs.
  - `Renderers` contains functions that actually render graphs, given the graph data and configuration. Each basic
    graph type has its own specification for the data and for the configuration. For example, a scatter plot data
    contains x coordinates, y coordinates, and colors, while the configuration controls the graph size, point shape and
    size, axis and graph titles, etc. We render most graphs using [Plotly](https://plotly.com/julia/), but use
    [ClusterGrammer2](https://github.com/ismms-himc/clustergrammer2) for heatmaps.
  - `Extractors` contains functions that extract graph data from a `Daf` data set. For example, a gene-gene plot will
    extract the expression of two genes in all metacells as the x and y coordinates, colored according to the type of
    the metacells.
  - `Plotters` contains functions that combine extraction and rendering, that is, will render a graph given a `Daf`
    data set and a graph configuration. Each plot can specify different defaults for the graph configuration. For
    example, the default titles of a gene-gene plot would be different from the default titles of a differential
    expression plot, even though both will use the same scatter plot renderer.

Jupyter notebook code (need to be implemented in all Jupyter languages, requiring TODO: separate `MCGraphs.py` and
`MCGraphs.r` packages):

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

While the overall architecture of the code here generalizes well, the functionality here is intentionally restricted to
what we found useful for visualizing scRNA-seq metacells data in `Daf` data sets. Likewise, the amount of customization
of the graphs is intentionally limited. The intent here is to make it as easy as possible for the analyst working in
Jupyter notebook to explore the data, and generate graphs for academic papers, **not** to create yet another
end-all-be-all graphs framework (of which there are too many already).

## Installation

Just `Pkg.add("MCGraphs")`, like installing any other Julia package. However, if being used in Jupyter notebook,
you will probably want to install the language specific package instead:

TODO: To install the Python wrappers...

TODO: To install the R wrappers...

## Features list:

This also serves as the main TODO list (including the Python and R wrappers).

### Environment:

  - Static file Plotly graphs (Julia; TODO: Python, TODO: R).
  - Static file Heatmap graphs (TODO: Julia; TODO: Python, TODO: R).
  - Interactive Plotly graphs (TODO: Julia; TODO: Python, TODO: R).
  - Interactive Heatmap graphs (TODO: Julia; TODO: Python, TODO: R).
  - TODO: Jupyter notebook vs. Jupyter lab vs. REPL.

### Graph types:

  - Distribution graph (Julia; TODO: Python, TODO: R).

      + Box graph.
      + Violin graph.
      + Curve graph.
      + Violin + Box graph.
      + Curve + Box graph.
      + Horizontal graph.
      + Log axis.

  - Distributions graph (Julia; TODO: Python, TODO: R).

      + Legend.
      + Separate.
      + TODO: Overlay.
  - Points graph (Julia; TODO: Python, TODO: R).

      + Same line.

      + Same band.
      + TODO: Horizontal line (& band?).
      + TODO: Vertical line (& band?).
      + Color scale.

          * Named.
          * Reversed.
          * TODO: Categorical.
          * TODO: Manual.
      + Colorbar.
      + Borders.

          * Colorbar.
      + Edges.
      + Log axis.
  - Line graph (used for CDF) (TODO: Julia; TODO: Python, TODO: R).
  - Lines graph (used for CDF) (TODO: Julia; TODO: Python, TODO: R).

      + TODO: Legend.
      + TODO: Overlay.
      + TODO: Stacked.
  - Bar graph (TODO: Julia; TODO: Python, TODO: R).

      + TODO: Annotations.
      + TODO: Annotations Legend.
  - Bars graph (TODO: Julia; TODO: Python, TODO: R).

      + TODO: Legend.
      + TODO: Annotations.
      + TODO: Annotations Legend.
      + TODO: Grouped.
      + TODO: Stacked.
  - Heatmap graph (TODO: Julia; TODO: Python, TODO: R).

      + TODO: Annotations.
      + TODO: Tree.
  - Flow (Sankey) graph (TODO: Julia; TODO: Python, TODO: R).

### Controllers:

  - Distribution controller (TODO: Julia; TODO: Python, TODO: R).

  - Distributions controller (TODO: Julia; TODO: Python, TODO: R).
  - Points controller (TODO: Julia; TODO: Python, TODO: R).

      + TODO: With border (TODO: Julia; TODO: Python, TODO: R).
      + TODO: With edges (TODO: Julia; TODO: Python, TODO: R).
  - Line controller (TODO: Julia; TODO: Python, TODO: R).
  - Lines controller (TODO: Julia; TODO: Python, TODO: R).
  - Bar controller (TODO: Julia; TODO: Python, TODO: R).
  - Bars controller (TODO: Julia; TODO: Python, TODO: R).
  - Heatmap controller (TODO: Julia; TODO: Python, TODO: R).

### Widgets & Extractors & Plotters

  - UMIs/metacell distribution (TODO: Julia; TODO: Python, TODO: R).
  - Cells/metacell distribution (TODO: Julia; TODO: Python, TODO: R).
  - Max-inner-fold/metacell distribution (TODO: Julia; TODO: Python, TODO: R).
  - Max-inner-stdev/metacell distribution (TODO: Julia; TODO: Python, TODO: R).
  - Max-zero-fold/metacell distribution (TODO: Julia; TODO: Python, TODO: R).
  - Gene expression/cell type distributions (TODO: Julia; TODO: Python, TODO: R).
  - Projection correlation/metacells distribution (TODO: Julia; TODO: Python, TODO: R).
  - Gene/gene expression points (TODO: Julia; TODO: Python, TODO: R).
  - Genes significant inner-fold/expression points (TODO: Julia; TODO: Python, TODO: R).
  - Genes zero cells/expected points (TODO: Julia; TODO: Python, TODO: R).
  - Manifold points & edges (TODO: Julia; TODO: Python, TODO: R).
  - Differential expression points (TODO: Julia; TODO: Python, TODO: R).
  - Gene observed/projected points (TODO: Julia; TODO: Python, TODO: R).
  - Gene projection correction/expression points (TODO: Julia; TODO: Python, TODO: R).
  - Markers heatmap (TODO: Julia; TODO: Python, TODO: R).
  - Gene modules heatmap (TODO: Julia; TODO: Python, TODO: R).
  - Inner-fold heatmap (TODO: Julia; TODO: Python, TODO: R).
  - Stdev-fold heatmap (TODO: Julia; TODO: Python, TODO: R).
  - Projected-fold heatmap (TODO: Julia; TODO: Python, TODO: R).
  - Projection types stacked bars (TODO: Julia; TODO: Python, TODO: R).
  - Projection types fitted genes (TODO: Julia; TODO: Python, TODO: R).

### Dashboards

  - Atlas Overview (TODO: Julia; TODO: Python, TODO: R).
  - Metacells QC (TODO: Julia; TODO: Python, TODO: R).
  - Projection QC (TODO: Julia; TODO: Python, TODO: R).
  - Annotation QC (TODO: Julia; TODO: Python, TODO: R).

### Work flows

  - Compute metacells (TODO: Julia; TODO: Python, TODO: R).
  - Manual type annotations (TODO: Julia; TODO: Python, TODO: R).

## License (MIT)

Copyright © 2024 Weizmann Institute of Science

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
