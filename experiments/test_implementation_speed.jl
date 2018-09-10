


if !in("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo",LOAD_PATH)
    push!(LOAD_PATH,"C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo");
    println("LOAD_PATH was extended\n");
end



using FAST_GOBOARD
using FAST_AGENT
#using GOBOARD
#using AGENT



board_size=7
N=1000;
Winners1=["none" for j in 1:N];

println("\nTime for $N random games")

@time for j=1:N
    gstate=start_new_game(board_size);
    Winners1[j]=player(simulate_game(gstate,RandomBot(true)));
end
