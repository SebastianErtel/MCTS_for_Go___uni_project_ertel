
if !in("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo",LOAD_PATH)
    push!(LOAD_PATH,"C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo");
    println("LOAD_PATH was extended\n");
end




#################################################################################################
#                                       Game Setting
#################################################################################################



board_size=6;
draw_time=0.01;



                player_white=7;
tmp_white=sqrt(2);
rollouts_white=1000;
num_workers_white=4;





                player_black=9;
tmp_black=0.0;
rollouts_black=1000;
num_workers_black=0;

try
    using PLAY_GO

    addprocs(max(num_workers_white,num_workers_black));
    @everywhere using FAST_GOBOARD
    @everywhere using FAST_AGENT
    println("\n\nNumber of processes: $(nprocs())\nNumber of Workers: $(length(workers()))")
    println("\n\n")

    play_game(board_size,draw_time,player_white,tmp_white,rollouts_white,num_workers_white,player_black,tmp_black,rollouts_black,num_workers_black)



finally
    if nprocs()>1
        rmprocs(workers());
    end
end
