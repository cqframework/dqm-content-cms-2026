/*
@description: Tests for the FHIRBuilders library
@comment: Each test expression is named `Test...` and evaluates to `true` when the test passes.

These tests need neither patient data nor terminology.

Each primitive builder is tested in both its function form (e.g. `string()`) and its fluent form
(e.g. `toFHIRString()`), for:
* the type of the result,
* the value it wraps, read with `.value` so that the test checks the builder rather than the FHIRHelpers
  implicit conversions, and
* a `null` input, which must give a `null` result rather than a primitive with no value.

The fluent forms are all named `toFHIR...()` (`toFHIRBoolean()`, `toFHIRString()`, ...). Several of
them could not be named `toBoolean()`, `toString()`, ..., since a fluent call with one of those names is
resolved as the FHIRPath function (the system `ToBoolean`, `ToString`, ... operators) and never reaches
the FHIRBuilders function; the prefix is used for all of them for consistency.

Values that are "empty" but not null (`false`, `0`) must still be wrapped. The exception is the empty
string `''`, which the String-valued builders treat as null, since FHIR does not allow empty strings.

`Period()`, `Quantity()`, `Coding()`, and `CodeableConcept()` are also round-tripped through FHIRHelpers, since the reason they exist is to
build FHIR elements that FHIRHelpers reads back as the original CQL value.
*/
library FHIRBuildersTests version '0.1.000-draft'

using FHIR version '4.0.1'

include hl7.fhir.uv.cql.FHIRHelpers version '4.0.1' called FHIRHelpers
include FHIRBuilders version '0.1.000-draft' called Build

context Patient

/*
 * base64Binary
 */

define TestBase64Binary:
  Build.base64Binary('SGVsbG8=') is FHIR.base64Binary
    and Build.base64Binary('SGVsbG8=').value = 'SGVsbG8='

define TestToFHIRBase64Binary:
  'SGVsbG8='.toFHIRBase64Binary() is FHIR.base64Binary
    and 'SGVsbG8='.toFHIRBase64Binary().value = 'SGVsbG8='

define TestBase64BinaryNull:
  Build.base64Binary(null as String) is null
    and (null as String).toFHIRBase64Binary() is null

/*
 * boolean
 */

define TestBoolean:
  Build.boolean(true) is FHIR.boolean
    and Build.boolean(true).value = true

define TestToFHIRBoolean:
  true.toFHIRBoolean() is FHIR.boolean
    and true.toFHIRBoolean().value = true

// false is a value, not a null, so it must be wrapped
define TestBooleanFalse:
  Build.boolean(false) is not null
    and Build.boolean(false).value = false
    and false.toFHIRBoolean().value = false

define TestBooleanNull:
  Build.boolean(null as Boolean) is null
    and (null as Boolean).toFHIRBoolean() is null

/*
 * canonical
 */

define TestCanonical:
  Build.canonical('http://example.org/Library/Test|1.0.0') is FHIR.canonical
    and Build.canonical('http://example.org/Library/Test|1.0.0').value = 'http://example.org/Library/Test|1.0.0'

define TestToFHIRCanonical:
  'http://example.org/Library/Test'.toFHIRCanonical() is FHIR.canonical
    and 'http://example.org/Library/Test'.toFHIRCanonical().value = 'http://example.org/Library/Test'

define TestCanonicalNull:
  Build.canonical(null as String) is null
    and (null as String).toFHIRCanonical() is null

/*
 * code
 */

define TestCode:
  Build.code('final') is FHIR.code
    and Build.code('final').value = 'final'

define TestToFHIRCode:
  'final'.toFHIRCode() is FHIR.code
    and 'final'.toFHIRCode().value = 'final'

define TestCodeNull:
  Build.code(null as String) is null
    and (null as String).toFHIRCode() is null

/*
 * date
 */

define TestDate:
  Build.date(@2024-03-01) is FHIR.date
    and Build.date(@2024-03-01).value = @2024-03-01

define TestToFHIRDate:
  @2024-03-01.toFHIRDate() is FHIR.date
    and @2024-03-01.toFHIRDate().value = @2024-03-01

// Partial dates are allowed in FHIR, and the precision must be kept
define TestDatePartial:
  Build.date(@2024-03).value ~ @2024-03
    and Build.date(@2024).value ~ @2024

define TestDateNull:
  Build.date(null as Date) is null
    and (null as Date).toFHIRDate() is null

/*
 * dateTime
 */

define TestDateTime:
  Build.dateTime(@2024-03-01T08:30:00.000Z) is FHIR.dateTime
    and Build.dateTime(@2024-03-01T08:30:00.000Z).value = @2024-03-01T08:30:00.000Z

define TestToFHIRDateTime:
  @2024-03-01T08:30:00.000Z.toFHIRDateTime() is FHIR.dateTime
    and @2024-03-01T08:30:00.000Z.toFHIRDateTime().value = @2024-03-01T08:30:00.000Z

define TestDateTimeKeepsOffset:
  Build.dateTime(@2024-03-01T08:30:00.000-05:00).value = @2024-03-01T13:30:00.000Z
    and timezoneoffset from Build.dateTime(@2024-03-01T08:30:00.000-05:00).value = -5.0

define TestDateTimePartial:
  Build.dateTime(@2024-03-01T).value ~ @2024-03-01T
    and Build.dateTime(@2024-03T).value ~ @2024-03T

define TestDateTimeNull:
  Build.dateTime(null as DateTime) is null
    and (null as DateTime).toFHIRDateTime() is null

/*
 * decimal
 */

define TestDecimal:
  Build.decimal(1.5) is FHIR.decimal
    and Build.decimal(1.5).value = 1.5

define TestToFHIRDecimal:
  1.5.toFHIRDecimal() is FHIR.decimal
    and 1.5.toFHIRDecimal().value = 1.5

define TestDecimalZeroAndNegative:
  Build.decimal(0.0).value = 0.0
    and Build.decimal(-2.25).value = -2.25

define TestDecimalNull:
  Build.decimal(null as Decimal) is null
    and (null as Decimal).toFHIRDecimal() is null

/*
 * id
 */

define TestId:
  Build.id('test-patient') is FHIR.id
    and Build.id('test-patient').value = 'test-patient'

define TestToFHIRId:
  'test-patient'.toFHIRId() is FHIR.id
    and 'test-patient'.toFHIRId().value = 'test-patient'

define TestIdNull:
  Build.id(null as String) is null
    and (null as String).toFHIRId() is null

/*
 * instant
 */

define TestInstant:
  Build.instant(@2024-03-01T08:30:00.000Z) is FHIR.instant
    and Build.instant(@2024-03-01T08:30:00.000Z).value = @2024-03-01T08:30:00.000Z

define TestToFHIRInstant:
  @2024-03-01T08:30:00.000Z.toFHIRInstant() is FHIR.instant
    and @2024-03-01T08:30:00.000Z.toFHIRInstant().value = @2024-03-01T08:30:00.000Z

define TestInstantNull:
  Build.instant(null as DateTime) is null
    and (null as DateTime).toFHIRInstant() is null

/*
 * integer
 */

define TestInteger:
  Build.integer(42) is FHIR.integer
    and Build.integer(42).value = 42

define TestToFHIRInteger:
  42.toFHIRInteger() is FHIR.integer
    and 42.toFHIRInteger().value = 42

define TestIntegerZeroAndNegative:
  Build.integer(0) is not null
    and Build.integer(0).value = 0
    and Build.integer(-7).value = -7

define TestIntegerNull:
  Build.integer(null as Integer) is null
    and (null as Integer).toFHIRInteger() is null

/*
 * string
 */

define TestString:
  Build.string('Test') is FHIR.string
    and Build.string('Test').value = 'Test'

define TestToFHIRString:
  'Test'.toFHIRString() is FHIR.string
    and 'Test'.toFHIRString().value = 'Test'

// FHIR does not allow empty strings, so the String-valued builders treat '' as null
define TestStringEmpty:
  Build.string('') is null
    and ''.toFHIRString() is null

// A whitespace-only string is also treated as null
define TestStringWhitespace:
  Build.string(' ') is null
    and Build.string(' \t\n ') is null
    and ' '.toFHIRString() is null

// Leading and trailing whitespace around a value is kept
define TestStringPaddedValue:
  Build.string(' Test ') is not null
    and ' Test '.toFHIRString() is not null

define TestEmptyStringBuilders:
  Build.base64Binary('') is null
    and ''.toFHIRBase64Binary() is null
    and Build.canonical('') is null
    and ''.toFHIRCanonical() is null
    and Build.code('') is null
    and ''.toFHIRCode() is null
    and Build.id('') is null
    and ''.toFHIRId() is null
    and Build.uri('') is null
    and ''.toFHIRUri() is null
    and Build.url('') is null
    and ''.toFHIRUrl() is null
    and Build.xhtml('') is null
    and ''.toFHIRXhtml() is null
define TestStringNull:
  Build.string(null as String) is null
    and (null as String).toFHIRString() is null

/*
 * time
 */

define TestTime:
  Build.time(@T08:30:00.000) is FHIR.time
    and Build.time(@T08:30:00.000).value = @T08:30:00.000

define TestToFHIRTime:
  @T08:30:00.000.toFHIRTime() is FHIR.time
    and @T08:30:00.000.toFHIRTime().value = @T08:30:00.000

define TestTimeNull:
  Build.time(null as Time) is null
    and (null as Time).toFHIRTime() is null

/*
 * uri
 */

define TestUri:
  Build.uri('http://loinc.org') is FHIR.uri
    and Build.uri('http://loinc.org').value = 'http://loinc.org'

define TestToFHIRUri:
  'urn:oid:2.16.840.1.113883.4.4'.toFHIRUri() is FHIR.uri
    and 'urn:oid:2.16.840.1.113883.4.4'.toFHIRUri().value = 'urn:oid:2.16.840.1.113883.4.4'

define TestUriNull:
  Build.uri(null as String) is null
    and (null as String).toFHIRUri() is null

/*
 * url
 */

define TestUrl:
  Build.url('http://example.org/fhir') is FHIR.url
    and Build.url('http://example.org/fhir').value = 'http://example.org/fhir'

define TestToFHIRUrl:
  'http://example.org/fhir'.toFHIRUrl() is FHIR.url
    and 'http://example.org/fhir'.toFHIRUrl().value = 'http://example.org/fhir'

define TestUrlNull:
  Build.url(null as String) is null
    and (null as String).toFHIRUrl() is null

/*
 * xhtml
 * Building a non-null FHIR.xhtml fails at runtime in the VS Code CQL engine ("Could not resolve data
 * provider for package 'org.hl7.fhir.utilities.xhtml'"), and that error aborts the whole run, so only the
 * null case is tested.
 */

define TestXhtmlNull:
  Build.xhtml(null as String) is null
    and (null as String).toFHIRXhtml() is null

/*
 * Period
 */

define TestPeriod:
  Build.Period(Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z]) is FHIR.Period
    and Build.Period(Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z]).start.value = @2024-03-01T08:00:00.000Z
    and Build.Period(Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z]).end.value = @2024-03-05T10:00:00.000Z

define TestToFHIRPeriod:
  Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z].toFHIRPeriod() is FHIR.Period
    and Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z].toFHIRPeriod().start.value = @2024-03-01T08:00:00.000Z
    and Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z].toFHIRPeriod().end.value = @2024-03-05T10:00:00.000Z

define TestPeriodRoundTrip:
  FHIRHelpers.ToInterval(Build.Period(Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z]))
    = Interval[@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z]

define TestPeriodPoint:
  Build.Period(Interval[@2024-03-01T08:00:00.000Z, @2024-03-01T08:00:00.000Z]).start.value = @2024-03-01T08:00:00.000Z
    and Build.Period(Interval[@2024-03-01T08:00:00.000Z, @2024-03-01T08:00:00.000Z]).end.value = @2024-03-01T08:00:00.000Z

// A closed null end is unbounded, so end of gives the maximum DateTime, but the period has no end
// element, which FHIR reads as ongoing
define TestPeriodNullEnd:
  Build.Period(Interval[@2024-03-01T08:00:00.000Z, null as DateTime]).start.value = @2024-03-01T08:00:00.000Z
    and Build.Period(Interval[@2024-03-01T08:00:00.000Z, null as DateTime]).end is null
    and Interval[@2024-03-01T08:00:00.000Z, null as DateTime].toFHIRPeriod().end is null

// An open null end is unknown, and also gives no end element
define TestPeriodUnknownEnd:
  Build.Period(Interval[@2024-03-01T08:00:00.000Z, null as DateTime)).start.value = @2024-03-01T08:00:00.000Z
    and Build.Period(Interval[@2024-03-01T08:00:00.000Z, null as DateTime)).end is null

define TestPeriodNullStart:
  Build.Period(Interval[null as DateTime, @2024-03-05T10:00:00.000Z]).start is null
    and Build.Period(Interval[null as DateTime, @2024-03-05T10:00:00.000Z]).end.value = @2024-03-05T10:00:00.000Z
    and Interval[null as DateTime, @2024-03-05T10:00:00.000Z].toFHIRPeriod().start is null

define TestPeriodUnknownStart:
  Build.Period(Interval(null as DateTime, @2024-03-05T10:00:00.000Z]).start is null
    and Build.Period(Interval(null as DateTime, @2024-03-05T10:00:00.000Z]).end.value = @2024-03-05T10:00:00.000Z

// A period with no end reads back as the closed, unbounded interval it was built from
define TestPeriodRoundTripNullEnd:
  FHIRHelpers.ToInterval(Build.Period(Interval[@2024-03-01T08:00:00.000Z, null as DateTime]))
    ~ Interval[@2024-03-01T08:00:00.000Z, null as DateTime]

// A FHIR Period is always closed, so open boundaries are resolved to their successor and predecessor
define TestPeriodOpenBoundaries:
  Build.Period(Interval(@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z)).start.value = @2024-03-01T08:00:00.001Z
    and Build.Period(Interval(@2024-03-01T08:00:00.000Z, @2024-03-05T10:00:00.000Z)).end.value = @2024-03-05T09:59:59.999Z

define TestPeriodNull:
  Build.Period(null as Interval<DateTime>) is null
    and (null as Interval<DateTime>).toFHIRPeriod() is null

/*
 * getSystem
 */

define TestGetSystemCalendarUnits:
  AllTrue(
    ({
      'year', 'years', 'month', 'months', 'day', 'days', 'hour', 'hours',
      'minute', 'minutes', 'second', 'seconds', 'millisecond', 'milliseconds'
    }) U
      return Build.getSystem(U).value = 'http://hl7.org/fhirpath/CodeSystem/calendar-units'
  )

define TestGetSystemUcum:
  Build.getSystem('mg').value = 'http://unitsofmeasure.org'
    and Build.getSystem('L/min').value = 'http://unitsofmeasure.org'
    and Build.getSystem('%').value = 'http://unitsofmeasure.org'
    and Build.getSystem('1').value = 'http://unitsofmeasure.org'

// UCUM codes for time units are not calendar duration names, so they are UCUM
define TestGetSystemUcumTimeUnits:
  Build.getSystem('d').value = 'http://unitsofmeasure.org'
    and Build.getSystem('wk').value = 'http://unitsofmeasure.org'
    and Build.getSystem('a').value = 'http://unitsofmeasure.org'

// Calendar unit names are case sensitive
define TestGetSystemCaseSensitive:
  Build.getSystem('Days').value = 'http://unitsofmeasure.org'

define TestGetSystemIsUri:
  Build.getSystem('mg') is FHIR.uri

/*
 * Quantity
 */

define TestQuantity:
  Build.Quantity(5 'mg') is FHIR.Quantity
    and Build.Quantity(5 'mg').value.value = 5.0
    and Build.Quantity(5 'mg').unit.value = 'mg'
    and Build.Quantity(5 'mg').code.value = 'mg'
    and Build.Quantity(5 'mg').system.value = 'http://unitsofmeasure.org'

define TestQuantityCalendarUnit:
  Build.Quantity(3 days).value.value = 3.0
    and Build.Quantity(3 days).unit.value = 'days'
    and Build.Quantity(3 days).code.value = 'days'
    and Build.Quantity(3 days).system.value = 'http://hl7.org/fhirpath/CodeSystem/calendar-units'

define TestQuantityDecimalValue:
  Build.Quantity(2.5 'L/min').value.value = 2.5
    and Build.Quantity(2.5 'L/min').code.value = 'L/min'

// A quantity with no unit has the default unit '1'
define TestQuantityUnitless:
  Build.Quantity(System.Quantity { value: 4.0 }).value.value = 4.0
    and Build.Quantity(System.Quantity { value: 4.0 }).code.value = '1'
    and Build.Quantity(System.Quantity { value: 4.0 }).system.value = 'http://unitsofmeasure.org'

define TestQuantityRoundTrip:
  FHIRHelpers.ToQuantity(Build.Quantity(5 'mg')) = 5 'mg'
    and FHIRHelpers.ToQuantity(Build.Quantity(2.5 'L/min')) = 2.5 'L/min'
    and FHIRHelpers.ToQuantity(Build.Quantity(30 '%')) = 30 '%'

define TestQuantityRoundTripCalendarUnit:
  FHIRHelpers.ToQuantity(Build.Quantity(3 days)) = 3 days
    and FHIRHelpers.ToQuantity(Build.Quantity(1 year)) = 1 year

define TestQuantityNull:
  Build.Quantity(null as System.Quantity) is null

/*
 * Coding
 */

define "Flow Rate Code":
  System.Code { code: '3151-8', system: 'http://loinc.org', version: '2.77', display: 'Inhaled oxygen flow rate' }

define "Bare Code":
  System.Code { code: '3151-8', system: 'http://loinc.org' }

define TestCoding:
  Build.Coding("Flow Rate Code") is FHIR.Coding
    and Build.Coding("Flow Rate Code").system.value = 'http://loinc.org'
    and Build.Coding("Flow Rate Code").version.value = '2.77'
    and Build.Coding("Flow Rate Code").code.value = '3151-8'
    and Build.Coding("Flow Rate Code").display.value = 'Inhaled oxygen flow rate'

define TestToFHIRCoding:
  "Flow Rate Code".toFHIRCoding() is FHIR.Coding
    and "Flow Rate Code".toFHIRCoding().code.value = '3151-8'
    and "Flow Rate Code".toFHIRCoding().system.value = 'http://loinc.org'

// Elements that are absent from the code are absent from the coding
define TestCodingWithoutVersionOrDisplay:
  Build.Coding("Bare Code").code.value = '3151-8'
    and Build.Coding("Bare Code").version is null
    and Build.Coding("Bare Code").display is null

define TestCodingRoundTrip:
  FHIRHelpers.ToCode(Build.Coding("Flow Rate Code")) = "Flow Rate Code"
    and FHIRHelpers.ToCode(Build.Coding("Bare Code")) = "Bare Code"

define TestCodingNull:
  Build.Coding(null as System.Code) is null
    and (null as System.Code).toFHIRCoding() is null

/*
 * CodeableConcept
 */

define "Pulse Oximetry Concept":
  System.Concept {
    codes: {
      System.Code { code: '59408-5', system: 'http://loinc.org' },
      System.Code { code: '2708-6', system: 'http://loinc.org' }
    },
    display: 'Pulse oximetry'
  }

define TestCodeableConcept:
  Build.CodeableConcept("Pulse Oximetry Concept") is FHIR.CodeableConcept
    and ((Build.CodeableConcept("Pulse Oximetry Concept").coding) C return C.code.value) = { '59408-5', '2708-6' }
    and Build.CodeableConcept("Pulse Oximetry Concept").text.value = 'Pulse oximetry'

define TestToFHIRCodeableConcept:
  "Pulse Oximetry Concept".toFHIRCodeableConcept() is FHIR.CodeableConcept
    and (("Pulse Oximetry Concept".toFHIRCodeableConcept().coding) C return C.code.value) = { '59408-5', '2708-6' }

define TestCodeableConceptRoundTrip:
  FHIRHelpers.ToConcept(Build.CodeableConcept("Pulse Oximetry Concept")) = "Pulse Oximetry Concept"

define TestCodeableConceptFromCode:
  Build.CodeableConcept("Flow Rate Code") is FHIR.CodeableConcept
    and Count(Build.CodeableConcept("Flow Rate Code").coding) = 1
    and Build.CodeableConcept("Flow Rate Code").coding[0].code.value = '3151-8'
    and Build.CodeableConcept("Flow Rate Code").coding[0].display.value = 'Inhaled oxygen flow rate'
    and Build.CodeableConcept("Flow Rate Code").text is null

define TestToFHIRCodeableConceptFromCode:
  "Flow Rate Code".toFHIRCodeableConcept() is FHIR.CodeableConcept
    and Count("Flow Rate Code".toFHIRCodeableConcept().coding) = 1

// A concept built from a code is equivalent to that code, which is how it is matched in measure logic
define TestCodeableConceptFromCodeEquivalent:
  Build.CodeableConcept("Flow Rate Code") ~ "Flow Rate Code"
    and Build.CodeableConcept("Bare Code") ~ "Flow Rate Code"

define TestCodeableConceptNull:
  Build.CodeableConcept(null as System.Concept) is null
    and Build.CodeableConcept(null as System.Code) is null
    and (null as System.Concept).toFHIRCodeableConcept() is null
    and (null as System.Code).toFHIRCodeableConcept() is null

/*
 * Identifier
 */

define TestIdentifier:
  Build.Identifier('http://hl7.org/fhir/sid/us-npi', '1234567893') is FHIR.Identifier
    and Build.Identifier('http://hl7.org/fhir/sid/us-npi', '1234567893').system.value = 'http://hl7.org/fhir/sid/us-npi'
    and Build.Identifier('http://hl7.org/fhir/sid/us-npi', '1234567893').value.value = '1234567893'

define TestIdentifierValueOnly:
  Build.Identifier(null, '1234567893').system is null
    and Build.Identifier(null, '1234567893').value.value = '1234567893'

define TestIdentifierSystemOnly:
  Build.Identifier('http://hl7.org/fhir/sid/us-npi', null).system.value = 'http://hl7.org/fhir/sid/us-npi'
    and Build.Identifier('http://hl7.org/fhir/sid/us-npi', null).value is null

define TestIdentifierNull:
  Build.Identifier(null, null) is null

/*
 * Reference
 */

define TestReference:
  Build.Reference('Patient/test-patient') is FHIR.Reference
    and Build.Reference('Patient/test-patient').reference.value = 'Patient/test-patient'

define TestToFHIRReference:
  'Location/er-1'.toFHIRReference() is FHIR.Reference
    and 'Location/er-1'.toFHIRReference().reference.value = 'Location/er-1'

define TestReferenceNull:
  Build.Reference(null as String) is null
    and (null as String).toFHIRReference() is null

define TestReferenceBlank:
  Build.Reference('') is null
    and Build.Reference(' ') is null
    and ''.toFHIRReference() is null

/*
 * Combined result
 */

// True only if every test in this library is true, for use as the population criteria of a Cohort
// measure. It uses `and` rather than AllTrue(), which ignores nulls, so that a null test fails it.
// It must list each Test define; .claude/skills/cql/check_results.py checks this.
define _Passed:
  TestBase64Binary
    and TestToFHIRBase64Binary
    and TestBase64BinaryNull
    and TestBoolean
    and TestToFHIRBoolean
    and TestBooleanFalse
    and TestBooleanNull
    and TestCanonical
    and TestToFHIRCanonical
    and TestCanonicalNull
    and TestCode
    and TestToFHIRCode
    and TestCodeNull
    and TestDate
    and TestToFHIRDate
    and TestDatePartial
    and TestDateNull
    and TestDateTime
    and TestToFHIRDateTime
    and TestDateTimeKeepsOffset
    and TestDateTimePartial
    and TestDateTimeNull
    and TestDecimal
    and TestToFHIRDecimal
    and TestDecimalZeroAndNegative
    and TestDecimalNull
    and TestId
    and TestToFHIRId
    and TestIdNull
    and TestInstant
    and TestToFHIRInstant
    and TestInstantNull
    and TestInteger
    and TestToFHIRInteger
    and TestIntegerZeroAndNegative
    and TestIntegerNull
    and TestString
    and TestToFHIRString
    and TestStringEmpty
    and TestStringWhitespace
    and TestStringPaddedValue
    and TestEmptyStringBuilders
    and TestStringNull
    and TestTime
    and TestToFHIRTime
    and TestTimeNull
    and TestUri
    and TestToFHIRUri
    and TestUriNull
    and TestUrl
    and TestToFHIRUrl
    and TestUrlNull
    and TestXhtmlNull
    and TestPeriod
    and TestToFHIRPeriod
    and TestPeriodRoundTrip
    and TestPeriodPoint
    and TestPeriodNullEnd
    and TestPeriodUnknownEnd
    and TestPeriodNullStart
    and TestPeriodUnknownStart
    and TestPeriodRoundTripNullEnd
    and TestPeriodOpenBoundaries
    and TestPeriodNull
    and TestGetSystemCalendarUnits
    and TestGetSystemUcum
    and TestGetSystemUcumTimeUnits
    and TestGetSystemCaseSensitive
    and TestGetSystemIsUri
    and TestQuantity
    and TestQuantityCalendarUnit
    and TestQuantityDecimalValue
    and TestQuantityUnitless
    and TestQuantityRoundTrip
    and TestQuantityRoundTripCalendarUnit
    and TestQuantityNull
    and TestCoding
    and TestToFHIRCoding
    and TestCodingWithoutVersionOrDisplay
    and TestCodingRoundTrip
    and TestCodingNull
    and TestCodeableConcept
    and TestToFHIRCodeableConcept
    and TestCodeableConceptRoundTrip
    and TestCodeableConceptFromCode
    and TestToFHIRCodeableConceptFromCode
    and TestCodeableConceptFromCodeEquivalent
    and TestCodeableConceptNull
    and TestIdentifier
    and TestIdentifierValueOnly
    and TestIdentifierSystemOnly
    and TestIdentifierNull
    and TestReference
    and TestToFHIRReference
    and TestReferenceNull
    and TestReferenceBlank
