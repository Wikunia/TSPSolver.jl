@testset "berlin52" begin 
    bnb_model = TSPSolver.optimize(joinpath(@__DIR__, "..", "data", "berlin52.tsp"))
    tour = Bonobo.get_solution(bnb_model)
    optimal_tour = [1,49,32,45,19,41,8,9,10,43,33,51,11,52,14,13,47,26,27,28,12,25,4,6,15,5,24,48,38,37,40,39,36,35,34,44,46,16,29,50,20,23,30,2,7,42,21,17,3,18,31,22]
    @test tour[2:end] == optimal_tour[2:end] || tour[2:end] == reverse(optimal_tour[2:end])
end