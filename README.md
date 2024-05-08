# womens_curling
Data analytics project on womens curling games and athletes.

Data provided by https://doubletakeout.com/ from Jan 2024.

**Data Dictionary** <br>
Events table <br>
•	6 columns, 107 rows
•	Years 2002 – 2024 (1 event in 2024)
|     Column name    |     Description                                       |     Data type    |     Notes                                           |
|--------------------|-------------------------------------------------------|------------------|-----------------------------------------------------|
|     event_id       |     Unique event identifier                           |     Integer      |                                                     |
|     event_name     |     Name of event/tournament                          |     Text         |                                                     |
|     Year           |                                                       |                  |                                                     |
|     Ends           |     Number of ends expected to be played each game    |     Integer      |                                                     |
|     Gender         |     Gender of players                                 |     Text         |     Women or men. Scoped to be women only events    |
|     Junior         |     Junior event or not                               |     integer      |     Binary: 1 = junior event, 0 = not junior        |


Endscores table <br>
•	8 columns, 79239 rows
|     Column name    |     Description                                  |     Data type    |     Notes    |
|--------------------|--------------------------------------------------|------------------|--------------|
|     event_id       |     Unique event identifier                      |     Integer      |              |
|     game_id        |     Unique game number                           |     Integer      |              |
|     team           |     Name of the team                             |     Text         |              |
|     end            |     The end number within a game                 |     Integer      |              |
|     Score          |     Points scored in the end by the team         |     Integer      |              |
|     Opp_score      |     Points scored in the end by opponent         |     Integer      |              |
|     Total          |     Team total score at the start of that end    |     Integer      |              |
|     Opp_total      |     Opponent score at the start of that end      |     Integer      |              |


Games table <br>
•	7 columns, 4129 rows
|     Column name    |     Description                                |     Data type    |     Notes                                               |
|--------------------|------------------------------------------------|------------------|---------------------------------------------------------|
|     event_id       |     Unique event identifier                    |     Integer      |                                                         |
|     game_id        |     Unique game number                         |     Integer      |     Should match to endscores table same column name    |
|     draw           |                                                |     text         |                                                         |
|     Team1          |     Team name                                  |     Text         |                                                         |
|     Team2          |     Team name                                  |     text         |                                                         |
|     Team1_score    |     Final score of the game for team1          |     integer      |                                                         |
|     Team2_score    |     Final score of the game for team2          |     Integer      |                                                         |
|     Opp_total      |     Opponent score at the start of that end    |     Integer      |                                                         |


Shots table <br>
• 9 columns, 592k+ rows
|     Column name    |     Description                                             |     Data type    |     Notes                                                                              |
|--------------------|-------------------------------------------------------------|------------------|----------------------------------------------------------------------------------------|
|     event_id       |     Unique event identifier                                 |     Integer      |                                                                                        |
|     game_id        |     Unique game number                                      |     Integer      |     Should match to endscores table same column name                                   |
|     team           |     Team name                                               |     Text         |                                                                                        |
|     Opponent       |     Name of the opponent team                               |     text         |                                                                                        |
|     End            |     The end number of the game                              |     Integer      |                                                                                        |
|     end_shot       |     Which shot of the end it was                            |     integer      |     Numbered 1-16 for each rock (8 shots per team)                                     |
|     athlete        |     Name of curler                                          |     Text         |                                                                                        |
|     task           |     Type of shot being made                                 |     Text         |                                                                                        |
|     Points         |     Numerical score of shot accuracy (closeness to task)    |     integer      |     0-4 points awarded.     0 = completely unsuccessful     4 = shot made as called    |
