

using GOBOARD
using UTILS
using GOTYPES
using Plots


board=create_board(19,19)
place_stone(board,Player("white"),Point(3,3));
place_stone(board,Player("black"),Point(3,2));
place_stone(board,Player("white"),Point(2,6));
place_stone(board,Player("black"),Point(13,19));
place_stone(board,Player("white"),Point(19,16));


function print_board_graph(board::Board)

    white_x=[];
    white_y=[];
    black_x=[];
    black_y=[];


    for row in 1:board.num_rows

        for col in 1:board.num_cols
            stone=get_stone(board,Point(row,col));

                if(stone=="black")
                    push!(black_x,row);
                    push!(black_y,col);
                end

                if(stone=="white")
                    push!(white_x,row);
                    push!(white_y,col);
                end
        end
    end

    #plot(white_x,black_x)

    scatter(white_x,white_y,legend=false,color="white",markersize=10,background_color_inside="grey",background_color_outside="grey");
    scatter!(black_x,black_y,legend=false,color="black",markersize=10);


end
