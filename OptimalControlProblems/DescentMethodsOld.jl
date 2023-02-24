## 
using Gridap
# To get AffineOperator into global space
using Gridap.Algebra

function descent_method()
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

    ## Define l2 norms and cost functional
    l2(g) = sum(∫(g*g)*dΩ)^0.5
    J(y,u) = 1/2*sum(∫((y-yΩ)*(y-yΩ))*dΩ) + γ/2*sum(∫(u*u)*dΩ)

    # Good to know/mind variable scope: Note that J depends implicitly on γ. If you change γ, so will J!
    γ = 10^-6

    ## Set-up and initial solve of state problem

    # Initialize u with some random values
    u_dof_vals = rand(Float64, num_free_dofs(U))
    u = FEFunction(U, u_dof_vals)

    # Define lhs/rhs for state problem
    a(y,φ) = ∫(∇(y)⋅∇(φ))*dΩ
    l(φ) = ∫((f+β*u)*φ)*dΩ

    # Assemble lhs/rhs
    A = assemble_matrix(a, Vd, V0)
    b = assemble_vector(l, V0)
    println("Initial assembly of b")
    print(b[1:10])

    ## Now solve the state problem, but cache the LU decomposition 
    op = AffineOperator(A, b)
    lu = LUSolver()
    y_dof_vals  =  fill(0.0, num_free_dofs(V0))
    cache = solve!(y_dof_vals, lu, op)
    y = FEFunction(Vd, y_dof_vals)
    ydiff = y - yΩ

    cost = J(y, u)
    println("Initial cost after state solve J(y, u) = $(cost)")
    println("|| y ||^2 J(y, u) = $(cost)")

    ## Set-up and initial solve of co-state problem
    astar(p, ψ) = a(ψ, p)
    lstar(ψ) = ∫((y-yΩ)*ψ)*dΩ

    # Assemble lhs/rhs
    # Note that we have Dirchlet b.c. y = 0 so Vd == V!
    Astar = assemble_matrix(astar, Vd, V0)
    bstar = assemble_vector(lstar, V0)

    println("Initial assembly of bstar")
    print(bstar[1:10])

    ## Now solve the co-state problem, but cache the LU decomposition 
    opstar = AffineOperator(Astar, bstar)
    lustar = LUSolver()
    p_dof_vals  =  fill(0.0, num_free_dofs(V0))
    cache_star = solve!(p_dof_vals, lustar, opstar)
    p = FEFunction(V0, p_dof_vals)

    # Initial solve of state problem
    # y = FEFunction(U, x)
    writevtk(Ω, "results", cellfields=["y"=> y, "yOmega"=>yΩ, "ydiff" => ydiff, "u" => u, "p" => p])

    ## Prepare loop for descent method 
    ρ, α_0, α_min, σ, K_max, tol = 1/2, 1.0, (1/2)^5, 10^-2, 5, 10^-3

    # Store copies for iteration
    u_old = FEFunction(U, get_free_dof_values(u))
    y_old = FEFunction(V0, get_free_dof_values(y))
    cost_old = J(y_old, u_old)
    println("Initial cost J(y, u) = $(cost_old)")
    # Compute gradien>t
    Jgrad = (γ*u + β*p)
    # Compute descent direction
    dk = - Jgrad
    # Compute norm of initial gradient
    l2_Jgrad_0 = l2(Jgrad)
    k = 1 

    ## Run iteration
    while k <= K_max && l2(Jgrad) > tol*l2_Jgrad_0
        println("========================================")
        println("Iteration Step k = $(k)")
        println("||Jgrad||^2=$(l2(Jgrad)^2)")
        α = α_0
        # Start backtracking
        while α > α_min
            println("----------------------------------------")
            println("Step length alpha = $(α)")
            # Compute tentative new control function defined by current line search parameter
            u = interpolate(u_old + α*dk, U)
            ## DEBUG: Check wether l is actually modified!
            # u = FEFunction(U, fill(1000.0, num_free_dofs(U)))
            # Compute corresponding state problem by reassembling rhs l and solve linear system using the cached LU decomposition
            b = assemble_vector(l, V0)
            println("Assembly of b after change in loop")
            print(b[1:10])
            op = AffineOperator(A, b)
            cache = solve!(y_dof_vals, lu, op, cache, false)
            y.free_values .= y_dof_vals
            # y = FEFunction(Vd, y_dof_vals)
            # Compare decrease in functional and accept if sufficient
            cost = J(y, u)
            println(" J(y_old, u_old) = $(cost_old)")
            println(" J(y, u) = $(cost)")
            println("<Jgrad, dk>  = $(sum(∫(Jgrad*dk)*dΩ))")
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
        ## CHECK!: is new y actually impacting lstar?
        bstar = assemble_vector(lstar, V0)
        println("Assembly of bstar after change in loop")
        print(bstar[1:10])
        opstar = AffineOperator(Astar, bstar)
        cache_star = solve!(p_dof_vals, lustar, opstar, cache_star, false)
        p = FEFunction(V0, p_dof_vals)
        Jgrad = (γ*u + β*p)
        dk = - Jgrad
        k += 1
    end     

    ydiff = y - yΩ
    writevtk(Ω, "results", cellfields=["y"=> y, "yOmega"=>yΩ, "ydiff" => ydiff, "u" => u, "p" => p])
end

descent_method()

