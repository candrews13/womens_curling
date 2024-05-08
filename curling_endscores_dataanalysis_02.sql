--- Curling Data Analysis
-- focusing on endscores table

-- counting frequency of when an end is blanked vs when either team scores points
select endscores.end,
    case
        when score = 0 and opp_score = 0 then 'blanked'
        else 'points scored'
    end as end_result,
    count(*) as frequency
from endscores
group by endscores.end, end_result
order by endscores.end, end_result;

-- add in a percentage column to the above
select endscores.end,
    case
        when score = 0 and opp_score = 0 then 'blanked'
        else 'points scored'
    end as end_result,
    count(*) as frequency,
	round(count(*) * 100.0 / sum(count(*)) over (partition by endscores.end), 2) as percentage_by_end
from endscores
group by endscores.end, end_result
order by endscores.end, end_result;


-- iteration on the above to separate 'points scored' into how many points scored
select 
    endscores.end,
    case
        when score = 0 and opp_score = 0 then 'blanked'
        else concat('points scored (', score, ')')
    end as end_result,
    count(*) as frequency
from endscores
group by endscores.end, 
    case
        when score = 0 and opp_score = 0 then 'blanked'
        else concat('points scored (', score, ')')
    end
order by endscores.end, end_result;
	
	
-- for each team, what is the number of times they blank an end, score, or their opponent scores
select team,
    endscores.end,
    case
        when score = 0 and opp_score = 0 then 'blanked'
        when score = 0 and opp_score > 0 then 'opp scored'
		when score > 0 and opp_score = 0 then 'team scored'
		else 'unknown'
    end as end_result,
    count(*) as frequency,
	round(count(*) * 100.0 / sum(count(*)) over (partition by team, endscores.end), 2) as percentage_by_end
from endscores
group by team, endscores.end, 
	case
        when score = 0 and opp_score = 0 then 'blanked'
        when score = 0 and opp_score > 0 then 'opp scored'
		when score > 0 and opp_score = 0 then 'team scored'
		else 'unknown'
    end
order by team, endscores.end, 
	case
        when score = 0 and opp_score = 0 then 'blanked'
        when score = 0 and opp_score > 0 then 'opp scored'
		when score > 0 and opp_score = 0 then 'team scored'
		else 'unknown'
    end
	

-- Team Analytics
-- points scored for and against by each team
-- average points scored for and against in an event
select 
    ga.event_id,
    case 
        when es.team = ga.team1 then ga.team1
        when es.team = ga.team2 then ga.team2
    end as team_name,
    avg(es.total) as avg_points_scored,
    avg(es.opp_total) as avg_points_scored_against,
    avg(es.total - es.opp_total) as point_differential
from games as ga
join endscores as es on ga.event_id = es.event_id and ga.game_id = es.game_id
group by ga.event_id, team_name
order by ga.event_id;


-- which teams score the most points on average in a game?
select 
    team_name,
    avg(points_scored) as avg_points_scored_per_game,
	count(*) as games_played
from ( --subquery to list team names in a single column with their game score
    select 
        case 
            when es.team = ga.team1 then ga.team1_score
            when es.team = ga.team2 then ga.team2_score
        end as points_scored,
        case 
            when es.team = ga.team1 then ga.team1
            when es.team = ga.team2 then ga.team2
        end as team_name
    from games as ga
    join endscores as es 
		on ga.event_id = es.event_id and ga.game_id = es.game_id
    group by ga.event_id, ga.game_id, team_name, points_scored
	) as subquery
group by team_name
order by avg_points_scored_per_game desc;


-- looking at scoring (per end) with and without hammer (hammer possession from shots table)
select 
    e.team,
    avg(case when s.has_hammer then e.score else null end) as avg_score_with_hammer,
    avg(case when not s.has_hammer then e.score else null end) as avg_score_without_hammer
from endscores as e
join shots as s 
	 on e.game_id = s.game_id and e.end = s.end and e.team = s.team
group by e.team;
	

---- Team Statistics
---- analyzing ends with hammer
-- calculating Hammer Efficiency for each team
select 
    team,
    count(*) as total_hammer_ends,
    sum(case when score >= 2 then 1 else 0 end) as ends_scoring_2_or_more,
    (sum(case when score >= 2 then 1 else 0 end) * 100.0 / count(*)) as hammer_efficiency
from (
	select es.team, es.game_id, es.end, es.score, es.opp_score, sh.has_hammer
	from endscores as es
	join shots as sh
		on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
	group by es.team, es.game_id, es.end, sh.has_hammer, es.score, es.opp_score
)
where has_hammer = true and (es.score > 0 or es.opp_score > 0) -- ends where team had hammer and the end didn't blank
group by team
order by team;
	
-- calculating Steal Defense
select 
    es.team,
    count(*) as total_hammer_ends,
    sum(case when es.opp_score > 0 then 1 else 0 end) as ends_stolen_against,
    (sum(case when es.opp_score > 0 then 1 else 0 end) * 100.0 / count(*)) as steal_defense
from endscores as es
join shots as sh 
	on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
where sh.has_hammer = true
group by es.team
order by es.team;
-- lower is better for this one

-- now lets combine the two and calculate Hammer Factor
with hammerefficiency as (
		select 
			es.team,
			count(*) as total_hammer_ends,
			sum(case when es.score >= 2 then 1 else 0 end) as ends_scoring_2_or_more,
			(sum(case when es.score >= 2 then 1 else 0 end) * 100.0 / count(*)) as hammer_efficiency
		from 
			endscores as es
		join shots as sh 
			on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
		where sh.has_hammer = true and (es.score > 0 or es.opp_score > 0) -- ends where team had hammer and the end didn't blank
		group by es.team
		order by es.team
),
	stealdefense as(
		select 
			es.team,
			count(*) as total_hammer_ends,
			sum(case when es.opp_score > 0 then 1 else 0 end) as ends_stolen_against,
			(sum(case when es.opp_score > 0 then 1 else 0 end) * 100.0 / count(*)) as steal_defense
		from endscores as es
		join shots sh 
			on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
		where sh.has_hammer = true
		group by es.team
		order by es.team
)
select he.team, he.hammer_efficiency, sd.steal_defense,
		(he.hammer_efficiency - sd.steal_defense) as hammer_factor
from hammerefficiency as he
join stealdefense as sd
	on he.team = sd.team
order by hammer_factor desc
;


---- analyzing ends without hammer
-- calculating Force Efficiency (limiting your opponent's scoring)
    select 
        es.team,
        count(*) filter (where not sh.has_hammer and es.opp_score > 0) as total_ends_without_hammer_opponent_scores,
        sum(case when es.opp_score = 1 and not sh.has_hammer then 1 else 0 end) as ends_opponent_scored_1,
        (sum(case when es.opp_score = 1 and not sh.has_hammer then 1 else 0 end) * 100.0 / count(*) filter (where not sh.has_hammer and es.opp_score > 0)) as force_efficiency
    from endscores as es
    join shots as sh 
		on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
    where not sh.has_hammer
    group by es.team
		

-- calculating Steal Efficiency
-- the percentage of ends a	team steals	one	or more points.	
select es.team,
    round(sum(case when es.score > 0 then 1.0 else 0 end) / count(*), 4) as steal_efficiency
from endscores as es
join shots as sh 
	on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
where not sh.has_hammer
group by es.team
order by es.team;


-- putting hammer and without hammer stats together into one table
with hammerefficiency as (
    select 
        es.team,
        count(*) as total_hammer_ends,
        sum(case when es.score >= 2 then 1.0 else 0 end) as ends_scoring_2_or_more,
        round((sum(case when es.score >= 2 then 1.0 else 0 end) / count(*)), 4) as hammer_efficiency
    from endscores as es
    join shots as sh 
        on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
    where sh.has_hammer = true and (es.score > 0 or es.opp_score > 0)
    group by es.team
),
stealdefense as (
    select 
        es.team,
        count(*) as total_hammer_ends,
        sum(case when es.opp_score > 0 then 1.0 else 0 end) as ends_stolen_against,
        round((sum(case when es.opp_score > 0 then 1.0 else 0 end) / count(*)), 4) as steal_defense
    from endscores as es
    join shots as sh 
        on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
    where sh.has_hammer = true
    group by es.team
),
forceefficiency as (
    select 
        es.team,
        count(*) filter (where not sh.has_hammer and es.opp_score > 0) as total_ends_without_hammer_opponent_scores,
        sum(case when es.opp_score = 1 and not sh.has_hammer then 1.0 else 0 end) as ends_opponent_scored_1,
        case 
            when count(*) filter (where not sh.has_hammer and es.opp_score > 0) = 0 then null 
            else (sum(case when es.opp_score = 1 and not sh.has_hammer then 1.0 else 0 end) / count(*) filter (where not sh.has_hammer and es.opp_score > 0)) 
        end as force_efficiency
    from endscores as es
    join shots as sh 
        on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
    where not sh.has_hammer
    group by es.team
),
stealefficiency as (
    select 
        es.team,
        round(sum(case when es.score > 0 then 1.0 else 0 end) / count(*), 4) as steal_efficiency
    from endscores as es
    join shots as sh 
        on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
    where not sh.has_hammer
    group by es.team
)
select 
    he.team,
    he.hammer_efficiency,
    sd.steal_defense,
    (he.hammer_efficiency - sd.steal_defense) as hammer_factor,
    fe.force_efficiency,
    se.steal_efficiency
from hammerefficiency as he
join stealdefense as sd on he.team = sd.team
join forceefficiency as fe on he.team = fe.team
join stealefficiency as se on he.team = se.team
	
	
-- adding in year as a factor
with hammerefficiency as (
    select 
        es.team,
		ev.year,
        count(*) as total_hammer_ends,
        sum(case when es.score >= 2 then 1.0 else 0 end) as ends_scoring_2_or_more,
        round((sum(case when es.score >= 2 then 1.0 else 0 end) / count(*)), 4) as hammer_efficiency
    from endscores as es
    join shots as sh 
        on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
	join events as ev
		on es.event_id = ev.event_id
    where sh.has_hammer = true and (es.score > 0 or es.opp_score > 0)
    group by es.team
),
stealdefense as (
    select 
        es.team,
		ev.year,
        count(*) as total_hammer_ends,
        sum(case when es.opp_score > 0 then 1.0 else 0 end) as ends_stolen_against,
        round((sum(case when es.opp_score > 0 then 1.0 else 0 end) / count(*)), 4) as steal_defense
    from endscores as es
    join shots as sh 
        on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
	join events as ev
		on es.event_id = ev.event_id
    where sh.has_hammer = true
    group by es.team, ev.year
),
forceefficiency as (
    select 
        es.team,
        ev.year,
        count(*) filter (where not sh.has_hammer and es.opp_score > 0) as total_ends_without_hammer_opponent_scores,
        sum(case when es.opp_score = 1 and not sh.has_hammer then 1 else 0 end) as ends_opponent_scored_1,
        case 
            when count(*) filter (where not sh.has_hammer and es.opp_score > 0) = 0 then null 
            else (sum(case when es.opp_score = 1 and not sh.has_hammer then 1 else 0 end) * 100.0 / count(*) filter (where not sh.has_hammer and es.opp_score > 0)) 
        end as force_efficiency
    from endscores as es
    join shots as sh 
        on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
    join events as ev 
        on es.event_id = ev.event_id
    where not sh.has_hammer
    group by es.team, ev.year
),
stealefficiency as (
    select 
        es.team,
        ev.year,
        round(sum(case when es.score > 0 then 1.0 else 0 end) / count(*), 4) as steal_efficiency
    from endscores as es
    join shots as sh 
        on es.game_id = sh.game_id and es.end = sh.end and es.team = sh.team
    join events as ev 
        on es.event_id = ev.event_id
    where not sh.has_hammer
    group by es.team, ev.year
)
select 
    he.team,
    he.year,
    he.hammer_efficiency,
    sd.steal_defense,
    (he.hammer_efficiency - sd.steal_defense) as hammer_factor,
    fe.force_efficiency,
    se.steal_efficiency
from hammerefficiency as he
join stealdefense as sd 
	on he.team = sd.team and he.year = sd.year
join forceefficiency as fe 
	on he.team = fe.team and he.year = fe.year
join stealefficiency as se 
	on he.team = se.team and he.year = se.year
order by he.year, he.team;