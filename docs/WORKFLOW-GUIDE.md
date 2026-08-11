# Syllabus Workflow Guide

This guide explains how to update, edit, and regenerate the syllabi in a way that is safe and repeatable.
It is written for someone with little technical experience, but it still covers the full workflow.

## 0. Quick reference for this exact workspace

Use these exact script commands from [package.json](../package.json):

```powershell
npm run generate
npm run generate:physics
npm run lint
npm run format
```

These scripts map to:

- `npm run generate` -> `powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/render-syllabi.ps1 -All`
- `npm run generate:physics` ->
  `powershell -NoProfile -ExecutionPolicy Bypass -File ./scripts/render-syllabi.ps1 -Class physics`

Current renderer and style files:

- Renderer script: [scripts/render-syllabi.ps1](../scripts/render-syllabi.ps1)
- Template: [syllabi/templates/syllabus-template.md](../syllabi/templates/syllabus-template.md)
- High-school Word reference: [syllabi/templates/word-reference/high-school-reference.docx](../syllabi/templates/word-reference/high-school-reference.docx)
- Middle-school Word reference: [syllabi/templates/word-reference/middle-school-reference.docx](../syllabi/templates/word-reference/middle-school-reference.docx)

## 0.1 How to find latest versions and IDs later

If you need to refresh environment details in the future, run:

```powershell
winget show --id Microsoft.VisualStudioCode -e
winget show --id Git.Git -e
winget show --id OpenJS.NodeJS.LTS -e
winget show --id JohnMacFarlane.Pandoc -e
code --list-extensions --show-versions
```

## 1. Start with the right files

The system is built from three main parts:

- The template: [syllabi/templates/syllabus-template.md](../syllabi/templates/syllabus-template.md)
- The class data: [syllabi/classes](../syllabi/classes)
- The shared content: [syllabi/shared](../syllabi/shared)

Use the template for structure. Use the YAML files for class-specific facts.
Use the shared files for rules that should apply to many classes.

## 2. What to change for each class

Every class has its own YAML file in [syllabi/classes](../syllabi/classes).

Edit the values in the YAML file for:

- `course_name`
- `term`
- `grades`
- `class_time`
- `textbook`
- `course_description`
- `units`
- `required_materials`
- `optional_materials`
- `exam_schedule`
- `reading_level`
- `instructor_name`
- `instructor_email`
- `office_location`
- `office_hours`

Important note:

- Use quotes around values that contain punctuation, especially colons.
- Avoid YAML block scalars such as `>-` in the current renderer. Use short single-line values instead.

## 3. What to change for shared rules

Shared content should be edited in:

- [syllabi/shared/high-school/rules.md](../syllabi/shared/high-school/rules.md)
- [syllabi/shared/middle-school/rules.md](../syllabi/shared/middle-school/rules.md)
- [syllabi/shared/high-school/grading.md](../syllabi/shared/high-school/grading.md)
- [syllabi/shared/middle-school/grading.md](../syllabi/shared/middle-school/grading.md)
- [syllabi/shared/high-school/policies.md](../syllabi/shared/high-school/policies.md)
- [syllabi/shared/middle-school/policies.md](../syllabi/shared/middle-school/policies.md)
- [syllabi/shared/high-school/safety.md](../syllabi/shared/high-school/safety.md)
- [syllabi/shared/middle-school/safety.md](../syllabi/shared/middle-school/safety.md)
- [syllabi/shared/high-school/contact-info.md](../syllabi/shared/high-school/contact-info.md)
- [syllabi/shared/middle-school/contact-info.md](../syllabi/shared/middle-school/contact-info.md)

If you change something here, it will flow into every class that uses that reading level.

## 4. What to change in the template

The master template is:

- [syllabi/templates/syllabus-template.md](../syllabi/templates/syllabus-template.md)

Use this file when you want to change the overall structure of the syllabus. Typical changes include:

- adding a new section
- changing the heading names
- moving a section to a different place
- adding a disclaimer or notice
- changing the shared include blocks

Exact placeholders already used in this template include:

- `{{ course_name }}`
- `{{ term }}`
- `{{ grades }}`
- `{{ class_time }}`
- `{{ textbook }}`
- `{{ course_description }}`
- `{{ syllabus_repo_link }}`
- `{{ rules_readme_link }}`

The template uses placeholders such as:

- `{{ course_name }}`
- `{{ term }}`
- `{{ grades }}`
- `{{ class_time }}`
- `{{ textbook }}`

The template also uses conditional blocks such as:

- `{% if reading_level == "high-school" %}`
- `{% else %}`
- `{% endif %}`

If you add a new placeholder, make sure the matching value exists in the
YAML file or the renderer will not have anything to fill it.

## 5. How to regenerate the files

You can generate all syllabi in either of these ways:

- Use the VS Code task named "Generate all syllabi"
- Run this command in the repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\render-syllabi.ps1 -All
```

To render just one class, use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\render-syllabi.ps1 -Class physics
```

Equivalent npm script commands:

```powershell
npm run generate
npm run generate:physics
```

## 6. Where the outputs go

After generation, the outputs appear in:

- [syllabi/output/github-markdown](../syllabi/output/github-markdown)
- [syllabi/output/word-friendly-markdown](../syllabi/output/word-friendly-markdown)
- [syllabi/output/facts-plain-text](../syllabi/output/facts-plain-text)

DOCX files are generated when Pandoc is available.

## 7. How to change the Word renderer and formatting

The main rendering logic lives in:

- [scripts/render-syllabi.ps1](../scripts/render-syllabi.ps1)

If you want to change Word-friendly formatting, look for the functions that prepare the markdown for Word and plain text.

### Change the Word-friendly cleanup

Edit the conversion function in the script if you want to:

- change spacing between sections
- remove extra markdown formatting
- improve how lists or headings look in Word

### Change DOCX styling

The style templates are stored here:

- [syllabi/templates/word-reference/high-school-reference.docx](../syllabi/templates/word-reference/high-school-reference.docx)
- [syllabi/templates/word-reference/middle-school-reference.docx](../syllabi/templates/word-reference/middle-school-reference.docx)

If you want different Word formatting, replace those reference documents with new ones.

After replacing a reference DOCX, rerun generation to apply styles:

```powershell
npm run generate
```

### Change plain text output

Plain text generation also happens in the same script.
If you want different plain text formatting, edit that conversion step there.

## 8. Lint and validation checks

Before finishing work, run:

```powershell
npm run lint
```

If you want to format files automatically, run:

```powershell
npm run format
```

## 9. Recommended order of work

Use this order every time:

1. Edit the shared content or class YAML.
2. Update the template if the structure changes.
3. Regenerate the outputs.
4. Review the generated files.
5. Run linting.
6. Save the results and commit the changes.

## 10. Common errors and fixes

### YAML errors

- Check for quotes around values with colons.
- Keep the list syntax simple.
- Avoid unsupported block-scalar syntax in the current parser.

### Missing output files

- Make sure the renderer completed successfully.
- Check that Pandoc is installed if DOCX files are expected.

Useful checks:

```powershell
where.exe pandoc
pandoc --version
```

### Rules not changing everywhere

- Confirm you edited the shared file, not just one class YAML file.
- Rerender after changing shared content.
