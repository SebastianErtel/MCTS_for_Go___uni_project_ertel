    module SLOW_GOBOARD

export Move, play, pass_turn, resign, GoString, remove_liberty, add_liberty, merged_with, num_liberties, __eq__, Board, is_on_grid, get_go_string, get_stone, place_stone, GameState, apply_move, start_new_game, is_over, is_move_self_capture, situation, does_move_violate_ko, is_valid_move, legal_moves, get_winner


#include("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo\\gotypes.jl")
using GOTYPES
#@everywhere begin

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
    for other_color_string in adjacent_opposite_color
        remove_liberty(other_color_string,point);
    end

    for other_color_string in adjacent_opposite_color
        if (num_liberties(other_color_string)==0)
            _remove_string(board,other_color_string);
        end
    end

end

#################################################################################
#                              Game State Class
#################################################################################

struct GameState
    board::Board;
    next_player::Player;
    previous_state; #previous GameState
    last_move;
end

function apply_move(state::GameState,player::Player,move::Move)

    @assert (player.color==state.next_player.color) ["Argument player is not the next player!\n player: $(player.color) != next player: $(state.next_player.color)"];
    #if(player.color!=state.next_player.color)
    #        ArgumentError("Argument player is not the next player!\n player: $(player.color) != next player: $(state.next_player.color)");
    #end

    if(move.is_play)
        next_board=deepcopy(state.board);
        place_stone(next_board,player,move.point);
    else
        next_board=state.board;
    end
    return GameState(next_board,Player(other(player)),state,move);
end

#class method

function start_new_game(board_size)
    board=Board(board_size,board_size,Dict([]));
    return GameState(board,Player("black"),nothing,nothing);
end


function is_over(state::GameState)
    if (state.last_move==nothing)
        return false;
    end

    if(state.last_move.is_resign)
        return true;
    end

    if(state.previous_state==nothing)
        return false;
    end
    second_last_move=state.previous_state.last_move;

    if(second_last_move==nothing)
        return false;
    end

    return (state.last_move.is_pass && second_last_move.is_pass);
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
    return [state.next_player,state.board];
end

function does_move_violate_ko(state::GameState,player::Player,move::Move)

    if(!(move.is_play))
        return false;
    end

    next_board=deepcopy(state.board);
    place_stone(next_board,player,move.point);
    next_situation=[Player(other(player)),next_board];

    past_state=state.previous_state;
    t=true;

    while (past_state!=nothing)

        t=true;
        for row in 1:past_state.board.num_rows
            for col in 1:past_state.board.num_cols
                if(get_stone(past_state.board,Point(row,col))!=get_stone(next_board,Point(row,col)))
                    t=false;
                end
            end
        end

        if((past_state.next_player==Player(other(player))) && t)
            return true;
        end
        past_state=past_state.previous_state;
    end

    return false;
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
#end
################################################################################
#                                  Testing area
################################################################################


#gg=GameState(Board(9,9,Dict([])),Player("white"),nothing,Move(Point(1,1),true,false,false));

#println(is_valid_move(gg,Move(Point(1,1),true,false,false)))

#display(legal_moves(gg))



#println(gg.board==bb);
#println(gg.board==bb2);

#gg2=apply_move(gg,Player("white"),Move(Point(1,1),true,false,false));

#does_move_violate_ko(gg2,Player("black"),Move(Point(2,2),true,false,false));

end
