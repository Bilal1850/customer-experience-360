-- Illustrative example written for this portfolio from the documented model rules.
-- It is NOT the production code; table and column names follow the published data model.
-- Rule (docs/data-model.md §10): NPS answers on a 0–10 scale are
--   Detractor 0–6 · Passive 7–8 · Promoter 9–10

WITH nps_answers AS (
    SELECT
        f.SurveySk,
        f.SSFactSk                        AS SubmissionSk,
        r.AnswerNumeric
    FROM SurveyResponseFact      AS r
    JOIN SurveySubmissionFact    AS f ON f.SSFactSk   = r.SSFactSk
    JOIN QuestionDim             AS q ON q.QuestionSk = r.QuestionSk
    JOIN ScaleDim                AS s ON s.ScaleSk    = r.ScaleSk
    WHERE q.IsNPS = 1
      AND s.MinValue = 0 AND s.MaxValue = 10
      AND r.AnswerNumeric IS NOT NULL
),
classified AS (
    SELECT
        SurveySk,
        SubmissionSk,
        CASE
            WHEN AnswerNumeric BETWEEN 0 AND 6 THEN 'Detractor'
            WHEN AnswerNumeric BETWEEN 7 AND 8 THEN 'Passive'
            WHEN AnswerNumeric BETWEEN 9 AND 10 THEN 'Promoter'
        END AS NpsClass
    FROM nps_answers
)
SELECT
    SurveySk,
    COUNT(*)                                                        AS Responses,
    100.0 * SUM(CASE WHEN NpsClass = 'Promoter'  THEN 1 ELSE 0 END) / COUNT(*)
  - 100.0 * SUM(CASE WHEN NpsClass = 'Detractor' THEN 1 ELSE 0 END) / COUNT(*) AS NPS
FROM classified
GROUP BY SurveySk;
