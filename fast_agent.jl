



module FAST_AGENT


# normal export
#export RandomBot,RandomBot_with_coded_patterns, simulate_game, select_move, StandardMCTSBot, EconomicMCTSBot, VirtualMCTSBot, RootParallelMCTSBot, LeafParallelMCTSBot,MCTSBot,Bot, create_HeuristicMCRaveBot_random_sims, HeuristicMCRaveBot


#export for testing
export RandomBot,RandomBot_with_coded_patterns,select_move, MCTSNode, __init__MCTSNODE, number_of_rollouts, set_num_rollouts, add_random_child, record_win, can_add_child, is_terminal, winning_pct, simulate_game, StandardMCTSBot, EconomicMCTSBot, VirtualMCTSBot, add_random_child!, RootParallelMCTSBot, LeafParallelMCTSBot, MCTSBot, Bot, create_HeuristicMCRaveBot_random_sims, HeuristicMCRaveBot

#include("./fast_goboard.jl")
using FAST_GOBOARD






################################################################################
#                               Random Bot
################################################################################

struct RandomBot
    is_random_bot::Bool;
end

function select_move(bot::RandomBot,state::GameState)

    @assert (bot.is_random_bot) ["\n bot.is_random_bot=$(bot.is_random_bot)\n"]
    candidates=Tuple{Int64,Int64}[];

    for r in 1:state.board.num_rows
        for c in 1:state.board.num_cols
            candidate=point(r,c);

            if (is_valid_move(state,play(candidate)) && !(is_point_an_eye(state.board,candidate,next_player(state))))
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



    candidates=Tuple{Int64,Int64}[];

    if !startofgame(state) && last_move(state).is_play
        for possible_move in area(last_move(state).point)
            if (is_on_grid(state.board,possible_move) && is_valid_move(state,play(possible_move))
                 && !is_atari_move(state,possible_move) && !is_point_an_eye(state.board,possible_move,next_player(state)))

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


    candidates=possible_captures(state,next_player(state));
    n=length(candidates);

    if(n>0)
        return play(candidates[rand(1:n)]);
    end

    candidates=Tuple{Int64,Int64}[];

    for r in 1:state.board.num_rows
        for c in 1:state.board.num_cols
            candidate=point(r,c);

            if(is_valid_move(state,play(candidate)) && !(is_point_an_eye(state.board,candidate,next_player(state))))
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
    parent::Union{MCTSNode,Void}; # parent node in the MCTS tree. Type: MCTSNode or nothing
    move::Move; #the last move that led to the current state, Type: Move or nothing

    num_rollouts::Array{Int64,1}; #No. of rollouts, stored in array to achieve mutability
    win_counts::Dict{Symbol,Int64}; # Dict with the No. of wins in rollouts of both players


    children::Array{MCTSNode,1}; # children nodes in the MCTS tree. Type: array of MCTSNode
    unvisited_moves::Array{Move,1}; #array of Moves to points that werent considered yet
end



function __init__MCTSNODE(game_state::GameState,parent=nothing,move=Move((-100,-100),true,false,false))
    return MCTSNode(game_state,parent,move,[0],Dict([:black=>0,:white=>0]),MCTSNode[],legal_moves(game_state));
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

    new_game_state=apply_move(self.game_state,next_player(self.game_state),new_move);


    new_node=__init__MCTSNODE(new_game_state,self,new_move);


    push!(self.children,new_node);

    return new_node;
end




function record_win(self::MCTSNode,winner::Symbol,no_of_wins=1)
    #println("record win")

    self.win_counts[winner]+=no_of_wins;

    set_num_rollouts(self,number_of_rollouts(self)+no_of_wins);
end



function can_add_child(self::MCTSNode)
    return (length(self.unvisited_moves)>0);
end



function is_terminal(self::MCTSNode)
    return is_over(self.game_state);
end


function winning_pct(self::MCTSNode,player::Symbol)
    return self.win_counts[player]/number_of_rollouts(self);
end



#################################################################################################################################
#                               reflex bot Type
#################################################################################################################################



ReflexBot=Union{RandomBot,RandomBot_with_coded_patterns}



function simulate_game(game_state::GameState,simulation_bot::ReflexBot)
    #println("simulate random game");

    while (!is_over(game_state))

        player=next_player(game_state);

        bot_move=select_move(simulation_bot,game_state);

        apply_move!(game_state,player,bot_move);
            #print_board(game_state.board);
    end

    winner=get_winner(game_state);

    return winner[1];
end



function playout_with_move_array(game_state::GameState,simulation_bot::ReflexBot)

    moves=Move[];

    while (!is_over(game_state))

        player=next_player(game_state);

        bot_move=select_move(simulation_bot,game_state);

        apply_move!(game_state,player,bot_move);
            #print_board(game_state.board);
        push!(moves,bot_move);
    end

    winner=get_winner(game_state);

    return (winner[1],moves);
end



#################################################################################################################################
#                               Standard MCTS Bot
#################################################################################################################################

struct StandardMCTSBot
    is_standardMCTS_bot::Bool;
    num_rounds::Int64;
    temperature::Float64;
    simulation_bot::ReflexBot;
    resignation_boundary::Float64;
end



function uct_score(parent_rollouts::Int64,child_rollouts::Int64,win_pct::Float64,temperature::Float64)
    #println("uct score");

    exploration=sqrt(log(parent_rollouts)/child_rollouts);
    exploitation=win_pct;

    return exploitation+temperature*exploration;
end



function select_child(bot::StandardMCTSBot,node::MCTSNode)

    n=length(node.children);

    if (n>0)
        best_child=node.children[1];
        total_rollouts=sum([number_of_rollouts(child) for child in node.children]);
        best_score=uct_score(total_rollouts,number_of_rollouts(best_child) ,winning_pct(best_child,next_player(node.game_state)),bot.temperature)

        for j=2:n
            score=uct_score(total_rollouts,number_of_rollouts(node.children[j]) ,winning_pct(node.children[j],next_player(node.game_state)),bot.temperature);

            if(score>best_score)
                best_score=score;
                best_child=node.children[j];
            end
        end

        return best_child;
    else
        #return nothing;
        return node;
    end
end



function select_move(bot::StandardMCTSBot,game_state::GameState)
    #println("select move -> StandardMCTSBot")

    @assert (bot.is_standardMCTS_bot) ["\n bot.is_standardMCTS_bot=$(bot.is_standardMCTS_bot)\n"]

    root=__init__MCTSNODE(game_state);

    if length(legal_moves(game_state))==0
        return [Move((-1,-1),false,true,false), -2];

    elseif ( last_move(game_state).is_pass && area_scoring(game_state)==next_player(game_state))
        return [Move((-1,-1),false,true,false), -2];

    else
        for i in 1:bot.num_rounds

            node=root;

            while (!can_add_child(node) && !is_terminal(node))

                if length(node.children)<=0
                    break;
                end

                node=select_child(bot,node);
                #if node==nothing
                #    return [Move((-1,-1),false,true,false),-2]
                #end
            end

            if can_add_child(node)
                node=add_random_child(node);
            end

            winner=simulate_game(deepcopy(node.game_state),bot.simulation_bot);

            while (node!=nothing)
                record_win(node,winner);
                node=node.parent;
            end
        end

        best_move=root.children[1];
        best_pct=-1;

        for child in root.children

            child_pct=winning_pct(child,next_player(game_state));

            if child_pct>best_pct
                best_pct=child_pct;
                best_move=child.move;
            end

        end

        if best_pct<bot.resignation_boundary
            best_move=Move((-1,-1),false,false,true);
        end

        return [best_move, best_pct];
    end
end



function rate_moves(bot::StandardMCTSBot,game_state::GameState)
    #println("select move -> StandardMCTSBot")

    @assert (bot.is_standardMCTS_bot) ["\n bot.is_standardMCTS_bot=$(bot.is_standardMCTS_bot)\n"]

    root=__init__MCTSNODE(game_state);

    for i in 1:bot.num_rounds

        node=root;

        while (!can_add_child(node) && !is_terminal(node))

            if length(node.children)<=0
                break;
            end

            node=select_child(bot,node);

        end

        if can_add_child(node)
            node=add_random_child(node);
        end

        winner=simulate_game(deepcopy(node.game_state),bot.simulation_bot);

        while (node!=nothing)
            record_win(node,winner);
            node=node.parent;
        end

    end

    rated_moves=[ (child.move,winning_pct(child,next_player(game_state)))  for child in root.children]

    return rated_moves;
end



#################################################################################################################################
#                                             spare MCTS Node
#################################################################################################################################

struct spareMCTSNode
    parent::Union{spareMCTSNode,Void}; # parent node in the MCTS tree.
    move::Move; #the last move that led to the current state

    num_rollouts::Array{Int64,1}; #No. of rollouts, stored in array to achieve mutability
    win_counts::Dict{Symbol,Int64}; # Dict with the No. of wins in rollouts of both players


    children::Array{spareMCTSNode,1}; # children nodes in the MCTS tree. Type: array of MCTSNode
    unvisited_moves::Array{Move,1}; #array of Moves to points that werent considered yet
end



function __init__spareMCTSNODE(game_state,parent=nothing,move=Move((-100,-100),true,false,false))
    return spareMCTSNode(parent,move,[0],Dict([:black=>0,:white=>0]),spareMCTSNode[],legal_moves(game_state));
end



function number_of_rollouts(node::spareMCTSNode)
    return node.num_rollouts[1];
end


function set_num_rollouts(node::spareMCTSNode,x::Int64)
    node.num_rollouts[1]=x;
end



function  add_random_child!(game_state::GameState,node::spareMCTSNode)
# chooses a random node from all possible nodes and adds it to the current MCTS tree
#
# Attention, it changes the game_state by doing so

    n=length(node.unvisited_moves)

    @assert(n>0,"no more nodes of the MCTS tree left!")

    new_move=splice!(node.unvisited_moves,rand(1:n));

    apply_move!(game_state,next_player(game_state),new_move);

    new_node=__init__spareMCTSNODE(game_state,node,new_move);


    push!(node.children,new_node);

    return new_node;
end



function record_win(self::spareMCTSNode,winner::Symbol,no_of_wins=1)
    #println("record win")

    self.win_counts[winner]+=no_of_wins;

    set_num_rollouts(self,number_of_rollouts(self)+no_of_wins);
end



function can_add_child(self::spareMCTSNode)
    return (length(self.unvisited_moves)>0);
end


function winning_pct(self::spareMCTSNode,player::Symbol)
    return self.win_counts[player]/number_of_rollouts(self);
end


#################################################################################################################################
#                               Economical MCTS Bot
#################################################################################################################################

struct EconomicMCTSBot
    is_EconomicMCTSBot_bot::Bool;
    num_rounds::Int64;
    temperature::Float64;
    simulation_bot::ReflexBot;
    resignation_boundary::Float64;
end



function select_child(bot::EconomicMCTSBot,node::spareMCTSNode,player::Symbol)

    n=length(node.children);

    if (n>0)
        best_child=node.children[1];
        total_rollouts=sum([number_of_rollouts(child) for child in node.children]);
        best_score=uct_score(total_rollouts,number_of_rollouts(best_child) ,winning_pct(best_child,player),bot.temperature)

        for j=2:n
            score=uct_score(total_rollouts,number_of_rollouts(node.children[j]) ,winning_pct(node.children[j],player),bot.temperature);

            if score>best_score
                best_score=score;
                best_child=node.children[j];

            end
        end

        return best_child;
    else
        #return nothing;
        return node;
    end
end



function select_move(bot::EconomicMCTSBot,game_state::GameState)
    #println("select move -> is_EconomicMCTSBot_bot")

    @assert (bot.is_EconomicMCTSBot_bot) ["\n bot.is_EconomicMCTSBot_bot=$(bot.is_EconomicMCTSBot_bot)\n"]

    root=__init__spareMCTSNODE(game_state);

    if length(legal_moves(game_state))==0
        return [Move((-1,-1),false,true,false),-2];

    elseif ( last_move(game_state).is_pass && area_scoring(game_state)==next_player(game_state))
        return [Move((-1,-1),false,true,false),-2];

    else
        for i in 1:bot.num_rounds

            node=root;
            state=deepcopy(game_state);

            while (!can_add_child(node) && !is_over(state))

                if length(node.children)<=0
                    break;
                end

                node=select_child(bot,node,next_player(state));

                apply_move!(state,next_player(state),node.move);
            end

            if can_add_child(node)
                node=add_random_child!(state,node);
            end

            winner=simulate_game(state,bot.simulation_bot);

            while (node!=nothing)
                record_win(node,winner);
                node=node.parent;
            end
        end

        best_move=root.children[1];
        best_pct=-1;

        for child in root.children

            child_pct=winning_pct(child,next_player(game_state));

            if child_pct>best_pct
                best_pct=child_pct;
                best_move=child.move;
            end

        end

        if best_pct<bot.resignation_boundary
            best_move=Move((-1,-1),false,false,true);
        end

        return [best_move, best_pct];

    end
end



function rate_moves(bot::EconomicMCTSBot,game_state::GameState)
    #println("select move -> EconomicMCTSBot")

    @assert (bot.is_EconomicMCTSBot_bot) ["\n bot.is_EconomicMCTSBot_bot=$(bot.is_EconomicMCTSBot_bot)\n"]

    root=__init__spareMCTSNODE(game_state);

    for i in 1:bot.num_rounds

        node=root;
        state=deepcopy(game_state);

        while (!can_add_child(node) && !is_over(state))

            if length(node.children)<=0
                break;
            end

            node=select_child(bot,node,next_player(state));
            apply_move!(state,next_player(state),node.move);
        end

        if can_add_child(node)
            node=add_random_child!(state,node);
        end

        winner=simulate_game(state,bot.simulation_bot);

        while (node!=nothing)
            record_win(node,winner);
            node=node.parent;
        end
    end

    rated_moves=[ (child.move,winning_pct(child,next_player(game_state)))  for child in root.children]

    return rated_moves;
end





#################################################################################################################################
#                               Virtual MCTS Bot
#################################################################################################################################


struct VirtualMCTSBot
    is_VirtualMCTSBot_bot::Bool;
    num_rounds::Int64;
    temperature::Float64;
    simulation_bot::ReflexBot;
    resignation_boundary::Float64;
end


struct VirtualMCTS_NodeData
    num_rollouts::Int64;
    num_wins::Int64;
end

function increment(data::VirtualMCTS_NodeData,added_rollouts::Int64,added_wins::Int64)
    return VirtualMCTS_NodeData(data.num_rollouts+added_rollouts,data.num_wins+added_wins);
end


function select_move(bot::VirtualMCTSBot,game_state::GameState)
    #println("select move -> is_EconomicMCTSBot_bot")

    @assert (bot.is_VirtualMCTSBot_bot) ["\n bot.is_VirtualMCTSBot_bot=$(bot.is_VirtualMCTSBot_bot)\n"]

    if length(legal_moves(game_state))==0
        return [Move((-1,-1),false,true,false),-2];

    elseif ( last_move(game_state).is_pass && area_scoring(game_state)==next_player(game_state))
        return [Move((-1,-1),false,true,false),-2];

    else

        #tree_data=Dict{Tuple{Symbol,UInt64,Move},VirtualMCTS_NodeData}();
        tree_data=Dict([(next_player(game_state),hash(game_state.board),move)=>VirtualMCTS_NodeData(0,0) for move in legal_moves(game_state)]);
        tree=Dict([(next_player(game_state),hash(game_state.board))=>0]);

        for j in 1:bot.num_rounds

            state=deepcopy(game_state);
            visited_states=Tuple{Symbol,UInt64}[];
            visited_moves=Move[];

            while !is_over(state) #traversing the tree

                if !in((next_player(state),hash(state.board)),keys(tree)) #adding a child

                    push!(tree,(next_player(state),hash(state.board))=>0);

                    for move in legal_moves(state)
                        push!(tree_data,(next_player(state),hash(state.board),move)=>VirtualMCTS_NodeData(0,0));
                    end

                    break;
                end

                push!(visited_states,(next_player(state),hash(state.board)))

                ################################################################
                #           selecting a child
                ################################################################

                selected_move=Move((-1,-1),false,true,false);

                possible_children=legal_moves(state);
                unvisited_moves=Move[];

                for move in possible_children

                    if tree_data[next_player(state),hash(state.board),move].num_rollouts==0
                        push!(unvisited_moves,move);
                    end

                end

                no_unvisited_moves=length(unvisited_moves);

                if no_unvisited_moves>0
                    selected_move=unvisited_moves[rand(1:no_unvisited_moves)];
                    #push!(visited_moves,selected_move);
                    #apply_move!(state,next_player(state),selected_move);
                    #break;

                else
                    if next_player(state)==next_player(game_state)

                        best_score=-2;

                        for move in possible_children

                            move_data=tree_data[next_player(state),hash(state.board),move];
                            move_score=(move_data.num_wins/move_data.num_rollouts)+bot.temperature*sqrt(log(tree[next_player(state),hash(state.board)])/move_data.num_rollouts);

                            if best_score<move_score
                                selected_move=move;
                                best_score=move_score;
                            end

                        end


                    else
                        best_score=2;

                        for move in possible_children

                            move_data=tree_data[next_player(state),hash(state.board),move];
                            move_score=(move_data.num_wins/move_data.num_rollouts)-bot.temperature*sqrt(log(tree[next_player(state),hash(state.board)])/move_data.num_rollouts);

                            if best_score>move_score
                                selected_move=move;
                                best_score=move_score;
                            end
                        end

                    end
                end
                ################################################################


                push!(visited_moves,selected_move);
                apply_move!(state,next_player(state),selected_move);

            end


            # Playout
            winner=simulate_game(state,bot.simulation_bot);


            for k=1:length(visited_states)

                s=visited_states[k];
                move=visited_moves[k];
                z=0;
                if winner==s[1]
                    z=1;
                end
                tree[s]+=1;
                tree_data[s[1],s[2],move]=increment(tree_data[s[1],s[2],move],1,z);
            end
            #println(j)
        end




        best_move=Move((-1,-1),false,false,true);
        best_pct=bot.resignation_boundary;

        for move in legal_moves(game_state)

            move_data=tree_data[next_player(game_state),hash(game_state.board),move];
            move_pct=(move_data.num_wins/move_data.num_rollouts);

            if move_pct>best_pct
                best_pct=move_pct;
                best_move=move;
            end

        end



        return [best_move, best_pct];

    end
end


#################################################################################################################################
#                               Root Parallel MCTS Bot
#################################################################################################################################

struct RootParallelMCTSBot
    is_RootParallelMCTS_bot::Bool;
    num_rounds::Int64;
    temperature::Float64;
    simulation_bot::ReflexBot;
    num_workers::Int64;
    resignation_boundary::Float64;
end



function select_move(bot::RootParallelMCTSBot,game_state::GameState)
    #println("select move -> StandardMCTSBot")

    @assert (bot.is_RootParallelMCTS_bot) ["\n bot.is_RootParallelMCTS_bot=$(bot.is_RootParallelMCTS_bot)\n"]


    bootstrap_bot=EconomicMCTSBot(true,cld(bot.num_rounds,bot.num_workers),bot.temperature,bot.simulation_bot,bot.resignation_boundary);

    rated_moves=pmap(rate_moves,[bootstrap_bot for j in 1:bot.num_workers],[deepcopy(game_state) for j in 1:bot.num_workers]);

    Moves=Dict(rated_moves[1]);

    for j in 2:bot.num_workers
        for move in rated_moves[j]
            if haskey(Moves,move[1])
                Moves[move[1]]+=move[2];
            else
                push!(Moves,move[1]=>move[2]);
            end
        end
    end

    best_move=Move((-1,-1),false,true,false);
    best_pct=-2;

    for move in Moves
        if move[2]>best_pct
            best_move=move[1];
            best_pct=move[2];
        end
    end

    if best_pct<bot.resignation_boundary
        best_move=Move((-1,-1),false,false,true);
    end

    return [best_move, best_pct/bot.num_workers];
end


#################################################################################################################################
#                               Leaf Parallel MCTS Bot
#################################################################################################################################


struct LeafParallelMCTSBot
    is_LeafParallelMCTS_bot::Bool;
    num_rounds::Int64;
    temperature::Float64;
    simulation_bot::ReflexBot;
    num_workers::Int64;
    resignation_boundary::Float64;
end



function select_child(bot::LeafParallelMCTSBot,node::spareMCTSNode,player::Symbol)

    n=length(node.children);

    if (n>0)
        best_child=node.children[1];
        total_rollouts=sum([number_of_rollouts(child) for child in node.children]);
        best_score=uct_score(total_rollouts,number_of_rollouts(best_child) ,winning_pct(best_child,player),bot.temperature)

        for j=2:n
            score=uct_score(total_rollouts,number_of_rollouts(node.children[j]) ,winning_pct(node.children[j],player),bot.temperature);

            if score>best_score
                best_score=score;
                best_child=node.children[j];

            end
        end

        return best_child;
    else
        #return nothing;
        return node;
    end
end




function select_move(bot::LeafParallelMCTSBot,game_state::GameState)
    #println("select move -> StandardMCTSBot")

    @assert (bot.is_LeafParallelMCTS_bot) ["\n bot.is_LeafParallelMCTS_bot=$(bot.is_LeafParallelMCTS_bot)\n"]

    root=__init__spareMCTSNODE(game_state);

    if length(legal_moves(game_state))==0
        return [Move((-1,-1),false,true,false),-2];

    elseif ( last_move(game_state).is_pass && area_scoring(game_state)==next_player(game_state))
        return [Move((-1,-1),false,true,false),-2];

    else
        for i in 1:bot.num_rounds

            node=root;
            state=deepcopy(game_state);

            while (!can_add_child(node) && !is_over(state))

                if length(node.children)<=0
                    break;
                end

                node=select_child(bot,node,next_player(state));

                apply_move!(state,next_player(state),node.move);
            end

            if can_add_child(node)
                node=add_random_child!(state,node);
            end

            winners=pmap(simulate_game,[deepcopy(state) for j in 1:bot.num_workers],[bot.simulation_bot for j in 1:bot.num_workers]);

            wins_black=0;
            wins_white=0;

            for j in 1:bot.num_workers
                if winners[j]==:black
                    wins_black+=1;
                else
                    wins_white+=1;
                end
            end


            while (node!=nothing)

                record_win(node,:black,wins_black);
                record_win(node,:white,wins_white);

                node=node.parent;
            end
        end

        best_move=root.children[1];
        best_pct=-1;

        for child in root.children

            child_pct=winning_pct(child,next_player(game_state));

            if child_pct>best_pct
                best_pct=child_pct;
                best_move=child.move;
            end

        end

        if best_pct<bot.resignation_boundary
            best_move=Move((-1,-1),false,false,true);
        end

        return [best_move, best_pct];

    end

end





#################################################################################################################################
#                                       Heuristic functions
#################################################################################################################################


function even_game_heuristic(state::GameState,move::Move)
    return 0.5;
end


#################################################################################################################################
#                                       MC Rave
#################################################################################################################################

struct HeuristicMCRaveBot
    is_HeuristicMCRaveNode_bot::Bool;
    num_rounds::Int64;
    temperature::Float64;
    simulation_bot::ReflexBot;
    resignation_boundary::Float64;

    heuristic::Symbol;
    heuristic_confidence::Union{Symbol,Int64};
    RAVE_bias::Float64;
end


function create_HeuristicMCRaveBot_random_sims(num_rounds::Int64,temperature::Float64,resignation_boundary::Float64,heuristic::Symbol,heuristic_confidence::Union{Symbol,Int64})
    return HeuristicMCRaveBot(true,num_rounds,temperature,RandomBot(true),resignation_boundary,heuristic,heuristic_confidence,1);
end

struct HeuristicMCRave_NodeData
    num_rollouts::Int64;
    winning_pct::Float64;
end

struct HeuristicMCRave_AMAFData
    num_rollouts::Int64;
    AMAF::Float64;
end


function increment(data::HeuristicMCRave_NodeData,added_rollouts::Int64,added_wins::Int64)
    return HeuristicMCRave_NodeData(data.num_rollouts+added_rollouts,(data.winning_pct*data.num_rollouts+added_wins)/(data.num_rollouts+added_rollouts));
end

function increment(data::HeuristicMCRave_AMAFData,added_rollouts::Int64,added_wins::Int64)
    return HeuristicMCRave_AMAFData(data.num_rollouts+added_rollouts,(data.AMAF*data.num_rollouts+added_wins)/(data.num_rollouts+added_rollouts));
end


function select_move_even_game_constant_confidence(bot::HeuristicMCRaveBot,game_state::GameState)
    #println("select move -> is_EconomicMCTSBot_bot")

    @assert (bot.is_HeuristicMCRaveNode_bot) ["\n bot.is_HeuristicMCRaveNode_bot=$(bot.is_HeuristicMCRaveNode_bot)\n"]

    if length(legal_moves(game_state))==0
        return [Move((-1,-1),false,true,false),-2];

    elseif ( last_move(game_state).is_pass && area_scoring(game_state)==next_player(game_state))
        return [Move((-1,-1),false,true,false),-2];

    else

        #tree_data=Dict{Tuple{Symbol,UInt64,Move},HeuristicMCRave_NodeData}();
        tree_data=Dict([(next_player(game_state),hash(game_state.board),move)=>HeuristicMCRave_NodeData(bot.heuristic_confidence,0.5) for move in legal_moves(game_state)]);
        AMAF_data=Dict([(next_player(game_state),hash(game_state.board),move)=>HeuristicMCRave_AMAFData(bot.heuristic_confidence,0.5) for move in legal_moves(game_state)]);
        push!(tree_data,(next_player(game_state),hash(game_state.board),Move((-1,-1),false,true,false))=>HeuristicMCRave_NodeData(bot.heuristic_confidence,0.5));
        push!(AMAF_data,(next_player(game_state),hash(game_state.board),Move((-1,-1),false,true,false))=>HeuristicMCRave_AMAFData(bot.heuristic_confidence,0.5));


        tree=Dict([(next_player(game_state),hash(game_state.board))=>bot.heuristic_confidence*length(tree_data)]);

        for j in 1:bot.num_rounds

            state=deepcopy(game_state);
            visited_states=Tuple{Symbol,UInt64}[];
            visited_moves=Move[];

            while !is_over(state) #traversing the tree

                if !in((next_player(state),hash(state.board)),keys(tree)) #adding a child

                    possible_moves=legal_moves(state);
                    push!(possible_moves,Move((-1,-1),false,true,false));

                    push!(tree,(next_player(state),hash(state.board))=>bot.heuristic_confidence*length(possible_moves));

                    for move in possible_moves
                        push!(tree_data,(next_player(state),hash(state.board),move)=>HeuristicMCRave_NodeData(bot.heuristic_confidence,0.5));
                        push!(AMAF_data,(next_player(state),hash(state.board),move)=>HeuristicMCRave_AMAFData(bot.heuristic_confidence,0.5));
                    end

                    push!(visited_states,(next_player(state),hash(state.board)));

                    move=select_move(bot.simulation_bot,state);
                    push!(visited_moves,move);
                    apply_move!(state,next_player(state),move);

                    break;
                end



                ################################################################
                #           selecting a child
                ################################################################

                selected_move=Move((-1,-1),false,true,false);

                possible_children=legal_moves(state);
                unvisited_moves=Move[];


                if next_player(state)==next_player(game_state)
                    best_score=-2;

                    for move in possible_children

                        move_data=tree_data[next_player(state),hash(state.board),move];
                        move_AMAF=AMAF_data[next_player(state),hash(state.board),move];

                        b=move_AMAF.num_rollouts/(move_AMAF.num_rollouts+move_data.num_rollouts+4*bot.RAVE_bias^2*move_AMAF.num_rollouts*move_data.num_rollouts);

                        move_score=(1-b)*move_data.winning_pct+b*move_AMAF.AMAF+bot.temperature*sqrt(log(tree[next_player(state),hash(state.board)])/move_data.num_rollouts);

                        if best_score<move_score
                            selected_move=move;
                            best_score=move_score;
                        end

                    end

                else
                    best_score=2;

                    for move in possible_children

                        move_data=tree_data[next_player(state),hash(state.board),move];
                        move_AMAF=AMAF_data[next_player(state),hash(state.board),move];

                        b=move_AMAF.num_rollouts/(move_AMAF.num_rollouts+move_data.num_rollouts+4*bot.RAVE_bias^2*move_AMAF.num_rollouts*move_data.num_rollouts);

                        move_score=(1-b)*move_data.winning_pct+b*move_AMAF.AMAF-bot.temperature*sqrt(log(tree[next_player(state),hash(state.board)])/move_data.num_rollouts);

                        if best_score>move_score
                            selected_move=move;
                            best_score=move_score;
                        end
                    end

                end

                ################################################################

                push!(visited_states,(next_player(state),hash(state.board)));
                push!(visited_moves,selected_move);
                apply_move!(state,next_player(state),selected_move);

            end


            # Playout
            winner,moves_in_playout=playout_with_move_array(state,bot.simulation_bot);

            append!(visited_moves,moves_in_playout);


            for k=1:length(visited_states)

                s=visited_states[k];
                move=visited_moves[k];
                z=0;
                if winner==s[1]
                    z=1;
                end
                tree[s]+=1;
                tree_data[s[1],s[2],move]=increment(tree_data[s[1],s[2],move],1,z);

                for l=k:2:length(visited_moves)
                    if (l>2 && !in(visited_moves[l],visited_moves[k:2:l-2]) && haskey(AMAF_data,(s[1],s[2],visited_moves[l])))
                        AMAF_data[s[1],s[2],visited_moves[l]]=increment(AMAF_data[s[1],s[2],visited_moves[l]],1,z);
                    end
                    ###############################
                end

            end
            #println(j)
        end




        best_move=Move((-1,-1),false,true,false);

        move_data=tree_data[next_player(game_state),hash(game_state.board),best_move];
        move_AMAF=AMAF_data[next_player(game_state),hash(game_state.board),best_move];

        b=move_AMAF.num_rollouts/(move_AMAF.num_rollouts+move_data.num_rollouts+4*bot.RAVE_bias^2*move_AMAF.num_rollouts*move_data.num_rollouts);

        move_pct=(1-b)*move_data.winning_pct+b*move_AMAF.AMAF

        best_pct=move_pct;

        for move in legal_moves(game_state)

            move_data=tree_data[next_player(game_state),hash(game_state.board),move];
            move_AMAF=AMAF_data[next_player(game_state),hash(game_state.board),move];

            b=move_AMAF.num_rollouts/(move_AMAF.num_rollouts+move_data.num_rollouts+4*bot.RAVE_bias^2*move_AMAF.num_rollouts*move_data.num_rollouts);

            move_pct=(1-b)*move_data.winning_pct+b*move_AMAF.AMAF

            if move_pct>best_pct
                best_pct=move_pct;
                best_move=move;
            end

        end
        if (best_pct<bot.resignation_boundary)
            best_move=Move((-1,-1),false,false,true);
        end



        return [best_move, best_pct];

    end
end

function select_move(bot::HeuristicMCRaveBot,game_state::GameState)

    if (bot.heuristic==:EvenGame && isa(bot.heuristic_confidence,Int64))
        return select_move_even_game_constant_confidence(bot,game_state);
    end

    error("no matching heuristics");
end




############################################################################################################################
#                                   Bot Class
###########################################################################################################################




MCTSBot=Union{StandardMCTSBot,EconomicMCTSBot,VirtualMCTSBot,RootParallelMCTSBot,LeafParallelMCTSBot,HeuristicMCRaveBot};
Bot=Union{RandomBot,RandomBot_with_coded_patterns,StandardMCTSBot,EconomicMCTSBot,VirtualMCTSBot,RootParallelMCTSBot,LeafParallelMCTSBot,HeuristicMCRaveBot};



function simulate_game(game_state::GameState,simulation_bot1::Bot,simulation_bot2::Bot)
    #println("simulate random game");

    j=-1;
    while (!is_over(game_state))

        j=-j;
        player=next_player(game_state);

        if j>0
            bot_move=select_move(simulation_bot1,game_state);

            if isa(simulation_bot1,RandomBot) || isa(simulation_bot1,RandomBot_with_coded_patterns)
                apply_move!(game_state,player,bot_move);
            else
                apply_move!(game_state,player,bot_move[1]);
            end

        else
            bot_move=select_move(simulation_bot2,game_state);

            if isa(simulation_bot2,RandomBot) || isa(simulation_bot2,RandomBot_with_coded_patterns)
                apply_move!(game_state,player,bot_move);
            else
                apply_move!(game_state,player,bot_move[1]);
            end
        end
            #print_board(game_state.board);
    end

    winner=area_scoring(game_state);

    return winner[1];
end














end
