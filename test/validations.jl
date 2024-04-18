struct DefaultValidation <: ObjectWithValidation end

struct SpecializedValidation <: ObjectWithValidation
    low::Int
    high::Int
end

function MCGraphs.Validations.validate_object(specialized_validation::SpecializedValidation)::Maybe{AbstractString}
    if specialized_validation.high <= specialized_validation.low
        return "high: $(specialized_validation.high)\n" * "is not higher than low: $(specialized_validation.low)"
    else
        return nothing
    end
end

function test_valid(object_with_validation::ObjectWithValidation)::Nothing
    @test validate_object(object_with_validation) === nothing
    return assert_valid_object(object_with_validation)
end

function test_invalid(object_with_validation::ObjectWithValidation, message::AbstractString)::Nothing
    @test validate_object(object_with_validation) == dedent(message)
    @test_throws "AssertionError: $(rstrip(message, '\n'))" assert_valid_object(object_with_validation)
    return nothing
end

nested_test("validations") do
    nested_test("default") do
        test_valid(DefaultValidation())
        return nothing
    end

    nested_test("specialized") do
        nested_test("valid") do
            test_valid(SpecializedValidation(0, 1))
            return nothing
        end

        nested_test("invalid") do
            test_invalid(
                SpecializedValidation(1, 0),
                """
                high: 0
                is not higher than low: 1
                """,
            )
            return nothing
        end
    end
end
