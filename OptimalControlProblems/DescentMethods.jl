## 
using Gridap
domain = (0,1,0,1)
# partition = (160, 160)
partition = (50, 50)
model = CartesianDiscreteModel(domain, partition) |> simplexify
writevtk(model, "mesh_nx$(partition[1])_ny$(partition[2])")


# %%
β = 1
f = 0
yΩ(x) = 10*x[1]*(1-x[1])*x[2]*(1-x[2]) # Target function
yd(x) = 0  # Dirichlet condition


## Define function spaces 
order = 1
reffe = ReferenceFE(lagrangian, Float64, order)

# Test and trial spaces for the state problem
V0 = TestFESpace(model, reffe, conformity=:H1, dirichlet_tags="boundary")
Vd = TrialFESpace(V0, yd)

# Function space for the control
U = FESpace(model, reffe, conformity=:H1)

# Set up measures
degree = 2*order
Ω = Triangulation(model)
dΩ = Measure(Ω, degree)

## Set-up and initial solve of state problem

# Initialize u with some random values
u_dof_vals  =  rand(Float64, num_free_dofs(U))
u = FEFunction(U, u_dof_vals)

# Define lhs/rhs for state problem
a(y,φ) = ∫(∇(y)⋅∇(φ))*dΩ
l(φ) = ∫((f+β*u)*φ)*dΩ

# Assemble lhs/rhs
A = assemble_matrix(a, Vd, V0)
b = assemble_vector(l, V0)

## Now solve the state problem, but cache the LU decomposition 
op = AffineOperator(A, b)
lu = LUSolver()
y_dof_vals  =  fill(0.0, num_free_dofs(V0))
@time cache = solve!(y_dof_vals, lu, op)
y = FEFunction(Vd, y_dof_vals)
ydiff = y - yΩ

## Set-up and initial solve of co-state problem
astar(p, ψ) = a(ψ, p)
lstar(ψ) = ∫((y-yΩ)*ψ)*dΩ

# Assemble lhs/rhs
# Note that we have Dirchlet b.c. y = 0 so Vd == V!
Astar = assemble_matrix(astar, Vd, V0)
bstar = assemble_vector(lstar, V0)

## Now solve the co-state problem, but cache the LU decomposition 
opstar = AffineOperator(Astar, bstar)
lustar = LUSolver()
p_dof_vals  =  fill(0.0, num_free_dofs(V0))
@time cache = solve!(p_dof_vals, lustar, opstar)
p = FEFunction(V0, p_dof_vals)

# Initial solve of state problem
# y = FEFunction(U, x)
writevtk(Ω, "results", cellfields=["y"=> y, "yOmega"=>yΩ, "ydiff" => ydiff, "u" => u, "p" => p])


# Set up initial

u = FEFunction(U, fill(1000.0, num_free_dofs(U)))
b = assemble_vector(l, V0)
op = AffineOperator(A, b)
@time cache = solve!(y_dof_vals, lu_solver, op, cache, false)
ydiff = y - yΩ
writevtk(Ω, "results_updated", cellfields=["y"=> y, "yOmega"=>yΩ, "ydiff" => ydiff, "u" => u])