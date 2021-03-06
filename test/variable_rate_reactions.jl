using DiffEqBiological, DiffEqJump, DiffEqBase, OrdinaryDiffEq, StochasticDiffEq
using Base.Test

r1 = VariableRateReaction(1e-4,(1,2),((1,-1),(2,1)))
r2 = VariableRateReaction(0.01,[2],[(2,-1),(3,1)])

prob = DiscreteProblem([999.0,3.0,0],(0.0,250.0))
jump_prob = GillespieProblem(prob,Direct(),r1,r2)

jump_prob = JumpProblem(prob,Direct(),build_jumps_from_reaction(r1),build_jumps_from_reaction(r2))


println("Solve the Gillespie Problem")
srand(110)
sol = solve(jump_prob,Tsit5())
#using Plots; plotly(); plot(sol)
@time sol = solve(jump_prob,Tsit5())
@test 700 <= sol[end][3] <= 850

#=
# Takes Too Long For Travis
nums = Int[]
@time for i in 1:100
  jump_prob = GillespieProblem(prob,Direct(),r1,r2)
  sol = solve(jump_prob,Tsit5())
  push!(nums,sol[end][3])
end
@test mean(nums) - 740 < 20
=#

f = function (du,u,p,t)
  du[4] = u[2]*u[3]/100000 - u[1]*u[2]/100000
end

prob = ODEProblem(f,[999.0,3.0,0.0,100.0],(0.0,250.0))
jump_prob = GillespieProblem(prob,Direct(),r1,r2)

srand(230)
println("Add ODE to Gillespie Problem")
sol = solve(jump_prob,Tsit5())
@test 650 <= sol[end][3] <= 900

r3 = VariableRateReaction(1e-2,[4],[(2,-1),(3,1)])
prob = ODEProblem(f,[999.0,3.0,0.0,1.0],(0.0,250.0))
jump_prob = GillespieProblem(prob,Direct(),r1,r2,r3)
sol = solve(jump_prob,Tsit5())

g = function (du,u,p,t)
  du[4] = 0.05u[4]
end

srand(331)
println("Turn Gillespie Problem into SDE")
prob = SDEProblem(f,g,[999.0,3.0,0.0,1.0],(0.0,250.0))
jump_prob = GillespieProblem(prob,Direct(),r1,r2,r3)
sol = solve(jump_prob,SRIW1())
@test 650 <= sol[end][3] <= 1500

println("Now mix constant rate reactions")
r1 = Reaction(1e-4,(1,2),((1,-1),(2,1)))
r2 = Reaction(0.01,[2],[(2,-1),(3,1)])
jump_prob = GillespieProblem(prob,Direct(),r1,r2,r3)
integrator = init(jump_prob,SRIW1())
solve!(integrator)
@test 650 <= sol[end][3] <= 1500
