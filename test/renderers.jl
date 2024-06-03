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

function test_svg(data::AbstractGraphData, configuration::AbstractGraphConfiguration, path::AbstractString)::Nothing
    render(data, configuration; output_file = "actual.svg")
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
    render(data, configuration; output_file = "actual.html")
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

        nested_test("invalid") do
            nested_test("!style") do
                configuration.distribution.show_box = false
                @test_throws "must specify at least one of: configuration.distribution.show_box, configuration.distribution.show_violin, configuration.distribution.show_curve" render(
                    data,
                    configuration,
                )
            end

            nested_test("!width") do
                configuration.graph.width = 0
                @test_throws "non-positive configuration.graph.width: 0" render(data, configuration)
            end

            nested_test("!height") do
                configuration.graph.height = 0
                @test_throws "non-positive configuration.graph.height: 0" render(data, configuration)
            end

            nested_test("!range") do
                configuration.value_axis.minimum = 1
                configuration.value_axis.maximum = 0
                @test_throws dedent("""
                    configuration.value_axis.maximum: 0
                    is not larger than configuration.value_axis.minimum: 1
                """) render(data, configuration)
            end

            nested_test("curve&violin") do
                configuration.distribution.show_curve = true
                configuration.distribution.show_violin = true
                @test_throws "must not specify both of: configuration.distribution.show_violin, configuration.distribution.show_curve" render(
                    data,
                    configuration,
                )
            end

            nested_test("!values") do
                data = DistributionGraphData(; distribution_values = Float32[])
                @test_throws "empty data.distribution_values vector" render(data)
            end

            nested_test("!log_regularization") do
                configuration.value_axis.log_regularization = -1.0
                @test_throws "negative configuration.value_axis.log_regularization: -1.0" render(data, configuration)
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
                configuration.distribution.values_orientation = HorizontalValues
                test_html(data, configuration, "distribution.box.horizontal.html")
                return nothing
            end

            nested_test("log") do
                configuration.value_axis.log_regularization = 0
                test_html(data, configuration, "distribution.box.log.html")
                return nothing
            end

            nested_test("outliers") do
                configuration.distribution.show_outliers = true
                test_html(data, configuration, "distribution.box.outliers.html")
                return nothing
            end

            nested_test("!color") do
                configuration.distribution.color = "oobleck"
                @test_throws "invalid configuration.distribution.color: oobleck" render(data, configuration)
                return nothing
            end
            nested_test("color") do
                configuration.distribution.color = "red"
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
                data.distribution_name = "Name"
                test_html(data, configuration, "distribution.box.titles.html")
                return nothing
            end
        end

        nested_test("violin") do
            configuration.distribution.show_box = false
            configuration.distribution.show_violin = true

            nested_test("()") do
                test_html(data, configuration, "distribution.violin.html")
                return nothing
            end

            nested_test("horizontal") do
                configuration.distribution.values_orientation = HorizontalValues
                test_html(data, configuration, "distribution.violin.horizontal.html")
                return nothing
            end

            nested_test("outliers") do
                configuration.distribution.show_outliers = true
                test_html(data, configuration, "distribution.violin.outliers.html")
                return nothing
            end

            nested_test("box") do
                configuration.distribution.show_box = true
                test_html(data, configuration, "distribution.violin.box.html")
                return nothing
            end

            nested_test("log") do
                configuration.value_axis.log_regularization = 0
                test_html(data, configuration, "distribution.violin.log.html")
                return nothing
            end
        end

        nested_test("curve") do
            configuration.distribution.show_box = false
            configuration.distribution.show_curve = true

            nested_test("()") do
                test_html(data, configuration, "distribution.curve.html")
                return nothing
            end

            nested_test("horizontal") do
                configuration.distribution.values_orientation = HorizontalValues
                test_html(data, configuration, "distribution.curve.horizontal.html")
                return nothing
            end

            nested_test("outliers") do
                configuration.distribution.show_outliers = true
                test_html(data, configuration, "distribution.curve.outliers.html")
                return nothing
            end

            nested_test("box") do
                configuration.distribution.show_box = true
                test_html(data, configuration, "distribution.curve.box.html")
                return nothing
            end

            nested_test("log") do
                configuration.value_axis.log_regularization = 0
                test_html(data, configuration, "distribution.curve.log.html")
                return nothing
            end
        end
    end

    nested_test("distributions") do
        configuration = DistributionsGraphConfiguration()
        data = DistributionsGraphData(;
            #! format: off
            distributions_values = [ [
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
                empty!(data.distributions_values)
                @test_throws "empty data.distributions_values vector" render(data, configuration)
            end

            nested_test("!value") do
                empty!(data.distributions_values[1])
                @test_throws "empty data.distributions_values[1] vector" render(data, configuration)
            end

            nested_test("~names") do
                data.distributions_names = ["Foo"]
                @test_throws dedent("""
                    the data.distributions_names size: 1
                    is different from the data.distributions_values size: 2
                """) render(data, configuration)
            end

            nested_test("!colors") do
                data.distributions_colors = ["Red", "Oobleck"]
                @test_throws "invalid data.distributions_colors[2]: Oobleck" render(data, configuration)
            end

            nested_test("~colors") do
                data.distributions_colors = ["Red"]
                @test_throws dedent("""
                    the data.distributions_colors size: 1
                    is different from the data.distributions_values size: 2
                """) render(data, configuration)
            end

            nested_test("!distributions_gap") do
                configuration.distributions_gap = -1
                @test_throws "non-positive configuration.distributions_gap: -1" render(data, configuration)
            end

            nested_test("~distributions_gap") do
                configuration.distributions_gap = 1
                @test_throws "too-large configuration.distributions_gap: 1" render(data, configuration)
            end
        end

        nested_test("box") do
            nested_test("()") do
                test_html(data, configuration, "distributions.box.html")
                return nothing
            end

            nested_test("!distributions_gap") do
                configuration.distributions_gap = 0
                test_html(data, configuration, "distributions.box.!distributions_gap.html")
                return nothing
            end

            nested_test("horizontal") do
                configuration.distribution.values_orientation = HorizontalValues
                test_html(data, configuration, "distributions.box.horizontal.html")
                return nothing
            end

            nested_test("overlay") do
                configuration.overlay_distributions = true

                nested_test("()") do
                    test_html(data, configuration, "distributions.box.overlay.html")
                    return nothing
                end

                nested_test("horizontal") do
                    configuration.distribution.values_orientation = HorizontalValues
                    test_html(data, configuration, "distributions.box.overlay.horizontal.html")
                    return nothing
                end

                nested_test("legend") do
                    configuration.show_legend = true
                    test_html(data, configuration, "distributions.box.overlay.legend.html")
                    return nothing
                end
            end
        end

        nested_test("violin") do
            configuration.distribution.show_box = false
            configuration.distribution.show_violin = true

            nested_test("()") do
                test_html(data, configuration, "distributions.violin.html")
                return nothing
            end

            nested_test("!distributions_gap") do
                configuration.distributions_gap = 0
                test_html(data, configuration, "distributions.violin.!distributions_gap.html")
                return nothing
            end

            nested_test("horizontal") do
                configuration.distribution.values_orientation = HorizontalValues
                test_html(data, configuration, "distributions.violin.horizontal.html")
                return nothing
            end

            nested_test("overlay") do
                configuration.overlay_distributions = true

                nested_test("()") do
                    test_html(data, configuration, "distributions.violin.overlay.html")
                    return nothing
                end

                nested_test("horizontal") do
                    configuration.distribution.values_orientation = HorizontalValues
                    test_html(data, configuration, "distributions.violin.overlay.horizontal.html")
                    return nothing
                end

                nested_test("legend") do
                    configuration.show_legend = true
                    test_html(data, configuration, "distributions.violin.overlay.legend.html")
                    return nothing
                end
            end
        end

        nested_test("curve") do
            configuration.distribution.show_box = false
            configuration.distribution.show_curve = true

            nested_test("()") do
                test_html(data, configuration, "distributions.curve.html")
                return nothing
            end

            nested_test("!distributions_gap") do
                configuration.distributions_gap = 0
                println("Ignore the following warning:")
                test_html(data, configuration, "distributions.curve.!distributions_gap.html")
                return nothing
            end

            nested_test("horizontal") do
                configuration.distribution.values_orientation = HorizontalValues
                test_html(data, configuration, "distributions.curve.horizontal.html")
                return nothing
            end

            nested_test("overlay") do
                configuration.overlay_distributions = true

                nested_test("()") do
                    test_html(data, configuration, "distributions.curve.overlay.html")
                    return nothing
                end

                nested_test("horizontal") do
                    configuration.distribution.values_orientation = HorizontalValues
                    test_html(data, configuration, "distributions.curve.overlay.horizontal.html")
                    return nothing
                end

                nested_test("legend") do
                    configuration.show_legend = true
                    test_html(data, configuration, "distributions.curve.overlay.legend.html")
                    return nothing
                end
            end
        end

        nested_test("log") do
            configuration.value_axis.log_regularization = 0
            test_html(data, configuration, "distributions.log.html")
            return nothing
        end

        nested_test("colors") do
            data.distributions_colors = ["red", "green"]
            test_html(data, configuration, "distributions.box.colors.html")
            return nothing
        end

        nested_test("titles") do
            data.distributions_names = ["Foo", "Bar"]
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
            data.distributions_names = ["Foo", "Bar"]
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
        data = LineGraphData(; points_xs = [0.0, 1.0, 2.0], points_ys = [-0.2, 1.2, 1.8])

        nested_test("invalid") do
            nested_test("!line_width") do
                configuration.line.width = 0
                @test_throws "non-positive configuration.line.width: 0" render(data, configuration)
            end

            nested_test("!line_is_filled") do
                configuration.line.width = nothing
                @test_throws "either configuration.line.width or configuration.line.is_filled must be specified" render(
                    data,
                    configuration,
                )
            end

            nested_test("~ys") do
                push!(data.points_ys, 2.0)
                @test_throws dedent("""
                    the data.points_xs size: 3
                    is different from the data.points_ys size: 4
                """) render(data, configuration)
            end
        end

        nested_test("()") do
            test_html(data, configuration, "line.html")
            return nothing
        end

        nested_test("dash") do
            configuration.line.is_dashed = true
            test_html(data, configuration, "line.dash.html")
            return nothing
        end

        nested_test("size") do
            configuration.line.width = 5
            test_html(data, configuration, "line.size.html")
            return nothing
        end

        nested_test("color") do
            configuration.line.color = "red"
            test_html(data, configuration, "line.color.html")
            return nothing
        end

        nested_test("fill_below") do
            configuration.line.is_filled = true
            test_html(data, configuration, "line.fill_below.html")
            return nothing
        end

        nested_test("fill_below!line") do
            configuration.line.width = nothing
            configuration.line.is_filled = true
            test_html(data, configuration, "line.fill_below!line.html")
            return nothing
        end

        nested_test("!grid") do
            configuration.graph.show_grid = false
            configuration.graph.show_ticks = false
            test_html(data, configuration, "line.!grid.html")
            return nothing
        end

        nested_test("vertical_lines") do
            configuration.vertical_bands.low.offset = 0.75
            configuration.vertical_bands.middle.offset = 1.25
            configuration.vertical_bands.high.offset = 1.5

            nested_test("()") do
                test_html(data, configuration, "line.vertical_lines.html")
                return nothing
            end

            nested_test("colors") do
                configuration.vertical_bands.low.color = "green"
                configuration.vertical_bands.middle.color = "red"
                configuration.vertical_bands.high.color = "blue"
                return test_html(data, configuration, "line.vertical_lines.colors.html")
            end

            nested_test("!colors") do
                configuration.vertical_bands.low.color = "green"
                configuration.vertical_bands.middle.color = "oobleck"
                configuration.vertical_bands.high.color = "blue"
                @test_throws "invalid configuration.vertical_bands.middle.color: oobleck" render(data, configuration)
            end

            nested_test("legend") do
                configuration.vertical_bands.show_legend = true
                test_legend(data, configuration, "line.vertical_lines") do
                    data.vertical_bands.legend_title = "Vertical"
                    data.vertical_bands.low_title = "Left"
                    data.vertical_bands.middle_title = "Middle"
                    data.vertical_bands.high_title = "Right"
                    return nothing
                end
            end
        end

        nested_test("vertical_fills") do
            configuration.vertical_bands.low.is_filled = true
            configuration.vertical_bands.middle.is_filled = true
            configuration.vertical_bands.high.is_filled = true

            configuration.vertical_bands.low.width = nothing
            configuration.vertical_bands.middle.width = nothing
            configuration.vertical_bands.high.width = nothing

            configuration.vertical_bands.low.color = "green"
            configuration.vertical_bands.middle.color = "red"
            configuration.vertical_bands.high.color = "blue"

            configuration.vertical_bands.low.offset = 0.75
            configuration.vertical_bands.high.offset = 1.5

            nested_test("()") do
                return test_html(data, configuration, "line.vertical_fills.html")
            end

            nested_test("legend") do
                configuration.vertical_bands.show_legend = true
                test_legend(data, configuration, "line.vertical_fills") do
                    data.vertical_bands.legend_title = "Vertical"
                    data.vertical_bands.low_title = "Left"
                    data.vertical_bands.middle_title = "Middle"
                    data.vertical_bands.high_title = "Right"
                    return nothing
                end
            end
        end

        nested_test("horizontal_lines") do
            configuration.horizontal_bands.low.offset = 0.75
            configuration.horizontal_bands.middle.offset = 1.25
            configuration.horizontal_bands.high.offset = 1.5

            nested_test("()") do
                return test_html(data, configuration, "line.horizontal_lines.html")
            end

            nested_test("legend") do
                configuration.horizontal_bands.show_legend = true
                test_legend(data, configuration, "line.horizontal_lines") do
                    data.horizontal_bands.legend_title = "Horizontal"
                    data.horizontal_bands.low_title = "Low"
                    data.horizontal_bands.middle_title = "Middle"
                    data.horizontal_bands.high_title = "High"
                    return nothing
                end
            end
        end

        nested_test("horizontal_fills") do
            configuration.horizontal_bands.low.is_filled = true
            configuration.horizontal_bands.middle.is_filled = true
            configuration.horizontal_bands.high.is_filled = true

            configuration.horizontal_bands.low.color = "#0000ff"
            configuration.horizontal_bands.middle.color = "#00ff00"
            configuration.horizontal_bands.high.color = "#ff0000"

            configuration.horizontal_bands.low.offset = 0.75
            configuration.horizontal_bands.high.offset = 1.5

            nested_test("()") do
                return test_html(data, configuration, "line.horizontal_fills.html")
            end

            nested_test("legend") do
                nested_test("()") do
                    configuration.horizontal_bands.show_legend = true
                    test_legend(data, configuration, "line.horizontal_fills") do
                        data.horizontal_bands.legend_title = "Horizontal"
                        data.horizontal_bands.low_title = "Low"
                        data.horizontal_bands.middle_title = "Middle"
                        data.horizontal_bands.high_title = "High"
                        return nothing
                    end
                end

                nested_test("mix") do
                    configuration.horizontal_bands.show_legend = true
                    configuration.horizontal_bands.middle.is_filled = false
                    configuration.horizontal_bands.middle.color = nothing
                    configuration.horizontal_bands.middle.offset = 1.25
                    test_legend(data, configuration, "line.horizontal_mix") do
                        data.horizontal_bands.legend_title = "Horizontal"
                        data.horizontal_bands.low_title = "Low"
                        data.horizontal_bands.middle_title = "Middle"
                        data.horizontal_bands.high_title = "High"
                        return nothing
                    end
                end

                nested_test("part") do
                    configuration.horizontal_bands.show_legend = true
                    configuration.horizontal_bands.middle.is_filled = false
                    test_legend(data, configuration, "line.horizontal_part") do
                        data.horizontal_bands.legend_title = "Horizontal"
                        data.horizontal_bands.low_title = "Low"
                        data.horizontal_bands.middle_title = "Middle"
                        data.horizontal_bands.high_title = "High"
                        return nothing
                    end
                end
            end
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
            lines_xs = [[0.0, 1.0, 2.0], [0.25, 0.5, 1.5, 2.5]],
            lines_ys = [[-0.2, 1.2, 1.8], [0.1, 1.0, 0.5, 2.0]],
        )

        nested_test("()") do
            test_html(data, configuration, "lines.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!lines") do
                empty!(data.lines_xs)
                empty!(data.lines_ys)
                @test_throws "empty data.lines_xs and data.lines_ys vectors" render(data, configuration)
            end

            nested_test("~ys") do
                push!(data.lines_ys, [2.0])
                @test_throws dedent("""
                    the data.lines_xs size: 2
                    is different from the data.lines_ys size: 3
                """) render(data, configuration)
            end

            nested_test("~points") do
                push!(data.lines_ys[2], 1.0)
                @test_throws dedent("""
                    the data.lines_xs[2] size: 4
                    is different from the data.lines_ys[2] size: 5
                """) render(data, configuration)
            end

            nested_test("~xs") do
                empty!(data.lines_xs[1])
                empty!(data.lines_ys[1])
                @test_throws "too few points in data.lines_xs[1] and data.lines_ys[1]: 0" render(data, configuration)
            end

            nested_test("~names") do
                data.lines_names = ["Foo"]
                @test_throws dedent("""
                    the data.lines_names size: 1
                    is different from the data.lines_xs and data.lines_ys size: 2
                """) render(data, configuration)
            end

            nested_test("!colors") do
                data.lines_colors = ["red", "oobleck"]
                @test_throws "invalid data.lines_colors[2]: oobleck" render(data, configuration)
            end

            nested_test("~colors") do
                data.lines_colors = ["red"]
                @test_throws dedent("""
                    the data.lines_colors size: 1
                    is different from the data.lines_xs and data.lines_ys size: 2
                """) render(data, configuration)
            end

            nested_test("~sizes") do
                data.lines_widths = [1]
                @test_throws dedent("""
                    the data.lines_widths size: 1
                    is different from the data.lines_xs and data.lines_ys size: 2
                """) render(data, configuration)
            end

            nested_test("!sizes") do
                data.lines_widths = [1, -1]
                @test_throws "non-positive data.lines_widths[2]: -1" render(data, configuration)
            end

            nested_test("!fill_below") do
                configuration.line.width = nothing
                @test_throws "either configuration.line.width or configuration.line.is_filled must be specified" render(
                    data,
                    configuration,
                )
            end

            nested_test("~fills") do
                data.lines_are_filled = [true]
                @test_throws dedent("""
                    the data.lines_are_filled size: 1
                    is different from the data.lines_xs and data.lines_ys size: 2
                """) render(data, configuration)
            end

            nested_test("~dashs") do
                data.lines_are_dashed = [true]
                @test_throws dedent("""
                    the data.lines_are_dashed size: 1
                    is different from the data.lines_xs and data.lines_ys size: 2
                """) render(data, configuration)
            end
        end

        nested_test("size") do
            configuration.line.width = 4
            test_html(data, configuration, "lines.size.html")
            return nothing
        end

        nested_test("sizes") do
            data.lines_widths = [4, 8]
            test_html(data, configuration, "lines.sizes.html")
            return nothing
        end

        nested_test("color") do
            configuration.line.color = "red"
            test_html(data, configuration, "lines.color.html")
            return nothing
        end

        nested_test("colors") do
            data.lines_colors = ["red", "green"]
            test_html(data, configuration, "lines.colors.html")
            return nothing
        end

        nested_test("dash") do
            configuration.line.is_dashed = true
            test_html(data, configuration, "lines.dash.html")
            return nothing
        end

        nested_test("dashs") do
            data.lines_are_dashed = [true, false]
            test_html(data, configuration, "lines.dashs.html")
            return nothing
        end

        nested_test("fill") do
            configuration.line.is_filled = true

            nested_test("()") do
                test_html(data, configuration, "lines.fill.html")
                return nothing
            end

            nested_test("!line") do
                configuration.line.width = nothing
                test_html(data, configuration, "lines.fill.!line.html")
                return nothing
            end
        end

        nested_test("fills") do
            data.lines_are_filled = [true, false]
            test_html(data, configuration, "lines.fills.html")
            return nothing
        end

        nested_test("stack") do
            nested_test("values") do
                configuration.data_stacking = StackDataValues
                test_html(data, configuration, "lines.stack.values.html")
                return nothing
            end

            nested_test("percents") do
                data.lines_ys[1][1] = 0.2
                configuration.data_stacking = StackDataPercents
                test_html(data, configuration, "lines.stack.percents.html")
                return nothing
            end

            nested_test("fractions") do
                data.lines_ys[1][1] = 0.2
                configuration.data_stacking = StackDataFractions
                test_html(data, configuration, "lines.stack.fractions.html")
                return nothing
            end
        end

        nested_test("vertical_lines") do
            configuration.vertical_bands.low.offset = 0.75
            configuration.vertical_bands.middle.offset = 1.25
            configuration.vertical_bands.high.offset = 1.5

            nested_test("()") do
                test_html(data, configuration, "lines.vertical_lines.html")
                return nothing
            end

            nested_test("colors") do
                configuration.vertical_bands.low.color = "green"
                configuration.vertical_bands.middle.color = "red"
                configuration.vertical_bands.high.color = "blue"
                return test_html(data, configuration, "lines.vertical_lines.colors.html")
            end

            nested_test("!colors") do
                configuration.vertical_bands.low.color = "green"
                configuration.vertical_bands.middle.color = "oobleck"
                configuration.vertical_bands.high.color = "blue"
                @test_throws "invalid configuration.vertical_bands.middle.color: oobleck" render(data, configuration)
            end

            nested_test("legend") do
                configuration.vertical_bands.show_legend = true
                test_legend(data, configuration, "lines.vertical_lines") do
                    data.vertical_bands.legend_title = "Vertical"
                    data.vertical_bands.low_title = "Left"
                    data.vertical_bands.middle_title = "Middle"
                    data.vertical_bands.high_title = "Right"
                    return nothing
                end
            end
        end

        nested_test("vertical_fills") do
            configuration.vertical_bands.low.is_filled = true
            configuration.vertical_bands.middle.is_filled = true
            configuration.vertical_bands.high.is_filled = true

            configuration.vertical_bands.low.width = nothing
            configuration.vertical_bands.middle.width = nothing
            configuration.vertical_bands.high.width = nothing

            configuration.vertical_bands.low.color = "green"
            configuration.vertical_bands.middle.color = "red"
            configuration.vertical_bands.high.color = "blue"

            configuration.vertical_bands.low.offset = 0.75
            configuration.vertical_bands.high.offset = 1.5

            nested_test("()") do
                return test_html(data, configuration, "lines.vertical_fills.html")
            end

            nested_test("legend") do
                configuration.vertical_bands.show_legend = true
                test_legend(data, configuration, "lines.vertical_fills") do
                    data.vertical_bands.legend_title = "Vertical"
                    data.vertical_bands.low_title = "Left"
                    data.vertical_bands.middle_title = "Middle"
                    data.vertical_bands.high_title = "Right"
                    return nothing
                end
            end
        end

        nested_test("horizontal_lines") do
            configuration.horizontal_bands.low.offset = 0.75
            configuration.horizontal_bands.middle.offset = 1.25
            configuration.horizontal_bands.high.offset = 1.5
            nested_test("()") do
                return test_html(data, configuration, "lines.horizontal_lines.html")
            end

            nested_test("legend") do
                configuration.horizontal_bands.show_legend = true
                test_legend(data, configuration, "lines.horizontal_lines") do
                    data.horizontal_bands.legend_title = "Horizontal"
                    data.horizontal_bands.low_title = "Low"
                    data.horizontal_bands.middle_title = "Middle"
                    data.horizontal_bands.high_title = "High"
                    return nothing
                end
            end
        end

        nested_test("horizontal_fills") do
            configuration.horizontal_bands.low.is_filled = true
            configuration.horizontal_bands.middle.is_filled = true
            configuration.horizontal_bands.high.is_filled = true

            configuration.horizontal_bands.low.width = nothing
            configuration.horizontal_bands.middle.width = nothing
            configuration.horizontal_bands.high.width = nothing

            configuration.horizontal_bands.low.color = "#0000ff"
            configuration.horizontal_bands.middle.color = "#00ff00"
            configuration.horizontal_bands.high.color = "#ff0000"

            configuration.horizontal_bands.low.offset = 0.75
            configuration.horizontal_bands.high.offset = 1.5

            nested_test("()") do
                return test_html(data, configuration, "lines.horizontal_fills.html")
            end

            nested_test("legend") do
                configuration.horizontal_bands.show_legend = true
                test_legend(data, configuration, "lines.horizontal_fills") do
                    data.horizontal_bands.legend_title = "Horizontal"
                    data.horizontal_bands.low_title = "Low"
                    data.horizontal_bands.middle_title = "Middle"
                    data.horizontal_bands.high_title = "High"
                    return nothing
                end
            end
        end

        nested_test("legend") do
            configuration.show_legend = true

            nested_test("()") do
                test_legend(data, configuration, "lines") do
                    data.legend_title = "Lines"
                    return nothing
                end
                return nothing
            end

            nested_test("names") do
                data.lines_names = ["Foo", "Bar"]
                test_legend(data, configuration, "lines.names") do
                    data.legend_title = "Lines"
                    return nothing
                end
                return nothing
            end
        end
    end

    nested_test("cdf") do
        configuration = CdfGraphConfiguration()
        data = CdfGraphData(;
            line_values = [
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
            test_html(data, configuration, "cdf.html")
            return nothing
        end

        nested_test("~values") do
            empty!(data.line_values)
            @test_throws "too few data.line_values: 0" render(data, configuration)
        end

        nested_test("vertical") do
            configuration.values_orientation = VerticalValues
            configuration.value_bands.middle.offset = 110
            configuration.fraction_bands.middle.offset = 0.5
            configuration.fraction_bands.middle.is_dashed = true
            test_html(data, configuration, "cdf.vertical.html")
            return nothing
        end

        nested_test("percent") do
            configuration.show_percent = true
            configuration.value_bands.middle.offset = 110
            configuration.fraction_bands.middle.offset = 0.5
            configuration.fraction_bands.middle.is_dashed = true
            test_html(data, configuration, "cdf.percent.html")
            return nothing
        end

        nested_test("downto") do
            configuration.cdf_direction = CdfDownToValue
            test_html(data, configuration, "cdf.downto.html")
            return nothing
        end
    end

    nested_test("cdfs") do
        configuration = CdfsGraphConfiguration()
        data = CdfsGraphData(;
            lines_values = [
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
            test_html(data, configuration, "cdfs.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("~values") do
                empty!(data.lines_values)
                @test_throws "empty data.lines_values vector" render(data, configuration)
            end

            nested_test("!values") do
                empty!(data.lines_values[2])
                @test_throws "too few data.lines_values[2]: 0" render(data, configuration)
            end
        end

        nested_test("vertical") do
            configuration.values_orientation = VerticalValues
            configuration.value_bands.middle.offset = 11
            configuration.fraction_bands.middle.offset = 0.5
            configuration.fraction_bands.middle.is_dashed = true
            test_html(data, configuration, "cdfs.vertical.html")
            return nothing
        end

        nested_test("percent") do
            configuration.show_percent = true
            configuration.value_bands.middle.offset = 11
            configuration.fraction_bands.middle.offset = 0.5
            configuration.fraction_bands.middle.is_dashed = true
            test_html(data, configuration, "cdfs.percent.html")
            return nothing
        end

        nested_test("downto") do
            configuration.cdf_direction = CdfDownToValue
            test_html(data, configuration, "cdfs.downto.html")
            return nothing
        end

        nested_test("legend") do
            configuration.show_legend = true
            test_legend(data, configuration, "cdfs") do
                data.legend_title = "Traces"
                return nothing
            end
            return nothing
        end
    end

    nested_test("bar") do
        data = BarGraphData(; bars_values = [-0.2, 1.2, 1.8])
        configuration = BarGraphConfiguration()

        nested_test("()") do
            test_html(data, configuration, "bar.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!bars_gap") do
                configuration.bars_gap = -1
                @test_throws "non-positive configuration.bars_gap: -1" render(data, configuration)
            end

            nested_test("~bars_gap") do
                configuration.bars_gap = 1
                @test_throws "too-large configuration.bars_gap: 1" render(data, configuration)
            end

            nested_test("~values") do
                empty!(data.bars_values)
                @test_throws "empty data.bars_values vector" render(data, configuration)
            end

            nested_test("~names") do
                data.bars_names = ["Foo"]
                @test_throws dedent("""
                    the data.bars_names size: 1
                    is different from the data.bars_values size: 3
                """) render(data, configuration)
            end

            nested_test("~hovers") do
                data.bars_hovers = ["Foo"]
                @test_throws dedent("""
                    the data.bars_hovers size: 1
                    is different from the data.bars_values size: 3
                """) render(data, configuration)
            end

            nested_test("~colors") do
                data.bars_colors = ["red"]
                @test_throws dedent("""
                    the data.bars_colors size: 1
                    is different from the data.bars_values size: 3
                """) render(data, configuration)
            end

            nested_test("!colors") do
                data.bars_colors = ["red", "oobleck", "blue"]
                @test_throws "invalid data.bars_colors[2]: oobleck" render(data, configuration)
            end
        end

        nested_test("names") do
            data.bars_names = ["Foo", "Bar", "Baz"]
            test_html(data, configuration, "bar.names.html")
            return nothing
        end

        nested_test("titles") do
            data.graph_title = "Graph"
            data.bar_axis_title = "Bars"
            data.value_axis_title = "Values"
            test_html(data, configuration, "bar.titles.html")
            return nothing
        end

        nested_test("horizontal") do
            configuration.values_orientation = HorizontalValues

            nested_test("()") do
                test_html(data, configuration, "bar.horizontal.html")
                return nothing
            end

            nested_test("names") do
                data.bars_names = ["Foo", "Bar", "Baz"]
                test_html(data, configuration, "bar.horizontal.names.html")
                return nothing
            end

            nested_test("titles") do
                data.graph_title = "Graph"
                data.bar_axis_title = "Bars"
                data.value_axis_title = "Values"
                test_html(data, configuration, "bar.horizontal.titles.html")
                return nothing
            end
        end

        nested_test("!bars_gap") do
            configuration.bars_gap = 0
            test_html(data, configuration, "bar.!bars_gap.html")
            return nothing
        end

        nested_test("color") do
            configuration.bars_color = "red"
            test_html(data, configuration, "bar.color.html")
            return nothing
        end

        nested_test("colors") do
            data.bars_colors = ["red", "green", "blue"]
            test_html(data, configuration, "bar.colors.html")
            return nothing
        end

        nested_test("hovers") do
            data.bars_hovers = ["Foo", "Bar", "Baz"]
            test_html(data, configuration, "bar.hovers.html")
            return nothing
        end
    end

    nested_test("bars") do
        data = BarsGraphData(; series_values = [[0.0, 1.0, 2.0], [0.2, 1.2, 1.8]])
        configuration = BarsGraphConfiguration()

        nested_test("()") do
            test_html(data, configuration, "bars.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!values") do
                empty!(data.series_values)
                @test_throws "empty data.series_values vector" render(data, configuration)
            end

            nested_test("!!values") do
                empty!(data.series_values[1])
                empty!(data.series_values[2])
                @test_throws "empty data.series_values vectors" render(data, configuration)
            end

            nested_test("~values") do
                push!(data.series_values[1], 0.0)
                @test_throws dedent("""
                    the data.series_values[2] size: 3
                    is different from the data.series_values[1] size: 4
                """) render(data, configuration)
            end

            nested_test("~bars_names") do
                data.bars_names = ["Foo"]
                @test_throws dedent("""
                    the data.bars_names size: 1
                    is different from the data.series_values[:] size: 3
                """) render(data, configuration)
            end

            nested_test("~series_names") do
                data.series_names = ["Foo"]
                @test_throws dedent("""
                    the data.series_names size: 1
                    is different from the data.series_values size: 2
                """) render(data, configuration)
            end

            nested_test("~series_hovers") do
                data.series_hovers = ["Foo"]
                @test_throws dedent("""
                    the data.series_hovers size: 1
                    is different from the data.series_values size: 2
                """) render(data, configuration)
            end

            nested_test("~bars_hovers") do
                data.bars_hovers = ["Foo"]
                @test_throws dedent("""
                    the data.bars_hovers size: 1
                    is different from the data.series_values[:] size: 3
                """) render(data, configuration)
            end

            nested_test("~colors") do
                data.series_colors = ["red"]
                @test_throws dedent("""
                    the data.series_colors size: 1
                    is different from the data.series_values size: 2
                """) render(data, configuration)
            end

            nested_test("!colors") do
                data.series_colors = ["red", "oobleck"]
                @test_throws "invalid data.series_colors[2]: oobleck" render(data, configuration)
            end
        end

        nested_test("stack") do
            nested_test("values") do
                configuration.data_stacking = StackDataValues
                test_html(data, configuration, "bars.stack.values.html")
                return nothing
            end

            nested_test("percents") do
                configuration.data_stacking = StackDataPercents
                test_html(data, configuration, "bars.stack.percents.html")
                return nothing
            end

            nested_test("fractions") do
                configuration.data_stacking = StackDataFractions
                test_html(data, configuration, "bars.stack.fractions.html")
                return nothing
            end
        end

        nested_test("!bars_gap") do
            configuration.bars_gap = 0
            test_html(data, configuration, "bars.!bars_gap.html")
            return nothing
        end

        nested_test("legend") do
            configuration.show_legend = true
            test_legend(data, configuration, "bars") do
                data.legend_title = "Series"
                return nothing
            end
        end

        nested_test("names") do
            data.series_names = ["Foo", "Bar"]

            nested_test("()") do
                test_html(data, configuration, "bars.names.html")
                return nothing
            end

            nested_test("legend") do
                configuration.show_legend = true
                test_legend(data, configuration, "bars.names") do
                    data.legend_title = "Series"
                    return nothing
                end
            end
        end

        nested_test("bars_names") do
            data.bars_names = ["Foo", "Bar", "Baz"]
            test_html(data, configuration, "bars.bar_names.html")
            return nothing
        end

        nested_test("titles") do
            data.graph_title = "Graph"
            data.bar_axis_title = "Bars"
            data.value_axis_title = "Values"
            test_html(data, configuration, "bars.titles.html")
            return nothing
        end

        nested_test("horizontal") do
            configuration.values_orientation = HorizontalValues

            nested_test("()") do
                test_html(data, configuration, "bars.horizontal.html")
                return nothing
            end

            nested_test("names") do
                data.series_names = ["Foo", "Bar"]
                test_html(data, configuration, "bars.horizontal.names.html")
                return nothing
            end

            nested_test("bars_names") do
                data.bars_names = ["Foo", "Bar", "Baz"]
                test_html(data, configuration, "bars.horizontal.bar_names.html")
                return nothing
            end

            nested_test("titles") do
                data.graph_title = "Graph"
                data.bar_axis_title = "Bars"
                data.value_axis_title = "Values"
                test_html(data, configuration, "bars.horizontal.titles.html")
                return nothing
            end
        end

        nested_test("colors") do
            data.series_colors = ["red", "green"]
            test_html(data, configuration, "bars.colors.html")
            return nothing
        end

        nested_test("hovers") do
            nested_test("series") do
                data.series_hovers = ["Foo", "Bar"]
                test_html(data, configuration, "bars.hovers.series.html")
                return nothing
            end

            nested_test("bars") do
                data.bars_hovers = ["Foo", "Bar", "Baz"]
                test_html(data, configuration, "bars.hovers.bars.html")
                return nothing
            end

            nested_test("both") do
                data.series_hovers = ["Foo", "Bar"]
                data.bars_hovers = ["Baz", "Vaz", "Var"]
                test_html(data, configuration, "bars.hovers.both.html")
                return nothing
            end
        end
    end

    nested_test("points") do
        configuration = PointsGraphConfiguration()
        data = PointsGraphData(; points_xs = [0.0, 1.0, 2.0], points_ys = [-0.2, 1.2, 1.8])

        nested_test("()") do
            test_html(data, configuration, "points.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!size") do
                configuration.points.size = 0
                @test_throws "non-positive configuration.points.size: 0" render(data, configuration)
            end

            nested_test("!line-width") do
                configuration.diagonal_bands.middle.width = 0
                @test_throws "non-positive configuration.diagonal_bands.middle.width: 0" render(data, configuration)
            end

            nested_test("~ys") do
                push!(data.points_ys, 2.0)
                @test_throws dedent("""
                    the data.points_xs size: 3
                    is different from the data.points_ys size: 4
                """) render(data, configuration)
            end

            nested_test("!colors") do
                configuration.points.show_color_scale = true
                @test_throws "no data.points_colors specified for configuration.points.show_color_scale" render(
                    data,
                    configuration,
                )
            end

            nested_test("~colors") do
                data.points_colors = ["Red"]
                @test_throws dedent("""
                    the data.points_colors size: 1
                    is different from the data.points_xs and data.points_ys size: 3
                """) render(data, configuration)
            end

            nested_test("!borders_colors") do
                configuration.borders.show_color_scale = true
                @test_throws "no data.borders_colors specified for configuration.borders.show_color_scale" render(
                    data,
                    configuration,
                )
            end

            nested_test("~borders_colors") do
                data.borders_colors = ["Red"]
                @test_throws dedent("""
                    the data.borders_colors size: 1
                    is different from the data.points_xs and data.points_ys size: 3
                """) render(data, configuration)
            end

            nested_test("~sizes") do
                data.points_sizes = [1.0, 2.0, 3.0, 4.0]
                @test_throws dedent("""
                    the data.points_sizes size: 4
                    is different from the data.points_xs and data.points_ys size: 3
                """) render(data, configuration)
            end

            nested_test("~borders_sizes") do
                data.borders_sizes = [1.0, 2.0, 3.0, 4.0]
                @test_throws dedent("""
                    the data.borders_sizes size: 4
                    is different from the data.points_xs and data.points_ys size: 3
                """) render(data, configuration)
            end

            nested_test("!sizes") do
                data.points_sizes = [1.0, -1.0, 3.0]
                @test_throws "negative data.points_sizes[2]: -1.0" render(data, configuration)
            end

            nested_test("!borders_sizes") do
                data.borders_sizes = [1.0, -1.0, 3.0]
                @test_throws "negative data.borders_sizes[2]: -1.0" render(data, configuration)
            end

            nested_test("~hovers") do
                data.points_hovers = ["Foo"]
                @test_throws dedent("""
                    the data.points_hovers size: 1
                    is different from the data.points_xs and data.points_ys size: 3
                """) render(data, configuration)
            end
        end

        nested_test("invalid") do
            nested_test("!low") do
                configuration.diagonal_bands.low.offset = 0.1
                configuration.diagonal_bands.middle.offset = 0
                configuration.diagonal_bands.high.offset = 0.3

                @test_throws dedent("""
                    configuration.diagonal_bands.low.offset: 0.1
                    is not less than configuration.diagonal_bands.middle.offset: 0
                """) render(data, configuration)
                return nothing
            end

            nested_test("!high") do
                configuration.diagonal_bands.low.offset = -0.3
                configuration.diagonal_bands.middle.offset = 0
                configuration.diagonal_bands.high.offset = -0.1

                @test_throws dedent("""
                    configuration.diagonal_bands.high.offset: -0.1
                    is not greater than configuration.diagonal_bands.middle.offset: 0
                """) render(data, configuration)
                return nothing
            end

            nested_test("!middle") do
                configuration.diagonal_bands.low.offset = 0.3
                configuration.diagonal_bands.high.offset = -0.3

                @test_throws dedent("""
                    configuration.diagonal_bands.low.offset: 0.3
                    is not less than configuration.diagonal_bands.high.offset: -0.3
                """) render(data, configuration)
                return nothing
            end
        end

        nested_test("diagonal") do
            nested_test("()") do
                configuration.diagonal_bands.low.offset = -0.3
                configuration.diagonal_bands.high.offset = 0.3
                configuration.diagonal_bands.middle.offset = 0

                configuration.diagonal_bands.middle.width = 8

                test_html(data, configuration, "points.diagonal.html")
                return nothing
            end

            nested_test("low_fills") do
                configuration.diagonal_bands.low.is_filled = true
                configuration.diagonal_bands.middle.is_filled = true
                configuration.diagonal_bands.high.is_filled = true

                configuration.diagonal_bands.low.width = nothing
                configuration.diagonal_bands.middle.width = nothing
                configuration.diagonal_bands.high.width = nothing

                configuration.diagonal_bands.low.color = "#0000ff"
                configuration.diagonal_bands.middle.color = "#00ff00"
                configuration.diagonal_bands.high.color = "#ff0000"

                configuration.diagonal_bands.low.offset = -0.6
                configuration.diagonal_bands.high.offset = -0.3

                test_html(data, configuration, "points.diagonal.low_fills.html")
                return nothing
            end

            nested_test("high_fills") do
                configuration.diagonal_bands.low.is_filled = true
                configuration.diagonal_bands.middle.is_filled = true
                configuration.diagonal_bands.high.is_filled = true

                configuration.diagonal_bands.low.width = nothing
                configuration.diagonal_bands.middle.width = nothing
                configuration.diagonal_bands.high.width = nothing

                configuration.diagonal_bands.low.color = "#0000ff"
                configuration.diagonal_bands.middle.color = "#00ff00"
                configuration.diagonal_bands.high.color = "#ff0000"

                configuration.diagonal_bands.low.offset = 0.3
                configuration.diagonal_bands.high.offset = 0.6

                test_html(data, configuration, "points.diagonal.high_fills.html")
                return nothing
            end

            nested_test("middle_fills") do
                configuration.diagonal_bands.low.is_filled = true
                configuration.diagonal_bands.middle.is_filled = true
                configuration.diagonal_bands.high.is_filled = true

                configuration.diagonal_bands.low.offset = -0.3
                configuration.diagonal_bands.high.offset = 0.6

                test_html(data, configuration, "points.diagonal.middle_fills.html")
                return nothing
            end
        end

        nested_test("vertical_lines") do
            configuration.vertical_bands.low.offset = 0.75
            configuration.vertical_bands.middle.offset = 1.25
            configuration.vertical_bands.high.offset = 1.5

            test_html(data, configuration, "points.vertical_lines.html")
            return nothing
        end

        nested_test("vertical_fills") do
            configuration.vertical_bands.low.is_filled = true
            configuration.vertical_bands.middle.is_filled = true
            configuration.vertical_bands.high.is_filled = true

            configuration.vertical_bands.low.width = nothing
            configuration.vertical_bands.middle.width = nothing
            configuration.vertical_bands.high.width = nothing

            configuration.vertical_bands.low.color = "#0000ff"
            configuration.vertical_bands.middle.color = "#00ff00"
            configuration.vertical_bands.high.color = "#ff0000"

            configuration.vertical_bands.low.offset = 0.75
            configuration.vertical_bands.high.offset = 1.5

            test_html(data, configuration, "points.vertical_fills.html")
            return nothing
        end

        nested_test("horizontal_lines") do
            configuration.horizontal_bands.low.offset = 0.75
            configuration.horizontal_bands.middle.offset = 1.25
            configuration.horizontal_bands.high.offset = 1.5

            test_html(data, configuration, "points.horizontal_lines.html")
            return nothing
        end

        nested_test("horizontal_fills") do
            configuration.horizontal_bands.low.is_filled = true
            configuration.horizontal_bands.middle.is_filled = true
            configuration.horizontal_bands.high.is_filled = true

            configuration.horizontal_bands.low.width = nothing
            configuration.horizontal_bands.middle.width = nothing
            configuration.horizontal_bands.high.width = nothing

            configuration.horizontal_bands.low.color = "#0000ff"
            configuration.horizontal_bands.middle.color = "#00ff00"
            configuration.horizontal_bands.high.color = "#ff0000"

            configuration.horizontal_bands.low.offset = 0.75
            configuration.horizontal_bands.high.offset = 1.5

            test_html(data, configuration, "points.horizontal_fills.html")
            return nothing
        end

        nested_test("log") do
            data.points_xs .*= 10
            data.points_ys .*= 10
            data.points_xs .+= 1
            data.points_ys .+= 3
            configuration.x_axis.log_regularization = 0
            configuration.y_axis.log_regularization = 0

            nested_test("invalid") do
                nested_test("!minimum") do
                    configuration.x_axis.minimum = 0.0
                    @test_throws "log of non-positive configuration.x_axis.minimum: 0.0" render(data, configuration)
                end

                nested_test("!maximum") do
                    configuration.y_axis.maximum = -1.0
                    @test_throws "log of non-positive configuration.y_axis.maximum: -1.0" render(data, configuration)
                end

                nested_test("!xs") do
                    data.points_xs[1] = 0
                    @test_throws "log of non-positive data.points_xs[1]: 0.0" render(data, configuration)
                end

                nested_test("!ys") do
                    data.points_ys[1] = -0.2
                    configuration.y_axis.log_regularization = 0
                    @test_throws "log of non-positive data.points_ys[1]: -0.2" render(data, configuration)
                end
            end

            nested_test("()") do
                test_html(data, configuration, "points.log.html")
                return nothing
            end

            nested_test("diagonal") do
                nested_test("invalid") do
                    nested_test("!line_offset") do
                        configuration.x_axis.log_regularization = 0
                        configuration.y_axis.log_regularization = 0
                        configuration.diagonal_bands.low.offset = -1
                        @test_throws "log of non-positive configuration.diagonal_bands.low.offset: -1" render(
                            data,
                            configuration,
                        )
                    end

                    nested_test("!log") do
                        configuration.y_axis.log_regularization = nothing
                        configuration.diagonal_bands.middle.offset = 1
                        @test_throws "configuration.diagonal_bands specified for a combination of linear and log scale axes" render(
                            data,
                            configuration,
                        )
                        return nothing
                    end
                end

                nested_test("()") do
                    configuration.x_axis.log_regularization = 0
                    configuration.y_axis.log_regularization = 0

                    configuration.diagonal_bands.low.offset = 0.5
                    configuration.diagonal_bands.middle.offset = 1
                    configuration.diagonal_bands.high.offset = 2

                    test_html(data, configuration, "points.log.diagonal.html")
                    return nothing
                end

                nested_test("low_fills") do
                    configuration.diagonal_bands.low.is_filled = true
                    configuration.diagonal_bands.middle.is_filled = true
                    configuration.diagonal_bands.high.is_filled = true

                    configuration.diagonal_bands.low.width = nothing
                    configuration.diagonal_bands.middle.width = nothing
                    configuration.diagonal_bands.high.width = nothing

                    configuration.diagonal_bands.low.color = "#0000ff"
                    configuration.diagonal_bands.middle.color = "#00ff00"
                    configuration.diagonal_bands.high.color = "#ff0000"

                    configuration.diagonal_bands.low.offset = 0.25
                    configuration.diagonal_bands.high.offset = 0.75

                    test_html(data, configuration, "points.log.diagonal.low_fills.html")
                    return nothing
                end

                nested_test("high_fills") do
                    configuration.diagonal_bands.low.is_filled = true
                    configuration.diagonal_bands.middle.is_filled = true
                    configuration.diagonal_bands.high.is_filled = true

                    configuration.diagonal_bands.low.width = nothing
                    configuration.diagonal_bands.middle.width = nothing
                    configuration.diagonal_bands.high.width = nothing

                    configuration.diagonal_bands.low.color = "#0000ff"
                    configuration.diagonal_bands.middle.color = "#00ff00"
                    configuration.diagonal_bands.high.color = "#ff0000"

                    configuration.diagonal_bands.low.offset = 1.25
                    configuration.diagonal_bands.high.offset = 1.75

                    test_html(data, configuration, "points.log.diagonal.high_fills.html")
                    return nothing
                end

                nested_test("middle_fills") do
                    configuration.diagonal_bands.low.is_filled = true
                    configuration.diagonal_bands.middle.is_filled = true
                    configuration.diagonal_bands.high.is_filled = true

                    configuration.diagonal_bands.low.offset = 0.75
                    configuration.diagonal_bands.high.offset = 1.25

                    test_html(data, configuration, "points.log.diagonal.middle_fills.html")
                    return nothing
                end
            end
        end

        nested_test("color") do
            configuration.points.color = "red"

            nested_test("()") do
                test_html(data, configuration, "points.color.html")
                return nothing
            end

            nested_test("!color") do
                configuration.points.color = "oobleck"
                @test_throws "invalid configuration.points.color: oobleck" render(data, configuration)
                return nothing
            end
        end

        nested_test("colors") do
            data.points_colors = ["red", "green", "blue"]

            nested_test("()") do
                test_html(data, configuration, "points.colors.html")
                return nothing
            end

            nested_test("!valid") do
                data.points_colors[2] = "oobleck"
                @test_throws "invalid data.points_colors[2]: oobleck" render(data, configuration)
            end

            nested_test("!legend") do
                configuration.points.show_color_scale = true
                @test_throws "explicit data.points_colors specified for configuration.points.show_color_scale" render(
                    data,
                    configuration,
                )
            end
        end

        nested_test("categorical") do
            data.points_colors = ["Foo", "Bar", "Baz"]
            configuration.points.color_palette = [("Foo", "red"), ("Bar", "green"), ("Baz", "blue"), ("Vaz", "magenta")]

            nested_test("()") do
                test_html(data, configuration, "points.categorical.html")
                return nothing
            end

            nested_test("!color") do
                configuration.points.color_palette[2] = ("Bar", "oobleck")
                @test_throws "invalid configuration.points.color_palette[2] color: oobleck" render(data, configuration)
            end

            nested_test("!reversed") do
                configuration.points.reverse_color_scale = true
                @test_throws "reversed categorical configuration.points.color_palette" render(data, configuration)
            end

            nested_test("legend") do
                configuration.points.show_color_scale = true
                test_legend(data, configuration, "points.categorical") do
                    data.points_colors_title = "Points"
                    return nothing
                end
                return nothing
            end
        end

        nested_test("continuous") do
            data.points_colors = [0.0, 1.0, 2.0]

            nested_test("linear") do
                nested_test("()") do
                    test_html(data, configuration, "points.continuous.html")
                    return nothing
                end

                nested_test("invalid") do
                    nested_test("!colorscale") do
                        configuration.points.color_palette = Vector{Tuple{Real, String}}()
                        @test_throws "empty configuration.points.color_palette" render(data, configuration)
                        return nothing
                    end

                    nested_test("~colorscale") do
                        configuration.points.color_palette = [(-1.0, "blue"), (-1.0, "red")]
                        @test_throws "single configuration.points.color_palette value: -1.0" render(data, configuration)
                        return nothing
                    end

                    nested_test("!range") do
                        configuration.points.color_scale.minimum = 1.5
                        configuration.points.color_scale.maximum = 0.5
                        @test_throws dedent("""
                            configuration.points.color_scale.maximum: 0.5
                            is not larger than configuration.points.color_scale.minimum: 1.5
                        """) render(data, configuration)
                        return nothing
                    end
                end

                nested_test("range") do
                    configuration.points.color_scale.minimum = 0.5
                    configuration.points.color_scale.maximum = 1.5
                    configuration.points.show_color_scale = true
                    test_html(data, configuration, "points.continuous.range.html")
                    return nothing
                end

                nested_test("viridis") do
                    configuration.points.color_palette = "Viridis"
                    test_html(data, configuration, "points.continuous.viridis.html")
                    return nothing
                end

                nested_test("reversed") do
                    configuration.points.reverse_color_scale = true
                    test_html(data, configuration, "points.continuous.reversed.html")
                    return nothing
                end

                nested_test("legend") do
                    configuration.points.show_color_scale = true
                    test_legend(data, configuration, "points.continuous") do
                        data.points_colors_title = "Points"
                        return nothing
                    end
                    return nothing
                end

                nested_test("gradient") do
                    configuration.points.color_palette = [(-1.0, "blue"), (3.0, "red")]

                    nested_test("()") do
                        test_html(data, configuration, "points.continuous.gradient.html")
                        return nothing
                    end

                    nested_test("reversed") do
                        configuration.points.reverse_color_scale = true
                        test_html(data, configuration, "points.continuous.gradient.reversed.html")
                        return nothing
                    end

                    nested_test("legend") do
                        configuration.points.show_color_scale = true
                        test_legend(data, configuration, "points.gradient") do
                            data.points_colors_title = "Points"
                            return nothing
                        end
                        return nothing
                    end
                end
            end

            nested_test("log") do
                data.points_colors = [0.0, 5.0, 10.0]
                configuration.points.color_scale.log_regularization = 1.0

                nested_test("invalid") do
                    nested_test("!log_color_scale_regularization") do
                        configuration.points.color_scale.log_regularization = -1.0
                        @test_throws "negative configuration.points.color_scale.log_regularization: -1.0" render(
                            data,
                            configuration,
                        )
                    end

                    nested_test("!cmin") do
                        configuration.points.color_palette = [(-1.0, "blue"), (1.0, "red")]
                        @test_throws "log of non-positive configuration.points.color_palette[1]: 0.0" render(
                            data,
                            configuration,
                        )
                    end

                    nested_test("!colors") do
                        data.points_colors[1] = -2.0
                        @test_throws "log of non-positive data.points_colors[1]: -1.0" render(data, configuration)
                    end

                    nested_test("!minimum") do
                        configuration.points.color_scale.minimum = -1.5
                        @test_throws "log of non-positive configuration.points.color_scale.minimum: -0.5" render(
                            data,
                            configuration,
                        )
                        return nothing
                    end

                    nested_test("!minimum") do
                        configuration.points.color_scale.maximum = -1.5
                        @test_throws "log of non-positive configuration.points.color_scale.maximum: -0.5" render(
                            data,
                            configuration,
                        )
                        return nothing
                    end
                end

                nested_test("()") do
                    test_html(data, configuration, "points.log.continuous.html")
                    return nothing
                end

                nested_test("viridis") do
                    configuration.points.color_palette = "Viridis"
                    test_html(data, configuration, "points.log.continuous.viridis.html")
                    return nothing
                end

                nested_test("!reversed") do
                    configuration.points.reverse_color_scale = true
                    @test_throws "reversed log configuration.points.color_scale" render(data, configuration)
                end

                nested_test("legend") do
                    configuration.points.show_color_scale = true

                    nested_test("small") do
                        test_legend(data, configuration, "points.log.continuous.small") do
                            data.points_colors_title = "Points"
                            return nothing
                        end
                        return nothing
                    end

                    nested_test("large") do
                        data.points_colors .*= 10
                        data.points_colors[1] += 6
                        test_legend(data, configuration, "points.log.continuous.large") do
                            data.points_colors_title = "Points"
                            return nothing
                        end
                        return nothing
                    end

                    nested_test("huge") do
                        data.points_colors .*= 100
                        test_legend(data, configuration, "points.log.continuous.huge") do
                            data.points_colors_title = "Points"
                            return nothing
                        end
                        return nothing
                    end
                end

                nested_test("gradient") do
                    configuration.points.color_palette = [(0.0, "blue"), (10.0, "red")]

                    nested_test("()") do
                        test_html(data, configuration, "points.log.continuous.gradient.html")
                        return nothing
                    end

                    nested_test("reversed") do
                        configuration.points.reverse_color_scale = true
                        test_html(data, configuration, "points.log.continuous.gradient.reversed.html")
                        return nothing
                    end

                    nested_test("legend") do
                        configuration.points.show_color_scale = true
                        test_legend(data, configuration, "points.log.gradient") do
                            data.points_colors_title = "Points"
                            return nothing
                        end
                        return nothing
                    end
                end
            end
        end

        nested_test("size") do
            configuration.points.size = 10
            test_html(data, configuration, "points.size.html")
            return nothing
        end

        nested_test("sizes") do
            data.points_sizes = [10.0, 25.0, 100.0]

            nested_test("()") do
                test_html(data, configuration, "points.sizes.html")
                return nothing
            end

            nested_test("!range") do
                configuration.points.size_range.smallest = 10.0
                configuration.points.size_range.largest = 2.0
                @test_throws dedent("""
                    configuration.points.size_range.largest: 2.0
                    is not larger than configuration.points.size_range.smallest: 10.0
                """) render(data, configuration)
            end

            nested_test("linear") do
                configuration.points.size_range.smallest = 2.0
                configuration.points.size_range.largest = 10.0
                test_html(data, configuration, "points.sizes.linear.html")
                return nothing
            end

            nested_test("log") do
                configuration.points.size_scale.log_regularization = 0
                test_html(data, configuration, "points.sizes.log.html")
                return nothing
            end
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
            data.points_hovers = ["<b>Foo</b><br>Low", "<b>Bar</b><br>Middle", "<b>Baz</b><br>High"]
            test_html(data, configuration, "points.hovers.html")
            return nothing
        end

        nested_test("border") do
            configuration.points.size = 6
            configuration.points.color = "black"

            nested_test("sizes") do
                data.borders_sizes = [10.0, 25.0, 100.0]

                nested_test("()") do
                    test_html(data, configuration, "points.border.sizes.html")
                    return nothing
                end

                nested_test("linear") do
                    configuration.borders.size_range.smallest = 2.0
                    configuration.borders.size_range.largest = 10.0
                    test_html(data, configuration, "points.border.sizes.linear.html")
                    return nothing
                end

                nested_test("log") do
                    configuration.borders.size_scale.log_regularization = 0
                    test_html(data, configuration, "points.border.sizes.log.html")
                    return nothing
                end

                nested_test("color") do
                    configuration.borders.color = "red"
                    test_html(data, configuration, "points.border.sizes.color.html")
                    return nothing
                end

                nested_test("!legend") do
                    configuration.borders.show_color_scale = true
                    @test_throws "no data.borders_colors specified for configuration.borders.show_color_scale" render(
                        data,
                        configuration,
                    )
                end
            end

            nested_test("colors") do
                data.borders_colors = ["red", "green", "blue"]

                nested_test("()") do
                    test_html(data, configuration, "points.border.colors.html")
                    return nothing
                end

                nested_test("size") do
                    configuration.borders.size = 6
                    test_html(data, configuration, "points.border.colors.size.html")
                    return nothing
                end

                nested_test("!legend") do
                    configuration.borders.show_color_scale = true
                    @test_throws "explicit data.borders_colors specified for configuration.borders.show_color_scale" render(
                        data,
                        configuration,
                    )
                end
            end

            nested_test("continuous") do
                data.borders_colors = [0.0, 1.0, 2.0]

                nested_test("()") do
                    test_html(data, configuration, "points.border.continuous.html")
                    return nothing
                end

                nested_test("size") do
                    configuration.borders.size = 6
                    test_html(data, configuration, "points.border.continuous.size.html")
                    return nothing
                end

                nested_test("legend") do
                    configuration.borders.show_color_scale = true

                    test_legend(data, configuration, "points.border.continuous") do
                        data.borders_colors_title = "Borders"
                        return nothing
                    end

                    nested_test("legend") do
                        data.points_colors = [20.0, 10.0, 0.0]
                        configuration.points.color_palette = "Viridis"
                        configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(data, configuration, "points.border.continuous.legend") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            data.borders_colors_title = "Borders"
                            test_legend(data, configuration, "points.border.continuous.legend.title") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end
                    end

                    nested_test("legend1") do
                        data.points_colors = ["Foo", "Bar", "Baz"]
                        configuration.points.color_palette = [("Foo", "red"), ("Bar", "green"), ("Baz", "blue")]
                        configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(data, configuration, "points.border.continuous.legend1") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            data.borders_colors_title = "Borders"
                            test_legend(data, configuration, "points.border.continuous.legend1.title") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end
                    end
                end
            end

            nested_test("categorical") do
                data.borders_colors = ["Foo", "Bar", "Baz"]
                configuration.borders.color_palette =
                    [("Foo", "red"), ("Bar", "green"), ("Baz", "blue"), ("Vaz", "magenta")]

                nested_test("()") do
                    test_html(data, configuration, "points.border.categorical.html")
                    return nothing
                end

                nested_test("legend") do
                    configuration.borders.show_color_scale = true

                    nested_test("()") do
                        test_legend(data, configuration, "points.border.categorical.colors") do
                            data.borders_colors_title = "Borders"
                            return nothing
                        end
                    end

                    nested_test("legend") do
                        data.points_colors = ["X", "Y", "Z"]
                        configuration.points.color_palette = [("X", "cyan"), ("Y", "magenta"), ("Z", "yellow")]
                        configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(data, configuration, "points.border.categorical.legend") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            data.borders_colors_title = "Borders"
                            test_legend(data, configuration, "points.border.categorical.legend.title") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end
                    end

                    nested_test("legend1") do
                        data.points_colors = [20.0, 10.0, 0.0]
                        configuration.points.color_palette = "Viridis"
                        configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(data, configuration, "points.border.categorical.legend1") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            data.borders_colors_title = "Borders"
                            test_legend(data, configuration, "points.border.categorical.legend1.title") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end
                    end
                end
            end
        end

        nested_test("edges") do
            data.edges_points = [(1, 2), (1, 3)]

            nested_test("()") do
                test_html(data, configuration, "points.edges.html")
                return nothing
            end

            nested_test("invalid") do
                nested_test("!from") do
                    data.edges_points[1] = (-1, 2)
                    @test_throws "data.edges_points[1] from invalid point: -1" render(data, configuration)
                end

                nested_test("!to") do
                    data.edges_points[1] = (1, 4)
                    @test_throws "data.edges_points[1] to invalid point: 4" render(data, configuration)
                end

                nested_test("self!") do
                    data.edges_points[1] = (1, 1)
                    @test_throws "data.edges_points[1] from point to itself: 1" render(data, configuration)
                end
            end

            nested_test("size") do
                configuration.edges.size = 8
                test_html(data, configuration, "points.edges.size.html")
                return nothing
            end

            nested_test("sizes") do
                data.edges_sizes = [6, 10]
                test_html(data, configuration, "points.edges.sizes.html")
                return nothing
            end

            nested_test("color") do
                configuration.edges.color = "magenta"
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

    nested_test("grid") do
        configuration = GridGraphConfiguration()
        data = GridGraphData(; points_colors = [1.0 2.0 3.0; 4.0 5.0 6.0])

        nested_test("()") do
            test_html(data, configuration, "grid.html")
            return nothing
        end

        nested_test("invalid") do
            nested_test("!sizes!colors") do
                data.points_colors = nothing
                @test_throws "neither data.points_colors nor data.points_sizes specified for grid" render(
                    data,
                    configuration,
                )
            end
        end

        nested_test("legend") do
            configuration.points.show_color_scale = true
            test_legend(data, configuration, "grid") do
                data.points_colors_title = "Grid"
                return nor
            end
        end

        nested_test("colors") do
            data.points_colors = ["red" "green" "blue"; "blue" "green" "red"]
            return test_html(data, configuration, "grid.colors.html")
        end

        nested_test("categorical") do
            data.points_colors = ["A" "B" "C"; "C" "B" "A"]
            configuration.points.color_palette = [("A", "red"), ("B", "green"), ("C", "blue")]

            nested_test("!scale") do
                return test_html(data, configuration, "grid.categorical.html")
            end

            nested_test("legend") do
                configuration.points.show_color_scale = true
                test_legend(data, configuration, "grid.categorical") do
                    data.points_colors_title = "Grid"
                    return nothing
                end
            end
        end

        nested_test("sizes") do
            data.points_sizes = (data.points_colors .- 1) .* 10

            nested_test("!sizes") do
                data.points_sizes = transpose(data.points_sizes)
                @test_throws dedent("""
                    the data.points_colors size: (2, 3)
                    is different from the data.points_sizes size: (3, 2)
                """) render(data, configuration)
            end

            nested_test("~sizes") do
                data.points_sizes[1, 2] = -1.5
                @test_throws "negative data.points_sizes[1,2]: -1.5" render(data, configuration)
            end

            nested_test("!colors") do
                data.points_colors = nothing
                return test_html(data, configuration, "grid.sizes.!colors.html")
            end

            nested_test("color") do
                data.points_colors = nothing
                configuration.points.color = "red"
                return test_html(data, configuration, "grid.sizes.color.html")
            end

            nested_test("()") do
                test_html(data, configuration, "grid.sizes.html")
                return nothing
            end

            nested_test("linear") do
                configuration.points.size_range.smallest = 2.0
                configuration.points.size_range.largest = 10.0
                test_html(data, configuration, "grid.sizes.linear.html")
                return nothing
            end

            nested_test("log") do
                configuration.points.size_scale.log_regularization = 1
                test_html(data, configuration, "grid.sizes.log.html")
                return nothing
            end
        end

        nested_test("!grid") do
            configuration.graph.show_grid = false
            test_html(data, configuration, "grid.!grid.html")
            return nothing
        end

        nested_test("titles") do
            data.x_axis_title = "X"
            data.y_axis_title = "Y"
            data.graph_title = "Graph"
            data.rows_names = ["A", "B"]
            data.columns_names = ["C", "D", "E"]
            test_html(data, configuration, "grid.titles.html")
            return nothing
        end

        nested_test("hovers") do
            data.points_hovers = ["A" "B" "C"; "D" "E" "F"]
            test_html(data, configuration, "grid.hovers.html")
            return nothing
        end

        nested_test("!hovers") do
            data.points_hovers = transpose(["A" "B" "C"; "D" "E" "F"])
            @test_throws dedent("""
                the data.points_hovers size: (3, 2)
                is different from the data.points_colors and/or data.points_sizes size: (2, 3)
            """) render(data, configuration)
        end

        nested_test("border") do
            data.borders_sizes = (data.points_colors .- 1) .* 10

            nested_test("!sizes") do
                data.borders_sizes = transpose(data.borders_sizes)
                @test_throws dedent("""
                    the data.borders_sizes size: (3, 2)
                    is different from the data.points_colors and/or data.points_sizes size: (2, 3)
                """) render(data, configuration)
            end

            nested_test("~sizes") do
                data.borders_sizes[1, 2] = -1.5
                @test_throws "negative data.borders_sizes[1,2]: -1.5" render(data, configuration)
            end

            nested_test("sizes") do
                nested_test("()") do
                    test_html(data, configuration, "grid.border.sizes.html")
                    return nothing
                end

                nested_test("linear") do
                    configuration.borders.size_range.smallest = 2.0
                    configuration.borders.size_range.largest = 10.0
                    test_html(data, configuration, "grid.border.sizes.linear.html")
                    return nothing
                end

                nested_test("log") do
                    configuration.borders.size_scale.log_regularization = 1
                    test_html(data, configuration, "grid.border.sizes.log.html")
                    return nothing
                end

                nested_test("color") do
                    configuration.borders.color = "black"
                    test_html(data, configuration, "grid.border.color.html")
                    return nothing
                end
            end

            nested_test("!colors") do
                data.borders_colors = ["red" "green" "blue"; "red" "green" "blue"]
                data.borders_colors = transpose(data.borders_colors)
                @test_throws dedent("""
                    the data.borders_colors size: (3, 2)
                    is different from the data.points_colors and/or data.points_sizes size: (2, 3)
                """) render(data, configuration)
            end

            nested_test("colors") do
                data.borders_sizes = nothing
                data.borders_colors = ["red" "green" "blue"; "red" "green" "blue"]

                nested_test("()") do
                    return test_html(data, configuration, "grid.border.colors.html")
                end

                nested_test("!scale") do
                    configuration.borders.show_color_scale = true
                    @test_throws "explicit data.borders_colors specified for configuration.borders.show_color_scale" render(
                        data,
                        configuration,
                    )
                end
            end

            nested_test("categorical") do
                data.borders_colors = ["A" "B" "C"; "C" "B" "A"]
                configuration.borders.color_palette = [("A", "red"), ("B", "green"), ("C", "blue")]

                nested_test("()") do
                    return test_html(data, configuration, "grid.border.categorical.html")
                end

                nested_test("legend") do
                    configuration.borders.show_color_scale = true

                    nested_test("()") do
                        test_legend(data, configuration, "grid.border.categorical") do
                            data.borders_colors_title = "Grid"
                            return nothing
                        end
                    end

                    nested_test("legend") do
                        data.points_colors = ["X" "Y" "Z"; "Z" "Y" "X"]
                        configuration.points.color_palette = [("X", "cyan"), ("Y", "magenta"), ("Z", "yellow")]
                        configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(data, configuration, "grid.border.categorical.legend") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            data.borders_colors_title = "Borders"
                            test_legend(data, configuration, "grid.border.categorical.legend.title") do
                                data.points_colors_title = "Grid"
                                return nothing
                            end
                        end
                    end

                    nested_test("legend1") do
                        data.points_colors = [1.0 2.0 3.0; 4.0 5.0 6.0]
                        configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(data, configuration, "grid.border.categorical.legend1") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            data.borders_colors_title = "Borders"
                            test_legend(data, configuration, "grid.border.categorical.legend1.title") do
                                data.points_colors_title = "Grid"
                                return nothing
                            end
                        end
                    end
                end
            end

            nested_test("continuous") do
                data.borders_colors = 0 .- data.points_colors
                nested_test("()") do
                    return test_html(data, configuration, "grid.border.continuous.html")
                end

                nested_test("log") do
                    configuration.borders.color_scale.log_regularization = 0.0
                    @test_throws "log of non-positive data.borders_colors[2,3]: -6.0" render(data, configuration)
                end

                nested_test("legend") do
                    configuration.borders.show_color_scale = true

                    nested_test("()") do
                        test_legend(data, configuration, "grid.border.continuous") do
                            data.borders_colors_title = "Grid"
                            return nothing
                        end
                    end

                    nested_test("legend") do
                        configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(data, configuration, "grid.border.continuous.legend") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end
                        nested_test("title") do
                            data.borders_colors_title = "Borders"
                            test_legend(data, configuration, "grid.border.continuous.legend.title") do
                                data.points_colors_title = "Grid"
                                return nothing
                            end
                        end
                    end

                    nested_test("legend1") do
                        data.points_colors = ["A" "B" "C"; "C" "B" "A"]
                        configuration.points.color_palette = [("A", "red"), ("B", "green"), ("C", "blue")]
                        configuration.points.show_color_scale = true

                        nested_test("()") do
                            test_legend(data, configuration, "grid.border.continuous.legend1") do
                                data.points_colors_title = "Points"
                                return nothing
                            end
                        end

                        nested_test("title") do
                            data.borders_colors_title = "Borders"
                            test_legend(data, configuration, "grid.border.continuous.legend1.title") do
                                data.points_colors_title = "Grid"
                                return nothing
                            end
                        end
                    end
                end
            end
        end
    end
end
