
if !in("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo",LOAD_PATH)
    push!(LOAD_PATH,"C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo");
    println("LOAD_PATH was extended\n");
end



using FAST_GOBOARD
using FAST_AGENT




gstate=start_new_game(5);
gstate=apply_move(gstate,:black,Move((5,5),true,false,false));
apply_move!(gstate,:white,Move((5,4),true,false,false));
apply_move!(gstate,:black,Move((1,4),true,false,false));
apply_move!(gstate,:white,Move((4,4),true,false,false));
apply_move!(gstate,:black,Move((4,5),true,false,false));
apply_move!(gstate,:white,Move((4,3),true,false,false));
apply_move!(gstate,:black,Move((3,5),true,false,false));
apply_move!(gstate,:white,Move((4,2),true,false,false));
apply_move!(gstate,:black,Move((2,3),true,false,false));
apply_move!(gstate,:white,Move((4,1),true,false,false));
apply_move!(gstate,:black,Move((3,3),true,false,false));
apply_move!(gstate,:white,Move((5,2),true,false,false));
apply_move!(gstate,:black,Move((3,4),true,false,false));
apply_move!(gstate,:white,Move((2,5),true,false,false));
apply_move!(gstate,:black,Move((1,5),true,false,false));
print_board(gstate.board)
println("\n")
#display(legal_moves(gstate));
#println("\n")

print_move(next_player(gstate),select_move(RandomBot(true),gstate));
print_move(next_player(gstate),select_move(RandomBot_with_coded_patterns(true),gstate));

M=__init__MCTSNODE(gstate)
MM=__init__MCTSNODE(gstate,M,pass_turn())


println("M is an $(typeof(M))");
println("M $(MM.parent==M ? "is" : "is not") the parent of M. Move of MM:")
print_move(next_player(gstate),MM.move)

println("\nNumber of rollouts of MM $(number_of_rollouts(MM))");
set_num_rollouts(MM,15);
println("\nNumber of rollouts of MM $(number_of_rollouts(MM))");

add_random_child(MM);
add_random_child(MM);

println("\nNumber of children of MM: $(length(MM.children))");

#display(MM.children)


record_win(M,:black);
record_win(M,:white);
record_win(M,:white);
println("\nNumber of rollouts of M: $(number_of_rollouts(M))\nPct of game won by white $(winning_pct(M,:white))");

apply_move!(gstate,next_player(gstate),resign())
MMM=__init__MCTSNODE(gstate,MM)
println("\nMM $(is_terminal(MM) ? "is" : "is not") terminal")
println("MMM $(is_terminal(MMM) ? "is" : "is not") terminal")

println("\nMM $(can_add_child(MM) ? "can" : "can not") add children")
println("MMM $(can_add_child(MMM) ? "can" : "can not") add children")

#display(M)

display(StandardMCTSBot(true,1000,sqrt(2),RandomBot(true),0.05))

gstate=start_new_game(9);
println("\nWinner of Random Game $(simulate_game(gstate,RandomBot(true)))")
print_board(gstate.board)
gstate=start_new_game(9);
println("\nWinner of Random Game with pattern $(simulate_game(gstate,RandomBot_with_coded_patterns(true)))")
print_board(gstate.board)
println("\n\n")
println(area_scoring(gstate));
println("\n\n\n\n")


gstate=start_new_game(9);
apply_move!(gstate,:black,Move((4,4),true,false,false));
apply_move!(gstate,:white,Move((5,4),false,true,false));
apply_move!(gstate,:black,Move((-1,-1),false,false,true));
println(area_scoring_graphical(gstate))
