#

if !in("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo",LOAD_PATH)
    push!(LOAD_PATH,"C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo");
    println("LOAD_PATH was extended\n");
end

function f()
    #gstate=start_new_game(5);
    @everywhere println(simulate_game(start_new_game(5),RandomBot(true)))
end

function g(gamestate)
    fref=[@spawnat pid simulate_game(gamestate,RandomBot(true)) for pid in workers()];
    res=[fetch(rref) for rref in fref];
    println(res);
end

#@everywhere using FAST_GOBOARD
#@everywhere using FAST_AGENT


num_procs=5;
println(nprocs())
addprocs(num_procs);
println(nprocs())
println("\n\n")

@everywhere using FAST_GOBOARD

@everywhere using FAST_AGENT;

gstate=start_new_game(5)
apply_move!(gstate,next_player(gstate),select_move(RandomBot(true),gstate));
apply_move!(gstate,next_player(gstate),select_move(RandomBot(true),gstate));
apply_move!(gstate,next_player(gstate),select_move(RandomBot(true),gstate));
apply_move!(gstate,next_player(gstate),select_move(RandomBot(true),gstate));
apply_move!(gstate,next_player(gstate),select_move(RandomBot(true),gstate));

print_board(gstate.board)


bootstrap_bot=StandardMCTSBot(true,10,sqrt(2),RandomBot(true));



x=pmap(select_move,[bootstrap_bot for j in 1:num_procs],[deepcopy(gstate) for j in 1:num_procs]);
display(x);



#g(deepcopy(gstate))




println("\n\n")
 rmprocs(workers());
 println(nprocs())
