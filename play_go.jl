if !in("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo",LOAD_PATH)
    push!(LOAD_PATH,"C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo");
    println("LOAD_PATH was extended\n");
end



module PLAY_GO

export play_game


using FAST_GOBOARD
using FAST_AGENT



function play_game(board_size,draw_time,player_white,tmp_white,rollouts_white,num_procs_white,player_black,tmp_black,rollouts_black,num_procs_black,resignation_boundary=0.07)



    #board_size=5;
    #draw_time=1;



                playerWhite=player_white;
                    tmp1=tmp_white;
                    num_rounds1=rollouts_white;





                playerBlack=player_black;
                    tmp2=tmp_black;
                    num_rounds2=rollouts_black;

##################################################################################################
#                                          Game
##################################################################################################


(WHITEAGENT=Dict([1=>RandomBot(true),
                 2=>RandomBot_with_coded_patterns(true),
                 3=>EconomicMCTSBot(true,num_rounds1,tmp1,RandomBot(true),resignation_boundary),
                 4=>EconomicMCTSBot(true,num_rounds1,tmp1,RandomBot_with_coded_patterns(true),resignation_boundary),
                 5=>LeafParallelMCTSBot(true,num_rounds1,tmp1,RandomBot(true),num_procs_white,resignation_boundary),
                 6=>LeafParallelMCTSBot(true,num_rounds1,tmp1,RandomBot_with_coded_patterns(true),num_procs_white,resignation_boundary),
                 7=>RootParallelMCTSBot(true,num_rounds1,tmp1,RandomBot(true),num_procs_white,resignation_boundary),
                 8=>RootParallelMCTSBot(true,num_rounds1,tmp1,RandomBot_with_coded_patterns(true),num_procs_white,resignation_boundary),
                 9=>create_HeuristicMCRaveBot_random_sims(num_rounds1,tmp1,resignation_boundary,:EvenGame,1),
                 10=>VirtualMCTSBot(true,num_rounds1,tmp1,RandomBot(true),resignation_boundary),
                 11=>VirtualMCTSBot(true,num_rounds1,tmp1,RandomBot_with_coded_patterns(true),resignation_boundary) ]))


(BLACKAGENT=Dict([1=>RandomBot(true),
                  2=>RandomBot_with_coded_patterns(true),
                  3=>EconomicMCTSBot(true,num_rounds2,tmp2,RandomBot(true),resignation_boundary),
                  4=>EconomicMCTSBot(true,num_rounds2,tmp2,RandomBot_with_coded_patterns(true),resignation_boundary),
                  5=>LeafParallelMCTSBot(true,num_rounds2,tmp2,RandomBot(true),num_procs_black,resignation_boundary),
                  6=>LeafParallelMCTSBot(true,num_rounds2,tmp2,RandomBot_with_coded_patterns(true),num_procs_black,resignation_boundary),
                  7=>RootParallelMCTSBot(true,num_rounds2,tmp2,RandomBot(true),num_procs_black,resignation_boundary),
                  8=>RootParallelMCTSBot(true,num_rounds2,tmp2,RandomBot_with_coded_patterns(true),num_procs_black,resignation_boundary),
                  9=>create_HeuristicMCRaveBot_random_sims(num_rounds2,tmp2,resignation_boundary,:EvenGame,1)
                  10=>VirtualMCTSBot(true,num_rounds2,tmp2,RandomBot(true),resignation_boundary),
                  11=>VirtualMCTSBot(true,num_rounds2,tmp2,RandomBot_with_coded_patterns(true),resignation_boundary)       ]))


turncounter=0;

#m=Move(Point(1,1),true,false,false)

game=start_new_game(board_size)
bots=Dict([:black=>BLACKAGENT[playerBlack],:white=>WHITEAGENT[playerWhite]]);
selection=Dict([:black=>playerBlack,:white=>playerWhite]);


print_board(game.board);

win_pct=0;
player=next_player(game);


while !is_over(game)
    #workspace();

    player=next_player(game);

    turncounter+=1;

    tic()

    if selection[player]>=3

        move_array=select_move(bots[player],game);

        win_pct=move_array[2];

        bot_move=move_array[1];

    else

        bot_move=select_move(bots[player],game);
    end

    game=apply_move(game,player,bot_move);

    print_board(game.board);
    #print_board_graphical(game.board);

    print_move(player,bot_move);

    if (selection[player]>=3)
        if (win_pct>0)
            println("\nwinning pct:  $win_pct\nturn: $turncounter");
        else
            println("\n\n\nturn: $turncounter")
        end

    else
        println("\n\n\nturn: $turncounter")
    end

    toc();
    println("\n\n")


    #if(selection[player.color]==1)
        sleep(draw_time);
    #end

end

Winner=area_scoring_graphical(game);
#if last_move(game).is_resign
#    if (player==:black)
#        Winner[1]=:white;
#    else
#        Winner[1]=:black;
#    end
#end

println("Winner    $(Winner[1])\n");
println("Score:\n")
println("Black     $(Winner[2])\n");
println("White     $(Winner[3])\n");
println("$turncounter turns played");

end



end
