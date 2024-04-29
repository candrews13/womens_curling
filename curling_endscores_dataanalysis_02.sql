--- Curling Data Analysis
-- focusing on endscores table

select *
from endscores
limit 5;


-- counting frequency of when an end is blanked vs when either team scores points
select endscores.end,
    case
        when score = 0 and opp_score = 0 then 'Blanked'
        else 'Points Scored'
    end as end_result,
    count(*) as frequency
from endscores
group by endscores.end, end_result
order by endscores.end, end_result;

-- add in a percentage column to the above
select endscores.end,
    case
        when score = 0 and opp_score = 0 then 'Blanked'
        else 'Points Scored'
    end as end_result,
    count(*) as frequency,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY endscores.end), 2) AS percentage_by_end
from endscores
group by endscores.end, end_result
order by endscores.end, end_result;


-- iteration on the above to separate 'points scored' into how many points scored
SELECT 
    endscores.end,
    CASE
        WHEN score = 0 AND opp_score = 0 THEN 'Blanked'
        ELSE CONCAT('Points Scored (', score, ')')
    END AS end_result,
    COUNT(*) AS frequency
from 
    endscores
GROUP BY 
    endscores.end, 
    CASE
        WHEN score = 0 AND opp_score = 0 THEN 'Blanked'
        ELSE CONCAT('Points Scored (', score, ')')
    END
ORDER BY 
    endscores.end, end_result;
	
	
-- for each team, what is the number of times they blank an end, score, or their opponent scores
SELECT team,
    endscores.end,
    CASE
        WHEN score = 0 AND opp_score = 0 THEN 'Blanked'
        WHEN score = 0 AND opp_score > 0 THEN 'Opp Scored'
		WHEN score > 0 AND opp_score = 0 THEN 'Team Scored'
		ELSE 'unknown'
    END AS end_result,
    COUNT(*) AS frequency,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY team, endscores.end), 2) AS percentage_by_end
from 
    endscores
group by team, endscores.end, CASE
        WHEN score = 0 AND opp_score = 0 THEN 'Blanked'
        WHEN score = 0 AND opp_score > 0 THEN 'Opp Scored'
		WHEN score > 0 AND opp_score = 0 THEN 'Team Scored'
		ELSE 'unknown'
    END
order by team, endscores.end, CASE
        WHEN score = 0 AND opp_score = 0 THEN 'Blanked'
        WHEN score = 0 AND opp_score > 0 THEN 'Opp Scored'
		WHEN score > 0 AND opp_score = 0 THEN 'Team Scored'
		ELSE 'unknown'
    END
	


-- points scored for and against by each team
-- average points scored for and against in an event
SELECT 
    ga.event_id,
    CASE 
        WHEN es.team = ga.team1 THEN ga.team1
        WHEN es.team = ga.team2 THEN ga.team2
    END AS team_name,
    AVG(es.total) AS avg_points_scored,
    AVG(es.opp_total) AS avg_points_scored_against,
    AVG(es.total - es.opp_total) AS point_differential
FROM 
    games AS ga
JOIN 
    endscores AS es ON ga.event_id = es.event_id AND ga.game_id = es.game_id
GROUP BY 
    ga.event_id, team_name
order by ga.event_id;


-- which teams score the most points on average in a game?
SELECT 
    team_name,
    AVG(points_scored) AS avg_points_scored_per_game,
	count(*) as games_played
FROM (
    SELECT 
        CASE 
            WHEN es.team = ga.team1 THEN ga.team1_score
            WHEN es.team = ga.team2 THEN ga.team2_score
        END AS points_scored,
        CASE 
            WHEN es.team = ga.team1 THEN ga.team1
            WHEN es.team = ga.team2 THEN ga.team2
        END AS team_name
    FROM 
        games AS ga
    JOIN 
        endscores AS es ON ga.event_id = es.event_id AND ga.game_id = es.game_id
    GROUP BY 
        ga.event_id, ga.game_id, team_name, points_scored
) AS subquery
GROUP BY 
    team_name
ORDER BY 
    avg_points_scored_per_game DESC;
	

-- looking at scoring with and without hammer (hammer possession based on shots data)
SELECT 
    e.team,
    AVG(CASE WHEN s.has_hammer THEN e.score ELSE NULL END) AS avg_score_with_hammer,
    AVG(CASE WHEN NOT s.has_hammer THEN e.score ELSE NULL END) AS avg_score_without_hammer
FROM 
    endscores e
JOIN 
    shots s ON e.game_id = s.game_id AND e.end = s.end AND e.team = s.team
GROUP BY 
    e.team;
	

select es.team, es.game_id, es.end, es.score, es.opp_score, sh.has_hammer
from endscores as es
join shots as sh
on es.game_id = sh.game_id AND es.end = sh.end AND es.team = sh.team
group by es.team, es.game_id, es.end, sh.has_hammer, es.score, es.opp_score
order by es.team, es.game_id, es.end;


---- Analyzing Ends with Hammer
-- calculating Hammer Efficiency for each team
SELECT 
    team,
    COUNT(*) AS total_hammer_ends,
    SUM(CASE WHEN score >= 2 THEN 1 ELSE 0 END) AS ends_scoring_2_or_more,
    (SUM(CASE WHEN score >= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS hammer_efficiency
from (
	select es.team, es.game_id, es.end, es.score, es.opp_score, sh.has_hammer
	from endscores as es
	join shots as sh
	on es.game_id = sh.game_id AND es.end = sh.end AND es.team = sh.team
	group by es.team, es.game_id, es.end, sh.has_hammer, es.score, es.opp_score
)
WHERE 
    has_hammer = true AND (es.score > 0 or es.opp_score > 0) -- ends where team had hammer and the end didn't blank
GROUP BY 
    team
ORDER BY 
    team;
	
-- calculating Steal Defense
SELECT 
    es.team,
    COUNT(*) AS total_hammer_ends,
    SUM(CASE WHEN es.opp_score > 0 THEN 1 ELSE 0 END) AS ends_stolen_against,
    (SUM(CASE WHEN es.opp_score > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS steal_defense
FROM 
    endscores es
JOIN 
    shots sh ON es.game_id = sh.game_id AND es.end = sh.end AND es.team = sh.team
WHERE 
    sh.has_hammer = true
GROUP BY 
    es.team
ORDER BY 
    es.team;
-- lower is better for this one

-- now lets combine the two and calculate Hammer Factor
/* In	general,	how	a	team	performs	with	hammer	provides	a	clearer	measure	of	relative	performance	
than	its	performance	without	hammer.		
Teams	often	have	varied strategies	that	can	result	in	similar	
winning	percentages	or	rankings	despite	different ranges	of	HE	or	SD.		
A	highly	ranked	team	with	a	lower	HE	may	have	a	lower	SD,	indicating	they	put	less	rocks	in	play	and	take	fewer	chances.
By	subtracting	these	results,	we	can	produce	a	Hammer	Factor	which	provides another	indicator	of	
a	team’s	level	of	play  */ 
WITH hammerEfficiency as (
		SELECT 
			es.team,
			COUNT(*) AS total_hammer_ends,
			SUM(CASE WHEN es.score >= 2 THEN 1 ELSE 0 END) AS ends_scoring_2_or_more,
			(SUM(CASE WHEN es.score >= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS hammer_efficiency
		FROM 
			endscores es
		JOIN 
			shots sh ON es.game_id = sh.game_id AND es.end = sh.end AND es.team = sh.team
		WHERE 
			sh.has_hammer = true AND (es.score > 0 or es.opp_score > 0) -- ends where team had hammer and the end didn't blank
		GROUP BY 
			es.team
		ORDER BY 
			es.team
),
	stealDefense as(
		SELECT 
		es.team,
		COUNT(*) AS total_hammer_ends,
		SUM(CASE WHEN es.opp_score > 0 THEN 1 ELSE 0 END) AS ends_stolen_against,
		(SUM(CASE WHEN es.opp_score > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS steal_defense
		FROM 
			endscores es
		JOIN 
			shots sh ON es.game_id = sh.game_id AND es.end = sh.end AND es.team = sh.team
		WHERE 
			sh.has_hammer = true
		GROUP BY 
			es.team
		ORDER BY 
			es.team
)
select he.team, he.hammer_efficiency, sd.steal_defense,
		(he.hammer_efficiency - sd.steal_defense) as hammer_factor
from hammerEfficiency as he
join stealDefense as sd
on he.team = sd.team
order by hammer_factor desc
;



---- Analyzing Ends without Hammer
-- calculating Force Efficiency (limiting your opponent's scoring)
    SELECT 
        es.team,
        COUNT(*) FILTER (WHERE NOT sh.has_hammer AND es.opp_score > 0) AS total_ends_without_hammer_opponent_scores,
        SUM(CASE WHEN es.opp_score = 1 AND NOT sh.has_hammer THEN 1 ELSE 0 END) AS ends_opponent_scored_1,
        (SUM(CASE WHEN es.opp_score = 1 AND NOT sh.has_hammer THEN 1 ELSE 0 END) * 100.0 / COUNT(*) FILTER (WHERE NOT sh.has_hammer AND es.opp_score > 0)) AS force_efficiency
    FROM 
        endscores es
    JOIN 
        shots sh ON es.game_id = sh.game_id AND es.end = sh.end AND es.team = sh.team
    WHERE 
        NOT sh.has_hammer
    GROUP BY 
        es.team
		

-- calculating Steal Efficiency
/* 	the	percentage	of	ends	a	team	steals	one	or	more	points.	
It's	calculated	by	dividing	ends	stolen	without	hammer	by	the	total	ends	played	without	hammer,
Blank	ends	are	included */
select es.team,
    round(SUM(CASE WHEN es.score > 0 THEN 1.0 ELSE 0 END) / COUNT(*), 4) AS steal_efficiency
from endscores as es
join shots sh ON es.game_id = sh.game_id AND es.end = sh.end AND es.team = sh.team
where NOT sh.has_hammer
GROUP BY es.team
ORDER BY es.team;

