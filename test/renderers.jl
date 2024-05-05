CSS_ID_REGEX = r"""id="([^"]+)"""
TRACE_REGEX = r"""trace([-_a-zA-Z0-9]+)"""
CLASS_REGEX = r"""class="([-_a-zA-Z]*[0-9][-_a-zA-Z0-9]*)"""
HTML_ID_REGEX = r"""id=([-_a-zA-Z0-9]+)"""

function normalize_ids(
    text::AbstractString,
    replace_prefix::AbstractString,
    capture_regex::Regex,
    match_prefix::AbstractString,
)::AbstractString
    seen = Dict{AbstractString, Int}()
    for id in eachmatch(capture_regex, text)
        index = get(seen, id.captures[1], nothing)
        if index === nothing
            index = length(seen) + 1
            seen[id.captures[1]] = index
        end
    end
    replacements = sort(
        ["$(match_prefix)$(id)" => "$(replace_prefix)$(index)" for (id, index) in seen];
        by = (pair) -> length(pair.first),
        rev = true,
    )
    return replace(text, replacements...)
end

function normalize_svg(svg::AbstractString)::AbstractString
    svg = normalize_ids(svg, "id-", CSS_ID_REGEX, "")
    svg = normalize_ids(svg, "class-", CLASS_REGEX, "")
    svg = normalize_ids(svg, "trace-", TRACE_REGEX, "trace")
    svg = replace(svg, " style=\"\"" => "", ">" => ">\n")
    return svg
end

function normalize_html(html::AbstractString)::AbstractString
    html = normalize_ids(html, "id-", HTML_ID_REGEX, "")
    return html
end

struct ResultFile
    path::AbstractString
    content::AbstractString
end

function Base.show(io::IO, result_file::ResultFile)::Nothing  # untested
    print(io, result_file.path)
    return nothing
end

function Base.:(==)(left_file::ResultFile, right_file::ResultFile)::Bool
    return left_file.content == right_file.content
end

function test_svg(path::AbstractString)::Nothing
    actual_svg = open("actual.svg", "r") do file
        return read(file, String)
    end
    rm("actual.svg")
    actual_svg = normalize_svg(actual_svg)

    actual_path = "actual/" * path
    open(actual_path, "w") do file
        write(file, actual_svg)
        return nothing
    end
    actual_result = ResultFile("test/" * actual_path, actual_svg)

    expected_path = "expected/" * path
    expected_svg = open(expected_path, "r") do file
        return read(file, String)
    end
    expected_result = ResultFile("test/" * expected_path, expected_svg)

    @test actual_result == expected_result
    return nothing
end

function test_html(path::AbstractString)::Nothing
    actual_html = open("actual.html", "r") do file
        return read(file, String)
    end
    rm("actual.html")
    actual_html = normalize_html(actual_html)

    actual_path = "actual/" * path
    open(actual_path, "w") do file
        write(file, actual_html)
        return nothing
    end
    actual_result = ResultFile("test/" * actual_path, actual_html)

    expected_path = "expected/" * path
    expected_html = open(expected_path, "r") do file
        return read(file, String)
    end
    expected_result = ResultFile("test/" * expected_path, expected_html)

    @test actual_result == expected_result
    return nothing
end

mkpath("actual")

nested_test("renderers") do
    nested_test("distribution") do
        data = DistributionGraphData(;
            values = [
                #! format: off
                79, 54, 74, 62, 85, 55, 88, 85, 51, 85, 54, 84, 78, 47, 83, 52, 62, 84, 52, 79, 51, 47, 78, 69, 74, 83,
                55, 76, 78, 79, 73, 77, 66, 80, 74, 52, 48, 80, 59, 90, 80, 58, 84, 58, 73, 83, 64, 53, 82, 59, 75, 90,
                54, 80, 54, 83, 71, 64, 77, 81, 59, 84, 48, 82, 60, 92, 78, 78, 65, 73, 82, 56, 79, 71, 62, 76, 60, 78,
                76, 83, 75, 82, 70, 65, 73, 88, 76, 80, 48, 86, 60, 90, 50, 78, 63, 72, 84, 75, 51, 82, 62, 88, 49, 83,
                81, 47, 84, 52, 86, 81, 75, 59, 89, 79, 59, 81, 50, 85, 59, 87, 53, 69, 77, 56, 88, 81, 45, 82, 55, 90,
                45, 83, 56, 89, 46, 82, 51, 86, 53, 79, 81, 60, 82, 77, 76, 59, 80, 49, 96, 53, 77, 77, 65, 81, 71, 70,
                81, 93, 53, 89, 45, 86, 58, 78, 66, 76, 63, 88, 52, 93, 49, 57, 77, 68, 81, 81, 73, 50, 85, 74, 55, 77,
                83, 83, 51, 78, 84, 46, 83, 55, 81, 57, 76, 84, 77, 81, 87, 77, 51, 78, 60, 82, 91, 53, 78, 46, 77, 84,
                49, 83, 71, 80, 49, 75, 64, 76, 53, 94, 55, 76, 50, 82, 54, 75, 78, 79, 78, 78, 70, 79, 70, 54, 86, 50,
                90, 54, 54, 77, 79, 64, 75, 47, 86, 63, 85, 82, 57, 82, 67, 74, 54, 83, 73, 73, 88, 80, 71, 83, 56, 79,
                78, 84, 58, 83, 43, 60, 75, 81, 46, 90, 46, 74, 150,
                #! format: on
            ],
        )
        graph_configuration = GraphConfiguration(; output_file = "actual.svg")

        nested_test("!style") do
            configuration = DistributionGraphConfiguration(;
                graph = graph_configuration,
                style = DistributionStyleConfiguration(; show_box = false),
            )
            @test_throws "must specify at least one of: distribution style.show_box, style.show_violin, style.show_curve" render(
                data,
                configuration,
            )
        end

        nested_test("!output_file") do
            @test_throws "must specify at least one of: graph.output_file, graph.show_interactive" render(data)
        end

        nested_test("!width") do
            configuration = DistributionGraphConfiguration(; graph = graph_configuration)
            configuration.graph.width = 0
            @test_throws "non-positive graph width: 0" render(data, configuration)
        end

        nested_test("!height") do
            configuration = DistributionGraphConfiguration(; graph = graph_configuration)
            configuration.graph.height = 0
            @test_throws "non-positive graph height: 0" render(data, configuration)
        end

        nested_test("!range") do
            configuration = DistributionGraphConfiguration(; graph = graph_configuration)
            configuration.value_axis.minimum = 1
            configuration.value_axis.maximum = 0
            @test_throws dedent("""
                values axis maximum: 0
                is not larger than minimum: 1
            """) render(data, configuration)
        end

        nested_test("curve&violin") do
            configuration = DistributionGraphConfiguration(;
                graph = graph_configuration,
                style = DistributionStyleConfiguration(; show_curve = true, show_violin = true),
            )
            @test_throws "can't specify both of: distribution style.show_violin, style.show_curve" render(
                data,
                configuration,
            )
        end

        nested_test("!values") do
            data = DistributionGraphData(; values = Float32[])
            @test_throws "empty values vector" render(data)
        end

        nested_test("box") do
            configuration = DistributionGraphConfiguration(; graph = graph_configuration)

            nested_test("size") do
                configuration.graph.height = 96 * 2
                configuration.graph.width = 96 * 2
                render(data, configuration)
                test_svg("distribution.box.size.svg")
                return nothing
            end

            nested_test("range") do
                configuration.value_axis.minimum = 0
                configuration.value_axis.maximum = 200
                render(data, configuration)
                test_svg("distribution.box.range.svg")
                return nothing
            end

            nested_test("()") do
                render(data, configuration)
                test_svg("distribution.box.svg")
                return nothing
            end

            nested_test("horizontal") do
                configuration.style.orientation = HorizontalValues
                render(data, configuration)
                test_svg("distribution.box.horizontal.svg")
                return nothing
            end

            nested_test("log") do
                configuration.value_axis.log_scale = true
                render(data, configuration)
                test_svg("distribution.box.log.svg")
                return nothing
            end

            nested_test("outliers") do
                configuration.style.show_outliers = true
                render(data, configuration)
                test_svg("distribution.box.outliers.svg")
                return nothing
            end

            nested_test("color") do
                configuration.style.color = "red"
                render(data, configuration)
                test_svg("distribution.box.color.svg")
                return nothing
            end

            nested_test("!grid") do
                configuration.graph.show_grid = false
                render(data, configuration)
                test_svg("distribution.box.!grid.svg")
                return nothing
            end

            nested_test("!ticks") do
                configuration.graph.show_ticks = false
                render(data, configuration)
                test_svg("distribution.box.!ticks.svg")
                return nothing
            end

            nested_test("titles") do
                data.graph_title = "Graph"
                data.value_axis_title = "Value"
                data.trace_axis_title = "Trace"
                data.name = "Name"
                render(data, configuration)
                test_svg("distribution.box.titles.svg")
                return nothing
            end
        end

        nested_test("violin") do
            configuration = DistributionGraphConfiguration(;
                graph = graph_configuration,
                style = DistributionStyleConfiguration(; show_box = false, show_violin = true),
            )

            nested_test("()") do
                render(data, configuration)
                test_svg("distribution.violin.svg")
                return nothing
            end

            nested_test("horizontal") do
                configuration.style.orientation = HorizontalValues
                render(data, configuration)
                test_svg("distribution.violin.horizontal.svg")
                return nothing
            end

            nested_test("outliers") do
                configuration.style.show_outliers = true
                render(data, configuration)
                test_svg("distribution.violin.outliers.svg")
                return nothing
            end

            nested_test("box") do
                configuration.style.show_box = true
                render(data, configuration)
                test_svg("distribution.violin.box.svg")
                return nothing
            end

            nested_test("log") do
                configuration.value_axis.log_scale = true
                render(data, configuration)
                test_svg("distribution.violin.log.svg")
                return nothing
            end
        end

        nested_test("curve") do
            configuration = DistributionGraphConfiguration(;
                graph = graph_configuration,
                style = DistributionStyleConfiguration(; show_box = false, show_curve = true),
            )

            nested_test("()") do
                render(data, configuration)
                test_svg("distribution.curve.svg")
                return nothing
            end

            nested_test("horizontal") do
                configuration.style.orientation = HorizontalValues
                render(data, configuration)
                test_svg("distribution.curve.horizontal.svg")
                return nothing
            end

            nested_test("outliers") do
                configuration.style.show_outliers = true
                render(data, configuration)
                test_svg("distribution.curve.outliers.svg")
                return nothing
            end

            nested_test("box") do
                configuration.style.show_box = true
                render(data, configuration)
                test_svg("distribution.curve.box.svg")
                return nothing
            end

            nested_test("log") do
                configuration.value_axis.log_scale = true
                render(data, configuration)
                test_svg("distribution.curve.log.svg")
                return nothing
            end
        end
    end

    nested_test("distributions") do
        data = DistributionsGraphData(;
            #! format: off
            values = [ [
                0.75, 5.25, 5.5, 6, 6.2, 6.6, 6.80, 7.0, 7.2, 7.5, 7.5, 7.75, 8.15, 8.15, 8.65, 8.93, 9.2, 9.5, 10,
                10.25, 11.5, 12, 16, 20.90, 22.3, 23.25,
            ], [
                79, 54, 74, 62, 85, 55, 88, 85, 51, 85, 54, 84, 78, 47, 83, 52, 62, 84, 52, 79, 51, 47, 78, 69, 74, 83,
                55, 76, 78, 79, 73, 77, 66, 80, 74, 52, 48, 80, 59, 90, 80, 58, 84, 58, 73, 83, 64, 53, 82, 59, 75, 90,
                54, 80, 54, 83, 71, 64, 77, 81, 59, 84, 48, 82, 60, 92, 78, 78, 65, 73, 82, 56, 79, 71, 62, 76, 60, 78,
                76, 83, 75, 82, 70, 65, 73, 88, 76, 80, 48, 86, 60, 90, 50, 78, 63, 72, 84, 75, 51, 82, 62, 88, 49, 83,
                81, 47, 84, 52, 86, 81, 75, 59, 89, 79, 59, 81, 50, 85, 59, 87, 53, 69, 77, 56, 88, 81, 45, 82, 55, 90,
                45, 83, 56, 89, 46, 82, 51, 86, 53, 79, 81, 60, 82, 77, 76, 59, 80, 49, 96, 53, 77, 77, 65, 81, 71, 70,
                81, 93, 53, 89, 45, 86, 58, 78, 66, 76, 63, 88, 52, 93, 49, 57, 77, 68, 81, 81, 73, 50, 85, 74, 55, 77,
                83, 83, 51, 78, 84, 46, 83, 55, 81, 57, 76, 84, 77, 81, 87, 77, 51, 78, 60, 82, 91, 53, 78, 46, 77, 84,
                49, 83, 71, 80, 49, 75, 64, 76, 53, 94, 55, 76, 50, 82, 54, 75, 78, 79, 78, 78, 70, 79, 70, 54, 86, 50,
                90, 54, 54, 77, 79, 64, 75, 47, 86, 63, 85, 82, 57, 82, 67, 74, 54, 83, 73, 73, 88, 80, 71, 83, 56, 79,
                78, 84, 58, 83, 43, 60, 75, 81, 46, 90, 46, 74, 150,
            ] ./ 10.0 ],
            #! format: on
        )

        graph_configuration = GraphConfiguration(; output_file = "actual.svg")

        configuration = DistributionsGraphConfiguration(; graph = graph_configuration)

        nested_test("!values") do
            empty!(data.values)
            @test_throws "empty values vector" render(data, configuration)
        end

        nested_test("!value") do
            empty!(data.values[1])
            @test_throws "empty values#1 vector" render(data, configuration)
        end

        nested_test("~names") do
            data.names = ["Foo"]
            @test_throws dedent("""
                the number of names: 1
                is different from the number of values: 2
            """) render(data, configuration)
        end

        nested_test("~colors") do
            data.colors = ["Red"]
            @test_throws dedent("""
                the number of colors: 1
                is different from the number of values: 2
            """) render(data, configuration)
        end

        nested_test("box") do
            render(data, configuration)
            test_svg("distributions.box.svg")
            return nothing
        end

        nested_test("log") do
            configuration.value_axis.log_scale = true
            render(data, configuration)
            test_svg("distributions.log.svg")
            return nothing
        end

        nested_test("colors") do
            data.colors = ["red", "green"]
            render(data, configuration)
            test_svg("distributions.box.colors.svg")
            return nothing
        end

        nested_test("titles") do
            data.names = ["Foo", "Bar"]
            data.value_axis_title = "Value"
            data.trace_axis_title = "Trace"
            data.graph_title = "Graph"
            render(data, configuration)
            test_svg("distributions.box.titles.svg")
            return nothing
        end

        nested_test("legend") do
            data.names = ["Foo", "Bar"]
            configuration.show_legend = true
            render(data, configuration)
            test_svg("distributions.box.legend.svg")
            return nothing
        end

        nested_test("legend!titles") do
            configuration.show_legend = true
            render(data, configuration)
            test_svg("distributions.box.legend!titles.svg")
            return nothing
        end
    end

    nested_test("points") do
        data = PointsGraphData(; xs = [0.0, 1.0, 2.0], ys = [-0.2, 1.2, 1.8])
        graph_configuration = GraphConfiguration(; output_file = "actual.svg")
        configuration = PointsGraphConfiguration(; graph = graph_configuration)

        nested_test("()") do
            render(data, configuration)
            test_svg("points.svg")
            return nothing
        end

        nested_test("!size") do
            configuration.style.size = 0
            @test_throws "non-positive points style.size: 0" render(data, configuration)
        end

        nested_test("!same_band_offset") do
            configuration.show_same_band_offset = -1
            @test_throws "non-positive points show_same_band_offset: -1" render(data, configuration)
        end

        nested_test("~ys") do
            push!(data.ys, 2.0)
            @test_throws dedent("""
                the number of xs: 3
                is different from the number of ys: 4
            """) render(data, configuration)
        end

        nested_test("~colors") do
            data.colors = ["Red"]
            @test_throws dedent("""
                the number of colors: 1
                is different from the number of points: 3
            """) render(data, configuration)
        end

        nested_test("~border_colors") do
            data.border_colors = ["Red"]
            @test_throws dedent("""
                the number of border_colors: 1
                is different from the number of points: 3
            """) render(data, configuration)
        end

        nested_test("~sizes") do
            data.sizes = [1.0, 2.0, 3.0, 4.0]
            @test_throws dedent("""
                the number of sizes: 4
                is different from the number of points: 3
            """) render(data, configuration)
        end

        nested_test("~border_sizes") do
            data.border_sizes = [1.0, 2.0, 3.0, 4.0]
            @test_throws dedent("""
                the number of border_sizes: 4
                is different from the number of points: 3
            """) render(data, configuration)
        end

        nested_test("!sizes") do
            data.sizes = [1.0, 0.0, 3.0]
            @test_throws "non-positive size#2: 0.0" render(data, configuration)
        end

        nested_test("!border_sizes") do
            data.border_sizes = [1.0, 0.0, 3.0]
            @test_throws "non-positive border_size#2: 0.0" render(data, configuration)
        end

        nested_test("~hovers") do
            data.hovers = ["Foo"]
            @test_throws dedent("""
                the number of hovers: 1
                is different from the number of points: 3
            """) render(data, configuration)
        end

        nested_test("log") do
            nested_test("!minimum") do
                configuration.x_axis.minimum = 0.0
                configuration.x_axis.log_scale = true
                @test_throws "non-positive x log axis minimum: 0.0" render(data, configuration)
            end

            nested_test("!maximum") do
                configuration.y_axis.maximum = -1.0
                configuration.y_axis.log_scale = true
                @test_throws "non-positive y log axis maximum: -1.0" render(data, configuration)
            end

            nested_test("!xs") do
                configuration.x_axis.log_scale = true
                @test_throws "non-positive log x#1: 0.0" render(data, configuration)
            end

            nested_test("!ys") do
                configuration.y_axis.log_scale = true
                @test_throws "non-positive log y#1: -0.2" render(data, configuration)
            end

            nested_test("()") do
                data.xs .*= 10
                data.ys .*= 10
                data.xs .+= 1
                data.ys .+= 3
                configuration.x_axis.log_scale = true
                configuration.y_axis.log_scale = true
                render(data, configuration)
                test_svg("points.log.svg")
                return nothing
            end

            nested_test("same") do
                data.xs .*= 10
                data.ys .*= 10
                data.xs .+= 1
                data.ys .+= 3
                configuration.x_axis.log_scale = true
                configuration.y_axis.log_scale = true
                configuration.show_same_line = true
                configuration.show_same_band_offset = 1.0
                render(data, configuration)
                test_svg("points.log.same.svg")
                return nothing
            end
        end

        nested_test("same") do
            configuration.show_same_line = true
            configuration.show_same_band_offset = 0.3
            render(data, configuration)
            test_svg("points.same.svg")
            return nothing
        end

        nested_test("color") do
            configuration.style.color = "red"
            render(data, configuration)
            test_svg("points.color.svg")
            return nothing
        end

        nested_test("colors") do
            data.colors = ["red", "green", "blue"]
            render(data, configuration)
            test_svg("points.colors.svg")
            return nothing
        end

        nested_test("values!scale") do
            data.colors = [0.0, 1.0, 2.0]
            render(data, configuration)
            test_svg("points.values!scale.svg")
            return nothing
        end

        nested_test("values") do
            data.colors = [0.0, 1.0, 2.0]
            configuration.style.show_scale = true
            render(data, configuration)
            test_svg("points.values.svg")
            return nothing
        end

        nested_test("reversed") do
            data.colors = [0.0, 1.0, 2.0]
            configuration.style.show_scale = true
            configuration.style.reverse_scale = true
            render(data, configuration)
            test_svg("points.reversed.svg")
            return nothing
        end

        nested_test("viridis") do
            data.colors = [0.0, 1.0, 2.0]
            configuration.style.show_scale = true
            configuration.style.color_scale = "Viridis"
            render(data, configuration)
            test_svg("points.viridis.svg")
            return nothing
        end

        nested_test("size") do
            configuration.style.size = 10
            render(data, configuration)
            test_svg("points.size.svg")
            return nothing
        end

        nested_test("sizes") do
            data.sizes = [10.0, 15.0, 20.0]
            render(data, configuration)
            test_svg("points.sizes.svg")
            return nothing
        end

        nested_test("!grid") do
            configuration.graph.show_grid = false
            render(data, configuration)
            test_svg("points.!grid.svg")
            return nothing
        end

        nested_test("!titles") do
            render(data, configuration)
            test_svg("points.!titles.svg")
            return nothing
        end

        nested_test("titles") do
            data.x_axis_title = "X"
            data.y_axis_title = "Y"
            data.graph_title = "Graph"
            render(data, configuration)
            test_svg("points.titles.svg")
            return nothing
        end

        nested_test("hovers") do
            configuration.graph.output_file = "actual.html"
            data.hovers = ["<b>Foo</b><br>Low", "<b>Bar</b><br>Middle", "<b>Baz</b><br>High"]
            render(data, configuration)
            test_html("points.hovers.html")
            return nothing
        end

        nested_test("border") do
            configuration.show_border = true

            nested_test("()") do
                render(data, configuration)
                test_svg("points.border.svg")
                return nothing
            end

            nested_test("size") do
                configuration.style.size = 6
                configuration.border_style.size = 8
                render(data, configuration)
                test_svg("points.border.size.svg")
                return nothing
            end

            nested_test("sizes") do
                configuration.style.size = 6
                data.border_sizes = [6, 8, 10]
                render(data, configuration)
                test_svg("points.border.sizes.svg")
                return nothing
            end

            nested_test("color") do
                configuration.style.size = 6
                configuration.border_style.size = 8
                configuration.border_style.color = "magenta"
                render(data, configuration)
                test_svg("points.border.color.svg")
                return nothing
            end

            nested_test("colors") do
                configuration.style.size = 6
                configuration.border_style.size = 8
                data.colors = [0.0, 1.0, 2.0]
                data.border_colors = ["red", "green", "blue"]
                render(data, configuration)
                test_svg("points.border.colors.svg")
                return nothing
            end

            nested_test("colorscale") do
                configuration.style.size = 6
                configuration.border_style.size = 8
                data.colors = [0.0, 1.0, 2.0]
                data.border_colors = [20.0, 10.0, 0.0]
                configuration.border_style.color_scale = "Viridis"
                configuration.border_style.show_scale = true
                render(data, configuration)
                test_svg("points.border.show_scale.svg")
                return nothing
            end

            nested_test("colorscales") do
                configuration.style.size = 6
                configuration.border_style.size = 8
                data.colors = [0.0, 1.0, 2.0]
                data.border_colors = [20.0, 10.0, 0.0]
                configuration.border_style.color_scale = "Viridis"
                configuration.style.show_scale = true
                configuration.border_style.show_scale = true
                render(data, configuration)
                test_svg("points.border.show_scales.svg")
                return nothing
            end
        end

        nested_test("edges") do
            data.edges = [(1, 2), (1, 3)]

            nested_test("()") do
                render(data, configuration)
                test_svg("points.edges.svg")
                return nothing
            end

            nested_test("!from") do
                data.edges[1] = (-1, 2)
                @test_throws "edge#1 from invalid point: -1" render(data, configuration)
            end

            nested_test("!to") do
                data.edges[1] = (1, 4)
                @test_throws "edge#1 to invalid point: 4" render(data, configuration)
            end

            nested_test("self") do
                data.edges[1] = (1, 1)
                @test_throws "edge#1 from point to itself: 1" render(data, configuration)
            end

            nested_test("size") do
                configuration.edges_style.size = 8
                render(data, configuration)
                test_svg("points.edges.size.svg")
                return nothing
            end

            nested_test("sizes") do
                data.edges_sizes = [6, 10]
                render(data, configuration)
                test_svg("points.edges.sizes.svg")
                return nothing
            end

            nested_test("color") do
                configuration.edges_style.color = "magenta"
                render(data, configuration)
                test_svg("points.edges.color.svg")
                return nothing
            end

            nested_test("colors") do
                data.edges_colors = ["red", "green"]
                render(data, configuration)
                test_svg("points.edges.colors.svg")
                return nothing
            end
        end
    end
end
