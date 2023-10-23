#This part of code is adopted from https://github.com/JuliaDiff/TaylorSeries.jl

# Control the display of the big 𝒪 notation
const bigOnotation = Bool[true]
const _show_default = [false]

"""
    displayBigO(d::Bool) --> nothing

Set/unset displaying of the big 𝒪 notation in  the output
of `Taylor1` and `TaylorN` polynomials. The initial value is
`true`.
"""
displayBigO(d::Bool) = (bigOnotation[end] = d; d)

"""
    use_Base_show(d::Bool) --> nothing

Use `Base.show_default` method (default `show` method
in Base), or a custom display. The initial value is
`false`, so customized display is used.
"""
use_show_default(d::Bool) = (_show_default[end] = d; d)

# Printing of TaylorSeries objects

# subscriptify is taken from the ValidatedNumerics.jl package, licensed under MIT "Expat".
# superscriptify is a small variation

const subscript_digits = [c for c in "₀₁₂₃₄₅₆₇₈₉"]
const superscript_digits = [c for c in "⁰¹²³⁴⁵⁶⁷⁸⁹"]

function subscriptify(n::Int)
    dig = reverse(digits(n))
    join([subscript_digits[i+1] for i in dig])
end

function superscriptify(n::Int)
    dig = reverse(digits(n))
    join([superscript_digits[i+1] for i in dig])
end


# #  Fallback
# function pretty_print(a::Taylor1)
#     # z = zero(a[0])
#     var = _params_Taylor1_.var_name
#     space = string(" ")
#     bigO = bigOnotation[end] ?
#         string("+ 𝒪(", var, superscriptify(a.order+1), ")") :
#         string("")
#     # iszero(a) && return string(space, z, space, bigO)
#     strout::String = space
#     ifirst = true
#     for i in eachindex(a)
#         monom::String = i==0 ? string("") : i==1 ? string(" ", var) :
#             string(" ", var, superscriptify(i))
#         @inbounds c = a[i]
#         # c == z && continue
#         cadena = numbr2str(c, ifirst)
#         strout = string(strout, cadena, monom, space)
#         ifirst = false
#     end
#     strout = strout * bigO
#     strout
# end

# function pretty_print(a::Taylor1{T}) where {T<:NumberNotSeries}
#     z = zero(a[0])
#     var = _params_Taylor1_.var_name
#     space = string(" ")
#     bigO = bigOnotation[end] ?
#         string("+ 𝒪(", var, superscriptify(a.order+1), ")") :
#         string("")
#     iszero(a) && return string(space, z, space, bigO)
#     strout::String = space
#     ifirst = true
#     for i in eachindex(a)
#         monom::String = i==0 ? string("") : i==1 ? string(" ", var) :
#             string(" ", var, superscriptify(i))
#         @inbounds c = a[i]
#         iszero(c) && continue
#         cadena = numbr2str(c, ifirst)
#         strout = string(strout, cadena, monom, space)
#         ifirst = false
#     end
#     strout = strout * bigO
#     strout
# end

# function pretty_print(a::Taylor1{T} where {T <: AbstractSeries{S}}) where {S<:Number}
#     z = zero(a[0])
#     var = _params_Taylor1_.var_name
#     space = string(" ")
#     bigO = bigOnotation[end] ?
#         string("+ 𝒪(", var, superscriptify(a.order+1), ")") :
#         string("")
#     iszero(a) && return string(space, z, space, bigO)
#     strout::String = space
#     ifirst = true
#     for i in eachindex(a)
#         monom::String = i==0 ? string("") : i==1 ? string(" ", var) :
#             string(" ", var, superscriptify(i))
#         @inbounds c = a[i]
#         iszero(c) && continue
#         cadena = numbr2str(c, ifirst)
#         ccad::String = i==0 ? cadena : ifirst ? string("(", cadena, ")") :
#             string(cadena[1:2], "(", cadena[3:end], ")")
#         strout = string(strout, ccad, monom, space)
#         ifirst = false
#     end
#     strout = strout * bigO
#     strout
# end

# function pretty_print(a::HomogeneousPolynomial{T}) where {T<:Number}
#     z = zero(a[1])
#     space = string(" ")
#     iszero(a) && return string(space, z)
#     strout::String = homogPol2str(a)
#     strout
# end

function pretty_print(a::TaylorSeries{T}) where {T}
    #z = zero(a[0])
    space = string("")
    bigO::String = bigOnotation[end] ?
                   string(" + 𝒪(‖x‖", superscriptify(_params_Taylor_.order + 1), ")") :
                   string("")
    # iszero(a) && return string(space, z, space, bigO)
    # strout::String = space
    # ifirst = true
    # for (i,coeff) in enumerate(a.coeffs)
    #     pol = a[ord]
    #     iszero(pol) && continue
    #     cadena::String = homogPol2str( pol )
    #     strsgn = (ifirst || ord == 0 || cadena[2] == '-') ?
    #         string("") : string(" +")
    #     strout = string( strout, strsgn, cadena)
    #     ifirst = false
    # end
    strout = homogPol2str(a)
    strout = strout * bigO
    strout
end

function homogPol2str(a::TaylorSeries{T}) where {T<:Number}
    numVars = get_numvars()
    #z = zero(a.coeffs[1])
    space = string(" ")
    strout::String = space
    ifirst = true
    for (order, coeff) in a.coeffs
        monom::String = string("")
        factor = 1
        for ivar = 1:numVars
            powivar = order[ivar]
            if powivar == 1
                monom = string(monom, name_taylorvar(ivar))
            elseif powivar > 1
                monom = string(monom, name_taylorvar(ivar), superscriptify(powivar))
                factor *= factorial(powivar)
            end
        end
        @inbounds c = coeff
        iszero(c) && continue
        #cadena = numbr2str(c / factor, ifirst)
        cadena = numbr2str(c, ifirst)
        strout = string(strout, cadena, monom, space)
        ifirst = false
    end
    return strout[1:prevind(strout, end)]
end

function homogPol2str(a::TaylorSeries{T}) where {T<:AbstractGraph}
    numVars = get_numvars()
    #z = zero(a.coeffs[1])
    space = string(" ")
    strout::String = space
    ifirst = true
    for (order, coeff) in a.coeffs
        monom::String = string("")
        factor = 1
        for ivar = 1:numVars
            powivar = order[ivar]
            if powivar == 1
                monom = string(monom, name_taylorvar(ivar))
            elseif powivar > 1
                monom = string(monom, name_taylorvar(ivar), superscriptify(powivar))
                factor *= factorial(powivar)
            end
        end
        c = coeff
        if ifirst
            cadena = "g$(coeff.id)"
            ifirst = false
        else
            cadena = "+ g$(coeff.id)"
        end
        strout = string(strout, cadena, monom, space)
        ifirst = false
    end
    return strout[1:prevind(strout, end)]
end


function numbr2str(zz, ifirst::Bool=false)
    plusmin = ifelse(ifirst, string(""), string("+ "))
    return string(plusmin, zz)
end

function numbr2str(zz::T, ifirst::Bool=false) where
{T<:Union{AbstractFloat,Integer,Rational}}
    iszero(zz) && return string(zz)
    plusmin = ifelse(zz < zero(T), string("- "),
        ifelse(ifirst, string(""), string("+ ")))
    return string(plusmin, abs(zz))
end

function numbr2str(zz::Complex, ifirst::Bool=false)
    zT = zero(zz.re)
    iszero(zz) && return string(zT)
    zre, zim = reim(zz)
    if zre > zT
        if ifirst
            cadena = string("( ", zz, " )")
        else
            cadena = string("+ ( ", zz, " )")
        end
    elseif zre < zT
        cadena = string("- ( ", -zz, " )")
    elseif zre == zT
        if zim > zT
            if ifirst
                cadena = string("( ", zz, " )")
            else
                cadena = string("+ ( ", zz, " )")
            end
        elseif zim < zT
            cadena = string("- ( ", -zz, " )")
        else
            if ifirst
                cadena = string("( ", zz, " )")
            else
                cadena = string("+ ( ", zz, " )")
            end
        end
    else
        if ifirst
            cadena = string("( ", zz, " )")
        else
            cadena = string("+ ( ", zz, " )")
        end
    end
    return cadena
end

name_taylorvar(i::Int) = string(" ", get_variable_names()[i])

# # summary
# summary(a::Taylor1{T}) where {T<:Number} =
#     string(a.order, "-order ", typeof(a), ":")

# function summary(a::Union{HomogeneousPolynomial{T}, TaylorN{T}}) where {T<:Number}
#     string(a.order, "-order ", typeof(a), " in ", get_numvars(), " variables:")
# end

# show
function Base.show(io::IO, a::TaylorSeries)
    # if _show_default[end]
    #     return Base.show_default(IOContext(io, :compact => false), a)
    # else
    #    
    # end
    return print(io, pretty_print(a))
end