{% macro load_raw_from_stage(target_table, columns, file_pattern, stage) %}
    {# Convention: all technical timestamps are TIMESTAMP_NTZ in UTC.
     _loaded_at is filled by current_timestamp() converted to NTZ, which uses the
     session time zone, so we pin the session to UTC to get UTC wall-clock time.
     metadata$file_last_modified is already NTZ in UTC and is copied as is. #}
  {% do run_query("alter session set timezone = 'UTC'") %}

  {# Technical columns added to every RAW table: defined once, used everywhere #}
  {% set metadata_columns = [
      {'name': '_file_name',          'type': 'varchar',       'value': 'metadata$filename'},
      {'name': '_file_last_modified', 'type': 'timestamp_ntz',  'value': 'metadata$file_last_modified'},
      {'name': '_file_content_key',   'type': 'varchar',       'value': 'metadata$file_content_key'},
      {'name': '_load_id',            'type': 'varchar',       'value': "'" ~ invocation_id ~ "'"}
      
  ] %}

  {% set create_sql %}
    create table if not exists {{ target_table }} (
      {%- for col in columns %}
      {{ col }} varchar,
      {%- endfor %}
      {%- for m in metadata_columns %}
      {{ m.name }} {{ m.type }},
      {%- endfor %}
      _loaded_at timestamp_ntz default current_timestamp()
    )
  {% endset %}

  {% set copy_sql %}
    copy into {{ target_table }} (
      {{ columns | join(', ') }},
      {{ metadata_columns | map(attribute='name') | join(', ') }}
    )
    from (
      select
        {%- for col in columns %} ${{ loop.index }},{% endfor %}
        {{ metadata_columns | map(attribute='value') | join(', ') }}
      from {{ stage }}
    )
    pattern = '{{ file_pattern }}'
    file_format = (
      type = csv
      skip_header = 1
      field_optionally_enclosed_by = '"'
    )
    on_error = abort_statement
  {% endset %}

  {% do run_query(create_sql) %}
  {{ log('--- ' ~ target_table ~ ' ---', info=True) }}
  {% do run_query(copy_sql).print_table() %}

{% endmacro %}