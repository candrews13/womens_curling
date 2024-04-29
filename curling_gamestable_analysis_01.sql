-- Games Table Analysis

-- a quick count of the rows
-- checking the total count of game_id
select count(game_id)
from games;
-- 3269 rows

-- comparing the count of game_id to the number of distinct values
-- if the same then no duplicates
select count(distinct game_id)
from games;
-- 3250 unique game IDs

-- listing the game_id that have more than 1 game associated with it
select game_id, count(game_id)
from games
group by game_id
having count(game_id) = 2
order by 1;
-- 19 duplicate game_id
/*
As noted during my inital data cleaning in Excel these duplicate game_id have different event_id.
So event_id + game_id becomes a unique identifier
*/

-- using concatenate function to double-check for duplicate games
select event_game_key, 
	   count(event_game_key)
from ( -- subquery with new unique identifier column
	select concat(event_id, '-', game_id) as event_game_key,
		event_id, 
		game_id
	from games
	)
group by event_game_key
order by 2 desc;
-- non have a count greater than 1

-- Checking how many games are part of each event
select event_id, 
	   count(game_id)
from games
group by event_id
order by 2 desc;
--- the biggest event has 97 games associated with it, the smallest 1

-- for the previous query lets join on the events table to see what the event names are
select g.event_id, ev.year, ev.event_name, count(g.game_id) as total_event_games
from games as g
join events as ev
on g.event_id = ev.event_id
group by g.event_id, ev.year, ev.event_name
order by count(g.game_id) desc;
-- the events with the most games are the Scotties and World Championships

/*
Add a new column "winner" to the "games" table, 
identifying the winning team for each game.
*/
ALTER TABLE games 
ADD COLUMN winner VARCHAR(255);

-- Update the win_loss column based on team1_score and team2_score comparison
UPDATE games
SET winner = CASE WHEN team1_score > team2_score THEN team1
                  WHEN team1_score < team2_score THEN team2
                  ELSE 'Tie' -- Handle tie scenarios if they come up
             END;


-- counting the number of wins for each team
select team_name, 
	   count(*) as num_of_wins
from (  -- subquery with unionall combines the wins as team1 with the wins as team2
	select team1 as team_name from games where team1_score > team2_score
	union all
	select team2 as team_name from games where team2_score > team1_score
) as wins_per_team
group by team_name
order by num_of_wins desc;
-- Sweden, Switzerland, and Canada make up the top 3; individual Canadian teams Homan and Einarson round out the top 5
-- note this dataset is somewhat biased to Canadian teams though, given some events are just for Canadian teams


-- query to calculate total games played by each team
select team, 
	   count(*) as total_games
from (
	select team1 as team from games
    union all
    select team2 as team from games
    ) as all_teams
group by team
order by team;

-- pulling the win count and total games played queries together and calculataing a win percentage
select team_name, 
	   count(*) as num_of_wins,
	   total_games_played.total_games as num_of_games_played,
	   round((count(*) * 100 / total_games_played.total_games), 2) as win_percentage
from ( -- subquery counting wins as team1 plus winds as team2
	select team1 as team_name from games where team1_score > team2_score
	union all
	select team2 as team_name from games where team2_score > team1_score
	) as wins_per_team
join ( -- subquery to calculate total games played by each team
		select team, count(*) as total_games
		from (
			select team1 as team from games
			union all
			select team2 as team from games
			) as all_teams
		group by team
	) as total_games_played
	on wins_per_team.team_name = total_games_played.team
where total_games_played.total_games > 1 -- to eliminate from the ranking team_name that only have 1 game associated to it
group by team_name, num_of_games_played
order by win_percentage desc, num_of_wins desc;
-- Einarson, when playing as Team Canada, has an 89% win rate



-- Analyzing the Score Columns
-- finding the munimum and maximun points scored in a game
select max(team1_score), max(team2_score), min(team1_score), min(team2_score)
from games;

-- who has scored 20+ points in a game?
select *
from games
where team1_score >= 20 or team2_score >= 20;
-- Japan beat Australia 20-0; China beat Qatar 25-0


-- what is the average points scored in a game for the team1 and team2 columns
select round(avg(team1_score), 4) as avg_score_team1,
		round(avg(team2_score), 4) as avg_score_team2
from games;

-- calculate average points scored by each team
select team, 
	   count(*) as total_games_played, 
	   round(avg(points_scored), 1) as avg_points_scored
from ( -- subquery for points scored by each team in a game
	select team1 as team,
			team1_score as points_scored
	from games
	union all
	select team2 as team,
			team2_score as points_scored
	from games
	) as team_list
group by team
order by avg_points_scored desc;


-- what are the minimum points scored by a team that still resulted in a win?
select team_name,
    min(points_scored) as min_points_scored
from ( -- subquery for points scored by each team in a game won
	select team1 as team_name,
			team1_score as points_scored
	from games
	where team1_score > team2_score
	union all
	select team2 as team_name,
			team2_score as points_scored
	from games
	where team2_score > team1_score
	) as winning_points_per_team
group by team_name
order by min_points_scored
limit 10;

-- adding in who the opponent was and opponent score to the above query
select team_name,
    min(points_scored) as min_points_scored,
	opponent_name,
    opponent_score
from ( -- subquery for points scored by each team in a game won
	select team1 as team_name,
			team1_score as points_scored,
			team2 AS opponent_name,
        	team2_score AS opponent_score
	from games
	where team1_score > team2_score
	union all
	select team2 as team_name,
			team2_score as points_scored,
			team1 AS opponent_name,
        	team1_score AS opponent_score
	from games
	where team2_score > team1_score
	) as winning_points_per_team
group by team_name, opponent_name, opponent_score
order by min_points_scored;


-- what game has the largest score difference?
select g.game_id, ev.event_name, ev.year,
    g.team1 as team1_name,
    g.team1_score,
    g.team2 as team2_name,
    g.team2_score,
    abs(team1_score - team2_score) as score_difference -- using the ABS() function to get an absolute value
from games as g
join events as ev
on g.event_id = ev.event_id
order by score_difference desc
limit 1;
-- 2018 Pacific Asia Championships Qatar loses to China 25-0


-- how many games were won by one point?
select g.game_id, ev.event_name, ev.year,
    g.team1 AS team1_name,
    g.team1_score,
    g.team2 AS team2_name,
    g.team2_score,
    abs(team1_score - team2_score) as score_difference -- using the ABS() function to get an absolute value
from games as g
join events as ev
on g.event_id = ev.event_id
where abs(team1_score - team2_score) = 1
-- 767 games had a since point difference between the winner and loser
-- a count of the above rather than a list:
select count(*)
from (
	select g.game_id, ev.event_name, ev.year,
		g.team1 AS team1_name,
		g.team1_score,
		g.team2 AS team2_name,
		g.team2_score,
		abs(team1_score - team2_score) as score_difference -- using the ABS() function to get an absolute value
	from games as g
	join events as ev
	on g.event_id = ev.event_id
)
where score_difference = 1;



-- what score differences was most frequent?
select abs(team1_score - team2_score) as score_difference, -- using the ABS() function to get an absolute value
	   count(*) as num_of_games
from games
group by score_difference
order by num_of_games desc
-- the larger the point differential, the less frequent it occurs


-- what is the avg number of points scored in a game over the years?
select ev.year,
    round(avg(g.team1_score + g.team2_score), 2) as avg_points_scored,
    count(g.game_id) as num_games
from events as ev
join games as g 
on ev.event_id = g.event_id
group by ev.year
order by ev.year;
-- between 2010-2023 (the years with about 50 or more games) the combined average number of points scored 
-- from both teams is consistently about 12-13


-- counting instances of final scores across games (ex. 4-3, 2-6, etc)
select 
    concat(team1_score, '-', team2_score) as final_score, -- concatenate the two team final scores
    count(*) as frequency
from games
group by final_score
order by final_score;
-- iterating on the above so that ex 1-4 and 4-1 are counted as the same final score
select 
    concat(
        least(team1_score, team2_score), '-', 
        greatest(team1_score, team2_score)
    ) as final_score,
    count(*) as frequency
from games
group by final_score
order by frequency desc;
-- top 3 most frequent: 5-6, 6-7, 5-7
