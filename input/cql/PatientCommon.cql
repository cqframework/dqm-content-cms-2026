/*
@description: Common patient fluent functions
@comment: These are currently in the CI Build of US CQL, reproduced here for ease of reference
*/
library PatientCommon

using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1'
include hl7.fhir.uv.cql.FHIRCommon version '2.0.0'

context Patient

/*
@description: Returns the age in days of the patient as of the given date, using birth time if known
@comment: This function returns the number of whole days between the patient birth date 
and the asOf date. If the patient has a birthTime, the calculation is performed using the 
birthDateTime, and the time component of the asOf parameter is considered. Note that when 
the birth time is known, timezone offset normalization will be used.
*/
define fluent function ageInDaysAt(patient Patient, asOf DateTime):
  if patient.birthTime() is not null then
    CalculateAgeInDaysAt(Patient.birthDateTime(), asOf)
  else
    CalculateAgeInDaysAt(Patient.birthDate, date from asOf)

/*
@description: Returns the current age in days of the patient, using birth time if known
@comment: This function returns the number of whole days between the patient birth date 
and the current date. If the patient has a birthTime, the calculation is performed using the 
birthDateTime and Now(), otherwise the calculation is performed using Today(). Note that when 
the birth time is known, timezone offset normalization will be used.
*/
define fluent function ageInDays(patient Patient):
  if patient.birthTime() is not null then
    CalculateAgeInDaysAt(Patient.birthDateTime(), Now())
  else
    CalculateAgeInDaysAt(Patient.birthDate, Today())

/*
@description: Returns the age in months of the patient as of the given date, using birth time if known
@comment: This function returns the number of whole calendar months between the patient birth date 
and the asOf date. If the patient has a birthTime, the calculation is performed using the 
birthDateTime, and the time component of the asOf parameter is considered. Note that when 
the birth time is known, timezone offset normalization will be used.
*/
define fluent function ageInMonthsAt(patient Patient, asOf DateTime):
  if patient.birthTime() is not null then
    CalculateAgeInMonthsAt(Patient.birthDateTime(), asOf)
  else
    CalculateAgeInMonthsAt(Patient.birthDate, date from asOf)

/*
@description: Returns the current age in months of the patient, using birth time if known
@comment: This function returns the number of whole calendar months between the patient birth date 
and the current date. If the patient has a birthTime, the calculation is performed using the 
birthDateTime and Now(), otherwise the calculation is performed using Today(). Note that when 
the birth time is known, timezone offset normalization will be used.
*/
define fluent function ageInMonths(patient Patient):
  if patient.birthTime() is not null then
    CalculateAgeInMonthsAt(Patient.birthDateTime(), Now())
  else
    CalculateAgeInMonthsAt(Patient.birthDate, Today())

/*
@description: Returns the age in years of the patient, as of the given date
@comment: This function returns the number of whole calendar years between the patient birth 
date and the given date. Regardless of whether the patient has a birthTime, the calculation is
performed using only the birth date. If the given date has a time component, it is ignored, on 
the grounds that birth time is almost universally not considered when determining age in years.
*/
define fluent function ageInYearsAt(patient Patient, asOf DateTime):
  CalculateAgeInYearsAt(Patient.birthDate, date from asOf)

/*
@description: Returns the current age in years of the patient
@comment: This function returns the number of whole calendar years between the patient birth 
date and the current date. Regardless of whether the patient has a birthTime, the calculation is
performed using only the birth date and Today(), on the grounds that birth time is almost universally 
not considered when determining age in years.
*/
define fluent function ageInYears(patient Patient):
  CalculateAgeInYearsAt(Patient.birthDate, Today())

