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

function test_svg(data::AbstractGraphData, configuration::AbstractGraphConfiguration, path::AbstractString)::Nothing
    render(data, configuration, "actual.svg")
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

function test_html(data::AbstractGraphData, configuration::AbstractGraphConfiguration, path::AbstractString)::Nothing
    render(data, configuration, "actual.html")
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

function test_legend(
    set_title::Function,
    data::AbstractGraphData,
    configuration::AbstractGraphConfiguration,
    path_prefix::AbstractString,
)::Nothing
    nested_test("()") do
        test_html(data, configuration, path_prefix * ".legend.html")
        return nothing
    end

    nested_test("title") do
        set_title()
        test_html(data, configuration, path_prefix * ".legend.title.html")
        return nothing
    end

    return nothing
end

mkpath("actual")

nested_test("renderers") do
    nested_test("distribution") do
        configuration = DistributionGraphConfiguration()
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

        nested_test("invalid") do
            nested_test("!style") do
                configuration.style.show_box = false
                @test_throws "must specify at least one of: distribution style.show_box, style.show_violin, style.show_curve" render(
                    data,
                    configuration,
                )
            end

            nested_test("!width") do
                configuration.graph.width = 0
                @test_throws "non-positive graph width: 0" render(data, configuration)
            end

            nested_test("!height") do
                configuration.graph.height = 0
                @test_throws "non-positive graph height: 0" render(data, configuration)
            end

            nested_test("!range") do
                configuration.value_axis.minimum = 1
                configuration.value_axis.maximum = 0
                @test_throws dedent("""
                    value axis maximum: 0
                    is not larger than minimum: 1
                """) render(data, configuration)
            end

            nested_test("curve&violin") do
                configuration.style.show_curve = true
                configuration.style.show_violin = true
                @test_throws "can't specify both of: distribution style.show_violin, style.show_curve" render(
                    data,
                    configuration,
                )
            end

            nested_test("!values") do
                data = DistributionGraphData(; values = Float32[])
                @test_throws "empty values vector" render(data)
            end
        end

        nested_test("box") do
            nested_test("size") do
                configuration.graph.height = 96 * 2
                configuration.graph.width = 96 * 2
                test_svg(data, configuration, "distribution.box.size.svg")
                return nothing
            end

            nested_test("range") do
                configuration.value_axis.minimum = 0
                configuration.value_axis.maximum = 200
                test_html(data, configuration, "distribution.box.range.html")
                return nothing
            end

            nested_test("()") do
                test_html(data, configuration, "distribution.box.html")
                return nothing
            end

            nested_test("horizontal") do
                configuration.style.orientation = HorizontalValues
                test_html(data, configuration, "distribution.box.horizontal.html")
                return nothing
            end

            nested_test("log") do
                configuration.value_axis.log_scale = true
                test_html(data, configuration, "distribution.box.log.html")
                return nothing
            end

            nested_test("outliers") do
                configuration.style.show_outliers = true
                test_html(data, configuration, "distribution.box.outliers.html")
                return nothing
            end

            nested_test("color") do
                configuration.style.color = "red"
                test_html(data, configuration, "distribution.box.color.html")
                return nothing
            end

            nested_test("!grid") do
                configuration.graph.show_grid = false
                test_html(data, configuration, "distribution.box.!grid.html")
                return nothing
            end

            nested_test("!ticks") do
                configuration.graph.show_ticks = false
                test_html(data, configuration, "distribution.box.!ticks.html")
                return nothing
            end

            nested_test("titles") do
                data.graph_title = "Graph"
                data.value_axis_title = "Value"
                data.trace_axis_title = "Trace"
                data.name = "Name"
                test_html(data, configuration, "distribution.box.titles.html")
                return nothing
            end
        end

        nested_test("violin") do
            configuration.style.show_box = false
            configuration.style.show_violin = true

            nested_test("()") do
                test_html(data, configuration, "distribution.violin.html")
                return nothing
            end

            nested_test("horizontal") do
                configuration.style.orientation = HorizontalValues
                test_html(data, configuration, "distribution.violin.horizontal.html")
                return nothing
            end

            nested_test("outliers") do
                configuration.style.show_outliers = true
                test_html(data, configuration, "distribution.violin.outliers.html")
                return nothing
            end

            nested_test("box") do
                configuration.style.show_box = true
                test_html(data, configuration, "distribution.violin.box.html")
                return nothing
            end

            nested_test("log") do
                configuration.value_axis.log_scale = true
                test_html(data, configuration, "distribution.violin.log.html")
                return nothing
            end
        end

        nested_test("curve") do
            configuration.style.show_box = false
            configuration.style.show_curve = true

            nested_test("()") do
                test_html(data, configuration, "distribution.curve.html")
                return nothing
            end

            nested_test("horizontal") do
                configuration.style.orientation = HorizontalValues
                test_html(data, configuration, "distribution.curve.horizontal.html")
                return nothing
            end

            nested_test("outliers") do
                configuration.style.show_outliers = true
                test_html(data, configuration, "distribution.curve.outliers.html")
                return nothing
            end

            nested_test("box") do
                configuration.style.show_box = true
                test_html(data, configuration, "distribution.curve.box.html")
                return nothing
            end

            nested_test("log") do
                configuration.value_axis.log_scale = true
                test_html(data, configuration, "distribution.curve.log.html")
                return nothing
            end
        end
    end

    nested_test("distributions") do
        configuration = DistributionsGraphConfiguration()
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

        nested_test("invalid") do
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
        end

        nested_test("box") do
            test_html(data, configuration, "distributions.box.html")
            return nothing
        end

        nested_test("log") do
            configuration.value_axis.log_scale = true
            test_html(data, configuration, "distributions.log.html")
            return nothing
        end

        nested_test("colors") do
            data.colors = ["red", "green"]
            test_html(data, configuration, "distributions.box.colors.html")
            return nothing
        end

        nested_test("titles") do
            data.names = ["Foo", "Bar"]
            data.value_axis_title = "Value"
            data.trace_axis_title = "Trace"
            data.graph_title = "Graph"
            data.legend_title = "Traces"
            test_html(data, configuration, "distributions.box.titles.html")
            return nothing
        end

        nested_test("legend") do
            configuration.show_legend = true
            test_html(data, configuration, "distributions.box.legend.html")
            return nothing
        end

        nested_test("legend&titles") do
            data.names = ["Foo", "Bar"]
            data.value_axis_title = "Value"
            data.trace_axis_title = "Trace"
            data.graph_title = "Graph"
            data.legend_title = "Traces"
            configuration.show_legend = true
            test_html(data, configuration, "distributions.box.legend&titles.html")
            return nothing
        end
    end

    nested_test("line") do
        configuration = LineGraphConfiguration()
        data = LineGraphData(; xs = [0.0, 1.0, 2.0], ys = [-0.2, 1.2, 1.8])

        nested_test("invalid") do
            nested_test("!line_width") do
                configuration.style.line_width = 0
                @test_throws "non-positive line_width: 0" render(data, configuration)
            end

            nested_test("!fill_below") do
                configuration.style.line_width = nothing
                @test_throws "either line_width or fill_below must be specified" render(data, configuration)
            end

            nested_test("~ys") do
                push!(data.ys, 2.0)
                @test_throws dedent("""
                    the number of xs: 3
                    is different from the number of ys: 4
                """) render(data, configuration)
            end
        end

        nested_test("()") do
            test_html(data, configuration, "line.html")
            return nothing
        end

        nested_test("dash") do
            configuration.style.line_is_dashed = true
            test_html(data, configuration, "line.dash.html")
            return nothing
        end

        nested_test("size") do
            configuration.style.line_width = 5
            test_html(data, configuration, "line.size.html")
            return nothing
        end

        nested_test("color") do
            configuration.style.line_color = "red"
            test_html(data, configuration, "line.color.html")
            return nothing
        end

        nested_test("fill_below") do
            configuration.style.fill_below = true
            test_html(data, configuration, "line.fill_below.html")
            return nothing
        end

        nested_test("fill_below!line") do
            configuration.style.line_width = nothing
            configuration.style.fill_below = true
            test_html(data, configuration, "line.fill_below!line.html")
            return nothing
        end

        nested_test("!grid") do
            configuration.graph.show_grid = false
            configuration.graph.show_ticks = false
            return test_html(data, configuration, "line.!grid.html")
        end

        nested_test("vertical_lines") do
            configuration.vertical_bands.middle.line_offset = 1.25
            configuration.vertical_bands.low.line_offset = 0.75
            configuration.vertical_bands.high.line_offset = 1.5
            test_html(data, configuration, "line.vertical_lines.html")
            return nothing
        end

        nested_test("vertical_fills") do
            configuration.vertical_bands.middle.line_color = nothing
            configuration.vertical_bands.low.line_color = nothing
            configuration.vertical_bands.high.line_color = nothing
            configuration.vertical_bands.middle.fill_color = "#00ff0080"
            configuration.vertical_bands.low.fill_color = "#0000ff80"
            configuration.vertical_bands.high.fill_color = "ff000080"
            configuration.vertical_bands.low.line_offset = 0.75
            configuration.vertical_bands.high.line_offset = 1.5
            test_html(data, configuration, "line.vertical_fills.html")
            return nothing
        end

        nested_test("horizontal_lines") do
            configuration.horizontal_bands.middle.line_offset = 1.25
            configuration.horizontal_bands.low.line_offset = 0.75
            configuration.horizontal_bands.high.line_offset = 1.5
            test_html(data, configuration, "line.horizontal_lines.html")
            return nothing
        end

        nested_test("horizontal_fills") do
            configuration.horizontal_bands.middle.line_color = nothing
            configuration.horizontal_bands.low.line_color = nothing
            configuration.horizontal_bands.high.line_color = nothing
            configuration.horizontal_bands.middle.fill_color = "#00ff0080"
            configuration.horizontal_bands.low.fill_color = "#0000ff80"
            configuration.horizontal_bands.high.fill_color = "ff000080"
            configuration.horizontal_bands.low.line_offset = 0.75
            configuration.horizontal_bands.high.line_offset = 1.5
            test_html(data, configuration, "line.horizontal_fills.html")
            return nothing
        end

        nested_test("titles") do
            data.graph_title = "Graph"
            data.x_axis_title = "X"
            data.y_axis_title = "Y"
            test_html(data, configuration, "line.titles.html")
            return nothing
        end
    end

    nested_test("lines") do
        configuration = LinesGraphConfiguration()
        data = LinesGraphData(;
            xs = [[0.0, 1.0, 2.0], [0.25, 0.5, 1.5, 2.5]],
            ys = [[-0.2, 1.2, 1.8], [0.1, 1.0, 0.5, 2.0]],
        )

        nested_test("()") do
            test_html(data, configuration, "lines.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!lines") do
                empty!(data.xs)
                empty!(data.ys)
                @test_throws "empty lines vectors" render(data, configuration)
            end

            nested_test("~ys") do
                push!(data.ys, [2.0])
                @test_throws dedent("""
                    the number of xs lines: 2
                    is different from the number of ys lines: 3
                """) render(data, configuration)
            end

            nested_test("~points") do
                push!(data.ys[2], 1.0)
                @test_throws dedent("""
                    the number of line#2 xs: 4
                    is different from the number of ys: 5
                """) render(data, configuration)
            end

            nested_test("~xs") do
                empty!(data.xs[1])
                empty!(data.ys[1])
                @test_throws "too few points in line#1: 0" render(data, configuration)
            end

            nested_test("~names") do
                data.names = ["Foo"]
                @test_throws dedent("""
                    the number of names: 1
                    is different from the number of lines: 2
                """) render(data, configuration)
            end

            nested_test("~colors") do
                data.line_colors = ["red"]
                @test_throws dedent("""
                    the number of line_colors: 1
                    is different from the number of lines: 2
                """) render(data, configuration)
            end

            nested_test("~sizes") do
                data.line_widths = [1]
                @test_throws dedent("""
                    the number of line_widths: 1
                    is different from the number of lines: 2
                """) render(data, configuration)
            end

            nested_test("!sizes") do
                data.line_widths = [1, -1]
                @test_throws "non-positive line_width#2: -1" render(data, configuration)
            end

            nested_test("!fill_below") do
                configuration.style.line_width = nothing
                @test_throws "either line_width or fill_below must be specified" render(data, configuration)
            end

            nested_test("~fills") do
                data.fill_belows = [true]
                @test_throws dedent("""
                    the number of fill_belows: 1
                    is different from the number of lines: 2
                """) render(data, configuration)
            end

            nested_test("~dashs") do
                data.are_dashed = [true]
                @test_throws dedent("""
                    the number of are_dashed: 1
                    is different from the number of lines: 2
                """) render(data, configuration)
            end
        end

        nested_test("size") do
            configuration.style.line_width = 4
            test_html(data, configuration, "lines.size.html")
            return nothing
        end

        nested_test("sizes") do
            data.line_widths = [4, 8]
            test_html(data, configuration, "lines.sizes.html")
            return nothing
        end

        nested_test("color") do
            configuration.style.line_color = "red"
            test_html(data, configuration, "lines.color.html")
            return nothing
        end

        nested_test("colors") do
            data.line_colors = ["red", "green"]
            test_html(data, configuration, "lines.colors.html")
            return nothing
        end

        nested_test("dash") do
            configuration.style.line_is_dashed = true
            test_html(data, configuration, "lines.dash.html")
            return nothing
        end

        nested_test("dashs") do
            data.are_dashed = [true, false]
            test_html(data, configuration, "lines.dashs.html")
            return nothing
        end

        nested_test("fill") do
            configuration.style.fill_below = true

            nested_test("()") do
                test_html(data, configuration, "lines.fill.html")
                return nothing
            end

            nested_test("!line") do
                configuration.style.line_width = nothing
                test_html(data, configuration, "lines.fill.!line.html")
                return nothing
            end
        end

        nested_test("fills") do
            data.fill_belows = [true, false]
            test_html(data, configuration, "lines.fills.html")
            return nothing
        end

        nested_test("stack") do
            nested_test("values") do
                configuration.stacking = StackValues
                test_html(data, configuration, "lines.stack.values.html")
                return nothing
            end

            nested_test("percents") do
                data.ys[1][1] = 0.2
                configuration.stacking = StackPercents
                test_html(data, configuration, "lines.stack.percents.html")
                return nothing
            end

            nested_test("fractions") do
                data.ys[1][1] = 0.2
                configuration.stacking = StackFractions
                test_html(data, configuration, "lines.stack.fractions.html")
                return nothing
            end
        end

        nested_test("legend") do
            configuration.show_legend = true

            nested_test("()") do
                test_legend(data, configuration, "lines") do
                    return data.legend_title = "Lines"
                end
                return nothing
            end

            nested_test("names") do
                data.names = ["Foo", "Bar"]
                test_legend(data, configuration, "lines.names") do
                    return data.legend_title = "Lines"
                end
                return nothing
            end
        end
    end

    nested_test("cdf") do
        configuration = CdfGraphConfiguration()
        data = CdfGraphData(;
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

        nested_test("()") do
            return test_html(data, configuration, "cdf.html")
        end

        nested_test("~values") do
            empty!(data.values)
            @test_throws "too few values: 0" render(data, configuration)
        end

        nested_test("vertical") do
            configuration.orientation = VerticalValues
            return test_html(data, configuration, "cdf.vertical.html")
        end

        nested_test("percent") do
            configuration.show_percent = true
            return test_html(data, configuration, "cdf.percent.html")
        end

        nested_test("downto") do
            configuration.direction = DownToValue
            return test_html(data, configuration, "cdf.downto.html")
        end
    end

    nested_test("cdfs") do
        configuration = CdfsGraphConfiguration()
        data = CdfsGraphData(;
            values = [
                [
                    #! format: off
                    0.75, 5.25, 5.5, 6, 6.2, 6.6, 6.80, 7.0, 7.2, 7.5, 7.5, 7.75, 8.15, 8.15, 8.65, 8.93, 9.2, 9.5, 10,
                    10.25, 11.5, 12, 16, 20.90, 22.3, 23.25,
                    #! format: on
                ],
                [
                    #! format: off
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
                    #! format: on
                ] ./ 10.0,
            ],
        )

        nested_test("()") do
            return test_html(data, configuration, "cdfs.html")
        end

        nested_test("invalid") do
            nested_test("~values") do
                empty!(data.values)
                @test_throws "empty values vector" render(data, configuration)
            end

            nested_test("!values") do
                empty!(data.values[2])
                @test_throws "too few values#2: 0" render(data, configuration)
            end
        end

        nested_test("vertical") do
            configuration.orientation = VerticalValues
            return test_html(data, configuration, "cdfs.vertical.html")
        end

        nested_test("percent") do
            configuration.show_percent = true
            return test_html(data, configuration, "cdfs.percent.html")
        end

        nested_test("downto") do
            configuration.direction = DownToValue
            return test_html(data, configuration, "cdfs.downto.html")
        end

        nested_test("legend") do
            configuration.show_legend = true
            test_legend(data, configuration, "cdfs") do
                return data.legend_title = "Traces"
            end
            return nothing
        end
    end

    nested_test("bar") do
        data = BarGraphData(; values = [-0.2, 1.2, 1.8])
        configuration = BarGraphConfiguration()

        nested_test("()") do
            return test_html(data, configuration, "bar.html")
        end

        nested_test("invalid") do
            nested_test("!bar_gap") do
                configuration.bar_gap = -1
                @test_throws "non-positive bar_gap: -1" render(data, configuration)
            end

            nested_test("~bar_gap") do
                configuration.bar_gap = 1
                @test_throws "too-large bar_gap: 1" render(data, configuration)
            end

            nested_test("~values") do
                empty!(data.values)
                @test_throws "empty values vector" render(data, configuration)
            end

            nested_test("~names") do
                data.names = ["Foo"]
                @test_throws dedent("""
                    the number of names: 1
                    is different from the number of bars: 3
                """) render(data, configuration)
            end

            nested_test("~hovers") do
                data.hovers = ["Foo"]
                @test_throws dedent("""
                    the number of hovers: 1
                    is different from the number of bars: 3
                """) render(data, configuration)
            end

            nested_test("~colors") do
                data.colors = ["red"]
                @test_throws dedent("""
                    the number of colors: 1
                    is different from the number of bars: 3
                """) render(data, configuration)
            end
        end

        nested_test("names") do
            data.names = ["Foo", "Bar", "Baz"]
            return test_html(data, configuration, "bar.names.html")
        end

        nested_test("titles") do
            data.graph_title = "Graph"
            data.bar_axis_title = "Bars"
            data.value_axis_title = "Values"
            return test_html(data, configuration, "bar.titles.html")
        end

        nested_test("horizontal") do
            configuration.orientation = HorizontalValues

            nested_test("()") do
                return test_html(data, configuration, "bar.horizontal.html")
            end

            nested_test("names") do
                data.names = ["Foo", "Bar", "Baz"]
                return test_html(data, configuration, "bar.horizontal.names.html")
            end

            nested_test("titles") do
                data.graph_title = "Graph"
                data.bar_axis_title = "Bars"
                data.value_axis_title = "Values"
                return test_html(data, configuration, "bar.horizontal.titles.html")
            end
        end

        nested_test("!bar_gap") do
            configuration.bar_gap = 0
            return test_html(data, configuration, "bar.!bar_gap.html")
        end

        nested_test("color") do
            configuration.color = "red"
            return test_html(data, configuration, "bar.color.html")
        end

        nested_test("colors") do
            data.colors = ["red", "green", "blue"]
            return test_html(data, configuration, "bar.colors.html")
        end

        nested_test("hovers") do
            data.hovers = ["Foo", "Bar", "Baz"]
            return test_html(data, configuration, "bar.hovers.html")
        end
    end

    nested_test("bars") do
        data = BarsGraphData(; values = [[0.0, 1.0, 2.0], [0.2, 1.2, 1.8]])
        configuration = BarsGraphConfiguration()

        nested_test("()") do
            test_html(data, configuration, "bars.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!values") do
                empty!(data.values)
                @test_throws "empty values vector" render(data, configuration)
            end

            nested_test("!!values") do
                empty!(data.values[1])
                empty!(data.values[2])
                @test_throws "empty values vectors" render(data, configuration)
            end

            nested_test("~values") do
                push!(data.values[1], 0.0)
                @test_throws dedent("""
                    the number of values#1: 4
                    is different from the number of values#2: 3
                """) render(data, configuration)
            end

            nested_test("~bar_names") do
                data.bar_names = ["Foo"]
                @test_throws dedent("""
                    the number of bar_names: 1
                    is different from the number of bars: 3
                """) render(data, configuration)
            end

            nested_test("~names") do
                data.names = ["Foo"]
                @test_throws dedent("""
                    the number of names: 1
                    is different from the number of series: 2
                """) render(data, configuration)
            end

            nested_test("~hovers") do
                data.hovers = ["Foo"]
                @test_throws dedent("""
                    the number of hovers: 1
                    is different from the number of series: 2
                """) render(data, configuration)
            end

            nested_test("~colors") do
                data.colors = ["red"]
                @test_throws dedent("""
                    the number of colors: 1
                    is different from the number of series: 2
                """) render(data, configuration)
            end
        end

        nested_test("stack") do
            nested_test("values") do
                configuration.stacking = StackValues
                test_html(data, configuration, "bars.stack.values.html")
                return nothing
            end

            nested_test("percents") do
                configuration.stacking = StackPercents
                test_html(data, configuration, "bars.stack.percents.html")
                return nothing
            end

            nested_test("fractions") do
                configuration.stacking = StackFractions
                test_html(data, configuration, "bars.stack.fractions.html")
                return nothing
            end
        end

        nested_test("!bar_gap") do
            configuration.bar_gap = 0
            return test_html(data, configuration, "bars.!bar_gap.html")
        end

        nested_test("legend") do
            configuration.show_legend = true
            test_legend(data, configuration, "bars") do
                return data.legend_title = "Series"
            end
        end

        nested_test("names") do
            data.names = ["Foo", "Bar"]

            nested_test("()") do
                return test_html(data, configuration, "bars.names.html")
            end

            nested_test("legend") do
                configuration.show_legend = true
                test_legend(data, configuration, "bars.names") do
                    return data.legend_title = "Series"
                end
            end
        end

        nested_test("bar_names") do
            data.bar_names = ["Foo", "Bar", "Baz"]
            return test_html(data, configuration, "bars.bar_names.html")
        end

        nested_test("titles") do
            data.graph_title = "Graph"
            data.bar_axis_title = "Bars"
            data.value_axis_title = "Values"
            return test_html(data, configuration, "bars.titles.html")
        end

        nested_test("horizontal") do
            configuration.orientation = HorizontalValues

            nested_test("()") do
                return test_html(data, configuration, "bars.horizontal.html")
            end

            nested_test("names") do
                data.names = ["Foo", "Bar"]
                return test_html(data, configuration, "bars.horizontal.names.html")
            end

            nested_test("bar_names") do
                data.bar_names = ["Foo", "Bar", "Baz"]
                return test_html(data, configuration, "bars.horizontal.bar_names.html")
            end

            nested_test("titles") do
                data.graph_title = "Graph"
                data.bar_axis_title = "Bars"
                data.value_axis_title = "Values"
                return test_html(data, configuration, "bars.horizontal.titles.html")
            end
        end

        nested_test("colors") do
            data.colors = ["red", "green"]
            return test_html(data, configuration, "bars.colors.html")
        end

        nested_test("hovers") do
            data.hovers = ["Foo", "Bar"]
            return test_html(data, configuration, "bars.hovers.html")
        end
    end

    nested_test("points") do
        configuration = PointsGraphConfiguration()
        data = PointsGraphData(; xs = [0.0, 1.0, 2.0], ys = [-0.2, 1.2, 1.8])

        nested_test("()") do
            test_html(data, configuration, "points.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!size") do
                configuration.style.size = 0
                @test_throws "non-positive points style.size: 0" render(data, configuration)
            end

            nested_test("!line-width") do
                configuration.diagonal_bands.middle.line_width = 0
                @test_throws "non-positive diagonal_bands middle line_width: 0" render(data, configuration)
            end

            nested_test("~ys") do
                push!(data.ys, 2.0)
                @test_throws dedent("""
                    the number of xs: 3
                    is different from the number of ys: 4
                """) render(data, configuration)
            end

            nested_test("!colors") do
                configuration.style.show_scale = true
                @test_throws "no data.colors specified for points style.show_scale" render(data, configuration)
            end

            nested_test("~colors") do
                data.colors = ["Red"]
                @test_throws dedent("""
                    the number of colors: 1
                    is different from the number of points: 3
                """) render(data, configuration)
            end

            nested_test("!border_colors") do
                configuration.border_style.show_scale = true
                @test_throws "no data.border_colors specified for points border_style.show_scale" render(
                    data,
                    configuration,
                )
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
        end

        nested_test("log") do
            data.xs .*= 10
            data.ys .*= 10
            data.xs .+= 1
            data.ys .+= 3
            configuration.x_axis.log_scale = true
            configuration.y_axis.log_scale = true

            nested_test("invalid") do
                nested_test("!minimum") do
                    configuration.x_axis.minimum = 0.0
                    @test_throws "non-positive x log axis minimum: 0.0" render(data, configuration)
                end

                nested_test("!maximum") do
                    configuration.y_axis.maximum = -1.0
                    @test_throws "non-positive y log axis maximum: -1.0" render(data, configuration)
                end

                nested_test("!xs") do
                    data.xs[1] = 0
                    @test_throws "non-positive log x#1: 0.0" render(data, configuration)
                end

                nested_test("!ys") do
                    data.ys[1] = -0.2
                    configuration.y_axis.log_scale = true
                    @test_throws "non-positive log y#1: -0.2" render(data, configuration)
                end
            end

            nested_test("()") do
                test_html(data, configuration, "points.log.html")
                return nothing
            end

            nested_test("diagonal") do
                nested_test("()") do
                    configuration.x_axis.log_scale = true
                    configuration.y_axis.log_scale = true
                    configuration.diagonal_bands.middle.line_offset = 1
                    configuration.diagonal_bands.low.line_offset = 0.5
                    configuration.diagonal_bands.high.line_offset = 2
                    test_html(data, configuration, "points.log.diagonal.html")
                    return nothing
                end

                nested_test("invalid") do
                    nested_test("!line_offset") do
                        configuration.x_axis.log_scale = true
                        configuration.y_axis.log_scale = true
                        configuration.diagonal_bands.low.line_offset = -1
                        @test_throws "non-positive log_scale diagonal_bands low line_offset: -1" render(
                            data,
                            configuration,
                        )
                    end

                    nested_test("!log") do
                        configuration.y_axis.log_scale = false
                        configuration.diagonal_bands.middle.line_offset = 1
                        @test_throws "diagonal_bands specified for a combination of linear and log scale axes" render(
                            data,
                            configuration,
                        )
                        return nothing
                    end
                end

                nested_test("low_fills") do
                    configuration.diagonal_bands.middle.line_color = nothing
                    configuration.diagonal_bands.low.line_color = nothing
                    configuration.diagonal_bands.high.line_color = nothing
                    configuration.diagonal_bands.middle.fill_color = "#00ff0080"
                    configuration.diagonal_bands.low.fill_color = "#0000ff80"
                    configuration.diagonal_bands.high.fill_color = "ff000080"
                    configuration.diagonal_bands.low.line_offset = 0.25
                    configuration.diagonal_bands.high.line_offset = 0.75
                    test_html(data, configuration, "points.log.diagonal.low_fills.html")
                    return nothing
                end

                nested_test("high_fills") do
                    configuration.diagonal_bands.middle.line_color = nothing
                    configuration.diagonal_bands.low.line_color = nothing
                    configuration.diagonal_bands.high.line_color = nothing
                    configuration.diagonal_bands.middle.fill_color = "#00ff0080"
                    configuration.diagonal_bands.low.fill_color = "#0000ff80"
                    configuration.diagonal_bands.high.fill_color = "ff000080"
                    configuration.diagonal_bands.low.line_offset = 1.25
                    configuration.diagonal_bands.high.line_offset = 1.75
                    test_html(data, configuration, "points.log.diagonal.high_fills.html")
                    return nothing
                end

                nested_test("middle_fills") do
                    configuration.diagonal_bands.middle.line_color = nothing
                    configuration.diagonal_bands.low.line_color = nothing
                    configuration.diagonal_bands.high.line_color = nothing
                    configuration.diagonal_bands.middle.fill_color = "#00ff0080"
                    configuration.diagonal_bands.low.fill_color = "#0000ff80"
                    configuration.diagonal_bands.high.fill_color = "ff000080"
                    configuration.diagonal_bands.low.line_offset = 0.75
                    configuration.diagonal_bands.high.line_offset = 1.25
                    test_html(data, configuration, "points.log.diagonal.middle_fills.html")
                    return nothing
                end
            end
        end

        nested_test("invalid") do
            nested_test("!low") do
                configuration.diagonal_bands.middle.line_offset = 0
                configuration.diagonal_bands.low.line_offset = 0.1
                configuration.diagonal_bands.high.line_offset = 0.3
                @test_throws dedent("""
                    diagonal_bands low line_offset: 0.1
                    is not less than middle line_offset: 0
                """) render(data, configuration)
                return nothing
            end

            nested_test("!high") do
                configuration.diagonal_bands.middle.line_offset = 0
                configuration.diagonal_bands.low.line_offset = -0.3
                configuration.diagonal_bands.high.line_offset = -0.1
                @test_throws dedent("""
                    diagonal_bands high line_offset: -0.1
                    is not greater than middle line_offset: 0
                """) render(data, configuration)
                return nothing
            end

            nested_test("!middle") do
                configuration.diagonal_bands.low.line_offset = 0.3
                configuration.diagonal_bands.high.line_offset = -0.3
                @test_throws dedent("""
                    diagonal_bands low line_offset: 0.3
                    is not less than high line_offset: -0.3
                """) render(data, configuration)
                return nothing
            end
        end

        nested_test("diagonal") do
            nested_test("()") do
                configuration.diagonal_bands.middle.line_offset = 0
                configuration.diagonal_bands.middle.line_width = 8
                configuration.diagonal_bands.low.line_offset = -0.3
                configuration.diagonal_bands.high.line_offset = 0.3
                test_html(data, configuration, "points.diagonal.html")
                return nothing
            end

            nested_test("low_fills") do
                configuration.diagonal_bands.middle.line_color = nothing
                configuration.diagonal_bands.low.line_color = nothing
                configuration.diagonal_bands.high.line_color = nothing
                configuration.diagonal_bands.middle.fill_color = "#00ff0080"
                configuration.diagonal_bands.low.fill_color = "#0000ff80"
                configuration.diagonal_bands.high.fill_color = "ff000080"
                configuration.diagonal_bands.low.line_offset = -0.6
                configuration.diagonal_bands.high.line_offset = -0.3
                test_html(data, configuration, "points.diagonal.low_fills.html")
                return nothing
            end

            nested_test("high_fills") do
                configuration.diagonal_bands.middle.line_color = nothing
                configuration.diagonal_bands.low.line_color = nothing
                configuration.diagonal_bands.high.line_color = nothing
                configuration.diagonal_bands.middle.fill_color = "#00ff0080"
                configuration.diagonal_bands.low.fill_color = "#0000ff80"
                configuration.diagonal_bands.high.fill_color = "ff000080"
                configuration.diagonal_bands.low.line_offset = 0.3
                configuration.diagonal_bands.high.line_offset = 0.6
                test_html(data, configuration, "points.diagonal.high_fills.html")
                return nothing
            end

            nested_test("middle_fills") do
                configuration.diagonal_bands.middle.line_color = nothing
                configuration.diagonal_bands.low.line_color = nothing
                configuration.diagonal_bands.high.line_color = nothing
                configuration.diagonal_bands.middle.fill_color = "#00ff0080"
                configuration.diagonal_bands.low.fill_color = "#0000ff80"
                configuration.diagonal_bands.high.fill_color = "ff000080"
                configuration.diagonal_bands.low.line_offset = -0.3
                configuration.diagonal_bands.high.line_offset = 0.6
                test_html(data, configuration, "points.diagonal.middle_fills.html")
                return nothing
            end
        end

        nested_test("vertical_lines") do
            configuration.vertical_bands.middle.line_offset = 1.25
            configuration.vertical_bands.low.line_offset = 0.75
            configuration.vertical_bands.high.line_offset = 1.5
            test_html(data, configuration, "points.vertical_lines.html")
            return nothing
        end

        nested_test("vertical_fills") do
            configuration.vertical_bands.middle.line_color = nothing
            configuration.vertical_bands.low.line_color = nothing
            configuration.vertical_bands.high.line_color = nothing
            configuration.vertical_bands.middle.fill_color = "#00ff0080"
            configuration.vertical_bands.low.fill_color = "#0000ff80"
            configuration.vertical_bands.high.fill_color = "ff000080"
            configuration.vertical_bands.low.line_offset = 0.75
            configuration.vertical_bands.high.line_offset = 1.5
            test_html(data, configuration, "points.vertical_fills.html")
            return nothing
        end

        nested_test("horizontal_lines") do
            configuration.horizontal_bands.middle.line_offset = 1.25
            configuration.horizontal_bands.low.line_offset = 0.75
            configuration.horizontal_bands.high.line_offset = 1.5
            test_html(data, configuration, "points.horizontal_lines.html")
            return nothing
        end

        nested_test("horizontal_fills") do
            configuration.horizontal_bands.middle.line_color = nothing
            configuration.horizontal_bands.low.line_color = nothing
            configuration.horizontal_bands.high.line_color = nothing
            configuration.horizontal_bands.middle.fill_color = "#00ff0080"
            configuration.horizontal_bands.low.fill_color = "#0000ff80"
            configuration.horizontal_bands.high.fill_color = "ff000080"
            configuration.horizontal_bands.low.line_offset = 0.75
            configuration.horizontal_bands.high.line_offset = 1.5
            test_html(data, configuration, "points.horizontal_fills.html")
            return nothing
        end

        nested_test("color") do
            configuration.style.color = "red"

            nested_test("()") do
                test_html(data, configuration, "points.color.html")
                return nothing
            end
        end

        nested_test("colors") do
            data.colors = ["red", "green", "blue"]

            nested_test("()") do
                test_html(data, configuration, "points.colors.html")
                return nothing
            end

            nested_test("!legend") do
                configuration.style.show_scale = true
                @test_throws "explicit data.colors specified for points style.show_scale" render(data, configuration)
            end
        end

        nested_test("categorical") do
            data.colors = ["Foo", "Bar", "Baz"]
            configuration.style.color_scale = [("Foo", "red"), ("Bar", "green"), ("Baz", "blue"), ("Vaz", "magenta")]

            nested_test("()") do
                test_html(data, configuration, "points.categorical.html")
                return nothing
            end

            nested_test("!reversed") do
                configuration.style.reverse_scale = true
                @test_throws "reversed categorical points style.color_scale" render(data, configuration)
            end

            nested_test("legend") do
                configuration.style.show_scale = true
                test_legend(data, configuration, "points.categorical") do
                    return data.scale_title = "Points"
                end
                return nothing
            end
        end

        nested_test("continuous") do
            data.colors = [0.0, 1.0, 2.0]

            nested_test("()") do
                test_html(data, configuration, "points.continuous.html")
                return nothing
            end

            nested_test("invalid") do
                nested_test("!colorscale") do
                    configuration.style.color_scale = Vector{Tuple{Real, String}}()
                    @test_throws "empty points style.color_scale" render(data, configuration)
                    return nothing
                end

                nested_test("~colorscale") do
                    configuration.style.color_scale = [(-1.0, "blue"), (-1.0, "red")]
                    @test_throws "single points style.color_scale value: -1.0" render(data, configuration)
                    return nothing
                end
            end

            nested_test("viridis") do
                configuration.style.color_scale = "Viridis"
                test_html(data, configuration, "points.continuous.viridis.html")
                return nothing
            end

            nested_test("reversed") do
                configuration.style.reverse_scale = true
                test_html(data, configuration, "points.continuous.reversed.html")
                return nothing
            end

            nested_test("legend") do
                configuration.style.show_scale = true
                test_legend(data, configuration, "points.continuous") do
                    return data.scale_title = "Points"
                end
                return nothing
            end

            nested_test("gradient") do
                configuration.style.color_scale = [(-1.0, "blue"), (3.0, "red")]

                nested_test("()") do
                    test_html(data, configuration, "points.continuous.gradient.html")
                    return nothing
                end

                nested_test("reversed") do
                    configuration.style.reverse_scale = true
                    test_html(data, configuration, "points.continuous.gradient.reversed.html")
                    return nothing
                end

                nested_test("legend") do
                    configuration.style.show_scale = true
                    test_legend(data, configuration, "points.gradient") do
                        return data.scale_title = "Points"
                    end
                    return nothing
                end
            end
        end

        nested_test("size") do
            configuration.style.size = 10
            test_html(data, configuration, "points.size.html")
            return nothing
        end

        nested_test("sizes") do
            data.sizes = [10.0, 15.0, 20.0]
            test_html(data, configuration, "points.sizes.html")
            return nothing
        end

        nested_test("!grid") do
            configuration.graph.show_grid = false
            test_html(data, configuration, "points.!grid.html")
            return nothing
        end

        nested_test("titles") do
            data.x_axis_title = "X"
            data.y_axis_title = "Y"
            data.graph_title = "Graph"
            test_html(data, configuration, "points.titles.html")
            return nothing
        end

        nested_test("hovers") do
            data.hovers = ["<b>Foo</b><br>Low", "<b>Bar</b><br>Middle", "<b>Baz</b><br>High"]
            test_html(data, configuration, "points.hovers.html")
            return nothing
        end

        nested_test("border") do
            configuration.style.size = 6
            configuration.style.color = "black"

            nested_test("sizes") do
                data.border_sizes = [6, 8, 10]

                nested_test("()") do
                    test_html(data, configuration, "points.border.sizes.html")
                    return nothing
                end

                nested_test("color") do
                    configuration.border_style.color = "red"
                    test_html(data, configuration, "points.border.sizes.color.html")
                    return nothing
                end

                nested_test("!legend") do
                    configuration.border_style.show_scale = true
                    @test_throws "no data.border_colors specified for points border_style.show_scale" render(
                        data,
                        configuration,
                    )
                end
            end

            nested_test("colors") do
                data.border_colors = ["red", "green", "blue"]

                nested_test("()") do
                    test_html(data, configuration, "points.border.colors.html")
                    return nothing
                end

                nested_test("size") do
                    configuration.border_style.size = 6
                    test_html(data, configuration, "points.border.colors.size.html")
                    return nothing
                end

                nested_test("!legend") do
                    configuration.border_style.show_scale = true
                    @test_throws "explicit data.border_colors specified for points border_style.show_scale" render(
                        data,
                        configuration,
                    )
                end
            end

            nested_test("continuous") do
                data.border_colors = [0.0, 1.0, 2.0]

                nested_test("()") do
                    test_html(data, configuration, "points.border.continuous.html")
                    return nothing
                end

                nested_test("size") do
                    configuration.border_style.size = 6
                    test_html(data, configuration, "points.border.continuous.size.html")
                    return nothing
                end

                nested_test("legend") do
                    configuration.border_style.show_scale = true
                    test_legend(data, configuration, "points.border.continuous") do
                        return data.border_scale_title = "Borders"
                    end

                    nested_test("legend") do
                        data.colors = [20.0, 10.0, 0.0]
                        configuration.style.color_scale = "Viridis"
                        configuration.style.show_scale = true
                        test_legend(data, configuration, "points.border.continuous.legend") do
                            return data.scale_title = "Points"
                        end
                        nested_test("title") do
                            data.border_scale_title = "Borders"
                            test_legend(data, configuration, "points.border.continuous.legend.title") do
                                return data.scale_title = "Points"
                            end
                        end
                    end
                end
            end

            nested_test("categorical") do
                data.border_colors = ["Foo", "Bar", "Baz"]
                configuration.border_style.color_scale =
                    [("Foo", "red"), ("Bar", "green"), ("Baz", "blue"), ("Vaz", "magenta")]

                nested_test("()") do
                    test_html(data, configuration, "points.border.categorical.html")
                    return nothing
                end

                nested_test("legend") do
                    configuration.border_style.show_scale = true
                    test_legend(data, configuration, "points.border.categorical.colors") do
                        return data.border_scale_title = "Borders"
                    end

                    nested_test("legend") do
                        data.colors = ["X", "Y", "Z"]
                        configuration.style.color_scale = [("X", "cyan"), ("Y", "magenta"), ("Z", "yellow")]
                        configuration.style.show_scale = true
                        test_legend(data, configuration, "points.border.categorical.legend") do
                            return data.scale_title = "Points"
                        end
                        nested_test("title") do
                            data.border_scale_title = "Borders"
                            test_legend(data, configuration, "points.border.categorical.legend.title") do
                                return data.scale_title = "Points"
                            end
                        end
                    end
                end
            end
        end

        nested_test("edges") do
            data.edges = [(1, 2), (1, 3)]

            nested_test("()") do
                test_html(data, configuration, "points.edges.html")
                return nothing
            end

            nested_test("invalid") do
                nested_test("!from") do
                    data.edges[1] = (-1, 2)
                    @test_throws "edge#1 from invalid point: -1" render(data, configuration)
                end

                nested_test("!to") do
                    data.edges[1] = (1, 4)
                    @test_throws "edge#1 to invalid point: 4" render(data, configuration)
                end

                nested_test("self!") do
                    data.edges[1] = (1, 1)
                    @test_throws "edge#1 from point to itself: 1" render(data, configuration)
                end
            end

            nested_test("size") do
                configuration.edges_style.size = 8
                test_html(data, configuration, "points.edges.size.html")
                return nothing
            end

            nested_test("sizes") do
                data.edges_sizes = [6, 10]
                test_html(data, configuration, "points.edges.sizes.html")
                return nothing
            end

            nested_test("color") do
                configuration.edges_style.color = "magenta"
                test_html(data, configuration, "points.edges.color.html")
                return nothing
            end

            nested_test("colors") do
                data.edges_colors = ["red", "green"]
                test_html(data, configuration, "points.edges.colors.html")
                return nothing
            end
        end
    end
end
