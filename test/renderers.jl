ID_REGEX = r"""id="([^"]*)"""

function normalize_svg(svg::AbstractString)::AbstractString
    seen = Dict{AbstractString, Int}()
    for id in eachmatch(ID_REGEX, svg)
        index = get(seen, id.captures[1], nothing)
        if index === nothing
            index = length(seen) + 1
            seen[id.captures[1]] = index
        end
    end
    replacements = sort([id => "id-$(index)" for (id, index) in seen]; by = (pair) -> length(pair.first), rev = true)
    svg = replace(svg, " style=\"\"" => "", ">" => ">\n", replacements...)
    return svg
end

struct ResultFile
    path::AbstractString
    content::AbstractString
end

function Base.show(io::IO, result_file::ResultFile)::Nothing
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

        nested_test("!shape") do
            configuration = DistributionGraphConfiguration(;
                graph = graph_configuration,
                shape = DistributionShapeConfiguration(; show_box = false),
            )
            @test_throws "must specify at least one of: shape.show_box, shape.show_violin, shape.show_curve" render(
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
            configuration.values_axis.minimum = 1
            configuration.values_axis.maximum = 0
            @test_throws dedent("""
                values axis maximum: 0
                is not larger than minimum: 1
            """) render(data, configuration)
        end

        nested_test("curve&violin") do
            configuration = DistributionGraphConfiguration(;
                graph = graph_configuration,
                shape = DistributionShapeConfiguration(; show_curve = true, show_violin = true),
            )
            @test_throws "can't specify both of: shape.show_violin, shape.show_curve" render(data, configuration)
        end

        nested_test("!values") do
            data = DistributionGraphData(; values = Float32[])
            @test_throws "empty values vector" render(data)
        end

        nested_test("box") do
            data.title = "trace"
            configuration = DistributionGraphConfiguration(;
                graph = graph_configuration,
                values_axis = AxisConfiguration(; title = "box"),
            )

            nested_test("size") do
                configuration.graph.title = "size"
                configuration.graph.height = 96 * 2
                configuration.graph.width = 96 * 2
                render(data, configuration)
                return test_svg("distribution.box.size.svg")
            end

            nested_test("()") do
                render(data, configuration)
                return test_svg("distribution.box.svg")
            end

            nested_test("horizontal") do
                configuration.graph.title = "horizontal"
                configuration.orientation = HorizontalValues
                render(data, configuration)
                return test_svg("distribution.box.horizontal.svg")
            end

            nested_test("outliers") do
                configuration.graph.title = "outliers"
                configuration.shape.show_outliers = true
                render(data, configuration)
                return test_svg("distribution.box.outliers.svg")
            end

            nested_test("color") do
                configuration.graph.title = "color"
                configuration.color = "red"
                render(data, configuration)
                return test_svg("distribution.box.color.svg")
            end
        end

        nested_test("violin") do
            configuration = DistributionGraphConfiguration(;
                graph = graph_configuration,
                shape = DistributionShapeConfiguration(; show_box = false, show_violin = true),
                values_axis = AxisConfiguration(; title = "violin"),
            )

            nested_test("()") do
                render(data, configuration)
                return test_svg("distribution.violin.svg")
            end

            nested_test("horizontal") do
                configuration.graph.title = "horizontal"
                configuration.orientation = HorizontalValues
                render(data, configuration)
                return test_svg("distribution.violin.horizontal.svg")
            end

            nested_test("outliers") do
                configuration.graph.title = "outliers"
                configuration.shape.show_outliers = true
                render(data, configuration)
                return test_svg("distribution.violin.outliers.svg")
            end

            nested_test("color") do
                configuration.graph.title = "color"
                configuration.color = "red"
                render(data, configuration)
                return test_svg("distribution.violin.color.svg")
            end

            nested_test("box") do
                configuration.graph.title = "box"
                configuration.shape.show_box = true
                render(data, configuration)
                return test_svg("distribution.violin.box.svg")
            end
        end

        nested_test("curve") do
            configuration = DistributionGraphConfiguration(;
                graph = graph_configuration,
                shape = DistributionShapeConfiguration(; show_box = false, show_curve = true),
                values_axis = AxisConfiguration(; title = "curve"),
            )

            nested_test("()") do
                render(data, configuration)
                return test_svg("distribution.curve.svg")
            end

            nested_test("horizontal") do
                configuration.graph.title = "horizontal"
                configuration.orientation = HorizontalValues
                render(data, configuration)
                return test_svg("distribution.curve.horizontal.svg")
            end

            nested_test("outliers") do
                configuration.graph.title = "outliers"
                configuration.shape.show_outliers = true
                render(data, configuration)
                return test_svg("distribution.curve.outliers.svg")
            end

            nested_test("color") do
                configuration.graph.title = "color"
                configuration.color = "red"
                render(data, configuration)
                return test_svg("distribution.curve.color.svg")
            end

            nested_test("box") do
                configuration.graph.title = "box"
                configuration.shape.show_box = true
                render(data, configuration)
                return test_svg("distribution.curve.box.svg")
            end
        end
    end
end
