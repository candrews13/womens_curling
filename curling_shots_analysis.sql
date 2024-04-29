--- Curling Data Analysis
--- focused on Shots table analysis


select *
from shots
--limit 5;
-- 469,067 shots

select distinct team
from shots;
-- 248 different team names

select distinct athlete_cleaned as athlete
from shots;
-- 922 names

-- couting the number of shots for each rock in each end
select end_shot, count(end_shot) as rocks_thrown
from shots
group by end_shot;
/* each team throws 8 rocks so as expected there is a count of 1-16.
the count should be roughly the same across all shots, though a decline for later shots
is not unexpected as in the last end of the game the losing team may acknowledge defeat
and end the game early */


-- counting number of shots for each team
select team, count(*) as num_shots_taken
from shots
group by team;



--- Adding Columns to the shots table for player positions and who has hammer
alter table shots
add column position varchar(10),
add column has_hammer boolean;

update shots
set position = case -- identifying player's position on a team based on which rocks they're throwing in the end
                    when end_shot between 1 and 4 then 'lead'
                    when end_shot between 5 and 8 then 'second'
                    when end_shot between 9 and 12 then 'vice'
                    when end_shot between 13 and 16 then 'skip'
                    else null 
                end;

update shots
set has_hammer = case -- team with even end_shot numbers would have hammer (last rock)
                    when end_shot % 2 = 0 then true
                    else false 
                end;


-- examining shot types
select task, count(task)
from shots
group by task
order by task;
/* Front & Guard, and Promotion & Raise are two different task names for very similar shots
whether further analysis of shots would require adjusting these task names depends on the level of granularity wanted for shot type.
Simplified, the 3 main categires of shot types are guards, draws, and take-outs. */

select task as shot_type, 
	   count(task)
from shots
group by task
order by 2 desc;
-- draws and take-outs come in as the two most popular shot types by a wide margin


-- how frequently are shots made accurately as called?
/* A score of 0-4 is assigned to each shot
0 = complete miss
4 = shot made as called
1-3 = partially made
*/
select points, count(points)
from shots
group by points;

select points, 
       count(points) as occurance,
       round((count(points) * 100.0 / (select count(*) from shots)), 2) as percentage
from shots
group by points;
-- a majority of shots are made accurately, which is not unexpected given the dataset of largely national and international competitions
-- where you would expect these players to be able to make their shots


-- are some shot tasks done more accurately than others?
select task,
       points,
       count(points) as count,
       round((count(points) * 100.0 / sum(count(points)) over (partition by task)), 1) as percentage_by_task
from shots
group by task, points
order by task;
/* some observations:
the more difficult takeout shot of a double scores a 4 only about 42% of the time, vs a general take-outs' 66%.
54% of draws were given a 4, 64% of guards, and 80% of front shots.
*/


-- finding average shot accuracy for each team in a game
select ga.game_id, s.team, avg(s.points) as avg_shot_accuracy
from games as ga
join shots s on ga.event_id = s.event_id and ga.game_id = s.game_id
group by ga.event_id, ga.game_id, s.team
order by ga.game_id



-- looking at the average shot accuracy for each team in each game
with shotsaggregated as
	(select s.event_id,
			s.game_id,
			s.team as team_name,
			avg(s.points) as avg_points
	 from shots s
	 group by s.event_id,
			s.game_id,
			s.team
	)
select g.event_id,
	g.game_id,
	g.team1_score as team1_finalscore,
	g.team2_score as team2_finalscore,
	g.team1 as team1_name,
	g.team2 as team2_name,
	sa1.avg_points as team1_avg_points,
	sa2.avg_points as team2_avg_points
from games g
left join shotsaggregated sa1 
	on g.event_id = sa1.event_id and g.game_id = sa1.game_id and g.team1 = sa1.team_name
left join shotsaggregated sa2 
	on g.event_id = sa2.event_id and g.game_id = sa2.game_id and g.team2 = sa2.team_name
order by g.event_id, g.game_id;



-- looking at shot accuracy per event, not per game
select ga.event_id, s.team, count(s.event_id) as num_shots_taken, avg(s.points) as avg_shot_accuracy
from games as ga
join shots s on ga.event_id = s.event_id and ga.game_id = s.game_id
group by ga.event_id, s.team
order by ga.event_id;

select ev.year, ga.event_id, s.team, count(s.event_id) as num_shots_taken, avg(s.points) as avg_shot_accuracy
from games as ga
join shots s on ga.event_id = s.event_id and ga.game_id = s.game_id
join events as ev on ev.event_id = ga.event_id
group by ev.year, ga.event_id, s.team
order by ev.year, ga.event_id



-- average accuracy of individual players
select shots.position,
		athlete_cleaned as athlete,
		count(points) as shots_taken,
		round(avg(points), 3) as avg_shot_accuracy
from shots
group by athlete, shots.position
having count(points) > 0
order by 4 desc;

-- amending the above to re-order by position, and remove athletes with less than 16 shots (equivalent to 1 game or less)
select shots.position,
		athlete_cleaned as athlete,
		count(points) as shots_taken,
		round(avg(points), 3) as avg_shot_accuracy
from shots
group by athlete, shots.position
having count(points) > 16
order by shots.position, avg(points) desc, athlete;


-- what is the average shot points for each team position?
select shots.position,
	   count(*) as shots_taken,
	   round(avg(points), 3) as avg_shot_accuracy
from shots
group by shots.position
-- leads have the highest overall shot points average (3.3), with second and vice all but tied next (3.1), and skip last (2.9)


-- are there types of shots that athletes playing certain positions are better at than others?
select 
    shots.position,
    task,
    count(*) as total_shots,
    round(avg(points), 3) as avg_shot_accuracy
from shots
group by shots.position, task
order by task, avg(points) desc;



-- how does athlete performance vary across shot type?
select athlete_cleaned as athlete,
		task,
		count(points) as shots_taken,
		round(avg(points), 3) as avg_shot_accuracy
from shots
--where athlete_cleaned ilike '%jones%'
group by athlete, task
order by athlete, avg(points) desc;


