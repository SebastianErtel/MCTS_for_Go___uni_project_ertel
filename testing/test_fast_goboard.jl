if !in("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo",LOAD_PATH)
    push!(LOAD_PATH,"C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo");
    println("LOAD_PATH was extended\n");
end



using FAST_GOBOARD

player1=:black;
player2=:white;

println("Player 1: $(other(player2))=$(player(player1))");
println("Player 1: $(other(player1))=$(player(player2))");
println("no Player: $(other(:nothing))=$(player(:nothing))\n");


position=point(2,2);

println("neighbors")
j=0;
pos=Dict([1=>"upper",2=>"lower",3=>"left",4=>"right"])

for neighbor in neighbors(position)
    j+=1;
    println("$neighbor -> $(pos[j])")
end

println("\n")
j=0;
str="";
for point in area(position)
    j+=1;
    str=str*"$point "
    if j==4
        str=str*"$position "
    end
    if j==3 || j==5 || j==8
        println(str);
        str="";
    end
end
println("\n")

display(play(point(2,2)))
println("\n")
display(pass_turn())
println("\n")
display(resign())
println("\n\n")

string1=GoString(:black,Set([(1,1),(1,2)]),Set([(2,2),(2,3),(2,1)]));
string2=GoString(:black,Set([(2,1)]),Set([(3,1),(2,2),(1,1)]));
string3=GoString(:white,Set([(3,2),(3,3)]),Set([(3,1),(2,2),(2,3)]));

add_liberty(string1,(1,3));
remove_liberty(string1,(2,1))
println(string1.liberties);

println("\n")
println(merged_with(string1,string2).stones)
println(merged_with(string1,string2).liberties)
println("Liberties of merged string: $(num_liberties(merged_with(string1,string2)))");
println(__eq__(string1,string2))
string2=deepcopy(string1)
println(__eq__(string1,string2))

println("\n")
@time for j=1:1000
    string1=GoString(:black,Set([(rand(1:3),rand(1:3)) for j in 1:rand(1:10)]),Set([(rand(1:3),rand(1:3)) for j in 1:rand(1:10)]));
    string2=GoString(:black,Set([(rand(1:3),rand(1:3)) for j in 1:rand(1:10)]),Set([(rand(1:3),rand(1:3)) for j in 1:rand(1:10)]));
    merged_with(string1,string2);
end

@time for j=1:1000
    string1=GoString(:black,Set([(rand(1:3),rand(1:3)) for j in 1:rand(1:10)]),Set([(rand(1:3),rand(1:3)) for j in 1:rand(1:10)]));
    string2=GoString(:black,Set([(rand(1:3),rand(1:3)) for j in 1:rand(1:10)]),Set([(rand(1:3),rand(1:3)) for j in 1:rand(1:10)]));
    string1=merged_with(string1,string2);
    string2=GoString(:nothing,Set{Tuple{Int64,Int64}}(),Set{Tuple{Int64,Int64}}());
end
println("\n")



board=create_board(9,9);
#display(board)

println("board size: $(board.num_rows)x$(board.num_cols)");
for j=1:4
    p=(rand(1:2board.num_rows),rand(1:2board.num_cols));
    println("$p $(is_on_grid(board,p) ? "is" :"is not" ) on board");
end
println("\n")



push!(board._grid,(1,1)=>string1)
display(get_go_string(board,(1,1)));
display(get_go_string(board,(1,2)));
println("\n");
println(get_stone(board,(1,1)))
println(get_stone(board,(1,2)))
println("\n\n");

#_remove_string(board,string1)
#display(board)


board=create_board(19,19);
place_stone(board,:black,(1,1));
place_stone(board,:white,(1,2));
place_stone(board,:black,(19,1));
place_stone(board,:white,(2,1));




gstate=start_new_game(5);

println("Next Player: $(next_player(gstate))\n")
println("Hashes: $(gstate.previous_states)\n")
println("Last 2 Moves: $(gstate.last_2_moves)\n")
#display(gstate.board)
println("\n")

gstate=apply_move(gstate,:black,Move((5,5),true,false,false));
println("Next Player: $(next_player(gstate))\n")
println("Hashes: $(gstate.previous_states)\n")
println("Last 2 Moves: $(gstate.last_2_moves)\n")
#display(gstate.board)
println("\n")

apply_move!(gstate,:white,Move((5,4),true,false,false));
println("Next Player: $(next_player(gstate))\n")
println("Hashes: $(gstate.previous_states)\n")
println("Last 2 Moves: $(gstate.last_2_moves)\n")
#display(gstate.board)
println("\n")

print_board(gstate.board)


#apply_move!(gstate,:black,Move((-1,-1),false,true,false));
#println(is_over(gstate));
#apply_move!(gstate,:white,Move((-1,-1),false,true,false));
#println(is_over(gstate));
#println("\n");




display(legal_moves(gstate))
apply_move!(gstate,:black,Move((1,4),true,false,false));
println("\n")
print_move(:black,gstate.last_2_moves[1]);
println("\n")
print_board(gstate.board)
println("\n\n\n")

#=
gstate=start_new_game(100);
@time for j=1:100, k=1:100
    gstate=apply_move(gstate,gstate.next_player[1],Move((j,k),true,false,false));
end


gstate=start_new_game(100);
@time for j=1:100, k=1:100
    apply_move!(gstate,gstate.next_player[1],Move((j,k),true,false,false));
end
=#





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


print_board(gstate.board)

println("\n");

points=[(5,1),(5,3),(2,4),(2,1)]

for p in points, c in [:black, :white]
    println("$p is $(is_point_an_eye(gstate.board,p,c) ? "" : "not") an eye of $c")
end




apply_move!(gstate,:white,Move((2,5),true,false,false));
apply_move!(gstate,:black,Move((1,3),true,false,false));
apply_move!(gstate,:white,Move((1,1),true,false,false));
apply_move!(gstate,:black,Move((1,2),true,false,false));
apply_move!(gstate,:white,Move((2,1),true,false,false));
apply_move!(gstate,:black,Move((2,2),true,false,false));

println("\n")
print_board(gstate.board)
println("Save from atari: $(save_from_atari(gstate))");
println("possible captures for $(:white): $(possible_captures(gstate,:white))");
println("possible captures for $(:black): $(possible_captures(gstate,:black))");
println("\n")
println("(1,5) is $(is_atari_move(gstate,(1,5),other(next_player(gstate))) ? "" : "not") atari move for $(other(next_player(gstate)))")
println("(1,5) is $(is_atari_move(gstate,(1,5)) ? "" : "not") atari move for $(next_player(gstate))")


println(cut1_pattern(gstate,(2,4)) ? "(2,4) matches Cut1 pattern" : "(2,4) does not match Cut1 pattern")
println(cut2_pattern(gstate,(2,4)) ? "(2,4) matches Cut2 pattern" : "(2,4) does not match Cut2 pattern")
println(hane_pattern(gstate,(2,4)) ? "(2,4) matches Hane pattern" : "(2,4) does not match Hane pattern")
println(boundary_pattern(gstate,(2,4)) ? "(2,4) matches boundary pattern" : "(2,4) does not match boundary pattern")










println("\n\n\n determining the  winner by area scoring")
gstate=start_new_game(9);
apply_move!(gstate,:black,Move((9,5),true,false,false));
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
apply_move!(gstate,:white,Move((5,4),true,false,false));
apply_move!(gstate,:black,Move((8,5),true,false,false));
apply_move!(gstate,:white,Move((6,4),true,false,false));
apply_move!(gstate,:black,Move((7,5),true,false,false));
apply_move!(gstate,:white,Move((7,4),true,false,false));
apply_move!(gstate,:black,Move((7,6),true,false,false));
apply_move!(gstate,:white,Move((7,3),true,false,false));
apply_move!(gstate,:black,Move((7,7),true,false,false));
apply_move!(gstate,:white,Move((7,2),true,false,false));
apply_move!(gstate,:black,Move((7,8),true,false,false));
apply_move!(gstate,:white,Move((7,1),true,false,false));
apply_move!(gstate,:black,Move((7,9),true,false,false));
apply_move!(gstate,:white,Move((8,4),true,false,false));
apply_move!(gstate,:black,Move((1,2),true,false,false));
apply_move!(gstate,:white,Move((5,5),true,false,false));
apply_move!(gstate,:black,Move((1,4),true,false,false));
apply_move!(gstate,:white,Move((5,6),true,false,false));
apply_move!(gstate,:black,Move((4,6),true,false,false));
apply_move!(gstate,:white,Move((5,7),true,false,false));
apply_move!(gstate,:black,Move((4,7),true,false,false));
apply_move!(gstate,:white,Move((6,8),true,false,false));
apply_move!(gstate,:black,Move((5,8),true,false,false));
apply_move!(gstate,:white,Move((3,1),true,false,false));
apply_move!(gstate,:black,Move((6,9),true,false,false));

#print_board(gstate.board)
result=area_scoring_graphical(gstate)
println("\nwinner: $(result[1])\n        score black: $(result[2])\n        score white: $(result[3])")


println("\n\n\nempty territories")
@time for territory in empty_territories(gstate)
    println(territory[1])
    println("is surrounded by $(territory[2])\n");
end
