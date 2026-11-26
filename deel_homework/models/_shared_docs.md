{% docs col__file_name %}
Stage file the row was loaded from.
{% enddocs %}

{% docs col__file_last_modified %}
Last modified time of the stage file (TIMESTAMP_NTZ, UTC).
{% enddocs %}

{% docs col__file_content_key %}
Hash of the stage file content; changes when the file content changes.
{% enddocs %}

{% docs col__load_id %}
dbt invocation_id of the load run; matches dbt logs.
{% enddocs %}

{% docs col__loaded_at %}
Time the row was inserted into Snowflake (TIMESTAMP_NTZ, UTC).
{% enddocs %}