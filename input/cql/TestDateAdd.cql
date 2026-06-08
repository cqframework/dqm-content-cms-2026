library TestDateAdd

define Test: @2021-01-01 + 25 hours

define TestDynamic: @2021-01-01 + Quantity { value: 25, unit: 'hours' }
