

if !in("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo",LOAD_PATH)
    push!(LOAD_PATH,"C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo");
    println("LOAD_PATH was extended\n");
end

#using FAST_GOBOARD
#using FAST_AGENT

num_workers=4;

#addprocs(num_workers);
#@everywhere using FAST_GOBOARD
#@everywhere using FAST_AGENT

################################################################################################################################
#
#                                    Settings
#
################################################################################################################################

N=10;
board_size=7;
number_of_rollouts=1000;
println("\n\n\nboard size: $board_size        number of rollouts: $number_of_rollouts")

gstate=start_new_game(board_size);

number_of_stones_previously_played=0;

for j=1:number_of_stones_previously_played

    player=next_player(gstate);

    bot_move=select_move(RandomBot(true),gstate);

    apply_move!(gstate,player,bot_move);
        #print_board(game_state.board);
end


println("\nboard situation")
print_board(gstate.board)

################################################################################################################################
#
#                                    Bot
#
################################################################################################################################



#bot=StandardMCTSBot(true,number_of_rollouts,sqrt(2),RandomBot(true),0.1);
#bot=EconomicMCTSBot(true,number_of_rollouts,sqrt(2),RandomBot(true),0.1);
bot=VirtualMCTSBot(true,number_of_rollouts,sqrt(2),RandomBot(true),0.1);
#bot=create_HeuristicMCRaveBot_random_sims(number_of_rollouts,0.0,0.1,:EvenGame,60)
#bot=RootParallelMCTSBot(true,number_of_rollouts,sqrt(2),RandomBot(true),num_workers,0.1);
#bot=LeafParallelMCTSBot(true,number_of_rollouts,sqrt(2),RandomBot(true),num_workers,0.1);

println("\n\nData for $(typeof(bot))");

################################################################################################################################
#
#                                   printed speed test
#
################################################################################################################################



println("\nwith @time:")
    @time select_move(bot,gstate)

println("\navg for elapsed:")

    t=@elapsed for j in 1:N
        select_move(bot,gstate)
    end

t=t/N;
println("      $t");





if nprocs()>1
    rmprocs(workers());
end
