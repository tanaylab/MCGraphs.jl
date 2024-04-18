"""
Validate user input.

Rendering graphs requires two objects: data and configuration. Both objects need to be internally consistent. This is
especially relevant for the graph configuration. When creating UI for filling in these objects, we can in general easily
validate each field on its own (e.g., ensure that a "color" field contains a valid color name). To ensure the overall
object is consistent, we provide overall-type-specific validation functions that can be invoked by the UI to inform the
user if the combination of (individually valid) field values is not valid for some reason.
"""
module Validations

export assert_valid_object
export validate_object
export ObjectWithValidation

using Daf.GenericTypes

"""
A common type for objects that support validation, that is, that one can invoke [`validate_object`](@ref) on.
"""
abstract type ObjectWithValidation end

"""
    validate_object(object::ObjectWithValidation)::Maybe{AbstractString}

Validate all field values of an object are compatible with each other, assuming each one is valid on its own. Returns
`nothing` for a valid object and an error message if something is wrong. By default, this returns `nothing`.

This can be used by GUI widgets to validate the object as a whole (as opposed to validating each field based on its
type).
"""
function validate_object(object::ObjectWithValidation)::Maybe{AbstractString}  # NOLINT
    return nothing
end

"""
    assert_valid_object(object_with_validation::ObjectWithValidation)::Maybe{AbstractString}

This will `@assert` that the `object_with_validation` is valid (that is, [`validate_object`](@ref) will return `nothing`
for it). This is used in the back-end (graph rendering) code. It is recommended that the front-end (UI) code will invoke
[`validate_object`](@ref) and ensure the user fixes problems before invoking the back-end code.
"""
function assert_valid_object(object_with_validation::ObjectWithValidation)::Nothing
    message = validate_object(object_with_validation)
    @assert message === nothing message
end

end
