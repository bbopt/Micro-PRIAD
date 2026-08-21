function basicSubSampler(nhnisbc, str)
    return 1:length(nhnisbc)
end

#=
Pour les test unitaire
=#
function TEST_SubSampler(nhnisbc, str)
    newIndex = []
    i = 0
    for elem in nhnisbc
        i += 1
        if mod(i,2) == 0
            push!(newIndex, i)
        end
    end
    return newIndex
end