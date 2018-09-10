module AGENT



export RandomBot,RandomBot_with_coded_patterns,select_move, StandardMCTSBot, simulate_game, RootParallelMCTSBot, LeafParallelMCTSBot
#include("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo\\gotypes.jl")

#include("C:\\Users\\sebas\\AppData\\Local\\JuliaPro-0.6.2.2\\dlgo\\goboard_slow.jl")
using GOBOARD
#using SLOW_GOBOARD


#@everywhere begin


################################################################################
#                               Random Bot
################################################################################

struct RandomBot
    is_random_bot::Bool;
end

function select_move(bot::RandomBot,state::GameState)

    @assert (bot.is_random_bot) ["\n bot.is_random_bot=$(bot.is_random_bot)\n"]
    candidates=[];

    for r in 1:state.board.num_rows
        for c in 1:state.board.num_cols
            candidate=Point(r,c);

            if(is_valid_move(state,play(candidate)) && !(is_point_an_eye(state.board,candidate,state.next_player.color)))
                push!(candidates,candidate);
            end
        end
    end

    n=length(candidates);
    if(n<1)
        return pass_turn()
    else
        return play(candidates[rand(1:n)]);
    end

end



#####################################################################################################################################
#                             Enhanced Random Bot
#####################################################################################################################################

struct RandomBot_with_coded_patterns
    is_random_bot_with_coded_patterns::Bool;
end

function select_move(bot::RandomBot_with_coded_patterns,state::GameState)

    @assert (bot.is_random_bot_with_coded_patterns) ["\n bot.is_random_bot_with_coded_patterns=$(bot.is_random_bot)\n"]


    candidates=save_from_atari(state);
    n=length(candidates);

    if(n>0)
        return play(candidates[rand(1:n)]);
    end



    candidates=[];

    if (state.last_move!=nothing && state.last_move.point!=nothing)
        for possible_move in area(state.last_move.point)
            if (is_on_grid(state.board,possible_move) && is_valid_move(state,Move(possible_move,true,false,false))
                 && is_atari_move(state,possible_move))

                if (hane_pattern(state,possible_move) || cut1_pattern(state,possible_move) || cut2_pattern(state,possible_move) || boundary_pattern(state,possible_move))
                    push!(candidates,possible_move)
                end

            end
        end
    end

    n=length(candidates);

    if(n>0)
        return play(candidates[rand(1:n)]);
    end


    candidates=possible_captures(state,state.next_player);
    n=length(candidates);

    if(n>0)
        return play(candidates[rand(1:n)]);
    end

    candidates=[];

    for r in 1:state.board.num_rows
        for c in 1:state.board.num_cols
            candidate=Point(r,c);

            if(is_valid_move(state,play(candidate)) && !(is_point_an_eye(state.board,candidate,state.next_player.color)))
                push!(candidates,candidate);
            end
        end
    end

    n=length(candidates);
    if(n<1)
        return pass_turn()
    else
        return play(candidates[rand(1:n)]);
    end

end



#################################################################################################################################
#                               MCTS Node
#################################################################################################################################

struct MCTSNode
    game_state::GameState; #current state of the game
    parent; #Type: MCTSNode or nothing
    move; #the last move that led to the current state, Type: Move or nothing

    num_rollouts::Array{Int64,1}; #No. of rollouts, stored in array to achieve mutability
    win_counts::Dict{String,Int64}; # Dict with the No. of wins in rollouts of both players


    children; #Type: array of MCTSNode
    unvisited_moves; #array of Moves to points that werent considered yet
end


function __init__MCTSNODE(game_state::GameState,parent=nothing,move=nothing)
    return MCTSNode(game_state,parent,move,[0],Dict(["black"=>0,"white"=>0]),[],legal_moves(game_state));
end


function number_of_rollouts(node::MCTSNode)
    return node.num_rollouts[1];
end


function set_num_rollouts(node::MCTSNode,x::Int64)
    node.num_rollouts[1]=x;
end


function  add_random_child(self::MCTSNode)
# chooses a random node from all possible nodes and adds it to the current MCTS tree

    n=length(self.unvisited_moves)

    @assert(n>0,"no more nodes of the MCTS tree left!")

    new_move=splice!(self.unvisited_moves,rand(1:n));

    #new_game_state=deepcopy(self.game_state)

    new_game_state=apply_move(self.game_state,self.game_state.next_player,new_move);


    new_node=__init__MCTSNODE(new_game_state,self,new_move);


    push!(self.children,new_node);

    return new_node;
end

function record_win(self::MCTSNode,winner::Player)
    #println("record win")

    self.win_counts[winner.color]+=1

    set_num_rollouts(self,number_of_rollouts(self)+1);
end

function can_add_child(self::MCTSNode)
    return (length(self.unvisited_moves)>0);
end

function is_terminal(self::MCTSNode)
    return is_over(self.game_state);
end

function winning_pct(self::MCTSNode,player::Player)
    return self.win_counts[player.color]/number_of_rollouts(self);
end




#################################################################################################################################
#                               Standard MCTS Bot
#################################################################################################################################

struct StandardMCTSBot
    is_standardMCTS_bot::Bool;
    num_rounds;
    temperature;
    simulation_bot;
end


function simulate_game(game_state::GameState,simulation_bot)
    #println("simulate random game");

    while(!is_over(game_state))

        player=game_state.next_player;

        bot_move=select_move(simulation_bot,game_state);

        game_state=apply_move(game_state,player,bot_move);
            #print_board(game_state.board);
    end

    winner=get_winner(game_state);

    return Player(winner[1]);
end

function uct_score(parent_rollouts,child_rollouts,win_pct,temperature)
    #println("uct score");

    exploration=sqrt(log(parent_rollouts)/child_rollouts);
    exploitation=win_pct;

    return exploitation+temperature*exploration;
end

function select_child(bot::StandardMCTSBot,node::MCTSNode)

    best_score=-1;
    best_child=nothing;

    if(length(node.children)>0)

        total_rollouts=sum([number_of_rollouts(child) for child in node.children]);

        for child in node.children
            score=uct_score(total_rollouts,number_of_rollouts(child) ,winning_pct(child,node.game_state.next_player),bot.temperature);

            if(score>best_score)
                best_score=score;
                best_child=child;
            end
        end
    end

    return best_child;
end



function select_move(bot::StandardMCTSBot,game_state::GameState)
    #println("select move -> StandardMCTSBot")

    @assert (bot.is_standardMCTS_bot) ["\n bot.is_standardMCTS_bot=$(bot.is_standardMCTS_bot)\n"]

    root=__init__MCTSNODE(game_state);

    for i in 1:bot.num_rounds

        node=root;

        while(!(can_add_child(node)) && !(is_terminal(node)))

            node=select_child(bot,node);
            if(node==nothing)
                return [Move(Point(-1,-1),false,true,false),-2]
            end

        end

        if(can_add_child(node))
            node=add_random_child(node);
        end

        winner=simulate_game(node.game_state,bot.simulation_bot);

        while(node!=nothing)
            record_win(node,winner);
            node=node.parent;
        end

    end

    best_move=nothing;
    best_pct=-1;

    for child in root.children

        child_pct=winning_pct(child,game_state.next_player);

        if child_pct>best_pct
            best_pct=child_pct;
            best_move=child.move;
        end

    end

    best_array=[best_move, best_pct]
    return best_array;
end


    function select_move_Bootstrap(Uebergabe)
        #println("select move -> StandardMCTSBot")
        bot=Uebergabe[1];
        game_state=Uebergabe[2];

        @assert (bot.is_standardMCTS_bot) ["\n bot.is_standardMCTS_bot=$(bot.is_standardMCTS_bot)\n"]

        root=__init__MCTSNODE(game_state);

        for i in 1:bot.num_rounds


            node=root;


            while(!(can_add_child(node)) && !(is_terminal(node)))

                node=select_child(bot,node);
                if(node==nothing)
                    return [Move(Point(-1,-1),false,true,false),-2]
                end

            end

            if(can_add_child(node))
                node=add_random_child(node);
            end

            winner=simulate_game(node.game_state,bot.simulation_bot);

            while(node!=nothing)
                record_win(node,winner);
                node=node.parent;
            end

        end

        best_move=nothing;
        best_pct=-1;

        for child in root.children

            child_pct=winning_pct(child,game_state.next_player);

            if child_pct>best_pct
                best_pct=child_pct;
                best_move=child.move;
            end

        end

        return [best_move, best_pct];
    end

#end #end of @everywhere



#################################################################################################################################
#                               Root Parallel MCTS Bot
#################################################################################################################################

struct RootParallelMCTSBot
    is_RootParallelMCTS_bot::Bool;
    num_rounds::Int;
    temperature;
    simulation_bot;
end

function select_move(bot::RootParallelMCTSBot,game_state::GameState)
    #println("select move -> StandardMCTSBot")

    @assert (bot.is_RootParallelMCTS_bot) ["\n bot.is_RootParallelMCTS_bot=$(bot.is_RootParallelMCTS_bot)\n"]

    num_threads=5;

    bootstrap_bot=StandardMCTSBot(true,ceil(bot.num_rounds/num_threads),bot.temperature,bot.simulation_bot);

    best_array=pmap(select_move_Bootstrap,[[bootstrap_bot,game_state] for i in 1:num_threads]);

    best_move=best_array[1][1];
    best_pct=best_array[1][2];

    for j in 2:num_threads
        if best_pct<best_array[j][2]
            best_move=best_array[j][1];
            best_pct=best_array[j][2];
        end

    end

    return [best_move, best_pct];
end




#################################################################################################################################
#                               Leaf Parallel MCTS Bot
#################################################################################################################################

struct LeafParallelMCTSBot
    is_LeafParallelMCTS_bot::Bool;
    num_rounds::Int;
    temperature;
    simulation_bot;
end



function select_child(bot::LeafParallelMCTSBot,node::MCTSNode)

    best_score=-1;
    best_child=nothing;

    if(length(node.children)>0)

        total_rollouts=sum([number_of_rollouts(child)  for child in node.children]);

        for child in node.children
            score=uct_score(total_rollouts,number_of_rollouts(child) ,winning_pct(child,node.game_state.next_player),bot.temperature);

            if(score>best_score)
                best_score=score;
                best_child=child;
            end
        end
    end

    return best_child;
end

function select_move(bot::LeafParallelMCTSBot,game_state::GameState)
    #println("select move -> StandardMCTSBot")

    @assert (bot.is_LeafParallelMCTS_bot) ["\n bot.is_LeafParallelMCTS_bot=$(bot.is_LeafParallelMCTS_bot)\n"]

    root=__init__MCTSNODE(game_state);

    for i in 1:bot.num_rounds


        node=root;


        while(!(can_add_child(node)) && !(is_terminal(node)))

            node=select_child(bot,node);
            if(node==nothing)
                return [Move(Point(-1,-1),false,true,false),-2]
            end

        end

        if(can_add_child(node))
            node=add_random_child(node);
        end

        winner1=@spawn simulate_game(node.game_state,bot.simulation_bot);
        winner2=@spawn simulate_game(node.game_state,bot.simulation_bot);
        winner3=@spawn simulate_game(node.game_state,bot.simulation_bot);
        winner4=@spawn simulate_game(node.game_state,bot.simulation_bot);

        while(node!=nothing)
            record_win(node,fetch(winner1));
            record_win(node,fetch(winner2));
            record_win(node,fetch(winner3));
            record_win(node,fetch(winner4));
            node=node.parent;
        end

    end

    best_move=nothing;
    best_pct=-1;

    for child in root.children

        child_pct=winning_pct(child,game_state.next_player);

        if child_pct>best_pct
            best_pct=child_pct;
            best_move=child.move;
        end

    end

    return [best_move, best_pct];
end



################################################################################
#                              Testing Area
################################################################################




#gg=start_new_game(3)
#gg=apply_move(gg,Player("black"),Move(Point(1,1),true,false,false))
#gg=apply_move(gg,Player("white"),Move(Point(2,1),true,false,false))
#gg=apply_move(gg,Player("black"),Move(Point(3,1),true,false,false))
#gg=apply_move(gg,Player("white"),Move(Point(2,2),true,false,false))
#gg=apply_move(gg,Player("black"),Move(Point(1,2),true,false,false))
#print_board(gg.board)
#display(possible_captures(gg,Player("white")))
#display(possible_captures(gg,Player("black")))

end
