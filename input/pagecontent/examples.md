{:toc}

{: #examples }

### CAUTI Examples

#### CAUTI Rate Examples

|    | Mar29 | Mar30 | Mar31 | Apr01 | Apr02 | Apr03 | Apr04 | Apr05 |
|----|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
| Patient A |IUC<br/>Inserted<br/>(Day 1)|IUC<br/>(Day 2)|IUC<br/>(Day 3)|IUC<br/>Removed<br/>(Day 4)|IUC<br/>Inserted<br/>(Day 5)|IUC<br/>Inserted<br/>(Day 6)|IUC<br/>Removed<br/>(Day 7)|No IUC|
| Patient B |IUC<br/>Inserted<br/>(Day 1)|IUC<br/>(Day 2)|IUC<br/>(Day 3)|IUC<br/>Removed<br/>(Day 4)|No IUC|IUC<br/>Inserted<br/>(Day 1)|IUC<br/>(Day 2)|IUC<br/>(Day 3)|

> Rationale (Patient A): A UTI with a date of event on or between March 31st and April 5th, would be a CAUTI since the patient had an IUC in place for greater than two consecutive days. Please note, a UTI with a date of event on April 5th does qualify as a CAUTI, even though the IUC was removed the day prior.

> Rationale (Patient B): A UTI with a date of event on or between March 31st and April 2nd, would be a CAUTI since the patient had an IUC in place for greater than two consecutive days. A UTI with a date of event on April 2nd does quality as a CAUTI, even though the IUC was removed the day prior. Additionally, Patient B becomes eligible again for a CAUTI on April 5th.

| Jan22 | Jan23 | Jan24 | Jan25 |
|:-----:|:-----:|:-----:|:-----:|
| IUC<br/>Inserted<br/>(Day 1)|IUC<br/>Date of Event<br/>(Day 2)|IUC<br/>(Day 3)|IUC<br/>(Day 4)|

This example is a FHIR rendering of the CAUTI calculation example given in the 2022 Rebaseline guide:

[Example Source](https://www.cdc.gov/nhsn/2022rebaseline/sir-guide.pdf)

❖ Example 2: Negative Binomial Regression Model
Let’s look at another example of the calculation for the number of predicted infections using the negative
binomial regression model. This next example is for CAUTIs in a critical access hospital (CAH). Table 3 provides
details of the risk adjustment model used to calculate the number of predicted CAUTIs for CAHs. Note: As of the
time of publication of this document, the 2022 baseline for CAUTI is not yet available in the NHSN application.
The example below is being used for educational purposes only. An example of the calculation used for MRSA
bacteremia can be found in the Appendix.
Table 3. Risk Factors Used in the Critical Access Hospital CAUTI Model
Patient
Diabe
-tes
ASA
Score BMI Age
Oncology
Hospital
Procedure
Duration Scope
SSI
Identified?
Medical
School
Affiliation
Probability
of SSI (𝒑̂)
1 Y 2 35 59 N 89 N 0 Graduate 0.006
2 Y 3 41.5 71 N 206 N 0 Graduate 0.012
3 N 2 34 77 N 104 Y 1 Graduate 0.004
. . . . . . . Graduate
. . . . . . . Graduate
100 N 1 30 30 N 358 Y 1 Graduate 0.007
Total
6
(observed
SSIs) 8.911
Factor Parameter Estimate P-Value Variable Coding,
Based on Specific
Example Below
Intercept -7.6495 <0.0001 1
Average length of stay1
: ≥ 6.5 days 0.4257 <0.0001 1
Average length of stay1
: 1-6.4 days REFERENT - 0
Proportion of total beds that are ICU2
: <
0.16
0.4189 <0.0001 1
Section 1: Overview of the SIR
9 | P a g e
1 Average length of stay is calculated as # annual patient days/ total # of annual admissions, as reported on the Annual Hospital Survey
2 Proportion of beds that are ICU is calculated as: # of ICU beds / total # of beds, as reported on the Annual Hospital Survey
We can input the model details from Table 3 into the general negative binomial regression formula:
# 𝑝𝑟𝑒𝑑𝑖𝑐𝑡𝑒𝑑 𝐶𝐴𝑈𝑇𝐼 =
𝐸𝑥𝑝 [−7.6495 + 0.4257(𝐴𝑣𝑒𝑟𝑎𝑔𝑒 𝑙𝑒𝑛𝑔𝑡ℎ 𝑜𝑓 𝑠𝑡𝑎𝑦 ≥ 6.5)
+ 0.4189(𝑃𝑟𝑜𝑝𝑜𝑟𝑡𝑖𝑜𝑛 𝑜𝑓 𝑡𝑜𝑡𝑎𝑙 𝑏𝑒𝑑𝑠 𝑡ℎ𝑎𝑡 𝑎𝑟𝑒 𝐼𝐶𝑈 < 0.16)] 𝑥 𝑐𝑎𝑡ℎ𝑒𝑡𝑒𝑟 𝑑𝑎𝑦𝑠
In our example, we would like to calculate the number of predicted CAUTI events for a medical ward in a CAH.
The medical ward in our example has reported 450 catheter days and 2 CAUTI events for the time period of
interest. According to the facility’s NHSN annual survey, this facility reported 3 ICU beds, 1,500 annual patient
days, 175 annual admissions and 25 total beds.
In our example hospital, the completed formula looks like this:
𝐸𝑥𝑝 [−7.6495 + 0.4257(1) + 0.4189(1)] 𝑥 450 𝑐𝑎𝑡ℎ𝑒𝑡𝑒𝑟 𝑑𝑎𝑦𝑠
= 0.499 𝑝𝑟𝑒𝑑𝑖𝑐𝑡𝑒𝑑 𝐶𝐴𝑈𝑇𝐼 𝑒𝑣𝑒𝑛𝑡𝑠
Based on the negative binomial regression model, 0.499 CAUTIs were predicted to have occurred in this medical
ward. Since the number of predicted CAUTIs is less than 1, an SIR will not be calculated. Facilities have a few
options, outlined here, for reviewing and interpreting HAI data when an SIR cannot be calculated.