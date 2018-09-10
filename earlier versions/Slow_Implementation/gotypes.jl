

module GOTYPES

export Player, other, Point, neighbors, area
#@everywhere begin


#################################################################################
#                           Player Class
#################################################################################



struct Player
    color;
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


end
