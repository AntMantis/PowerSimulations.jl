function powerstoragevariables(m::JuMP.Model, devices_netinjection:: A, devices::Array{T,1}, time_periods::Int64) where {A <: PowerExpressionArray, T <: PowerSystems.Storage}

    on_set = [d.name for d in devices if d.available]
    t = 1:time_periods

    pstin = @variable(m, pstin[on_set,t])
    pstout = @variable(m, pstout[on_set,t])

    devices_netinjection = varnetinjectiterate!(devices_netinjection,  pstin, pstout, t, devices)

    return pstin, pstout, devices_netinjection
end

function energystoragevariables(m::JuMP.Model, devices::Array{T,1}, time_periods::Int64) where T <: PowerSystems.Storage

    on_set = [d.name for d in devices if d.available]
    t = 1:time_periods

    ebt = @variable(m, ebt[on_set,t] >= 0.0)

    return ebt
end

function powerconstraints(m::JuMP.Model, pstin::PowerVariable, pstout::PowerVariable, devices::Array{T,1}, time_periods::Int64) where T <: PowerSystems.Storage

    (length(pstin.indexsets[2]) != time_periods) ? error("Length of time dimension inconsistent"): true
    (length(pstout.indexsets[2]) != time_periods) ? error("Length of time dimension inconsistent"): true

    # TODO: @constraintref dissapears in JuMP 0.19. A new syntax goes here.
    # JuMP.JuMPArray(Array{ConstraintRef}(JuMP.size(x)), x.indexsets[1], x.indexsets[2])

    @constraintref pmax_in[1:length(pstin.indexsets[1]),1:length(pstin.indexsets[2])]
    @constraintref pmax_out[1:length(pstout.indexsets[1]),1:length(pstout.indexsets[2])]
    @constraintref pmin_in[1:length(pstin.indexsets[1]),1:length(pstin.indexsets[2])]
    @constraintref pmin_out[1:length(pstout.indexsets[1]),1:length(pstout.indexsets[2])]

    (pstin.indexsets[1] !== pstout.indexsets[1]) ? warn("Input/Output variables indexes are inconsistent"): true

    for t in pstin.indexsets[2], (ix, name) in enumerate(pstin.indexsets[1])
        if name == devices[ix].name
            pmin_in[ix, t] = @constraint(m, pstin[name, t] <= devices[ix].inputrealpowerlimits.min)
            pmin_out[ix, t] = @constraint(m, pstout[name, t] <= devices[ix].outputrealpowerlimits.min)
            pmax_in[ix, t] = @constraint(m, pstin[name, t] <= devices[ix].inputrealpowerlimits.max)
            pmax_out[ix, t] = @constraint(m, pstout[name, t] <= devices[ix].outputrealpowerlimits.max)
        else
            error("Bus name in Array and variable do not match")
        end
    end

    JuMP.registercon(m, :pmax_in, pmax_in)
    JuMP.registercon(m, pmax_out, pmax_out)
    JuMP.registercon(m, :pmin_in, pmin_in)
    JuMP.registercon(m, :pmin_out, pmin_out)

    return m
end

function energybookkeeping(m::JuMP.Model, pstin::PowerVariable, pstout::PowerVariable, ebt::PowerVariable, devices::Array{T,1}, time_periods::Int64; ini_cond = 0.0) where T <: PowerSystems.GenericBattery

    (length(pstin.indexsets[2]) != time_periods) ? error("Length of time dimension inconsistent in P_bt_in"): true
    (length(pstout.indexsets[2]) != time_periods) ? error("Length of time dimension inconsistent in P_bt_out"): true
    (length(ebt.indexsets[2]) != time_periods) ? error("Length of time dimension inconsistent in E_bt"): true

    @constraintref bookkeep_bt[1:length(ebt.indexsets[1]),1:length(ebt.indexsets[2])]

    (pstin.indexsets[1] !== pstout.indexsets[1]) ? warn("Input/Output Power variables indexes are inconsistent"): true
    (pstin.indexsets[1] !== ebt.indexsets[1]) ? warn("Input/Output and Battery Energy variables indexes are inconsistent"): true

    # TODO: Change loop order
    # TODO: Add Initial SOC for storage for sequential simulation
    for (ix,name) in enumerate(ebt.indexsets[1])
        if name == devices[ix].name
            t1 = pstin.indexsets[2][1]
            bookkeep_bt[ix,t1] = @constraint(m,ebt[name,t1] == devices[ix].energy -  pstout[name,t1]/devices[ix].efficiency.out + pstin[name,t1]*devices[ix].efficiency.in)
            for t in ebt.indexsets[2][2:end]
                bookkeep_bt[ix,t] = @constraint(m,ebt[name,t] == ebt[name,t-1] -  pstout[name,t]/devices[ix].efficiency.out + pstin[name,t]*devices[ix].efficiency.in)
            end
        else
            error("Bus name in Array and variable do not match")
        end
    end

    JuMP.registercon(m, :book_keep, bookkeep_bt)

    return m

end

function energyconstraints(m::JuMP.Model, ebt::PowerVariable, devices::Array{T,1}, time_periods::Int64) where T <: PowerSystems.GenericBattery

    (length(ebt.indexsets[2]) != time_periods) ? error("Length of time dimension inconsistent"): true
    @constraintref energylimit_bt[1:length(ebt.indexsets[1]),1:length(ebt.indexsets[2])]
    for t in ebt.indexsets[2], (ix,name) in enumerate(ebt.indexsets[1])
        if name == devices[ix].name
            energylimit_bt[ix,t] = @constraint(m,ebt[name,t] <= devices[ix].capacity.max)
        else
            error("Bus name in Array and variable do not match")
        end
    end

    JuMP.registercon(m, :energystoragelimit, energylimit_bt)

    return m
end