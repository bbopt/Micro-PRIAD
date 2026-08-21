include("Struct.jl")
include("Param.jl")
include("ElectricitySimulator.jl")
include("RiskModule.jl")

using Random

#=
The "minMaintenancesPeriodicity" function take an equipment "equip" as input and return the most frequent maintenance for this equipment and return the periodicity of that maintenance "min"
=#
function minMaintenancesPeriodicity(equip::Equipment)
    min::Float64 = Inf64
    for m in equip.Maintenances
        if m.Periodicity < min
            min =  m.Periodicity
        end
    end
    return min
end

#=
The "relativMaintenancePeriodicity" function take as input an equipment "equip" and return the relativ periodicity of the other maintance if there is one
=#
function relativMaintenancePeriodicity(equip::Equipment)
    minPeriodicity = minMaintenancesPeriodicity(equip)

    for m in equip.Maintenances
        relativVal = m.Periodicity/minPeriodicity
        if (relativVal - 1) >= 0.001
            return Int.(round(relativVal, digits = 1))
        end
    end
    return 1
end


#=
The "logNormalGenerator" function take an esperance as input and return a log normal random variable with that esperance and a variance of 0.25
=#
function logNormalGenerator(esperance)
    variance = 0.25
    sigma = sqrt(log(variance/esperance^2 + 1))
    mu = log(esperance) - sigma^2 / 2
    U1 = rand()
    U2 = rand()
    Z0 = sqrt(-2 * log(U1)) * cos(2 * pi * U2)
    LN = exp(mu + sigma * Z0)
    return LN
end

#=
The "requiredTime4EachMaintenance" function take an equipment as input and return a vector of the time required for the maintenaces linked to this equipment
=#
function requiredTime4EachMaintenance(equip::Equipment)
    nbMaintenances = length(equip.Maintenances) # prend la valeur 1 ou 2 
    if nbMaintenances == 1
        return [logNormalGenerator(equip.Maintenances[1].RequiredTime)]
    else
        return [logNormalGenerator(equip.Maintenances[2].RequiredTime), logNormalGenerator(equip.Maintenances[1].RequiredTime)]
    end   
end

#=
The "GetFailureRequiredTime" function take a failure as input and an PG number and return the number of houres required for the maintenence linked to this failure
=#
function GetFailureRequiredTime(failure::Failure, PG)
    splitName = split(failure.Name)
    index = parse(Int,String(splitName[1]))
    requiredTimeToRepairFailures = FailuresParam(PG)
    return logNormalGenerator(requiredTimeToRepairFailures[index])
end

#=
The "realUnavailabilityVector" function takes the intervals of unavailability cause by planned maintenance ("uifm") and intervals of unavailability cause by failures maintenance ("uiff") 
    and return a vector of the interval where the equipment is unavailable considering the failure's maintences and the planned maintenaces
=#
function realUnavailabilityVector(uifm, uiff)
    ui = [[] for i in 1:length(uifm)]
    bidon = Interval(0, 0)
    for e in 1:length(uifm)
        ui[e] = vcat(uifm[e], uiff[e])
        for i in 1:length(uifm[e])
            for k in 1:length(uiff[e])
                if uiff[e][k].lb <= uifm[e][i].lb && uiff[e][k].ub >= uifm[e][i].ub
                    ui[e][i] = bidon
                elseif uifm[e][i].lb <= uiff[e][k].lb && uifm[e][i].ub >= uiff[e][k].ub
                    ui[e][k + length(uifm[e])] = bidon
                elseif ((uifm[e][i].ub - uiff[e][k].ub) <= (uifm[e][i].ub - uifm[e][i].lb)) && ((uifm[e][i].ub - uiff[e][k].ub) >= 0)
                    ui[e][i] = bidon
                elseif ((uiff[e][k].ub - uifm[e][i].ub) <= (uiff[e][k].ub - uiff[e][k].lb)) && ((uiff[e][k].ub - uifm[e][i].ub) >= 0)
                    ui[e][k + length(uifm[e])] = bidon
                end
            end
        end
        nbDelete = 0
        for index in findall(x -> x == bidon, ui[e])
            deleteat!(ui[e], index - nbDelete)
            nbDelete += 1
        end
        sort!(ui[e])
    end
    return ui
end

#=
The "intermidiateReturn" function takes the FFC (flag, function, constraint) object, the divider that corespond to how many MC trials have been done and the timer value and return the formated output for the MicroPRIAD function 
=#
function intermidiateReturn(FFCT, divider1, divider2, timer) # divider2 and FFCT[14] are redondant
    FFCTformated = Vector{Float64}(undef, 14)
    FFCTformated = deepcopy(FFCT)
    FFCTformated[2] = FFCTformated[2]/divider2
    FFCTformated[8] = FFCTformated[8]/divider1 - 500
    FFCTformated[9] = FFCTformated[9]/divider1 - 500
    FFCTformated[10] = FFCTformated[10]/divider2 - 500
    FFCTformated[11] = FFCTformated[11]/divider2
    FFCTformated[11] -= 500
    FFCTformated[12] = timer
    return FFCTformated
end

#=
The "splitUnavailSimulator" function is the function that run the MC trials, the inputs are:
    @Param nbEval: represent the number of MC trials, 
    @Param nbEquipments: is the total number of equipment,
    @Param nbStation: is the total number of station,
    @Param stations: is the vector of stations that reprensent the eletrical network,
    @Param FFC: is the (flag, function, constraint) object,
    @Param ϕ: is the fidelity level after the "nbEval" MC trials,
    @Param costDivider1: is the number of MC trials done before the "nbEval" MC trials,
    @Param costDivider2: is the number of MC trials done on the second stage of the blackbox before the "nbEval" MC trials,
    @Param Interrupter: is a function that can be anything, the user can chose what it does, but it decides wether you continue or not this iteration the BB at this point,
    @Param timer: represent he time used for running the simulation since the beggening of the iteration,
    @Param clk: is the result of time() function at the last call of Interrupter,
    @Param C1_2_3_4_6_7_8_9multiplier: is a multiplier that control the constraint for the different input length,
    @Param PG: represent the power grid instance number,
    @Param nbVec: is the result of the function nbParam.
    @Param availInterrupter: is a boolean that indicate if you want to have intermediate return
    @param single_MC_info_return: indicate to the program if and where to print information about every Monte Carlo trials
    @Return FFCT: (flag, function, constraint, timer) object after the MC trials if it was not interupted befor calculating the cost and the constraints linked to the cost.    
=#
function splitUnavailSimulator(nbEval::Int64, nbEquipments::Int64, nbStation::Int64, stations, FFC::Vector{Float64}, ϕ::Float64, costDivider1::Int64, costDivider2, Interrupter::Function, timer, clk, C1_2_3_4_6_7_8_9multiplier::Float64, PG::Union{Int64, Char, String}, nbVec, availInterrupter::Bool, N::Int64, AnyParamForInterrupter, single_MC_info_return::Function, AnyParamForSingle_MC_Info_ReturnFunction, SubSampler::Function, AnyParamForSubSampler)
    ϕBefore = round((ϕ - nbEval/N), sigdigits = 4)
    nbHoursInAYear = 365.25 * 24
    allui = []
    totMaintenanceTime = 0.0
    totFailure = 0
    employeeSalary = 40
    nbEmployeeNeeded = 3 + 4    # the 3 represent the actual number of employee needed and the 4 represent the other expense (cost as much as two employee salary)
    costByFailure = 50000 

    single_MC_info::Vector{Float64} = [0.0, 0.0, 0.0, 0.0, 0.0] # [f C6 C7 C8 C9] <==> S MC I

    if (nbEval == 0)
        return vcat(FFC, timer, clk, costDivider2)
    end

    for eval in 1:nbEval
        unavailIntervalsForMaintenances = [[] for i in 1:nbEquipments]
        unavailIntervalsForFailures = [[] for i in 1:nbEquipments]
        e = 0
        for s in 1:nbStation
            for equip in stations[s].Equipments
                e += 1
                minTime = minMaintenancesPeriodicity(equip) # retourne la périodicité de la maintenance la plus fréquente pour cet équipement
                relativPeriodicity = relativMaintenancePeriodicity(equip::Equipment)
                whenCombinedMaintenaces = rand(1:(relativPeriodicity)) # check if we start with a full maintenace or by a maintenace only on theft
                requiredTime = requiredTime4EachMaintenance(equip)
                first = rand() * minTime
                if whenCombinedMaintenaces != 1
                    I = Interval(first, first + requiredTime[1]/nbHoursInAYear)
                    push!(unavailIntervalsForMaintenances[e], I)
                    whenCombinedMaintenaces -= 1
                    totMaintenanceTime += requiredTime[1]
                else
                    I = Interval(first, first + sum(requiredTime)/nbHoursInAYear)
                    push!(unavailIntervalsForMaintenances[e], I)
                    whenCombinedMaintenaces = relativPeriodicity
                    totMaintenanceTime += sum(requiredTime)
                end
                nbRemaningMaintenancesIn40Years = floor(Int, (40 - first)/minTime)
                for i in 1:nbRemaningMaintenancesIn40Years
                    requiredTime = requiredTime4EachMaintenance(equip)
                    first += minTime
                    if whenCombinedMaintenaces != 1
                        I = Interval(first, first + requiredTime[1]/nbHoursInAYear)
                        push!(unavailIntervalsForMaintenances[e], I)
                        whenCombinedMaintenaces -= 1
                        totMaintenanceTime += requiredTime[1]
                    else
                        I = Interval(first, first + sum(requiredTime)/nbHoursInAYear)
                        push!(unavailIntervalsForMaintenances[e], I)
                        whenCombinedMaintenaces = relativPeriodicity
                        totMaintenanceTime += sum(requiredTime)
                    end
                end 
            end
        end
        e = 0
        for s in 1:nbStation
            for equip in stations[s].Equipments
                e += 1 
                for y in 1:40
                    for f in equip.Failure
                        if rand() <= f.DegradationProbability
                            first = y + rand()
                            frt = GetFailureRequiredTime(f, PG)
                            ###### C7 #######
                            C7 = frt/nbEquipments * 12.6 * C1_2_3_4_6_7_8_9multiplier^0.121
                            single_MC_info[3] += C7 # S MC I
                            FFC[9] += C7
                            #################
                            I = Interval(first, first + frt/nbHoursInAYear)
                            push!(unavailIntervalsForFailures[e], I)
                            totFailure += 1
                        end
                    end
                end
            end
        end
        ui = realUnavailabilityVector(unavailIntervalsForMaintenances, unavailIntervalsForFailures)
        push!(allui, ui)
    end
    ######## C6 ########
    C6 = 0.0
    for ui in allui
        for i in ui
            for elem in i
                C6 += (elem.ub - elem.lb)
            end
        end
    end
    FFC[8] += nbHoursInAYear * C6/nbEquipments * 6.2 * C1_2_3_4_6_7_8_9multiplier^0.138
    single_MC_info[2] = nbHoursInAYear * C6/nbEquipments * 6.2 * C1_2_3_4_6_7_8_9multiplier^0.138   # S MC I
    ####################

    ########## conditional intermediate return ############
    if availInterrupter == true
        FFCcopied = deepcopy(FFC)
        if FFCcopied[2] == 0.0
            FFCcopied[2] = Inf
            FFCcopied[10:11] = [Inf, Inf]
        else
            FFCcopied[2] = FFCcopied[2]/costDivider2
        end
        FFCcopied[8] = FFCcopied[8]/(ϕ * N) - 500
        FFCcopied[9] = FFCcopied[9]/(ϕ * N) - 500
        FFCcopied[10] = FFCcopied[10]/costDivider2 - 500
        FFCcopied[11] = FFCcopied[11]/costDivider2
        FFCcopied[11] -= 500

        timer += time() - clk
        ϕVec = [ϕBefore, ϕ, ϕ, ϕ, ϕ, ϕ, ϕ, ϕ, ϕBefore, ϕBefore]
        if Interrupter(ϕVec, FFCcopied[2:11], AnyParamForInterrupter) == false
            FFCT = Vector{Float64}(undef, 14)
            FFCT[1:11] = FFCcopied
            FFCT[12] = timer 
            FFCT[13] = Inf64
            FFCT[14] = costDivider2
            return FFCT
        end
        clk = time()
    end
    ############################################

    maintenanceCost = totMaintenanceTime * employeeSalary * nbEmployeeNeeded
    failureCost = totFailure * costByFailure


    #######################################################################################################
    hoursVec = interpretationOfUi(stations, allui, nbStation, SubSampler, AnyParamForSubSampler, timer, clk) # le SubSampler ce cache ici
    
    costDivider2 += length(hoursVec)

    FFC[2] += maintenanceCost + failureCost 
    single_MC_info[1] += maintenanceCost + failureCost                                   # S MC I

    for a in hoursVec
        single_MC_info[1] = 0.0
        single_MC_info[4] = 0.0
        single_MC_info[5] = 0.0
        for s in 1:nbStation
            CCC = riskModule(stations[s], a[(s-1)*6+1:(s-1)*6+6], nbVec)
            FFC[2]  += CCC[1]
            FFC[10] += CCC[2] * C1_2_3_4_6_7_8_9multiplier^0.689
            FFC[11] += CCC[3] * C1_2_3_4_6_7_8_9multiplier^0.858

            single_MC_info[1] += CCC[1]                                                      # S MC I
            single_MC_info[4] += CCC[2] * C1_2_3_4_6_7_8_9multiplier^0.689                   # S MC I
            single_MC_info[5] += CCC[3] * C1_2_3_4_6_7_8_9multiplier^0.858                   # S MC I
        end
        timer += time() - clk
        single_MC_info_return(single_MC_info, AnyParamForSingle_MC_Info_ReturnFunction)      # S MC I
        clk = time()
    end
    #######################################################################################################

    FFCT = Vector{Float64}(undef, 14)
    FFCT[1:11] = FFC
    FFCT[12] = timer 
    FFCT[13] = clk
    FFCT[14] = costDivider2
    return FFCT
end

#=
The "UnavailSimulator" function is the function that call the splitUnavailSimulator function, controls the number of MC trials for each call of that function so it gets to fidelity asked,
    it calls that function by block of 1000 MC trials to comunicate with Interrupter at different moment of the iteration, all the argument are the same as those descibed in the description of 
    the splitUnavailSimulator function.
This function is the one that return the value of FFCT to the Main function MicroPRIAD
=#
function UnavailSimulator(FFC::Vector{Float64}, stations::Vector{Station}, ϕ::Float64, x::Union{Vector{Float64}, Vector{Int64}}, seedMC::Int64, Interrupter::Function, timer, clk, C1_2_3_4_6_7_8_9multiplier::Float64, PG::Union{Int64, Char, String}, nbVec, s::Int64, availInterrupter::Bool, N::Int64, AnyParamForInterrupter, single_MC_info_return::Function, AnyParamForSingle_MC_Info_ReturnFunction, SubSampler::Function, AnyParamForSubSampler, first_s_to_one::Bool)  
    nbEquipments = nbVec[18]
    if x[1] == Inf64
        nbStation = sum(nbVec[8:10])
    else
        nbStation = sum(nbVec[5:10])
    end

    Random.seed!(seedMC)
    
    nbEval = ceil(Int, N * ϕ)

    nbReturn = floor(Int, nbEval/s)

    FFCT = Vector{Float64}(undef, 14)

    FFC[2] = 0.0
    FFC[8:11] = [0.0, 0.0, 0.0, 0.0]
    if first_s_to_one
        FFCT = splitUnavailSimulator(1, nbEquipments, nbStation, stations, FFC, 1/N, 1, 0, Interrupter, timer, clk, C1_2_3_4_6_7_8_9multiplier, PG, nbVec, availInterrupter, N, AnyParamForInterrupter, single_MC_info_return, AnyParamForSingle_MC_Info_ReturnFunction, SubSampler, AnyParamForSubSampler)
        if FFCT[13] == Inf64
            return vcat(FFCT[1:12], 1, 1/N)
        end
        ########## intermediate return ############ 
        timer += time() - clk
        modFFCT = intermidiateReturn(FFCT, 1, FFCT[14], timer)
        ϕVec = [1/N for i in 1:10]
        if Interrupter(ϕVec, modFFCT[2:11], AnyParamForInterrupter) == false
            return vcat(modFFCT[1:12], 1, 1/N)
        end
        clk = time()
    end
    ############################################
    if nbReturn != 0
        for r in 1:nbReturn
            if r == 1

                FFCT = splitUnavailSimulator((s - first_s_to_one), nbEquipments, nbStation, stations, FFC, s/N, 1 * s, FFCT[14], Interrupter, timer, clk, C1_2_3_4_6_7_8_9multiplier, PG, nbVec, availInterrupter, N, AnyParamForInterrupter, single_MC_info_return, AnyParamForSingle_MC_Info_ReturnFunction, SubSampler, AnyParamForSubSampler)
                first_s_to_one = false
                if FFCT[13] == Inf64
                    return vcat(FFCT[1:12], s, s/N)
                end
            else
                FFCT = splitUnavailSimulator(s, nbEquipments, nbStation, stations, FFC, r * s/N, r * s, FFCT[14], Interrupter, timer, clk, C1_2_3_4_6_7_8_9multiplier, PG, nbVec, availInterrupter, N, AnyParamForInterrupter, single_MC_info_return, AnyParamForSingle_MC_Info_ReturnFunction, SubSampler, AnyParamForSubSampler)
                if FFCT[13] == Inf64
                    return vcat(FFCT[1:12], r * s, r * s/N)
                end
            end
            ######### intermediate return ############
            timer += time() - clk
            
            modFFCT = intermidiateReturn(FFCT, s * r, FFCT[14], timer)
            ϕVec = [r * s/N for i in 1:10]
            if Interrupter(ϕVec, modFFCT[2:11], AnyParamForInterrupter) == false
                return vcat(modFFCT[1:12], r * s, r * s/N)
            end
            clk = time()
            ############################################
        end
    end

    if (nbEval - s * nbReturn) != 0 && !(nbEval == 1 && first_s_to_one == true)
        if nbReturn == 0
            FFCT = splitUnavailSimulator((nbEval - s * nbReturn - first_s_to_one), nbEquipments, nbStation, stations, FFC, ϕ, s * nbReturn, FFCT[14], Interrupter, timer, clk, C1_2_3_4_6_7_8_9multiplier, PG, nbVec, availInterrupter, N, AnyParamForInterrupter, single_MC_info_return, AnyParamForSingle_MC_Info_ReturnFunction, SubSampler, AnyParamForSubSampler)    
        else
            FFCT = splitUnavailSimulator((nbEval - s * nbReturn), nbEquipments, nbStation, stations, FFC, ϕ, s * nbReturn, FFCT[14], Interrupter, timer, clk, C1_2_3_4_6_7_8_9multiplier, PG, nbVec, availInterrupter, N, AnyParamForInterrupter, single_MC_info_return, AnyParamForSingle_MC_Info_ReturnFunction, SubSampler, AnyParamForSubSampler)    
        end
        if FFCT[13] == Inf64
            return vcat(FFCT[1:12], nbEval, ϕ)
        end
        ######## intermediate return ############
        timer += time() - clk
        modFFCT = intermidiateReturn(FFCT, nbEval, FFCT[14], timer)
        ϕVec = [ϕ for i in 1:10]
        if Interrupter(ϕVec, modFFCT[2:11], AnyParamForInterrupter) ==  false 
            return vcat(modFFCT[1:12], nbEval, ϕ)
        end
        clk = time()
        ############################################
    end

    ############# return ################
    timer += time() - clk
    FFCT = intermidiateReturn(FFCT, nbEval, FFCT[14], timer)
    return vcat(FFCT[1:12], nbEval, ϕ)
    #####################################
end

GC.gc()
