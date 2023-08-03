using BoundaryValueDiffEq
using DiffEqBase, DiffEqDevTools, LinearAlgebra
using Test

# First order test
function func_1!(du, u, p, t)
    du[1] = u[2]
    du[2] = 0
end

# Not able to change the initial condition.
# Hard coded solution.
func_1 = ODEFunction(func_1!, analytic = (u0, p, t) -> [5 - t, -1])

function boundary!(residual, u, p, t)
    residual[1] = u[1][1] - 5
    residual[2] = u[end][1]
end

function boundary_two_point!(residual, u, p, t)
    ua = u[1]
    ub = u[end]
    residual[1] = ua[1] - 5
    residual[2] = ub[1]
end

# Second order linear test
function func_2!(du, u, p, t)
    du[1] = u[2]
    du[2] = -u[1]
end

# Not able to change the initial condition.
# Hard coded solution.
func_2 = ODEFunction(func_2!,
    analytic = (u0, p, t) -> [5 * (cos(t) - cot(5) * sin(t)),
        5 * (-cos(t) * cot(5) - sin(t))])
tspan = (0.0, 5.0)
u0 = [5.0, -3.5]
probArr = [
    BVProblem(func_1, boundary!, u0, tspan),
    BVProblem(func_2, boundary!, u0, tspan),
    TwoPointBVProblem(func_1, boundary_two_point!, u0, tspan),
    TwoPointBVProblem(func_2, boundary_two_point!, u0, tspan),
]

testTol = 0.2
affineTol = 1e-2
dts1 = 1 .// 2 .^ (3:-1:1)
dts2 = 1 .// 2 .^ (4:-1:3)
dts3 = 1 .// 2 .^ (9:-1:6)

println("Collocation method (GeneralMIRK)")
println("Affineness Test")
prob = probArr[1]

# GeneralMIRK3

@time sol = solve(prob, GeneralMIRK3(), dt = 0.2)
@test norm(diff(first.(sol.u)) .+ 0.2, Inf) + abs(sol[1][1] - 5) < affineTol

# GeneralMIRK4

@time sol = solve(prob, GeneralMIRK4(), dt = 0.2)
@test norm(diff(first.(sol.u)) .+ 0.2, Inf) + abs(sol[1][1] - 5) < affineTol

# GeneralMIRK5

@time sol = solve(prob, GeneralMIRK5(), dt = 0.2)
@test norm(diff(first.(sol.u)) .+ 0.2, Inf) + abs(sol[1][1] - 5) < affineTol

# GeneralMIRK6

@time sol = solve(prob, GeneralMIRK6(), dt = 0.2)
@test norm(diff(map(first, sol.u)) .+ 0.2, Inf) + abs(sol[1][1] - 5) < affineTol

println("Convergence Test on Linear")
prob = probArr[2]

# GeneralMIRK3

@time sim = test_convergence(dts2, prob, GeneralMIRK3(); abstol = 1e-3, reltol = 1e-3);
@test sim.𝒪est[:final]≈3 atol=testTol

# GeneralMIRK4

@time sim = test_convergence(dts1, prob, GeneralMIRK4(); abstol = 1e-4, reltol = 1e-4);
@test sim.𝒪est[:final]≈4 atol=testTol

# GeneralMIRK5

@time sim = test_convergence(dts2, prob, GeneralMIRK5(); abstol = 1e-4, reltol = 1e-4);
@test sim.𝒪est[:final]≈5 atol=0.3

# GeneralMIRK6

@time sim = test_convergence(dts3, prob, GeneralMIRK6(); abstol = 1e-4, reltol = 1e-4);
@test sim.𝒪est[:final]≈6 atol=testTol

println("Collocation method (MIRK)")
println("Affineness Test")
prob = probArr[3]

# MIRK3

@time sol = solve(prob, MIRK3(), dt = 0.2)
@test norm(diff(map(x -> x[1], sol.u)) .+ 0.2, Inf) .+ abs(sol[1][1] - 5) < affineTol

# MIRK4

@time sol = solve(prob, MIRK4(), dt = 0.2)
@test norm(diff(map(x -> x[1], sol.u)) .+ 0.2, Inf) .+ abs(sol[1][1] - 5) < affineTol

# MIRK5

@time sol = solve(prob, MIRK5(), dt = 0.2)
@test norm(diff(map(x -> x[1], sol.u)) .+ 0.2, Inf) .+ abs(sol[1][1] - 5) < affineTol

# MIRK6

@time sol = solve(prob, MIRK6(), dt = 0.2)
@test norm(diff(map(x -> x[1], sol.u)) .+ 0.2, Inf) .+ abs(sol[1][1] - 5) < affineTol

println("Convergence Test on Linear")
prob = probArr[4]

# MIRK3

@time sim = test_convergence(dts2, prob, MIRK3(); abstol = 1e-3, reltol = 1e-3);
@test sim.𝒪est[:final]≈3 atol=testTol

# MIRK4

@time sim = test_convergence(dts1, prob, MIRK4(); abstol = 1e-4, reltol = 1e-4);
@test sim.𝒪est[:final]≈4 atol=testTol

# MIRK5

@time sim = test_convergence(dts2, prob, MIRK5(); abstol = 1e-4, reltol = 1e-4);
@test sim.𝒪est[:final]≈5 atol=0.3

# MIRK6

@time sim = test_convergence(dts3, prob, MIRK6(); abstol = 1e-4, reltol = 1e-4);
@test sim.𝒪est[:final]≈6 atol=testTol

using StaticArrays
tspan = (0.0, pi / 2)
function simplependulum!(du, u, p, t)
    g = 9.81
    L = 1.0
    θ = u[1]
    dθ = u[2]
    du[1] = dθ
    du[2] = -(g / L) * sin(θ)
end

function bc1!(residual, u, p, t)
    residual[1] = u[end ÷ 2][1] + pi / 2 # the solution at the middle of the time span should be -pi/2
    residual[2] = u[end][1] - pi / 2 # the solution at the end of the time span should be pi/2
end

u0 = MVector{2}([pi / 2, pi / 2])
bvp1 = BVProblem(simplependulum!, bc1!, u0, tspan)
@test_nowarn solve(bvp1, GeneralMIRK3(), dt = 0.005)
@test_nowarn solve(bvp1, GeneralMIRK4(), dt = 0.05)
@test_nowarn solve(bvp1, GeneralMIRK5(), dt = 0.05)
@test_nowarn solve(bvp1, GeneralMIRK6(), dt = 0.05)
