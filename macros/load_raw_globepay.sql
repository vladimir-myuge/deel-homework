{% macro load_raw_globepay() %}

  {% set raw_schema = target.database ~ '.RAW' %}
  {% set stage = '@' ~ raw_schema ~ '.GLOBEPAY_STAGE' %}

  {# Column lists must follow the column order in the CSV files #}

  {% do load_raw_from_stage(
      target_table = raw_schema ~ '.GLOBEPAY_ACCEPTANCE',
      columns      = ['external_ref', 'status', 'source', 'ref', 'date_time', 'state',
                      'cvv_provided', 'amount', 'country', 'currency', 'rates'],
      file_pattern = '.*Acceptance.*[.]csv',
      stage        = stage
  ) %}

  {% do load_raw_from_stage(
      target_table = raw_schema ~ '.GLOBEPAY_CHARGEBACKS',
      columns      = ['external_ref', 'status', 'source', 'chargeback'],
      file_pattern = '.*Chargeback.*[.]csv',
      stage        = stage
  ) %}

{% endmacro %}