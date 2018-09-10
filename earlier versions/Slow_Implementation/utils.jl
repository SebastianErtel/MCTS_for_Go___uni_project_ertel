
module UTILS

export print_move,print_board,print_board_graphical

#include("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo\\goboard_slow.jl")
using GOBOARD

#using SLOW_GOBOARD


using Plots

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


end
