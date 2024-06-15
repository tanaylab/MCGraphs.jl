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

function strip_nulls(text::AbstractString)::AbstractString
    while true
        next_text = replace(
            text,
            r",\"[^\"]+\":null" => "",
            r"{\"[^\"]+\":null," => "{",
            r"{\"[^\"]+\":null}" => "{}",
            r",\"[^\"]+\":{}" => "",
            r"{\"[^\"]+\":{}," => "{",
            r"{\"[^\"]+\":{}}" => "{}",
        )
        if next_text == text
            return next_text
        end
        text = next_text
    end
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
    html = strip_nulls(html)
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

function test_svg(graph::Graph, path::AbstractString)::Nothing
    save_graph(graph, "actual.svg")
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

function test_html(graph::Graph, path::AbstractString)::Nothing
    save_graph(graph, "actual.html")
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

function test_legend(set_title::Function, graph::Graph, path_prefix::AbstractString)::Nothing
    nested_test("()") do
        test_html(graph, path_prefix * ".legend.html")
        return nothing
    end

    nested_test("title") do
        set_title()
        test_html(graph, path_prefix * ".legend.title.html")
        return nothing
    end

    return nothing
end

mkpath("actual")

nested_test("renderers") do
    nested_test("distribution") do
        graph = distribution_graph(;
            distribution_values = [
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

        nested_test("show") do
            @test "$(graph)" ==
                  "Graph{DistributionGraphData, DistributionGraphConfiguration} (use .figure to show the graph)"
        end

        nested_test("invalid") do
            nested_test("!style") do
                graph.configuration.distribution.show_curve = false
                @test_throws "must specify at least one of: configuration.distribution.show_box, configuration.distribution.show_violin, configuration.distribution.show_curve" graph.figure
            end

            nested_test("!width") do
                graph.configuration.graph.width = 0
                @test_throws "non-positive configuration.graph.width: 0" graph.figure
            end

            nested_test("!height") do
                graph.configuration.graph.height = 0
                @test_throws "non-positive configuration.graph.height: 0" graph.figure
            end

            nested_test("!range") do
                graph.configuration.value_axis.minimum = 1
                graph.configuration.value_axis.maximum = 0
                @test_throws dedent("""
                    configuration.value_axis.maximum: 0
                    is not larger than configuration.value_axis.minimum: 1
                """) graph.figure
            end

            nested_test("curve&violin") do
                graph.configuration.distribution.show_curve = true
                graph.configuration.distribution.show_violin = true
                @test_throws "must not specify both of: configuration.distribution.show_violin, configuration.distribution.show_curve" graph.figure
            end

            nested_test("!values") do
                empty!(graph.data.distribution_values)
                @test_throws "empty data.distribution_values vector" graph.figure
            end

            nested_test("!log_regularization") do
                graph.configuration.value_axis.log_regularization = -1.0
                @test_throws "negative configuration.value_axis.log_regularization: -1.0" graph.figure
            end
        end

        nested_test("box") do
            graph.configuration.distribution.show_curve = false
            graph.configuration.distribution.show_box = true

            nested_test("size") do
                graph.configuration.graph.height = 96 * 2
                graph.configuration.graph.width = 96 * 2
                test_html(graph, "distribution.box.size.html")
                test_svg(graph, "distribution.box.size.svg")
                return nothing
            end

            nested_test("range") do
                graph.configuration.value_axis.minimum = 0
                graph.configuration.value_axis.maximum = 200
                test_html(graph, "distribution.box.range.html")
                return nothing
            end

            nested_test("()") do
                test_html(graph, "distribution.box.html")
                return nothing
            end

            nested_test("vertical") do
                graph.configuration.distribution.values_orientation = VerticalValues
                test_html(graph, "distribution.box.vertical.html")
                return nothing
            end

            nested_test("log") do
                graph.configuration.value_axis.log_regularization = 0
                test_html(graph, "distribution.box.log.html")
                return nothing
            end

            nested_test("outliers") do
                graph.configuration.distribution.show_outliers = true
                test_html(graph, "distribution.box.outliers.html")
                return nothing
            end

            nested_test("!color") do
                graph.configuration.distribution.color = "oobleck"
                @test_throws "invalid configuration.distribution.color: oobleck" graph.figure
                return nothing
            end
            nested_test("color") do
                graph.configuration.distribution.color = "red"
                test_html(graph, "distribution.box.color.html")
                return nothing
            end

            nested_test("!grid") do
                graph.configuration.graph.show_grid = false
                test_html(graph, "distribution.box.!grid.html")
                return nothing
            end

            nested_test("!ticks") do
                graph.configuration.graph.show_ticks = false
                test_html(graph, "distribution.box.!ticks.html")
                return nothing
            end

            nested_test("titles") do
                graph.data.graph_title = "Graph"
                graph.data.value_axis_title = "Value"
                graph.data.trace_axis_title = "Trace"
                graph.data.distribution_name = "Name"
                test_html(graph, "distribution.box.titles.html")
                return nothing
            end
        end

        nested_test("violin") do
            graph.configuration.distribution.show_curve = false
            graph.configuration.distribution.show_violin = true

            nested_test("()") do
                test_html(graph, "distribution.violin.html")
                return nothing
            end

            nested_test("vertical") do
                graph.configuration.distribution.values_orientation = VerticalValues
                test_html(graph, "distribution.violin.vertical.html")
                return nothing
            end

            nested_test("outliers") do
                graph.configuration.distribution.show_outliers = true
                test_html(graph, "distribution.violin.outliers.html")
                return nothing
            end

            nested_test("box") do
                graph.configuration.distribution.show_box = true
                test_html(graph, "distribution.violin.box.html")
                return nothing
            end

            nested_test("log") do
                graph.configuration.value_axis.log_regularization = 0
                test_html(graph, "distribution.violin.log.html")
                return nothing
            end
        end

        nested_test("curve") do
            graph.configuration.distribution.show_box = false
            graph.configuration.distribution.show_curve = true

            nested_test("()") do
                test_html(graph, "distribution.curve.html")
                return nothing
            end

            nested_test("vertical") do
                graph.configuration.distribution.values_orientation = VerticalValues
                test_html(graph, "distribution.curve.vertical.html")
                return nothing
            end

            nested_test("outliers") do
                graph.configuration.distribution.show_outliers = true
                test_html(graph, "distribution.curve.outliers.html")
                return nothing
            end

            nested_test("box") do
                graph.configuration.distribution.show_box = true
                test_html(graph, "distribution.curve.box.html")
                return nothing
            end

            nested_test("log") do
                graph.configuration.value_axis.log_regularization = 0
                test_html(graph, "distribution.curve.log.html")
                return nothing
            end
        end
    end

    nested_test("distributions") do
        graph = distributions_graph(;
            distributions_values = [
                #! format: off
                [
                    0.75, 5.25, 5.5, 6, 6.2, 6.6, 6.80, 7.0, 7.2, 7.5, 7.5, 7.75, 8.15, 8.15, 8.65, 8.93, 9.2, 9.5, 10,
                    10.25, 11.5, 12, 16, 20.90, 22.3, 23.25,
                ], [
                    79, 54, 74, 62, 85, 55, 88, 85, 51, 85, 54, 84, 78, 47, 83, 52, 62, 84, 52, 79, 51, 47, 78, 69, 74,
                    83, 55, 76, 78, 79, 73, 77, 66, 80, 74, 52, 48, 80, 59, 90, 80, 58, 84, 58, 73, 83, 64, 53, 82, 59,
                    75, 90, 54, 80, 54, 83, 71, 64, 77, 81, 59, 84, 48, 82, 60, 92, 78, 78, 65, 73, 82, 56, 79, 71, 62,
                    76, 60, 78, 76, 83, 75, 82, 70, 65, 73, 88, 76, 80, 48, 86, 60, 90, 50, 78, 63, 72, 84, 75, 51, 82,
                    62, 88, 49, 83, 81, 47, 84, 52, 86, 81, 75, 59, 89, 79, 59, 81, 50, 85, 59, 87, 53, 69, 77, 56, 88,
                    81, 45, 82, 55, 90, 45, 83, 56, 89, 46, 82, 51, 86, 53, 79, 81, 60, 82, 77, 76, 59, 80, 49, 96, 53,
                    77, 77, 65, 81, 71, 70, 81, 93, 53, 89, 45, 86, 58, 78, 66, 76, 63, 88, 52, 93, 49, 57, 77, 68, 81,
                    81, 73, 50, 85, 74, 55, 77, 83, 83, 51, 78, 84, 46, 83, 55, 81, 57, 76, 84, 77, 81, 87, 77, 51, 78,
                    60, 82, 91, 53, 78, 46, 77, 84, 49, 83, 71, 80, 49, 75, 64, 76, 53, 94, 55, 76, 50, 82, 54, 75, 78,
                    79, 78, 78, 70, 79, 70, 54, 86, 50, 90, 54, 54, 77, 79, 64, 75, 47, 86, 63, 85, 82, 57, 82, 67, 74,
                    54, 83, 73, 73, 88, 80, 71, 83, 56, 79, 78, 84, 58, 83, 43, 60, 75, 81, 46, 90, 46, 74, 150,
                ] ./ 10.0
                #! format: on
            ],
        )

        nested_test("invalid") do
            nested_test("!values") do
                empty!(graph.data.distributions_values)
                @test_throws "empty data.distributions_values vector" graph.figure
            end

            nested_test("!value") do
                empty!(graph.data.distributions_values[1])
                @test_throws "empty data.distributions_values[1] vector" graph.figure
            end

            nested_test("~names") do
                graph.data.distributions_names = ["Foo"]
                @test_throws dedent("""
                    the data.distributions_names size: 1
                    is different from the data.distributions_values size: 2
                """) graph.figure
            end

            nested_test("!colors") do
                graph.data.distributions_colors = ["Red", "Oobleck"]
                @test_throws "invalid data.distributions_colors[2]: Oobleck" graph.figure
            end

            nested_test("~colors") do
                graph.data.distributions_colors = ["Red"]
                @test_throws dedent("""
                    the data.distributions_colors size: 1
                    is different from the data.distributions_values size: 2
                """) graph.figure
            end

            nested_test("!distributions_gap") do
                graph.configuration.distributions_gap = -1
                @test_throws "non-positive configuration.distributions_gap: -1" graph.figure
            end

            nested_test("~distributions_gap") do
                graph.configuration.distributions_gap = 1
                @test_throws "too-large configuration.distributions_gap: 1" graph.figure
            end
        end

        nested_test("box") do
            nested_test("()") do
                test_html(graph, "distributions.box.html")
                return nothing
            end

            nested_test("!distributions_gap") do
                graph.configuration.distributions_gap = 0
                test_html(graph, "distributions.box.!distributions_gap.html")
                return nothing
            end

            nested_test("vertical") do
                graph.configuration.distribution.values_orientation = VerticalValues
                test_html(graph, "distributions.box.vertical.html")
                return nothing
            end

            nested_test("overlay") do
                graph.configuration.overlay_distributions = true

                nested_test("()") do
                    test_html(graph, "distributions.box.overlay.html")
                    return nothing
                end

                nested_test("vertical") do
                    graph.configuration.distribution.values_orientation = VerticalValues
                    test_html(graph, "distributions.box.overlay.vertical.html")
                    return nothing
                end

                nested_test("legend") do
                    graph.configuration.show_legend = true
                    test_html(graph, "distributions.box.overlay.legend.html")
                    return nothing
                end
            end
        end

        nested_test("violin") do
            graph.configuration.distribution.show_box = false
            graph.configuration.distribution.show_violin = true

            nested_test("()") do
                test_html(graph, "distributions.violin.html")
                return nothing
            end

            nested_test("!distributions_gap") do
                graph.configuration.distributions_gap = 0
                test_html(graph, "distributions.violin.!distributions_gap.html")
                return nothing
            end

            nested_test("vertical") do
                graph.configuration.distribution.values_orientation = VerticalValues
                test_html(graph, "distributions.violin.vertical.html")
                return nothing
            end

            nested_test("overlay") do
                graph.configuration.overlay_distributions = true

                nested_test("()") do
                    test_html(graph, "distributions.violin.overlay.html")
                    return nothing
                end

                nested_test("vertical") do
                    graph.configuration.distribution.values_orientation = VerticalValues
                    test_html(graph, "distributions.violin.overlay.vertical.html")
                    return nothing
                end

                nested_test("legend") do
                    graph.configuration.show_legend = true
                    test_html(graph, "distributions.violin.overlay.legend.html")
                    return nothing
                end
            end
        end

        nested_test("curve") do
            graph.configuration.distribution.show_box = false
            graph.configuration.distribution.show_curve = true

            nested_test("()") do
                test_html(graph, "distributions.curve.html")
                return nothing
            end

            nested_test("!distributions_gap") do
                graph.configuration.distributions_gap = 0
                println("Ignore the following warning:")
                test_html(graph, "distributions.curve.!distributions_gap.html")
                return nothing
            end

            nested_test("vertical") do
                graph.configuration.distribution.values_orientation = VerticalValues
                test_html(graph, "distributions.curve.vertical.html")
                return nothing
            end

            nested_test("overlay") do
                graph.configuration.overlay_distributions = true

                nested_test("()") do
                    test_html(graph, "distributions.curve.overlay.html")
                    return nothing
                end

                nested_test("vertical") do
                    graph.configuration.distribution.values_orientation = VerticalValues
                    test_html(graph, "distributions.curve.overlay.vertical.html")
                    return nothing
                end

                nested_test("legend") do
                    graph.configuration.show_legend = true
                    test_html(graph, "distributions.curve.overlay.legend.html")
                    return nothing
                end
            end
        end

        nested_test("log") do
            graph.configuration.value_axis.log_regularization = 0
            test_html(graph, "distributions.log.html")
            return nothing
        end

        nested_test("colors") do
            graph.data.distributions_colors = ["red", "green"]
            test_html(graph, "distributions.box.colors.html")
            return nothing
        end

        nested_test("titles") do
            graph.data.distributions_names = ["Foo", "Bar"]
            graph.data.value_axis_title = "Value"
            graph.data.trace_axis_title = "Trace"
            graph.data.graph_title = "Graph"
            graph.data.legend_title = "Traces"
            test_html(graph, "distributions.box.titles.html")
            return nothing
        end

        nested_test("legend") do
            graph.configuration.show_legend = true
            test_html(graph, "distributions.box.legend.html")
            return nothing
        end

        nested_test("legend&titles") do
            graph.data.distributions_names = ["Foo", "Bar"]
            graph.data.value_axis_title = "Value"
            graph.data.trace_axis_title = "Trace"
            graph.data.graph_title = "Graph"
            graph.data.legend_title = "Traces"
            graph.configuration.show_legend = true
            test_html(graph, "distributions.box.legend&titles.html")
            return nothing
        end
    end

    nested_test("line") do
        graph = line_graph(; points_xs = [0.0, 1.0, 2.0], points_ys = [-0.2, 1.2, 1.8])

        nested_test("invalid") do
            nested_test("!line_width") do
                graph.configuration.line.width = 0
                @test_throws "non-positive configuration.line.width: 0" graph.figure
            end

            nested_test("!line_is_filled") do
                graph.configuration.line.width = nothing
                @test_throws "either configuration.line.width or configuration.line.is_filled must be specified" graph.figure
            end

            nested_test("~ys") do
                push!(graph.data.points_ys, 2.0)
                @test_throws dedent("""
                    the data.points_xs size: 3
                    is different from the data.points_ys size: 4
                """) graph.figure
            end
        end

        nested_test("()") do
            test_html(graph, "line.html")
            return nothing
        end

        nested_test("dash") do
            graph.configuration.line.is_dashed = true
            test_html(graph, "line.dash.html")
            return nothing
        end

        nested_test("size") do
            graph.configuration.line.width = 5
            test_html(graph, "line.size.html")
            return nothing
        end

        nested_test("color") do
            graph.configuration.line.color = "red"
            test_html(graph, "line.color.html")
            return nothing
        end

        nested_test("fill_below") do
            graph.configuration.line.is_filled = true
            test_html(graph, "line.fill_below.html")
            return nothing
        end

        nested_test("fill_below!line") do
            graph.configuration.line.width = nothing
            graph.configuration.line.is_filled = true
            test_html(graph, "line.fill_below!line.html")
            return nothing
        end

        nested_test("!grid") do
            graph.configuration.graph.show_grid = false
            graph.configuration.graph.show_ticks = false
            test_html(graph, "line.!grid.html")
            return nothing
        end

        nested_test("vertical_lines") do
            graph.configuration.vertical_bands.low.offset = 0.75
            graph.configuration.vertical_bands.middle.offset = 1.25
            graph.configuration.vertical_bands.high.offset = 1.5

            nested_test("()") do
                test_html(graph, "line.vertical_lines.html")
                return nothing
            end

            nested_test("colors") do
                graph.configuration.vertical_bands.low.color = "green"
                graph.configuration.vertical_bands.middle.color = "red"
                graph.configuration.vertical_bands.high.color = "blue"
                test_html(graph, "line.vertical_lines.colors.html")
                return nothing
            end

            nested_test("!colors") do
                graph.configuration.vertical_bands.low.color = "green"
                graph.configuration.vertical_bands.middle.color = "oobleck"
                graph.configuration.vertical_bands.high.color = "blue"
                @test_throws "invalid configuration.vertical_bands.middle.color: oobleck" graph.figure
            end

            nested_test("legend") do
                graph.configuration.vertical_bands.show_legend = true
                test_legend(graph, "line.vertical_lines") do
                    graph.data.vertical_bands.legend_title = "Vertical"
                    graph.data.vertical_bands.low_title = "Left"
                    graph.data.vertical_bands.middle_title = "Middle"
                    graph.data.vertical_bands.high_title = "Right"
                    return nothing
                end
            end
        end

        nested_test("vertical_fills") do
            graph.configuration.vertical_bands.low.is_filled = true
            graph.configuration.vertical_bands.middle.is_filled = true
            graph.configuration.vertical_bands.high.is_filled = true

            graph.configuration.vertical_bands.low.width = nothing
            graph.configuration.vertical_bands.middle.width = nothing
            graph.configuration.vertical_bands.high.width = nothing

            graph.configuration.vertical_bands.low.color = "green"
            graph.configuration.vertical_bands.middle.color = "red"
            graph.configuration.vertical_bands.high.color = "blue"

            graph.configuration.vertical_bands.low.offset = 0.75
            graph.configuration.vertical_bands.high.offset = 1.5

            nested_test("()") do
                test_html(graph, "line.vertical_fills.html")
                return nothing
            end

            nested_test("legend") do
                graph.configuration.vertical_bands.show_legend = true
                test_legend(graph, "line.vertical_fills") do
                    graph.data.vertical_bands.legend_title = "Vertical"
                    graph.data.vertical_bands.low_title = "Left"
                    graph.data.vertical_bands.middle_title = "Middle"
                    graph.data.vertical_bands.high_title = "Right"
                    return nothing
                end
            end
        end

        nested_test("horizontal_lines") do
            graph.configuration.horizontal_bands.low.offset = 0.75
            graph.configuration.horizontal_bands.middle.offset = 1.25
            graph.configuration.horizontal_bands.high.offset = 1.5

            nested_test("()") do
                test_html(graph, "line.horizontal_lines.html")
                return nothing
            end

            nested_test("legend") do
                graph.configuration.horizontal_bands.show_legend = true
                test_legend(graph, "line.horizontal_lines") do
                    graph.data.horizontal_bands.legend_title = "Horizontal"
                    graph.data.horizontal_bands.low_title = "Low"
                    graph.data.horizontal_bands.middle_title = "Middle"
                    graph.data.horizontal_bands.high_title = "High"
                    return nothing
                end
            end
        end

        nested_test("horizontal_fills") do
            graph.configuration.horizontal_bands.low.is_filled = true
            graph.configuration.horizontal_bands.middle.is_filled = true
            graph.configuration.horizontal_bands.high.is_filled = true

            graph.configuration.horizontal_bands.low.color = "#0000ff"
            graph.configuration.horizontal_bands.middle.color = "#00ff00"
            graph.configuration.horizontal_bands.high.color = "#ff0000"

            graph.configuration.horizontal_bands.low.offset = 0.75
            graph.configuration.horizontal_bands.high.offset = 1.5

            nested_test("()") do
                test_html(graph, "line.horizontal_fills.html")
                return nothing
            end

            nested_test("legend") do
                nested_test("()") do
                    graph.configuration.horizontal_bands.show_legend = true
                    test_legend(graph, "line.horizontal_fills") do
                        graph.data.horizontal_bands.legend_title = "Horizontal"
                        graph.data.horizontal_bands.low_title = "Low"
                        graph.data.horizontal_bands.middle_title = "Middle"
                        graph.data.horizontal_bands.high_title = "High"
                        return nothing
                    end
                end

                nested_test("mix") do
                    graph.configuration.horizontal_bands.show_legend = true
                    graph.configuration.horizontal_bands.middle.is_filled = false
                    graph.configuration.horizontal_bands.middle.color = nothing
                    graph.configuration.horizontal_bands.middle.offset = 1.25
                    test_legend(graph, "line.horizontal_mix") do
                        graph.data.horizontal_bands.legend_title = "Horizontal"
                        graph.data.horizontal_bands.low_title = "Low"
                        graph.data.horizontal_bands.middle_title = "Middle"
                        graph.data.horizontal_bands.high_title = "High"
                        return nothing
                    end
                end

                nested_test("part") do
                    graph.configuration.horizontal_bands.show_legend = true
                    graph.configuration.horizontal_bands.middle.is_filled = false
                    test_legend(graph, "line.horizontal_part") do
                        graph.data.horizontal_bands.legend_title = "Horizontal"
                        graph.data.horizontal_bands.low_title = "Low"
                        graph.data.horizontal_bands.middle_title = "Middle"
                        graph.data.horizontal_bands.high_title = "High"
                        return nothing
                    end
                end
            end
            return nothing
        end

        nested_test("titles") do
            graph.data.graph_title = "Graph"
            graph.data.x_axis_title = "X"
            graph.data.y_axis_title = "Y"
            test_html(graph, "line.titles.html")
            return nothing
        end
    end

    nested_test("lines") do
        graph = lines_graph(;
            lines_xs = [[0.0, 1.0, 2.0], [0.25, 0.5, 1.5, 2.5]],
            lines_ys = [[-0.2, 1.2, 1.8], [0.1, 1.0, 0.5, 2.0]],
        )

        nested_test("()") do
            test_html(graph, "lines.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!lines") do
                empty!(graph.data.lines_xs)
                empty!(graph.data.lines_ys)
                @test_throws "empty data.lines_xs and data.lines_ys vectors" graph.figure
            end

            nested_test("~ys") do
                push!(graph.data.lines_ys, [2.0])
                @test_throws dedent("""
                    the data.lines_xs size: 2
                    is different from the data.lines_ys size: 3
                """) graph.figure
            end

            nested_test("~points") do
                push!(graph.data.lines_ys[2], 1.0)
                @test_throws dedent("""
                    the data.lines_xs[2] size: 4
                    is different from the data.lines_ys[2] size: 5
                """) graph.figure
            end

            nested_test("~xs") do
                empty!(graph.data.lines_xs[1])
                empty!(graph.data.lines_ys[1])
                @test_throws "too few points in data.lines_xs[1] and data.lines_ys[1]: 0" graph.figure
            end

            nested_test("~names") do
                graph.data.lines_names = ["Foo"]
                @test_throws dedent("""
                    the data.lines_names size: 1
                    is different from the data.lines_xs and data.lines_ys size: 2
                """) graph.figure
            end

            nested_test("!colors") do
                graph.data.lines_colors = ["red", "oobleck"]
                @test_throws "invalid data.lines_colors[2]: oobleck" graph.figure
            end

            nested_test("~colors") do
                graph.data.lines_colors = ["red"]
                @test_throws dedent("""
                    the data.lines_colors size: 1
                    is different from the data.lines_xs and data.lines_ys size: 2
                """) graph.figure
            end

            nested_test("~sizes") do
                graph.data.lines_widths = [1]
                @test_throws dedent("""
                    the data.lines_widths size: 1
                    is different from the data.lines_xs and data.lines_ys size: 2
                """) graph.figure
            end

            nested_test("!sizes") do
                graph.data.lines_widths = [1, -1]
                @test_throws "non-positive data.lines_widths[2]: -1" graph.figure
            end

            nested_test("!fill_below") do
                graph.configuration.line.width = nothing
                @test_throws "either configuration.line.width or configuration.line.is_filled must be specified" graph.figure
            end

            nested_test("~fills") do
                graph.data.lines_are_filled = [true]
                @test_throws dedent("""
                    the data.lines_are_filled size: 1
                    is different from the data.lines_xs and data.lines_ys size: 2
                """) graph.figure
            end

            nested_test("~dashs") do
                graph.data.lines_are_dashed = [true]
                @test_throws dedent("""
                    the data.lines_are_dashed size: 1
                    is different from the data.lines_xs and data.lines_ys size: 2
                """) graph.figure
            end
        end

        nested_test("size") do
            graph.configuration.line.width = 4
            test_html(graph, "lines.size.html")
            return nothing
        end

        nested_test("sizes") do
            graph.data.lines_widths = [4, 8]
            test_html(graph, "lines.sizes.html")
            return nothing
        end

        nested_test("color") do
            graph.configuration.line.color = "red"
            test_html(graph, "lines.color.html")
            return nothing
        end

        nested_test("colors") do
            graph.data.lines_colors = ["red", "green"]
            test_html(graph, "lines.colors.html")
            return nothing
        end

        nested_test("dash") do
            graph.configuration.line.is_dashed = true
            test_html(graph, "lines.dash.html")
            return nothing
        end

        nested_test("dashs") do
            graph.data.lines_are_dashed = [true, false]
            test_html(graph, "lines.dashs.html")
            return nothing
        end

        nested_test("fill") do
            graph.configuration.line.is_filled = true

            nested_test("()") do
                test_html(graph, "lines.fill.html")
                return nothing
            end

            nested_test("!line") do
                graph.configuration.line.width = nothing
                test_html(graph, "lines.fill.!line.html")
                return nothing
            end
        end

        nested_test("fills") do
            graph.data.lines_are_filled = [true, false]
            test_html(graph, "lines.fills.html")
            return nothing
        end

        nested_test("stack") do
            nested_test("values") do
                graph.configuration.stacking_normalization = NormalizeToValues
                test_html(graph, "lines.stack.values.html")
                return nothing
            end

            nested_test("percents") do
                graph.data.lines_ys[1][1] = 0.2
                graph.configuration.stacking_normalization = NormalizeToPercents
                test_html(graph, "lines.stack.percents.html")
                return nothing
            end

            nested_test("fractions") do
                graph.data.lines_ys[1][1] = 0.2
                graph.configuration.stacking_normalization = NormalizeToFractions
                test_html(graph, "lines.stack.fractions.html")
                return nothing
            end
        end

        nested_test("vertical_lines") do
            graph.configuration.vertical_bands.low.offset = 0.75
            graph.configuration.vertical_bands.middle.offset = 1.25
            graph.configuration.vertical_bands.high.offset = 1.5

            nested_test("()") do
                test_html(graph, "lines.vertical_lines.html")
                return nothing
            end

            nested_test("colors") do
                graph.configuration.vertical_bands.low.color = "green"
                graph.configuration.vertical_bands.middle.color = "red"
                graph.configuration.vertical_bands.high.color = "blue"
                test_html(graph, "lines.vertical_lines.colors.html")
                return nothing
            end

            nested_test("!colors") do
                graph.configuration.vertical_bands.low.color = "green"
                graph.configuration.vertical_bands.middle.color = "oobleck"
                graph.configuration.vertical_bands.high.color = "blue"
                @test_throws "invalid configuration.vertical_bands.middle.color: oobleck" graph.figure
            end

            nested_test("legend") do
                graph.configuration.vertical_bands.show_legend = true
                test_legend(graph, "lines.vertical_lines") do
                    graph.data.vertical_bands.legend_title = "Vertical"
                    graph.data.vertical_bands.low_title = "Left"
                    graph.data.vertical_bands.middle_title = "Middle"
                    graph.data.vertical_bands.high_title = "Right"
                    return nothing
                end
            end
        end

        nested_test("vertical_fills") do
            graph.configuration.vertical_bands.low.is_filled = true
            graph.configuration.vertical_bands.middle.is_filled = true
            graph.configuration.vertical_bands.high.is_filled = true

            graph.configuration.vertical_bands.low.width = nothing
            graph.configuration.vertical_bands.middle.width = nothing
            graph.configuration.vertical_bands.high.width = nothing

            graph.configuration.vertical_bands.low.color = "green"
            graph.configuration.vertical_bands.middle.color = "red"
            graph.configuration.vertical_bands.high.color = "blue"

            graph.configuration.vertical_bands.low.offset = 0.75
            graph.configuration.vertical_bands.high.offset = 1.5

            nested_test("()") do
                test_html(graph, "lines.vertical_fills.html")
                return nothing
            end

            nested_test("legend") do
                graph.configuration.vertical_bands.show_legend = true
                test_legend(graph, "lines.vertical_fills") do
                    graph.data.vertical_bands.legend_title = "Vertical"
                    graph.data.vertical_bands.low_title = "Left"
                    graph.data.vertical_bands.middle_title = "Middle"
                    graph.data.vertical_bands.high_title = "Right"
                    return nothing
                end
            end
        end

        nested_test("horizontal_lines") do
            graph.configuration.horizontal_bands.low.offset = 0.75
            graph.configuration.horizontal_bands.middle.offset = 1.25
            graph.configuration.horizontal_bands.high.offset = 1.5
            nested_test("()") do
                test_html(graph, "lines.horizontal_lines.html")
                return nothing
            end

            nested_test("legend") do
                graph.configuration.horizontal_bands.show_legend = true
                test_legend(graph, "lines.horizontal_lines") do
                    graph.data.horizontal_bands.legend_title = "Horizontal"
                    graph.data.horizontal_bands.low_title = "Low"
                    graph.data.horizontal_bands.middle_title = "Middle"
                    graph.data.horizontal_bands.high_title = "High"
                    return nothing
                end
            end
        end

        nested_test("horizontal_fills") do
            graph.configuration.horizontal_bands.low.is_filled = true
            graph.configuration.horizontal_bands.middle.is_filled = true
            graph.configuration.horizontal_bands.high.is_filled = true

            graph.configuration.horizontal_bands.low.width = nothing
            graph.configuration.horizontal_bands.middle.width = nothing
            graph.configuration.horizontal_bands.high.width = nothing

            graph.configuration.horizontal_bands.low.color = "#0000ff"
            graph.configuration.horizontal_bands.middle.color = "#00ff00"
            graph.configuration.horizontal_bands.high.color = "#ff0000"

            graph.configuration.horizontal_bands.low.offset = 0.75
            graph.configuration.horizontal_bands.high.offset = 1.5

            nested_test("()") do
                test_html(graph, "lines.horizontal_fills.html")
                return nothing
            end

            nested_test("legend") do
                graph.configuration.horizontal_bands.show_legend = true
                test_legend(graph, "lines.horizontal_fills") do
                    graph.data.horizontal_bands.legend_title = "Horizontal"
                    graph.data.horizontal_bands.low_title = "Low"
                    graph.data.horizontal_bands.middle_title = "Middle"
                    graph.data.horizontal_bands.high_title = "High"
                    return nothing
                end
            end
        end

        nested_test("legend") do
            graph.configuration.show_legend = true

            nested_test("()") do
                test_legend(graph, "lines") do
                    graph.data.legend_title = "Lines"
                    return nothing
                end
                return nothing
            end

            nested_test("names") do
                graph.data.lines_names = ["Foo", "Bar"]
                test_legend(graph, "lines.names") do
                    graph.data.legend_title = "Lines"
                    return nothing
                end
                return nothing
            end
        end
    end

    nested_test("cdf") do
        graph = cdf_graph(;
            cdf_values = [
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

        nested_test("()") do
            test_html(graph, "cdf.html")
            return nothing
        end

        nested_test("~values") do
            empty!(graph.data.cdf_values)
            @test_throws "too few data.cdf_values: 0" graph.figure
        end

        nested_test("vertical") do
            graph.configuration.values_orientation = VerticalValues
            graph.configuration.value_bands.middle.offset = 110
            graph.configuration.fraction_bands.middle.offset = 0.5
            graph.configuration.fraction_bands.middle.is_dashed = true
            test_html(graph, "cdf.vertical.html")
            return nothing
        end

        nested_test("percent") do
            graph.configuration.fractions_normalization = NormalizeToPercents
            graph.configuration.value_bands.middle.offset = 110
            graph.configuration.fraction_bands.middle.offset = 0.5
            graph.configuration.fraction_bands.middle.is_dashed = true
            test_html(graph, "cdf.percent.html")
            return nothing
        end

        nested_test("values") do
            graph.configuration.fractions_normalization = NormalizeToValues
            graph.configuration.value_bands.middle.offset = 110
            graph.configuration.fraction_bands.middle.offset = 0.5
            graph.configuration.fraction_bands.middle.is_dashed = true
            test_html(graph, "cdf.values.html")
            return nothing
        end

        nested_test("downto") do
            graph.configuration.cdf_direction = CdfDownToValue
            test_html(graph, "cdf.downto.html")
            return nothing
        end
    end

    nested_test("cdfs") do
        graph = cdfs_graph(;
            cdfs_values = [
                #! format: off
                [
                    0.75, 5.25, 5.5, 6, 6.2, 6.6, 6.80, 7.0, 7.2, 7.5, 7.5, 7.75, 8.15, 8.15, 8.65, 8.93, 9.2, 9.5, 10,
                    10.25, 11.5, 12, 16, 20.90, 22.3, 23.25,
                ], [
                    79, 54, 74, 62, 85, 55, 88, 85, 51, 85, 54, 84, 78, 47, 83, 52, 62, 84, 52, 79, 51, 47, 78, 69, 74,
                    83, 55, 76, 78, 79, 73, 77, 66, 80, 74, 52, 48, 80, 59, 90, 80, 58, 84, 58, 73, 83, 64, 53, 82, 59,
                    75, 90, 54, 80, 54, 83, 71, 64, 77, 81, 59, 84, 48, 82, 60, 92, 78, 78, 65, 73, 82, 56, 79, 71, 62,
                    76, 60, 78, 76, 83, 75, 82, 70, 65, 73, 88, 76, 80, 48, 86, 60, 90, 50, 78, 63, 72, 84, 75, 51, 82,
                    62, 88, 49, 83, 81, 47, 84, 52, 86, 81, 75, 59, 89, 79, 59, 81, 50, 85, 59, 87, 53, 69, 77, 56, 88,
                    81, 45, 82, 55, 90, 45, 83, 56, 89, 46, 82, 51, 86, 53, 79, 81, 60, 82, 77, 76, 59, 80, 49, 96, 53,
                    77, 77, 65, 81, 71, 70, 81, 93, 53, 89, 45, 86, 58, 78, 66, 76, 63, 88, 52, 93, 49, 57, 77, 68, 81,
                    81, 73, 50, 85, 74, 55, 77, 83, 83, 51, 78, 84, 46, 83, 55, 81, 57, 76, 84, 77, 81, 87, 77, 51, 78,
                    60, 82, 91, 53, 78, 46, 77, 84, 49, 83, 71, 80, 49, 75, 64, 76, 53, 94, 55, 76, 50, 82, 54, 75, 78,
                    79, 78, 78, 70, 79, 70, 54, 86, 50, 90, 54, 54, 77, 79, 64, 75, 47, 86, 63, 85, 82, 57, 82, 67, 74,
                    54, 83, 73, 73, 88, 80, 71, 83, 56, 79, 78, 84, 58, 83, 43, 60, 75, 81, 46, 90, 46, 74, 150,
                ] ./ 10.0,
                #! format: on
            ],
        )

        nested_test("()") do
            test_html(graph, "cdfs.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("~values") do
                empty!(graph.data.cdfs_values)
                @test_throws "empty data.cdfs_values vector" graph.figure
            end

            nested_test("!values") do
                empty!(graph.data.cdfs_values[2])
                @test_throws "too few data.cdfs_values[2]: 0" graph.figure
            end
        end

        nested_test("vertical") do
            graph.configuration.values_orientation = VerticalValues
            graph.configuration.value_bands.middle.offset = 11
            graph.configuration.fraction_bands.middle.offset = 0.5
            graph.configuration.fraction_bands.middle.is_dashed = true
            test_html(graph, "cdfs.vertical.html")
            return nothing
        end

        nested_test("percent") do
            graph.configuration.fractions_normalization = NormalizeToPercents
            graph.configuration.value_bands.middle.offset = 11
            graph.configuration.fraction_bands.middle.offset = 0.5
            graph.configuration.fraction_bands.middle.is_dashed = true
            test_html(graph, "cdfs.percent.html")
            return nothing
        end

        nested_test("values") do
            graph.configuration.fractions_normalization = NormalizeToValues
            graph.configuration.value_bands.middle.offset = 11
            graph.configuration.fraction_bands.middle.offset = 0.5
            graph.configuration.fraction_bands.middle.is_dashed = true

            nested_test("!length") do
                @test_throws dedent("""
                    the data.cdfs_values[2] size: 273
                    is different from the data.cdfs_values[1] size: 26
                """) graph.figure
            end

            nested_test("()") do
                resize!(graph.data.cdfs_values[2], length(graph.data.cdfs_values[1]))
                test_html(graph, "cdfs.values.html")
                return nothing
            end
        end

        nested_test("downto") do
            graph.configuration.cdf_direction = CdfDownToValue
            test_html(graph, "cdfs.downto.html")
            return nothing
        end

        nested_test("legend") do
            graph.configuration.show_legend = true
            test_legend(graph, "cdfs") do
                graph.data.legend_title = "Traces"
                return nothing
            end
            return nothing
        end
    end

    nested_test("bar") do
        graph = bar_graph(; bars_values = [-0.2, 1.2, 1.8])

        nested_test("()") do
            test_html(graph, "bar.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!bars_gap") do
                graph.configuration.bars_gap = -1
                @test_throws "non-positive configuration.bars_gap: -1" graph.figure
            end

            nested_test("~bars_gap") do
                graph.configuration.bars_gap = 1
                @test_throws "too-large configuration.bars_gap: 1" graph.figure
            end

            nested_test("~values") do
                empty!(graph.data.bars_values)
                @test_throws "empty data.bars_values vector" graph.figure
            end

            nested_test("~names") do
                graph.data.bars_names = ["Foo"]
                @test_throws dedent("""
                    the data.bars_names size: 1
                    is different from the data.bars_values size: 3
                """) graph.figure
            end

            nested_test("~hovers") do
                graph.data.bars_hovers = ["Foo"]
                @test_throws dedent("""
                    the data.bars_hovers size: 1
                    is different from the data.bars_values size: 3
                """) graph.figure
            end

            nested_test("~colors") do
                graph.data.bars_colors = ["red"]
                @test_throws dedent("""
                    the data.bars_colors size: 1
                    is different from the data.bars_values size: 3
                """) graph.figure
            end

            nested_test("!colors") do
                graph.data.bars_colors = ["red", "oobleck", "blue"]
                @test_throws "invalid data.bars_colors[2]: oobleck" graph.figure
            end
        end

        nested_test("names") do
            graph.data.bars_names = ["Foo", "Bar", "Baz"]
            test_html(graph, "bar.names.html")
            return nothing
        end

        nested_test("titles") do
            graph.data.graph_title = "Graph"
            graph.data.bar_axis_title = "Bars"
            graph.data.value_axis_title = "Values"
            test_html(graph, "bar.titles.html")
            return nothing
        end

        nested_test("horizontal") do
            graph.configuration.values_orientation = HorizontalValues

            nested_test("()") do
                test_html(graph, "bar.horizontal.html")
                return nothing
            end

            nested_test("names") do
                graph.data.bars_names = ["Foo", "Bar", "Baz"]
                test_html(graph, "bar.horizontal.names.html")
                return nothing
            end

            nested_test("titles") do
                graph.data.graph_title = "Graph"
                graph.data.bar_axis_title = "Bars"
                graph.data.value_axis_title = "Values"
                test_html(graph, "bar.horizontal.titles.html")
                return nothing
            end
        end

        nested_test("!bars_gap") do
            graph.configuration.bars_gap = 0
            test_html(graph, "bar.!bars_gap.html")
            return nothing
        end

        nested_test("color") do
            graph.configuration.bars_color = "red"
            test_html(graph, "bar.color.html")
            return nothing
        end

        nested_test("colors") do
            graph.data.bars_colors = ["red", "green", "blue"]
            test_html(graph, "bar.colors.html")
            return nothing
        end

        nested_test("hovers") do
            graph.data.bars_hovers = ["Foo", "Bar", "Baz"]
            test_html(graph, "bar.hovers.html")
            return nothing
        end
    end

    nested_test("bars") do
        graph = bars_graph(; series_values = [[0.0, 1.0, 2.0], [0.2, 1.2, 1.8]])

        nested_test("()") do
            test_html(graph, "bars.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!values") do
                empty!(graph.data.series_values)
                @test_throws "empty data.series_values vector" graph.figure
            end

            nested_test("!!values") do
                empty!(graph.data.series_values[1])
                empty!(graph.data.series_values[2])
                @test_throws "empty data.series_values vectors" graph.figure
            end

            nested_test("~values") do
                push!(graph.data.series_values[1], 0.0)
                @test_throws dedent("""
                    the data.series_values[2] size: 3
                    is different from the data.series_values[1] size: 4
                """) graph.figure
            end

            nested_test("~bars_names") do
                graph.data.bars_names = ["Foo"]
                @test_throws dedent("""
                    the data.bars_names size: 1
                    is different from the data.series_values[:] size: 3
                """) graph.figure
            end

            nested_test("~series_names") do
                graph.data.series_names = ["Foo"]
                @test_throws dedent("""
                    the data.series_names size: 1
                    is different from the data.series_values size: 2
                """) graph.figure
            end

            nested_test("~series_hovers") do
                graph.data.series_hovers = ["Foo"]
                @test_throws dedent("""
                    the data.series_hovers size: 1
                    is different from the data.series_values size: 2
                """) graph.figure
            end

            nested_test("~bars_hovers") do
                graph.data.bars_hovers = ["Foo"]
                @test_throws dedent("""
                    the data.bars_hovers size: 1
                    is different from the data.series_values[:] size: 3
                """) graph.figure
            end

            nested_test("~colors") do
                graph.data.series_colors = ["red"]
                @test_throws dedent("""
                    the data.series_colors size: 1
                    is different from the data.series_values size: 2
                """) graph.figure
            end

            nested_test("!colors") do
                graph.data.series_colors = ["red", "oobleck"]
                @test_throws "invalid data.series_colors[2]: oobleck" graph.figure
            end
        end

        nested_test("stack") do
            nested_test("values") do
                graph.configuration.stacking_normalization = NormalizeToValues
                test_html(graph, "bars.stack.values.html")
                return nothing
            end

            nested_test("percents") do
                graph.configuration.stacking_normalization = NormalizeToPercents
                test_html(graph, "bars.stack.percents.html")
                return nothing
            end

            nested_test("fractions") do
                graph.configuration.stacking_normalization = NormalizeToFractions
                test_html(graph, "bars.stack.fractions.html")
                return nothing
            end
        end

        nested_test("!bars_gap") do
            graph.configuration.bars_gap = 0
            test_html(graph, "bars.!bars_gap.html")
            return nothing
        end

        nested_test("legend") do
            graph.configuration.show_legend = true
            test_legend(graph, "bars") do
                graph.data.legend_title = "Series"
                return nothing
            end
        end

        nested_test("names") do
            graph.data.series_names = ["Foo", "Bar"]

            nested_test("()") do
                test_html(graph, "bars.names.html")
                return nothing
            end

            nested_test("legend") do
                graph.configuration.show_legend = true
                test_legend(graph, "bars.names") do
                    graph.data.legend_title = "Series"
                    return nothing
                end
            end
        end

        nested_test("bars_names") do
            graph.data.bars_names = ["Foo", "Bar", "Baz"]
            test_html(graph, "bars.bar_names.html")
            return nothing
        end

        nested_test("titles") do
            graph.data.graph_title = "Graph"
            graph.data.bar_axis_title = "Bars"
            graph.data.value_axis_title = "Values"
            test_html(graph, "bars.titles.html")
            return nothing
        end

        nested_test("horizontal") do
            graph.configuration.values_orientation = HorizontalValues

            nested_test("()") do
                test_html(graph, "bars.horizontal.html")
                return nothing
            end

            nested_test("names") do
                graph.data.series_names = ["Foo", "Bar"]
                test_html(graph, "bars.horizontal.names.html")
                return nothing
            end

            nested_test("bars_names") do
                graph.data.bars_names = ["Foo", "Bar", "Baz"]
                test_html(graph, "bars.horizontal.bar_names.html")
                return nothing
            end

            nested_test("titles") do
                graph.data.graph_title = "Graph"
                graph.data.bar_axis_title = "Bars"
                graph.data.value_axis_title = "Values"
                test_html(graph, "bars.horizontal.titles.html")
                return nothing
            end
        end

        nested_test("colors") do
            graph.data.series_colors = ["red", "green"]
            test_html(graph, "bars.colors.html")
            return nothing
        end

        nested_test("hovers") do
            nested_test("series") do
                graph.data.series_hovers = ["Foo", "Bar"]
                test_html(graph, "bars.hovers.series.html")
                return nothing
            end

            nested_test("bars") do
                graph.data.bars_hovers = ["Foo", "Bar", "Baz"]
                test_html(graph, "bars.hovers.bars.html")
                return nothing
            end

            nested_test("both") do
                graph.data.series_hovers = ["Foo", "Bar"]
                graph.data.bars_hovers = ["Baz", "Vaz", "Var"]
                test_html(graph, "bars.hovers.both.html")
                return nothing
            end
        end
    end

    nested_test("points") do
        graph = points_graph(; points_xs = [0.0, 1.0, 2.0], points_ys = [-0.2, 1.2, 1.8])

        nested_test("()") do
            test_html(graph, "points.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!size") do
                graph.configuration.points.size = 0
                @test_throws "non-positive configuration.points.size: 0" graph.figure
            end

            nested_test("!line-width") do
                graph.configuration.diagonal_bands.middle.width = 0
                @test_throws "non-positive configuration.diagonal_bands.middle.width: 0" graph.figure
            end

            nested_test("~ys") do
                push!(graph.data.points_ys, 2.0)
                @test_throws dedent("""
                    the data.points_xs size: 3
                    is different from the data.points_ys size: 4
                """) graph.figure
            end

            nested_test("!colors") do
                graph.configuration.points.show_color_scale = true
                @test_throws "no data.points_colors specified for configuration.points.show_color_scale" graph.figure
            end

            nested_test("~colors") do
                graph.data.points_colors = ["Red"]
                @test_throws dedent("""
                    the data.points_colors size: 1
                    is different from the data.points_xs and data.points_ys size: 3
                """) graph.figure
            end

            nested_test("!borders_colors") do
                graph.configuration.borders.show_color_scale = true
                @test_throws "no data.borders_colors specified for configuration.borders.show_color_scale" graph.figure
            end

            nested_test("~borders_colors") do
                graph.data.borders_colors = ["Red"]
                @test_throws dedent("""
                    the data.borders_colors size: 1
                    is different from the data.points_xs and data.points_ys size: 3
                """) graph.figure
            end

            nested_test("~sizes") do
                graph.data.points_sizes = [1.0, 2.0, 3.0, 4.0]
                @test_throws dedent("""
                    the data.points_sizes size: 4
                    is different from the data.points_xs and data.points_ys size: 3
                """) graph.figure
            end

            nested_test("~borders_sizes") do
                graph.data.borders_sizes = [1.0, 2.0, 3.0, 4.0]
                @test_throws dedent("""
                    the data.borders_sizes size: 4
                    is different from the data.points_xs and data.points_ys size: 3
                """) graph.figure
            end

            nested_test("!sizes") do
                graph.data.points_sizes = [1.0, -1.0, 3.0]
                @test_throws "negative data.points_sizes[2]: -1.0" graph.figure
            end

            nested_test("!borders_sizes") do
                graph.data.borders_sizes = [1.0, -1.0, 3.0]
                @test_throws "negative data.borders_sizes[2]: -1.0" graph.figure
            end

            nested_test("~hovers") do
                graph.data.points_hovers = ["Foo"]
                @test_throws dedent("""
                    the data.points_hovers size: 1
                    is different from the data.points_xs and data.points_ys size: 3
                """) graph.figure
            end
        end

        nested_test("invalid") do
            nested_test("!low") do
                graph.configuration.diagonal_bands.low.offset = 0.1
                graph.configuration.diagonal_bands.middle.offset = 0
                graph.configuration.diagonal_bands.high.offset = 0.3

                @test_throws dedent("""
                    configuration.diagonal_bands.low.offset: 0.1
                    is not less than configuration.diagonal_bands.middle.offset: 0
                """) graph.figure
                return nothing
            end

            nested_test("!high") do
                graph.configuration.diagonal_bands.low.offset = -0.3
                graph.configuration.diagonal_bands.middle.offset = 0
                graph.configuration.diagonal_bands.high.offset = -0.1

                @test_throws dedent("""
                    configuration.diagonal_bands.high.offset: -0.1
                    is not greater than configuration.diagonal_bands.middle.offset: 0
                """) graph.figure
                return nothing
            end

            nested_test("!middle") do
                graph.configuration.diagonal_bands.low.offset = 0.3
                graph.configuration.diagonal_bands.high.offset = -0.3

                @test_throws dedent("""
                    configuration.diagonal_bands.low.offset: 0.3
                    is not less than configuration.diagonal_bands.high.offset: -0.3
                """) graph.figure
                return nothing
            end
        end

        nested_test("diagonal") do
            nested_test("()") do
                graph.configuration.diagonal_bands.low.offset = -0.3
                graph.configuration.diagonal_bands.high.offset = 0.3
                graph.configuration.diagonal_bands.middle.offset = 0

                graph.configuration.diagonal_bands.middle.width = 8

                test_html(graph, "points.diagonal.html")
                return nothing
            end

            nested_test("low_fills") do
                graph.configuration.diagonal_bands.low.is_filled = true
                graph.configuration.diagonal_bands.middle.is_filled = true
                graph.configuration.diagonal_bands.high.is_filled = true

                graph.configuration.diagonal_bands.low.width = nothing
                graph.configuration.diagonal_bands.middle.width = nothing
                graph.configuration.diagonal_bands.high.width = nothing

                graph.configuration.diagonal_bands.low.color = "#0000ff"
                graph.configuration.diagonal_bands.middle.color = "#00ff00"
                graph.configuration.diagonal_bands.high.color = "#ff0000"

                graph.configuration.diagonal_bands.low.offset = -0.6
                graph.configuration.diagonal_bands.high.offset = -0.3

                test_html(graph, "points.diagonal.low_fills.html")
                return nothing
            end

            nested_test("high_fills") do
                graph.configuration.diagonal_bands.low.is_filled = true
                graph.configuration.diagonal_bands.middle.is_filled = true
                graph.configuration.diagonal_bands.high.is_filled = true

                graph.configuration.diagonal_bands.low.width = nothing
                graph.configuration.diagonal_bands.middle.width = nothing
                graph.configuration.diagonal_bands.high.width = nothing

                graph.configuration.diagonal_bands.low.color = "#0000ff"
                graph.configuration.diagonal_bands.middle.color = "#00ff00"
                graph.configuration.diagonal_bands.high.color = "#ff0000"

                graph.configuration.diagonal_bands.low.offset = 0.3
                graph.configuration.diagonal_bands.high.offset = 0.6

                test_html(graph, "points.diagonal.high_fills.html")
                return nothing
            end

            nested_test("middle_fills") do
                graph.configuration.diagonal_bands.low.is_filled = true
                graph.configuration.diagonal_bands.middle.is_filled = true
                graph.configuration.diagonal_bands.high.is_filled = true

                graph.configuration.diagonal_bands.low.offset = -0.3
                graph.configuration.diagonal_bands.high.offset = 0.6

                test_html(graph, "points.diagonal.middle_fills.html")
                return nothing
            end
        end

        nested_test("vertical_lines") do
            graph.configuration.vertical_bands.low.offset = 0.75
            graph.configuration.vertical_bands.middle.offset = 1.25
            graph.configuration.vertical_bands.high.offset = 1.5

            test_html(graph, "points.vertical_lines.html")
            return nothing
        end

        nested_test("vertical_fills") do
            graph.configuration.vertical_bands.low.is_filled = true
            graph.configuration.vertical_bands.middle.is_filled = true
            graph.configuration.vertical_bands.high.is_filled = true

            graph.configuration.vertical_bands.low.width = nothing
            graph.configuration.vertical_bands.middle.width = nothing
            graph.configuration.vertical_bands.high.width = nothing

            graph.configuration.vertical_bands.low.color = "#0000ff"
            graph.configuration.vertical_bands.middle.color = "#00ff00"
            graph.configuration.vertical_bands.high.color = "#ff0000"

            graph.configuration.vertical_bands.low.offset = 0.75
            graph.configuration.vertical_bands.high.offset = 1.5

            test_html(graph, "points.vertical_fills.html")
            return nothing
        end

        nested_test("horizontal_lines") do
            graph.configuration.horizontal_bands.low.offset = 0.75
            graph.configuration.horizontal_bands.middle.offset = 1.25
            graph.configuration.horizontal_bands.high.offset = 1.5

            test_html(graph, "points.horizontal_lines.html")
            return nothing
        end

        nested_test("horizontal_fills") do
            graph.configuration.horizontal_bands.low.is_filled = true
            graph.configuration.horizontal_bands.middle.is_filled = true
            graph.configuration.horizontal_bands.high.is_filled = true

            graph.configuration.horizontal_bands.low.width = nothing
            graph.configuration.horizontal_bands.middle.width = nothing
            graph.configuration.horizontal_bands.high.width = nothing

            graph.configuration.horizontal_bands.low.color = "#0000ff"
            graph.configuration.horizontal_bands.middle.color = "#00ff00"
            graph.configuration.horizontal_bands.high.color = "#ff0000"

            graph.configuration.horizontal_bands.low.offset = 0.75
            graph.configuration.horizontal_bands.high.offset = 1.5

            test_html(graph, "points.horizontal_fills.html")
            return nothing
        end

        nested_test("log") do
            graph.data.points_xs .*= 10
            graph.data.points_ys .*= 10
            graph.data.points_xs .+= 1
            graph.data.points_ys .+= 3
            graph.configuration.x_axis.log_regularization = 0
            graph.configuration.y_axis.log_regularization = 0

            nested_test("invalid") do
                nested_test("!minimum") do
                    graph.configuration.x_axis.minimum = 0.0
                    @test_throws "log of non-positive configuration.x_axis.minimum: 0.0" graph.figure
                end

                nested_test("!maximum") do
                    graph.configuration.y_axis.maximum = -1.0
                    @test_throws "log of non-positive configuration.y_axis.maximum: -1.0" graph.figure
                end

                nested_test("!xs") do
                    graph.data.points_xs[1] = 0
                    @test_throws "log of non-positive data.points_xs[1]: 0.0" graph.figure
                end

                nested_test("!ys") do
                    graph.data.points_ys[1] = -0.2
                    graph.configuration.y_axis.log_regularization = 0
                    @test_throws "log of non-positive data.points_ys[1]: -0.2" graph.figure
                end
            end

            nested_test("()") do
                test_html(graph, "points.log.html")
                return nothing
            end

            nested_test("diagonal") do
                nested_test("invalid") do
                    nested_test("!line_offset") do
                        graph.configuration.x_axis.log_regularization = 0
                        graph.configuration.y_axis.log_regularization = 0
                        graph.configuration.diagonal_bands.low.offset = -1
                        @test_throws "log of non-positive configuration.diagonal_bands.low.offset: -1" graph.figure
                    end

                    nested_test("!log") do
                        graph.configuration.y_axis.log_regularization = nothing
                        graph.configuration.diagonal_bands.middle.offset = 1
                        @test_throws "configuration.diagonal_bands specified for a combination of linear and log scale axes" graph.figure
                        return nothing
                    end
                end

                nested_test("()") do
                    graph.configuration.x_axis.log_regularization = 0
                    graph.configuration.y_axis.log_regularization = 0

                    graph.configuration.diagonal_bands.low.offset = 0.5
                    graph.configuration.diagonal_bands.middle.offset = 1
                    graph.configuration.diagonal_bands.high.offset = 2

                    test_html(graph, "points.log.diagonal.html")
                    return nothing
                end

                nested_test("low_fills") do
                    graph.configuration.diagonal_bands.low.is_filled = true
                    graph.configuration.diagonal_bands.middle.is_filled = true
                    graph.configuration.diagonal_bands.high.is_filled = true

                    graph.configuration.diagonal_bands.low.width = nothing
                    graph.configuration.diagonal_bands.middle.width = nothing
                    graph.configuration.diagonal_bands.high.width = nothing

                    graph.configuration.diagonal_bands.low.color = "#0000ff"
                    graph.configuration.diagonal_bands.middle.color = "#00ff00"
                    graph.configuration.diagonal_bands.high.color = "#ff0000"

                    graph.configuration.diagonal_bands.low.offset = 0.25
                    graph.configuration.diagonal_bands.high.offset = 0.75

                    test_html(graph, "points.log.diagonal.low_fills.html")
                    return nothing
                end

                nested_test("high_fills") do
                    graph.configuration.diagonal_bands.low.is_filled = true
                    graph.configuration.diagonal_bands.middle.is_filled = true
                    graph.configuration.diagonal_bands.high.is_filled = true

                    graph.configuration.diagonal_bands.low.width = nothing
                    graph.configuration.diagonal_bands.middle.width = nothing
                    graph.configuration.diagonal_bands.high.width = nothing

                    graph.configuration.diagonal_bands.low.color = "#0000ff"
                    graph.configuration.diagonal_bands.middle.color = "#00ff00"
                    graph.configuration.diagonal_bands.high.color = "#ff0000"

                    graph.configuration.diagonal_bands.low.offset = 1.25
                    graph.configuration.diagonal_bands.high.offset = 1.75

                    test_html(graph, "points.log.diagonal.high_fills.html")
                    return nothing
                end

                nested_test("middle_fills") do
                    graph.configuration.diagonal_bands.low.is_filled = true
                    graph.configuration.diagonal_bands.middle.is_filled = true
                    graph.configuration.diagonal_bands.high.is_filled = true

                    graph.configuration.diagonal_bands.low.offset = 0.75
                    graph.configuration.diagonal_bands.high.offset = 1.25

                    test_html(graph, "points.log.diagonal.middle_fills.html")
                    return nothing
                end
            end
        end

        nested_test("color") do
            graph.configuration.points.color = "red"

            nested_test("()") do
                test_html(graph, "points.color.html")
                return nothing
            end

            nested_test("!color") do
                graph.configuration.points.color = "oobleck"
                @test_throws "invalid configuration.points.color: oobleck" graph.figure
                return nothing
            end
        end

        nested_test("colors") do
            graph.data.points_colors = ["red", "green", "blue"]

            nested_test("()") do
                test_html(graph, "points.colors.html")
                return nothing
            end

            nested_test("!color") do
                graph.data.points_colors[2] = "oobleck"
                @test_throws "invalid data.points_colors[2]: oobleck" graph.figure
            end

            nested_test("!log") do
                graph.configuration.points.color_scale.log_regularization = 0
                @test_throws "non-real data.points_colors with configuration.points.color_scale.log_regularization" graph.figure
            end

            nested_test("!legend") do
                graph.configuration.points.show_color_scale = true
                @test_throws "explicit data.points_colors specified for configuration.points.show_color_scale" graph.figure
            end
        end

        nested_test("categorical") do
            graph.data.points_colors = ["Foo", "Bar", "Baz"]
            graph.configuration.points.color_palette =
                [("Foo", "red"), ("Bar", "green"), ("Baz", "blue"), ("Vaz", "magenta")]

            nested_test("()") do
                test_html(graph, "points.categorical.html")
                return nothing
            end

            nested_test("!log") do
                graph.data.points_colors = [1.0, 2.0, 3.0]
                graph.configuration.points.color_scale.log_regularization = 0
                @test_throws "non-string data.points_colors for categorical configuration.points.color_palette" graph.figure
            end

            nested_test("~color") do
                graph.configuration.points.color_palette[2] = ("Bar", "oobleck")
                @test_throws "invalid configuration.points.color_palette[2] color: oobleck" graph.figure
            end

            nested_test("!color") do
                graph.data.points_colors = ["Foo", "Faz", "Baz"]
                @test_throws "categorical configuration.points.color_palette does not contain data.points_colors[2]: Faz" graph.figure
            end

            nested_test("!reversed") do
                graph.configuration.points.reverse_color_scale = true
                @test_throws "reversed categorical configuration.points.color_palette" graph.figure
            end

            nested_test("legend") do
                graph.configuration.points.show_color_scale = true
                test_legend(graph, "points.categorical") do
                    graph.data.points_colors_title = "Points"
                    return nothing
                end
                return nothing
            end
        end

        nested_test("continuous") do
            graph.data.points_colors = [0.0, 1.0, 2.0]

            nested_test("linear") do
                nested_test("()") do
                    test_html(graph, "points.continuous.html")
                    return nothing
                end

                nested_test("invalid") do
                    nested_test("!colorscale") do
                        graph.configuration.points.color_palette = Vector{Tuple{Real, String}}()
                        @test_throws "empty configuration.points.color_palette" graph.figure
                        return nothing
                    end

                    nested_test("~colorscale") do
                        graph.configuration.points.color_palette = [(-1.0, "blue"), (-1.0, "red")]
                        @test_throws "single configuration.points.color_palette value: -1.0" graph.figure
                        return nothing
                    end

                    nested_test("!range") do
                        graph.configuration.points.color_scale.minimum = 1.5
                        graph.configuration.points.color_scale.maximum = 0.5
                        @test_throws dedent("""
                            configuration.points.color_scale.maximum: 0.5
                            is not larger than configuration.points.color_scale.minimum: 1.5
                        """) graph.figure
                        return nothing
                    end
                end

                nested_test("range") do
                    graph.configuration.points.color_scale.minimum = 0.5
                    graph.configuration.points.color_scale.maximum = 1.5
                    graph.configuration.points.show_color_scale = true
                    test_html(graph, "points.continuous.range.html")
                    return nothing
                end

                nested_test("viridis") do
                    graph.configuration.points.color_palette = "Viridis"
                    test_html(graph, "points.continuous.viridis.html")
                    return nothing
                end

                nested_test("reversed") do
                    graph.configuration.points.reverse_color_scale = true
                    test_html(graph, "points.continuous.reversed.html")
                    return nothing
                end

                nested_test("legend") do
                    graph.configuration.points.show_color_scale = true
                    test_legend(graph, "points.continuous") do
                        graph.data.points_colors_title = "Points"
                        return nothing
                    end
                    return nothing
                end

                nested_test("gradient") do
                    graph.configuration.points.color_palette = [(-1.0, "blue"), (3.0, "red")]

                    nested_test("()") do
                        test_html(graph, "points.continuous.gradient.html")
                        return nothing
                    end

                    nested_test("reversed") do
                        graph.configuration.points.reverse_color_scale = true
                        test_html(graph, "points.continuous.gradient.reversed.html")
                        return nothing
                    end

                    nested_test("legend") do
                        graph.configuration.points.show_color_scale = true
                        test_legend(graph, "points.gradient") do
                            graph.data.points_colors_title = "Points"
                            return nothing
                        end
                        return nothing
                    end
                end
            end

            nested_test("log") do
                graph.data.points_colors = [0.0, 5.0, 10.0]
                graph.configuration.points.color_scale.log_regularization = 1.0

                nested_test("invalid") do
                    nested_test("!log_color_scale_regularization") do
                        graph.configuration.points.color_scale.log_regularization = -1.0
                        @test_throws "negative configuration.points.color_scale.log_regularization: -1.0" graph.figure
                    end

                    nested_test("!cmin") do
                        graph.configuration.points.color_palette = [(-1.0, "blue"), (1.0, "red")]
                        @test_throws "log of non-positive configuration.points.color_palette[1]: 0.0" graph.figure
                    end

                    nested_test("!colors") do
                        graph.data.points_colors[1] = -2.0
                        @test_throws "log of non-positive data.points_colors[1]: -1.0" graph.figure
                    end

                    nested_test("!minimum") do
                        graph.configuration.points.color_scale.minimum = -1.5
                        @test_throws "log of non-positive configuration.points.color_scale.minimum: -0.5" graph.figure
                        return nothing
                    end

                    nested_test("!minimum") do
                        graph.configuration.points.color_scale.maximum = -1.5
                        @test_throws "log of non-positive configuration.points.color_scale.maximum: -0.5" graph.figure
                        return nothing
                    end
                end

                nested_test("()") do
                    test_html(graph, "points.log.continuous.html")
                    return nothing
                end

                nested_test("viridis") do
                    graph.configuration.points.color_palette = "Viridis"
                    test_html(graph, "points.log.continuous.viridis.html")
                    return nothing
                end

                nested_test("!reversed") do
                    graph.configuration.points.reverse_color_scale = true
                    @test_throws "reversed log configuration.points.color_scale" graph.figure
                end

                nested_test("legend") do
                    graph.configuration.points.show_color_scale = true

                    nested_test("small") do
                        test_legend(graph, "points.log.continuous.small") do
                            graph.data.points_colors_title = "Points"
                            return nothing
                        end
                        return nothing
                    end

                    nested_test("large") do
                        graph.data.points_colors .*= 10
                        graph.data.points_colors[1] += 6
                        test_legend(graph, "points.log.continuous.large") do
                            graph.data.points_colors_title = "Points"
                            return nothing
                        end
                        return nothing
                    end

                    nested_test("huge") do
                        graph.data.points_colors .*= 100
                        test_legend(graph, "points.log.continuous.huge") do
                            graph.data.points_colors_title = "Points"
                            return nothing
                        end
                        return nothing
                    end
                end

                nested_test("gradient") do
                    graph.configuration.points.color_palette = [(0.0, "blue"), (10.0, "red")]

                    nested_test("()") do
                        test_html(graph, "points.log.continuous.gradient.html")
                        return nothing
                    end

                    nested_test("reversed") do
                        graph.configuration.points.reverse_color_scale = true
                        test_html(graph, "points.log.continuous.gradient.reversed.html")
                        return nothing
                    end

                    nested_test("legend") do
                        graph.configuration.points.show_color_scale = true
                        test_legend(graph, "points.log.gradient") do
                            graph.data.points_colors_title = "Points"
                            return nothing
                        end
                        return nothing
                    end
                end
            end
        end

        nested_test("size") do
            graph.configuration.points.size = 10
            test_html(graph, "points.size.html")
            return nothing
        end

        nested_test("sizes") do
            graph.data.points_sizes = [10.0, 25.0, 100.0]

            nested_test("()") do
                test_html(graph, "points.sizes.html")
                return nothing
            end

            nested_test("!range") do
                graph.configuration.points.size_range.smallest = 10.0
                graph.configuration.points.size_range.largest = 2.0
                @test_throws dedent("""
                    configuration.points.size_range.largest: 2.0
                    is not larger than configuration.points.size_range.smallest: 10.0
                """) graph.figure
            end

            nested_test("linear") do
                graph.configuration.points.size_range.smallest = 2.0
                graph.configuration.points.size_range.largest = 10.0
                test_html(graph, "points.sizes.linear.html")
                return nothing
            end

            nested_test("log") do
                graph.configuration.points.size_scale.log_regularization = 0
                test_html(graph, "points.sizes.log.html")
                return nothing
            end

            nested_test("colors") do
                graph.data.points_colors = ["red", "", "blue"]
                test_html(graph, "points.sizes.colors.html")
                return nothing
            end

            nested_test("categorical") do
                graph.data.points_colors = ["Foo", "Bar", "Baz"]
                graph.configuration.points.color_palette = [("Foo", "red"), ("Bar", "green"), ("Baz", "blue")]
                test_html(graph, "points.sizes.categorical.html")
                return nothing
            end

            nested_test("continuous") do
                graph.data.points_colors = [0.0, 1.0, 2.0]
                test_html(graph, "point.sizes.continuous.html")
                return nothing
            end
        end

        nested_test("!grid") do
            graph.configuration.graph.show_grid = false
            test_html(graph, "points.!grid.html")
            return nothing
        end

        nested_test("titles") do
            graph.data.x_axis_title = "X"
            graph.data.y_axis_title = "Y"
            graph.data.graph_title = "Graph"
            test_html(graph, "points.titles.html")
            return nothing
        end

        nested_test("hovers") do
            graph.data.points_hovers = ["<b>Foo</b><br>Low", "<b>Bar</b><br>Middle", "<b>Baz</b><br>High"]
            test_html(graph, "points.hovers.html")
            return nothing
        end

        nested_test("border") do
            graph.configuration.points.size = 6
            graph.configuration.points.color = "black"

            nested_test("sizes") do
                graph.data.borders_sizes = [10.0, 25.0, 100.0]

                nested_test("()") do
                    test_html(graph, "points.border.sizes.html")
                    return nothing
                end

                nested_test("linear") do
                    graph.configuration.borders.size_range.smallest = 2.0
                    graph.configuration.borders.size_range.largest = 10.0
                    test_html(graph, "points.border.sizes.linear.html")
                    return nothing
                end

                nested_test("log") do
                    graph.configuration.borders.size_scale.log_regularization = 0
                    test_html(graph, "points.border.sizes.log.html")
                    return nothing
                end

                nested_test("color") do
                    graph.configuration.borders.color = "red"
                    test_html(graph, "points.border.sizes.color.html")
                    return nothing
                end

                nested_test("colors") do
                    graph.data.borders_colors = ["red", "", "blue"]
                    test_html(graph, "points.border.sizes.colors.html")
                    return nothing
                end

                nested_test("categorical") do
                    graph.data.borders_colors = ["Foo", "Bar", "Baz"]
                    graph.configuration.borders.color_palette = [("Foo", "red"), ("Bar", "green"), ("Baz", "blue")]
                    test_html(graph, "points.border.sizes.categorical.html")
                    return nothing
                end

                nested_test("continuous") do
                    graph.data.borders_colors = [0.0, 1.0, 2.0]
                    test_html(graph, "points.border.sizes.continuous.html")
                    return nothing
                end

                nested_test("!legend") do
                    graph.configuration.borders.show_color_scale = true
                    @test_throws "no data.borders_colors specified for configuration.borders.show_color_scale" graph.figure
                end
            end

            nested_test("colors") do
                graph.data.borders_colors = ["red", "green", "blue"]

                nested_test("()") do
                    test_html(graph, "points.border.colors.html")
                    return nothing
                end

                nested_test("size") do
                    graph.configuration.borders.size = 6
                    test_html(graph, "points.border.colors.size.html")
                    return nothing
                end

                nested_test("!legend") do
                    graph.configuration.borders.show_color_scale = true
                    @test_throws "explicit data.borders_colors specified for configuration.borders.show_color_scale" graph.figure
                end
            end

            nested_test("continuous") do
                graph.data.borders_colors = [0.0, 1.0, 2.0]

                nested_test("()") do
                    test_html(graph, "points.border.continuous.html")
                    return nothing
                end

                nested_test("size") do
                    graph.configuration.borders.size = 6
                    test_html(graph, "points.border.continuous.size.html")
                    return nothing
                end

                nested_test("legend") do
                    graph.configuration.borders.show_color_scale = true

                    test_legend(graph, "points.border.continuous") do
                        graph.data.borders_colors_title = "Borders"
                        return nothing
                    end

                    nested_test("legend") do
                        graph.data.points_colors = [20.0, 10.0, 0.0]
                        graph.configuration.points.color_palette = "Viridis"
                        graph.configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(graph, "points.border.continuous.legend") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            graph.data.borders_colors_title = "Borders"
                            test_legend(graph, "points.border.continuous.legend.title") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end
                    end

                    nested_test("legend1") do
                        graph.data.points_colors = ["Foo", "Bar", "Baz"]
                        graph.configuration.points.color_palette = [("Foo", "red"), ("Bar", "green"), ("Baz", "blue")]
                        graph.configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(graph, "points.border.continuous.legend1") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            graph.data.borders_colors_title = "Borders"
                            test_legend(graph, "points.border.continuous.legend1.title") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end
                    end
                end
            end

            nested_test("categorical") do
                graph.data.borders_colors = ["Foo", "Bar", "Baz"]
                graph.configuration.borders.color_palette =
                    [("Foo", "red"), ("Bar", "green"), ("Baz", "blue"), ("Vaz", "magenta")]

                nested_test("()") do
                    test_html(graph, "points.border.categorical.html")
                    return nothing
                end

                nested_test("legend") do
                    graph.configuration.borders.show_color_scale = true

                    nested_test("()") do
                        test_legend(graph, "points.border.categorical.colors") do
                            graph.data.borders_colors_title = "Borders"
                            return nothing
                        end
                    end

                    nested_test("legend") do
                        graph.data.points_colors = ["X", "Y", "Z"]
                        graph.configuration.points.color_palette = [("X", "cyan"), ("Y", "magenta"), ("Z", "yellow")]
                        graph.configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(graph, "points.border.categorical.legend") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            graph.data.borders_colors_title = "Borders"
                            test_legend(graph, "points.border.categorical.legend.title") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end
                    end

                    nested_test("legend1") do
                        graph.data.points_colors = [20.0, 10.0, 0.0]
                        graph.configuration.points.color_palette = "Viridis"
                        graph.configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(graph, "points.border.categorical.legend1") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            graph.data.borders_colors_title = "Borders"
                            test_legend(graph, "points.border.categorical.legend1.title") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end
                    end
                end
            end
        end

        nested_test("edges") do
            graph.data.edges_points = [(1, 2), (1, 3)]

            nested_test("()") do
                test_html(graph, "points.edges.html")
                return nothing
            end

            nested_test("!over") do
                graph.configuration.edges_over_points = false
                test_html(graph, "points.edges.!over.html")
                return nothing
            end

            nested_test("invalid") do
                nested_test("!from") do
                    graph.data.edges_points[1] = (-1, 2)
                    @test_throws "data.edges_points[1] from invalid point: -1" graph.figure
                end

                nested_test("!to") do
                    graph.data.edges_points[1] = (1, 4)
                    @test_throws "data.edges_points[1] to invalid point: 4" graph.figure
                end

                nested_test("self!") do
                    graph.data.edges_points[1] = (1, 1)
                    @test_throws "data.edges_points[1] from point to itself: 1" graph.figure
                end
            end

            nested_test("size") do
                graph.configuration.edges.size = 8
                test_html(graph, "points.edges.size.html")
                return nothing
            end

            nested_test("sizes") do
                graph.data.edges_sizes = [6, 10]
                test_html(graph, "points.edges.sizes.html")
                return nothing
            end

            nested_test("color") do
                graph.configuration.edges.color = "magenta"
                test_html(graph, "points.edges.color.html")
                return nothing
            end

            nested_test("colors") do
                graph.data.edges_colors = ["red", "green"]
                test_html(graph, "points.edges.colors.html")
                return nothing
            end
        end
    end

    nested_test("grid") do
        graph = grid_graph(; points_colors = [1.0 2.0 3.0; 4.0 5.0 6.0])

        nested_test("()") do
            test_html(graph, "grid.html")
            return nothing
        end

        nested_test("!rows") do
            graph.data.points_colors = zeros(Float32, 0, 3)
            @test_throws "no rows in data.points_colors" graph.figure
        end

        nested_test("!columns") do
            graph.data.points_colors = zeros(Float32, 2, 0)
            @test_throws "no columns in data.points_colors" graph.figure
        end

        nested_test("invalid") do
            nested_test("!sizes!colors") do
                graph.data.points_colors = nothing
                @test_throws "neither data.points_colors nor data.points_sizes specified for grid" graph.figure
            end
        end

        nested_test("legend") do
            graph.configuration.points.show_color_scale = true
            test_legend(graph, "grid") do
                graph.data.points_colors_title = "Grid"
                return nor
            end
        end

        nested_test("colors") do
            graph.data.points_colors = ["red" "green" "blue"; "blue" "green" "red"]
            test_html(graph, "grid.colors.html")
            return nothing
        end

        nested_test("!colors") do
            graph.data.points_colors = ["red" "oobleck" "blue"; "blue" "green" "red"]
            @test_throws "invalid data.points_colors[1,2]: oobleck" graph.figure
        end

        nested_test("~colors") do
            graph.configuration.points.color_palette = [("A", "red"), ("B", "green"), ("C", "blue")]
            @test_throws "non-string data.points_colors for categorical configuration.points.color_palette" graph.figure
        end

        nested_test("categorical") do
            graph.data.points_colors = ["A" "B" "C"; "C" "B" "A"]
            graph.configuration.points.color_palette = [("A", "red"), ("B", "green"), ("C", "blue")]

            nested_test("!scale") do
                test_html(graph, "grid.categorical.html")
                return nothing
            end

            nested_test("!color") do
                graph.data.points_colors[1, 2] = "D"
                @test_throws "categorical configuration.points.color_palette does not contain data.points_colors[1,2)]: D" graph.figure
            end

            nested_test("legend") do
                graph.configuration.points.show_color_scale = true
                test_legend(graph, "grid.categorical") do
                    graph.data.points_colors_title = "Grid"
                    return nothing
                end
            end
        end

        nested_test("sizes") do
            graph.data.points_sizes = (graph.data.points_colors .- 1) .* 10

            nested_test("!sizes") do
                graph.data.points_sizes = transpose(graph.data.points_sizes)
                @test_throws dedent("""
                    the data.points_colors size: (2, 3)
                    is different from the data.points_sizes size: (3, 2)
                """) graph.figure
            end

            nested_test("!scale") do
                graph.data.points_colors = nothing
                graph.configuration.points.show_color_scale = true
                @test_throws "no data.points_colors specified for configuration.points.show_color_scale" graph.figure
            end

            nested_test("~sizes") do
                graph.data.points_sizes[1, 2] = -1.5
                @test_throws "negative data.points_sizes[1,2]: -1.5" graph.figure
            end

            nested_test("!colors") do
                graph.data.points_colors = nothing
                test_html(graph, "grid.sizes.!colors.html")
                return nothing
            end

            nested_test("color") do
                graph.data.points_colors = nothing
                graph.configuration.points.color = "red"
                test_html(graph, "grid.sizes.color.html")
                return nothing
            end

            nested_test("colors") do
                graph.data.points_colors = ["red" "green" ""; "blue" "red" ""]
                test_html(graph, "grid.sizes.colors.html")
                return nothing
            end

            nested_test("categorical") do
                graph.data.points_colors = ["Foo" "Bar" "Baz"; "Baz" "Bar" "Foo"]
                graph.configuration.points.color_palette = [("Foo", "red"), ("Bar", "green"), ("Baz", "blue")]

                nested_test("()") do
                    test_html(graph, "grid.sizes.categorical.html")
                    return nothing
                end

                nested_test("!log") do
                    graph.configuration.points.color_scale.log_regularization = 0
                    @test_throws "non-real data.points_colors with configuration.points.color_scale.log_regularization" graph.figure
                end
            end

            nested_test("continuous") do
                graph.data.points_colors = [0.0 1.0 2.0; 2.0 1.0 0.0]
                test_html(graph, "grid.sizes.continuous.html")
                return nothing
            end

            nested_test("()") do
                test_html(graph, "grid.sizes.html")
                return nothing
            end

            nested_test("linear") do
                graph.configuration.points.size_range.smallest = 2.0
                graph.configuration.points.size_range.largest = 10.0
                test_html(graph, "grid.sizes.linear.html")
                return nothing
            end

            nested_test("log") do
                graph.configuration.points.size_scale.log_regularization = 1
                test_html(graph, "grid.sizes.log.html")
                return nothing
            end
        end

        nested_test("!grid") do
            graph.configuration.graph.show_grid = false
            test_html(graph, "grid.!grid.html")
            return nothing
        end

        nested_test("titles") do
            graph.data.x_axis_title = "X"
            graph.data.y_axis_title = "Y"
            graph.data.graph_title = "Graph"
            graph.data.rows_names = ["A", "B"]
            graph.data.columns_names = ["C", "D", "E"]
            test_html(graph, "grid.titles.html")
            return nothing
        end

        nested_test("hovers") do
            graph.data.points_hovers = ["A" "B" "C"; "D" "E" "F"]
            test_html(graph, "grid.hovers.html")
            return nothing
        end

        nested_test("!hovers") do
            graph.data.points_hovers = transpose(["A" "B" "C"; "D" "E" "F"])
            @test_throws dedent("""
                the data.points_hovers size: (3, 2)
                is different from the data.points_colors and/or data.points_sizes size: (2, 3)
            """) graph.figure
        end

        nested_test("border") do
            graph.data.borders_sizes = (graph.data.points_colors .- 1) .* 10

            nested_test("!sizes") do
                graph.data.borders_sizes = transpose(graph.data.borders_sizes)
                @test_throws dedent("""
                    the data.borders_sizes size: (3, 2)
                    is different from the data.points_colors and/or data.points_sizes size: (2, 3)
                """) graph.figure
            end

            nested_test("~sizes") do
                graph.data.borders_sizes[1, 2] = -1.5
                @test_throws "negative data.borders_sizes[1,2]: -1.5" graph.figure
            end

            nested_test("sizes") do
                nested_test("()") do
                    test_html(graph, "grid.border.sizes.html")
                    return nothing
                end

                nested_test("linear") do
                    graph.configuration.borders.size_range.smallest = 2.0
                    graph.configuration.borders.size_range.largest = 10.0
                    test_html(graph, "grid.border.sizes.linear.html")
                    return nothing
                end

                nested_test("log") do
                    graph.configuration.borders.size_scale.log_regularization = 1
                    test_html(graph, "grid.border.sizes.log.html")
                    return nothing
                end

                nested_test("color") do
                    graph.configuration.borders.color = "black"
                    test_html(graph, "grid.border.sizes.color.html")
                    return nothing
                end

                nested_test("colors") do
                    graph.data.borders_colors = ["red" "green" ""; "blue" "green" ""]
                    test_html(graph, "grid.border.sizes.colors.html")
                    return nothing
                end

                nested_test("categorical") do
                    graph.data.borders_colors = ["Foo" "Bar" "Baz"; "Baz" "Bar" "Foo"]
                    graph.configuration.borders.color_palette = [("Foo", "red"), ("Bar", "green"), ("Baz", "blue")]
                    test_html(graph, "grid.border.sizes.categorical.html")
                    return nothing
                end

                nested_test("continuous") do
                    graph.data.borders_colors = [0.0 1.0 2.0; 2.0 1.0 0.0]
                    test_html(graph, "grid.border.sizes.continuous.html")
                    return nothing
                end
            end

            nested_test("!colors") do
                graph.data.borders_colors = ["red" "green" "blue"; "red" "green" "blue"]
                graph.data.borders_colors = transpose(graph.data.borders_colors)
                @test_throws dedent("""
                    the data.borders_colors size: (3, 2)
                    is different from the data.points_colors and/or data.points_sizes size: (2, 3)
                """) graph.figure
            end

            nested_test("colors") do
                graph.data.borders_sizes = nothing
                graph.data.borders_colors = ["red" "green" "blue"; "red" "green" "blue"]

                nested_test("()") do
                    test_html(graph, "grid.border.colors.html")
                    return nothing
                end

                nested_test("!scale") do
                    graph.configuration.borders.show_color_scale = true
                    @test_throws "explicit data.borders_colors specified for configuration.borders.show_color_scale" graph.figure
                end
            end

            nested_test("categorical") do
                graph.data.borders_colors = ["A" "B" "C"; "C" "B" "A"]
                graph.configuration.borders.color_palette = [("A", "red"), ("B", "green"), ("C", "blue")]

                nested_test("()") do
                    test_html(graph, "grid.border.categorical.html")
                    return nothing
                end

                nested_test("legend") do
                    graph.configuration.borders.show_color_scale = true

                    nested_test("()") do
                        test_legend(graph, "grid.border.categorical") do
                            graph.data.borders_colors_title = "Grid"
                            return nothing
                        end
                    end

                    nested_test("legend") do
                        graph.data.points_colors = ["X" "Y" "Z"; "Z" "Y" "X"]
                        graph.configuration.points.color_palette = [("X", "cyan"), ("Y", "magenta"), ("Z", "yellow")]
                        graph.configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(graph, "grid.border.categorical.legend") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            graph.data.borders_colors_title = "Borders"
                            test_legend(graph, "grid.border.categorical.legend.title") do
                                graph.data.points_colors_title = "Grid"
                                return nothing
                            end
                        end
                    end

                    nested_test("legend1") do
                        graph.data.points_colors = [1.0 2.0 3.0; 4.0 5.0 6.0]
                        graph.configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(graph, "grid.border.categorical.legend1") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            graph.data.borders_colors_title = "Borders"
                            test_legend(graph, "grid.border.categorical.legend1.title") do
                                graph.data.points_colors_title = "Grid"
                                return nothing
                            end
                        end
                    end
                end
            end

            nested_test("continuous") do
                graph.data.borders_colors = 0 .- graph.data.points_colors
                nested_test("()") do
                    test_html(graph, "grid.border.continuous.html")
                    return nothing
                end

                nested_test("log") do
                    graph.configuration.borders.color_scale.log_regularization = 0.0
                    @test_throws "log of non-positive data.borders_colors[2,3]: -6.0" graph.figure
                end

                nested_test("legend") do
                    graph.configuration.borders.show_color_scale = true

                    nested_test("()") do
                        test_legend(graph, "grid.border.continuous") do
                            graph.data.borders_colors_title = "Grid"
                            return nothing
                        end
                    end

                    nested_test("legend") do
                        graph.configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(graph, "grid.border.continuous.legend") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end
                        nested_test("title") do
                            graph.data.borders_colors_title = "Borders"
                            test_legend(graph, "grid.border.continuous.legend.title") do
                                graph.data.points_colors_title = "Grid"
                                return nothing
                            end
                        end
                    end

                    nested_test("legend1") do
                        graph.data.points_colors = ["A" "B" "C"; "C" "B" "A"]
                        graph.configuration.points.color_palette = [("A", "red"), ("B", "green"), ("C", "blue")]
                        graph.configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(graph, "grid.border.continuous.legend1") do
                                graph.data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            graph.data.borders_colors_title = "Borders"
                            test_legend(graph, "grid.border.continuous.legend1.title") do
                                graph.data.points_colors_title = "Grid"
                                return nothing
                            end
                        end
                    end
                end
            end
        end
    end

    nested_test("heatmap") do
        graph = heatmap_graph(; entries_colors = [1.0 2.0 3.0; 4.0 5.0 6.0])
        nested_test("()") do
            test_html(graph, "heatmap.html")
            return nothing
        end

        nested_test("!rows") do
            graph.data.entries_colors = zeros(Float32, 0, 3)
            @test_throws "no rows in data.entries_colors" graph.figure
        end

        nested_test("!columns") do
            graph.data.entries_colors = zeros(Float32, 2, 0)
            @test_throws "no columns in data.entries_colors" graph.figure
        end

        nested_test("!hovers") do
            graph.data.entries_hovers = ["A" "B"; "C" "D"; "E" "F"]
            @test_throws dedent("""
                the data.entries_hovers size: (3, 2)
                is different from the data.entries_colors size: (2, 3)
            """) graph.figure
        end

        nested_test("hovers") do
            graph.data.entries_hovers = ["A" "B" "C"; "D" "E" "F"]
            test_html(graph, "heatmap.hovers.html")
            return nothing
        end

        nested_test("ticks") do
            graph.data.rows_names = ["Foo", "Bar"]
            graph.data.columns_names = ["Baz", "Vaz", "Faz"]
            test_html(graph, "heatmap.ticks.html")
            return nothing
        end

        nested_test("!ticks") do
            graph.configuration.graph.show_ticks = false
            test_html(graph, "heatmap.!ticks.html")
            return nothing
        end

        nested_test("legend") do
            graph.configuration.entries.show_color_scale = true

            test_legend(graph, "heatmap") do
                graph.data.entries_colors_title = "Entries"
                return nothing
            end
        end

        nested_test("titles") do
            graph.data.graph_title = "Graph"
            graph.data.x_axis_title = "Columns"
            graph.data.y_axis_title = "Rows"
            test_html(graph, "heatmap.titles.html")
            return nothing
        end
    end
end
