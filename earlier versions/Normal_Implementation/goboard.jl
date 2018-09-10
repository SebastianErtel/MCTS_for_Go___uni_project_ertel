module GOBOARD

export Player, player, other, Point, point, neighbors, area, Move, play, pass_turn, resign, GoString, remove_liberty, add_liberty, merged_with, num_liberties, __eq__, Board, is_on_grid, get_go_string, get_stone, place_stone, GameState, next_player, apply_move, start_new_game, is_over, is_move_self_capture, situation, does_move_violate_ko, is_valid_move, legal_moves, get_winner, create_board, print_move, print_board, is_point_an_eye, is_atari_move, save_from_atari, possible_captures, hane_pattern, cut1_pattern, cut2_pattern, boundary_pattern


#include("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo\\gotypes.jl")




############################################################################
#                           Zobrist Hashes
############################################################################

global_num_rows=19;
global_num_cols=19;

function generate_rand_position_code_table(num_rows::Int,num_cols::Int)
    table=Dict([])


    MAX63=0x7fffffffffffffff;

    for row in 1:num_rows
        for col in 1:num_cols
            for color in ["black","white"]
                code=rand(1:MAX63);


                push!(table,(row,col,color)=>code);
            end
        end
    end

    empty_board=xor(MAX63,MAX63);
    push!(table,0=>empty_board);

    return table;
end

HASH_CODE=generate_rand_position_code_table(global_num_rows,global_num_cols);





#################################################################################
#                           Player Class
#################################################################################



struct Player
    color;
end

function player(player::Player)
    #returns the color of player as a string
    return player.color;
end

function other(playervariable::Player)
    #returns the color of the other player

    @assert (playervariable.color=="black" || playervariable.color=="white")

    if(playervariable.color=="black")
        return "white";
    else
        return "black";
    end

end



#################################################################################
#                           Point Class
#################################################################################




struct Point
    row;
    col;
end

function point(row,col)
    return Point(row, col);
end

function neighbors(point::Point)
        return [Point(point.row-1,point.col), Point(point.row+1,point.col),
                Point(point.row,point.col-1), Point(point.row,point.col+1)];
end

function area(point::Point)
        return [Point(point.row+1,point.col), Point(point.row+1,point.col+1),
                Point(point.row,point.col+1), Point(point.row-1,point.col+1),
                Point(point.row-1,point.col), Point(point.row-1,point.col-1),
                Point(point.row,point.col-1), Point(point.row+1,point.col-1)];
end



############################################################################
#                               Move Class
############################################################################
struct Move
    point; #should be point or nothing
    is_play::Bool;
    is_pass::Bool;
    is_resign::Bool;
end

function play(p::Point)
    return Move(p,true,false,false);
end

function pass_turn()
    return Move(nothing,false,true,false);
end

function resign()
    return Move(nothing,false,false,true);
end



###############################################################################
#                           GoString Class
###############################################################################

struct GoString
    color::String;
    stones; # set of points
    liberties;  #set of points
end

function remove_liberty(string::GoString,p::Point)
    if(in(p,string.liberties))
        pop!(string.liberties,p);
    else
        println("warning, attempt to remove non existant liberty")
    end
end

function add_liberty(gostring::GoString,p::Point)
    push!(gostring.liberties,p);
end

function merged_with(gostring1::GoString,gostring2::GoString)
    @assert(gostring1.color==gostring2.color);

    combined_stones=union(gostring1.stones,gostring2.stones);

    return GoString(gostring1.color,combined_stones,setdiff(union(gostring1.liberties,gostring2.liberties),combined_stones));
end

function num_liberties(gostring::GoString)
    return length(gostring.liberties);
end

function __eq__(gostring1::GoString,gostring2::GoString)
    return ((gostring1 isa GoString)&&(gostring1 isa GoString)&&
                (gostring1.color==gostring2.color)&&
                (gostring1.stones==gostring2.stones)&&
                (gostring1.liberties==gostring2.liberties)
                )

end


#############################################################################
#                           Board Class
#############################################################################

struct Board
    num_rows; #number of rows
    num_cols; #number of columns of the Go board
    _grid; #dictionary that stores strings of stones
    _hash::Vector{UInt64}; #hash value of the board configuration

end

function create_board(num_rows,num_cols)
    @assert (num_rows<=global_num_rows) "num_rows>$global_num_rows\n"
    @assert (num_cols<=global_num_cols ) "num_cols>$global_num_cols\n"

    return Board(num_rows,num_cols,Dict([]),[HASH_CODE[0]])
end


function is_on_grid(board::Board,point::Point)
    return ((1<=point.row)&&(point.row<=board.num_rows)&&(1<=point.col)&&(point.col<=board.num_cols));
end

function get_go_string(board::Board,point::Point)
    str=get(board._grid,point,nothing);
    if(str==nothing)
        return nothing;
    end
    return str;
end

function get_stone(board::Board,point::Point)
    str=get(board._grid,point,nothing);
    if(str==nothing)
        return nothing;
    end
    return str.color;
end

function _remove_string(board::Board,str::GoString)
    for point in str.stones
        for neighbor in neighbors(point)
            neighbor_string=get_go_string(board,neighbor);
            if (neighbor_string==nothing)
                continue;
            else
                add_liberty(neighbor_string,point);
            end
        end
        delete!(board._grid,point);

    board._hash[1]=xor(board._hash[1],HASH_CODE[point.row,point.col,str.color]);
    end
end



function place_stone(board::Board,player::Player,point::Point)
    @assert(is_on_grid(board,point));
    @assert(get(board._grid,point,nothing)==nothing);

    adjacent_same_color=[];
    adjacent_opposite_color=[];
    liberties=[];

    for neighbor in neighbors(point)

        if(!(is_on_grid(board,neighbor)))
            continue;
        end

        neighbor_string=get_go_string(board,neighbor);

       if(neighbor_string==nothing)
            push!(liberties,neighbor);
        elseif neighbor_string.color==player.color
            if(!(in(neighbor_string,adjacent_same_color)))
                push!(adjacent_same_color,neighbor_string);
            end
        else
            if(!(in(neighbor_string,adjacent_opposite_color)))
                push!(adjacent_opposite_color,neighbor_string);
            end
        end
    end

    new_string=GoString(player.color,Set([point]),Set(liberties));

    for same_color_string in adjacent_same_color
        new_string=merged_with(new_string,same_color_string);
    end

    for new_string_point in new_string.stones
        board._grid[new_string_point]=new_string;
    end

    board._hash[1]=xor(board._hash[1],HASH_CODE[point.row,point.col,player.color]);

    for other_color_string in adjacent_opposite_color
        remove_liberty(other_color_string,point);
    end

    for other_color_string in adjacent_opposite_color
        if (num_liberties(other_color_string)==0)
            _remove_string(board,other_color_string);
        end
    end

end

function hash(board::Board)
    return board._hash[1];
end





#################################################################################
#                              Game State Class
#################################################################################

struct GameState
    board::Board;
    next_player::Player;
    previous_states; #set of tuples of hash values of previous game states and the last player color (as a string)
    last_move; # last move
    second_last_move; # move before the last move
end

function next_player(state::GameState)
    return state.next_player.color;
end



function apply_move!(state::GameState,player::Player,move::Move)

    @assert (player.color==state.next_player.color) ["Argument player is not the next player!\n player: $(player.color) != next player: $(state.next_player.color)"];
    #if(player.color!=state.next_player.color)
    #        ArgumentError("Argument player is not the next player!\n player: $(player.color) != next player: $(state.next_player.color)");
    #end

    push!(state.previous_states,(state.next_player.color,hash(state.board)));

    if(move.is_play)
        place_stone(state.board,player,move.point);
    end

    state.second_last_move=state.last_move;
    state.last_move=move;
    state.next_player=Player(other(player));

end

function apply_move(state::GameState,player::Player,move::Move)

    @assert (player.color==state.next_player.color) ["Argument player is not the next player!\n player: $(player.color) != next player: $(state.next_player.color)"];
    #if(player.color!=state.next_player.color)
    #        ArgumentError("Argument player is not the next player!\n player: $(player.color) != next player: $(state.next_player.color)");
    #end

    next_previous_states=deepcopy(state.previous_states)
    push!(next_previous_states,(state.next_player.color,hash(state.board)))

    if(move.is_play)
        next_board=deepcopy(state.board);
        place_stone(next_board,player,move.point);
    else
        next_board=state.board;
    end


    return GameState(next_board,Player(other(player)),next_previous_states,move,state.last_move);
end



#class method

function start_new_game(board_size)
    board=create_board(board_size,board_size);
    return GameState(board,Player("black"),Set([]),nothing,nothing);
end



function is_over(state::GameState)
    if (state.last_move==nothing)
        return false;
    end

    if(state.last_move.is_resign)
        return true;
    end

    if(state.second_last_move==nothing)
        return false;
    end

    return (state.last_move.is_pass && state.second_last_move.is_pass);
end



function is_move_self_capture(state::GameState,player::Player,move::Move)
    if(!(move.is_play))
        return false;
    end

    next_board=deepcopy(state.board);
    place_stone(next_board,player,move.point);
    new_string=get_go_string(next_board,move.point);

    return (num_liberties(new_string)==0)

end



function situation(state::GameState)
    return (state.next_player,state.board);
end



function does_move_violate_ko(state::GameState,player::Player,move::Move)

    if(!(move.is_play))
        return false;
    end

    next_board=deepcopy(state.board);
    place_stone(next_board,player,move.point);
    next_player=Player(other(player));
    next_situation=(next_player.color,hash(next_board));


    return (next_situation in state.previous_states);
end



function is_valid_move(state::GameState,move::Move)
    if(is_over(state))
        return false;
    end

    if(move.is_pass || move.is_resign)
        return true;
    end

    return ((get_stone(state.board,move.point)==nothing) &&
            !(is_move_self_capture(state,state.next_player,move))&&
            !(does_move_violate_ko(state,state.next_player,move)))
end



function legal_moves(state::GameState)

    possible_moves=[];

    for row in 1:state.board.num_rows

        for col in 1:state.board.num_cols
            if  is_valid_move(state,Move(Point(row,col),true,false,false))

                push!(possible_moves,Move(Point(row,col),true,false,false));

            end
        end
    end

    return possible_moves;
end




function get_winner(state::GameState)
# returns winner by area scoring

    score_white=0;
    score_black=0;

    #komi compensation
    score_white=6.5;

    neighbor_set=Set([])
    empty_neighbor=false;


    for row in 1:state.board.num_rows
        for col in 1:state.board.num_cols

            stone=get_stone(state.board,Point(row,col));

            if(stone==nothing)
                empty_neighbor=false;
                for neighbor in neighbors(Point(row,col))
                    if (!(is_on_grid(state.board,neighbor)))
                        continue;
                    end

                    if neighbor==nothing
                        empty_neighbor==true;
                    end

                    if (get_stone(state.board,neighbor)=="black" && !(empty_neighbor))
                        push!(neighbor_set,"black");
                    elseif (get_stone(state.board,neighbor)=="white"&& !(empty_neighbor))
                        push!(neighbor_set,"white");
                    end
                end

                if(neighbor_set==Set(["white"]))
                    score_white+=1;
                elseif (neighbor_set==Set(["black"]))
                    score_black+=1;
                end

                neighbor_set=Set([]);


            elseif(stone=="black")
                score_black+=1;
            else
                score_white+=1;
            end
        end
    end

    if(score_black>score_white)
        return ["black",score_black,score_white];
    else
        return ["white",score_black,score_white];
    end

end

#########################################################################################################################
#                                  Print board
#########################################################################################################################



COLS="ABCDEFGHJKLMNOPQRST";

#stone_to_char=Dict([nothing=>'.',"black"=>'x',"white"=>'o']);
stone_to_char=Dict([nothing=>'.',"white"=>'⚈',"black"=>'O']);


function print_move(player::Player,move::Move)
    if(move.is_pass)
        move_str="passes";
    elseif(move.is_resign)
        move_str="resigns";
    else
        move_str=string("(",COLS[move.point.col],move.point.row,")");
    end

    println("\n $(player.color): $move_str");
end



function print_board(board::Board)

    for row in 1:board.num_rows

        disprow="";

        for col in 1:board.num_cols
            stone=get_stone(board,Point(row,col));

            disprow*="$(stone_to_char[stone])  ";
        end

        println("\n$row   $disprow");
    end


    disprow=""

    for col in 1:board.num_cols
        disprow*="$(COLS[col])  ";
    end
    println("\n.   $disprow\n");

end

################################################################################
#                       auxiliary functions
################################################################################



function is_point_an_eye(board::Board,point::Point,color::String)
    if(get_stone(board,point)!=nothing)
        return false;
    end

    for neighbor in neighbors(point)
        if(is_on_grid(board,neighbor))
            if(get_stone(board,neighbor)!=color)
                return false;
            end
        end
    end

    friendly_corners=0;
    off_board_corners=0;
    corners=[Point(point.row-1,point.col-1),Point(point.row-1,point.col+1),Point(point.row+1,point.col-1),Point(point.row+1,point.col+1)];

    for corner in corners
        if(is_on_grid(board,corner))
            if(color==get_stone(board,corner))
                friendly_corners+=1;
            end
        else
            off_board_corners+=1;
        end
    end

    if(off_board_corners>0)
        return (off_board_corners+friendly_corners==4);
    end

    return (friendly_corners>=3)
end



function is_atari_move(state::GameState,point::Point)

    next_board=deepcopy(state.board);

    place_stone(next_board,state.next_player,point);

    str=get_go_string(next_board,point);

    return (length(str.liberties)==1);
end



function save_from_atari(state::GameState)

    saving_stones=Set([]);

    if(state.last_move!=nothing)
        if(state.last_move.is_play==true)
            p=state.last_move.point;

            for neighbor in neighbors(p)
                if(is_on_grid(state.board,neighbor) && (get_stone(state.board,neighbor)==state.next_player.color))

                    str=get_go_string(state.board,neighbor);

                    if(length(str.liberties)==1)

                        pp=pop!(deepcopy(str.liberties));

                        if is_valid_move(state,Move(pp,true,false,false))
                            saving_stones=union(saving_stones,str.liberties);
                        end
                    end
                end
            end
        end
    end


    return collect(saving_stones);
end



function possible_captures(state::GameState,player::Player)

    capturing_points=Set([]);

    for str in Set(values(state.board._grid))
        if(str.color==other(player))
            if(length(str.liberties)==1)
                pp=pop!(deepcopy(str.liberties));

                if is_valid_move(state,Move(pp,true,false,false))
                    capturing_points=union(capturing_points,str.liberties);
                end
            end
        end
    end

    return collect(capturing_points);
end



function hane_pattern(state::GameState,point::Point)

    row=point.row;
    col=point.col;

    for p in area(point)
        if (!(is_on_grid(state.board,p)))
            return false;
        end
    end

    a=get_stone(state.board,Point(row+1,col-1));
    b=get_stone(state.board,Point(row+1,col));
    c=get_stone(state.board,Point(row+1,col+1));
    d=get_stone(state.board,Point(row,col-1));
    e=get_stone(state.board,Point(row,col+1));
    f=get_stone(state.board,Point(row-1,col-1));
    g=get_stone(state.board,Point(row-1,col));
    h=get_stone(state.board,Point(row-1,col+1));



    t1=((c!=nothing) && (b!=nothing) && (c==a) && (c!=b) && (e==nothing) && (d==nothing));

    t2=((a!=nothing) && (d!=nothing) && (f==a) && (a!=d) && (b==nothing) && (g==nothing));

    t3=((f!=nothing) && (g!=nothing) && (f==h) && (f!=g) && (d==nothing) && (e==nothing));

    t4=((h!=nothing) && (e!=nothing) && (c==h) && (h!=e) && (g==nothing) && (b==nothing));



    T1=(t1 || t2 || t3 || t4);




    t1=((a!=nothing) && (b!=nothing) && (a!=b) && (c==nothing) && (e==nothing) && (d==nothing) && (g==nothing));

    t1= t1 || ((c!=nothing) && (b!=nothing) && (c!=b) && (a==nothing) && (d==nothing) && (e==nothing) && (g==nothing)) ;

    t2=((f!=nothing) && (d!=nothing) && (f!=d) && (a==nothing) && (b==nothing) && (e==nothing) && (g==nothing));

    t2= t2 || ((a!=nothing) && (d!=nothing) && (a!=d) && (f==nothing) && (b==nothing) && (g==nothing) && (e==nothing));

    t3=((c!=nothing) && (e!=nothing) && (c!=e) && (h==nothing) && (b==nothing) && (d==nothing) && (g==nothing));

    t3= t3 || ((h!=nothing) && (e!=nothing) && (h!=e) && (c==nothing) && (b==nothing) && (d==nothing) && (g==nothing));

    t4=((h!=nothing) && (g!=nothing) && (h!=g) && (f==nothing) && (d==nothing) && (e==nothing) && (b==nothing));

    t4= t4 || ((f!=nothing) && (g!=nothing) && (f!=g) && (h==nothing) && (d==nothing) && (e==nothing) && (b==nothing));


    T2=(t1 || t2 || t3 || t4);




    t1=((a!=nothing) && (b!=nothing) && (a==d) && (a!=b) && (g==nothing) && (e==nothing));

    t1= t1 || ((c!=nothing) && (b!=nothing) && (c==e) && (b!=c) && (d==nothing) && (g==nothing));

    t2=((f!=nothing) && (d!=nothing) && (f==g) && (d!=f) && (b==nothing) && (e==nothing));

    t2= t2 || ((a!=nothing) && (d!=nothing) && (a==b) && (d!=a) && (g==nothing) && (e==nothing));

    t3=((h!=nothing) && (g!=nothing) && (h==e) && (h!=g) && (d==nothing) && (b==nothing));

    t3= t3 || ((f!=nothing) && (g!=nothing) && (f==d) && (f!=g) && (e==nothing) && (b==nothing));

    t4=((c!=nothing) && (e!=nothing) && (c==b) && (c!=e) && (g==nothing) && (d==nothing));

    t4=t4 || ((h!=nothing) && (e!=nothing) && (h==g) && (h!=e) && (b==nothing) && (d==nothing));


    T3=(t1 || t2 || t3 || t4);



    t1=((state.next_player.color==a) && (b!=nothing) && (c==b) && (a!=b) && (d==nothing) && (e==nothing) && (g==nothing));

    t1= t1 || ((state.next_player.color==c) && (b!=nothing) && (a==b) && (c!=b) && (d==nothing) && (e==nothing) && (g==nothing));

    t2=((state.next_player.color==f) && (d!=nothing) && (a==d) && (f!=d) && (b==nothing) && (e==nothing) && (g==nothing));

    t2= t2 || ((state.next_player.color==a) && (d!=nothing) && (f==d) && (a!=d) && (b==nothing) && (e==nothing) && (g==nothing));

    t3=((state.next_player.color==f) && (g!=nothing) && (h==g) && (f!=g) && (d==nothing) && (e==nothing) && (b==nothing));

    t3= t3 || ((state.next_player.color==h) && (g!=nothing) && (f==g) && (h!=g) && (d==nothing) && (e==nothing) && (b==nothing));

    t4=((state.next_player.color==h) && (e!=nothing) && (c==e) && (h!=e) && (b==nothing) && (d==nothing) && (g==nothing));

    t4= t4 || ((state.next_player.color==c) && (e!=nothing) && (h==e) && (c!=e) && (b==nothing) && (d==nothing) && (g==nothing));


    T4=(t1 || t2 || t3 || t4);

        return (T1 || T2 || T3 || T4);

end



function cut1_pattern(state::GameState,point::Point)

    row=point.row;
    col=point.col;

    for p in area(point)
        if (!(is_on_grid(state.board,p)))
            return false;
        end
    end

    a=get_stone(state.board,Point(row+1,col-1));
    b=get_stone(state.board,Point(row+1,col));
    c=get_stone(state.board,Point(row+1,col+1));
    d=get_stone(state.board,Point(row,col-1));
    e=get_stone(state.board,Point(row,col+1));
    f=get_stone(state.board,Point(row-1,col-1));
    g=get_stone(state.board,Point(row-1,col));
    h=get_stone(state.board,Point(row-1,col+1));



    t1=((a!=nothing) && (b!=nothing) && (a!=b) && (b==d)  &&  !((e==b) && (g==nothing))  &&  !((g==b) && (e==nothing)));

    t2=((c!=nothing) && (b!=nothing) && (c!=b) && (b==e)  &&  !((d==b) && (g==nothing))  &&  !((g==b) && (d==nothing)));

    t3=((f!=nothing) && (d!=nothing) && (f!=d) && (d==g)  &&  !((d==b) && (e==nothing))  &&  !((e==d) && (b==nothing)));

    t4=((h!=nothing) && (g!=nothing) && (h!=g) && (e==g)  &&  !((d==g) && (b==nothing))  &&  !((b==g) && (d==nothing)));

    return (t1 || t2 || t3 || t4);

end




function cut2_pattern(state::GameState,point::Point)

    row=point.row;
    col=point.col;

    for p in area(point)
        if (!(is_on_grid(state.board,p)))
            return false;
        end
    end

    a=get_stone(state.board,Point(row+1,col-1));
    b=get_stone(state.board,Point(row+1,col));
    c=get_stone(state.board,Point(row+1,col+1));
    d=get_stone(state.board,Point(row,col-1));
    e=get_stone(state.board,Point(row,col+1));
    f=get_stone(state.board,Point(row-1,col-1));
    g=get_stone(state.board,Point(row-1,col));
    h=get_stone(state.board,Point(row-1,col+1));


    t1=((b!=nothing) && (d!=nothing) && (d==e) && (b!=d) && (f!=d) && (g!=d) && (h!=g));

    t2=((d!=nothing) && (b!=nothing) && (b==g) && (d!=b) && (h!=b) && (e!=b) && (c!=b));

    t3=((g!=nothing) && (d!=nothing) && (d==e) && (g!=d) && (a!=d) && (b!=d) && (c!=g));

    t4=((e!=nothing) && (b!=nothing) && (b==g) && (b!=e) && (a!=b) && (d!=b) && (f!=b));

    return (t1 || t2 || t3 || t4);

end




function boundary_pattern(state::GameState,point::Point)

    row=point.row;
    col=point.col;

    if ( !is_on_grid(state.board,Point(row-1,col-1)) && !is_on_grid(state.board,Point(row-1,col+1)) && is_on_grid(state.board,Point(row,col-1)) && is_on_grid(state.board,Point(row,col+1)) && is_on_grid(state.board,Point(row+1,col)) )

        a=get_stone(state.board,Point(row+1,col-1));
        b=get_stone(state.board,Point(row+1,col));
        c=get_stone(state.board,Point(row+1,col+1));
        d=get_stone(state.board,Point(row,col-1));
        e=get_stone(state.board,Point(row,col+1));


        t1=((a!=nothing) && (d!=nothing) && (a!=d) && (b==nothing));
        t1= t1 || ((c!=nothing) && (e!=nothing) && (c!=e) && (b==nothing));

        t2=((d!=nothing) && (e!=nothing) && (b==d) && (d!=e));
        t2= t2 || ((d!=nothing) && (e!=nothing) && (b==e) && (d!=e));

        t3=((b==state.next_player) && (c!=nothing) && (b!=c));

        t4=((c==state.next_player) && (b!=nothing) && (e==b) && (c!=b));
        t4= t4 || ((a==state.next_player) && (b!=nothing) && (d==b) && (a!=b));


        return (t1 || t2 || t3 || t4);

    end

    if ( !is_on_grid(state.board,Point(row-1,col-1)) && !is_on_grid(state.board,Point(row+1,col-1)) && is_on_grid(state.board,Point(row+1,col)) && is_on_grid(state.board,Point(row-1,col)) && is_on_grid(state.board,Point(row,col+1)) )

        d=get_stone(state.board,Point(row+1,col));
        a=get_stone(state.board,Point(row+1,col+1));
        b=get_stone(state.board,Point(row,col+1));
        e=get_stone(state.board,Point(row-1,col));
        c=get_stone(state.board,Point(row-1,col+1));


        t1=((a!=nothing) && (d!=nothing) && (a!=d) && (b==nothing));
        t1= t1 || ((c!=nothing) && (e!=nothing) && (c!=e) && (b==nothing));

        t2=((d!=nothing) && (e!=nothing) && (b==d) && (d!=e));
        t2= t2 || ((d!=nothing) && (e!=nothing) && (b==e) && (d!=e));

        t3=((b==state.next_player) && (c!=nothing) && (b!=c));

        t4=((c==state.next_player) && (b!=nothing) && (e==b) && (c!=b));
        t4= t4 || ((a==state.next_player) && (b!=nothing) && (d==b) && (a!=b));


        return (t1 || t2 || t3 || t4);

    end

    if ( !is_on_grid(state.board,Point(row+1,col+1)) && !is_on_grid(state.board,Point(row-1,col+1)) && is_on_grid(state.board,Point(row+1,col)) && is_on_grid(state.board,Point(row-1,col)) && is_on_grid(state.board,Point(row,col-1)) )

        c=get_stone(state.board,Point(row+1,col-1));
        e=get_stone(state.board,Point(row+1,col));
        b=get_stone(state.board,Point(row,col-1));
        a=get_stone(state.board,Point(row-1,col-1));
        d=get_stone(state.board,Point(row-1,col));


        t1=((a!=nothing) && (d!=nothing) && (a!=d) && (b==nothing));
        t1= t1 || ((c!=nothing) && (e!=nothing) && (c!=e) && (b==nothing));

        t2=((d!=nothing) && (e!=nothing) && (b==d) && (d!=e));
        t2= t2 || ((d!=nothing) && (e!=nothing) && (b==e) && (d!=e));

        t3=((b==state.next_player) && (c!=nothing) && (b!=c));

        t4=((c==state.next_player) && (b!=nothing) && (e==b) && (c!=b));
        t4= t4 || ((a==state.next_player) && (b!=nothing) && (d==b) && (a!=b));


        return (t1 || t2 || t3 || t4);

    end

    if ( !is_on_grid(state.board,Point(row+1,col-1)) && !is_on_grid(state.board,Point(row+1,col+1)) && is_on_grid(state.board,Point(row,col-1)) && is_on_grid(state.board,Point(row,col+1)) && is_on_grid(state.board,Point(row-1,col)) )

        d=get_stone(state.board,Point(row,col-1));
        e=get_stone(state.board,Point(row,col+1));
        a=get_stone(state.board,Point(row-1,col-1));
        b=get_stone(state.board,Point(row-1,col));
        c=get_stone(state.board,Point(row-1,col+1));


        t1=((a!=nothing) && (d!=nothing) && (a!=d) && (b==nothing));
        t1= t1 || ((c!=nothing) && (e!=nothing) && (c!=e) && (b==nothing));

        t2=((d!=nothing) && (e!=nothing) && (b==d) && (d!=e));
        t2= t2 || ((d!=nothing) && (e!=nothing) && (b==e) && (d!=e));

        t3=((b==state.next_player) && (c!=nothing) && (b!=c));

        t4=((c==state.next_player) && (b!=nothing) && (e==b) && (c!=b));
        t4= t4 || ((a==state.next_player) && (b!=nothing) && (d==b) && (a!=b));


        return (t1 || t2 || t3 || t4);

    end

    return false;
end

















end
