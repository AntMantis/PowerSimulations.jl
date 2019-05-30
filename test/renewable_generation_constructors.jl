@testset "Renewable data misspecification" begin
    # See https://discourse.julialang.org/t/how-to-use-test-warn/15557/5 about testing for warning throwing
    warn_message = "The data doesn't devices of type RenewableDispatch, consider changing the device models"
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableFullDispatch)
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps,)
    @test_logs (:warn, warn_message) construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5, time_steps, Dates.Minute(5); parameters = true);
    ps_model = PSI._canonical_model_init(buses14, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    @test_logs (:warn, warn_message) construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys14, time_steps, Dates.Minute(5); parameters = true);
end

@testset "Renewable DCPLossLess FullDispatch" begin
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableFullDispatch)
    #5 Bus testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5));
    @test JuMP.num_variables(ps_model.JuMPmodel) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
    # No Parameters Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps; parameters = false)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5); parameters = false);
    @test !(:params in keys(ps_model.JuMPmodel.ext))
    @test JuMP.num_variables(ps_model.JuMPmodel) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
    # No Forecast Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5); forecast = false);
    @test JuMP.num_variables(ps_model.JuMPmodel) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
    # No Forecast - No Parameters Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps; parameters = false)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5); parameters = false, forecast = false);
    @test !(:params in keys(ps_model.JuMPmodel.ext))
    @test JuMP.num_variables(ps_model.JuMPmodel) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
end

@testset "Renewable ACPPower Full Dispatch (Broken, Missing data)" begin
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    #construct_device!(ps_model, PSY.RenewableDispatch, PSI.RenewableFullDispatch, PM.StandardACPForm, c_sys5_re, time_steps, Dates.Minute(5));
end

@testset "Renewable DCPLossLess ConstantPowerFactor" begin
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableConstantPowerFactor)
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5));
    @test JuMP.num_variables(ps_model.JuMPmodel) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
    # No Parameters Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps; parameters = false)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5); parameters = false);
    @test !(:params in keys(ps_model.JuMPmodel.ext))
    @test JuMP.num_variables(ps_model.JuMPmodel) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
    # No Forecast Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5); forecast = false);
    @test JuMP.num_variables(ps_model.JuMPmodel) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
    # No Forecast - No Parameters Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps; parameters = false)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5); parameters = false, forecast = false);
    @test !(:params in keys(ps_model.JuMPmodel.ext))
    @test JuMP.num_variables(ps_model.JuMPmodel) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
end

@testset "Renewable ACP ConstantPowerFactor" begin
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableConstantPowerFactor)
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    construct_device!(ps_model, model, PM.StandardACPForm, c_sys5_re, time_steps, Dates.Minute(5));
    @test JuMP.num_variables(ps_model.JuMPmodel) == 144
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 72
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
    # No Parameters Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps; parameters = false)
    construct_device!(ps_model, model, PM.StandardACPForm, c_sys5_re, time_steps, Dates.Minute(5); parameters = false);
    @test !(:params in keys(ps_model.JuMPmodel.ext))
    @test JuMP.num_variables(ps_model.JuMPmodel) == 144
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 72
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
    # No Forecast Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    construct_device!(ps_model, model, PM.StandardACPForm, c_sys5_re, time_steps, Dates.Minute(5); forecast = false);
    @test JuMP.num_variables(ps_model.JuMPmodel) == 144
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 72
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
    # No Forecast - No Parameters Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps; parameters = false)
    construct_device!(ps_model, model, PM.StandardACPForm, c_sys5_re, time_steps, Dates.Minute(5); parameters = false, forecast = false);
    @test !(:params in keys(ps_model.JuMPmodel.ext))
    @test JuMP.num_variables(ps_model.JuMPmodel) == 144
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.Interval{Float64}) == 72
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 72
    JuMP.@objective(ps_model.JuMPmodel, Min, ps_model.cost_function)
    @test JuMP.objective_function_type(ps_model.JuMPmodel) == JuMP.GenericAffExpr{Float64,VariableRef}
end

@testset "Renewable DCPLossLess FixedOutput" begin
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableFixed)
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5));
    @test JuMP.num_variables(ps_model.JuMPmodel) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    # No Parameters Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps; parameters = false)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5); parameters = false);
    @test !(:params in keys(ps_model.JuMPmodel.ext))
    @test JuMP.num_variables(ps_model.JuMPmodel) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    # No Forecast Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5); forecast = false);
    @test JuMP.num_variables(ps_model.JuMPmodel) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    # No Forecast - No Parameters Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps; parameters = false)
    construct_device!(ps_model, model, PM.DCPlosslessForm, c_sys5_re, time_steps, Dates.Minute(5); parameters = false, forecast = false);
    @test !(:params in keys(ps_model.JuMPmodel.ext))
    @test JuMP.num_variables(ps_model.JuMPmodel) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
end

@testset "Renewable ACP FixedOutput" begin
    model = DeviceModel(PSY.RenewableDispatch, PSI.RenewableFixed)
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    construct_device!(ps_model, model, PM.StandardACPForm, c_sys5_re, time_steps, Dates.Minute(5));
    @test JuMP.num_variables(ps_model.JuMPmodel) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    # No Parameters Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps; parameters = false)
    construct_device!(ps_model, model, PM.StandardACPForm, c_sys5_re, time_steps, Dates.Minute(5); parameters = false);
    @test !(:params in keys(ps_model.JuMPmodel.ext))
    @test JuMP.num_variables(ps_model.JuMPmodel) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    # No Forecast Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps)
    construct_device!(ps_model, model, PM.StandardACPForm, c_sys5_re, time_steps, Dates.Minute(5); forecast = false);
    @test JuMP.num_variables(ps_model.JuMPmodel) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
    # No Forecast - No Parameters Testing
    ps_model = PSI._canonical_model_init(buses5, 100.0, nothing, PM.AbstractPowerFormulation, time_steps; parameters = false)
    construct_device!(ps_model, model, PM.StandardACPForm, c_sys5_re, time_steps, Dates.Minute(5); parameters = false, forecast = false);
    @test !(:params in keys(ps_model.JuMPmodel.ext))
    @test JuMP.num_variables(ps_model.JuMPmodel) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.LessThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.GreaterThan{Float64}) == 0
    @test JuMP.num_constraints(ps_model.JuMPmodel,JuMP.GenericAffExpr{Float64,VariableRef},MOI.EqualTo{Float64}) == 0
end