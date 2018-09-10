

if !in("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo",LOAD_PATH)
    push!(LOAD_PATH,"C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo");
    println("LOAD_PATH was extended\n");
end

using FAST_GOBOARD
using FAST_AGENT

N=10;
board_sizes=[7];
results_agent1=[];
results_agent2=[];

function other_agent(x)
    return x==1 ? 2 : 1;
end

agent=[StandardMCTSBot(true,5000,sqrt(2),RandomBot(true),0.1),StandardMCTSBot(true,1000,sqrt(2),RandomBot_with_coded_patterns(true),0.1)];



println("\n\n\n\n$N games on boards of size $board_sizes")

tic()
for board_size in board_sizes
    alt=-1;
    wins=[0,0];


    for j=1:N
        alt=-alt;
        current_agent=1;

        if alt<0
            current_agent=2;
        end

        game_state=start_new_game(board_size);



        winner=simulate_game(game_state,agent[current_agent],agent[other_agent(current_agent)])

        if alt<0
            color_to_agent=Dict([:black=>2,:white=>1]);
        else
            color_to_agent=Dict([:black=>1,:white=>2]);
        end

        wins[color_to_agent[winner]]+=1;
        println("game $j")
    end

    push!(results_agent1,wins[1]/N);
    push!(results_agent2,wins[2]/N);

end

if isa(agent[1],MCTSBot)
    println("\n\nresults $(typeof(agent[1])) with  $(typeof(agent[1].simulation_bot)) and $(agent[1].num_rounds) sims: $results_agent1\n")
else
    println("\n\nresults $(typeof(agent[1])): $results_agent1\n")
end

if isa(agent[2],MCTSBot)
    println("\n\nresults $(typeof(agent[2])) with  $(typeof(agent[2].simulation_bot))  and $(agent[2].num_rounds): $results_agent2\n")
else
    println("\nresults $(typeof(agent[2])): $results_agent2\n\n")
end


toc()
