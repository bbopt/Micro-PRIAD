
#=
This function calculates the number of hours not in service by categories for a given station and a given equipment name. It compares the unavailability intervals (ui) of all equipments with the given name and calculates the intersection of these intervals to find the intervals during which all equipments with the given name are not in service. Then it categorizes these intervals by their duration and counts the number of hours not in service for each category.
=#
function nhnisbcCalculatorLVL2(station::Station, name::String, ui, decal::Int64)
    C8 = 0.0
    C9 = 0.0
    uiToCompare = Vector{Vector{Interval}}()
    index = 0
    nbHoursInAYear = 365.25 * 24
    for e in station.Equipments
        index += 1
        if e.Name == name
            push!(uiToCompare, ui[decal + index])
        end
    end
    nexti = Interval[] # nexti := next interval
    if length(uiToCompare) == 1
        nexti = uiToCompare[1]
    elseif length(uiToCompare) != 0
        i = uiToCompare[1] # i := interval
        nbToCompare = length(uiToCompare)
        index = 2
        while (nbToCompare != 1)
            nexti = Interval[]
            oi = uiToCompare[index]
            for elem in i 
                for oelem in oi # o := other
                    if elem.lb <= oelem.lb && elem.ub >= oelem.ub
                        push!(nexti, Interval(oelem.lb, oelem.ub))
                    elseif oelem.lb <= elem.lb && oelem.ub >= elem.ub
                        push!(nexti, Interval(elem.lb, elem.ub))
                    elseif ((elem.ub - oelem.ub <= elem.ub - elem.lb) &&  (elem.ub - oelem.ub > 0))   
                        push!(nexti, Interval(elem.lb, oelem.ub))
                    elseif ((oelem.ub - elem.ub <= oelem.ub - oelem.lb) &&  (oelem.ub - elem.ub > 0))
                        push!(nexti, Interval(oelem.lb, elem.ub))
                    end
                end
            end
            index += 1
            nbToCompare -= 1
            i = nexti
        end
    end
    nbHoureNotInServiceByCategories::Vector{Float64} = [0.0 for i in 1:6]
    for elem in nexti 
        time = (elem.ub - elem.lb) * nbHoursInAYear
        if time > 16
            nbHoureNotInServiceByCategories[1] += time
        elseif time > 8
            nbHoureNotInServiceByCategories[2] += time
        elseif time > 4
            nbHoureNotInServiceByCategories[3] += time
        elseif time > 1
            nbHoureNotInServiceByCategories[4] += time
        elseif time > 0.5
            nbHoureNotInServiceByCategories[5] += time
        else
            nbHoureNotInServiceByCategories[6] += time
        end
    end
    return nbHoureNotInServiceByCategories
end

#=
This function calculates the number of hours not in service by categories for all equipments in all stations.
=#
function nhnisbcCalculator(stations::Vector{Station}, ui, nbStation)

    names = ["Transformateur élévateur de tension", "Isolateur haute tension",  "Câble haute tension", "Transformateur haute à moyenne tension", "Sectionneur haute tension", "Disjoncteur haute tesnsion", "Câble moyenne tension", "Isolateur moyenne tension", "Transformateur moyenne à basse tension", "Sectionneur moyenne tension", "Disjoncteur moyenne tension", "Câble basse tension"]

    nbHoureNotInServiceByCategories = Vector{Float64}()
    decal = 0
    for s in 1:nbStation
        nbHoureNotInServiceByCategories4eachStation = [0.0 for i in 1:6]
        for n in names
            nbHoureNotInServiceByCategories4eachStation += nhnisbcCalculatorLVL2(stations[s], n, ui, decal)
        end
        for i in 1:6
            push!(nbHoureNotInServiceByCategories, nbHoureNotInServiceByCategories4eachStation[i])
        end
        decal += length(stations[s].Equipments)
    end
    return nbHoureNotInServiceByCategories
end

#=
This function calculates the interpretation of the unavailability intervals (ui) calculating the number of hours not in service by categories for all ui in allui and then apply SubSampler if needed.
=#
function interpretationOfUi(stations::Vector{Station}, allui, nbStation, SubSampler::Function, AnyParamForSubSampler, timer, clk)
    hoursVec = Vector{Vector{Float64}}() # hoursVec := nbHoureNotInServiceByCategories
    for ui in allui
        nbHoureNotInServiceByCategories = nhnisbcCalculator(stations, ui, nbStation) 
        push!(hoursVec, nbHoureNotInServiceByCategories)
    end
    timer += time() - clk
    index = SubSampler(hoursVec, AnyParamForSubSampler)
    NEWnhnisbc = hoursVec[index]
    clk = time()
    return NEWnhnisbc
end

GC.gc()
