function construct_device!(ps_m::CanonicalModel,
                           device::Type{L},
                           device_formulation::Type{D},
                           system_formulation::Type{S},
                           sys::PSY.System,
                           time_range::UnitRange{Int64};
                           kwargs...) where {L <: PSY.ElectricLoad,
                                             D <: PSI.AbstractControllablePowerLoadForm,
                                             S <: PM.AbstractPowerFormulation}

    parameters = get(kwargs, :parameters, true)

    fixed_resources = [fs for fs in sys.loads if isa(fs,PSY.PowerLoad)]

    controllable_resources = [fs for fs in sys.loads if !isa(fs,PSY.PowerLoad)]

        if !isempty(controllable_resources)

            #Variables
            activepower_variables(ps_m, controllable_resources, time_range);

            reactivepower_variables(ps_m, controllable_resources, time_range);

            #Constraints
            activepower_constraints(ps_m, controllable_resources, device_formulation, system_formulation, time_range, parameters)

            reactivepower_constraints(ps_m, controllable_resources, device_formulation, system_formulation, time_range)

            #Cost Function
            cost_function(ps_m, controllable_resources, device_formulation, system_formulation)

        else
            @warn("The Data Doesn't Contain Controllable Loads, Consider Changing the Device Formulation to StaticPowerLoad")

        end

        #add to expression

        if !isempty(fixed_resources)
            nodal_expression(ps_m, fixed_resources, system_formulation, time_range, parameters)
        end

        return

end

function construct_device!(ps_m::CanonicalModel,
                           device::Type{L},
                           device_formulation::Type{D},
                           system_formulation::Type{S},
                           sys::PSY.System,
                           time_range::UnitRange{Int64};
                           kwargs...) where {L <: PSY.ElectricLoad,
                                             D <: PSI.AbstractControllablePowerLoadForm,
                                             S <: PM.AbstractActivePowerFormulation}

    parameters = get(kwargs, :parameters, true)

    fixed_resources = [fs for fs in sys.loads if isa(fs,PSY.PowerLoad)]

    controllable_resources = [fs for fs in sys.loads if !isa(fs,PSY.PowerLoad)]

    if !isempty(controllable_resources)

        #Variables
        activepower_variables(ps_m, controllable_resources, time_range);

        #Constraints
        activepower_constraints(ps_m, controllable_resources, device_formulation, system_formulation, time_range, parameters)

        #Cost Function
        cost_function(ps_m, controllable_resources, device_formulation, system_formulation)

    else
        @warn("The Data Doesn't Contain Controllable Loads, Consider Changing the Device Formulation to StaticPowerLoad")
    end

    #add to expression

    if !isempty(fixed_resources)
        nodal_expression(ps_m, fixed_resources, system_formulation, time_range, parameters)
    end

    return

end

function construct_device!(ps_m::CanonicalModel,
                           device::Type{L},
                           device_formulation::Type{PSI.StaticPowerLoad},
                           system_formulation::Type{S},
                           sys::PSY.System,
                           time_range::UnitRange{Int64};
                           kwargs...) where {L <: PSY.ElectricLoad,
                                             S <: PM.AbstractPowerFormulation}

    parameters = get(kwargs, :parameters, true)

    nodal_expression(ps_m, sys.loads, system_formulation, time_range, parameters)

    return

end