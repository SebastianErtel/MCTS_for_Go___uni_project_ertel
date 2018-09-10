if !in("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo",LOAD_PATH)
    push!(LOAD_PATH,"C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo");
    println("LOAD_PATH was extended\n");
end

using FAST_GOBOARD
using FAST_AGENT


N=200;
board_sizes=[5,7,9,13];
results_agent1=[];
results_agent2=[];


agent=[RandomBot(true),RandomBot_with_coded_patterns(true)];

function other_agent(x)
    return x==1 ? 2 : 1;
end

@time for board_size in board_sizes
    alt=-1;
    wins=[0,0];


    for j=1:N
        alt=-alt;
        current_agent=1;

        if alt<0
            current_agent=2;
        end

        game_state=start_new_game(board_size);

        while (!is_over(game_state))

            #player=next_player(game_state);

            #bot_move=select_move(agent[current_agent],game_state);

            apply_move!(game_state,next_player(game_state),select_move(agent[current_agent],game_state));
                #print_board(game_state.board);

            current_agent=other_agent(current_agent);

        end

        winner=get_winner(game_state)[1];

        if alt<0
            color_to_agent=Dict([:black=>2,:white=>1]);
        else
            color_to_agent=Dict([:black=>1,:white=>2]);
        end

        wins[color_to_agent[winner]]+=1;

    end

    push!(results_agent1,wins[1]/N);
    push!(results_agent2,wins[2]/N);
end


println("\n\nresults agent1: $results_agent1\n")
println("\nresults agent2: $results_agent2\n\n")
