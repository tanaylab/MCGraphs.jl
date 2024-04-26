ID_REGEX = r"""id="([^"]*)"""

function normalize_svg_ids(svg::AbstractString)::AbstractString
    seen = Dict{AbstractString, Int}()
    for id in eachmatch(ID_REGEX, svg)
        index = get(seen, id.captures[1], nothing)
        if index === nothing
            index = length(seen) + 1
            seen[id.captures[1]] = index
        end
    end
    replacements = sort([id => "id-$(index)" for (id, index) in seen]; by = (pair) -> length(pair.first), rev = true)
    svg = replace(svg, ">" => ">\n", replacements...)
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
    actual_path = "actual/" * path
    actual_svg = open(actual_path, "r") do file
        return read(file, String)
    end
    actual_svg = normalize_svg_ids(actual_svg)
    open(actual_path, "w") do file
        return write(file, actual_svg)
    end
    actual_result = ResultFile(actual_path, actual_svg)

    expected_path = "expected/" * path
    expected_svg = open(expected_path, "r") do file
        return read(file, String)
    end
    expected_result = ResultFile(expected_path, expected_svg)

    @test expected_result == actual_result
    return nothing
end

mkpath("actual")

nested_test("renderers") do
    nested_test("distribution") do
        data = DistributionGraphData(; values = [1.0, 1.0, 2.0, 3.0, 3.0])

        nested_test("!shape") do
            configuration = DistributionGraphConfiguration(; output = "actual/distribution.box.svg", curve = false)
            @test_throws "must specify at least one of: curve, violin, box, points" render(data, configuration)
        end

        nested_test("curve&violin") do
            configuration = DistributionGraphConfiguration(; output = "actual/distribution.box.svg", violin = true)
            @test_throws "can't specify both of: curve, violin" render(data, configuration)
        end

        nested_test("!values") do
            data = DistributionGraphData(; values = Float32[])
            @test_throws "empty values vector" render(data)
        end

        nested_test("!colors") do
            data.colors = ["red", "green"]
            @test_throws dedent("""
                length of colors: 2
                is different from length of values: 5
            """) render(data)
        end

        nested_test("box") do
            configuration =
                DistributionGraphConfiguration(; output = "actual/distribution.box.svg", curve = false, box = true)
            render(data, configuration)
            return test_svg("distribution.box.svg")
        end
    end
end
