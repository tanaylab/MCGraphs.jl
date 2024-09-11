"""
Shorthand names for structures can be used instead of the full structure name for creating literals. It is easier to
write `HGC(entries = CC(color_axis = AC(minimum = 0))` than
`HeatmapGraphConfiguration(entries = ColorsConfiguration(color_axis = AxisConfiguration(minimum = 0))))`. However, it is
less readable.

A better approach in many cases is to create a default top-level structure `configuration = HeatmapGraphConfiguration()`
and then set the specific fields (`configuration.entries.color_axis.minimum = 0`). This has the advantage that the
auto-complete of any type-aware IDE will guide you by showing the available fields and their types along each step of
the way.

To avoid the inevitable conflicts with other packages, we do not re-export the opaque short names defined here from the
global namespace; that is, to use them, you need to write `using MCGraphs.Shorthands` or `import` specific shorthands.
This may be acceptable in interactive environments and one-off scripts; in production code, you should use the full
structure names.
"""
module Shorthands

using ..Renderers

export AC
export AD
export AGC
export AGD
export BC
export BGC
export BGD
export BsGC
export BsGD
export CC
export CGC
export CGD
export CsGC
export CsGD
export DC
export DGC
export DGD
export DsGC
export DsGD
export FC
export GCD
export GGC
export HGC
export HGD
export LC
export LGC
export LGD
export LsGC
export LsGD
export PC
export PsGC
export PsGD
export SRC

"""
Shorthand for [`AxisConfiguration`](@ref).
"""
AC = AxisConfiguration

"""
Shorthand for [`AnnotationData`](@ref).
"""
AD = AnnotationData

"""
Shorthand for [`AbstractGraphConfiguration`](@ref).
"""
AGC = AbstractGraphConfiguration

"""
Shorthand for [`AbstractGraphData`](@ref).
"""
AGD = AbstractGraphData

"""
Shorthand for [`BandConfiguration`](@ref).
"""
BC = BandConfiguration

"""
Shorthand for [`BarGraphConfiguration`](@ref).
"""
BGC = BarGraphConfiguration

"""
Shorthand for [`BarGraphData`](@ref).
"""
BGD = BarGraphData

"""
Shorthand for [`BarsGraphConfiguration`](@ref).
"""
BsGC = BarsGraphConfiguration

"""
Shorthand for [`BarsGraphData`](@ref).
"""
BsGD = BarsGraphData

"""
Shorthand for [`ColorsConfiguration`](@ref).
"""
CC = ColorsConfiguration

"""
Shorthand for [`CdfGraphConfiguration`](@ref).
"""
CGC = CdfGraphConfiguration

"""
Shorthand for [`CdfGraphData`](@ref).
"""
CGD = CdfGraphData

"""
Shorthand for [`CdfsGraphConfiguration`](@ref).
"""
CsGC = CdfsGraphConfiguration

"""
Shorthand for [`CdfsGraphData`](@ref).
"""
CsGD = CdfsGraphData

"""
Shorthand for [`DistributionConfiguration`](@ref).
"""
DC = DistributionConfiguration

"""
Shorthand for [`DistributionGraphConfiguration`](@ref).
"""
DGC = DistributionGraphConfiguration

"""
Shorthand for [`DistributionGraphData`](@ref).
"""
DGD = DistributionGraphData

"""
Shorthand for [`DistributionsGraphConfiguration`](@ref).
"""
DsGC = DistributionsGraphConfiguration

"""
Shorthand for [`DistributionsGraphData`](@ref).
"""
DsGD = DistributionsGraphData

"""
Shorthand for [`FigureConfiguration`](@ref).
"""
FC = FigureConfiguration

"""
Shorthand for [`GridGraphData`](@ref).
"""
GCD = GridGraphData

"""
Shorthand for [`GridGraphConfiguration`](@ref).
"""
GGC = GridGraphConfiguration

"""
Shorthand for [`HeatmapGraphConfiguration`](@ref).
"""
HGC = HeatmapGraphConfiguration

"""
Shorthand for [`HeatmapGraphData`](@ref).
"""
HGD = HeatmapGraphData

"""
Shorthand for [`LineConfiguration`](@ref).
"""
LC = LineConfiguration

"""
Shorthand for [`LineGraphConfiguration`](@ref).
"""
LGC = LineGraphConfiguration

"""
Shorthand for [`LineGraphData`](@ref).
"""
LGD = LineGraphData

"""
Shorthand for [`LinesGraphConfiguration`](@ref).
"""
LsGC = LinesGraphConfiguration

"""
Shorthand for [`LinesGraphData`](@ref).
"""
LsGD = LinesGraphData

"""
Shorthand for [`PointsConfiguration`](@ref).
"""
PC = PointsConfiguration

"""
Shorthand for [`PointsGraphConfiguration`](@ref).
"""
PsGC = PointsGraphConfiguration

"""
Shorthand for [`PointsGraphData`](@ref).
"""
PsGD = PointsGraphData

"""
Shorthand for [`SizeRangeConfiguration`](@ref).
"""
SRC = SizeRangeConfiguration

end  # module
