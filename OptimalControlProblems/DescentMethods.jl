## 
using Gridap

# To get AffineOperator into global space
using Gridap.Algebra

function descent_method(;a, l, astar, lstar, spaces, J, ∇J,
                         ρ, α_0, α_min, σ, K_max, tol)
    ## Step 1 Initialization 

    # Extract spaces
    Vd, V0, U = spaces

    # Initialize u with some random values
    u_dof_vals = rand(Float64, num_free_dofs(U))
    u = FEFunction(U, u_dof_vals)

    # Assemble lhs/rhs
    A = assemble_matrix(a, Vd, V0)
    b = assemble_vector(φ ->l(φ, u), V0)

    ## Now solve the state problem, but cache the LU decomposition 
    op = AffineOperator(A, b)
    lu = LUSolver()
    y_dof_vals  =  fill(0.0, num_free_dofs(V0))
    cache = solve!(y_dof_vals, lu, op)
    y = FEFunction(Vd, y_dof_vals)
    ydiff = y - yΩ

    # Assemble lhs/rhs
    # Note that we have Dirchlet b.c. y = 0 so Vd == V!
    Astar = assemble_matrix(astar, Vd, V0)
    bstar = assemble_vector(ψ -> lstar(ψ,y), V0)

    ## Now solve the co-state problem, but cache the LU decomposition 
    opstar = AffineOperator(Astar, bstar)
    lustar = LUSolver()
    p_dof_vals  =  fill(0.0, num_free_dofs(V0))
    cache_star = solve!(p_dof_vals, lustar, opstar)
    p = FEFunction(V0, p_dof_vals)

    # Initial solve of state problem
    writevtk(Ω, "results_intial", cellfields=["y"=> y, "yOmega"=>yΩ, "ydiff" => ydiff, "u" => u, "p" => p])

    # Store copies for iteration
    u_old = FEFunction(U, get_free_dof_values(u))
    y_old = FEFunction(V0, get_free_dof_values(y))
    cost_old = J(y_old, u_old)
    println("Initial cost J(y, u) = $(cost_old)")

    # Compute initial gradient
    Jgrad =  ∇J(u, p)
    # Compute initial descent direction
    dk = - Jgrad
    # Compute norm of initial gradient
    l2_Jgrad_0 = l2(Jgrad)

    ## Step 2: Run iteration
    k = 1 
    while k <= K_max && l2(Jgrad) > tol*l2_Jgrad_0
        println("========================================")
        println("Iteration Step k = $(k)")
        # Make sure that cost variable is defined outside of backtracking loop
        cost = cost_old

        # Start backtracking
        α = α_0
        while α > α_min
            println("----------------------------------------")
            println("Step length alpha = $(α)")
            # Compute tentative new control function defined by current line search parameter
            u = interpolate(u_old + α*dk, U)

            # Compute corresponding state problem by reassembling rhs l and solve linear system using the cached LU decomposition
            b = assemble_vector(φ->l(φ, u), V0)
            op = AffineOperator(A, b)
            cache = solve!(y_dof_vals, lu, op, cache, false)
            y = FEFunction(Vd, y_dof_vals)

            # Compare decrease in functional and accept if sufficient
            cost = J(y, u)
            println(" J(y_old, u_old) = $(cost_old)")
            println(" J(y, u) = $(cost)")
            if cost < cost_old + σ*α*sum(∫(Jgrad*dk)*dΩ)
                break
            else
                α *= ρ
            end
        end

        # Store latest control and state and resulting cost for next iteration
        u_old = FEFunction(U, get_free_dof_values(u))
        y_old = FEFunction(V0, get_free_dof_values(y))
        cost_old = cost

        # Compute new gradient via new adjoint state
        bstar = assemble_vector(ψ -> lstar(ψ,y), V0)
        opstar = AffineOperator(Astar, bstar)
        cache_star = solve!(p_dof_vals, lustar, opstar, cache_star, false)
        p = FEFunction(V0, p_dof_vals)
        Jgrad = (γ*u + β*p)
        dk = - Jgrad
        k += 1
    end     

    ydiff = y - yΩ
    writevtk(Ω, "results_final", cellfields=["y"=> y, "yOmega"=>yΩ, "ydiff" => ydiff, "u" => u, "p" => p])
end

domain = (0,1,0,1)
partition = (50, 50)
model = CartesianDiscreteModel(domain, partition) |> simplexify
writevtk(model, "mesh_nx$(partition[1])_ny$(partition[2])")

#
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

## Define l2 norms and cost functional
l2(g) = sum(∫(g*g)*dΩ)^0.5
# Good to know/mind variable scope: Note that J depends implicitly on γ. If you change γ, so will J!
γ = 10^-6
J(y,u) = 1/2*sum(∫((y-yΩ)*(y-yΩ))*dΩ) + γ/2*sum(∫(u*u)*dΩ)

## Set-up and initial solve of state problem

# Define lhs for state problem
a(y,φ) = ∫(∇(y)⋅∇(φ))*dΩ
# Define lhs for state problem
# As the control u will change throughout the numerical computation
# make l dependent on u as well.
# Later we use lambda function to make a concrete l in each step, e.g.
# l_u = φ -> l(φ, u)
l(φ, u) = ∫((f+β*u)*φ)*dΩ

# Set-up and initial solve of co-state problem
astar(p, ψ) = a(ψ, p)
# As the control state will change throughout the numerical computation
# make lstar dependent on y as well.
# Later we use lambda function to make a concrete lstar in each step.
lstar(ψ, y) = ∫((y-yΩ)*ψ)*dΩ

# Define gradient
∇J(u, p) = (γ*u + β*p)

# Set parameter for descent method 
ρ, α_0, α_min, σ, K_max, tol = 1/2, 1.0, (1/2)^5, 10^-4, 2000, 10^-3

descent_method(a=a, l=l, astar=astar, lstar=lstar, spaces=(Vd, V0, U), J=J, ∇J=∇J,
               ρ=ρ, α_0=α_0, α_min=α_min, σ=σ, K_max=K_max, tol=tol)
