

#MAX63=0x7fffffffffffffff;



MAX63=0x7fffffffffffffff;



function generate_rand_position_code_table(num_rows::Int,num_cols::Int)
    table=Dict([])
    empty_board=0;



    for row in 1:num_rows
        for col in 1:num_cols
            for color in ["black","white"]
                code=rand(1:MAX63);


                push!(table,(row,col,color)=>code);
            end
        end
    end

    push!(table,empty_board=>empty_board);

    return table;
end

table=generate_rand_position_code_table(19,19)
