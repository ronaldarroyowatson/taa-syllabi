<!-- markdownlint-disable MD032 MD013 -->

# {{ course_name }} Syllabus

## Term

{{ term }}

## Course Header

- Grades: {{ grades }}
- Class Time: {{ class_time }}
- Textbook: {{ textbook }}

## Course Description

{{ course_description }}

## Units

{% for unit in units %}
- {{ unit }}
{% endfor %}

## Required Materials

{% for item in required_materials %}
- {{ item }}
{% endfor %}

## Optional Materials

{% for item in optional_materials %}
- {{ item }}
{% endfor %}

## Exam Schedule

{% include_relative ../shared/common/exam-schedule.md %}

## Shared Rules

{% if reading_level == "high-school" %}
{% include_relative ../shared/high-school/rules.md %}
{% else %}
{% include_relative ../shared/middle-school/rules.md %}
{% endif %}

## Shared Grading

{% if reading_level == "high-school" %}
{% include_relative ../shared/high-school/grading.md %}
{% else %}
{% include_relative ../shared/middle-school/grading.md %}
{% endif %}

## Shared Policies

{% if reading_level == "high-school" %}
{% include_relative ../shared/high-school/policies.md %}
{% else %}
{% include_relative ../shared/middle-school/policies.md %}
{% endif %}

## Shared Safety

{% if reading_level == "high-school" %}
{% include_relative ../shared/high-school/safety.md %}
{% else %}
{% include_relative ../shared/middle-school/safety.md %}
{% endif %}

## Shared Contact Info

{% if reading_level == "high-school" %}
{% include_relative ../shared/high-school/contact-info.md %}
{% else %}
{% include_relative ../shared/middle-school/contact-info.md %}
{% endif %}

## Syllabus Change Notice

- Class rules, procedures, and expectations may change at any time to support student learning, school policy, legal requirements, or safety needs.
- Official updates will be posted in this repository copy of the syllabus: [Current class syllabus]({{ syllabus_repo_link }}).
- A repository-wide summary of rule updates is tracked in [README change log]({{ rules_readme_link }}).

<!-- markdownlint-enable MD032 MD013 -->
