# CX Survey Enterprise Data Model: design notes

Designed by Bilal Anjum, the CX Survey Data Model establishes a centralized, scalable, and Kimball-compliant analytical foundation for Customer Experience reporting across SurveyMonkey, Call Center, and WhatsApp channels. The objective is to bring survey interactions, submissions, questions, answers, customer feedback, and CX performance indicators into a common dimensional structure that can be consumed consistently by reporting, analytics, and Power BI.

## What is included in the design

The solution covers the complete survey data lifecycle, from the raw SurveyMonkey response grain through semantic classification and dimensional modeling to final analytical facts and CX measures.

## 1. Multi-channel CX architecture

The model extends the existing Call Center survey constellation so that SurveyMonkey can be integrated without creating a separate analytical model. The architecture is designed around reusable, conformed dimensions that can eventually support SurveyMonkey, Call Center, WhatsApp, and additional CX channels.

The model follows a Kimball constellation/star-schema approach, with common dimensions shared across multiple fact tables.

## 2. Defined SurveyMonkey source and atomic grain

The SurveyMonkey Bronze source is defined as:

BronzeLakehouse.dbo.sm_satisfaction_1

The atomic source grain is:

One row per Survey × Submission × Question

The main source attributes include:

collector_id for the survey

respondent_id for the completed submission

question for the individual survey question

answer for the respondent's raw response

answer_type to identify the nature of the answer

date_created for submission timing

Defining the grain explicitly ensures that downstream dimensions and facts are built consistently and prevents accidental duplication during aggregation.

## 3. Conformed dimensions

The design introduces or reuses several dimensions to provide a standardized analytical context:

SurveyDim stores survey-level metadata, including the survey identifier, name, product, status, and owning customer information.

ChannelDim standardizes the source channel, including Call Center, WhatsApp, and SurveyMonkey.

TouchPointDim provides the business context in which the interaction occurred, including media type, channel subtype, agent, language, and associated channel.

DateDim and TimeDim provide standardized calendar and time analysis across all CX facts.

These dimensions allow different survey systems to be analyzed through the same enterprise semantic structure.

## 4. QuestionDim as the semantic core

A major component of the solution is the enrichment of QuestionDim.

Rather than repeatedly interpreting the meaning of a survey question inside Power BI or individual reports, the semantic interpretation is performed during ingestion and persisted in the dimensional model.

Each question can therefore be classified according to CX intent, including:

CSAT – Customer Satisfaction

NPS – Net Promoter Score / loyalty

CES – Customer Effort Score

FCR – First Contact Resolution

Value – usefulness or perceived value

Perception – brand/image-related feedback

Text – open-ended customer feedback

Context – supporting or contextual survey questions

The design uses question-text pattern recognition to populate flags such as IsCSAT, IsNPS, IsCES, IsFCR, and IsValue.

This means the semantic interpretation is performed once during the data engineering process, rather than independently in every dashboard.

## 5. Automatic scale identification

The model also identifies the expected response scale directly from the question definition.

Supported scale patterns include:

1–5 rating scale

1–10 rating scale

0–10 NPS scale

Yes/No binary scale

No numeric scale for qualitative questions

These scales are represented centrally through ScaleDim, which stores the permitted minimum and maximum numeric values.

This separates the meaning of a question from the physical response received from the source system.

## 6. Standardized answer interpretation

AnswerChoiceDim provides the translation layer between raw textual survey answers and analytical numeric values.

For example:

Très insatisfait → 1

Insatisfait → 2

Neutre → 3

Satisfait → 4

Très satisfait → 5

Similarly:

Oui / Yes → 1

Non / No → 0

This design avoids embedding answer-conversion logic repeatedly in Power BI measures, reports, notebooks, or downstream analytical processes.

## 7. Survey invitation modeling

SurveyInviteFact is included to represent survey invitations when this information is available.

Its intended grain is:

One row per survey invitation

This provides the foundation for future analysis of invitation-to-response conversion, participation, non-response, and channel effectiveness.

## 8. Submission-level fact

SurveySubmissionFact represents the overall customer survey submission.

Its grain is:

One row per Survey × Submission

It consolidates information such as:

Submission ID

Survey

Channel

Touchpoint

Submission date and time

Number of answered questions

Aggregated CSAT score

NPS classification

Source system

ETL batch information

Record creation timestamp

This fact therefore provides the appropriate level for calculating overall survey participation and submission-level CX indicators.

## 9. Question-level response fact

SurveyResponseFact maintains the detailed response-level information at:

One row per Submission × Question

Numeric responses store:

Question

Scale

Answer choice

Interpreted numeric answer

Open-ended responses store the original customer feedback through CommentText.

This ensures the model preserves both structured quantitative feedback and unstructured qualitative feedback without mixing their analytical meaning.

## 10. CX metric calculation

The model includes the foundations for calculating major CX KPIs.

For example, CSAT responses are identified through QuestionDim.IsCSAT and aggregated from the standardized AnswerNumeric value.

For NPS, responses on the 0–10 scale are categorized as:

Detractor: 0–6

Passive: 7–8

Promoter: 9–10

The resulting classification can then be associated with the submission and used downstream to calculate enterprise NPS.

The same architecture provides the basis for CES, FCR, Value, brand perception, process indicators, and adoption analysis.

## 11. Open-ended customer feedback

The architecture explicitly supports free-text survey responses.

Questions classified within the TEXT CX domain retain the original answer as CommentText. This allows the same model to support future use cases such as:

Sentiment analysis

Complaint/topic classification

Customer pain-point detection

Feedback categorization

Keyword/trend analysis

AI-based summarization and recommendation generation

This is particularly useful for combining quantitative CX scores with the customer's actual written feedback.

## 12. Data quality and governance controls

The design also establishes validation rules to maintain the reliability of the CX semantic layer.

Key rules include:

A question should not be simultaneously classified into conflicting CX metrics.

CX domain classification must remain consistent with metric flags.

Numeric responses must contain a valid AnswerNumeric.

Textual responses must contain CommentText.

A response should not simultaneously be treated as both numeric and free text.

Every response must reference a valid submission.

Dimension references should resolve to valid surrogate keys.

These controls provide a strong basis for implementing automated data-quality checks in the Silver layer.

## Overall Outcome

The completed design transforms raw SurveyMonkey responses into an enterprise CX analytical model rather than simply loading survey data into reporting tables.

It introduces a reusable semantic layer where survey, channel, touchpoint, question, scale, answer interpretation, submission, and individual response are modeled separately but connected through conformed dimensions and facts.

The resulting architecture supports a consistent analytical journey:

`Raw Survey Response → Question Classification → Scale Identification → Answer Standardization → Submission Consolidation → CX KPI Calculation → Enterprise CX Reporting

This provides a scalable foundation for combining SurveyMonkey, Call Center, WhatsApp, and future customer-feedback channels while maintaining consistent definitions for CSAT, NPS, CES, FCR, Value, perception, contextual indicators, and qualitative feedback across the organization.

